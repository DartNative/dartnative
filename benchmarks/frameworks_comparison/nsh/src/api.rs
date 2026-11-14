//! The GraphQL operations of `spec/storefront.graphql`, sent as plain HTTP
//! POSTs with NSH's `fetch`.

use serde::de::DeserializeOwned;
use serde_json::{Value, json};

use nsh_core::prelude::*;

use crate::{config, models::*};

macro_rules! product_card {
    () => {
        "fragment ProductCard on Product {
  id
  handle
  title
  featuredImage { url altText }
  priceRange { minVariantPrice { amount currencyCode } }
  compareAtPriceRange { minVariantPrice { amount currencyCode } }
}
"
    };
}

macro_rules! cart_fields {
    () => {
        "fragment CartFields on Cart {
  id
  checkoutUrl
  totalQuantity
  cost { subtotalAmount { amount currencyCode } }
  lines(first: 100) {
    nodes {
      id
      quantity
      cost { totalAmount { amount currencyCode } }
      merchandise {
        ... on ProductVariant {
          id
          title
          image { url altText }
          product { handle title featuredImage { url altText } }
        }
      }
    }
  }
}
"
    };
}

const HOME: &str = concat!(
    product_card!(),
    "
query Home {
  collections(first: 20) {
    nodes { id handle title image { url altText } }
  }
  products(first: 10, sortKey: BEST_SELLING) {
    nodes { ...ProductCard }
  }
}
"
);

const COLLECTION_PRODUCTS: &str = concat!(
    product_card!(),
    "
query CollectionProducts($handle: String!, $first: Int!, $after: String, $sortKey: ProductCollectionSortKeys!, $reverse: Boolean!) {
  collection(handle: $handle) {
    id
    title
    description
    products(first: $first, after: $after, sortKey: $sortKey, reverse: $reverse) {
      pageInfo { hasNextPage endCursor }
      nodes { ...ProductCard }
    }
  }
}
"
);

const SEARCH: &str = concat!(
    product_card!(),
    "
query Search($query: String!, $first: Int!, $after: String) {
  search(query: $query, first: $first, after: $after, types: PRODUCT) {
    totalCount
    pageInfo { hasNextPage endCursor }
    nodes { ... on Product { ...ProductCard } }
  }
}
"
);

const PRODUCT: &str = concat!(
    product_card!(),
    "
query Product($handle: String!) {
  product(handle: $handle) {
    id
    handle
    title
    description
    images(first: 10) { nodes { url altText } }
    options { name optionValues { name } }
    variants(first: 100) {
      nodes {
        id
        title
        availableForSale
        selectedOptions { name value }
        price { amount currencyCode }
        compareAtPrice { amount currencyCode }
      }
    }
  }
  productRecommendations(productHandle: $handle) { ...ProductCard }
}
"
);

const CART_CREATE: &str = concat!(
    cart_fields!(),
    "
mutation CartCreate($lines: [CartLineInput!]!) {
  cartCreate(input: { lines: $lines }) {
    cart { ...CartFields }
    userErrors { field message }
  }
}
"
);

const CART_LINES_ADD: &str = concat!(
    cart_fields!(),
    "
mutation CartLinesAdd($cartId: ID!, $lines: [CartLineInput!]!) {
  cartLinesAdd(cartId: $cartId, lines: $lines) {
    cart { ...CartFields }
    userErrors { field message }
  }
}
"
);

const CART_LINES_UPDATE: &str = concat!(
    cart_fields!(),
    "
mutation CartLinesUpdate($cartId: ID!, $lines: [CartLineUpdateInput!]!) {
  cartLinesUpdate(cartId: $cartId, lines: $lines) {
    cart { ...CartFields }
    userErrors { field message }
  }
}
"
);

/// Page size of the collection grid and the search results.
pub const PAGE_SIZE: u32 = 24;

/// Sends one operation; its `data`, or why there is none.
async fn send<T: DeserializeOwned>(operation: &str, query: &str, variables: Value) -> Result<T, String> {
    let body = json!({
        "operationName": operation,
        "query": query,
        "variables": variables,
    })
    .to_string();
    let request = HttpRequest::post(config::endpoint(), body).header("Content-Type", "application/json");
    let response = fetch(request).await?;
    if !response.ok() {
        return Err(format!("HTTP {}", response.status()));
    }
    let mut value: Value = serde_json::from_slice(&response.body).map_err(|e| e.to_string())?;
    match value.get_mut("data").map(Value::take) {
        Some(data) if !data.is_null() => serde_json::from_value(data).map_err(|e| e.to_string()),
        _ => Err(value["errors"][0]["message"]
            .as_str()
            .unwrap_or("no data")
            .to_owned()),
    }
}

pub async fn home() -> Result<HomeData, String> {
    send("Home", HOME, json!({})).await
}

