//! Everbloom: a small shop on the Storefront API of mock.shop, written in
//! Rust with Native Shell. `nsh.json` names the root, [`App`].

mod api;
mod cart;
mod config;
mod models;
mod nav;
mod pages;
mod ui;

use std::{cell::Cell, future::Future};

use nsh_base::nav_stack;
use nsh_core::prelude::*;

pub use config::set_home_ready_hook;
use nav::{Route, StackId, Tab};
use ui::{
    icons::{Icon, icon},
    parts::pressable,
    tokens::*,
};

/// The app's UI set (`nsh.json` `"rust"`).
#[native_module("everbloom/native")]
fn native(registry: &mut Registry) {
    registry.register::<App>();
}

thread_local! {
    /// The root's owner: tasks that must outlive the screen that starts
    /// them (cart mutations) run under it.
    static APP_OWNER: Cell<Option<Owner>> = const { Cell::new(None) };
}

/// Runs `future` under `owner`: it ends when `owner` goes, not with the
/// region that starts it (a Retry button's error state).
pub(crate) fn spawn_in<T: 'static>(owner: &Owner, future: impl Future<Output = T> + 'static) {
    owner.run(|| {
        spawn(future);
    });
}

/// Runs `future` for as long as the app runs.
pub(crate) fn spawn_app<T: 'static>(future: impl Future<Output = T> + 'static) {
    match APP_OWNER.with(Cell::get) {
        Some(owner) => spawn_in(&owner, future),
        None => {
            spawn(future);
        }
    }
}

/// The app's root: the three tabs, each keeping its pages, over the tab bar.
#[component]
pub fn App() -> impl IntoElement {
    APP_OWNER.with(|o| o.set(Some(Owner::current())));
    view()
        .flex_1()
        .bg(page_bg())
        .child(
            view()
                .flex_1()
                .child(tab_panel(Tab::Home, stack(StackId::Home)))
                .child(tab_panel(Tab::Search, stack(StackId::Search)))
                .child(tab_panel(Tab::Cart, pages::cart::cart_page())),
        )
        // Content stays above the keyboard, which covers the tab bar.
        .pb_keyboard()
        .child(tab_bar().style_when(move || nav::showing_product() || keyboard_height() > px(0.0), |s| s.hidden()))
}

/// A tab's content, kept while another tab shows.
fn tab_panel(tab: Tab, content: impl IntoElement) -> impl IntoElement {
    view()
        .absolute()
        .inset(px(0.0))
        .style_when(move || nav::tab() != tab, |s| s.hidden())
        .child(content)
}

/// A tab's navigation stack: its first page, then the pages pushed over it.
fn stack(id: StackId) -> impl IntoElement {
    let first = match id {
        StackId::Home => pages::home::home_page(),
        StackId::Search => pages::search::search_page(),
    };
    nav_stack().flex_1().child(first).child(each(
        move || nav::entries(id),
        |entry: &nav::Entry| entry.key,
        move |entry, depth| {
            let page = match entry.get_untracked().route {
                Route::Collection { handle, title } => pages::collection::collection_page(id, handle, title),
                Route::Product { handle } => pages::product::product_page(id, handle),
            };
            // A native back (the swipe) pops the page: the routes follow.
            page.on_dismiss(move || nav::truncate(id, depth.get_untracked()))
        },
    ))
}

fn tab_bar() -> View {
    let item = |tab: Tab, glyph: Icon, title: &'static str, test_id: &'static str| {
        let active = move || nav::tab() == tab;
        pressable()
            .test_id(test_id)
            .label(title)
            .role(AccessibilityRole::Tab)
            .on_press(move || nav::select_tab(tab))
            .flex_1()
            .h_full()
            .items_center()
            .justify_center()
            .gap(px(2.0))
            .child(icon(glyph, 24.0, move || if active() { text_color() } else { text_muted() }))
            .child(dynamic(move || {
                let on = active();
                label(title, 11.0, if on { FontWeight::SEMIBOLD } else { FontWeight::MEDIUM })
                    .text_color(if on { text_color() } else { text_muted() })
            }))
    };
    // The badge sits over the Cart tab as a sibling, so that UI tests see it.
    let badge = when(
        move || cart::total_quantity() > 0,
        || {
            view()
                .test_id("cart-badge")
                .absolute()
                .top(px(4.0))
                .left(relative(5.0 / 6.0))
                .ml(px(6.0))
                .min_w(px(18.0))
                .h(px(18.0))
                .px(px(5.0))
                .rounded(px(9.0))
                .bg(sale())
                .items_center()
                .justify_center()
                .pointer_events(PointerEvents::None)
                .child(
                    label(
                        move || SharedString::from(cart::total_quantity().to_string()),
                        11.0,
                        FontWeight::BOLD,
                    )
                    .text_color(page_bg()),
                )
        },
    );
    view()
        .bg(page_bg())
        .border_t_1()
        .border_color(border())
        .pb_safe_area()
        .child(
            view()
                .h(px(49.0))
                .flex_row()
                .child(item(Tab::Home, Icon::Home, "Home", "tab-home"))
                .child(item(Tab::Search, Icon::Search, "Search", "tab-search"))
                .child(item(Tab::Cart, Icon::Cart, "Cart", "tab-cart"))
                .child(badge),
        )
}
