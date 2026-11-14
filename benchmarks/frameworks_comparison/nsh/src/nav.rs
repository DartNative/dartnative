//! Which tab shows, and the pages pushed in the Home and Search tabs.
//! Putting a route in a stack pushes its page; taking it out pops it.

use nsh_core::prelude::*;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Tab {
    #[default]
    Home,
    Search,
    Cart,
}

/// The tabs that hold a navigation stack.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StackId {
    Home,
    Search,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Route {
    Collection { handle: String, title: String },
    Product { handle: String },
}

/// A pushed page: its route, and a key unique for the app's run.
#[derive(Debug, Clone, PartialEq)]
pub struct Entry {
    pub key: u64,
    pub route: Route,
}

#[derive(Debug, Clone, Default, PartialEq)]
struct Stacks {
    home: Vec<Entry>,
    search: Vec<Entry>,
    next_key: u64,
}

impl Stacks {
    fn of(&mut self, stack: StackId) -> &mut Vec<Entry> {
        match stack {
            StackId::Home => &mut self.home,
            StackId::Search => &mut self.search,
        }
    }
}

fn stacks() -> Signal<Stacks> {
    global::<Stacks>()
}

fn tab_signal() -> Signal<Tab> {
    global::<Tab>()
}

/// The selected tab (tracked where it is read).
pub fn tab() -> Tab {
    tab_signal().get()
}

pub fn select_tab(tab: Tab) {
    tab_signal().set(tab);
}

/// The pages over the stack's first page (tracked where it is read).
pub fn entries(stack: StackId) -> Vec<Entry> {
    stacks().with(|s| match stack {
        StackId::Home => s.home.clone(),
        StackId::Search => s.search.clone(),
    })
}

pub fn push(stack: StackId, route: Route) {
    stacks().update(|s| {
        let key = s.next_key;
        s.next_key += 1;
        s.of(stack).push(Entry { key, route });
    });
}

pub fn pop(stack: StackId) {
    stacks().update(|s| {
        s.of(stack).pop();
    });
}

/// Leaves `depth` pages over the stack's first page (the user went back
/// natively).
pub fn truncate(stack: StackId, depth: usize) {
    stacks().update(|s| s.of(stack).truncate(depth));
}

/// Whether the selected tab shows a product (tracked where it is read): the
/// tab bar hides then.
pub fn showing_product() -> bool {
    let top_is_product =
        |entries: &[Entry]| matches!(entries.last(), Some(Entry { route: Route::Product { .. }, .. }));
    match tab() {
        Tab::Home => stacks().with(|s| top_is_product(&s.home)),
        Tab::Search => stacks().with(|s| top_is_product(&s.search)),
        Tab::Cart => false,
    }
}
