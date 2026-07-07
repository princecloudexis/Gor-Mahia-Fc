# Shop Purchase APIs for Testing

Here are the API endpoints and the expected JSON responses used during the shop product purchase and M-Pesa checkout flow. You can use these structures to mock responses in your backend or use them in Postman for testing.

---

## 1. Place Order

**Endpoint:** `POST /api/user/shop/order/place`
**Auth:** Bearer Token (Sanctum)

This endpoint takes the items in the user's cart, calculates the total, and creates a new pending `ShopOrder`.

### Request Body (JSON)
```json
{
  "delivery_name": "John Doe",
  "delivery_phone": "254712345678",
  "delivery_address": "Nairobi CBD",
  "payment_method": "mpesa",
  "notes": "Please call upon arrival"
}
```

### Expected Response (Success)
```json
{
    "status": true,
    "message": "Order placed! Complete your payment via M-Pesa to confirm it.",
    "data": {
        "id": 101,
        "order_number": "ORD-20260704-ABCD",
        "status": "pending",
        "payment_status": "unpaid",
        "payment_method": "mpesa",
        "total_amount": 1500.00,
        "requires_mpesa": true,
        "items": [
            {
                "id": 501,
                "product_id": 10,
                "product_name": "Home Jersey",
                "product_image": "https://api.gormahia.com/admin/images/product.png",
                "size": "L",
                "unit_price": 1500.0,
                "quantity": 1,
                "subtotal": 1500.0
            }
        ]
    }
}
```

---

## 2. Initiate M-Pesa STK Push (Shop)

**Endpoint:** `POST /api/user/shop/mpesa/stk-push`
**Auth:** Bearer Token (Sanctum)

This endpoint triggers the M-Pesa STK push to the user's phone for the shop order they just placed.

### Request Body (JSON)
```json
{
  "shop_order_id": 101,
  "phone": "254712345678"
}
```

### Expected Response (Success)
```json
{
    "status": true,
    "message": "Check your phone and enter your M-Pesa PIN to complete payment.",
    "data": {
        "checkout_request_id": "ws_CO_04072026_1234567890",
        "order_id": "SHOP-101",
        "amount": 1500.00
    }
}
```

---

## 3. Check Payment Status

**Endpoint:** `GET /api/user/shop/mpesa/status/{checkoutRequestId}`
**Auth:** Bearer Token (Sanctum)

This endpoint polls the status of the M-Pesa transaction using the `checkout_request_id` returned from the STK push.

### Expected Response (Pending - User hasn't entered PIN yet)
```json
{
    "status": true,
    "payment": "pending",
    "message": "Waiting for M-Pesa confirmation."
}
```

### Expected Response (Failed - User cancelled or insufficient funds)
```json
{
    "status": true,
    "payment": "failed",
    "message": "The balance is insufficient for the transaction."
}
```

### Expected Response (Success - Payment Completed)
```json
{
    "status": true,
    "payment": "success",
    "message": "Payment confirmed! Your order is being processed.",
    "data": {
        "order_number": "ORD-20260704-ABCD",
        "mpesa_receipt": "SGH123ABCD",
        "amount": 1500.0,
        "items": [
            {
                "id": 501,
                "product_id": 10,
                "product_name": "Home Jersey",
                "product_image": "https://api.gormahia.com/admin/images/product.png",
                "size": "L",
                "unit_price": 1500.0,
                "quantity": 1,
                "subtotal": 1500.0
            }
        ]
    }
}
```
