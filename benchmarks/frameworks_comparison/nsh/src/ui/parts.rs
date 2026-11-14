//! The pieces the screens share: product cards, prices, the navigation bar,
//! chips, skeleton blocks, the error state and the list footer.

use nsh_core::{element::Image, prelude::*};

use super::{
    icons::{Icon, icon},
    tokens::*,
};
use crate::models::{Money, ProductCard, image_url};

/// A remote image, cropped to fill its frame, on `surface` until it loads.
/// A press target: a view in the button role, which UI tests and screen
/// readers see as one element with its test id.
pub fn pressable() -> View {
    view().role(AccessibilityRole::Button)
}

pub fn remote_image(url: String) -> Image {
    image(url)
        .object_fit(ResizeMode::Cover)
        .bg(surface())
        .overflow_hidden()
}

/// A price, in `sale` and followed by the compare-at price struck through
/// when there is one.
pub fn price_row(price: &Money, compare_at: Option<&Money>, size: f32) -> View {
    let on_sale = compare_at.is_some();
    view()
        .flex_row()
        .items_baseline()
        .gap(px(6.0))
        .child(
            label(price.display(), size, FontWeight::BOLD)
                .text_color(if on_sale { sale() } else { text_color() }),
        )
        .child(compare_at.map(|compare| {
            label(compare.display(), 13.0, FontWeight::NORMAL)
                .text_color(text_muted())
                .line_through()
        }))
}

/// A product in a grid: image (3:4), title (two lines at most), price.
pub fn product_card(product: &ProductCard, test_id: &str, on_press: impl Fn() + 'static) -> View {
    pressable()
        .test_id(test_id)
        .label(product.title.clone())
        .on_press(on_press)
        .gap(px(8.0))
        .active(|s| s.opacity(0.7))
        .child(
            remote_image(image_url(product.featured_image.as_ref(), 480))
                .w_full()
                .aspect_ratio(0.75)
                .rounded(px(8.0)),
        )
        .child(
            label(product.title.clone(), 14.0, FontWeight::NORMAL)
                .line_height(px(18.0))
                .number_of_lines(2),
        )
        .child(price_row(product.price(), product.compare_at(), 15.0))
}

/// A product in a horizontal carousel: 140 wide, the image `image_height`
/// tall.
pub fn carousel_card(
    product: &ProductCard,
    test_id: &str,
    image_height: f32,
    on_press: impl Fn() + 'static,
) -> View {
    pressable()
        .test_id(test_id)
        .label(product.title.clone())
        .on_press(on_press)
        .w(px(140.0))
        .gap(px(6.0))
        .active(|s| s.opacity(0.7))
        .child(
            remote_image(image_url(product.featured_image.as_ref(), 480))
                .w(px(140.0))
                .h(px(image_height))
                .rounded(px(8.0)),
        )
        .child(
            label(product.title.clone(), 14.0, FontWeight::NORMAL)
                .line_height(px(18.0))
                .number_of_lines(2),
        )
        .child(label(product.price().display(), 14.0, FontWeight::BOLD))
}

/// The back button: 44 × 44, the chevron in `text`.
pub fn back_button(on_press: impl Fn() + 'static) -> View {
    pressable()
        .test_id("back")
        .label("Back")
        .on_press(on_press)
        .size(px(44.0))
        .items_center()
        .justify_center()
        .active(|s| s.opacity(0.5))
        .child(icon(Icon::Back, 24.0, text_color()))
}

/// A navigation bar 44 tall: back, the title centered, nothing at the end.
pub fn nav_bar(title: impl IntoReactive<SharedString>, on_back: impl Fn() + 'static) -> View {
    view()
        .h(px(44.0))
        .px(px(8.0))
        .flex_row()
        .items_center()
        .child(back_button(on_back))
        .child(
            label(title, 17.0, FontWeight::SEMIBOLD)
                .flex_1()
                .text_center()
                .number_of_lines(1),
        )
        .child(view().size(px(44.0)))
}

