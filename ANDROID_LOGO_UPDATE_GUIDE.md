# Android App Logo Update Guide

## Overview
This guide will help you update the Android app logo. The app uses **adaptive icons** (Android 8.0+), which consist of a foreground image and a background color.

## Current Configuration
- **Foreground**: Vector drawable (`ic_launcher_foreground.xml`)
- **Background Color**: `#FF4C6FFF` (purple) - defined in `colors.xml`
- **Icon Reference**: `@mipmap/ic_launcher` in AndroidManifest.xml

## Step-by-Step Instructions

### Step 1: Prepare Your Logo Image
1. **Size**: 1024x1024 pixels (recommended for best quality)
2. **Format**: PNG with transparency
3. **Design Guidelines**:
   - Keep your logo centered
   - Use only the inner 66% of the canvas (safe zone) to avoid cropping
   - The outer 33% may be cropped on different device shapes (circle, square, rounded square)

### Step 2: Place Your Logo File
1. Copy your logo PNG file to:
   ```
   CliqueAndroid/app/src/main/res/drawable/
   ```
2. Name it `app_logo.png` (or any name you prefer, e.g., `yalla_logo.png`)

### Step 3: Update the Foreground Drawable
You have two options:

#### Option A: Use PNG directly (Simplest)
Replace the content of `CliqueAndroid/app/src/main/res/drawable/ic_launcher_foreground.xml` with:

```xml
<?xml version="1.0" encoding="utf-8"?>
<bitmap xmlns:android="http://schemas.android.com/apk/res/android"
    android:src="@drawable/app_logo" />
```

Replace `app_logo` with your actual filename (without the `.png` extension).

#### Option B: Keep vector drawable format (if you convert logo to vector)
If you have a vector version of your logo, you can replace the paths in the existing `ic_launcher_foreground.xml`.

### Step 4: Optional - Update Background Color
If you want to change the icon background color:
1. Open `CliqueAndroid/app/src/main/res/values/colors.xml`
2. Modify the `ic_launcher_background` color value:
   ```xml
   <color name="ic_launcher_background">#YOUR_COLOR_HERE</color>
   ```
   Example: `#FFFFFFFF` for white, `#FF000000` for black

### Step 5: Rebuild the App
1. In Android Studio, go to **Build** → **Clean Project**
2. Then **Build** → **Rebuild Project**
3. Run the app to see your new logo

### Step 6: Test on Device/Emulator
- Install the app and check the home screen icon
- Test on different Android versions if possible
- Verify the icon looks good in both light and dark themes

## File Locations Summary
```
CliqueAndroid/app/src/main/res/
├── drawable/
│   ├── ic_launcher_foreground.xml  ← Update this file
│   └── app_logo.png                ← Place your logo here
├── mipmap-anydpi-v26/
│   ├── ic_launcher.xml             ← References foreground
│   └── ic_launcher_round.xml       ← References foreground
└── values/
    └── colors.xml                  ← Background color (optional to change)
```

## Troubleshooting

### Icon looks cropped
- Make sure your logo is centered and uses only the inner 66% of the canvas
- Test on different device shapes (circular, square, rounded)

### Icon doesn't update
- Clean and rebuild the project
- Uninstall the app from the device/emulator and reinstall
- Clear Android Studio cache: **File** → **Invalidate Caches / Restart**

### Icon appears blurry
- Ensure your source image is at least 1024x1024 pixels
- Use PNG format (not JPEG) for better quality

## Notes
- The adaptive icon system automatically handles different device shapes
- The same foreground is used for both regular and round icons
- Legacy icons (for Android < 8.0) are not currently configured but can be added if needed



