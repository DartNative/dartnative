import NativeShopBench from '../specs/NativeShopBench';

const DEFAULT_ENDPOINT = 'https://apparel-large-catalog.mock.shop/api';
const REQUEST_TIMEOUT_MS = 15000;

let endpoint: string | null = null;
function getEndpoint(): string {
  if (endpoint === null) {
    let override = '';
    try {
      override = NativeShopBench.getApiUrl().trim();
    } catch {
      override = '';
    }
    endpoint = override !== '' ? override : DEFAULT_ENDPOINT;
  }
  return endpoint;
}

export type Money = { amount: string; currencyCode: string };
export type Image = { url: string; altText: string | null } | null;

export type ProductCardData = {
  id: string;
  handle: string;
  title: string;
  featuredImage: Image;
  priceRange: { minVariantPrice: Money };
  compareAtPriceRange: { minVariantPrice: Money };
};

export type PageInfo = { hasNextPage: boolean; endCursor: string | null };

export type Collection = {
  id: string;
  handle: string;
  title: string;
  image: Image;
};

export type HomeData = {
  collections: { nodes: Collection[] };
  products: { nodes: ProductCardData[] };
};

export type CollectionProductsData = {
  collection: {
    id: string;
    title: string;
    description: string;
    products: { pageInfo: PageInfo; nodes: ProductCardData[] };
  } | null;
};

export type SearchData = {
  search: {
    totalCount: number;
    pageInfo: PageInfo;
    nodes: Array<ProductCardData | {}>;
  };
};

export type Variant = {
  id: string;
  title: string;
  availableForSale: boolean;
  selectedOptions: { name: string; value: string }[];
  price: Money;
  compareAtPrice: Money | null;
};

export type ProductData = {
  product: {
    id: string;
    handle: string;
    title: string;
    description: string;
    images: { nodes: { url: string; altText: string | null }[] };
    options: { name: string; optionValues: { name: string }[] }[];
    variants: { nodes: Variant[] };
  } | null;
  productRecommendations: ProductCardData[] | null;
};

export type CartLine = {
  id: string;
  quantity: number;
  cost: { totalAmount: Money };
  merchandise: {
    id: string;
    title: string;
    image: Image;
    product: { handle: string; title: string; featuredImage: Image };
  };
};

export type Cart = {
  id: string;
  checkoutUrl: string;
  totalQuantity: number;
  cost: { subtotalAmount: Money };
  lines: { nodes: CartLine[] };
};

export type CartPayload = {
  cart: Cart | null;
  userErrors: { field: string[] | null; message: string }[];
};

export async function gql<T>(
  operationName: string,
  query: string,
  variables: Record<string, unknown> = {},
): Promise<T> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  try {
    const res = await fetch(getEndpoint(), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ operationName, query, variables }),
      signal: controller.signal,
    });
    if (!res.ok) {
      throw new Error(`HTTP ${res.status}`);
    }
    const json = await res.json();
    if (json.errors && json.errors.length > 0 && !json.data) {
      throw new Error(json.errors[0].message ?? 'GraphQL error');
    }
    if (!json.data) {
      throw new Error('Empty response');
    }
    return json.data as T;
  } finally {
    clearTimeout(timer);
  }
}

export function formatMoney(m: Money | null | undefined): string {
  if (!m) {
    return '';
  }
  const n = parseFloat(m.amount);
  return '$' + (isNaN(n) ? '0.00' : n.toFixed(2));
}

export function isDiscounted(price: Money, compare: Money | null | undefined): boolean {
  if (!compare) {
    return false;
  }
  return parseFloat(compare.amount) > parseFloat(price.amount);
}

export function imageUrl(url: string | null | undefined, width: number): string | undefined {
  if (!url) {
    return undefined;
  }
  return url + (url.includes('?') ? '&' : '?') + 'width=' + width;
}

export function isProduct(node: ProductCardData | {}): node is ProductCardData {
  return (node as ProductCardData).id !== undefined;
}
