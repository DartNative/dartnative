use crate::api::{self, ProductCard, ProductDetail, ProductOption, Variant};
use crate::screens::Load;
use crate::state::AppState;
use crate::ui::*;
use whisker::css::{BorderStyle, Overflow, PositionKind, TextDecorationLine, TextDecorationStyle};
use whisker::prelude::*;
use whisker_router::{use_navigator, use_param};
use whisker_safe_area::safe_area_insets;

#[component]
pub fn product_screen() -> Element {
    let owner = current_owner();
    let handle = use_param("handle").get_untracked().unwrap_or_default();
    let data = signal(Load::<ProductDetail>::Loading);
    let generation = StoredValue::new(0u64);
    let handle_store = StoredValue::new(handle);
    let load = move || {
        let g = generation.update(|g| {
            *g += 1;
            *g
        });
        data.set(Load::Loading);
        let handle = handle_store.get();
        spawn_in(owner, async move {
            let result = api::product(handle).await;
            if generation.get() != g {
                return;
            }
            data.set(match result {
                Ok(d) => Load::Ready(d),
                Err(_) => Load::Failed,
            });
        });
    };
    load();

    let insets = safe_area_insets();
    let status = computed(move || data.with(|d| d.kind()));
    let content = render! {
        View(
            style: col()
                .flex_grow(1.0)
                .min_height(px(0))
                .background_color(color(BACKGROUND)),
        ) {
            Show(when: move || status.get() == 2) {
                ProductContent(detail: data.with_untracked(|d| d.ready().cloned()).expect("ready"))
            }
            Show(when: move || status.get() == 0) {
                {product_skeleton()}
            }
            Show(when: move || status.get() == 1) {
                View(
                    style: computed(move || {
                        col()
                            .flex_grow(1.0)
                            .padding_top(px(insets.get().top as f32 + 44.0))
                    }),
                ) {
                    ErrorState(on_retry: move |_| load())
                }
            }
            BackButton
        }
    };
    stacked_screen(content, format!("/product/{}", handle_store.get()), None)
}

#[component]
fn back_button() -> Element {
    let nav = use_navigator();
    let insets = safe_area_insets();
    render! {
        View(
            accessibility: button_id("back").label("Back"),
            style: computed(move || {
                row()
                    .position(PositionKind::Absolute)
                    .top(px(insets.get().top as f32))
                    .left(px(12))
                    .width(px(40))
                    .height(px(40))
                    .border_radius(px(20))
                    .justify_content(JustifyContent::Center)
                    .background_color(color(BACKGROUND))
            }),
            on_tap: move |_| {
                let _ = nav.back();
            },
        ) {
            Icon(svg: ICON_BACK, tint: TEXT, size: 22.0)
        }
    }
}

fn product_skeleton() -> Element {
    View::builder()
        .style(col().gap(px(12)))
        .body(|b| {
            b.push(skeleton(
                Css::new().width(percent(100)).aspect_ratio(3.0, 4.0),
            ));
            b.push(skeleton(
                Css::new()
                    .margin((px(8), px(16), px(0)))
                    .width(percent(70))
                    .height(px(22))
                    .border_radius(px(4)),
            ));
            b.push(skeleton(
                Css::new()
                    .margin((px(0), px(16)))
                    .width(px(80))
                    .height(px(20))
                    .border_radius(px(4)),
            ));
        })
        .build()
}

fn initial_variant(variants: &[Variant]) -> usize {
    variants
        .iter()
        .position(|v| v.available_for_sale)
        .unwrap_or(0)
}

fn visible_options(options: &[ProductOption]) -> Vec<ProductOption> {
    options
        .iter()
        .filter(|o| {
            !(o.name == "Title"
                && o.option_values.len() == 1
                && o.option_values[0].name == "Default Title")
        })
        .cloned()
        .collect()
}

/// Index of the variant matching the current selection with `name` set to
/// `value`; falls back to the first variant carrying that value.
fn pick_variant(variants: &[Variant], current: usize, name: &str, value: &str) -> Option<usize> {
    let base = variants.get(current)?;
    let wanted: Vec<(String, String)> = base
        .selected_options
        .iter()
        .map(|o| {
            if o.name == name {
                (o.name.clone(), value.to_string())
            } else {
                (o.name.clone(), o.value.clone())
            }
        })
        .collect();
    variants
        .iter()
        .position(|v| {
            wanted.iter().all(|(n, val)| {
                v.selected_options
                    .iter()
                    .any(|o| &o.name == n && &o.value == val)
            })
        })
        .or_else(|| {
            variants.iter().position(|v| {
                v.selected_options
                    .iter()
                    .any(|o| o.name == name && o.value == value)
            })
        })
}

