# Firebase Test Phone Numbers Setup

## Purpose
Test phone numbers allow you to test phone authentication without sending real SMS messages and without hitting rate limits. This is essential for development and testing.

## How to Add Test Numbers

1. **Open Firebase Console:**
   - Go to: https://console.firebase.google.com
   - Select your CliqueApp project

2. **Navigate to Phone Auth Settings:**
   - Click **Authentication** in left sidebar
   - Click **Sign-in method** tab
   - Find the **Phone** provider (should be enabled)
   - Click the **Phone** row to edit it

3. **Add Test Phone Numbers:**
   Scroll down to **"Phone numbers for testing"** section and add:

   ```
   Phone Number          | Verification Code
   ---------------------|------------------
   +1 650-555-1234      | 123456
   +1 650-555-5678      | 111111
   +1 650-555-9999      | 999999
   ```

4. **Click Save**

## How Test Numbers Work

- When you enter a test phone number in the app, Firebase **pretends** to send an SMS
- No actual SMS is sent (saves money, no rate limits)
- The code is always the one you configured (e.g., `123456`)
- Works instantly, unlimited times
- Perfect for development and automated testing

## Usage in App

### Sign Up with Test Number:
1. Enter phone: `6505551234` (or `+1 650-555-1234`)
2. Tap "Send Code" - will succeed immediately
3. Enter code: `123456`
4. Complete sign up ✅

### Login with Test Number:
1. Enter phone: `6505551234`
2. Tap "Send Code" - will succeed immediately
3. Enter code: `123456`
4. Login successful ✅

## Important Notes

- Test numbers only work when added in Firebase Console
- They work in both Debug and Release builds
- They don't count against SMS quota
- You can add up to 10 test numbers
- Test numbers are **NOT** visible to users - they only work for you during development
- For production, users will use real phone numbers with real SMS

## Current Rate Limit Issue

If you see "We have blocked all requests from this device due to unusual activity":
- This happens after ~5-10 verification attempts in a short period
- Solution: Use test phone numbers instead of real ones during development
- Or wait 15-60 minutes for the block to clear

## Recommended Test Numbers for Development

Create multiple test accounts for different scenarios:

```
Account Type         | Phone Number      | Code   | Purpose
--------------------|-------------------|--------|---------------------------
Primary Test        | +1 650-555-1234   | 123456 | Your main test account
Secondary Test      | +1 650-555-5678   | 111111 | For testing friend features
Event Organizer     | +1 650-555-1111   | 111111 | For creating events
Event Attendee      | +1 650-555-2222   | 222222 | For joining events
```

## Alternative: Increase Rate Limits (Not Recommended for Dev)

Firebase has rate limits to prevent abuse. While you can request increases for production, during development it's better to use test numbers instead.


