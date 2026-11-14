# The README banner

`../dartnative-banner-phones.png`, the banner at the top of the repository's
README, is rendered from `banner.html` in this folder:

```sh
sh docs/assets/banner/render.sh
```

It needs Google Chrome, and the Geist font from Google Fonts (the page loads
it, so the render needs a network connection).

- **Text:** the logo (`dn-logo.svg`) and the name, the headline and the line
  of tags are plain HTML in `banner.html`; edit them there and render again.
- **Phones:** `screens/` holds one picture per phone, in the order the page
  shows them: music player, chat, lyrics over video, photo picker, video
  feed, stickers keyboard, cover flow. They are the playground's Showcase
  demos on an iPhone, 328 x 688 each. To change a phone, replace its
  picture with another of the same size, or point its `<img>` at a new
  one.
- **Size:** 1280 x 600, rendered at twice the scale (2560 x 1200). The
  phones start 292 px from the top; the text sits above them on plain
  black.
