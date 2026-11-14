//! The design tokens of `spec/design/screens/Tokens.dc.html`: every color
//! and text style the screens use comes from here.

use nsh_core::prelude::*;

/// Screen background.
pub fn page_bg() -> Rgba {
    rgb(0xFFFFFF)
}
/// Image placeholder, chips, search field.
pub fn surface() -> Rgba {
    rgb(0xF4F1EC)
}
/// Loading blocks.
pub fn skeleton() -> Rgba {
    rgb(0xEDE9E3)
}
/// Dividers, outlines, bars.
pub fn border() -> Rgba {
    rgb(0xE6E1D9)
}
/// Text, primary button, selection.
pub fn text_color() -> Rgba {
    rgb(0x1C1B19)
}
/// Secondary text, inactive tabs.
pub fn text_muted() -> Rgba {
    rgb(0x6E6A63)
}
/// The product description's text.
pub fn text_body() -> Rgba {
    rgb(0x3D3A35)
}
/// Sale price, cart badge.
pub fn sale() -> Rgba {
    rgb(0xB4361E)
}
/// The featured banner's caption band: `text` at 72 %.
pub fn scrim() -> Rgba {
    rgba(0x1C1B19B8)
}
/// An inactive page dot: `text` at 25 %.
pub fn dot_inactive() -> Rgba {
    rgba(0x1C1B1940)
}

/// Screen horizontal padding.
pub const GUTTER: f32 = 16.0;

/// A text in the system font at `size` points, in `weight`, `text` colored.
pub fn label(content: impl IntoReactive<SharedString>, size: f32, weight: FontWeight) -> Text {
    text(content)
        .text_size(px(size))
        .font_weight(weight)
        .text_color(text_color())
}
