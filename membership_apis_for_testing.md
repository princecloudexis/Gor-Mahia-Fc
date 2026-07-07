# Membership APIs for Testing

Here are the API endpoints and expected JSON structures used during the membership purchase and M-Pesa checkout flow. You can use these structures to test the app UI or mock backend responses.

---

## 1. Save Membership Details (Before Payment)

**Endpoint:** `POST /api/user/membership`
**Auth:** Bearer Token (Sanctum)

This endpoint saves the user's membership details and calculates the final cost before initiating the M-Pesa STK push.

### Request Body (JSON)
```json
{
  "user_id": 1,
  "country": "Kenya",
  "branch_id": 2,
  "package_type_id": 3
}
```

### Expected Response (Success)
```json
{
    "status": 201,
    "success": true,
    "message": "Details saved. Proceed to payment.",
    "data": {
        "membership_id": 55,
        "package_name": "Platinum Membership",
        "price": 1000.0,
        "vat": 160.0,
        "vat_rate": 0.16,
        "platform_charge": 50.0,
        "amount": 1210.0
    }
}
```
*(Note: `amount` here is the `price` + `vat` + `platform_charge`)*

---

## 2. Initiate M-Pesa STK Push (Membership)

**Endpoint:** `POST /api/user/pay`
**Auth:** Bearer Token (Sanctum)

This endpoint triggers the M-Pesa STK push for the membership total amount.

### Request Body (JSON)
```json
{
  "membership_id": 55,
  "phone": "254712345678",
  "payment_status": "pending" 
}
```

### Expected Response (Success)
```json
{
    "status": 200,
    "success": true,
    "message": "Check your phone and enter your M-Pesa PIN to complete payment.",
    "data": {
        "checkout_request_id": "ws_CO_04072026_9876543210",
        "membership_id": 55
    }
}
```

---

## 3. Check Payment Status (Membership)

**Endpoint:** `POST /api/user/status`
**Auth:** Bearer Token (Sanctum)

This endpoint checks if the STK push was successful and activates the membership if the M-Pesa transaction is successful.

### Request Body (JSON)
```json
{
  "checkout_request_id": "ws_CO_04072026_9876543210",
  "membership_id": 55,
  "payment_status": "pending",
  "plan": "paid"
}
```

### Expected Response (Pending - User hasn't entered PIN)
```json
{
    "success": true,
    "status": "pending",
    "message": "Waiting for M-Pesa confirmation."
}
```

### Expected Response (Failed)
```json
{
    "status": 200,
    "success": true,
    "message": "The balance is insufficient for the transaction."
}
```

### Expected Response (Success - Payment Completed & Membership Activated)
```json
{
    "status": 200,
    "success": true,
    "message": "Payment confirmed. Membership activated.",
    "data": {
        "membership_id": 55,
        "mpesa_receipt": "SGH123ABCD"
    }
}
```
