# Running Android App on Physical Device

## Prerequisites
- Android phone with Android 5.0 (API level 21) or higher
- USB cable to connect your phone to your computer
- Android Studio installed on your computer

## Step-by-Step Instructions

### Step 1: Enable Developer Options on Your Phone

The location varies by manufacturer. Try these methods:

#### Method 1: Standard Android (Most Common)
1. Open **Settings** on your Android phone
2. Scroll down and tap **About phone** (or **About device** or **About**)
3. Look for one of these options (tap 7 times):
   - **Build number** (most common)
   - **Build version**
   - **Software information** → then **Build number**
   - **Version** → then **Build number**
   - **MIUI version** (Xiaomi phones)
   - **Version number** (some Samsung phones)
4. Tap the option 7 times in a row
   - You'll see a message like "You are now a developer!" after a few taps
5. Go back to the main Settings menu
6. You should now see **Developer options** (usually under System, Advanced, or Additional settings)

#### Method 2: Samsung Phones
1. Settings → **About phone** (or **About device**)
2. Tap **Software information**
3. Tap **Build number** 7 times

#### Method 3: Xiaomi/Redmi Phones
1. Settings → **About phone**
2. Tap **MIUI version** 7 times (instead of Build number)

#### Method 4: OnePlus Phones
1. Settings → **About phone**
2. Tap **Build number** 7 times

#### Method 5: If You Can't Find "About Phone"
1. Open Settings
2. Scroll to the bottom
3. Look for **System** → **About phone**
4. Or search for "build" in Settings search bar

#### Method 6: Search in Settings
1. Open Settings
2. Use the search bar at the top
3. Search for "build number" or "developer"
4. This will take you directly to the right location

**Still can't find it?** Tell me your phone brand/model and I can give you specific instructions!

### Step 2: Enable USB Debugging

1. Open **Settings** → **Developer options**
2. Toggle **Developer options** ON (if not already on)
3. Scroll down and enable **USB debugging**
   - You may see a warning - tap **OK** to confirm
4. (Optional but recommended) Enable **Stay awake** - keeps screen on while charging
5. (Optional) Enable **Install via USB** - allows installing apps via USB

### Step 3: Connect Your Phone to Computer

1. Connect your phone to your Mac using a USB cable
2. On your phone, you may see a popup asking "Allow USB debugging?"
   - Check **Always allow from this computer** (optional but convenient)
   - Tap **Allow** or **OK**

### Step 4: Verify Connection in Android Studio

1. Open Android Studio
2. Open your CliqueAndroid project
3. Look at the bottom toolbar or open **View** → **Tool Windows** → **Logcat**
4. In the device selector (top toolbar, next to the run button), you should see:
   - Your phone's name/model (e.g., "Samsung Galaxy S21")
   - Or check via terminal: Open Terminal in Android Studio and run:
     ```bash
     adb devices
     ```
   - You should see your device listed (e.g., "ABC123XYZ    device")

### Step 5: Run the App

1. In Android Studio, make sure your phone is selected in the device dropdown (top toolbar)
2. Click the **Run** button (green play icon) or press `Shift + F10` (Mac: `Control + R`)
3. Android Studio will:
   - Build the app
   - Install it on your phone
   - Launch it automatically

### Troubleshooting

#### Device Not Detected

**Problem**: Phone doesn't appear in Android Studio device list

**Solutions**:
1. **Check USB connection**:
   - Try a different USB cable
   - Try a different USB port
   - Make sure the cable supports data transfer (not just charging)

2. **Check USB debugging**:
   - Make sure USB debugging is enabled in Developer options
   - Disconnect and reconnect the phone
   - Revoke USB debugging authorizations in Developer options, then reconnect

3. **Check ADB**:
   - Open Terminal in Android Studio
   - Run: `adb devices`
   - If you see "unauthorized", check your phone for the USB debugging permission popup
   - If you see "offline", try:
     ```bash
     adb kill-server
     adb start-server
     adb devices
     ```

4. **Install USB drivers** (if needed):
   - Some manufacturers require specific USB drivers
   - Samsung: Install Samsung USB drivers
   - Google Pixel: Usually works without additional drivers
   - Check your phone manufacturer's website for drivers

#### "Allow USB Debugging" Popup Not Appearing

1. Disconnect and reconnect the USB cable
2. Revoke USB debugging authorizations in Developer options
3. Reconnect and look for the popup again

#### App Installation Fails

1. **Check storage space** on your phone
2. **Enable "Install via USB"** in Developer options
3. **Uninstall previous version** if the app was installed before
4. Check Logcat in Android Studio for error messages

#### Build Errors

1. Make sure you're using the correct build variant (usually "debug")
2. Clean and rebuild: **Build** → **Clean Project**, then **Build** → **Rebuild Project**
3. Check that your phone's Android version meets the minimum SDK (24 in your case)

### Alternative: Wireless Debugging (Android 11+)

If you prefer not to use a USB cable:

1. Connect your phone and computer to the same Wi-Fi network
2. On your phone: **Settings** → **Developer options** → **Wireless debugging**
3. Enable **Wireless debugging**
4. Tap **Pair device with pairing code**
5. In Android Studio Terminal, run:
   ```bash
   adb pair <IP_ADDRESS>:<PORT>
   ```
   (Use the IP and port shown on your phone)
6. Enter the pairing code when prompted
7. Your phone should now appear in the device list

### Quick Commands Reference

```bash
# List connected devices
adb devices

# Restart ADB server
adb kill-server
adb start-server

# Install APK directly (if you have the APK file)
adb install path/to/app.apk

# Uninstall app
adb uninstall com.clique.app

# View device logs
adb logcat
```

### Notes

- The first time you connect, you'll need to authorize the computer on your phone
- Your phone must be unlocked when running the app
- Keep USB debugging enabled while developing
- For security, you can disable Developer options when not developing

