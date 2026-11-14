//! A collection: its description, the sort chips and a lazily rendered
//! grid of its products, one page at a time.

use nsh_base::nav_page;
use nsh_core::{element::Screen, prelude::*};

use super::Status;
use crate::{
    api::{self, Sort},
    models::ProductCard,
    nav::{self, Route, StackId},
    spawn_in,
    ui::{parts::*, tokens::*},
};

pub fn collection_page(stack: StackId, handle: String, title: String) -> Screen {
    let owner = Owner::current();
    let handle = SharedString::from(handle);
    let sort = signal(Sort::Featured);
    let status = signal(Status::Loading);
    let description = signal(String::new());
    let products = signal(Vec::<ProductCard>::new());
    let cursor = stored(None::<String>);
    let has_next = stored(false);
    let loading_more = signal(false);
    // Answers to an earlier sort are dropped.
    let generation = stored(0_u64);

    let load_first = {
        let handle = handle.clone();
        move || {
            let current = generation.with(|g| {
                *g += 1;
                *g
            });
            status.set(Status::Loading);
            products.set(Vec::new());
            loading_more.set(false);
            let handle = handle.clone();
            spawn_in(&owner, async move {
                let result = api::collection_products(&handle, sort.get_untracked(), None).await;
                if generation.get() != current {
                    return;
                }
                match result {
                    Ok(page) => {
                        description.set(page.description);
                        cursor.replace(page.products.page_info.end_cursor);
                        has_next.replace(page.products.page_info.has_next_page);
                        products.set(page.products.nodes);
                        status.set(Status::Ready);
                    }
                    Err(_) => status.set(Status::Failed),
                }
            });
        }
    };
    let load_more = {
        let handle = handle.clone();
        move || {
            if loading_more.get_untracked() || !has_next.get() || status.get_untracked() != Status::Ready {
                return;
            }
            let current = generation.get();
            loading_more.set(true);
            let handle = handle.clone();
            let after = cursor.get();
            spawn_in(&owner, async move {
                let result = api::collection_products(&handle, sort.get_untracked(), after).await;
                if generation.get() != current {
                    return;
                }
                if let Ok(page) = result {
                    cursor.replace(page.products.page_info.end_cursor);
                    has_next.replace(page.products.page_info.has_next_page);
                    products.update(|p| p.extend(page.products.nodes));
                }
                loading_more.set(false);
            });
        }
    };
    load_first();

    let sort_chips = {
        let load_first = load_first.clone();
        scroll().horizontal().scrollbar(false).flex_shrink_0().child(
            view()
                .flex_row()
                .gap(px(8.0))
                .py(px(12.0))
                .px(px(GUTTER))
                .child(
                    Sort::ALL
                        .iter()
                        .map(|&option| {
                            let load_first = load_first.clone();
                            let selected = move || sort.get() == option;
                            pressable()
                                .test_id(option.test_id())
                                .on_press(move || {
                                    if sort.get_untracked() != option {
                                        sort.set(option);
                                        load_first();
                                    }
                                })
                                .h(px(32.0))
                                .px(px(12.0))
                                .rounded(px(16.0))
                                .border_1()
                                .justify_center()
                                .border_color(move || if selected() { text_color() } else { border() })
                                .bg(move || if selected() { text_color() } else { page_bg() })
                                .child(dynamic(move || {
                                    let on = selected();
                                    label(option.label(), 13.0, if on { FontWeight::SEMIBOLD } else { FontWeight::MEDIUM })
                                        .number_of_lines(1)
                                        .text_color(if on { page_bg() } else { text_color() })
                                }))
                        })
                        .collect::<Vec<_>>(),
                ),
        )
    };

    let body = dynamic(move || match status.get() {
        Status::Loading => view().flex_1().overflow_hidden().child(grid_skeleton()).into_element(),
        Status::Failed => error_state(load_first.clone()).into_element(),
        Status::Ready => grid(stack, products, loading_more, load_more.clone()).into_element(),
    });

    nav_page().header_visible(false).child(
        view()
            .flex_1()
            .bg(page_bg())
            .pt_safe_area()
            .child(nav_bar(title, move || nav::pop(stack)))
            .child(
                view().pt(px(4.0)).px(px(GUTTER)).child(
                    label(move || SharedString::from(description.get()), 14.0, FontWeight::NORMAL)
                        .line_height(px(20.0))
                        .text_color(text_muted()),
                ),
            )
            .child(sort_chips)
            .child(view().flex_1().child(body)),
    )
}

fn grid(
    stack: StackId,
    products: Signal<Vec<ProductCard>>,
    loading_more: Signal<bool>,
    load_more: impl Fn() + 'static,
) -> impl IntoElement {
    virtual_list(move || products.with(Vec::len), move |at| grid_cell(stack, products, at))
        .columns(2)
        .estimated_item_size(px(300.0))
        .content_padding_x(px(GUTTER))
        .content_padding_bottom(px(16.0))
        .column_gap(px(12.0))
        .row_gap(px(20.0))
        .on_load_more(load_more)
        .footer(view().child(dynamic(move || loading_more.get().then(loading_footer))))
        .test_id("product-grid")
        .flex_1()
}

/// A cell of the grid: made once, given other rows as it is reused, so its
/// card (and its test id) follow the row it shows.
pub fn grid_cell(stack: StackId, products: Signal<Vec<ProductCard>>, at: Position) -> impl IntoElement {
    let product = computed(move || products.with(|p| p.get(at.index()).cloned()));
    view().child(dynamic(move || {
        let index = at.index();
        product.get().map(|product| {
            let handle = product.handle.clone();
            product_card(&product, &format!("product-card-{index}"), move || {
                nav::push(stack, Route::Product { handle: handle.clone() })
            })
        })
    }))
}