/// A screen's header with its title (22 / 700).
pub fn screen_header(title: &'static str) -> View {
    view()
        .h(px(44.0))
        .px(px(GUTTER))
        .flex_row()
        .items_center()
        .child(label(title, 22.0, FontWeight::BOLD).letter_spacing(px(-0.4)))
}

/// A pill: `surface` behind it, or `text` when selected.
pub fn chip(title: impl IntoReactive<SharedString>) -> Text {
    label(title, 14.0, FontWeight::MEDIUM)
}

/// A loading block.
pub fn block(width: Option<f32>, height: f32, radius: f32) -> View {
    let block = view().h(px(height)).rounded(px(radius)).bg(skeleton());
    match width {
        Some(width) => block.w(px(width)),
        None => block,
    }
}

/// The primary button: 52 tall, `text` behind white type.
pub fn primary_button(title: impl IntoReactive<SharedString>) -> View {
    pressable()
        .h(px(52.0))
        .rounded(px(12.0))
        .bg(text_color())
        .items_center()
        .justify_center()
        .active(|s| s.opacity(0.8))
        .disabled_style(|s| s.opacity(0.5))
        .child(label(title, 16.0, FontWeight::SEMIBOLD).text_color(page_bg()))
}

/// A centered message with an icon, a title, a line and a button.
fn notice(
    glyph: Icon,
    title: &'static str,
    body: &'static str,
    action: impl IntoElement,
) -> View {
    view()
        .flex_1()
        .items_center()
        .justify_center()
        .gap(px(12.0))
        .px(px(32.0))
        .child(icon(glyph, 48.0, text_muted()))
        .child(label(title, 17.0, FontWeight::BOLD).text_center())
        .child(
            label(body, 15.0, FontWeight::NORMAL)
                .line_height(px(22.0))
                .text_color(text_muted())
                .text_center(),
        )
        .child(view().mt(px(8.0)).child(action))
}

/// "Couldn't load products", and Retry.
pub fn error_state(on_retry: impl Fn() + 'static) -> View {
    notice(
        Icon::Alert,
        "Couldn't load products",
        "Check your connection and try again.",
        pressable()
            .test_id("error-retry")
            .on_press(on_retry)
            .h(px(48.0))
            .px(px(24.0))
            .rounded(px(12.0))
            .border_1()
            .border_color(text_color())
            .bg(page_bg())
            .items_center()
            .justify_center()
            .active(|s| s.opacity(0.6))
            .child(label("Retry", 16.0, FontWeight::SEMIBOLD)),
    )
}

/// The empty cart, and a way back to the shop.
pub fn empty_cart(on_shop: impl Fn() + 'static) -> View {
    notice(
        Icon::CartEmpty,
        "Your cart is empty",
        "Items you add will appear here.",
        pressable()
            .on_press(on_shop)
            .h(px(48.0))
            .px(px(24.0))
            .rounded(px(12.0))
            .bg(text_color())
            .items_center()
            .justify_center()
            .active(|s| s.opacity(0.8))
            .child(label("Start shopping", 16.0, FontWeight::SEMIBOLD).text_color(page_bg())),
    )
}

/// The end of a list while its next page loads.
pub fn loading_footer() -> View {
    view()
        .py(px(16.0))
        .items_center()
        .child(label("Loading…", 13.0, FontWeight::NORMAL).text_color(text_muted()))
}

/// Skeleton cards of the product grid.
pub fn grid_skeleton() -> View {
    let card = || {
        view()
            .flex_1()
            .gap(px(8.0))
            .child(view().w_full().aspect_ratio(0.75).rounded(px(8.0)).bg(skeleton()))
            .child(block(None, 14.0, 4.0))
            .child(block(Some(60.0), 15.0, 4.0))
    };
    view()
        .px(px(GUTTER))
        .gap(px(20.0))
        .child(
            (0..2)
                .map(|_| view().flex_row().gap(px(12.0)).child(card()).child(card()))
                .collect::<Vec<_>>(),
        )
}
