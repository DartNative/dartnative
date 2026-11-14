use std::sync::atomic::{AtomicBool, Ordering};

use crate::api::{self, Collection, HomeData, ProductCard};
use crate::screens::Load;
use crate::state::AppState;
use crate::ui::*;
use whisker::css::Overflow;
use whisker::prelude::*;
use whisker_router::use_navigator;
use whisker_safe_area::safe_area_insets;

static HOME_READY_LOGGED: AtomicBool = AtomicBool::new(false);

#[component]
pub fn home() -> Element {
    let owner = current_owner();
    let state = use_context::<AppState>().expect("AppState");
    let data = signal(Load::<HomeData>::Loading);
    let generation = StoredValue::new(0u64);
    let load = move || {
        let g = generation.update(|g| {
            *g += 1;
            *g
        });
        data.set(Load::Loading);
        spawn_in(owner, async move {
            let result = api::home().await;
            if generation.get() != g {
                return;
            }
            match result {
                Ok(home) => {
                    state.collection_titles.set(
                        home.collections
                            .iter()
                            .map(|c| (c.handle.clone(), c.title.clone()))
                            .collect(),
                    );
                    data.set(Load::Ready(home));
                }
                Err(_) => data.set(Load::Failed),
            }
        });
    };
    load();

    let insets = safe_area_insets();
    let failed = computed(move || data.with(|d| matches!(d, Load::Failed)));
    let ready = computed(move || data.with(|d| d.ready().cloned()));
    let content = render! {
        View(
            style: computed(move || {
                col()
                    .flex_grow(1.0)
                    .min_height(px(0))
                    .padding_top(px(insets.get().top as f32))
            }),
        ) {
            Show(
                when: move || failed.get(),
                fallback: move || render! {
                    ScrollView(
                        accessibility: id("home-scroll"),
                        style: Css::new().flex_grow(1.0).min_height(px(0)),
                    ) {
                        View(style: col().padding_bottom(px(24))) {
                            HomeHeader
                            Show(
                                when: move || ready.with(|r| r.is_some()),
                                fallback: || home_skeleton(),
                            ) {
                                HomeContent(
                                    data: ready.get_untracked().unwrap_or_else(|| HomeData {
                                        collections: vec![],
                                        products: vec![],
                                    }),
                                )
                            }
                        }
                    }
                },
            ) {
                HomeHeader
                ErrorState(on_retry: move |_| load())
            }
        }
    };
    stacked_screen(content, "/".to_string(), Some("home"))
}

#[component]
fn home_header() -> Element {
    render! {
        View(
            style: row()
                .height(px(44))
                .padding((px(0), px(16)))
                .flex_shrink(0.0),
        ) {
            Text(
                value: "Everbloom",
                style: text(22.0, 700, TEXT).letter_spacing(px(-0.4)),
            )
        }
    }
}

fn home_skeleton() -> Element {
    View::builder()
        .style(col())
        .body(|b| {
            b.push(
                View::builder()
                    .style(row().gap(px(8)).padding((px(8), px(16), px(12))))
                    .body(|r| {
                        for w in [52.0, 110.0, 96.0, 80.0] {
                            r.push(skeleton(
                                Css::new().width(px(w)).height(px(36)).border_radius(px(18)),
                            ));
                        }
                    })
                    .build(),
            );
            b.push(skeleton(
                Css::new()
                    .margin((px(4), px(16), px(0)))
                    .height(px(240))
                    .border_radius(px(12)),
            ));
            b.push(
                View::builder()
                    .style(col().padding((px(28), px(16), px(12))))
                    .body(|r| {
                        r.push(skeleton(
                            Css::new()
                                .width(px(120))
                                .height(px(18))
                                .border_radius(px(4)),
                        ))
                    })
                    .build(),
            );
            b.push(
                View::builder()
                    .style(
                        row()
                            .gap(px(12))
                            .padding((px(0), px(16)))
                            .overflow(Overflow::Hidden),
                    )
                    .body(|r| {
                        for _ in 0..3 {
                            r.push(skeleton(
                                Css::new()
                                    .width(px(140))
                                    .height(px(175))
                                    .border_radius(px(8)),
                            ));
                        }
                    })
                    .build(),
            );
        })
        .build()
}

