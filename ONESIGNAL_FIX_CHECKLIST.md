# OneSignal Fix Checklist

## ✅ Already Completed (by AI)
- [x] Removed hardcoded API keys from source code
- [x] Updated `OneSignal.swift` to read from config file
- [x] Updated `CliqueAppApp.swift` to read from config file  
- [x] Added `OneSignal-Info.plist` to `.gitignore`
- [x] Created sample template file (`OneSignal-Info.sample.plist`)
- [x] Created setup documentation

## 🔧 YOUR ACTION ITEMS (Do These Now)

### Step 1: Generate New API Key
1. Go to https://onesignal.com/ and log in
2. Find your app: **CliqueApp** (5374139d-d071-43ca-8960-ab614e9911b0)
3. Go to **Settings** → **Keys & IDs**
4. Under **REST API Key**, click **Generate New Key** (or "Show" if key exists)
5. **COPY** the new API key (starts with `os_v2_app_...`)

### Step 2: Create Local Config File
1. In Finder, navigate to:
   ```
   /Users/tareksakakini/Documents/AppDevelopment/CliqueApp/CliqueApp/Services/
   ```

2. Create a new file named: `OneSignal-Info.plist`

3. Paste this content (replace YOUR_NEW_KEY):
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>API_KEY</key>
       <string>YOUR_NEW_KEY_HERE</string>
       <key>APP_ID</key>
       <string>5374139d-d071-43ca-8960-ab614e9911b0</string>
   </dict>
   </plist>
   ```

### Step 3: Add File to Xcode
1. Open your project in Xcode
2. In the Project Navigator, right-click on `CliqueApp/Services` folder
3. Select **"Add Files to CliqueApp..."**
4. Navigate to and select `OneSignal-Info.plist`
5. Check **"Copy items if needed"**
6. Ensure **"CliqueApp"** target is checked
7. Click **Add**

### Step 4: Build and Test
1. Clean build folder: **Cmd+Shift+K**
2. Build project: **Cmd+B**
3. Run on device or simulator: **Cmd+R**
4. Check console for: ✅ No errors about missing config
5. Test sending a notification

### Step 5: Commit Your Changes
```bash
cd /Users/tareksakakini/Documents/AppDevelopment/CliqueApp

# Verify OneSignal-Info.plist is NOT staged (should be ignored)
git status

# You should see:
# - Modified: .gitignore
# - Modified: CliqueApp/Helpers/OneSignal.swift
# - Modified: CliqueApp/CliqueAppApp.swift
# - New: CliqueApp/Services/OneSignal-Info.sample.plist
# - New: ONESIGNAL_SETUP.md
# - New: ONESIGNAL_FIX_CHECKLIST.md

# OneSignal-Info.plist should NOT appear (it's ignored)

git add .
git commit -m "Secure OneSignal API key - move to local config file"
git push origin main
```

## ⚠️ IMPORTANT SECURITY NOTES

1. **NEVER commit `OneSignal-Info.plist`** - it's in `.gitignore` for a reason
2. If you accidentally commit the API key:
   - OneSignal will revoke it again
   - You'll need to generate another new key
   - Consider using `git filter-branch` to remove it from history

3. The old API key (`YallaOneSignalAPIKey`) is DEAD - don't try to use it

## 🎯 Success Criteria

You'll know it works when:
- ✅ App builds without errors
- ✅ No console errors about missing OneSignal config
- ✅ Push notifications are received successfully
- ✅ `git status` doesn't show `OneSignal-Info.plist` as changed
- ✅ Badge counts update correctly

## 📞 Need Help?

If you get stuck:
1. Check `ONESIGNAL_SETUP.md` for detailed instructions
2. Verify the file is in the correct location
3. Make sure the plist XML syntax is correct (no typos)
4. Ensure the API key is the new one from OneSignal dashboard

