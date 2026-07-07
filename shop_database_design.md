# Shop Feature — Complete Database Design

> **Status: Phase 3 — Orders & M-Pesa Complete ✅**
> All phases implemented: Banners, Categories, Products, Variants, Cart, Orders, M-Pesa Integration.

---

## Overview

```
shop_banners            ← Section 1: Dynamic banner image + text
shop_categories         ← Section 4: Category tabs (Jerseys, Socks, Gloves...)
shop_products           ← Section 2, 3, 4: All products
shop_product_variants   ← Sizes (S, M, L, XL) per product
shop_carts              ← One cart per user
shop_cart_items         ← Items inside a user's cart
shop_orders             ← A completed order placed from cart
shop_order_items        ← Snapshot of each item in an order
mpesa_transactions      ← Standard M-Pesa records (handles both tickets and shop)
```

---

## Table 1: `shop_banners` ✅

Used for **Section 1** — dynamic banner at the top of the shop screen.

| Column | Type | Description |
|---|---|---|
| `id` | bigint (PK) | Auto increment |
| `title` | string | e.g. `OFFICIAL MERCHANDISE` |
| `subtitle` | string (nullable) | e.g. `Wear Green. Live Green.` |
| `button_text` | string (nullable) | e.g. `SHOP NOW` |
| `image` | string | URL/path of the banner image |
| `target_type` | string (nullable) | Type of link (e.g. `product`, `category`) |
| `target_id` | bigint (nullable) | The ID of the target product/category |
| `is_active` | boolean | `1` = visible |
| `sort_order` | integer | For future carousel ordering |
| `created_at` | timestamp | Auto |
| `updated_at` | timestamp | Auto |

**API:** `GET /api/user/shop/banners`

---

## Table 2: `shop_categories` ✅

Used for **Section 4** — the horizontal category tabs.

| Column | Type | Description |
|---|---|---|
| `id` | bigint (PK) | Auto increment |
| `name` | string | e.g. `Jerseys`, `Socks`, `Gloves` |
| `icon` | string (nullable) | Optional icon URL |
| `sort_order` | integer | Controls display order |
| `is_active` | boolean | `1` = visible in app |
| `created_at` | timestamp | Auto |
| `updated_at` | timestamp | Auto |

**API:** `GET /api/user/shop/categories`

---

## Table 3: `shop_products` ✅

The main product table — handles Sections 2, 3, and 4.

| Column | Type | Description |
|---|---|---|
| `id` | bigint (PK) | Auto increment |
| `shop_category_id` | bigint (FK) | Links to `shop_categories.id` |
| `name` | string | e.g. `Official Home Jersey 24/25` |
| `description` | text (nullable) | Full product description |
| `price` | decimal(10,2) | Base price e.g. `2500.00` |
| `image` | string (nullable) | Product image URL/path |
| `is_new` | boolean | `1` = show in **New Arrivals** |
| `is_top_pick` | boolean | `1` = show in **Top Picks** |
| `is_active` | boolean | `1` = visible in app |
| `sort_order` | integer | Display order within category |
| `created_at` | timestamp | Auto |
| `updated_at` | timestamp | Auto |

**APIs:**
- `GET /api/user/shop/new-arrivals`
- `GET /api/user/shop/top-picks`
- `GET /api/user/shop/category/{id}/products`
- `GET /api/user/shop/product/{id}` — full detail + sizes

---

## Table 4: `shop_product_variants` ✅

Handles **size options** (S, M, L, XL) per product.

| Column | Type | Description |
|---|---|---|
| `id` | bigint (PK) | Auto increment |
| `shop_product_id` | bigint (FK) | Links to `shop_products.id` |
| `size` | string | `S`, `M`, `L`, `XL`, `One Size` |
| `stock` | integer | How many are in stock |
| `price_override` | decimal(10,2) (nullable) | Different price for this size |
| `is_available` | boolean | Toggle size on/off |
| `created_at` | timestamp | Auto |
| `updated_at` | timestamp | Auto |

---

## Table 5: `shop_carts` ✅

One cart per user. Auto-created on first add.

| Column | Type | Description |
|---|---|---|
| `id` | bigint (PK) | Auto increment |
| `user_id` | bigint (FK) | Links to `users.id` |
| `created_at` | timestamp | Auto |
| `updated_at` | timestamp | Auto |

---

## Table 6: `shop_cart_items` ✅

Each row is one product+size combination in a user's cart.

| Column | Type | Description |
|---|---|---|
| `id` | bigint (PK) | Auto increment |
| `shop_cart_id` | bigint (FK) | Links to `shop_carts.id` |
| `shop_product_id` | bigint (FK) | Which product |
| `shop_product_variant_id` | bigint (FK, nullable) | Which size (null if no size needed) |
| `quantity` | integer | How many items |
| `created_at` | timestamp | Auto |
| `updated_at` | timestamp | Auto |