#[component]
fn home_content(data: HomeData) -> Element {
    on_mount(|| {
        if !HOME_READY_LOGGED.swap(true, Ordering::SeqCst) {
            shop_native::log_line("SHOPBENCH home_ready");
        }
    });
    let featured = data.collections.first().cloned();
    let collections: Vec<(usize, Collection)> =
        data.collections.iter().cloned().enumerate().collect();
    let products: Vec<(usize, ProductCard)> = data.products.iter().cloned().enumerate().collect();
    let chip_items = collections.clone();
    let card_items = collections.clone();
    render! {
        View(style: col()) {
            ScrollView(
                axis: ScrollAxis::Horizontal,
                style: Css::new().flex_shrink(0.0),
            ) {
                View(style: row().gap(px(8)).padding((px(8), px(16), px(12)))) {
                    ForEach(
                        each: move || chip_items.clone(),
                        key: |c: &(usize, Collection)| c.0,
                        children: |c: ReadSignal<(usize, Collection)>| {
                            let c = c.get_untracked();
                            render! { CollectionChip(index: c.0, collection: c.1) }
                        },
                    )
                }
            }
            Show(
                when: {
                    let has = featured.is_some();
                    move || has
                },
            ) {
                FeaturedBanner(collection: featured.clone().expect("featured"))
            }
            View(style: col().padding_top(px(28)).flex_shrink(0.0)) {
                View(style: row().padding((px(0), px(16), px(12)))) {
                    Text(value: "Collections", style: text(17.0, 700, TEXT))
                }
                ScrollView(axis: ScrollAxis::Horizontal, style: Css::new().flex_shrink(0.0)) {
                    View(
                        style: row()
                            .align_items(AlignItems::FlexStart)
                            .gap(px(12))
                            .padding((px(0), px(16))),
                    ) {
                        ForEach(
                            each: move || card_items.clone(),
                            key: |c: &(usize, Collection)| c.0,
                            children: |c: ReadSignal<(usize, Collection)>| {
                                let c = c.get_untracked();
                                render! { CollectionCard(index: c.0, collection: c.1) }
                            },
                        )
                    }
                }
            }
            View(style: col().padding((px(28), px(16), px(0))).flex_shrink(0.0)) {
                Text(value: "Best sellers", style: text(17.0, 700, TEXT).margin_bottom(px(12)))
                View(style: two_column_grid()) {
                    ForEach(
                        each: move || products.clone(),
                        key: |p: &(usize, ProductCard)| p.0,
                        children: |p: ReadSignal<(usize, ProductCard)>| {
                            let p = p.get_untracked();
                            render! {
                                ProductTile(product: p.1, test_id: format!("best-seller-{}", p.0))
                            }
                        },
                    )
                }
            }
        }
    }
}

#[component]
fn collection_chip(index: usize, collection: Collection) -> Element {
    let nav = use_navigator();
    let handle = collection.handle.clone();
    let title = collection.title.clone();
    render! {
        View(
            accessibility: button_id(format!("collection-chip-{index}")).label(title.clone()),
            style: row()
                .flex_shrink(0.0)
                .height(px(36))
                .padding((px(0), px(14)))
                .border_radius(px(18))
                .background_color(color(SURFACE)),
            on_tap: move |_| {
                let _ = nav.push(&format!("/collection/{handle}"));
            },
        ) {
            Text(value: title.clone(), max_lines: 1u32, style: text(14.0, 500, TEXT))
        }
    }
}

#[component]
fn featured_banner(collection: Collection) -> Element {
    let nav = use_navigator();
    let handle = collection.handle.clone();
    let title = collection.title.clone();
    let image = collection
        .image
        .as_ref()
        .map(|i| i.url.clone())
        .unwrap_or_default();
    render! {
        View(
            accessibility: button_id("featured-collection").label(title.clone()),
            style: col()
                .margin((px(4), px(16), px(0)))
                .height(px(240))
                .border_radius(px(12))
                .overflow(Overflow::Hidden)
                .background_color(color(SURFACE))
                .flex_shrink(0.0),
            on_tap: move |_| {
                let _ = nav.push(&format!("/collection/{handle}"));
            },
        ) {
            Photo(
                url: image.clone(),
                width: 1080,
                style: absolute_fill(),
            )
            View(
                style: col()
                    .position(whisker::css::PositionKind::Absolute)
                    .left(px(0))
                    .right(px(0))
                    .bottom(px(0))
                    .padding(px(16))
                    .gap(px(2))
                    .background_color(Color::rgba(28, 27, 25, 0.72)),
            ) {
                Text(
                    value: "FEATURED COLLECTION",
                    style: text(12.0, 600, BACKGROUND).letter_spacing(px(0.6)),
                )
                Text(value: title.clone(), style: text(20.0, 700, BACKGROUND))
                Text(value: "Shop now", style: text(14.0, 400, BACKGROUND))
            }
        }
    }
}

#[component]
fn collection_card(index: usize, collection: Collection) -> Element {
    let nav = use_navigator();
    let handle = collection.handle.clone();
    let title = collection.title.clone();
    let image = collection
        .image
        .as_ref()
        .map(|i| i.url.clone())
        .unwrap_or_default();
    render! {
        View(
            accessibility: button_id(format!("collection-card-{index}")).label(title.clone()),
            style: col().width(px(140)).flex_shrink(0.0).gap(px(8)),
            on_tap: move |_| {
                let _ = nav.push(&format!("/collection/{handle}"));
            },
        ) {
            Photo(
                url: image.clone(),
                width: 480,
                style: Css::new()
                    .width(px(140))
                    .height(px(175))
                    .border_radius(px(8)),
            )
            Text(
                value: title.clone(),
                style: text(14.0, 600, TEXT).line_height(px(18)),
            )
        }
    }
}
