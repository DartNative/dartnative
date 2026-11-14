//! The cart, in memory only: the last `cart` a mutation returned.

use nsh_base::alert_dialog;
use nsh_core::prelude::*;

use crate::{api, models::Cart};

#[derive(Debug, Clone, Default, PartialEq)]
struct CartState {
    cart: Option<Cart>,
    /// A mutation is on its way.
    busy: bool,
}

fn state() -> Signal<CartState> {
    global::<CartState>()
}

/// The cart (tracked where it is read).
pub fn cart() -> Option<Cart> {
    state().with(|s| s.cart.clone())
}

/// The cart's `totalQuantity`, 0 without one (tracked where it is read).
pub fn total_quantity() -> u32 {
    state().with(|s| s.cart.as_ref().map_or(0, |c| c.total_quantity))
}

/// Whether a mutation is on its way (tracked where it is read).
pub fn busy() -> bool {
    state().with(|s| s.busy)
}

/// Shows `message` in the system's alert.
fn alert(message: String) {
    let answer = alert_dialog().title(message).cancel("ok", "OK").show();
    crate::spawn_app(async move {
        let _ = answer.await;
    });
}

/// Applies a mutation's answer: its cart replaces the one shown, and its
/// first user error shows in an alert. Whether it answered at all.
fn apply(result: Result<crate::models::CartPayload, String>) -> bool {
    match result {
        Ok(payload) => {
            if let Some(cart) = payload.cart {
                state().update(|s| s.cart = Some(cart));
            }
            if let Some(error) = payload.user_errors.into_iter().next() {
                alert(error.message);
            }
            true
        }
        Err(_) => {
            alert("Couldn't update the cart. Check your connection and try again.".to_owned());
            false
        }
    }
}

/// Adds one of the variant `variant_id`: `CartCreate` the first time,
/// `CartLinesAdd` after. Whether the server answered.
pub async fn add(variant_id: String) -> bool {
    let cart_id = state().with_untracked(|s| s.cart.as_ref().map(|c| c.id.clone()));
    state().update(|s| s.busy = true);
    let result = match cart_id {
        None => api::cart_create(&variant_id).await,
        Some(id) => api::cart_lines_add(&id, &variant_id).await,
    };
    state().update(|s| s.busy = false);
    apply(result)
}

/// Sets the line `line_id` to `quantity` (0 removes it).
pub fn set_quantity(line_id: String, quantity: u32) {
    let Some(cart_id) = state().with_untracked(|s| {
        (!s.busy).then(|| s.cart.as_ref().map(|c| c.id.clone())).flatten()
    }) else {
        return;
    };
    state().update(|s| s.busy = true);
    crate::spawn_app(async move {
        let result = api::cart_lines_update(&cart_id, &line_id, quantity).await;
        state().update(|s| s.busy = false);
        apply(result);
    });
}
