//! App-wide state: the in-memory cart.

use crate::api::{self, Cart, CartResult};
use whisker::prelude::*;

#[derive(Clone, Copy)]
pub struct AppState {
    pub cart: RwSignal<Option<Cart>>,
    /// A cart mutation is in flight.
    pub cart_busy: RwSignal<bool>,
    /// Collection titles from Home, keyed by handle, so the Collection nav
    /// bar can show its title before its own request returns.
    pub collection_titles: StoredValue<Vec<(String, String)>>,
    /// App root owner: cart requests outlive the screen that started them.
    pub owner: whisker::Owner,
}

impl AppState {
    pub fn new() -> Self {
        Self {
            cart: signal(None),
            cart_busy: signal(false),
            collection_titles: StoredValue::new(Vec::new()),
            owner: whisker::Owner::current().expect("root owner"),
        }
    }

    pub fn spawn(&self, future: impl std::future::Future<Output = ()> + 'static) {
        self.owner.with(|| spawn_local(future));
    }

    pub fn total_quantity(&self) -> i64 {
        self.cart
            .with(|c| c.as_ref().map(|c| c.total_quantity).unwrap_or(0))
    }

    /// Applies a cart response. Returns true when it succeeded without
    /// user errors.
    fn apply(&self, result: Result<CartResult, String>) -> bool {
        match result {
            Ok(r) => {
                if let Some(cart) = r.cart {
                    self.cart.set(Some(cart));
                }
                if let Some(first) = r.user_errors.first() {
                    shop_native::alert(&first.message);
                    false
                } else {
                    true
                }
            }
            Err(_) => {
                shop_native::alert(
                    "Couldn’t update your cart. Check your connection and try again.",
                );
                false
            }
        }
    }

    /// Adds one of `variant_id`; creates the cart on first use.
    pub async fn add(self, variant_id: String) -> bool {
        self.cart_busy.set(true);
        let cart_id = self
            .cart
            .with_untracked(|c| c.as_ref().map(|c| c.id.clone()));
        let result = match cart_id {
            Some(id) => api::cart_lines_add(id, variant_id).await,
            None => api::cart_create(variant_id).await,
        };
        let ok = self.apply(result);
        self.cart_busy.set(false);
        ok
    }

    /// Sets a line's quantity (0 removes it).
    pub fn update(self, line_id: String, quantity: i64) {
        if self.cart_busy.get_untracked() {
            return;
        }
        let Some(cart_id) = self
            .cart
            .with_untracked(|c| c.as_ref().map(|c| c.id.clone()))
        else {
            return;
        };
        self.cart_busy.set(true);
        self.spawn(async move {
            let result = api::cart_lines_update(cart_id, line_id, quantity.max(0)).await;
            self.apply(result);
            self.cart_busy.set(false);
        });
    }
}
