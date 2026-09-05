# Notifications, local & push

The finished code for the [notifications tutorial](https://dartnative.com/tutorials/notifications):
permission, local alerts, iOS Communication (chat-style) notifications
with a real avatar, and the FCM token + foreground-message pipeline —
all over FFI, no MethodChannel.

The permission + local-notification sections work with no setup at all.
Configuration required for the push (FCM) sections:

- Your own `GoogleService-Info.plist` in the Runner (Firebase project).
- **Push Notifications** + **Background Modes → Remote notifications**
  capabilities on the Runner target.
- A physical device (APNs does not work on the simulator).

On Android the committed shell also ships `notification_icon.png`
(five densities): the status-bar icon must be a WHITE SILHOUETTE on
transparency — Android tints by alpha only, so a full-colour launcher
icon renders as a solid black square. Recipe + sizes: the
dartnative_notifications README ("small-notification icon").

```sh
dn pub get
dn run
```

The screen is carried over from the DartNative playground **byte-identical**:
[`lib/screens/notifications_demo.dart`](lib/screens/notifications_demo.dart)
is the playground's notifications demo verbatim, and
[`lib/screens/home/demo_ui.dart`](lib/screens/home/demo_ui.dart) is the
playground's shared UI kit, also verbatim. [`lib/main.dart`](lib/main.dart)
adds only the thin entry — plugin registration plus the Firebase /
notifications startup block. When the playground demo improves, this
tutorial updates by copying the files again. Verified against dartnative
`^1.0.0`.
