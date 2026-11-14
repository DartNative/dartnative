//! Design tokens and shared components.

use crate::api::{self, Money, ProductCard};
use whisker::css::{
    Animation, AnimationIterationCount, BorderStyle, EasingFunction, FontWeight, GridTemplate,
    GridTrack, Keyframes, Overflow, PositionKind, TextAlign, TextDecorationLine,
    TextDecorationStyle, TransformFn,
};
use whisker::prelude::*;
use whisker_image::{Image, ImageMode};
use whisker_router::use_navigator;
use whisker_svg::Svg;

pub const BACKGROUND: u32 = 0xFFFFFF;
pub const SURFACE: u32 = 0xF4F1EC;
pub const SKELETON: u32 = 0xEDE9E3;
pub const BORDER: u32 = 0xE6E1D9;
pub const TEXT: u32 = 0x1C1B19;
pub const TEXT_MUTED: u32 = 0x6E6A63;
pub const TEXT_BODY: u32 = 0x3D3A35;
pub const SALE: u32 = 0xB4361E;

pub const ICON_HOME: &str = r#"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/></svg>"#;
pub const ICON_SEARCH: &str = r#"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>"#;
pub const ICON_CART: &str = r#"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M6 7h12l-1 13H7z"/><path d="M9 7a3 3 0 0 1 6 0"/></svg>"#;
pub const ICON_CART_LIGHT: &str = r#"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.25" stroke-linecap="round" stroke-linejoin="round"><path d="M6 7h12l-1 13H7z"/><path d="M9 7a3 3 0 0 1 6 0"/></svg>"#;
pub const ICON_BACK: &str = r#"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="m15 5-7 7 7 7"/></svg>"#;
pub const ICON_ALERT: &str = r#"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.25" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 7.5v5.5"/><path d="M12 16.5h.01"/></svg>"#;
pub const ICON_MINUS: &str = r#"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M5 12h14"/></svg>"#;
pub const ICON_PLUS: &str = r#"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>"#;

pub fn color(hex: u32) -> Color {
    Color::hex(hex)
}

pub fn col() -> Css {
    Css::new()
        .display(Display::Flex)
        .flex_direction(FlexDirection::Column)
}

pub fn row() -> Css {
    Css::new()
        .display(Display::Flex)
        .flex_direction(FlexDirection::Row)
        .align_items(AlignItems::Center)
}

pub fn text(size: f32, weight: u16, hex: u32) -> Css {
    Css::new()
        .font_size(px(size))
        .font_weight(FontWeight::Numeric(weight))
        .color(color(hex))
}

pub fn border_line() -> Border {
    Border::new()
        .width(px(1))
        .style(BorderStyle::Solid)
        .color(color(BORDER))
}

pub fn id(identifier: impl Into<String>) -> Accessibility {
    Accessibility::new().identifier(identifier)
}

pub fn button_id(identifier: impl Into<String>) -> Accessibility {
    Accessibility::new()
        .identifier(identifier)
        .role(AccessibilityRole::Button)
}

/// One column of the 2-column grid: (screen width - 2*16 padding - 12 gap) / 2.
pub fn grid_card_width() -> whisker::css::LengthPercentage {
    use whisker::css::CalcExpr;
    whisker::css::LengthPercentage::calc(CalcExpr::value(vw(50)).sub(CalcExpr::value(px(22))))
}

pub fn two_column_grid() -> Css {
    Css::new()
        .display(Display::Grid)
        .grid_template_columns(GridTemplate::tracks([
            GridTrack::fraction(1.0),
            GridTrack::fraction(1.0),
        ]))
        .column_gap(px(12))
        .row_gap(px(20))
}

/// Vector icon drawn from the design's SVG paths.
#[component]
pub fn icon(svg: &'static str, tint: u32, size: f32) -> Element {
    render! {
        Svg(
            content: svg,
            color: format!("#{tint:06X}"),
            style: Css::new().width(px(size)).height(px(size)).flex_shrink(0.0),
        )
    }
}

/// Remote image cropped (aspect-fill) into the parent-provided frame with
/// the `surface` color until it loads.
#[component]
pub fn photo(url: String, width: i32, style: Css) -> Element {
    let src = if url.is_empty() {
        String::new()
    } else {
        api::sized(&url, width as u32)
    };
    render! {
        View(
            style: style
                .clone()
                .background_color(color(SURFACE))
                .overflow(Overflow::Hidden),
        ) {
            Show(
                when: {
                    let has = !src.is_empty();
                    move || has
                },
            ) {
                Image(
                    src: src.clone(),
                    mode: ImageMode::AspectFill,
                    style: Css::new().width(percent(100)).height(percent(100)),
                )
            }
        }
    }
}

