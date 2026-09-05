/**
 * dn_share_bridge.cpp — dart_native_share Android JNI/C bridge.
 *
 * Architecture:
 *   Dart (platform thread) ──[FFI]──► extern "C" DNShareText / DNShareFiles
 *                                  ──[JNI]──► Kotlin top-level fn
 *
 * Exposed entry points (match the iOS surface):
 *   DNShareText(text)                                   — text/plain share
 *   DNShareFiles(paths, pathCount,
 *                mimeTypes, mimeCount,
 *                text)                                  — one OR many files
 *                                                         (ACTION_SEND for 1,
 *                                                         ACTION_SEND_MULTIPLE for N)
 *
 * JNI_OnLoad caches the JavaVM and the Kotlin top-level method IDs.
 */

#include <jni.h>
#include <cstdint>
#include <dlfcn.h>
#include <android/log.h>

#define LOG_TAG "DNShare"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// ─── Global state ─────────────────────────────────────────────────────────────

static JavaVM*   g_jvm           = nullptr;
static jclass    g_bridgeClass   = nullptr;
static jclass    g_stringClass   = nullptr;
static jmethodID g_shareText     = nullptr;
static jmethodID g_shareFiles    = nullptr;
// Result-reporting variants (nullable: guarded at every call site so a
// mismatched Kotlin/native pairing degrades instead of failing JNI_OnLoad).
static jmethodID g_setDispatcher        = nullptr;
static jmethodID g_shareTextWithResult  = nullptr;
static jmethodID g_shareFilesWithResult = nullptr;

// ─── Helpers ──────────────────────────────────────────────────────────────────

static JNIEnv* getEnv() {
    JNIEnv* env = nullptr;
    if (!g_jvm) return nullptr;
    if (g_jvm->GetEnv((void**)&env, JNI_VERSION_1_6) != JNI_OK) return nullptr;
    return env;
}

static jmethodID safeGet(JNIEnv* env, jclass cls, const char* name, const char* sig) {
    jmethodID mid = env->GetStaticMethodID(cls, name, sig);
    if (env->ExceptionCheck()) { env->ExceptionClear(); return nullptr; }
    return mid;
}

static jstring toJString(JNIEnv* env, const char* s) {
    return s ? env->NewStringUTF(s) : nullptr;
}

/// Convert `const char** arr` of length `count` into a fresh `String[]`.
/// NULL elements become empty strings. Returns nullptr if `arr == nullptr`
/// or `count <= 0`.
static jobjectArray toJStringArray(JNIEnv* env, const char** arr, int32_t count) {
    if (!arr || count <= 0 || !g_stringClass) return nullptr;
    jobjectArray jarr = env->NewObjectArray(count, g_stringClass, nullptr);
    if (!jarr) return nullptr;
    for (int32_t i = 0; i < count; i++) {
        jstring js = env->NewStringUTF(arr[i] ? arr[i] : "");
        env->SetObjectArrayElement(jarr, i, js);
        if (js) env->DeleteLocalRef(js);
    }
    return jarr;
}

// ─── JNI_OnLoad ───────────────────────────────────────────────────────────────

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void* /*reserved*/) {
    g_jvm = vm;
    JNIEnv* env = nullptr;
    if (vm->GetEnv((void**)&env, JNI_VERSION_1_6) != JNI_OK) return JNI_ERR;

    jclass cls = env->FindClass("com/dartnative/share/DNShareBridgeKt");
    if (!cls) {
        LOGE("JNI_OnLoad: class DNShareBridgeKt not found");
        return JNI_ERR;
    }
    g_bridgeClass = (jclass)env->NewGlobalRef(cls);
    env->DeleteLocalRef(cls);

    jclass strCls = env->FindClass("java/lang/String");
    if (!strCls) {
        LOGE("JNI_OnLoad: class java/lang/String not found");
        return JNI_ERR;
    }
    g_stringClass = (jclass)env->NewGlobalRef(strCls);
    env->DeleteLocalRef(strCls);

    g_shareText = safeGet(env, g_bridgeClass, "shareText", "(Ljava/lang/String;)V");
    if (!g_shareText) {
        LOGE("JNI_OnLoad: method shareText not found");
        return JNI_ERR;
    }

    g_shareFiles = safeGet(
        env, g_bridgeClass, "shareFiles",
        "([Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)V"
    );
    if (!g_shareFiles) {
        LOGE("JNI_OnLoad: method shareFiles not found");
        return JNI_ERR;
    }

    // Result-reporting variants — soft-resolved (see the globals' comment).
    g_setDispatcher = safeGet(env, g_bridgeClass, "setDispatcher", "(J)V");
    g_shareTextWithResult = safeGet(
        env, g_bridgeClass, "shareTextWithResult", "(JLjava/lang/String;)V"
    );
    g_shareFilesWithResult = safeGet(
        env, g_bridgeClass, "shareFilesWithResult",
        "(J[Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)V"
    );

    LOGI("JNI_OnLoad OK");
    return JNI_VERSION_1_6;
}

