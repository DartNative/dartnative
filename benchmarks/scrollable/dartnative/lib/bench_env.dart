/// Reads a variable from the app's launch environment, where the harness
/// puts its settings (such as `BENCH_MEMORY`), as the Swift and React
/// Native apps read theirs.
///
/// `Platform.environment` is empty on iOS, because Dart's `dart:io` does
/// not read the process environment there. The C library does, so on iOS
/// the variable is read with `getenv` through `dart:ffi`.
library;
import 'dart:convert' show utf8;
import 'dart:ffi';
import 'dart:io' show Platform;

String? benchEnv(String name) {
  if (!Platform.isIOS) return Platform.environment[name];
  final lib = DynamicLibrary.process();
  final getenv = lib.lookupFunction<Pointer<Uint8> Function(Pointer<Uint8>),
      Pointer<Uint8> Function(Pointer<Uint8>)>('getenv');
  final malloc = lib.lookupFunction<Pointer<Uint8> Function(IntPtr),
      Pointer<Uint8> Function(int)>('malloc');
  final free = lib.lookupFunction<Void Function(Pointer<Uint8>),
      void Function(Pointer<Uint8>)>('free');
  final bytes = utf8.encode(name);
  final cName = malloc(bytes.length + 1);
  cName.asTypedList(bytes.length + 1)
    ..setAll(0, bytes)
    ..[bytes.length] = 0;
  try {
    final value = getenv(cName);
    if (value == nullptr) return null;
    var length = 0;
    while (value[length] != 0) {
      length++;
    }
    return utf8.decode(value.asTypedList(length));
  } finally {
    free(cName);
  }
}
