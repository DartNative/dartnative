use crate::api::CartLine;
use crate::state::AppState;
use crate::ui::*;
use whisker::css::{BorderStyle, TextAlign};
use whisker::prelude::*;
use whisker_router::use_navigator;
use whisker_safe_area::safe_area_insets;

#[component]
pub fn cart() -> Element {
    let state = use_context::<AppState>().expect("AppState");
    let nav = StoredValue::new(use_navigator());
    let insets = safe_area_insets();
    let lines = computed(move || {
        state.cart.with(|c| {
            c.as_ref()
                .map(|c| c.lines().iter().cloned().enumerate().collect::<Vec<_>>())
                .unwrap_or_default()
        })
    });
    let empty = computed(move || lines.with(|l| l.is_empty()));
    let subtotal = computed(move || {
        state.cart.with(|c| {
            c.as_ref()
                .map(|c| c.subtotal().display())
                .unwrap_or_default()
        })
    });
    let checkout = move |_| {
        let url = state
            .cart
            .with_untracked(|c| c.as_ref().map(|c| c.checkout_url.clone()));
        if let Some(url) = url {
            state.spawn(async move {
                let _ = whisker_web_browser::open_browser_async(&url).await;
            });
        }
    };
    render! {
        View(
            style: computed(move || {
                col()
                    .flex_grow(1.0)
                    .min_height(px(0))
                    .padding_top(px(insets.get().top as f32))
            }),
        ) {
            View(
                style: row()
                    .height(px(44))
                    .padding((px(0), px(16)))
                    .flex_shrink(0.0),
            ) {
                Text(value: "Cart", style: text(22.0, 700, TEXT))
            }
            Show(
                when: move || empty.get(),
                fallback: move || render! {
                    View(style: col().flex_grow(1.0).min_height(px(0))) {
                        ScrollView(style: Css::new().flex_grow(1.0).min_height(px(0))) {
                            View(style: col().padding((px(0), px(16)))) {
                                ForEach(
                                    each: move || lines.get(),
                                    key: |l: &(usize, CartLine)| {
                                        (
                                            l.0,
                                            l.1.id.clone(),
                                            l.1.quantity,
                                            l.1.total().amount.clone(),
                                        )
                                    },
                                    children: |l: ReadSignal<(usize, CartLine)>| {
                                        let l = l.get_untracked();
                                        render! { CartLineRow(index: l.0, line: l.1) }
                                    },
                                )
                            }
                        }
                        View(
                            style: col()
                                .padding(px(16))
                                .gap(px(12))
                                .border_top(border_line())
                                .background_color(color(BACKGROUND))
                                .flex_shrink(0.0),
                        ) {
                            View(
                                style: row()
                                    .justify_content(JustifyContent::SpaceBetween)
                                    .align_items(AlignItems::Baseline),
                            ) {
                                Text(value: "Subtotal", style: text(15.0, 400, TEXT))
                                Text(
                                    accessibility: computed(move || id("cart-subtotal").label(subtotal.get())),
                                    value: subtotal,
                                    style: text(17.0, 700, TEXT),
                                )
                            }
                            Text(
                                value: "Taxes and shipping are calculated at checkout.",
                                style: text(13.0, 400, TEXT_MUTED),
                            )
                            View(
                                accessibility: button_id("checkout").label("Check out"),
                                style: row()
                                    .height(px(52))
                                    .border_radius(px(12))
                                    .justify_content(JustifyContent::Center)
                                    .background_color(color(TEXT)),
                                on_tap: checkout,
                            ) {
                                Text(value: "Check out", style: text(16.0, 600, BACKGROUND))
                            }
                        }
                    }
                },
            ) {
                View(
                    style: col()
                        .flex_grow(1.0)
                        .align_items(AlignItems::Center)
                        .justify_content(JustifyContent::Center)
                        .gap(px(12))
                        .padding((px(0), px(32))),
                ) {
                    Icon(svg: ICON_CART_LIGHT, tint: TEXT_MUTED, size: 48.0)
                    Text(value: "Your cart is empty", style: text(17.0, 700, TEXT))
                    Text(
                        value: "Items you add will appear here.",
                        style: text(15.0, 400, TEXT_MUTED)
                            .line_height(px(22))
                            .text_align(TextAlign::Center),
                    )
                    View(
                        style: row()
                            .margin_top(px(8))
                            .height(px(48))
                            .padding((px(0), px(24)))
                            .border_radius(px(12))
                            .background_color(color(TEXT)),
                        on_tap: move |_| {
                            nav.with(|n| {
                                let _ = n.navigate("/(home)");
                            })
                        },
                    ) {
                        Text(value: "Start shopping", style: text(16.0, 600, BACKGROUND))
                    }
                }
            }
        }
    }
}

