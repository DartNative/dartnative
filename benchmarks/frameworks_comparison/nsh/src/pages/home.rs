//! Home: the wordmark, collection chips, the featured collection, the
//! collections carousel and the best sellers.

use std::rc::Rc;

use nsh_base::nav_page;
use nsh_core::{element::Screen, prelude::*};

use super::Load;
use crate::{
    api, config,
    models::{Collection, HomeData, image_url},
    nav::{self, Route, StackId},
    spawn_in,
    ui::{parts::*, tokens::*},
};

fn open_collection(collection: &Collection) {
    nav::push(
        StackId::Home,
        Route::Collection {
            handle: collection.handle.clone(),
            title: collection.title.clone(),
        },
    );
}

pub fn home_page() -> Screen {
    let state = signal(Load::<Rc<HomeData>>::Loading);
    let owner = Owner::current();
    let load = move || {
        state.set(Load::Loading);
        spawn_in(&owner, async move {
            match api::home().await {
                Ok(data) => {
                    state.set(Load::Ready(Rc::new(data)));
                    // After the commit that shows it.
                    let _ = next_frame().await;
                    config::home_ready();
                }
                Err(_) => state.set(Load::Failed),
            }
        });
    };
    load();
    nav_page().header_visible(false).child(
        view()
            .flex_1()
            .bg(page_bg())
            .pt_safe_area()
            .child(dynamic(move || match state.get() {
                Load::Loading => skeleton().into_element(),
                Load::Failed => view()
                    .flex_1()
                    .child(wordmark())
                    .child(error_state(load))
                    .into_element(),
                Load::Ready(data) => content(&data).into_element(),
            })),
    )
}

fn wordmark() -> View {
    view()
        .h(px(44.0))
        .px(px(GUTTER))
        .flex_row()
        .items_center()
        .child(label("Everbloom", 22.0, FontWeight::BOLD).letter_spacing(px(-0.4)))
}

fn skeleton() -> View {
    view()
        .flex_1()
        .overflow_hidden()
        .child(wordmark())
        .child(
            view()
                .flex_row()
                .gap(px(8.0))
                .pt(px(8.0))
                .pb(px(12.0))
                .px(px(GUTTER))
                .child([52.0, 110.0, 96.0, 80.0].map(|w| block(Some(w), 36.0, 18.0))),
        )
        .child(view().mt(px(4.0)).mx(px(GUTTER)).child(block(None, 240.0, 12.0)))
        .child(
            view()
                .pt(px(28.0))
                .pb(px(12.0))
                .px(px(GUTTER))
                .child(block(Some(120.0), 18.0, 4.0)),
        )
        .child(
            view()
                .flex_row()
                .gap(px(12.0))
                .px(px(GUTTER))
                .child([0; 3].map(|_| block(Some(140.0), 175.0, 8.0).flex_shrink_0())),
        )
}

fn content(data: &HomeData) -> Scroll {
    let collections = &data.collections.nodes;
    scroll()
        .flex_1()
        .test_id("home-scroll")
        .child(
            view()
                .pb(px(24.0))
                .child(wordmark())
                .child(chips(collections))
                .child(collections.first().map(featured))
                .child(carousel(collections))
                .child(best_sellers(data)),
        )
}

fn chips(collections: &[Collection]) -> Scroll {
    scroll().horizontal().scrollbar(false).child(
        view()
            .flex_row()
            .gap(px(8.0))
            .pt(px(8.0))
            .pb(px(12.0))
            .px(px(GUTTER))
            .child(
                collections
                    .iter()
                    .enumerate()
                    .map(|(i, collection)| {
                        let c = collection.clone();
                        pressable()
                            .test_id(&format!("collection-chip-{i}"))
                            .on_press(move || open_collection(&c))
                            .h(px(36.0))
                            .px(px(14.0))
                            .rounded(px(18.0))
                            .bg(surface())
                            .justify_center()
                            .active(|s| s.opacity(0.6))
                            .child(chip(collection.title.clone()).number_of_lines(1))
                    })
                    .collect::<Vec<_>>(),
            ),
    )
}

