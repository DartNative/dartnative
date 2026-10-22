# JSON

DartNative decodes JSON straight from the bytes of a response, faster than
`jsonDecode`, on the calling isolate or in the background. The result is
the same maps and lists `jsonDecode` gives, so the rest of your code does
not change.

```dart
import 'package:dartnative/dartnative.dart';

final response = await client.get(Uri.https('example.com', '/feed.json'));
final feed = await jsonDecodeInBackground(response.bodyBytes) as Map<String, dynamic>;
```

---

## Which one to use

| | Runs on | Use it for |
|---|---|---|
| `jsonDecodeInBackground(bytes)` | a background isolate | responses from the network, and any JSON larger than a few kilobytes: the screen keeps drawing while it decodes |
| `jsonDecodeNative(bytes)` | the calling isolate | small JSON, or code that already runs on a background isolate |

Both take the bytes as they arrive (`response.bodyBytes`, a file's bytes),
so there is no `String` to make first: that step alone is a large part of
what `jsonDecode(response.body)` costs.

---

## The same result as `jsonDecode`

Both return exactly what `jsonDecode(utf8.decode(bytes))` returns:

- `Map<String, dynamic>`, with the keys in the document's order;
- `List<dynamic>`, `String`, `int`, `double`, `bool` and `null`;
- the same numbers: an integer too large for an `int` is a `double`, as
  in Dart.

Code written for `jsonDecode` keeps working, `fromJson` constructors from
json_serializable and freezed included:

```dart
final user = User.fromJson(await jsonDecodeInBackground(bytes) as Map<String, dynamic>);
```

Invalid JSON, or bytes that are not valid UTF-8, throw the same
`FormatException` as `jsonDecode`, with the same message.

---

## With `dartnative_http`

`dartnative_http`, an HTTP client on the phone's own networking, keeps a
whole response body in native memory: pass `response.bodyBytes` to
`jsonDecodeInBackground` and the bytes reach the decoder without going
through the Dart heap, and without a `String`.

```dart
import 'package:dartnative_http/http.dart';

final client = NativeHttpClient();
final response = await client.get(url);
final items = await jsonDecodeInBackground(response.bodyBytes) as List<dynamic>;
```
