# Zeppo

Zeppo is a smart inventory and expiry management system for warehouses, food storage, and retail operations. This Flutter app now includes a Firebase-ready foundation for authentication, Firestore-backed batch tracking, and FIFO-style smart picking.

## What is implemented

- Firebase bootstrap with a clear setup screen when platform config is missing
- Email/password authentication with Firestore user profile creation
- Firestore data model for `users`, `products`, `batches`, and `warehouses`
- Add inventory batches for new or existing products
- Inventory dashboard with expiry-focused smart pick suggestions
- Inventory list with batch deletion support

## Firestore structure

Use one signed-in user as the root tenant:

```text
users/{uid}
users/{uid}/products/{productId}
users/{uid}/batches/{batchId}
users/{uid}/warehouses/{warehouseId}
```

Suggested field responsibilities:

- `users/{uid}`: profile fields like `email`, `displayName`, `role`, `createdAt`
- `products/{productId}`: stable product data like `name`, `sku`, `qrCode`, `unit`
- `batches/{batchId}`: batch data like `productId`, `batchNumber`, `manufacturedAt`, `expiryDate`, `remainingQuantity`, `warehouseName`, `locationCode`, `source`
- `warehouses/{warehouseId}`: storage or zone metadata like `name`, `locationCode`

This split is important for FIFO picking because batches, not products, carry expiry and quantity state.

## Firebase setup

1. Create a Firebase project.
2. Enable Email/Password sign-in in Firebase Authentication.
3. Create a Firestore database.
4. Add `android/app/google-services.json`.
5. Add `ios/Runner/GoogleService-Info.plist`.
6. For web, either run FlutterFire configuration or pass the `FIREBASE_WEB_*` dart defines used in [`lib/services/firebase_service.dart`](/Users/trish/Invento/invento_app/lib/services/firebase_service.dart).

The Android Gradle setup now conditionally applies the Google Services plugin when `google-services.json` exists, so the repo can stay analyzable even before secrets/config files are committed.

A starter Firestore rules file is included at [firestore.rules](/Users/trish/Invento/invento_app/firestore.rules) to keep each signed-in user scoped to their own data tree.

## Recommended next steps

1. Add QR scanning and OCR services that populate the add-batch form.
2. Deploy the included Firestore rules to your Firebase project.
3. Add batch update and pick/consume flows to reduce `remainingQuantity`.
4. Add notification scheduling for expiring batches.
