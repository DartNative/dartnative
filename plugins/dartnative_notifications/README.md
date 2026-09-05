# dartnative_notifications

Local notifications for DartNative — show alerts, handle taps, and (on iOS 15+) post
chat-style Communication Notifications with a sender avatar. iOS and Android.

## Why you'll like it

- **Simple to fire** — `show(id, title, body)` and you're done; tap handling is one `setup` call.
- **Permission built in** — `requestPermission()` returns whether the user said yes.
- **Communication Notifications** — `showChat(...)` renders the iOS 15+ messaging style (sender
  name + avatar via `INSendMessageIntent`), falling back to a plain notification elsewhere.

## Highlights

- **`DartNativeNotifications.setup({onTap})`** — wire a tap handler (receives the payload).
- **`requestPermission()`** → `Future<bool>` (alert / badge / sound).
- **`show({id, title, body, payload})`** — a standard notification.
- **`showChat({id, senderName, body, avatar, payload})`** — Communication Notification (iOS 15+).
- **`cancel(id)` / `cancelAll()`** — dismiss one notification, or all of them.

## Install

```yaml
dependencies:
  dartnative_notifications: ^1.0.0   # from dartpub.dev
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
import 'package:dartnative_notifications/dartnative_notifications.dart';
```

Set up tap handling, ask for permission, then fire one:

```dart
DartNativeNotifications.setup(onTap: (payload) => openRoute(payload));
await DartNativeNotifications.requestPermission();

DartNativeNotifications.show(
  id: 'welcome',
  title: 'Welcome 👋',
  body: 'Thanks for installing.',
  payload: '/home',
);
```

A chat-style Communication Notification (iOS 15+):

```dart
DartNativeNotifications.showChat(
  id: 'msg-42',
  senderName: 'Ada',
  body: 'See you at 5?',
  avatar: avatarBytes, // Uint8List
);
```

## Platform setup

The [`example/`](./example) is wired up exactly as below — copy from it.

### iOS

Basic notifications need no setup — the prompt comes from `requestPermission()`.

`showChat` uses iOS 15+ Communication Notifications, which need **two** things on your app target:

1. The **Communication Notifications** capability (Xcode → Signing & Capabilities → +; it adds an
   entry to `Runner.entitlements`).
2. The send-message intent declared in `ios/Runner/Info.plist`:
   ```xml
   <key>NSUserActivityTypes</key>
   <array>
     <string>INSendMessageIntent</string>
   </array>
   ```

Without both, `showChat` falls back to a plain notification.

### Android

The `POST_NOTIFICATIONS` (Android 13+) and `VIBRATE` permissions are declared **for you** (merged
from the plugin manifest); the runtime prompt comes from `requestPermission()`.

Notification **taps are delivered automatically** — the plugin watches the Activity lifecycle
(`Application.ActivityLifecycleCallbacks`) and reads the tap `Intent` itself, so you no longer
forward `handleIntent`. A few small things remain:

1. **`setIntent(intent)` in `onNewIntent`.** Automatic with `DartNativeActivity` — the base class
   already does it. Only a CUSTOM activity (not extending `DartNativeActivity`) needs the standard
   one-liner:
   ```kotlin
   override fun onNewIntent(intent: Intent) {
     super.onNewIntent(intent)
     setIntent(intent)   // required for warm notification taps
   }
   ```

2. **`android:launchMode="singleTop"`** on your Activity in `AndroidManifest.xml`, so a warm tap
   reuses the running Activity (via `onNewIntent`) instead of stacking a duplicate:
   ```xml
   <activity … android:launchMode="singleTop" >
   ```

3. **A small-notification icon** (`notification_icon`). **This one matters** — get it wrong and the
   status-bar / banner icon shows as a **solid black (or grey) square**.

   Android tints the small icon using **only its alpha channel**: every non-transparent pixel is
   painted the notification colour, transparent pixels stay clear. A full-colour, fully-opaque icon
   (e.g. your launcher icon) therefore becomes one solid tinted rectangle. The icon must be a
   **white silhouette on a transparent background** — the logo shape opaque (white), everything else
   fully transparent.

   Create `notification_icon.png` at these sizes and drop one in each density folder:

   | folder                     | size (px) |
   |----------------------------|-----------|
   | `res/drawable-mdpi/`       | 24 × 24   |
   | `res/drawable-hdpi/`       | 36 × 36   |
   | `res/drawable-xhdpi/`      | 48 × 48   |
   | `res/drawable-xxhdpi/`     | 72 × 72   |
   | `res/drawable-xxxhdpi/`    | 96 × 96   |

   Tips: keep ~12–15% transparent padding so the glyph isn't clipped; the RGB colour is irrelevant
   (only alpha is used), but exporting it white avoids surprises. From a logo that already has a
   transparent background you can generate all five with Python/Pillow:

   ```python
   from PIL import Image
   src = Image.open("logo_on_transparent.png").convert("RGBA")
   glyph = src.crop(src.getchannel("A").getbbox())          # tight-crop to the shape
   white = Image.new("RGBA", glyph.size, (255, 255, 255, 255))
   white.putalpha(glyph.getchannel("A"))                    # white where the logo is
   for folder, s in {"mdpi":24,"hdpi":36,"xhdpi":48,"xxhdpi":72,"xxxhdpi":96}.items():
       white.resize((s, s), Image.LANCZOS).save(f"res/drawable-{folder}/notification_icon.png")
   ```

   The plugin resolves it for you — you don't pass an icon name. It looks up `notification_icon`,
   then `app_icon`, and only falls back to the (square-looking) launcher icon if neither exists:

   ```kotlin
   // DNNotificationsBridge.kt
   NotificationCompat.Builder(ctx, CHANNEL_ID)
       .setSmallIcon(smallIconRes(ctx))    // @drawable/notification_icon → @drawable/app_icon → launcher
       .setColor(notificationColor(ctx))   // @color/notification_color if defined, else system default
       …

   private fun smallIconRes(ctx: Context): Int {
       for (name in listOf("notification_icon", "app_icon")) {
           val id = ctx.resources.getIdentifier(name, "drawable", ctx.packageName)
           if (id != 0) return id
       }
       return ctx.applicationInfo.icon    // ← full-colour launcher = the grey/black square
   }
   ```

4. **(Optional) Brand tint.** Define `<color name="notification_color">#FF2C5FEC</color>` in
   `res/values/colors.xml` to tint the small icon + app-name label. Omit it for the system default
   (usually white, which reads best on a dark shade).

> **Chat avatars** (`showChat`) need no setup — if you don't pass avatar bytes, the plugin uses your
> app's launcher icon for the sender, so the avatar slot never shows a black square.

> **Using this plugin's `requestPermission()`**? The permission result is delivered
> **automatically**: `DartNativeActivity` dispatches activity events to plugins
> (`DNActivityEvents` in the core runtime) and this plugin self-registers — without it the
> permission Future would wait forever. Only a CUSTOM activity (not extending
> `DartNativeActivity`) still forwards manually:
> ```kotlin
> override fun onRequestPermissionsResult(
>   requestCode: Int, permissions: Array<out String>, grantResults: IntArray,
> ) {
>   super.onRequestPermissionsResult(requestCode, permissions, grantResults)
>   com.dartnative.notifications.DNNotificationsBridge.onRequestPermissionsResult(requestCode, grantResults)
> }
> ```

## Example

The [`example/`](./example) app posts standard and chat-style notifications — borrow from it
freely.

## Credits & license

Android side ported from
[`flutter_local_notifications`](https://github.com/MaikuB/flutter_local_notifications) (BSD-3-Clause);
iOS built on `UNUserNotificationCenter`.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
