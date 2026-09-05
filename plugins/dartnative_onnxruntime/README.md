# dartnative_onnxruntime

On-device ONNX Runtime inference for DartNative — iOS (CoreML / CPU) and Android
(NNAPI / CPU). Drop-in for `flutter_onnxruntime`.

## Why you'll like it

- **Hardware acceleration out of the box** — pass `OrtProvider.CORE_ML` on iOS to
  run on the Apple Neural Engine / GPU; `OrtProvider.NNAPI` on Android. CPU fallback
  is automatic.
- **Familiar API** — `OnnxRuntime`, `OrtSession`, `OrtValue` mirror the
  `flutter_onnxruntime` surface, so existing call sites port with minimal changes.
- **Typed tensors** — `OrtValue.fromList` accepts `Float32List`, `Int32List`,
  `Int64List`, `Uint8List`, and plain `List<num>`/`List<bool>`; shape mismatch is
  caught before it reaches native.

## Highlights

- **`OnnxRuntime().createSession(path, options:)`** — load a `.onnx` model from disk,
  optionally specifying providers and thread counts.
- **`session.run(inputs)`** — synchronous inference; returns a `Map<String, OrtValue>`.
- **`OrtValue.fromList(data, shape)`** — create an input tensor from any typed list.
- **`value.asFlattenedList()` / `value.asList()`** — read the output tensor back to Dart.
- **`value.dispose()` / `session.close()`** — release native resources explicitly.
- **`ort.getAvailableProviders()`** — query which execution providers are available on
  this device at runtime.

## Install

```yaml
dependencies:
  dartnative_onnxruntime: ^1.6.4   # from dartpub.dev
```

```bash
dn pub get
```

```dart
void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const MyApp());
}
```

## Quick look

```dart
import 'package:dartnative_onnxruntime/dartnative_onnxruntime.dart';
```

Load a model with CoreML acceleration and a CPU fallback:

```dart
final ort = OnnxRuntime();
OrtSession session;
try {
  session = await ort.createSession(
    '/path/to/model.onnx',
    options: OrtSessionOptions(
      providers: [OrtProvider.CORE_ML, OrtProvider.CPU],
    ),
  );
} catch (_) {
  // CoreML unavailable or incompatible — fall back to CPU only
  session = await ort.createSession('/path/to/model.onnx');
}
```

Run inference:

```dart
final input = await OrtValue.fromList(
  Float32List.fromList(myFloats),   // raw data
  [1, 256],                         // shape [batch, features]
);

final outputs = await session.run({'input': input});
final data = await outputs['output']!.asFlattenedList();

await input.dispose();
await outputs['output']!.dispose();
```

Inspect inputs and outputs before running:

```dart
print(session.inputNames);   // ['input']
print(session.outputNames);  // ['output']

final meta = await session.getMetadata();
print(meta.producerName);
```

Query available providers at runtime:

```dart
final providers = await ort.getAvailableProviders();
// e.g. [OrtProvider.CORE_ML, OrtProvider.CPU] on an A-series iOS device
```

> **Tip — dispose everything.** `OrtValue` objects are backed by a native registry.
> Call `value.dispose()` on every input and output tensor after each inference run,
> and `session.close()` when the session is no longer needed.

## Platform setup

### iOS

Requires **iOS 16.0+** (`platform :ios, '16.0'` in your Podfile + the Xcode
deployment target — the podspec's minimum). No other native setup: the plugin
links the `onnxruntime-objc` CocoaPod automatically.

### Android

Requires **minSdk 24**. No other native setup: the plugin bundles the
`onnxruntime-android` AAR and the JNI bridge is loaded at engine attach by
`DartNativeOnnxruntimePlugin`.

## Example

The [`example/`](./example) app bundles a tiny synthetic model and walks through the
full API: load session → create tensors → run inference → read output → dispose.

Used in production by `dartnative_supertonic_tts`.

## Credits & license

Ported from
[`flutter_onnxruntime`](https://github.com/masicai/flutter_onnxruntime)
(MIT), reworked to FFI with CoreML and Android JNI backends.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on
the plugin's page.
