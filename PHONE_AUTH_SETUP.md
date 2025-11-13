# Phone Authentication Setup

The app now relies on Firebase Phone Auth for account creation, login, and password recovery. Make sure these steps are completed before shipping.

## 1. Firebase Console (Authentication)

1. Open **Firebase Console → Authentication → Sign-in method**.
2. Enable the **Phone** provider and press **Save**.
3. (Recommended) Scroll to **Phone numbers for testing** and add a few test entries so you can log in during development without consuming real SMS quotas.
4. If you previously enforced email verification, disable any rules/workflows that block unverified users.

## 2. Firebase Console (APNs / Phone Auth app verification)

Firebase uses either APNs tokens or reCAPTCHA for iOS phone auth. Uploading an APNs auth key lets Firebase silently verify the device so users don’t see the reCAPTCHA prompt.

1. In the Apple Developer portal, create (or reuse) an **APNs Auth Key** that already exists in this repo as `AuthKey_*.p8`.
2. Go to **Firebase Console → Project Settings → Cloud Messaging → Apple app configuration**.
3. Upload the `.p8` auth key, fill in the Key ID and Team ID, and select your iOS bundle identifier (`CliqueApp` target).
4. Make sure the iOS app in Firebase has **Push Notifications** capability enabled (Xcode → Signing & Capabilities → add “Push Notifications” if not already present).

> Without the APNs key, Firebase falls back to a reCAPTCHA challenge that opens Safari, which is a poor UX.

## 3. Xcode Project Checklist

- The `CliqueApp` target already includes Firebase dependencies. Just ensure the **Push Notifications** capability stays enabled.
- No Info.plist changes are required for stock Firebase Phone Auth, but if you add a custom reCAPTCHA domain later you will need to whitelist it under `LSApplicationQueriesSchemes`.

## 4. Usage Notes

- Phone numbers are normalized to U.S. 10-digit numbers by default (automatic `+1` prefix). Update `PhoneNumberFormatter.canonical(_:)` if you need different regional rules.
- After sign-up we automatically call `linkPhoneNumberToUser` so event invitations that were addressed to a raw phone number are migrated to the new account.
- Password resets now require the user to receive an SMS code, so keep at least one verified test number handy for QA.

## 5. Monitoring & Quotas

- Firebase enforces SMS sending quotas per project. In production, consider requesting quota increases if you expect high sign-up volume.
- Keep the **Usage** tab in Authentication under review; anomalies usually mean abuse or automated testing.