fn featured(collection: &Collection) -> View {
    let c = collection.clone();
    pressable()
        .test_id("featured-collection")
        .label(collection.title.clone())
        .on_press(move || open_collection(&c))
        .mt(px(4.0))
        .mx(px(GUTTER))
        .h(px(240.0))
        .rounded(px(12.0))
        .overflow_hidden()
        .bg(surface())
        .active(|s| s.opacity(0.85))
        .child(
            remote_image(image_url(collection.image.as_ref(), 1080))
                .absolute()
                .inset(px(0.0)),
        )
        .child(
            view()
                .absolute()
                .left(px(0.0))
                .right(px(0.0))
                .bottom(px(0.0))
                .p(px(16.0))
                .gap(px(2.0))
                .bg(scrim())
                .child(
                    label("Featured collection", 12.0, FontWeight::SEMIBOLD)
                        .uppercase()
                        .letter_spacing(px(0.6))
                        .text_color(page_bg()),
                )
                .child(label(collection.title.clone(), 20.0, FontWeight::BOLD).text_color(page_bg()))
                .child(label("Shop now", 14.0, FontWeight::NORMAL).text_color(page_bg())),
        )
}

fn carousel(collections: &[Collection]) -> View {
    view()
        .pt(px(28.0))
        .child(
            view()
                .px(px(GUTTER))
                .pb(px(12.0))
                .child(label("Collections", 17.0, FontWeight::BOLD)),
        )
        .child(
            scroll().horizontal().scrollbar(false).child(
                view()
                    .flex_row()
                    .gap(px(12.0))
                    .px(px(GUTTER))
                    .child(
                        collections
                            .iter()
                            .enumerate()
                            .map(|(i, collection)| {
                                let c = collection.clone();
                                pressable()
                                    .test_id(&format!("collection-card-{i}"))
                                    .label(collection.title.clone())
                                    .on_press(move || open_collection(&c))
                                    .w(px(140.0))
                                    .gap(px(8.0))
                                    .active(|s| s.opacity(0.7))
                                    .child(
                                        remote_image(image_url(
                                            collection.image.as_ref(),
                                            480,
                                        ))
                                        .w(px(140.0))
                                        .h(px(175.0))
                                        .rounded(px(8.0)),
                                    )
                                    .child(
                                        label(collection.title.clone(), 14.0, FontWeight::SEMIBOLD)
                                            .line_height(px(18.0)),
                                    )
                            })
                            .collect::<Vec<_>>(),
                    ),
            ),
        )
}

fn best_sellers(data: &HomeData) -> View {
    let products = &data.products.nodes;
    view()
        .pt(px(28.0))
        .px(px(GUTTER))
        .child(view().pb(px(12.0)).child(label("Best sellers", 17.0, FontWeight::BOLD)))
        .child(
            view().gap(px(20.0)).child(
                products
                    .chunks(2)
                    .enumerate()
                    .map(|(row, pair)| {
                        view().flex_row().gap(px(12.0)).child(
                            (0..2)
                                .map(|col| {
                                    let i = row * 2 + col;
                                    let cell = view().flex_1().min_w(px(0.0));
                                    match pair.get(col) {
                                        Some(product) => {
                                            let handle = product.handle.clone();
                                            cell.child(product_card(
                                                product,
                                                &format!("best-seller-{i}"),
                                                move || {
                                                    nav::push(
                                                        StackId::Home,
                                                        Route::Product { handle: handle.clone() },
                                                    )
                                                },
                                            ))
                                        }
                                        None => cell,
                                    }
                                })
                                .collect::<Vec<_>>(),
                        )
                    })
                    .collect::<Vec<_>>(),
            ),
        )
}