#[component]
fn cart_line_row(index: usize, line: CartLine) -> Element {
    let state = use_context::<AppState>().expect("AppState");
    let busy = state.cart_busy;
    let image = line
        .merchandise
        .image
        .as_ref()
        .or(line.merchandise.product.featured_image.as_ref())
        .map(|i| i.url.clone())
        .unwrap_or_default();
    let variant_title = line.merchandise.title.clone();
    let show_variant = variant_title != "Default Title";
    let quantity = line.quantity;
    let product_title = line.merchandise.product.title.clone();
    let total = line.total().display();
    let dec_id = line.id.clone();
    let inc_id = line.id.clone();
    let stepper_button = move || {
        row()
            .width(px(36))
            .height(px(34))
            .justify_content(JustifyContent::Center)
    };
    render! {
        View(
            accessibility: id(format!("cart-line-{index}")),
            style: row()
                .align_items(AlignItems::Stretch)
                .gap(px(12))
                .padding((px(16), px(0)))
                .border_bottom(border_line()),
        ) {
            Photo(
                url: image,
                width: 240,
                style: Css::new()
                    .width(px(80))
                    .height(px(107))
                    .border_radius(px(8))
                    .flex_shrink(0.0),
            )
            View(
                style: col()
                    .flex_grow(1.0)
                    .flex_shrink(1.0)
                    .min_width(px(0))
                    .gap(px(4)),
            ) {
                Text(value: product_title, style: text(15.0, 600, TEXT).line_height(px(20)))
                Show(when: move || show_variant) {
                    Text(value: variant_title.clone(), style: text(13.0, 400, TEXT_MUTED))
                }
                View(
                    style: row()
                        .margin_top(px(8))
                        .flex_grow(1.0)
                        .align_items(AlignItems::FlexEnd)
                        .justify_content(JustifyContent::SpaceBetween),
                ) {
                    View(
                        style: computed(move || {
                            row()
                                .height(px(36))
                                .border(
                                    Border::new()
                                        .width(px(1))
                                        .style(BorderStyle::Solid)
                                        .color(color(BORDER)),
                                )
                                .border_radius(px(12))
                                .opacity(if busy.get() { 0.5 } else { 1.0 })
                        }),
                    ) {
                        View(
                            accessibility: button_id(format!("qty-dec-{index}")).label("Decrease quantity"),
                            style: stepper_button(),
                            on_tap: move |_| state.update(dec_id.clone(), quantity - 1),
                        ) {
                            Icon(svg: ICON_MINUS, tint: TEXT, size: 16.0)
                        }
                        Text(
                            value: quantity.to_string(),
                            style: text(15.0, 600, TEXT)
                                .min_width(px(24))
                                .text_align(TextAlign::Center),
                        )
                        View(
                            accessibility: button_id(format!("qty-inc-{index}")).label("Increase quantity"),
                            style: stepper_button(),
                            on_tap: move |_| state.update(inc_id.clone(), quantity + 1),
                        ) {
                            Icon(svg: ICON_PLUS, tint: TEXT, size: 16.0)
                        }
                    }
                    Text(value: total, style: text(15.0, 700, TEXT))
                }
            }
        }
    }
}