#[component]
fn product_content(detail: ProductDetail) -> Element {
    let state = use_context::<AppState>().expect("AppState");
    let nav = use_navigator();
    let insets = safe_area_insets();
    let variants = StoredValue::new(detail.variants.clone());
    let selected = signal(initial_variant(&detail.variants));
    let variant = computed(move || variants.with(|v| v.get(selected.get()).cloned()));
    let price_text = computed(move || variant.get().map(|v| v.price.display()).unwrap_or_default());
    let on_sale = computed(move || {
        variant.get().is_some_and(|v| {
            v.compare_at_price
                .as_ref()
                .is_some_and(|c| c.value() > v.price.value())
        })
    });
    let compare_text = computed(move || {
        variant
            .get()
            .and_then(|v| v.compare_at_price.map(|c| c.display()))
            .unwrap_or_default()
    });
    let price_style = computed(move || text(20.0, 700, if on_sale.get() { SALE } else { TEXT }));
    let button_label = computed(move || format!("Add to cart · {}", price_text.get()));
    let busy = state.cart_busy;
    let button_style = computed(move || {
        row()
            .height(px(52))
            .border_radius(px(12))
            .justify_content(JustifyContent::Center)
            .background_color(color(TEXT))
            .opacity(if busy.get() { 0.5 } else { 1.0 })
    });
    let button_a11y = computed(move || {
        button_id("add-to-cart")
            .label(button_label.get())
            .state(AccessibilityState::new().disabled(busy.get()))
    });
    let bar_style = computed(move || {
        col()
            .padding((px(12), px(16), px((insets.get().bottom as f32).max(12.0))))
            .border_top(border_line())
            .background_color(color(BACKGROUND))
            .flex_shrink(0.0)
    });

    let options: Vec<Element> = visible_options(&detail.options)
        .into_iter()
        .map(|option| {
            render! { OptionPicker(option: option, variants: variants, selected: selected) }
        })
        .collect();
    let recommendations: Vec<(usize, ProductCard)> =
        detail.recommendations.iter().cloned().enumerate().collect();
    let has_recs = !recommendations.is_empty();
    let recommendations = StoredValue::new(recommendations);
    let description = StoredValue::new(detail.description.clone());
    let title = detail.title.clone();
    let images = detail.images.clone();
    let has_description = description.with(|d| !d.is_empty());

    let add = move |_| {
        if busy.get_untracked() {
            return;
        }
        let Some(v) = variant.get_untracked() else {
            return;
        };
        let nav = nav.clone();
        state.spawn(async move {
            if state.add(v.id).await {
                let _ = nav.navigate("/(cart)");
            }
        });
    };

    render! {
        View(style: col().flex_grow(1.0).min_height(px(0))) {
            ScrollView(style: Css::new().flex_grow(1.0).min_height(px(0))) {
                View(style: col().padding_bottom(px(24))) {
                    Carousel(images: images)
                    View(style: col().padding((px(20), px(16), px(0))).gap(px(6))) {
                        Text(value: title, style: text(22.0, 700, TEXT).line_height(px(28)))
                        View(style: row().align_items(AlignItems::Baseline).gap(px(6))) {
                            Text(value: price_text, style: price_style)
                            Show(when: move || on_sale.get()) {
                                Text(
                                    value: compare_text,
                                    style: text(15.0, 400, TEXT_MUTED).text_decoration(
                                        TextDecorationLine::LineThrough,
                                        TextDecorationStyle::Solid,
                                        color(TEXT_MUTED),
                                    ),
                                )
                            }
                        }
                    }
                    ..options
                    Show(when: move || has_description) {
                        View(style: col().padding((px(24), px(16), px(0)))) {
                            Text(
                                value: "Description",
                                style: text(15.0, 600, TEXT).margin_bottom(px(8)),
                            )
                            Text(
                                value: description.get(),
                                style: text(15.0, 400, TEXT_BODY).line_height(px(22)),
                            )
                        }
                    }
                    Show(when: move || has_recs) {
                        View(style: col().padding_top(px(32))) {
                            Text(
                                value: "You may also like",
                                style: text(17.0, 700, TEXT)
                                    .padding((px(0), px(16)))
                                    .margin_bottom(px(12)),
                            )
                            ScrollView(
                                axis: ScrollAxis::Horizontal,
                                style: Css::new().flex_shrink(0.0),
                            ) {
                                View(
                                    style: row()
                                        .align_items(AlignItems::FlexStart)
                                        .gap(px(12))
                                        .padding((px(0), px(16))),
                                ) {
                                    ForEach(
                                        each: move || recommendations.get(),
                                        key: |p: &(usize, ProductCard)| p.0,
                                        children: |p: ReadSignal<(usize, ProductCard)>| {
                                            let p = p.get_untracked();
                                            render! {
                                                CarouselProduct(
                                                    product: p.1,
                                                    test_id: format!("recommendation-{}", p.0),
                                                )
                                            }
                                        },
                                    )
                                }
                            }
                        }
                    }
                }
            }
            View(style: bar_style) {
                View(accessibility: button_a11y, style: button_style, on_tap: add) {
                    Text(value: button_label, max_lines: 1u32, style: text(16.0, 600, BACKGROUND))
                }
            }
        }
    }
}

