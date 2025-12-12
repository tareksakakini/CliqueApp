# Create Service Account Key for OneSignal

## Use the Firebase Admin SDK Service Account

You already have a Firebase Admin SDK service account that's perfect for this:
- **Email**: `firebase-adminsdk-38u08@cliqueapp-3834b.iam.gserviceaccount.com`
- **Name**: `firebase-adminsdk`

### Step 1: Create a Key for the Firebase Admin SDK Service Account

1. In the Service Accounts page (where you are now)
2. Find the row with **`firebase-adminsdk-38u08@cliqueapp-3834b.iam.gserviceaccount.com`**
3. Click on the **service account email** (the blue link) to open its details
4. Go to the **"Keys"** tab at the top
5. Click **"Add Key"** → **"Create new key"**
6. Select **"JSON"** format
7. Click **"Create"**
8. A JSON file will download (e.g., `cliqueapp-3834b-xxxxx.json`)

### Step 2: Check OneSignal Dashboard for Service Account Support

1. Go to [OneSignal Dashboard](https://onesignal.com/)
2. **Settings** → **Platforms** → **Google Android (FCM)**
3. Check if there's a **"Service Account"** section or option

**If OneSignal has Service Account support:**
- Upload the JSON file, OR
- Open the JSON file and copy:
  - `client_email` (the service account email)
  - `private_key` (the entire key including BEGIN/END markers)
- Paste these into OneSignal

**If OneSignal only has "Firebase Server Key" field:**
- You'll need to enable the Legacy API instead (see below)

### Alternative: Enable Legacy API for Server Key

If OneSignal doesn't support Service Accounts yet, you need the Legacy Server Key:

1. Go back to **Firebase Console** → **Project Settings** → **Cloud Messaging**
2. Find **"Cloud Messaging API (Legacy)"** section
3. Click **"Manage API in Google Cloud Console"** or the three dots (⋮)
4. In Google Cloud Console, click **"Enable"**
5. Return to Firebase Console and **refresh**
6. The **Server Key** should now appear under Legacy API
7. Copy it and paste into OneSignal

## Recommendation

**Try the Service Account first** (Step 1-2) - it's the modern approach. If OneSignal doesn't support it yet, then enable Legacy API as a fallback.

## Security Note

⚠️ **Keep the downloaded JSON file secure** - it contains sensitive credentials. Don't commit it to Git. Store it safely on your local machine.








