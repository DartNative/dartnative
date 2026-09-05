# Calling Dart back from native code — events, results, streams

> **TL;DR** — if your plugin's native code calls Dart back *later* (an event, a
> progress update, an async result), follow
> [the standard pattern](#the-standard-pattern-the-dispatcher-slot-option-3).
> Copy the three snippets, keep the three rules, and your plugin will never
> crash a hot restart. Everything else on this page is context and edge cases.

> **Do you even need this page?** Only if native code invokes a Dart callback
> **after** your Dart→native call has returned. If your plugin is pure Dart, or
> native only *returns values* to Dart, none of this applies — skip it.

---

## The problem, in plain words

When Dart hands a callback to native code, native does not receive a Dart
function. It receives a **plain C function pointer** that the Dart VM generates
on the fly. Native calls that pointer, and your Dart function runs. So far so
good.

The catch is the pointer's **lifetime**. On a **hot restart** (capital `R` in
the terminal) Dart throws away the entire program and runs `main()` again —
*inside the same OS process*. Every C pointer the VM generated for the old run
is deleted. But your native code was **not** restarted: a video player is still
playing, a download is still in flight, a sensor listener is still registered.
The moment any of them calls a deleted pointer, the app dies on the spot:

```
error: Callback invoked after it has been deleted.   → SIGABRT
```

Notes on scope:

