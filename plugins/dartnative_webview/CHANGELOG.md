## 1.0.1

- `onNavigationRequest` now runs before each page loads and can return a
  `Future`.
- A sign-in flow that returns to your app through a custom link now reaches your
  code instead of leaving a blank page.
- `NavigationRequest.isMainFrame` tells you if a navigation is in the main
  frame.

## 1.0.0

- First release: show web pages inside your app with the platform's own web
  view, on iOS and Android.
