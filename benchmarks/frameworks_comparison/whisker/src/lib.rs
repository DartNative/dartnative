//! Everbloom — a small Storefront shop app built with Whisker.

mod api;
mod screens;
mod state;
mod ui;

use screens::{Cart, CollectionScreen, Home, ProductScreen, SearchScreen};
use state::AppState;
use ui::*;
use whisker::css::{FontWeight, PositionKind};
use whisker::prelude::*;
use whisker_router::{Outlet, Router, routes, use_group, use_navigator, use_pathname};
use whisker_safe_area::safe_area_insets;

#[whisker::main]
pub fn app() -> Element {
    render! { Root }
}

#[component]
fn root() -> Element {
    provide_context(AppState::new());
    render! {
        View(
            style: col()
                .flex_grow(1.0)
                .width(vw(100))
                .height(vh(100))
                .background_color(color(BACKGROUND)),
        ) {
            Router(
                routes: routes! {
                    Route(component: TabsLayout) {
                        Switch {
                            Route(path: "(home)") {
                                Stack {
                                    Route(path: "", component: Home)
                                    Route(path: "collection/:handle", component: CollectionScreen)
                                    Route(path: "product/:handle", component: ProductScreen)
                                }
                            }
                            Route(path: "(search)") {
                                Stack {
                                    Route(path: "search", component: SearchScreen)
                                    Route(path: "product/:handle", component: ProductScreen)
                                }
                            }
                            Route(path: "(cart)") {
                                Stack {
                                    Route(path: "cart", component: Cart)
                                }
                            }
                        }
                    }
                },
            ) {
                Outlet {
                }
            }
        }
    }
}

#[component]
fn tabs_layout() -> Element {
    provide_context(ShellOwner(whisker::Owner::current().expect("owner")));
    let pathname = use_pathname();
    let show_bar = computed(move || !pathname.get().contains("/product/"));
    render! {
        View(style: col().flex_grow(1.0).background_color(color(BACKGROUND))) {
            View(style: col().flex_grow(1.0).flex_shrink(1.0).min_height(px(0))) {
                Outlet {
                }
            }
            Show(when: move || show_bar.get()) {
                TabBar
            }
        }
    }
}

#[component]
fn tab_bar() -> Element {
    let insets = safe_area_insets();
    let style = computed(move || {
        row()
            .align_items(AlignItems::Stretch)
            .height(px(49.0 + insets.get().bottom as f32))
            .padding_bottom(px(insets.get().bottom as f32))
            .border_top(border_line())
            .background_color(color(BACKGROUND))
            .flex_shrink(0.0)
    });
    render! {
        View(style: style) {
            TabItem(group: "home", target: "/(home)", label: "Home", svg: ICON_HOME)
            TabItem(group: "search", target: "/(search)", label: "Search", svg: ICON_SEARCH)
            TabItem(group: "cart", target: "/(cart)", label: "Cart", svg: ICON_CART)
            CartBadge
        }
    }
}

#[component]
fn tab_item(
    group: &'static str,
    target: &'static str,
    label: &'static str,
    svg: &'static str,
) -> Element {
    let nav = use_navigator();
    let current = use_group();
    let active = computed(move || current.get().as_deref().unwrap_or("home") == group);
    let tint = computed(move || format!("#{:06X}", if active.get() { TEXT } else { TEXT_MUTED }));
    let label_style = computed(move || {
        text(
            11.0,
            if active.get() { 600 } else { 500 },
            if active.get() { TEXT } else { TEXT_MUTED },
        )
    });
    render! {
        View(
            accessibility: button_id(format!("tab-{group}")).label(label),
            style: col()
                .flex_grow(1.0)
                .flex_basis(px(0))
                .align_items(AlignItems::Center)
                .justify_content(JustifyContent::Center)
                .gap(px(2)),
            on_tap: move |_| {
                let _ = nav.navigate(target);
            },
        ) {
            whisker_svg::Svg(
                content: svg,
                color: tint,
                style: Css::new().width(px(24)).height(px(24)),
            )

            Text(value: label, style: label_style)
        }
    }
}

/// Cart quantity badge, drawn over the Cart tab icon as a sibling of the tab
/// button so it stays its own accessibility element.
#[component]
fn cart_badge() -> Element {
    let nav = StoredValue::new(use_navigator());
    let state = use_context::<AppState>().expect("AppState");
    let count = computed(move || state.total_quantity());
    render! {
        Show(when: move || count.get() > 0) {
            View(
                accessibility: computed(move || id("cart-badge").label(count.get().to_string())),
                style: row()
                    .position(PositionKind::Absolute)
                    .top(px(4))
                    .left(percent(83.333))
                    .margin_left(px(6))
                    .min_width(px(18))
                    .height(px(18))
                    .padding((px(0), px(5)))
                    .border_radius(px(9))
                    .justify_content(JustifyContent::Center)
                    .background_color(color(SALE)),
                on_tap: move |_| {
                    nav.with(|n| {
                        let _ = n.navigate("/(cart)");
                    })
                },
            ) {
                Text(
                    value: computed(move || count.get().to_string()),
                    style: Css::new()
                        .font_size(px(11))
                        .font_weight(FontWeight::Bold)
                        .color(color(BACKGROUND)),
                )
            }
        }
    }
}
