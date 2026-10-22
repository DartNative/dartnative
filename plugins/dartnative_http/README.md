# dartnative_http

An HTTP client for DartNative apps that runs on the networking libraries
native apps use: NSURLSession on iOS, OkHttp on Android. It implements
package:http's `Client`, so code written for package:http works unchanged.
iOS and Android.

## Why you'll like it

- **Your UI stays smooth**: the request itself, HTTPS, decompression and
  HTTP/2 run on the platform's own networking threads, not on your app's UI
  thread.
- **Fast JSON**: `getJson` downloads a URL and decodes the JSON on a
  background isolate that DartNative keeps ready, then hands you the result
  without copying it.
- **No extra copies**: for `get`, `post`, `put`, `patch`, `delete` and
  `head`, the response body stays in native memory, and `response.bodyBytes`
  reads it there instead of copying it.
- **Works with your existing code**: `NativeHttpClient` is a package:http
  `Client`, so you can pass it to anything that expects one.

## Highlights

- **`NativeHttpClient()`** creates the client. Create one and reuse it for
  all your requests: the client keeps its connections to a server open, so
  later requests to the same server start faster. Call `client.close()` when
  you no longer need it.
- **`getJson(url)`** downloads a URL and decodes the body as JSON, into the
  same maps, lists, strings and numbers that `jsonDecode` returns. The result
  has the status code, the headers, the final URL (after any redirects) and
  the decoded `json`. The body is decoded whatever the status code, so check
  `statusCode` as you would after `get`. A body that is not valid JSON throws
  a `FormatException`; a request that fails throws package:http's
  `ClientException`, as `get` does.
- **`get`, `post`, `put`, `patch`, `delete` and `head`** work as in
  package:http. For a request body, pass a `String`, a list of bytes, or a
  `Map<String, String>` of form fields.
- **`send`** delivers a large download piece by piece, so the whole file is
  never held in memory at once. If your code falls behind (for example while
  it writes a piece to a file), the download pauses once about 1 MB is
  waiting for you, and continues when you read on.
- **To cancel a request**, send a package:http `AbortableRequest` and
  complete its `abortTrigger`. The request then fails with a
  `RequestAbortedException`.
- **Options**: `timeout` is how long a request may wait for data before it
  fails; when you do not set it, the platform's own default applies. `cache`
  turns HTTP caching on or off and `cookies` turns cookies on or off; both
  are on by default. `ios:` holds the settings that exist on iOS only:
  whether requests may use cellular data or networks the system marks as
  expensive (a personal hotspot, for example), whether they may run while Low
  Data Mode is on, and whether a request with no network waits for one
  instead of failing at once.
- **Cookies** are shared by every client in the app. On iOS they are kept
  between launches; on Android they last until the app is closed.
- **Background isolates**: the client also works inside your own isolate,
  for example in `Isolate.run`. Create the client in that isolate.

## Install

```yaml
dependencies:
  dartnative_http: ^1.0.0   # from dartpub.dev
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
import 'dart:convert';

import 'package:dartnative_http/http.dart';

final client = NativeHttpClient();

// Fetch JSON: the request and the decoding both run off the UI thread.
final response = await client.getJson(Uri.https('example.com', '/items.json'));
if (response.statusCode == 200) {
  final items = response.json as List;
  // ...
}

// Send data, as with package:http.
await client.post(
  Uri.https('example.com', '/items'),
  headers: {'content-type': 'application/json'},
  body: jsonEncode({'name': 'Dart'}),
);

client.close(); // when you no longer need the client
```

`getJson` sends a GET. For any other request whose answer is JSON, decode the
body with DartNative's `jsonDecodeInBackground`, which also keeps the UI
thread free:

```dart
import 'dart:convert';

import 'package:dartnative/dartnative.dart';

final url = Uri.https('example.com', '/items');
final response = await client.post(url, body: jsonEncode({'name': 'Dart'}));
final result = await jsonDecodeInBackground(response.bodyBytes);
```

A large download, read as it arrives:

```dart
import 'package:http/http.dart' as http;

final request = http.Request('GET', Uri.https('example.com', '/big-file.zip'));
final download = await client.send(request);
await for (final chunk in download.stream) {
  // write the chunk to a file, update a progress bar, ...
}
```

A request you can cancel:

```dart
import 'dart:async';

import 'package:http/http.dart' as http;

final url = Uri.https('example.com', '/items.json');
final cancel = Completer<void>();
final request = http.AbortableRequest('GET', url, abortTrigger: cancel.future);
final pending = client.send(request);
cancel.complete(); // for example when the user leaves the screen
try {
  await pending;
} on http.RequestAbortedException {
  // the request was cancelled
}
```

Every option, shown with its default. `timeout` alone has no default of its
own: the platform's applies.

```dart
final client = NativeHttpClient(
  timeout: const Duration(seconds: 20), // fail after 20 seconds without data
  cache: true,   // follow HTTP caching
  cookies: true, // send and keep cookies
  ios: const IosHttpOptions(
    allowsCellularAccess: true,
    allowsExpensiveNetworkAccess: true,   // personal hotspots and the like
    allowsConstrainedNetworkAccess: true, // requests while Low Data Mode is on
    waitsForConnectivity: false,
  ),
);
```

## Platform setup

### iOS

No native setup required.

### Android

No native setup required: the plugin declares the `INTERNET` permission for
you.

## Example

The [`example/`](./example) app is Dart Package Search, the example app of
Dart's own `http` package, rewritten with DartNative's widgets: it searches
pub.dev's packages as you type, and every request goes through one
`NativeHttpClient`. Borrow from it freely.

## Credits & license

- The client is **adapted from**
  [`cupertino_http`](https://github.com/dart-lang/http/tree/master/pkgs/cupertino_http)
  and [`ok_http`](https://github.com/dart-lang/http/tree/master/pkgs/ok_http)
  by the Dart project authors (BSD-3-Clause), with the platform calls
  rewritten over FFI.
- On Android it runs on [OkHttp](https://square.github.io/okhttp/)
  (Apache-2.0).

First-party DartNative plugin, free to use in any DartNative app. Distributed
through [dartpub.dev](https://dartpub.dev); report issues on the plugin's page.