**Cart APIs:** (🔐 requires login)
- `GET /api/user/shop/cart`
- `POST /api/user/shop/cart/add`
- `PUT /api/user/shop/cart/item/{id}`
- `DELETE /api/user/shop/cart/item/{id}`
- `DELETE /api/user/shop/cart/clear`

---

## Table 7: `shop_orders` ✅

A confirmed order placed by the user from the cart.

| Column | Type | Description |
|---|---|---|
| `id` | bigint (PK) | Auto increment |
| `user_id` | bigint (FK) | Links to `users.id` |
| `order_number` | string (unique) | e.g. `ORD-20260702-A3F1` |
| `total_amount` | decimal(10,2) | Grand total |
| `status` | enum | `pending` → `confirmed` → `shipped` → `delivered` \| `cancelled` |
| `delivery_name` | string (nullable) | Recipient name |
| `delivery_phone` | string (nullable) | Recipient phone |
| `delivery_address` | text (nullable) | Full delivery address |
| `payment_status` | enum | `unpaid` or `paid` |
| `payment_method` | string (nullable) | `mpesa`, `cash_on_delivery` |
| `payment_reference` | string (nullable) | M-Pesa transaction ID |
| `notes` | text (nullable) | Any special instructions |
| `created_at` | timestamp | Auto |
| `updated_at` | timestamp | Auto |

> [!TIP]
> **Order Number** is human-readable (e.g. `ORD-20260702-A3F1`) so the user can quote it for support.
>
> **Price snapshots** are stored in `shop_order_items` so order history stays accurate even if product prices change later.

---

## Table 8: `shop_order_items` ✅

A frozen snapshot of each cart item at the time of ordering.

| Column | Type | Description |
|---|---|---|
| `id` | bigint (PK) | Auto increment |
| `shop_order_id` | bigint (FK) | Links to `shop_orders.id` |
| `shop_product_id` | bigint (FK) | The product |
| `shop_product_variant_id` | bigint (FK, nullable) | The size chosen |
| `product_name` | string | **Snapshot** of name at order time |
| `size` | string (nullable) | **Snapshot** of size at order time |
| `unit_price` | decimal(10,2) | **Snapshot** of price at order time |
| `quantity` | integer | Quantity ordered |
| `subtotal` | decimal(10,2) | `unit_price × quantity` |
| `created_at` | timestamp | Auto |
| `updated_at` | timestamp | Auto |

---

## M-Pesa Integration Flow

**How it works:**
1. User places an order via `/api/user/shop/order/place` and gets a `shop_order_id`.
2. App calls `/api/user/shop/mpesa/stk-push` sending the `shop_order_id` and `phone`.
3. The API prefixes the order ID with `SHOP-` (e.g., `SHOP-15`) when talking to Safaricom/Daraja, so the main callback knows what type of order it is.
4. Safaricom sends the STK push to the user's phone.
5. While the user enters their PIN, the app polls `/api/user/shop/mpesa/status/{checkoutRequestId}`.
6. Once the user pays, Safaricom sends a callback to the main `MpesaController@callback`.
7. The callback checks if the order ID starts with `SHOP-`. If yes, it updates the `shop_orders` table (sets `payment_status = paid`, saves receipt, and sets `status = confirmed`).
8. The app polling sees `success` and shows a confirmation screen.

---

## Full Relationship Map

```
shop_categories  (1) ──→ (many) shop_products
shop_products    (1) ──→ (many) shop_product_variants
users            (1) ──→ (1)    shop_carts
shop_carts       (1) ──→ (many) shop_cart_items
shop_cart_items  (→) shop_products
shop_cart_items  (→) shop_product_variants
users            (1) ──→ (many) shop_orders
shop_orders      (1) ──→ (many) shop_order_items
shop_order_items (→) shop_products
shop_order_items (→) shop_product_variants
```

---

## All API Endpoints Summary

| # | Method | Endpoint | Auth | Description |
|---|---|---|---|---|
| 1 | GET | `/api/user/shop/banners` | ❌ | Get active banners |
| 2 | GET | `/api/user/shop/categories` | ❌ | Get all categories |
| 3 | GET | `/api/user/shop/new-arrivals` | ❌ | Products where `is_new = 1` |
| 4 | GET | `/api/user/shop/top-picks` | ❌ | Products where `is_top_pick = 1` |
| 5 | GET | `/api/user/shop/category/{id}/products` | ❌ | Products by category |
| 6 | GET | `/api/user/shop/product/{id}` | ❌ | Single product + sizes |
| 7 | GET | `/api/user/shop/cart` | 🔐 | View cart |
| 8 | POST | `/api/user/shop/cart/add` | 🔐 | Add item to cart |
| 9 | PUT | `/api/user/shop/cart/item/{id}` | 🔐 | Update quantity |
| 10 | DELETE | `/api/user/shop/cart/item/{id}` | 🔐 | Remove item |
| 11 | DELETE | `/api/user/shop/cart/clear` | 🔐 | Clear entire cart |
| 12 | POST | `/api/user/shop/order/place` | 🔐 | Place order from cart |
| 13 | GET | `/api/user/shop/orders` | 🔐 | My order history |
| 14 | GET | `/api/user/shop/order/{id}` | 🔐 | Order detail |
| 15 | POST | `/api/user/shop/order/{id}/cancel` | 🔐 | Cancel pending order |
| 16 | POST | `/api/user/shop/mpesa/stk-push` | 🔐 | Send M-Pesa prompt for a shop order |
| 17 | GET | `/api/user/shop/mpesa/status/{id}`| 🔐 | Poll M-Pesa payment status |