#[component]
fn carousel(images: Vec<String>) -> Element {
    let page = signal(0usize);
    let count = images.len();
    let scroller = ScrollViewHandle::new();
    let width = StoredValue::new(390.0f64);
    let pages: Vec<Element> = images
        .iter()
        .take(10)
        .map(|url| {
            render! {
                Photo(
                    url: url.clone(),
                    width: 1080,
                    style: Css::new()
                        .width(vw(100))
                        .aspect_ratio(3.0, 4.0)
                        .flex_shrink(0.0),
                )
            }
        })
        .collect();
    let dot_count = if count > 1 { count.min(10) } else { 0 };
    let dots: Vec<Element> = (0..dot_count)
        .map(|i| {
            let dot_style = computed(move || {
                Css::new()
                    .width(px(8))
                    .height(px(8))
                    .border_radius(px(4))
                    .background_color(if page.get() == i {
                        color(TEXT)
                    } else {
                        Color::rgba(28, 27, 25, 0.25)
                    })
            });
            render! {
                View(
                    style: row()
                        .width(px(24))
                        .height(px(24))
                        .justify_content(JustifyContent::Center),
                    on_tap: move |_| scroller.scroll_to(width.get() * i as f64, true),
                ) {
                    View(style: dot_style)
                }
            }
        })
        .collect();
    render! {
        View(
            style: col()
                .width(percent(100))
                .aspect_ratio(3.0, 4.0)
                .background_color(color(SURFACE))
                .overflow(Overflow::Hidden),
        ) {
            ScrollView(
                accessibility: id("product-carousel"),
                element_ref: scroller.r(),
                axis: ScrollAxis::Horizontal,
                snap: ScrollSnap::start(),
                scroll_snap_stop: ScrollSnapStop::Always,
                style: Css::new().width(percent(100)).height(percent(100)),
                on_scroll: move |e: whisker::event::ScrollEvent| {
                    let d = e.detail;
                    if d.viewport_width > 0.0 {
                        width.set(d.viewport_width);
                        let p = (d.scroll_left / d.viewport_width).round().max(0.0) as usize;
                        if page.get_untracked() != p {
                            page.set(p);
                        }
                    }
                },
            ) {
                ..pages
            }
            View(
                style: row()
                    .position(PositionKind::Absolute)
                    .left(px(0))
                    .right(px(0))
                    .bottom(px(12))
                    .justify_content(JustifyContent::Center)
                    .gap(px(4)),
            ) {
                ..dots
            }
        }
    }
}

#[component]
fn option_picker(
    option: ProductOption,
    variants: StoredValue<Vec<Variant>>,
    selected: RwSignal<usize>,
) -> Element {
    let name = option.name.clone();
    let label_text = format!("{}: ", option.name);
    let current_value = {
        let name = name.clone();
        computed(move || {
            variants.with(|vs| {
                vs.get(selected.get())
                    .and_then(|v| {
                        v.selected_options
                            .iter()
                            .find(|o| o.name == name)
                            .map(|o| o.value.clone())
                    })
                    .unwrap_or_default()
            })
        })
    };
    let pills: Vec<Element> = option
        .option_values
        .iter()
        .map(|value| {
            let value = value.name.clone();
            let name = name.clone();
            let is_on = {
                let value = value.clone();
                computed(move || current_value.get() == value)
            };
            let style = computed(move || {
                let on = is_on.get();
                row()
                    .min_width(px(56))
                    .height(px(44))
                    .padding((px(0), px(16)))
                    .border_radius(px(12))
                    .justify_content(JustifyContent::Center)
                    .border(
                        Border::new()
                            .width(px(if on { 2.0 } else { 1.0 }))
                            .style(BorderStyle::Solid)
                            .color(color(if on { TEXT } else { BORDER })),
                    )
                    .background_color(color(BACKGROUND))
            });
            let label_style = computed(move || text(15.0, if is_on.get() { 600 } else { 500 }, TEXT));
            let test_id = format!("option-{name}-{value}");
            let a11y = {
                let value = value.clone();
                computed(move || {
                    button_id(test_id.clone())
                        .label(value.clone())
                        .state(AccessibilityState::new().selected(is_on.get()))
                })
            };
            let label = value.clone();
            render! {
                View(
                    accessibility: a11y,
                    style: style,
                    on_tap: move |_| {
                        let next = variants.with(|vs| pick_variant(vs, selected.get_untracked(), &name, &value));
                        if let Some(i) = next {
                            selected.set(i);
                        }
                    },
                ) {
                    Text(value: label, max_lines: 1u32, style: label_style)
                }
            }
        })
        .collect();
    render! {
        View(style: col().margin_top(px(24)).padding((px(0), px(16)))) {
            View(style: row().padding_bottom(px(12))) {
                Text(value: label_text, style: text(15.0, 600, TEXT))
                Text(value: current_value, style: text(15.0, 400, TEXT_MUTED))
            }
            View(style: row().flex_wrap(FlexWrap::Wrap).gap(px(8))) {
                ..pills
            }
        }
    }
}
