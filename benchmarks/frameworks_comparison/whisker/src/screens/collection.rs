use crate::api::{self, ProductCard, Sort};
use crate::screens::Status;
use crate::state::AppState;
use crate::ui::*;
use whisker::css::{BorderStyle, Overflow};
use whisker::prelude::*;
use whisker_router::use_param;
use whisker_safe_area::safe_area_insets;

const SORTS: [(Sort, &str, &str); 4] = [
    (Sort::Featured, "Featured", "sort-featured"),
    (Sort::BestSelling, "Best selling", "sort-best-selling"),
    (Sort::PriceAsc, "Price: low to high", "sort-price-asc"),
    (Sort::PriceDesc, "Price: high to low", "sort-price-desc"),
];

#[component]
pub fn collection_screen() -> Element {
    let owner = current_owner();
    let state = use_context::<AppState>().expect("AppState");
    let handle = use_param("handle").get_untracked().unwrap_or_default();
    let cached_title = state
        .collection_titles
        .with(|t| t.iter().find(|(h, _)| *h == handle).map(|(_, t)| t.clone()))
        .unwrap_or_default();
    let title = signal(cached_title);
    let description = signal(String::new());
    let sort = signal(Sort::Featured);
    let status = signal(Status::Loading);
    let products = signal(Vec::<(usize, ProductCard)>::new());
    let cursor = StoredValue::new(None::<String>);
    let has_next = StoredValue::new(false);
    let loading_more = signal(false);
    let generation = StoredValue::new(0u64);
    let handle_store = StoredValue::new(handle);

    let fetch_first = move || {
        let g = generation.update(|g| {
            *g += 1;
            *g
        });
        status.set(Status::Loading);
        loading_more.set(false);
        products.set(Vec::new());
        let handle = handle_store.get();
        let current_sort = sort.get_untracked();
        spawn_in(owner, async move {
            let result = api::collection_products(handle, current_sort, None).await;
            if generation.get() != g {
                return;
            }
            match result {
                Ok(page) => {
                    title.set(page.title);
                    description.set(page.description);
                    cursor.set(page.page_info.end_cursor);
                    has_next.set(page.page_info.has_next_page);
                    products.set(page.products.into_iter().enumerate().collect());
                    status.set(Status::Ready);
                }
                Err(_) => status.set(Status::Failed),
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
        let handle = handle_store.get();
        let current_sort = sort.get_untracked();
        let after = cursor.get();
        spawn_in(owner, async move {
            let result = api::collection_products(handle, current_sort, after).await;
            if generation.get() != g {
                return;
            }
            if let Ok(page) = result {
                cursor.set(page.page_info.end_cursor);
                has_next.set(page.page_info.has_next_page);
                products.update(|items| {
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

    fetch_first();

    let sort_chips: Vec<Element> = SORTS
        .iter()
        .map(|(value, label, test_id)| {
            let value = *value;
            render! {
                SortChip(
                    label: *label,
                    test_id: *test_id,
                    selected: computed(move || sort.get() == value),
                    on_pick: move |_| {
                        if sort.get_untracked() != value {
                            sort.set(value);
                            fetch_first();
                        }
                    },
                )
            }
        })
        .collect();

    let insets = safe_area_insets();
    let content = render! {
        View(
            style: computed(move || {
                col()
                    .flex_grow(1.0)
                    .min_height(px(0))
                    .padding_top(px(insets.get().top as f32))
            }),
        ) {
            NavBar(title: title)
            Show(when: move || description.with(|d| !d.is_empty())) {
                View(style: col().padding((px(4), px(16), px(0))).flex_shrink(0.0)) {
                    Text(
                        value: description,
                        style: text(14.0, 400, TEXT_MUTED).line_height(px(20)),
                    )
                }
            }
            ScrollView(axis: ScrollAxis::Horizontal, style: Css::new().flex_shrink(0.0)) {
                View(style: row().gap(px(8)).padding((px(12), px(16)))) {
                    ..sort_chips
                }
            }
            Show(when: move || status.get() == Status::Failed) {
                ErrorState(on_retry: move |_| fetch_first())
            }
            Show(when: move || status.get() == Status::Loading) {
                View(style: col().flex_grow(1.0).overflow(Overflow::Hidden)) {
                    {skeleton_grid(4)}
                }
            }
            Show(when: move || status.get() == Status::Ready) {
                List(
                    accessibility: id("product-grid"),
                    style: Css::new().flex_grow(1.0).min_height(px(0)),
                    content_style: two_column_grid().padding((px(0), px(16), px(24))),
                    each: move || products.get(),
                    key: |p: &(usize, ProductCard)| p.0,
                    children: |p: ReadSignal<(usize, ProductCard)>| {
                        let (index, product) = p.get_untracked();
                        render! {
                            ProductTile(product: product, test_id: format!("product-card-{index}"))
                        }
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
                        if d.scroll_top + d.viewport_height >= d.scroll_height - d.viewport_height {
                            fetch_more();
                        }
                    },
                    on_end_reached: move || fetch_more(),
                    end_reached_threshold: 600.0,
                )
            }
        }
    };
    stacked_screen(content, format!("/collection/{}", handle_store.get()), None)
}

#[component]
fn sort_chip(
    label: &'static str,
    test_id: &'static str,
    selected: Signal<bool>,
    on_pick: Callback<()>,
) -> Element {
    let style = computed(move || {
        let on = selected.get();
        row()
            .flex_shrink(0.0)
            .height(px(32))
            .padding((px(0), px(12)))
            .border_radius(px(16))
            .border(
                Border::new()
                    .width(px(1))
                    .style(BorderStyle::Solid)
                    .color(color(if on { TEXT } else { BORDER })),
            )
            .background_color(color(if on { TEXT } else { BACKGROUND }))
    });
    let label_style = computed(move || {
        let on = selected.get();
        text(
            13.0,
            if on { 600 } else { 500 },
            if on { BACKGROUND } else { TEXT },
        )
    });
    let a11y = computed(move || {
        button_id(test_id)
            .label(label)
            .state(AccessibilityState::new().selected(selected.get()))
    });
    render! {
        View(accessibility: a11y, style: style, on_tap: move |_| on_pick.call()) {
            Text(value: label, max_lines: 1u32, style: label_style)
        }
    }
}
