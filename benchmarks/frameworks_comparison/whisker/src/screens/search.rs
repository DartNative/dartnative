use crate::api::{self, ProductCard};
use crate::screens::Status;
use crate::ui::*;
use whisker::css::TextAlign;
use whisker::prelude::*;
use whisker_input::{AutoCapitalize, Input, ReturnKey};
use whisker_router::use_navigator;
use whisker_safe_area::safe_area_insets;

#[component]
pub fn search_screen() -> Element {
    let owner = current_owner();
    let query = signal(String::new());
    let status = signal(Status::Idle);
    let results = signal(Vec::<(usize, ProductCard)>::new());
    let total = signal(0i64);
    let current = StoredValue::new(String::new());
    let cursor = StoredValue::new(None::<String>);
    let has_next = StoredValue::new(false);
    let loading_more = signal(false);
    // Bumped for every new query; responses for older generations are dropped.
    let generation = StoredValue::new(0u64);
    let debounce = StoredValue::new(0u64);

    let run = move |q: String| {
        let g = generation.update(|g| {
            *g += 1;
            *g
        });
        loading_more.set(false);
        results.set(Vec::new());
        current.set(q.clone());
        if q.is_empty() {
            status.set(Status::Idle);
            return;
        }
        status.set(Status::Loading);
        spawn_in(owner, async move {
            let result = api::search(q, None).await;
            if generation.get() != g {
                return;
            }
            match result {
                Ok(page) => {
                    total.set(page.total_count);
                    cursor.set(page.page_info.end_cursor);
                    has_next.set(page.page_info.has_next_page);
                    results.set(page.products.into_iter().enumerate().collect());
                    status.set(Status::Ready);
                }
                Err(_) => status.set(Status::Failed),
            }
        });
    };

    let on_input = move |value: String| {
        let token = debounce.update(|d| {
            *d += 1;
            *d
        });
        let q = value.trim().to_string();
        if q.is_empty() {
            run(q);
            return;
        }
        spawn_in(owner, async move {
            shop_native::sleep_ms(300).await;
            if debounce.get() == token {
                run(q);
            }
        });
    };

    let fetch_more = move || {
        if loading_more.get_untracked()
            || status.get_untracked() != Status::Ready
            || !has_next.get()
        {
            return;
        }
        loading_more.set(true);
        let g = generation.get();
        let q = current.get();
        let after = cursor.get();
        spawn_in(owner, async move {
            let result = api::search(q, after).await;
            if generation.get() != g {
                return;
            }
            if let Ok(page) = result {
                cursor.set(page.page_info.end_cursor);
                has_next.set(page.page_info.has_next_page);
                results.update(|items| {
                    let start = items.len();
                    items.extend(
                        page.products
                            .into_iter()
                            .enumerate()
                            .map(|(i, p)| (start + i, p)),
                    );
                });
            }
            loading_more.set(false);
        });
    };

    on_mount(move || {
        spawn_in(owner, async move {
            for _ in 0..20 {
                if shop_native::tag_text_field("search-input") {
                    break;
                }
                shop_native::sleep_ms(100).await;
            }
        });
    });

    let insets = safe_area_insets();
    let keyboard = whisker_keyboard::keyboard_height();
    let content = render! {
        View(
            style: computed(move || {
                // Keep the results above the keyboard; the tab bar (49 + inset) is
                // already below this screen.
                let tab_bar = 49.0 + insets.get().bottom;
                let overlap = (keyboard.get() - tab_bar).max(0.0);
                col()
                    .flex_grow(1.0)
                    .min_height(px(0))
                    .padding_top(px(insets.get().top as f32))
                    .padding_bottom(px(overlap as f32))
            }),
        ) {
            View(style: col().padding((px(4), px(16), px(12))).flex_shrink(0.0)) {
                View(
                    style: row()
                        .height(px(44))
                        .border_radius(px(12))
                        .background_color(color(SURFACE))
                        .gap(px(8))
                        .padding((px(0), px(12))),
                ) {
                    Icon(svg: ICON_SEARCH, tint: TEXT_MUTED, size: 20.0)
                    Input(
                        text: query,
                        on_input: on_input,
                        on_submit: move |_| whisker_keyboard::dismiss(),
                        placeholder: "Search products",
                        placeholder_color: "#6E6A63",
                        return_key: ReturnKey::Search,
                        auto_capitalize: AutoCapitalize::None,
                        autocorrect: false,
                        style: Css::new()
                            .flex_grow(1.0)
                            .flex_shrink(1.0)
                            .min_width(px(0))
                            .height(px(44))
                            .font_size(px(16))
                            .color(color(TEXT)),
                    )
                }
            }
            Show(when: move || status.get() == Status::Idle) {
                View(style: col().padding((px(48), px(32)))) {
                    Text(
                        value: "Search across 995 products by name.",
                        style: text(15.0, 400, TEXT_MUTED)
                            .line_height(px(22))
                            .text_align(TextAlign::Center),
                    )
                }
            }
            Show(when: move || status.get() == Status::Loading) {
                {spinner()}
            }
            Show(when: move || status.get() == Status::Failed) {
                ErrorState(on_retry: move |_| run(current.get()))
            }
            Show(when: move || status.get() == Status::Ready) {
                View(style: col().flex_grow(1.0).min_height(px(0))) {
                    Text(
                        value: computed(move || format!("{} results", total.get())),
                        style: text(13.0, 400, TEXT_MUTED).padding((px(4), px(16), px(8))),
                    )
                    List(
                        accessibility: id("search-results"),
                        style: Css::new().flex_grow(1.0).min_height(px(0)),
                        content_style: col().padding_bottom(px(16)),
                        each: move || results.get(),
                        key: |p: &(usize, ProductCard)| p.0,
                        children: |p: ReadSignal<(usize, ProductCard)>| {
                            let (index, product) = p.get_untracked();
                            render! { SearchRow(index: index, product: product) }
                        },
                        footer: move || render! {
                            View(style: col()) {
                                Show(when: move || loading_more.get()) {
                                    {spinner()}
                                }
                            }
                        },
                        on_scroll: move |e: whisker::event::ScrollEvent| {
                            let d = e.detail;
                            if d.is_dragging {
                                whisker_keyboard::dismiss();
                            }
                            if d.scroll_top + d.viewport_height >= d.scroll_height - d.viewport_height {
                                fetch_more();
                            }
                        },
                        on_end_reached: move || fetch_more(),
                        end_reached_threshold: 600.0,
                    )
                }
            }
        }
    };
    stacked_screen(content, "/search".to_string(), Some("search"))
}

#[component]
fn search_row(index: usize, product: ProductCard) -> Element {
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
    let a11y = button_id(format!("search-result-{index}")).label(title.clone());
    render! {
        View(
            accessibility: a11y,
            style: row().gap(px(12)).padding((px(8), px(16))),
            on_tap: move |_| {
                let _ = nav.push(&format!("/product/{handle}"));
            },
        ) {
            Photo(
                url: image,
                width: 240,
                style: Css::new()
                    .width(px(64))
                    .height(px(85))
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
                Text(value: title, style: text(15.0, 400, TEXT).line_height(px(20)))
                PriceRow(price: price, compare_at: compare_at, size: 15.0)
            }
        }
    }
}
