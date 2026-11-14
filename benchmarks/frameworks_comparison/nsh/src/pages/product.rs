//! A product: its images, price, options, description, recommendations
//! and the Add to cart bar.

use std::rc::Rc;

use nsh_base::{carousel, carousel_content, carousel_item, carousel_pagination, carousel_pagination_item, nav_page};
use nsh_core::{element::Screen, prelude::*};

use super::Load;
use crate::{
    api, cart,
    models::{ProductCard, ProductDetail, image_url},
    nav::{self, Route, StackId, Tab},
    spawn_app, spawn_in,
    ui::{
        icons::{Icon, icon},
        parts::*,
        tokens::*,
    },
};

type Data = Rc<(ProductDetail, Vec<ProductCard>)>;

pub fn product_page(stack: StackId, handle: String) -> Screen {
    let owner = Owner::current();
    let state = signal(Load::<Data>::Loading);
    let load = move || {
        let handle = handle.clone();
        state.set(Load::Loading);
        spawn_in(&owner, async move {
            match api::product(&handle).await {
                Ok(data) => state.set(Load::Ready(Rc::new(data))),
                Err(_) => state.set(Load::Failed),
            }
        });
    };
    load();
    nav_page().header_visible(false).child(
        view()
            .flex_1()
            .bg(page_bg())
            .child(dynamic(move || match state.get() {
                Load::Loading => skeleton(stack).into_element(),
                Load::Failed => view()
                    .flex_1()
                    .pt_safe_area()
                    .child(view().px(px(8.0)).child(back_button(move || nav::pop(stack))))
                    .child(error_state(load.clone()))
                    .into_element(),
                Load::Ready(data) => content(stack, data).into_element(),
            })),
    )
}

/// The round back button over the image.
fn floating_back(stack: StackId) -> View {
    view().absolute().top(px(0.0)).left(px(12.0)).pt_safe_area().child(
        pressable()
            .test_id("back")
            .label("Back")
            .on_press(move || nav::pop(stack))
            .size(px(40.0))
            .rounded(px(20.0))
            .bg(page_bg())
            .items_center()
            .justify_center()
            .active(|s| s.opacity(0.7))
            .child(icon(Icon::Back, 22.0, text_color())),
    )
}

fn skeleton(stack: StackId) -> View {
    view()
        .flex_1()
        .overflow_hidden()
        .child(view().w_full().aspect_ratio(0.75).bg(skeleton_color()).child(floating_back(stack)))
        .child(
            view()
                .pt(px(20.0))
                .px(px(GUTTER))
                .gap(px(10.0))
                .child(block(Some(240.0), 24.0, 4.0))
                .child(block(Some(90.0), 22.0, 4.0)),
        )
}

fn skeleton_color() -> Rgba {
    crate::ui::tokens::skeleton()
}

fn content(stack: StackId, data: Data) -> View {
    let product = &data.0;
    let recommendations = &data.1;
    let selected = signal(product.initial_variant());
    let adding = signal(false);
    let price_of = {
        let data = data.clone();
        move || {
            data.0
                .variants
                .nodes
                .get(selected.get())
                .map(|v| v.price.display())
                .unwrap_or_default()
        }
    };

    let add = {
        let data = data.clone();
        move || {
            let Some(variant) = data.0.variants.nodes.get(selected.get_untracked()) else {
                return;
            };
            if adding.get_untracked() {
                return;
            }
            adding.set(true);
            let id = variant.id.clone();
            spawn_app(async move {
                let answered = cart::add(id).await;
                adding.set(false);
                if answered {
                    nav::select_tab(Tab::Cart);
                }
            });
        }
    };

    view()
        .flex_1()
        .child(
            scroll().flex_1().child(
                view()
                    .pb(px(24.0))
                    .child(gallery(stack, product))
                    .child(title_and_price(data.clone(), selected))
                    .child(options(data.clone(), selected))
                    .child((!product.description.is_empty()).then(|| {
                        view()
                            .pt(px(24.0))
                            .px(px(GUTTER))
                            .child(
                                view()
                                    .pb(px(8.0))
                                    .child(label("Description", 15.0, FontWeight::SEMIBOLD)),
                            )
                            .child(
                                label(product.description.clone(), 15.0, FontWeight::NORMAL)
                                    .line_height(px(22.0))
                                    .text_color(text_body()),
                            )
                    }))
                    .child((!recommendations.is_empty()).then(|| recommendations_row(stack, recommendations))),
            ),
        )
        .child(
            view()
                .pt(px(12.0))
                .px(px(GUTTER))
                .pb_safe_area_plus(px(0.0))
                .bg(page_bg())
                .border_t_1()
                .border_color(border())
                .child(
                    view().pb(px(12.0)).child(
                        primary_button(move || SharedString::from(format!("Add to cart · {}", price_of())))
                            .test_id("add-to-cart")
                            .disabled(adding)
                            .on_press(add),
                    ),
                ),
        )
}

