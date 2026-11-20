## 1.1.2

- On iOS, requests are faster. When several run at once, the client keeps
  using its open connections instead of opening new ones, and each response
  reaches your code with less work.
- On iOS, large responses reach your code sooner.
- On Android, requests are faster with the HTTP cache on (the default). A
  response the cache could never reuse, one with no `ETag`,
  `Last-Modified`, `Expires` or `max-age`, is no longer written to it. On a
  mid-range phone, that write cost about 1 ms per small request and 5 ms
  per megabyte. Such a response is also no longer returned for a request
  that sends `Cache-Control: max-stale`. The cache starts empty once after
  the update.
- On Android, if the app stops at its first request with
  `Failed to lookup symbol` after the update, run `dn clean` once, then
  build again.

## 1.1.1

- On iOS, the first request after the app starts is faster.

## 1.1.0

- WebSockets now work too, through `NativeWebSocket`.

## 1.0.0

- First release: an HTTP client for iOS and Android that runs on the phone's
  own networking and works with your `package:http` code.
