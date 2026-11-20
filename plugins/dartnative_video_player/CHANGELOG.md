## 1.3.2

- On iOS, a video left before it finished downloading now shows its first
  frame at once when it plays again.
- On Android, a player created before `runApp` keeps playing after a hot
  restart.
- On Android, player events that arrive during a hot restart no longer reach
  the restarted app.

## 1.3.1

- On iOS, opening several cached videos at once, as a feed does, no longer
  freezes the app for a moment.

## 1.3.0

- Videos can now play in Picture in Picture on iOS and Android.
- Videos can keep playing in the background, with play and pause on the lock
  screen.
- On iOS, the new `AirPlayButton` sends the video to a TV the user picks.

## 1.0.1

- On Android, the next video in a feed is already showing when it slides in.
- On Android, a cached video now plays from the phone instead of the network.
- On iOS, a video that runs out of buffer now waits and resumes instead of
  freezing.

## 1.0.0

- First release: play videos with the platform's own player on iOS and
  Android, with pre-caching and built-in or custom controls.
