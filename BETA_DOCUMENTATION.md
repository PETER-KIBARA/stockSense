# StockSense Beta Documentation (Server Admin Guide)

This document provides a technical overview of the StockSense Inventory Management System for server administrators and developers. It details the multi-tenant architecture, security protocols, and operational workflows implemented for the 14-day trial phase.

## Architecture & Data Isolation

StockSense employs a **multi-tenant subcollection model** to ensure complete data isolation between trial users and to protect root production data.

- **Isolation Strategy**: All user-specific data is stored within subcollections under each user's unique identifier (UID).
- **Storage Path**: `users/{userId}/inventory_items/`
- **Benefits**:
    - **Interference Prevention**: Standard users cannot access or accidentally overwrite data from other users.
    - **Clean Scaling**: New users enter a "blank slate" environment without inherited statistics.
    - **Migration Ready**: This structure allows for easy data porting if a trial user upgrades to a production tier.

## Security Logic

The system utilizes **Firebase Firestore Security Rules (Version 2)** with a hybrid logic model that prioritizes individual data ownership.

- **Recursive Access**: Rules are configured to allow recursive, owner-only access to subcollections.
- **Rule Signature**: `rules_version = '2';`
- **Logic Highlights**:
    - **Legacy Protection**: Root collections are protected by standard authentication checks.
    - **Recursive Ownership**: Trial subcollections verify that the `request.auth.uid` matches the `{userId}` document path, ensuring only the owner can read or write their specific inventory data.
    - **Admin Overrides**: Specific administrative roles are granted access to the root `categories` and `users` collections for management purposes.

## App Setup Walkthrough

### Dependencies
Before local deployment, ensure the following assets are correctly registered in the `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
```
- **Landing Hero**: `assets/images/landing_image.png` is used for the Hero section warehouse texture.
- **Branding**: `assets/icons/orange_logo.jpeg` is the primary 3D-style logo.

### Initialization
The **Trial Service** handles the lifecycle of the 14-day trial period:

1.  **Trigger**: Upon a user's first successful login, the `TrialService.getFirstLaunchDate()` method executes.
2.  **Timestamp**: A persistent ISO8601 timestamp is generated and stored locally via `SharedPreferences`.
3.  **Persistence**: This timestamp serves as the "T-Zero" anchor for the 14-day countdown across all sessions.

## Operational Flow

### 1. Landing Interface
- **Hero Section**: Features a high-contrast Hero section with the warehouse image set at **0.25 opacity** for subtle texture.
- **Sticky Navbar**: A modern **frosted-glass (BackdropFilter blur)** AppBar that stays pinned to the top, providing quick navigation to Features, Pricing, and Login.

### 2. Active Trial Phase
- **Dashboard Banner**: Users see a persistent countdown banner on the main dashboard indicating how many days remain in their trial.
- **Dynamic Styling**: The banner switches to a warning state (red tint) when fewer than 3 days remain, encouraging conversion.

### 3. Expiry and Redirect
- **Automatic Enforcement**: Upon app launch (SplashScreen), the `TrialService` checks the current date against the stored "first launch" timestamp.
- **Expiry Screen**: If the 14-day period has concluded, users are automatically redirected to a dedicated **Expiry Screen**.
- **Consultation Funnel**: The Expiry Screen provides a direct "Contact Cloudora" action, which opens the consultation dialog to initiate a formal subscription request at ` support@cloudora.africa`.

