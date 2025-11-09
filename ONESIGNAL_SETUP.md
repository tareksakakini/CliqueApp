# OneSignal Setup Instructions

## Overview
OneSignal API keys are stored locally and NOT committed to version control for security.

## First-Time Setup

### 1. Create the Configuration File
Copy the sample configuration file:
```bash
cp CliqueApp/Services/OneSignal-Info.sample.plist CliqueApp/Services/OneSignal-Info.plist
```

### 2. Get Your OneSignal Credentials
1. Go to [OneSignal Dashboard](https://onesignal.com/)
2. Navigate to your app: **CliqueApp** (ID: 5374139d-d071-43ca-8960-ab614e9911b0)
3. Go to **Settings** → **Keys & IDs**
4. Copy the following:
   - **App ID** (under "OneSignal App ID")
   - **REST API Key** (under "REST API Key")

### 3. Update Your Local Configuration
Open `CliqueApp/Services/OneSignal-Info.plist` and replace the placeholders:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>API_KEY</key>
    <string>os_v2_app_YOUR_ACTUAL_KEY_HERE</string>
    <key>APP_ID</key>
    <string>5374139d-d071-43ca-8960-ab614e9911b0</string>
</dict>
</plist>
```

### 4. Verify Setup
Build and run the app. Check the console for:
- ✅ No error messages about missing OneSignal configuration
- ✅ OneSignal initializes successfully
- ✅ Push notifications work as expected

## Security Notes

⚠️ **NEVER commit the `OneSignal-Info.plist` file to Git**
- This file is already in `.gitignore`
- Only commit `OneSignal-Info.sample.plist` (the template)

⚠️ **If an API key is exposed:**
1. OneSignal will automatically revoke it
2. Generate a new key from the OneSignal dashboard
3. Update your local `OneSignal-Info.plist`
4. DO NOT hardcode keys in source code

## Troubleshooting

### "Could not load OneSignal-Info.plist" Error
- Make sure the file exists at `CliqueApp/Services/OneSignal-Info.plist`
- Verify the file is added to your Xcode project target
- Check that API_KEY and APP_ID are not empty

### Notifications Not Working
1. Verify your API key is valid in OneSignal dashboard
2. Check that your App ID matches your OneSignal app
3. Ensure notification permissions are granted on device

### Adding the File to Xcode
If Xcode doesn't see the file:
1. Right-click on `CliqueApp/Services` folder in Xcode
2. Choose "Add Files to CliqueApp..."
3. Select `OneSignal-Info.plist`
4. Make sure "Copy items if needed" is checked
5. Ensure "CliqueApp" target is selected

## For Team Members

When cloning this repository:
1. Follow steps 1-3 above to create your local configuration
2. Get credentials from the team lead or OneSignal dashboard
3. Never commit your `OneSignal-Info.plist` file