fn gallery(stack: StackId, product: &ProductDetail) -> View {
    let images = product.images.nodes.clone();
    let count = images.len();
    let index = signal(0_u32);
    let carousel = carousel()
        .index(move || Some(index.get()))
        .on_change(move |i: &u32| index.set(*i))
        .accessibility_label("Product images")
        .w_full()
        .aspect_ratio(0.75)
        .bg(surface())
        .child(
            carousel_content()
                .w_full()
                .h_full()
                .child(
                    images
                        .iter()
                        .enumerate()
                        .map(|(i, image)| {
                            carousel_item()
                                .accessibility_label(format!("Image {} of {count}", i + 1))
                                .w_full()
                                .h_full()
                                .child(
                                    remote_image(image_url(Some(image), 1080))
                                        .w_full()
                                        .h_full(),
                                )
                        })
                        .collect::<Vec<_>>(),
                ),
        )
        .child((count > 1).then(|| {
            carousel_pagination()
                .absolute()
                .left(px(0.0))
                .right(px(0.0))
                .bottom(px(12.0))
                .flex_row()
                .justify_center()
                .gap(px(4.0))
                .child(
                    (0..count as u32)
                        .map(|i| {
                            carousel_pagination_item()
                                .index(i)
                                .accessibility_label(format!("Show image {}", i + 1))
                                .size(px(8.0))
                                .m(px(8.0))
                                .rounded(px(4.0))
                                .bg(dot_inactive())
                                .selected_style(|s| s.bg(text_color()))
                        })
                        .collect::<Vec<_>>(),
                )
        }))
        .child(floating_back(stack));
    // The id goes on a group around the carousel: its parts take none.
    view()
        .test_id("product-carousel")
        .role(AccessibilityRole::Group)
        .w_full()
        .child(carousel)
}

fn title_and_price(data: Data, selected: Signal<usize>) -> View {
    let title = data.0.title.clone();
    view()
        .pt(px(20.0))
        .px(px(GUTTER))
        .gap(px(6.0))
        .child(label(title, 22.0, FontWeight::BOLD).line_height(px(28.0)))
        .child(dynamic(move || {
            data.0
                .variants
                .nodes
                .get(selected.get())
                .map(|v| price_row(&v.price, v.compare_at(), 20.0))
        }))
}

fn options(data: Data, selected: Signal<usize>) -> View {
    let shown = data.0.shown_options();
    view().child(
        shown
            .into_iter()
            .map(|option| {
                let data = data.clone();
                view().mt(px(24.0)).px(px(GUTTER)).child(dynamic(move || {
                    let current = selected.get();
                    let value = data
                        .0
                        .variants
                        .nodes
                        .get(current)
                        .and_then(|v| v.option(&option.name))
                        .unwrap_or_default()
                        .to_owned();
                    view()
                        .child(
                            view()
                                .pb(px(12.0))
                                .flex_row()
                                .child(label(format!("{}:", option.name), 15.0, FontWeight::SEMIBOLD))
                                .child(label(value.clone(), 15.0, FontWeight::NORMAL).text_color(text_muted()).ml(px(4.0))),
                        )
                        .child(
                            view().flex_row().flex_wrap().gap(px(8.0)).child(
                                option
                                    .option_values
                                    .iter()
                                    .map(|v| {
                                        let on = v.name == value;
                                        let (name, picked) = (option.name.clone(), v.name.clone());
                                        let data = data.clone();
                                        pressable()
                                            .test_id(&format!("option-{}-{}", option.name, v.name))
                                            .on_press(move || {
                                                if let Some(next) =
                                                    data.0.variant_with(selected.get_untracked(), &name, &picked)
                                                {
                                                    selected.set(next);
                                                }
                                            })
                                            .min_w(px(56.0))
                                            .h(px(44.0))
                                            .px(px(16.0))
                                            .rounded(px(12.0))
                                            .border_color(if on { text_color() } else { border() })
                                            .items_center()
                                            .justify_center()
                                            .bg(page_bg())
                                            .active(|s| s.opacity(0.6))
                                            .when_border(on)
                                            .child(label(
                                                v.name.clone(),
                                                15.0,
                                                if on { FontWeight::SEMIBOLD } else { FontWeight::MEDIUM },
                                            ))
                                    })
                                    .collect::<Vec<_>>(),
                            ),
                        )
                }))
            })
            .collect::<Vec<_>>(),
    )
}

/// A pill's outline: 2 when selected, else 1.
trait PillBorder {
    fn when_border(self, selected: bool) -> Self;
}

impl<T: Styled> PillBorder for T {
    fn when_border(self, selected: bool) -> Self {
        if selected { self.border_2() } else { self.border_1() }
    }
}

fn recommendations_row(stack: StackId, products: &[ProductCard]) -> View {
    view()
        .pt(px(32.0))
        .child(
            view()
                .px(px(GUTTER))
                .pb(px(12.0))
                .child(label("You may also like", 17.0, FontWeight::BOLD)),
        )
        .child(
            scroll().horizontal().scrollbar(false).child(
                view().flex_row().gap(px(12.0)).px(px(GUTTER)).child(
                    products
                        .iter()
                        .enumerate()
                        .map(|(i, product)| {
                            let handle = product.handle.clone();
                            carousel_card(product, &format!("recommendation-{i}"), 187.0, move || {
                                nav::push(stack, Route::Product { handle: handle.clone() })
                            })
                        })
                        .collect::<Vec<_>>(),
                ),
            ),
        )
}