---

## Order Status Flow

```
[pending] → [confirmed] → [shipped] → [delivered]
    ↓
[cancelled]  ← only possible from 'pending'
```

> [!NOTE]
> Status transitions (`confirmed`, `shipped`, `delivered`) are managed from the **Admin Panel** on the web side. The app only reads the status and can cancel if still `pending`.

---

## Detailed API Requests & Responses

Below are the exact JSON request bodies and response examples to help you test quickly in Postman or Flutter.

### 1-6. Browsing (No Auth Required)

**GET `/api/user/shop/banners`**
```json
// Response
{
  "status": true,
  "message": "Banners fetched successfully",
  "data": [
    {
      "id": 1,
      "title": "OFFICIAL MERCHANDISE",
      "button_text": "SHOP NOW",
      "image": "assets/images/banner.png",
      "target_type": "product",
      "target_id": 1
    }
  ]
}
```

**GET `/api/user/shop/product/{id}`**
```json
// Response
{
  "status": true,
  "message": "Product details fetched successfully",
  "data": {
    "id": 1,
    "name": "Official Home Jersey 24/25",
    "price": "2500.00",
    "image": "assets/images/home_jersey.png",
    "variants": [
      { "id": 1, "size": "M", "stock": 50, "price_override": null },
      { "id": 2, "size": "L", "stock": 30, "price_override": null }
    ]
  }
}
```

### 7-11. Cart Management (Auth: Bearer Token)

**POST `/api/user/shop/cart/add`**
```json
// Request Body
{
  "shop_product_id": 1,
  "shop_product_variant_id": 2,
  "quantity": 2
}

// Response
{
  "status": true,
  "message": "Item added to cart."
}
```

**PUT `/api/user/shop/cart/item/{id}`**
*(Note: `{id}` is the ID of the `shop_cart_item`, not the product)*
```json
// Request Body
{
  "quantity": 3
}

// Response
{
  "status": true,
  "message": "Cart item updated."
}
```

**GET `/api/user/shop/cart`**
```json
// Response
{
  "status": true,
  "data": {
    "id": 1,
    "items": [
      {
        "id": 5,
        "quantity": 2,
        "product": { "id": 1, "name": "Official Home Jersey", "price": "2500.00" },
        "variant": { "id": 2, "size": "L" }
      }
    ],
    "cart_total": 5000.00
  }
}
```

### 12-15. Orders (Auth: Bearer Token)

**POST `/api/user/shop/order/place`**
```json
// Request Body
{
  "delivery_name": "Bella Swan",
  "delivery_phone": "254712345678",
  "delivery_address": "Nairobi CBD, Tom Mboya Street",
  "payment_method": "mpesa",
  "notes": "Please call before delivery"
}

// Response
{
  "status": true,
  "message": "Order placed successfully.",
  "data": {
    "order_id": 15,
    "order_number": "ORD-20260702-A3F1",
    "total_amount": "5000.00"
  }
}
```

**GET `/api/user/shop/orders`**
```json
// Response
{
  "status": true,
  "data": [
    {
      "id": 15,
      "order_number": "ORD-20260702-A3F1",
      "total_amount": "5000.00",
      "status": "pending",
      "payment_status": "unpaid",
      "items": [
        {
          "product_name": "Official Home Jersey",
          "size": "L",
          "unit_price": "2500.00",
          "quantity": 2,
          "subtotal": "5000.00"
        }
      ]
    }
  ]
}
```

### 16-17. M-Pesa Payment (Auth: Bearer Token)

**POST `/api/user/shop/mpesa/stk-push`**
```json
// Request Body
{
  "shop_order_id": 15,
  "phone": "254712345678"
}

// Response
{
  "status": true,
  "message": "Check your phone and enter your M-Pesa PIN to complete payment.",
  "data": {
    "checkout_request_id": "ws_CO_02072026123456",
    "order_id": "SHOP-15",
    "amount": 5000
  }
}
```

**GET `/api/user/shop/mpesa/status/{checkoutRequestId}`**
```json
// Response (While waiting)
{
  "status": true,
  "payment": "pending",
  "message": "Waiting for M-Pesa confirmation."
}

// Response (Success)
{
  "status": true,
  "payment": "success",
  "message": "Payment confirmed! Your order is being processed.",
  "data": {
    "order_number": "ORD-20260702-A3F1",
    "mpesa_receipt": "SGH234KJD",
    "amount": 5000
  }
}
```
