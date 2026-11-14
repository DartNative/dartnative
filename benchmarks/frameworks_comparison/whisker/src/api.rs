//! Storefront GraphQL over plain HTTP POST (via the platform HTTP stack).

use serde::Deserialize;
use serde::de::DeserializeOwned;
use serde_json::{Value, json};

const DEFAULT_ENDPOINT: &str = "https://apparel-large-catalog.mock.shop/api";

/// Runtime `SHOP_API_URL` (iOS launch environment), then the build-time
/// value (Android), then the default endpoint.
pub fn endpoint() -> String {
    if let Ok(v) = std::env::var("SHOP_API_URL") {
        if !v.trim().is_empty() {
            return v.trim().to_string();
        }
    }
    if let Some(v) = option_env!("SHOP_API_URL") {
        if !v.trim().is_empty() {
            return v.trim().to_string();
        }
    }
    DEFAULT_ENDPOINT.to_string()
}

// Documents are copied verbatim from spec/storefront.graphql.

const PRODUCT_CARD: &str = "fragment ProductCard on Product {
  id
  handle
  title
  featuredImage { url altText }
  priceRange { minVariantPrice { amount currencyCode } }
  compareAtPriceRange { minVariantPrice { amount currencyCode } }
}";

const CART_FIELDS: &str = "fragment CartFields on Cart {
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
}";

const HOME: &str = "query Home {
  collections(first: 20) {
    nodes { id handle title image { url altText } }
  }
  products(first: 10, sortKey: BEST_SELLING) {
    nodes { ...ProductCard }
  }
}";

const COLLECTION_PRODUCTS: &str = "query CollectionProducts($handle: String!, $first: Int!, $after: String, $sortKey: ProductCollectionSortKeys!, $reverse: Boolean!) {
  collection(handle: $handle) {
    id
    title
    description
    products(first: $first, after: $after, sortKey: $sortKey, reverse: $reverse) {
      pageInfo { hasNextPage endCursor }
      nodes { ...ProductCard }
    }
  }
}";

const SEARCH: &str = "query Search($query: String!, $first: Int!, $after: String) {
  search(query: $query, first: $first, after: $after, types: PRODUCT) {
    totalCount
    pageInfo { hasNextPage endCursor }
    nodes { ... on Product { ...ProductCard } }
  }
}";

const PRODUCT: &str = "query Product($handle: String!) {
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
}";

const CART_CREATE: &str = "mutation CartCreate($lines: [CartLineInput!]!) {
  cartCreate(input: { lines: $lines }) {
    cart { ...CartFields }
    userErrors { field message }
  }
}";

const CART_LINES_ADD: &str = "mutation CartLinesAdd($cartId: ID!, $lines: [CartLineInput!]!) {
  cartLinesAdd(cartId: $cartId, lines: $lines) {
    cart { ...CartFields }
    userErrors { field message }
  }
}";

const CART_LINES_UPDATE: &str =
    "mutation CartLinesUpdate($cartId: ID!, $lines: [CartLineUpdateInput!]!) {
  cartLinesUpdate(cartId: $cartId, lines: $lines) {
    cart { ...CartFields }
    userErrors { field message }
  }
}";

// ---- Models ----

#[derive(Clone, Debug, PartialEq, Deserialize)]
pub struct Money {
    pub amount: String,
    #[serde(rename = "currencyCode")]
    pub currency_code: String,
}

impl Money {
    pub fn value(&self) -> f64 {
        self.amount.parse().unwrap_or(0.0)
    }
    pub fn display(&self) -> String {
        format!("${:.2}", self.value())
    }
}

#[derive(Clone, Debug, PartialEq, Deserialize)]
pub struct ImageRef {
    pub url: String,
}

#[derive(Clone, Debug, PartialEq, Deserialize)]
struct MinPrice {
    #[serde(rename = "minVariantPrice")]
    min_variant_price: Money,
}

#[derive(Clone, Debug, PartialEq, Deserialize)]
pub struct ProductCard {
    pub id: String,
    pub handle: String,
    pub title: String,
    #[serde(rename = "featuredImage")]
    pub featured_image: Option<ImageRef>,
    #[serde(rename = "priceRange")]
    price_range: MinPrice,
    #[serde(rename = "compareAtPriceRange")]
    compare_at_price_range: MinPrice,
}

impl ProductCard {
    pub fn price(&self) -> &Money {
        &self.price_range.min_variant_price
    }
    pub fn compare_at(&self) -> &Money {
        &self.compare_at_price_range.min_variant_price
    }
}

#[derive(Clone, Debug, PartialEq, Deserialize)]
pub struct Collection {
    pub id: String,
    pub handle: String,
    pub title: String,
    pub image: Option<ImageRef>,
}

#[derive(Deserialize)]
struct Nodes<T> {
    nodes: Vec<T>,
}

#[derive(Clone, Debug, PartialEq, Deserialize)]
pub struct PageInfo {
    #[serde(rename = "hasNextPage")]
    pub has_next_page: bool,
    #[serde(rename = "endCursor")]
    pub end_cursor: Option<String>,
}

