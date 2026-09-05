# DartNative tutorials

Hands-on tutorials, each a **complete, runnable app** in its own folder. Copy
a folder, `dn pub get`, `dn run` — building and testing is free.

Every tutorial has a matching step-by-step article on
[dartnative.com/tutorials](https://dartnative.com/tutorials); the code here is
the finished result the article builds toward.

| Tutorial | Folder | What it teaches |
|---|---|---|
| Layout that thinks in widgets | [`layout_basics/`](layout_basics/) | Row/Column/Stack/Padding/Expanded — Flutter's layout rules on native views |
| Navigation & routes | [`navigation/`](navigation/) | Push/pop, named routes, modal transitions, native back gestures |
| State, from setState up | [`state/`](state/) | setState, `signal` + `watch`, `Provided<T>` subtree values |
| Build the chat screen | [`chat_screen/`](chat_screen/) | Reverse lists, native keyboard choreography, the input bar, Liquid Glass polish |
| Photo grid, infinitely | [`photo_grid/`](photo_grid/) | FastGrid + masonry, infinite scroll, decode sizing, content windowing |
| Lists that never jank | [`fast_list/`](fast_list/) | FastList pagination, stableItems, keepAliveCount, index scrolling |
| A story viewer with Hero | [`hero_stories/`](hero_stories/) | Shared-element morphs, `RouteTransition.none`, drag-to-close |
| Search done right | [`search_app_bar/`](search_app_bar/) | `AppBar.searchBar` — Apple in-place search + the M3 search view |
| Liquid Glass, the real one | [`liquid_glass/`](liquid_glass/) | GlassEffectContainer/Group, regular vs clear, the clear large-title bar |
| Material 3 & dynamic color | [`material_you/`](material_you/) | DynamicColor palettes, real M3 badges, hide-on-scroll bar |
| Charts on the native canvas | [`native_canvas/`](native_canvas/) | CustomPaint on Core Graphics / android.graphics.Canvas |
| Native video playback | [`video_player/`](video_player/) | AVPlayer/ExoPlayer, controls, caching, controller-driven UI |
| Storage, all four kinds | [`storage/`](storage/) | Preferences, secure storage, Hive, SQLite — over FFI |
| Sign in with Apple & Google | [`social_sign_in/`](social_sign_in/) | The real auth sheets, provider config, token handling |
| Notifications, local & push | [`notifications/`](notifications/) | Permission, local alerts, chat-style banners, FCM tokens |
| A camera screen | [`camera/`](camera/) | AVFoundation/CameraX preview, capture, flash, flip |
| Lottie in the hierarchy | [`lottie/`](lottie/) | Controller-driven animations + a CDN sticker grid |
| On-device text-to-speech | [`text_to_speech/`](text_to_speech/) | SuperTonic-3 over ONNX — 31 languages, streamed PCM playback |
| A native map | [`google_maps/`](google_maps/) | The real Google Maps SDK view, markers, camera moves |
| Build a plugin | [`build_a_plugin/`](build_a_plugin/) | The full plugin anatomy via the open-source share plugin — FFI bindings, Swift/Kotlin bridges, hot-restart-safe callbacks |

## Running a tutorial

```sh
cd chat_screen
dn pub get
dn run          # picks up a connected device or simulator
```

Requirements: the `dn` CLI ([dartpub.dev](https://dartpub.dev)) and Xcode
(iOS) or an Android SDK.

## Porting with an AI assistant

The [`skills/`](../skills/) folder ships instruction files for coding
assistants: `dart-native` (the framework guide) and `dart-native-porting`
(the Flutter-porting playbook). Hand both to your assistant and it can port
screens, apply the API diffs, and fix the classic build failures.
