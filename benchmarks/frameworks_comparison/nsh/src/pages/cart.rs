//! The cart: its lines with quantity steppers, the subtotal and Check out;
//! the empty state while it has no lines.

use nsh_core::prelude::*;

use crate::{
    cart,
    models::{Cart, CartLine, image_url},
    nav::{self, Tab},
    ui::{
        icons::{Icon, icon},
        parts::*,
        tokens::*,
    },
};

pub fn cart_page() -> impl IntoElement {
    // Rebuilt when the cart changes, not when a mutation starts or ends.
    let shown = computed(cart::cart);
    view()
        .flex_1()
        .bg(page_bg())
        .pt_safe_area()
        .child(screen_header("Cart"))
        .child(dynamic(move || match shown.get() {
            Some(cart) if !cart.lines.nodes.is_empty() => filled(&cart).into_element(),
            _ => empty_cart(|| nav::select_tab(Tab::Home)).into_element(),
        }))
}

fn filled(cart: &Cart) -> View {
    let checkout_url = cart.checkout_url.clone();
    view()
        .flex_1()
        .child(
            scroll().flex_1().child(
                view().px(px(GUTTER)).child(
                    cart.lines
                        .nodes
                        .iter()
                        .enumerate()
                        .map(|(i, line)| line_row(i, line))
                        .collect::<Vec<_>>(),
                ),
            ),
        )
        .child(
            view()
                .p(px(16.0))
                .gap(px(12.0))
                .bg(page_bg())
                .border_t_1()
                .border_color(border())
                .child(
                    view()
                        .flex_row()
                        .items_baseline()
                        .justify_between()
                        .child(label("Subtotal", 15.0, FontWeight::NORMAL))
                        .child(
                            label(cart.cost.subtotal_amount.display(), 17.0, FontWeight::BOLD)
                                .test_id("cart-subtotal"),
                        ),
                )
                .child(
                    label("Taxes and shipping are calculated at checkout.", 13.0, FontWeight::NORMAL)
                        .text_color(text_muted()),
                )
                .child(primary_button("Check out").test_id("checkout").on_press(move || {
                    let opened = open_url(checkout_url.clone());
                    spawn(async move {
                        let _ = opened.await;
                    });
                })),
        )
}

fn line_row(index: usize, line: &CartLine) -> View {
    let quantity = line.quantity;
    let (dec_id, inc_id) = (line.id.clone(), line.id.clone());
    let stepper_button = |glyph: Icon, test_id: String, on_press: Box<dyn Fn()>| {
        pressable()
            .test_id(&test_id)
            .label(if glyph == Icon::Minus { "Decrease quantity" } else { "Increase quantity" })
            .disabled(cart::busy)
            .on_press(move || on_press())
            .w(px(36.0))
            .h(px(34.0))
            .items_center()
            .justify_center()
            .active(|s| s.opacity(0.5))
            .disabled_style(|s| s.opacity(0.4))
            .child(icon(glyph, 16.0, text_color()))
    };
    view()
        .test_id(&format!("cart-line-{index}"))
        .flex_row()
        .gap(px(12.0))
        .py(px(16.0))
        .border_b_1()
        .border_color(border())
        .child(
            remote_image(image_url(line.image(), 240))
                .w(px(80.0))
                .h(px(107.0))
                .rounded(px(8.0))
                .flex_shrink_0(),
        )
        .child(
            view()
                .flex_1()
                .min_w(px(0.0))
                .gap(px(4.0))
                .child(
                    label(line.merchandise.product.title.clone(), 15.0, FontWeight::SEMIBOLD)
                        .line_height(px(20.0)),
                )
                .child(
                    line.variant_title()
                        .map(|title| label(title.to_owned(), 13.0, FontWeight::NORMAL).text_color(text_muted())),
                )
                .child(view().flex_1())
                .child(
                    view()
                        .flex_row()
                        .items_center()
                        .justify_between()
                        .child(
                            view()
                                .flex_row()
                                .items_center()
                                .h(px(36.0))
                                .rounded(px(12.0))
                                .border_1()
                                .border_color(border())
                                .child(stepper_button(
                                    Icon::Minus,
                                    format!("qty-dec-{index}"),
                                    Box::new(move || cart::set_quantity(dec_id.clone(), quantity.saturating_sub(1))),
                                ))
                                .child(
                                    label(quantity.to_string(), 15.0, FontWeight::SEMIBOLD)
                                        .min_w(px(24.0))
                                        .text_center(),
                                )
                                .child(stepper_button(
                                    Icon::Plus,
                                    format!("qty-inc-{index}"),
                                    Box::new(move || cart::set_quantity(inc_id.clone(), quantity + 1)),
                                )),
                        )
                        .child(label(line.cost.total_amount.display(), 15.0, FontWeight::BOLD)),
                ),
        )
}