/// Price, in `sale` color with the struck-through compare-at price when the
/// compare-at amount is higher.
#[component]
pub fn price_row(price: Money, compare_at: Option<Money>, size: f32) -> Element {
    let on_sale = compare_at
        .as_ref()
        .is_some_and(|c| c.value() > price.value());
    let price_text = price.display();
    let compare_text = compare_at.as_ref().map(|c| c.display()).unwrap_or_default();
    render! {
        View(style: row().align_items(AlignItems::Baseline).gap(px(6))) {
            Text(
                value: price_text,
                style: text(size, 700, if on_sale { SALE } else { TEXT }),
            )
            Show(when: move || on_sale) {
                Text(
                    value: compare_text.clone(),
                    style: text(13.0, 400, TEXT_MUTED).text_decoration(
                        TextDecorationLine::LineThrough,
                        TextDecorationStyle::Solid,
                        color(TEXT_MUTED),
                    ),
                )
            }
        }
    }
}

/// Grid card: 3:4 image, two-line title, price.
#[component]
pub fn product_tile(product: ProductCard, test_id: String) -> Element {
    let nav = use_navigator();
    let handle = product.handle.clone();
    let image = product
        .featured_image
        .as_ref()
        .map(|i| i.url.clone())
        .unwrap_or_default();
    let title = product.title.clone();
    let price = product.price().clone();
    let compare_at = product.compare_at().clone();
    let a11y = button_id(test_id.clone()).label(title.clone());
    render! {
        View(
            accessibility: a11y,
            style: col().gap(px(8)).width(grid_card_width()),
            on_tap: move |_| {
                let _ = nav.push(&format!("/product/{handle}"));
            },
        ) {
            Photo(
                url: image,
                width: 480,
                style: Css::new()
                    .width(percent(100))
                    .aspect_ratio(3.0, 4.0)
                    .border_radius(px(8)),
            )
            Text(
                value: title,
                max_lines: 2u32,
                style: text(14.0, 400, TEXT).line_height(px(18)),
            )
            PriceRow(price: price, compare_at: compare_at, size: 15.0)
        }
    }
}

/// Horizontal-carousel card (140 wide) used for recommendations.
#[component]
pub fn carousel_product(product: ProductCard, test_id: String) -> Element {
    let nav = use_navigator();
    let handle = product.handle.clone();
    let image = product
        .featured_image
        .as_ref()
        .map(|i| i.url.clone())
        .unwrap_or_default();
    let title = product.title.clone();
    let price = product.price().clone();
    let compare_at = product.compare_at().clone();
    let a11y = button_id(test_id.clone()).label(title.clone());
    render! {
        View(
            accessibility: a11y,
            style: col().width(px(140)).flex_shrink(0.0).gap(px(6)),
            on_tap: move |_| {
                let _ = nav.push(&format!("/product/{handle}"));
            },
        ) {
            Photo(
                url: image,
                width: 480,
                style: Css::new()
                    .width(px(140))
                    .height(px(187))
                    .border_radius(px(8)),
            )
            Text(
                value: title,
                max_lines: 2u32,
                style: text(14.0, 400, TEXT).line_height(px(18)),
            )
            PriceRow(price: price, compare_at: compare_at, size: 14.0)
        }
    }
}

pub fn skeleton(style: Css) -> Element {
    View::builder()
        .style(style.background_color(color(SKELETON)).flex_shrink(0.0))
        .build()
}

/// Two-column grid of placeholder cards.
pub fn skeleton_grid(count: usize) -> Element {
    View::builder()
        .style(two_column_grid().padding((px(0), px(16))))
        .body(|body| {
            for _ in 0..count {
                body.push(
                    View::builder()
                        .style(col().gap(px(8)))
                        .body(|card| {
                            card.push(skeleton(
                                Css::new()
                                    .width(percent(100))
                                    .aspect_ratio(3.0, 4.0)
                                    .border_radius(px(8)),
                            ));
                            card.push(skeleton(
                                Css::new()
                                    .width(percent(80))
                                    .height(px(14))
                                    .border_radius(px(4)),
                            ));
                            card.push(skeleton(
                                Css::new().width(px(56)).height(px(14)).border_radius(px(4)),
                            ));
                        })
                        .build(),
                );
            }
        })
        .build()
}

/// Small rotating ring shown while a page is loading.
pub fn spinner() -> Element {
    let spin = Keyframes::builder()
        .named("spin")
        .from(Css::new().transform(TransformFn::Rotate(deg(0.0).into())))
        .to(Css::new().transform(TransformFn::Rotate(deg(360.0).into())))
        .build()
        .expect("valid keyframes");
    View::builder()
        .style(
            row()
                .justify_content(JustifyContent::Center)
                .padding((px(16), px(0))),
        )
        .body(|body| {
            body.push(
                View::builder()
                    .style(
                        Css::new()
                            .width(px(22))
                            .height(px(22))
                            .border_radius(px(11))
                            .border(
                                Border::new()
                                    .width(px(2))
                                    .style(BorderStyle::Solid)
                                    .color(color(BORDER)),
                            )
                            .border_top_color(color(TEXT))
                            .animation(
                                Animation::new(spin)
                                    .duration(ms(800.0))
                                    .timing(EasingFunction::Linear)
                                    .iteration_count(AnimationIterationCount::Infinite),
                            ),
                    )
                    .build(),
            )
        })
        .build()
}