/// How the collection grid is sorted.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Sort {
    #[default]
    Featured,
    BestSelling,
    PriceAsc,
    PriceDesc,
}

impl Sort {
    pub const ALL: [Sort; 4] = [Sort::Featured, Sort::BestSelling, Sort::PriceAsc, Sort::PriceDesc];

    pub fn label(self) -> &'static str {
        match self {
            Sort::Featured => "Featured",
            Sort::BestSelling => "Best selling",
            Sort::PriceAsc => "Price: low to high",
            Sort::PriceDesc => "Price: high to low",
        }
    }

    pub fn test_id(self) -> &'static str {
        match self {
            Sort::Featured => "sort-featured",
            Sort::BestSelling => "sort-best-selling",
            Sort::PriceAsc => "sort-price-asc",
            Sort::PriceDesc => "sort-price-desc",
        }
    }

    fn key(self) -> (&'static str, bool) {
        match self {
            Sort::Featured => ("COLLECTION_DEFAULT", false),
            Sort::BestSelling => ("BEST_SELLING", false),
            Sort::PriceAsc => ("PRICE", false),
            Sort::PriceDesc => ("PRICE", true),
        }
    }
}

pub async fn collection_products(handle: &str, sort: Sort, after: Option<String>) -> Result<CollectionPage, String> {
    let (sort_key, reverse) = sort.key();
    let data: CollectionData = send(
        "CollectionProducts",
        COLLECTION_PRODUCTS,
        json!({
            "handle": handle,
            "first": PAGE_SIZE,
            "after": after,
            "sortKey": sort_key,
            "reverse": reverse,
        }),
    )
    .await?;
    data.collection.ok_or_else(|| "no such collection".to_owned())
}

/// One page of search results.
#[derive(Debug, Clone, PartialEq)]
pub struct SearchPage {
    pub total_count: u32,
    pub page_info: PageInfo,
    pub products: Vec<ProductCard>,
}

pub async fn search(query: &str, after: Option<String>) -> Result<SearchPage, String> {
    let data: SearchData = send(
        "Search",
        SEARCH,
        json!({ "query": query, "first": PAGE_SIZE, "after": after }),
    )
    .await?;
    let search = data.search;
    Ok(SearchPage {
        total_count: search.total_count,
        page_info: search.page_info,
        products: search
            .nodes
            .into_iter()
            .filter_map(|node| serde_json::from_value(node).ok())
            .collect(),
    })
}

pub async fn product(handle: &str) -> Result<(ProductDetail, Vec<ProductCard>), String> {
    let data: ProductData = send("Product", PRODUCT, json!({ "handle": handle })).await?;
    let product = data.product.ok_or_else(|| "no such product".to_owned())?;
    Ok((product, data.product_recommendations.unwrap_or_default()))
}

fn payload(mut data: Value, field: &str) -> Result<CartPayload, String> {
    serde_json::from_value(data[field].take()).map_err(|e| e.to_string())
}

pub async fn cart_create(variant_id: &str) -> Result<CartPayload, String> {
    let data: Value = send(
        "CartCreate",
        CART_CREATE,
        json!({ "lines": [{ "merchandiseId": variant_id, "quantity": 1 }] }),
    )
    .await?;
    payload(data, "cartCreate")
}

pub async fn cart_lines_add(cart_id: &str, variant_id: &str) -> Result<CartPayload, String> {
    let data: Value = send(
        "CartLinesAdd",
        CART_LINES_ADD,
        json!({ "cartId": cart_id, "lines": [{ "merchandiseId": variant_id, "quantity": 1 }] }),
    )
    .await?;
    payload(data, "cartLinesAdd")
}

pub async fn cart_lines_update(cart_id: &str, line_id: &str, quantity: u32) -> Result<CartPayload, String> {
    let data: Value = send(
        "CartLinesUpdate",
        CART_LINES_UPDATE,
        json!({ "cartId": cart_id, "lines": [{ "id": line_id, "quantity": quantity }] }),
    )
    .await?;
    payload(data, "cartLinesUpdate")
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Every operation, as `spec/storefront.graphql` writes it.
    #[test]
    fn operations_match_the_spec() {
        let spec = include_str!("../spec/storefront.graphql");
        let squash = |s: &str| s.split_whitespace().collect::<Vec<_>>().join(" ");
        let spec = squash(spec);
        for doc in [
            HOME,
            COLLECTION_PRODUCTS,
            SEARCH,
            PRODUCT,
            CART_CREATE,
            CART_LINES_ADD,
            CART_LINES_UPDATE,
        ] {
            for part in doc.split("\n\n") {
                let part = squash(part);
                if !part.is_empty() {
                    assert!(spec.contains(&part), "not in the spec: {part}");
                }
            }
        }
    }
}