#[derive(Clone, Debug, PartialEq)]
pub struct HomeData {
    pub collections: Vec<Collection>,
    pub products: Vec<ProductCard>,
}

#[derive(Clone, Debug, PartialEq)]
pub struct ProductPage {
    pub title: String,
    pub description: String,
    pub page_info: PageInfo,
    pub products: Vec<ProductCard>,
    pub total_count: i64,
}

#[derive(Clone, Debug, PartialEq, Deserialize)]
pub struct OptionValue {
    pub name: String,
}

#[derive(Clone, Debug, PartialEq, Deserialize)]
pub struct ProductOption {
    pub name: String,
    #[serde(rename = "optionValues")]
    pub option_values: Vec<OptionValue>,
}

#[derive(Clone, Debug, PartialEq, Deserialize)]
pub struct SelectedOption {
    pub name: String,
    pub value: String,
}

#[derive(Clone, Debug, PartialEq, Deserialize)]
pub struct Variant {
    pub id: String,
    pub title: String,
    #[serde(rename = "availableForSale")]
    pub available_for_sale: bool,
    #[serde(rename = "selectedOptions")]
    pub selected_options: Vec<SelectedOption>,
    pub price: Money,
    #[serde(rename = "compareAtPrice")]
    pub compare_at_price: Option<Money>,
}

#[derive(Clone, Debug, PartialEq)]
pub struct ProductDetail {
    pub title: String,
    pub description: String,
    pub images: Vec<String>,
    pub options: Vec<ProductOption>,
    pub variants: Vec<Variant>,
    pub recommendations: Vec<ProductCard>,
}

#[derive(Clone, Debug, PartialEq, Deserialize)]
pub struct CartLineProduct {
    pub title: String,
    #[serde(rename = "featuredImage")]
    pub featured_image: Option<ImageRef>,
}

#[derive(Clone, Debug, PartialEq, Deserialize)]
pub struct Merchandise {
    pub id: String,
    pub title: String,
    pub image: Option<ImageRef>,
    pub product: CartLineProduct,
}

#[derive(Clone, Debug, PartialEq, Deserialize)]
struct LineCost {
    #[serde(rename = "totalAmount")]
    total_amount: Money,
}

#[derive(Clone, Debug, PartialEq, Deserialize)]
pub struct CartLine {
    pub id: String,
    pub quantity: i64,
    cost: LineCost,
    pub merchandise: Merchandise,
}

impl CartLine {
    pub fn total(&self) -> &Money {
        &self.cost.total_amount
    }
}

#[derive(Clone, Debug, PartialEq, Deserialize)]
struct CartCost {
    #[serde(rename = "subtotalAmount")]
    subtotal_amount: Money,
}

#[derive(Clone, Debug, PartialEq, Deserialize)]
struct CartLines {
    nodes: Vec<CartLine>,
}

#[derive(Clone, Debug, PartialEq, Deserialize)]
pub struct Cart {
    pub id: String,
    #[serde(rename = "checkoutUrl")]
    pub checkout_url: String,
    #[serde(rename = "totalQuantity")]
    pub total_quantity: i64,
    cost: CartCost,
    lines: CartLines,
}

impl Cart {
    pub fn subtotal(&self) -> &Money {
        &self.cost.subtotal_amount
    }
    pub fn lines(&self) -> &[CartLine] {
        &self.lines.nodes
    }
}

#[derive(Clone, Debug, PartialEq, Deserialize)]
pub struct UserError {
    pub message: String,
}

#[derive(Deserialize)]
struct CartPayload {
    cart: Option<Cart>,
    #[serde(rename = "userErrors", default)]
    user_errors: Vec<UserError>,
}

pub struct CartResult {
    pub cart: Option<Cart>,
    pub user_errors: Vec<UserError>,
}

// ---- Transport ----

async fn execute<T: DeserializeOwned>(
    operation: &str,
    document: String,
    variables: Value,
) -> Result<T, String> {
    let body = json!({
        "operationName": operation,
        "query": document,
        "variables": variables,
    })
    .to_string();
    let text = shop_native::post_json(&endpoint(), body).await?;
    #[derive(Deserialize)]
    struct Envelope<T> {
        data: Option<T>,
        errors: Option<Vec<Value>>,
    }
    let envelope: Envelope<T> = serde_json::from_str(&text).map_err(|e| e.to_string())?;
    match (envelope.data, envelope.errors) {
        (Some(data), None) => Ok(data),
        (_, Some(errors)) if !errors.is_empty() => Err("GraphQL error".to_string()),
        (Some(data), _) => Ok(data),
        (None, _) => Err("empty response".to_string()),
    }
}

fn with_fragment(operation: &str, fragment: &str) -> String {
    format!("{operation}\n\n{fragment}")
}

