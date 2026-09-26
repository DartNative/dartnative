# Parity

A DartNative app looks identical to a native app. These screens show it:
the same widgets, added with their default values and no customisation,
once in DartNative and once in the platform's own toolkit. Run both on a
phone and compare.

| Folder | What it is |
|---|---|
| `dartnative/` | the DartNative app, one screen, the same code on Android and iOS |
| `android/kotlin/` | the same screen in Kotlin with Material 3 |
| `ios/swiftui/` | the same screen in SwiftUI |

Run the DartNative app from `dartnative/` with `dn run`. Build the Kotlin
app from `android/kotlin/` with `./gradlew installDebug` (Android Studio
opens the folder as a project). Open `ios/swiftui/Parity.xcodeproj` in
Xcode and run it (`project.yml` regenerates the project with xcodegen).
The button at the right of each screen's bar switches between light and
dark in place, so both themes are compared from one install.

The three screens share one layout: the same spacing between rows and the
same margins around them, in points on iOS and dp on Android. Only the
widgets differ, each the platform's own at its defaults, so that is what
the comparison shows.

One colour is set on purpose, on Android: the system navigation strip at
the bottom takes the colour of what sits above it, the tab bar, or a sheet
while one is open, so the bottom of the screen reads as one surface.
DartNative does this by itself; the Kotlin screen sets it by hand from the
tab bar's and the sheet's own colours.

iOS has no checkbox, radio button, card, floating action button or centre
dialog, and SwiftUI has no tinted or outlined button style: those rows are
DartNative's own and have no line in the SwiftUI screen. The wavy
progress indicators are Material's, so the DartNative screen shows them
on Android only. Material has no neutral grey button, so that row has no
line in the Kotlin screen.
