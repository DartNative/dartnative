//! Search: a field sent 300 ms after typing stops, the result count and a
//! lazily rendered list of results, one page at a time.

use std::time::Duration;

use nsh_base::{input, nav_page};
use nsh_core::{element::Screen, prelude::*};

use super::Status;
use crate::{
    api,
    models::{ProductCard, image_url},
    nav::{self, Route, StackId},
    spawn_in,
    ui::{
        icons::{Icon, icon},
        parts::*,
        tokens::*,
    },
};

/// How long typing must pause before the query is sent.
const DEBOUNCE: Duration = Duration::from_millis(300);

/// What the screen shows under the field.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Shown {
    /// The field is empty.
    Hint,
    Results(Status),
}

pub fn search_page() -> Screen {
    let owner = Owner::current();
    let query = signal(String::new());
    let shown = signal(Shown::Hint);
    let results = signal(Vec::<ProductCard>::new());
    let total = signal(0_u32);
    let cursor = stored(None::<String>);
    let has_next = stored(false);
    let loading_more = signal(false);
    // Each edit makes the answers to earlier queries stale.
    let generation = stored(0_u64);

    // Sends `text` as the query after the pause, unless it changed since.
    let run = move |text: String, wait: bool| {
        let current = generation.with(|g| {
            *g += 1;
            *g
        });
        loading_more.set(false);
        if text.is_empty() {
            shown.set(Shown::Hint);
            results.set(Vec::new());
            return;
        }
        spawn_in(&owner, async move {
            if wait {
                timer(DEBOUNCE).await;
                if generation.get() != current {
                    return;
                }
            }
            shown.set(Shown::Results(Status::Loading));
            let answer = api::search(&text, None).await;
            if generation.get() != current {
                return;
            }
            match answer {
                Ok(page) => {
                    total.set(page.total_count);
                    cursor.replace(page.page_info.end_cursor);
                    has_next.replace(page.page_info.has_next_page);
                    results.set(page.products);
                    shown.set(Shown::Results(Status::Ready));
                }
                Err(_) => shown.set(Shown::Results(Status::Failed)),
            }
        });
    };
    let load_more = move || {
        if loading_more.get_untracked()
            || !has_next.get()
            || shown.get_untracked() != Shown::Results(Status::Ready)
        {
            return;
        }
        let current = generation.get();
        let text = query.get_untracked().trim().to_owned();
        let after = cursor.get();
        loading_more.set(true);
        spawn_in(&owner, async move {
            let answer = api::search(&text, after).await;
            if generation.get() != current {
                return;
            }
            if let Ok(page) = answer {
                cursor.replace(page.page_info.end_cursor);
                has_next.replace(page.page_info.has_next_page);
                results.update(|r| r.extend(page.products));
            }
            loading_more.set(false);
        });
    };
    let retry = move || run(query.get_untracked().trim().to_owned(), false);

    let field = view().pt(px(4.0)).pb(px(12.0)).px(px(GUTTER)).child(
        view()
            .h(px(44.0))
            .rounded(px(12.0))
            .bg(surface())
            .flex_row()
            .items_center()
            .gap(px(8.0))
            .px(px(12.0))
            .child(icon(Icon::Search, 20.0, text_muted()))
            .child(
                input()
                    .test_id("search-input")
                    .label("Search products")
                    .value(move || query.get())
                    .on_change(move |text: &str| {
                        query.set(text.to_owned());
                        run(text.trim().to_owned(), true);
                    })
                    .placeholder("Search products")
                    .placeholder_color(|| text_muted())
                    .caret_color(|| text_color())
                    .return_key_type(ReturnKeyType::Search)
                    .auto_correct(false)
                    .auto_capitalize(AutoCapitalize::None)
                    .flex_1()
                    .h_full()
                    .text_size(px(16.0))
                    .text_color(text_color()),
            ),
    );

    let body = dynamic(move || match shown.get() {
        Shown::Hint => view()
            .py(px(48.0))
            .px(px(32.0))
            .child(
                label("Search across 995 products by name.", 15.0, FontWeight::NORMAL)
                    .line_height(px(22.0))
                    .text_color(text_muted())
                    .text_center(),
            )
            .into_element(),
        Shown::Results(Status::Loading) => rows_skeleton().into_element(),
        Shown::Results(Status::Failed) => error_state(retry).into_element(),
        Shown::Results(Status::Ready) => view()
            .flex_1()
            .child(
                view().pt(px(4.0)).pb(px(8.0)).px(px(GUTTER)).child(
                    label(move || SharedString::from(format!("{} results", total.get())), 13.0, FontWeight::NORMAL)
                        .text_color(text_muted()),
                ),
            )
            .child(
                virtual_list(move || results.with(Vec::len), move |at| result_row(results, at))
                    .estimated_item_size(px(101.0))
                    .keyboard_dismiss_mode(KeyboardDismissMode::OnDrag)                    .keyboard_taps(KeyboardTaps::Handled)
                    .on_load_more(load_more)
                    .footer(view().child(dynamic(move || loading_more.get().then(loading_footer))))
                    .test_id("search-results")
                    .flex_1(),
            )
            .into_element(),
    });

    nav_page().header_visible(false).child(
        view()
            .flex_1()
            .bg(page_bg())
            .pt_safe_area()
            .child(field)
            .child(view().flex_1().child(body)),
    )
}

/// A row of the results: made once, given other rows as it is reused.
fn result_row(results: Signal<Vec<ProductCard>>, at: Position) -> View {
    let product = computed(move || results.with(|r| r.get(at.index()).cloned()));
    view().child(dynamic(move || {
        let index = at.index();
        product.get().map(|product| {
            let handle = product.handle.clone();
            pressable()
                .test_id(&format!("search-result-{index}"))
                .label(product.title.clone())
                .on_press(move || nav::push(StackId::Search, Route::Product { handle: handle.clone() }))
                .flex_row()
                .items_center()
                .gap(px(12.0))
                .py(px(8.0))
                .px(px(GUTTER))
                .active(|s| s.bg(surface()))
                .child(
                    remote_image(image_url(product.featured_image.as_ref(), 240))
                        .w(px(64.0))
                        .h(px(85.0))
                        .rounded(px(8.0))
                        .flex_shrink_0(),
                )
                .child(
                    view()
                        .flex_1()
                        .min_w(px(0.0))
                        .gap(px(4.0))
                        .child(label(product.title.clone(), 15.0, FontWeight::NORMAL).line_height(px(20.0)))
                        .child(label(product.price().display(), 15.0, FontWeight::BOLD)),
                )
        })
    }))
}

fn rows_skeleton() -> View {
    view().flex_1().overflow_hidden().pt(px(4.0)).child(
        (0..6)
            .map(|_| {
                view()
                    .flex_row()
                    .items_center()
                    .gap(px(12.0))
                    .py(px(8.0))
                    .px(px(GUTTER))
                    .child(block(Some(64.0), 85.0, 8.0))
                    .child(
                        view()
                            .flex_1()
                            .gap(px(8.0))
                            .child(block(None, 15.0, 4.0))
                            .child(block(Some(70.0), 15.0, 4.0)),
                    )
            })
            .collect::<Vec<_>>(),
    )
}
