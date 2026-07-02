# Backend API Requirements: Registration & Payment Flow

This document outlines the API endpoints, request payloads, and expected responses required by the frontend to fully support the new Registration, OTP, Membership, and M-PESA Payment flows.

---

## 1. User Registration (Details Step)
**Endpoint:** `POST /api/auth/register` (or similar)

**Description:** Registers the initial user details before OTP verification.

**Required Changes / Notes:**
- The frontend now collects a **National ID** during signup. The database and API must be updated to accept and validate this field.

**Request Payload (JSON):**
```json
{
  "full_name": "John Ochieng",
  "email": "john@example.com",
  "phone_number": "0700000000",
  "national_id": "12345678",
  "password": "securepassword",
  "password_confirmation": "securepassword"
}
```

**Expected Response (JSON):**
```json
{
  "success": true,
  "encrypted_email": "encrypted_string_here",
  "message": "OTP sent successfully."
}
```

---

## 2. OTP Verification (OTP Step)
**Endpoint:** `POST /api/auth/verify-otp`

**Description:** Verifies the 4-digit code sent to the user's email/phone.

**Request Payload (JSON):**
```json
{
  "encrypted_email": "encrypted_string_here",
  "otp": "1234"
}
```

**Expected Response (JSON):**
```json
{
  "success": true,
  "token": "jwt_auth_token_here",
  "user": {
    "id": 1,
    "first_name": "John",
    "email": "john@example.com"
  },
  "message": "Account verified successfully."
}
```

---

## 3. Initiate M-PESA Payment (Membership & Payment Step)
**Endpoint:** `POST /api/payment/stk-push` (NEW)

**Description:** The frontend collects membership tier, location data, and the user's M-PESA phone number. This endpoint should trigger the Safaricom Daraja STK Push to the provided phone number.

**Request Payload (JSON):**
```json
{
  "county": "Nairobi",
  "branch": "Kisumu Branch",
  "membership_type": "green_army", // or "premium"
  "mpesa_phone_number": "0712345678",
  "amount": 200 // Optional: Backend should ideally calculate this based on membership_type to prevent tampering.
}
```

**Expected Response (JSON):**
```json
{
  "success": true,
  "checkout_request_id": "ws_CO_1234567890",
  "message": "STK Push initiated successfully."
}
```

---

## 4. Check Payment Status (Polling / Webhook)
**Endpoint:** `GET /api/payment/status/{checkout_request_id}` (NEW)

**Description:** After the frontend triggers the STK push, it will poll this endpoint every few seconds to check if the user has entered their PIN and completed the transaction. Alternatively, you can use WebSockets or Firebase Cloud Messaging (FCM) to push the status to the frontend.

**Expected Response - Pending (JSON):**
```json
{
  "success": true,
  "status": "pending",
  "message": "Waiting for user to enter PIN."
}
```

**Expected Response - Completed (JSON):**
```json
{
  "success": true,
  "status": "completed",
  "member_id": "GM1968-000123",
  "valid_until": "2025-05-31T23:59:59Z",
  "message": "Payment received and membership activated."
}
```

**Expected Response - Failed (JSON):**
```json
{
  "success": false,
  "status": "failed",
  "message": "Transaction failed: Insufficient funds." // Or "User cancelled"
}
```
