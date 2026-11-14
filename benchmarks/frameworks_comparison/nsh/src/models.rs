//! The Storefront API's data, as the operations in `api.rs` select it.

use serde::Deserialize;

#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Money {
    pub amount: String,
    pub currency_code: String,
}

impl Money {
    /// The amount as a number (0 when it does not parse).
    pub fn value(&self) -> f64 {
        self.amount.parse().unwrap_or(0.0)
    }

    /// `$` and the amount with two decimals: `"75.0"` is `$75.00`.
    pub fn display(&self) -> String {
        format!("${:.2}", self.value())
    }
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ImageRef {
    pub url: String,
    pub alt_text: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct Nodes<T> {
    pub nodes: Vec<T>,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PageInfo {
    pub has_next_page: bool,
    pub end_cursor: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PriceRange {
    pub min_variant_price: Money,
}

/// `fragment ProductCard`.
#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ProductCard {
    pub id: String,
    pub handle: String,
    pub title: String,
    pub featured_image: Option<ImageRef>,
    pub price_range: PriceRange,
    pub compare_at_price_range: PriceRange,
}

impl ProductCard {
    pub fn price(&self) -> &Money {
        &self.price_range.min_variant_price
    }

    /// The compare-at price, when it is higher than the price.
    pub fn compare_at(&self) -> Option<&Money> {
        let compare = &self.compare_at_price_range.min_variant_price;
        (compare.value() > self.price().value()).then_some(compare)
    }
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Collection {
    pub id: String,
    pub handle: String,
    pub title: String,
    pub image: Option<ImageRef>,
}

/// `query Home`.
#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct HomeData {
    pub collections: Nodes<Collection>,
    pub products: Nodes<ProductCard>,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ProductConnection {
    pub page_info: PageInfo,
    pub nodes: Vec<ProductCard>,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct CollectionPage {
    pub id: String,
    pub title: String,
    pub description: String,
    pub products: ProductConnection,
}

/// `query CollectionProducts`.
#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct CollectionData {
    pub collection: Option<CollectionPage>,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SearchConnection {
    pub total_count: u32,
    pub page_info: PageInfo,
    /// Products; another kind of result would be an empty object.
    pub nodes: Vec<serde_json::Value>,
}

/// `query Search`.
#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct SearchData {
    pub search: SearchConnection,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct OptionValue {
    pub name: String,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ProductOption {
    pub name: String,
    pub option_values: Vec<OptionValue>,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct SelectedOption {
    pub name: String,
    pub value: String,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Variant {
    pub id: String,
    pub title: String,
    pub available_for_sale: bool,
    pub selected_options: Vec<SelectedOption>,
    pub price: Money,
    pub compare_at_price: Option<Money>,
}

impl Variant {
    /// The value it has for the option `name`.
    pub fn option(&self, name: &str) -> Option<&str> {
        self.selected_options
            .iter()
            .find(|o| o.name == name)
            .map(|o| o.value.as_str())
    }

    /// The compare-at price, when it is higher than the price.
    pub fn compare_at(&self) -> Option<&Money> {
        self.compare_at_price
            .as_ref()
            .filter(|compare| compare.value() > self.price.value())
    }
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct ProductDetail {
    pub id: String,
    pub handle: String,
    pub title: String,
    pub description: String,
    pub images: Nodes<ImageRef>,
    pub options: Vec<ProductOption>,
    pub variants: Nodes<Variant>,
}

impl ProductDetail {
    /// The options shown: all but a lone `Title` / `Default Title`.
    pub fn shown_options(&self) -> Vec<ProductOption> {
        self.options
            .iter()
            .filter(|o| {
                !(o.name == "Title"
                    && o.option_values.len() == 1
                    && o.option_values[0].name == "Default Title")
            })
            .cloned()
            .collect()
    }

    /// The variant selected at first: the first for sale, else the first.
    pub fn initial_variant(&self) -> usize {
        self.variants
            .nodes
            .iter()
            .position(|v| v.available_for_sale)
            .unwrap_or(0)
    }

    /// The variant to select when `name` is set to `value` while `current`
    /// is selected: the one whose options are all the current variant's with
    /// `name` changed, else the first with `name` = `value`.
    pub fn variant_with(&self, current: usize, name: &str, value: &str) -> Option<usize> {
        let variants = &self.variants.nodes;
        let wanted: Vec<(String, String)> = variants
            .get(current)
            .map(|v| {
                v.selected_options
                    .iter()
                    .map(|o| {
                        let value = if o.name == name { value } else { o.value.as_str() };
                        (o.name.clone(), value.to_owned())
                    })
                    .collect()
            })
            .unwrap_or_else(|| vec![(name.to_owned(), value.to_owned())]);
        variants
            .iter()
            .position(|v| wanted.iter().all(|(n, val)| v.option(n) == Some(val.as_str())))
            .or_else(|| variants.iter().position(|v| v.option(name) == Some(value)))
    }
}

/// `query Product`.
#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ProductData {
    pub product: Option<ProductDetail>,
    pub product_recommendations: Option<Vec<ProductCard>>,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CartCost {
    pub subtotal_amount: Money,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LineCost {
    pub total_amount: Money,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LineProduct {
    pub handle: String,
    pub title: String,
    pub featured_image: Option<ImageRef>,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct Merchandise {
    pub id: String,
    pub title: String,
    pub image: Option<ImageRef>,
    pub product: LineProduct,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct CartLine {
    pub id: String,
    pub quantity: u32,
    pub cost: LineCost,
    pub merchandise: Merchandise,
}

impl CartLine {
    /// The variant's image, else the product's.
    pub fn image(&self) -> Option<&ImageRef> {
        self.merchandise
            .image
            .as_ref()
            .or(self.merchandise.product.featured_image.as_ref())
    }

    /// The variant's title, unless it is `Default Title`.
    pub fn variant_title(&self) -> Option<&str> {
        let title = self.merchandise.title.as_str();
        (title != "Default Title" && !title.is_empty()).then_some(title)
    }
}

/// `fragment CartFields`.
#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Cart {
    pub id: String,
    pub checkout_url: String,
    pub total_quantity: u32,
    pub cost: CartCost,
    pub lines: Nodes<CartLine>,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct UserError {
    pub message: String,
}

/// The payload of every cart mutation.
#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CartPayload {
    pub cart: Option<Cart>,
    #[serde(default)]
    pub user_errors: Vec<UserError>,
}

/// `image` with the `width` parameter the screen loads it at.
pub fn image_url(image: Option<&ImageRef>, width: u32) -> String {
    match image {
        Some(image) if !image.url.is_empty() => {
            let sep = if image.url.contains('?') { '&' } else { '?' };
            format!("{}{sep}width={width}", image.url)
        }
        _ => String::new(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn money(amount: &str) -> Money {
        Money {
            amount: amount.into(),
            currency_code: "USD".into(),
        }
    }

    #[test]
    fn money_has_two_decimals() {
        assert_eq!(money("75.0").display(), "$75.00");
        assert_eq!(money("120").display(), "$120.00");
        assert_eq!(money("45.5").display(), "$45.50");
    }

    #[test]
    fn images_get_a_width() {
        let plain = ImageRef {
            url: "https://cdn.example/a.jpg".into(),
            alt_text: None,
        };
        let query = ImageRef {
            url: "https://cdn.example/a.jpg?v=1".into(),
            alt_text: None,
        };
        assert_eq!(image_url(Some(&plain), 480), "https://cdn.example/a.jpg?width=480");
        assert_eq!(image_url(Some(&query), 240), "https://cdn.example/a.jpg?v=1&width=240");
        assert_eq!(image_url(None, 240), "");
    }
}
