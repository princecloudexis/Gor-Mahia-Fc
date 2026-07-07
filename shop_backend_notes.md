# Shop Backend Notes & Missing Features

While reviewing the `shop_database_design.md` to implement the frontend, I identified a few missing features and potential improvements for the backend APIs. Please consider adding these to improve the user experience.

## 1. Search Functionality
**Missing:** There is currently no endpoint to search for products by name or description.
**Proposed API:** `GET /api/user/shop/search?q={query}`
**Reason:** In an e-commerce app, users often want to search for specific items (e.g., "away kit" or "gloves") rather than scrolling through categories.

## 2. Pagination for Products
**Missing:** Endpoints like `/api/user/shop/category/{id}/products` and `/api/user/shop/new-arrivals` return a list of items. If the shop grows to 100+ items, returning all of them at once will slow down the app.
**Proposed Update:** Implement standard pagination (e.g., Laravel's `->paginate(15)`) for product listing APIs. The app can then implement pull-to-refresh and infinite scrolling.

## 3. Cart Item Count Endpoint
**Missing:** To show a badge with the number of items in the cart on the top App Bar, the app currently has to fetch the entire cart (`GET /api/user/shop/cart`). 
**Proposed API:** `GET /api/user/shop/cart/count`
**Reason:** A lightweight endpoint that just returns `{"count": 3}` is much faster for UI updates across different screens.

## 4. Wishlist / Favorites (Optional but recommended)
**Missing:** Users cannot save items they like for later.
**Proposed Tables/APIs:** `shop_wishlists` table and APIs like `POST /api/user/shop/wishlist/add` and `GET /api/user/shop/wishlist`.

## 5. Product Ratings and Reviews (Optional)
**Missing:** No way to see reviews or ratings on a product.
**Proposed Tables:** `shop_product_reviews` with columns like `rating` (1-5), `comment`, `user_id`.

## 6. Image Base URL Handling
**Note:** Ensure the backend either returns full absolute URLs for images (e.g., `https://domain.com/storage/products/image.png`) OR the app will prepend the base URL. Returning absolute URLs directly from the API Resource is usually easier.