- This happens on **iOS and Android alike**. (The belief that "iOS kills the
  process on hot restart" is false — the process keeps running.)
- It is **debug-only**: release apps never hot-restart. But it kills every
  debugging session, so treat it as a must-fix, not a nice-to-have.
- The same abort can also happen **within one session** if native fires a
  callback after your Dart code closed it (a queued block that lands late).
  The patterns below handle both.

The framework cannot intercept this for you — native calls the pointer
directly, no framework code is on the stack. What the framework *can* do is
tell native "that pointer is about to die" **before** it dies. That is exactly
what the standard pattern plugs into.

---

## One question decides everything

**Does native call your Dart function *after* your FFI call has returned?**

| Answer | What to do |
|---|---|
| **No** — native computes and *returns* values, or fires the callback synchronously *during* your call | You're (almost) done. For synchronous callbacks use the [liveness gate](#synchronous-callbacks-fired-during-your-call). |
| **Yes** — events, ticks, progress, async results, anything delivered later | Use [the standard pattern](#the-standard-pattern-the-dispatcher-slot-option-3). |

One more thing to know before you start: everything below assumes your FFI
calls run on the **main isolate** (they almost always do). If you call native
from an `Isolate.spawn` worker, read [Worker isolates](#worker-isolates) first
— the standard pattern does not protect workers.

### Firing through `DNCallbackFire` (Android)

If your Kotlin calls `DNCallbackFire.fire*` instead of invoking a stored
pointer yourself, you inherit the framework's hot-restart protection and need
none of the pattern below. Three first-party plugins already work this way
(`media_picker`, `permissions`, `webview`).

The pattern below is for plugins that hold their own pointer — a C callback, a
Swift closure, a background thread — and for iOS in every case, where the
dispatcher slot is always the mechanism.

---

## The standard pattern: the dispatcher slot (option 3)

The whole idea, no framework knowledge required:

1. **Dart creates ONE callback pointer for your whole plugin** — not one per
   player/request/listener — and hands its address to native. Each call carries
   a `token` (an int id) so one pointer can serve many objects.
2. **Native stores that address in ONE variable** — "the slot" — and registers
   the slot's location with the framework, once.
3. **On hot restart, the framework sets the slot to 0** (Android: bumps a
   restart counter) — and it does this **while the old pointer is still
   valid**, before Dart tears anything down.
4. **Native re-reads the slot every single time it wants to call Dart.**
   Slot is 0 (or the counter moved)? The event is dropped instead of fired.

That ordering is the entire trick: any call that happens *before* the framework
zeroes the slot hits a still-valid pointer (harmless, the old program is still
alive); any call *after* reads 0 and does nothing. There is no moment where a
dead pointer can be called.

After the restart, your plugin's Dart setup code runs again in the new session
and hands native a fresh address — the slot refills by itself. An event carrying
a token from the *previous* session finds no handler on the Dart side and is
ignored. Everything self-heals.

### Step 1 — Dart side (same for iOS and Android)

```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';

// The C signature every callback arrives with. Keep it simple:
// (token, eventType, payload-string). One string carries any data as JSON.
typedef _DispatchC = Void Function(Int64, Int32, Pointer<Utf8>);

// ONE handler map for the whole plugin: token → Dart-side listener.
// Populated when you create an object, cleaned up when you dispose it.
final Map<int, void Function(int type, String payload)> _handlers = {};

// ONE static dispatcher for the whole plugin. Must be a top-level or static
// function (Pointer.fromFunction requires it). Routes by token; a token from
// before a hot restart simply finds no handler and is dropped.
void _dispatch(int token, int type, Pointer<Utf8> payload) {
  _handlers[token]?.call(type, payload.toDartString());
}

final Pointer<NativeFunction<_DispatchC>> _dispatchPtr =
    Pointer.fromFunction<_DispatchC>(_dispatch);

// A plain FFI setter your plugin defines natively (see step 2):
final _setDispatcher = DynamicLibrary.process()
    .lookupFunction<Void Function(Int64), void Function(int)>(
      'MyPluginSetDispatcher',
    );
// (Android: DynamicLibrary.open('libmy_plugin.so') instead of .process())

void initMyPlugin() {
  _setDispatcher(_dispatchPtr.address);   // hand native the address — once
}
```

That's the whole Dart side. Note what you did **not** do: no per-object
callbacks, no `NativeCallable.listener`, no manual cleanup on hot restart.

### Step 2 (iOS) — native side, Swift

```swift
import Foundation  // dlsym

// THE SLOT. Heap-allocated so its address never moves — the framework keeps
// a pointer to it and writes 0 into it when a hot restart begins.
private let _dispatcherSlot: UnsafeMutablePointer<Int64> = {
    let p = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
    p.pointee = 0
    return p
}()
private var _slotRegistered = false

@_cdecl("MyPluginSetDispatcher")
public func MyPluginSetDispatcher(_ callbackPtr: Int64) {
    _dispatcherSlot.pointee = callbackPtr
    if !_slotRegistered {                       // register with the framework, once
        _slotRegistered = true
        typealias RegFn = @convention(c) (UnsafeMutablePointer<Int64>) -> Void
        if let sym = dlsym(UnsafeMutableRawPointer(bitPattern: -2),
                           "DNRegisterAsyncDispatcherSlot") {
            unsafeBitCast(sym, to: RegFn.self)(_dispatcherSlot)
        }
    }
}

// EVERY place native wants to call Dart goes through this — and nowhere else.
private typealias Dispatch =
    @convention(c) (Int64, Int32, UnsafePointer<CChar>) -> Void

func fireToDart(token: Int64, type: Int32, payload: String) {
    // Must run on the MAIN thread — Dart lives there. If your event arrives
    // on a background queue, hop first:
    //   DispatchQueue.main.async { fireToDart(...) }
    let addr = _dispatcherSlot.pointee   // read FRESH every time — never cache
    guard addr != 0 else { return }      // hot restart happened → drop quietly
    payload.withCString { cStr in
        unsafeBitCast(addr, to: Dispatch.self)(token, type, cStr)
    }
    // Dart copies the string during the call — no ownership to manage.
}
```

### Step 2 (Android) — native side, Kotlin + one C function

On Android the framework's invalidation signal is a **restart counter**
(`DN_IsolateGen()` — "isolate generation"). It increments the moment a hot
restart begins. You capture its value when Dart hands you the pointer; before
every call you check it hasn't moved.

```kotlin
object MyPluginBridge {
    @Volatile private var dispatcherPtr: Long = 0L
    @Volatile private var dispatcherGen: Long = 0L

    // Called (via JNI or your FFI entry) when Dart hands over the address:
    fun setDispatcher(ptr: Long) {
        dispatcherPtr = ptr
        dispatcherGen = nativeIsolateGen()   // capture the counter WITH the ptr
    }

    // EVERY place native wants to call Dart goes through this:
    fun fireToDart(token: Long, type: Int, payload: String) {
        // Must run on the main thread — post to the main Looper if needed:
        //   Handler(Looper.getMainLooper()).post { fireToDart(...) }
        if (dispatcherGen != nativeIsolateGen()) return  // restarted → drop
        val ptr = dispatcherPtr
        if (ptr == 0L) return
        nativeDeliver(ptr, token, type, payload)
    }

    private external fun nativeIsolateGen(): Long
    private external fun nativeDeliver(ptr: Long, token: Long, type: Int, payload: String)
}
```

```cpp
// In your plugin's .cpp — two small helpers:
#include <dlfcn.h>
#include <jni.h>

// Reads the framework's restart counter from the core library.
extern "C" JNIEXPORT jlong JNICALL
Java_com_example_MyPluginBridge_nativeIsolateGen(JNIEnv*, jobject) {
    using GenFn = uint64_t (*)();
    static GenFn fn = (GenFn)dlsym(RTLD_DEFAULT, "DN_IsolateGen");
    return fn ? (jlong)fn() : 0;
}

// Invokes the Dart dispatcher pointer.
extern "C" JNIEXPORT void JNICALL
Java_com_example_MyPluginBridge_nativeDeliver(
    JNIEnv* env, jobject, jlong ptr, jlong token, jint type, jstring payload) {
    using Dispatch = void (*)(int64_t, int32_t, const char*);
    const char* cStr = env->GetStringUTFChars(payload, nullptr);
    ((Dispatch)ptr)(token, type, cStr);
    env->ReleaseStringUTFChars(payload, cStr);
}
```

> Android also offers `DNViewRegistry.registerResetHook { … }` — hooks that run
> when the **new** session starts. Use those for resource cleanup (dispose
> players, cancel downloads), **not** as the crash guard: they run too late.
> The generation check above is the crash guard.

### The three rules that make it safe

The guarantee holds **only** if you follow all three — each one exists because
breaking it re-opens the crash:

1. **One variable holds the address.** Never copy the raw address into a
   closure, a listener, a per-object field, or a local that outlives the call.
   A copy is invisible to the framework — it cannot zero what it doesn't know
   about, and the copy **will** crash.
2. **Register with the framework once** — iOS: hand the slot's location to
   `DNRegisterAsyncDispatcherSlot`; Android: capture `DN_IsolateGen()` next to
   the pointer.
3. **Re-check before every call** — read the slot fresh and skip on 0 (iOS);
   compare the captured generation and skip on mismatch (Android). And always
   call from the **main thread**.

### Sending data and errors

The channel carries `(token, type, one string)` — that is deliberately all:

- **Payloads**: encode as JSON in the string. Scalars travel stringified
  (`"73"` parses back to an int).
- **Errors**: encode them *in* the string (e.g. `{"__error":"timeout"}`) and
  `throw` on the Dart side after decoding. Two-value `(error, result)`
  callbacks fold into the same shape.
- **Streams**: route by `token` to a per-object handler or `StreamController`;
  remove the handler in `dispose()`.
- **One-shot results** (a "future" answered by native): same shape — store a
  `Completer` in the handler map under the token, complete it on delivery,
  remove it.

This is the same pattern the official plugins run in production:
`dartnative_video_player` (event + position streams), `dartnative_connectivity`
(network-change stream), `dartnative_revenuecat` (one-shot purchase results).
The snippets above are the complete pattern — nothing else is needed.

---

## Alternatives to the standard pattern

Two other delivery channels are also hot-restart-proof. Reach for them only
when they fit better than the slot:

### Option 2 — Pull / poll

Native never calls Dart at all: it **buffers** results, and Dart fetches them
on a timer with a plain FFI call that *returns* the data. Nothing native holds
can dangle, because native holds nothing. Best for bulk, latency-tolerant data.

```dart
Timer.periodic(const Duration(milliseconds: 50), (_) {
  final n = _drain(_buf, _buf.length);   // plain FFI call, returns bytes
  if (n > 0) _handle(_buf, n);
});
```

### Option 1 — Native port (`Dart_PostCObject`)

Dart hands native a **port id** (`ReceivePort().sendPort.nativePort`, an
`int64`); native posts messages to it. Posting to a closed port is a harmless
no-op, so this is safe across hot restart **and worker isolates** by
construction. Cost: wiring `dart_api_dl.h` + `Dart_InitializeApiDL` into your
native build, and there is no in-tree worked reference yet. It is the **only**
safe channel for worker-isolate delivery; on the main isolate the slot pattern
gives the same safety with less machinery.

---

## Synchronous callbacks (fired *during* your call)

If native invokes the callback **before your FFI call returns** (a value
computed in-call, a gesture handler the framework dispatches), the hot-restart
problem cannot reach it — but a *queued* late fire in the same session can.
Route the callback through the framework's liveness gate; a late fire then
becomes a no-op instead of a crash:

```dart
import 'package:dartnative/dartnative.dart' show DnCallbacks;

final nc = NativeCallable<Void Function(Int32)>.isolateLocal(onEvent);
_dnRegisterCallback(DnCallbacks.arm(nc));   // NOT nc.nativeFunction.address
// teardown:
DnCallbacks.disarmAndClose(nc);             // NOT nc.close()
```

---

## Worker isolates

If your FFI calls run on a worker isolate (`Isolate.spawn`, for heavy compute),
the main-isolate patterns **break**: the slot and handler map are per-isolate,
and the pre-restart invalidation never runs for a dying worker. Two correct
approaches:

1. **Keep the whole channel inside the worker** — the worker registers its own
   dispatcher and handler map, and native calls back the pointer the *calling*
   isolate handed it. Each isolate owns its own delivery.
2. **Native port (option 1)** — port ids are isolate-agnostic and posting to a
   closed port is a no-op. This is the robust choice.

Worker-isolate delivery is genuinely tricky. Build it, then **test it with a
hot restart mid-operation** before relying on it.

---

## ⛔ Things that look like fixes but are not

- **"I'll use one global `Pointer.fromFunction` — its address is stable."**
  No: the pointer is bound to the isolate and is deleted on hot restart like
  any other. Without the slot registration (rule 2), native still calls a dead
  address. The standard pattern uses one global pointer *plus* the framework
  invalidation — the invalidation is the part that saves you.
- **"My token map will catch stale calls."** No: the app aborts on *entering*
  the dead pointer, before your token lookup ever runs. The check must happen
  on the **native** side, before the call.
- **"I'll clean up in the new session's init."** Too late: native can fire in
  the window before your init runs. Only the framework's pre-teardown
  invalidation (or a channel that holds no pointer at all) closes that window.

---

## Checklist

- [ ] Native calls Dart back *later*? If **no** → plain return values (plus the
      liveness gate for sync callbacks). Done.
- [ ] If **yes** → the dispatcher slot (option 3): one Dart dispatcher + one
      native slot + framework registration. Snippets above.
- [ ] Every native call site re-checks (slot ≠ 0 / generation unchanged) and
      runs on the **main thread**. The raw address is never copied anywhere.
- [ ] Errors travel inside the payload string; streams route by token.
- [ ] Worker isolate? → native port, or keep delivery inside the worker.
- [ ] **Test it**: start an operation (play a stream, kick off a download),
      press capital `R` mid-flight (lowercase `r` is hot *reload* and does not
      reproduce the problem), confirm there is no crash — and that the plugin
      works again after the restart.
