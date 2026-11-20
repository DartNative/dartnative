## 1.0.4

- On Android, a notification tap that opened the app is no longer reported a
  second time when the app is reopened.

## 1.0.3

- A tap or a permission answer that arrives during a hot restart no longer
  reaches the restarted app.
- On Android, asking for permission while the system dialog is already up
  now waits for that dialog's answer.
- On Android, an interrupted permission dialog no longer asks the user to
  turn notifications on in Settings.

## 1.0.2

- Apps now build for the iOS simulator with Xcode 26.

## 1.0.1

- Apps now build with Xcode 27.

## 1.0.0

- First release: show local notifications on iOS and Android, with tap
  handling and chat-style notifications that show the sender's picture.
