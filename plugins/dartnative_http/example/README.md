# dartnative_http example

Dart Package Search, the example app of Dart's own `http` package, running
on `dartnative_http`. Type a name to search pub.dev's packages, and see each
package's publisher, likes and downloads. Every request goes through one
`NativeHttpClient`, so it runs on NSURLSession on iPhone and OkHttp on
Android.

The **WebSocket** button in the top bar opens a second screen: it connects
to a public echo server, and every message you send comes back.

## Run it

```sh
dn pub get
dn run -d <device-id>
```

The example is an official demo: free to run, no license setup.

## Where the code is

- `lib/http_demo.dart`: the screens and the requests, adapted from
  [`flutter_http_example`](https://github.com/dart-lang/http/tree/master/pkgs/flutter_http_example)
  in dart-lang/http, with one `NativeHttpClient` for the whole app.
- `lib/web_socket_demo.dart`: the WebSocket screen, with one
  `NativeWebSocket`.
- `lib/main.dart`: starts the app.
