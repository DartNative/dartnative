//! One file per screen.

pub mod cart;
pub mod collection;
pub mod home;
pub mod product;
pub mod search;

/// A screen's data while it loads.
#[derive(Debug, Clone, PartialEq)]
pub enum Load<T> {
    Loading,
    Failed,
    Ready(T),
}

/// Where a paged list's first page is.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Status {
    Loading,
    Failed,
    Ready,
}