pub async fn home() -> Result<HomeData, String> {
    #[derive(Deserialize)]
    struct Data {
        collections: Nodes<Collection>,
        products: Nodes<ProductCard>,
    }
    let data: Data = execute("Home", with_fragment(HOME, PRODUCT_CARD), json!({})).await?;
    Ok(HomeData {
        collections: data.collections.nodes,
        products: data.products.nodes,
    })
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Sort {
    Featured,
    BestSelling,
    PriceAsc,
    PriceDesc,
}

impl Sort {
    fn key(self) -> (&'static str, bool) {
        match self {
            Sort::Featured => ("COLLECTION_DEFAULT", false),
            Sort::BestSelling => ("BEST_SELLING", false),
            Sort::PriceAsc => ("PRICE", false),
            Sort::PriceDesc => ("PRICE", true),
        }
    }
}

pub async fn collection_products(
    handle: String,
    sort: Sort,
    after: Option<String>,
) -> Result<ProductPage, String> {
    #[derive(Deserialize)]
    struct Products {
        #[serde(rename = "pageInfo")]
        page_info: PageInfo,
        nodes: Vec<ProductCard>,
    }
    #[derive(Deserialize)]
    struct Coll {
        title: String,
        description: String,
        products: Products,
    }
    #[derive(Deserialize)]
    struct Data {
        collection: Option<Coll>,
    }
    let (sort_key, reverse) = sort.key();
    let data: Data = execute(
        "CollectionProducts",
        with_fragment(COLLECTION_PRODUCTS, PRODUCT_CARD),
        json!({
            "handle": handle,
            "first": 24,
            "after": after,
            "sortKey": sort_key,
            "reverse": reverse,
        }),
    )
    .await?;
    let c = data
        .collection
        .ok_or_else(|| "collection not found".to_string())?;
    Ok(ProductPage {
        title: c.title,
        description: c.description,
        page_info: c.products.page_info,
        products: c.products.nodes,
        total_count: 0,
    })
}

pub async fn search(query: String, after: Option<String>) -> Result<ProductPage, String> {
    #[derive(Deserialize)]
    struct Search {
        #[serde(rename = "totalCount")]
        total_count: i64,
        #[serde(rename = "pageInfo")]
        page_info: PageInfo,
        nodes: Vec<ProductCard>,
    }
    #[derive(Deserialize)]
    struct Data {
        search: Search,
    }
    let data: Data = execute(
        "Search",
        with_fragment(SEARCH, PRODUCT_CARD),
        json!({ "query": query, "first": 24, "after": after }),
    )
    .await?;
    Ok(ProductPage {
        title: String::new(),
        description: String::new(),
        page_info: data.search.page_info,
        products: data.search.nodes,
        total_count: data.search.total_count,
    })
}

pub async fn product(handle: String) -> Result<ProductDetail, String> {
    #[derive(Deserialize)]
    struct Product {
        title: String,
        description: String,
        images: Nodes<ImageRef>,
        options: Vec<ProductOption>,
        variants: Nodes<Variant>,
    }
    #[derive(Deserialize)]
    struct Data {
        product: Option<Product>,
        #[serde(rename = "productRecommendations")]
        product_recommendations: Option<Vec<ProductCard>>,
    }
    let data: Data = execute(
        "Product",
        with_fragment(PRODUCT, PRODUCT_CARD),
        json!({ "handle": handle }),
    )
    .await?;
    let p = data
        .product
        .ok_or_else(|| "product not found".to_string())?;
    Ok(ProductDetail {
        title: p.title,
        description: p.description,
        images: p.images.nodes.into_iter().map(|i| i.url).collect(),
        options: p.options,
        variants: p.variants.nodes,
        recommendations: data.product_recommendations.unwrap_or_default(),
    })
}

async fn cart_mutation(
    operation: &str,
    document: &str,
    field: &str,
    variables: Value,
) -> Result<CartResult, String> {
    let data: Value = execute(operation, with_fragment(document, CART_FIELDS), variables).await?;
    let payload = data
        .get(field)
        .cloned()
        .ok_or_else(|| "missing payload".to_string())?;
    let payload: CartPayload = serde_json::from_value(payload).map_err(|e| e.to_string())?;
    Ok(CartResult {
        cart: payload.cart,
        user_errors: payload.user_errors,
    })
}

pub async fn cart_create(variant_id: String) -> Result<CartResult, String> {
    cart_mutation(
        "CartCreate",
        CART_CREATE,
        "cartCreate",
        json!({ "lines": [{ "merchandiseId": variant_id, "quantity": 1 }] }),
    )
    .await
}

pub async fn cart_lines_add(cart_id: String, variant_id: String) -> Result<CartResult, String> {
    cart_mutation(
        "CartLinesAdd",
        CART_LINES_ADD,
        "cartLinesAdd",
        json!({ "cartId": cart_id, "lines": [{ "merchandiseId": variant_id, "quantity": 1 }] }),
    )
    .await
}

pub async fn cart_lines_update(
    cart_id: String,
    line_id: String,
    quantity: i64,
) -> Result<CartResult, String> {
    cart_mutation(
        "CartLinesUpdate",
        CART_LINES_UPDATE,
        "cartLinesUpdate",
        json!({ "cartId": cart_id, "lines": [{ "id": line_id, "quantity": quantity }] }),
    )
    .await
}

/// Appends the `width` query parameter the spec requires before loading.
pub fn sized(url: &str, width: u32) -> String {
    if url.contains('?') {
        format!("{url}&width={width}")
    } else {
        format!("{url}?width={width}")
    }
}
