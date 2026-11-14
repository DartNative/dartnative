// Copied verbatim from spec/storefront.graphql.
const String kStorefrontDocument = r'''fragment ProductCard on Product {
  id
  handle
  title
  featuredImage { url altText }
  priceRange { minVariantPrice { amount currencyCode } }
  compareAtPriceRange { minVariantPrice { amount currencyCode } }
}

fragment CartFields on Cart {
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

query Home {
  collections(first: 20) {
    nodes { id handle title image { url altText } }
  }
  products(first: 10, sortKey: BEST_SELLING) {
    nodes { ...ProductCard }
  }
}

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

query Search($query: String!, $first: Int!, $after: String) {
  search(query: $query, first: $first, after: $after, types: PRODUCT) {
    totalCount
    pageInfo { hasNextPage endCursor }
    nodes { ... on Product { ...ProductCard } }
  }
}

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

mutation CartCreate($lines: [CartLineInput!]!) {
  cartCreate(input: { lines: $lines }) {
    cart { ...CartFields }
    userErrors { field message }
  }
}

mutation CartLinesAdd($cartId: ID!, $lines: [CartLineInput!]!) {
  cartLinesAdd(cartId: $cartId, lines: $lines) {
    cart { ...CartFields }
    userErrors { field message }
  }
}

mutation CartLinesUpdate($cartId: ID!, $lines: [CartLineUpdateInput!]!) {
  cartLinesUpdate(cartId: $cartId, lines: $lines) {
    cart { ...CartFields }
    userErrors { field message }
  }
}
''';