/// "Couldn't load products" state with a Retry button.
#[component]
pub fn error_state(on_retry: Callback<()>) -> Element {
    render! {
        View(
            style: col()
                .flex_grow(1.0)
                .align_items(AlignItems::Center)
                .justify_content(JustifyContent::Center)
                .gap(px(12))
                .padding((px(0), px(32))),
        ) {
            Icon(svg: ICON_ALERT, tint: TEXT_MUTED, size: 48.0)
            Text(value: "Couldn’t load products", style: text(17.0, 700, TEXT))
            Text(
                value: "Check your connection and try again.",
                style: text(15.0, 400, TEXT_MUTED)
                    .line_height(px(22))
                    .text_align(TextAlign::Center),
            )
            View(
                accessibility: button_id("error-retry"),
                style: row()
                    .margin_top(px(8))
                    .height(px(48))
                    .padding((px(0), px(24)))
                    .border_radius(px(12))
                    .border(
                        Border::new()
                            .width(px(1))
                            .style(BorderStyle::Solid)
                            .color(color(TEXT)),
                    )
                    .background_color(color(BACKGROUND)),
                on_tap: move |_| on_retry.call(),
            ) {
                Text(value: "Retry", style: text(16.0, 600, TEXT))
            }
        }
    }
}

/// 44pt navigation bar with a back button and a centered title.
#[component]
pub fn nav_bar(title: Signal<String>) -> Element {
    let nav = use_navigator();
    render! {
        View(
            style: row()
                .height(px(44))
                .padding((px(0), px(8)))
                .flex_shrink(0.0),
        ) {
            View(
                accessibility: button_id("back").label("Back"),
                style: row()
                    .width(px(44))
                    .height(px(44))
                    .justify_content(JustifyContent::Center),
                on_tap: move |_| {
                    let _ = nav.back();
                },
            ) {
                Icon(svg: ICON_BACK, tint: TEXT, size: 24.0)
            }
            Text(
                value: title,
                max_lines: 1u32,
                style: text(17.0, 600, TEXT)
                    .flex_grow(1.0)
                    .flex_shrink(1.0)
                    .text_align(TextAlign::Center),
            )
            View(style: Css::new().width(px(44)).height(px(44)))
        }
    }
}

pub fn absolute_fill() -> Css {
    Css::new()
        .position(PositionKind::Absolute)
        .top(px(0))
        .left(px(0))
        .right(px(0))
        .bottom(px(0))
}

/// Owner of the tab layout: inside the Router, but never paused by a Stack.
#[derive(Clone, Copy)]
pub struct ShellOwner(pub whisker::Owner);

/// Wraps a screen that lives in a Stack. While another screen covers it, the
/// wrapper hides its subtree from accessibility so automation identifiers
/// stay unique. The flag is computed under the never-paused shell owner,
/// because the Stack pauses the covered screen's own owner.
///
/// `path` is the screen's own public location; `group` its tab (`None` takes
/// the tab active when the screen mounts, which is right for pushed screens).
pub fn stacked_screen(content: Element, path: String, group: Option<&'static str>) -> Element {
    let shell = use_context::<ShellOwner>().expect("ShellOwner").0;
    let owner = whisker::Owner::new(Some(shell));
    on_cleanup(move || owner.dispose());
    owner.with(|| {
        let current_path = whisker_router::use_pathname();
        let current_group = whisker_router::use_group();
        let mine = group
            .map(str::to_string)
            .or_else(|| current_group.get_untracked())
            .unwrap_or_else(|| "home".to_string());
        let a11y = computed(move || {
            let same_tab = current_group.get().as_deref().unwrap_or("home") == mine;
            Accessibility::new().hidden(same_tab && current_path.get() != path)
        });
        View::builder()
            .style(
                col()
                    .flex_grow(1.0)
                    .min_height(px(0))
                    .background_color(color(BACKGROUND)),
            )
            .accessibility(a11y)
            .child(content)
            .build()
    })
}

/// Spawns `future` under `owner`, so it is cancelled only when that owner
/// goes away (a task is otherwise cancelled with the transient owner of the
/// event handler that started it, e.g. a Retry button that unmounts on tap).
pub fn spawn_in(owner: whisker::Owner, future: impl std::future::Future<Output = ()> + 'static) {
    owner.with(|| spawn_local(future));
}

pub fn current_owner() -> whisker::Owner {
    whisker::Owner::current().expect("inside a component")
}
