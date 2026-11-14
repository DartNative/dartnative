mod cart;
mod collection;
mod home;
mod product;
mod search;

pub use cart::Cart;
pub use collection::CollectionScreen;
pub use home::Home;
pub use product::ProductScreen;
pub use search::SearchScreen;

/// Loading state of a single-request screen.
#[derive(Clone, Debug, PartialEq)]
pub enum Load<T> {
    Loading,
    Failed,
    Ready(T),
}

impl<T> Load<T> {
    pub fn ready(&self) -> Option<&T> {
        match self {
            Load::Ready(t) => Some(t),
            _ => None,
        }
    }

    /// 0 = loading, 1 = failed, 2 = ready.
    pub fn kind(&self) -> u8 {
        match self {
            Load::Loading => 0,
            Load::Failed => 1,
            Load::Ready(_) => 2,
        }
    }
}

/// First-page state of a paginated list.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Status {
    Idle,
    Loading,
    Failed,
    Ready,
}
