# Badge Double-Counting Fix - Quick Summary

## 🎯 The Problem
Badge was increasing by **2** instead of **1** when receiving notifications with app closed.

## ✅ The Solution
**Move badge calculation to Notification Service Extension** - This gives us complete control over the badge value before the notification displays, preventing iOS from auto-incrementing.

## 📝 What I Changed

### 1. OneSignal.swift
- ❌ **REMOVED:** Badge setting from notification payload (`ios_badgeType`, `ios_badgeCount`)
- ✅ **ADDED:** `mutable_content: true` to enable extension
- ✅ **ADDED:** `receiverEmail` in notification data

### 2. NotificationService.swift (Extension)
- ✅ **ADDED:** Firebase integration
- ✅ **ADDED:** Badge calculation from Firestore
- ✅ **ADDED:** Sets correct badge before notification displays

### 3. BadgeManager.swift  
- ✅ **FIXED:** Now only counts upcoming events (not past events)

## ⚡ Quick Setup (3 steps in Xcode)

1. **Add Firebase to Extension Target:**
   - Select `OneSignalNotificationServiceExtension` target
   - Build Phases → Link Binary With Libraries → Add:
     - FirebaseCore
     - FirebaseFirestore

2. **Share GoogleService-Info.plist:**
   - Select `GoogleService-Info.plist` in project
   - File Inspector → Target Membership
   - ✅ Check `OneSignalNotificationServiceExtension`

3. **Clean & Build:**
   - ⇧⌘K (Clean)
   - ⌘B (Build)

## 🧪 Test It

1. **Close app completely**
2. **Have someone send you an invite**
3. **Check badge on home screen** - should be correct now!
4. **Open app** - badge shouldn't change
5. **Check Xcode Device Console** for:
   ```
   🔔 [Extension] ✅ Set badge to 3 for tektech@example.com
   ```

## 🐛 If Badge Still Wrong

**Check Device Console** (Window → Devices → Select Device → Console):

- ✅ See extension logs? → **Extension working**
- ❌ No logs? → **Check mutable_content and target setup**
- ⚠️ Error logs? → **Check Firebase configuration**

## 📞 Common Issues

| Problem | Solution |
|---------|----------|
| "No such module FirebaseCore" | Add Firebase frameworks to extension target |
| "Cannot find GoogleService-Info.plist" | Add plist to extension target membership |
| No extension logs appear | Verify `mutable_content: true` in payload |
| Badge still wrong | Check Device Console for extension errors |

## 🎉 Expected Result

**Before Fix:**
```
Badge: 2
↓ (receive invite)
Badge: 4 ❌ WRONG
```

**After Fix:**
```
Badge: 2
↓ (receive invite)
Badge: 3 ✅ CORRECT
```

---

**Full details in:** `FINAL_FIX_STEPS.md`

**Debug if needed:** `BADGE_DOUBLING_DEBUG.md`