// ─── FFI entry points (called from Dart) ─────────────────────────────────────

extern "C" __attribute__((visibility("default")))
void DNShareText(const char* text) {
    JNIEnv* env = getEnv();
    if (!env || !g_bridgeClass || !g_shareText) return;
    jstring jText = toJString(env, text);
    env->CallStaticVoidMethod(g_bridgeClass, g_shareText, jText);
    if (jText) env->DeleteLocalRef(jText);
    if (env->ExceptionCheck()) { env->ExceptionClear(); }
}

extern "C" __attribute__((visibility("default")))
void DNShareFiles(
    const char** paths,
    int32_t pathCount,
    const char** mimeTypes,
    int32_t mimeCount,
    const char* text
) {
    JNIEnv* env = getEnv();
    if (!env || !g_bridgeClass || !g_shareFiles) return;
    jobjectArray jPaths = toJStringArray(env, paths, pathCount);
    jobjectArray jMimes = toJStringArray(env, mimeTypes, mimeCount);
    jstring      jText  = toJString(env, text);
    env->CallStaticVoidMethod(
        g_bridgeClass, g_shareFiles, jPaths, jMimes, jText
    );
    if (jPaths) env->DeleteLocalRef(jPaths);
    if (jMimes) env->DeleteLocalRef(jMimes);
    if (jText)  env->DeleteLocalRef(jText);
    if (env->ExceptionCheck()) { env->ExceptionClear(); }
}

// ─── Result-reporting variants ───────────────────────────────────────────────

/// Store the Dart dispatcher address Kotlin-side (paired with the isolate
/// generation — see DNShareBridge.kt `setDispatcher`).
extern "C" __attribute__((visibility("default")))
void DNShareSetDispatcher(int64_t callbackPtr) {
    JNIEnv* env = getEnv();
    if (!env || !g_bridgeClass || !g_setDispatcher) return;
    env->CallStaticVoidMethod(g_bridgeClass, g_setDispatcher, (jlong)callbackPtr);
    if (env->ExceptionCheck()) { env->ExceptionClear(); }
}

extern "C" __attribute__((visibility("default")))
void DNShareTextWithResult(int64_t token, const char* text) {
    JNIEnv* env = getEnv();
    if (!env || !g_bridgeClass || !g_shareTextWithResult) return;
    jstring jText = toJString(env, text);
    env->CallStaticVoidMethod(
        g_bridgeClass, g_shareTextWithResult, (jlong)token, jText
    );
    if (jText) env->DeleteLocalRef(jText);
    if (env->ExceptionCheck()) { env->ExceptionClear(); }
}

extern "C" __attribute__((visibility("default")))
void DNShareFilesWithResult(
    int64_t token,
    const char** paths,
    int32_t pathCount,
    const char** mimeTypes,
    int32_t mimeCount,
    const char* text
) {
    JNIEnv* env = getEnv();
    if (!env || !g_bridgeClass || !g_shareFilesWithResult) return;
    jobjectArray jPaths = toJStringArray(env, paths, pathCount);
    jobjectArray jMimes = toJStringArray(env, mimeTypes, mimeCount);
    jstring      jText  = toJString(env, text);
    env->CallStaticVoidMethod(
        g_bridgeClass, g_shareFilesWithResult,
        (jlong)token, jPaths, jMimes, jText
    );
    if (jPaths) env->DeleteLocalRef(jPaths);
    if (jMimes) env->DeleteLocalRef(jMimes);
    if (jText)  env->DeleteLocalRef(jText);
    if (env->ExceptionCheck()) { env->ExceptionClear(); }
}

// ─── Kotlin externals (result delivery) ──────────────────────────────────────

/// Reads the framework's isolate-generation counter — bumped BEFORE the old
/// isolate dies on hot restart, so Kotlin's gen-gate drops stale deliveries.
extern "C" JNIEXPORT jlong JNICALL
Java_com_dartnative_share_DNShareBridgeKt_nativeIsolateGen(JNIEnv*, jclass) {
    using GenFn = uint64_t (*)();
    static GenFn fn = (GenFn)dlsym(RTLD_DEFAULT, "DN_IsolateGen");
    return fn ? (jlong)fn() : 0;
}

/// Invokes the Dart dispatcher fn-pointer: (token, status, raw).
/// Called on the main thread (= the Dart isolate's thread) with the
/// generation already checked; the call is synchronous, so the stack-scoped
/// UTF-8 buffer is safe — Dart copies it during the call.
extern "C" JNIEXPORT void JNICALL
Java_com_dartnative_share_DNShareBridgeKt_nativeDeliverShareResult(
    JNIEnv* env, jclass, jlong ptr, jlong token, jint status, jstring raw
) {
    if (!ptr) return;
    using DispatchFn = void (*)(int64_t, int32_t, const char*);
    const char* c = raw ? env->GetStringUTFChars(raw, nullptr) : nullptr;
    ((DispatchFn)ptr)((int64_t)token, (int32_t)status, c ? c : "");
    if (raw && c) env->ReleaseStringUTFChars(raw, c);
}
