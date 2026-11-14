//! The icons drawn in the design, as SVG: their strokes take the element's
//! text color (`currentColor`).

use nsh_core::{element::ImageSrc, prelude::*};

const HOME: &str = r#"<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/></svg>"#;
const SEARCH: &str = r#"<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>"#;
const CART: &str = r#"<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M6 7h12l-1 13H7z"/><path d="M9 7a3 3 0 0 1 6 0"/></svg>"#;
const BACK: &str = r#"<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="m15 5-7 7 7 7"/></svg>"#;
const MINUS: &str = r#"<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M5 12h14"/></svg>"#;
const PLUS: &str = r#"<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>"#;
const CART_EMPTY: &str = r#"<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.25" stroke-linecap="round" stroke-linejoin="round"><path d="M6 7h12l-1 13H7z"/><path d="M9 7a3 3 0 0 1 6 0"/></svg>"#;
const ALERT: &str = r#"<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.25" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 7.5v5.5"/><path d="M12 16.5h.01"/></svg>"#;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Icon {
    Home,
    Search,
    Cart,
    Back,
    Minus,
    Plus,
    CartEmpty,
    Alert,
}

impl Icon {
    fn markup(self) -> &'static str {
        match self {
            Icon::Home => HOME,
            Icon::Search => SEARCH,
            Icon::Cart => CART,
            Icon::Back => BACK,
            Icon::Minus => MINUS,
            Icon::Plus => PLUS,
            Icon::CartEmpty => CART_EMPTY,
            Icon::Alert => ALERT,
        }
    }
}

/// `icon` at `size` points, stroked in `color`.
pub fn icon(icon: Icon, size: f32, color: impl IntoReactive<AdaptiveColor>) -> Svg {
    svg(ImageSrc::svg_markup(icon.markup()))
        .size(px(size))
        .text_color(color)
}
