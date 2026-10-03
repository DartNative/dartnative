# dartnative_hive_generator

Generates the type adapters [dartnative_hive](https://dartpub.dev/plugins/dartnative_hive)
uses to store your own classes and enums. It is a port of
[hive_ce_generator](https://pub.dev/packages/hive_ce_generator) 1.11.3: the same annotations,
the same generated code, the same schema file, for apps that use `dartnative_hive`.

## Install

```yaml
dependencies:
  dartnative_hive: ^2.0.0

dev_dependencies:
  dartnative_hive_generator:
    hosted: https://dartpub.dev
    version: ^2.0.0
  build_runner: ^2.5.4
```

```bash
dn pub get
```

## Generate adapters

List the types to store in one file, and the generator gives each one a type id:

```dart
// lib/hive/hive_adapters.dart
import 'package:dartnative_hive/dartnative_hive.dart';

import '../person.dart';

@GenerateAdapters([AdapterSpec<Person>()])
part 'hive_adapters.g.dart';
```

Or annotate a class yourself:

```dart
import 'package:dartnative_hive/dartnative_hive.dart';

part 'person.g.dart';

@HiveType(typeId: 0)
class Person {
  Person({required this.name, required this.age});

  @HiveField(0)
  final String name;

  @HiveField(1)
  final int age;
}
```

Then generate:

```bash
dn pub run build_runner build
```

The build also writes `hive_registrar.g.dart`, which registers every adapter in one call:

```dart
import 'hive/hive_registrar.g.dart';

Hive.initDartNative(documentsPath);
Hive.registerAdapters();
```

`GenerateAdapters` keeps a schema in `lib/hive/hive_adapters.g.yaml`, so a type keeps its id
and its fields keep their indexes as your classes change. Check it in with your code.

Every option of hive_ce_generator works the same way; Hive's
[documentation](https://docs.hive.isar.community) applies as written, with
`package:dartnative_hive/dartnative_hive.dart` in place of `package:hive_ce/hive_ce.dart`.

## Credits & license

A port of [hive_ce_generator](https://github.com/IO-Design-Team/hive_ce/tree/main/hive_generator),
part of the community edition of Hive. Its licence is in `LICENSE`.
