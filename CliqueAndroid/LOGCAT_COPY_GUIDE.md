# How to Copy Multiple Lines from Logcat

## Method 1: Android Studio Logcat Window

### Basic Selection
1. **Single click** on the first log line you want
2. **Shift + Click** on the last log line you want
3. **Cmd+C** (Mac) or **Ctrl+C** (Windows/Linux) to copy
4. Paste into your text editor or share

### Select All Visible Logs
1. Click anywhere in the Logcat window
2. **Cmd+A** (Mac) or **Ctrl+A** (Windows/Linux) to select all
3. **Cmd+C** or **Ctrl+C** to copy

### Filter First, Then Copy
1. In the Logcat filter box, enter your filter:
   - `OneSignalManager` - for OneSignal logs
   - `CliqueAppViewModel` - for ViewModel logs
   - `tag:OneSignalManager` - more specific tag filter
   - `package:mine` - only your app's logs
2. Wait for logs to filter
3. Select and copy as above

### Save to File Directly
1. Right-click in Logcat window
2. Select **"Save Logcat to File"** or **"Export Logcat"**
3. Choose location and save
4. Open the file and copy what you need

## Method 2: Command Line (adb logcat)

### Save All Logs to File
```bash
# Save all logs to a file
adb logcat > logcat_output.txt

# Stop logging: Press Ctrl+C
# Then open logcat_output.txt and copy what you need
```

### Filter and Save Specific Logs
```bash
# Filter by tag (OneSignalManager)
adb logcat -s OneSignalManager:* > onesignal_logs.txt

# Filter by tag (CliqueAppViewModel)
adb logcat -s CliqueAppViewModel:* > viewmodel_logs.txt

# Filter by both tags
adb logcat -s OneSignalManager:* CliqueAppViewModel:* > notification_logs.txt

# Filter by package (your app only)
adb logcat | grep "com.clique.app" > app_logs.txt
```

### Clear Logs First, Then Capture
```bash
# Clear existing logs
adb logcat -c

# Start capturing (do this BEFORE performing the action)
adb logcat > fresh_logs.txt

# Perform your action (send notification, etc.)
# Press Ctrl+C to stop
```

### Filter by Log Level
```bash
# Only show errors and warnings
adb logcat *:E *:W > errors_warnings.txt

# Show debug, info, warning, and error
adb logcat *:D *:I *:W *:E > all_important_logs.txt
```

## Method 3: Filter by Time Range

### In Android Studio
1. Use the time filter in Logcat toolbar
2. Select "Show only selected application" to filter by your app
3. Use the search box for specific terms
4. Select and copy

### Command Line with Timestamps
```bash
# Include timestamps in output
adb logcat -v time > timestamped_logs.txt

# Filter by tag with timestamps
adb logcat -v time -s OneSignalManager:* > onesignal_timestamped.txt
```

## Method 4: Use Logcat Filters for Notification Debugging

### Recommended Filters for Notification Debugging

**Filter 1: OneSignal Only**
```
tag:OneSignalManager
```

**Filter 2: ViewModel Only**
```
tag:CliqueAppViewModel
```

**Filter 3: Both Notification-Related**
```
tag:OneSignalManager | tag:CliqueAppViewModel
```

**Filter 4: Errors Only**
```
level:error tag:OneSignalManager | level:error tag:CliqueAppViewModel
```

**Filter 5: Your App Only**
```
package:mine
```

### How to Create Saved Filters
1. In Logcat, click the filter dropdown
2. Click **"Edit Filter Configuration"**
3. Click **"+"** to add new filter
4. Name it (e.g., "Notification Debug")
5. Set tag: `OneSignalManager|CliqueAppViewModel`
6. Click **OK**
7. Select your saved filter from dropdown

## Method 5: Copy Specific Log Sections

### Copy Logs Between Two Actions
1. **Before action**: Note the timestamp or clear logs (`adb logcat -c`)
2. **Perform action** (send notification, etc.)
3. **After action**: Select all logs that appeared
4. Copy and paste

### Copy Logs with Context
1. Filter by tag: `OneSignalManager`
2. Select a few lines before and after the error
3. This gives context for debugging

## Quick Tips

### Tip 1: Use Multiple Filters
Create separate filters for:
- `OneSignalManager` - OneSignal initialization and sending
- `CliqueAppViewModel` - User actions and login
- `package:mine` - All your app logs

### Tip 2: Clear Before Testing
```bash
adb logcat -c
```
This clears old logs so you only see new ones.

### Tip 3: Save Important Sessions
When you find an issue:
1. Save the logcat to a file
2. Name it descriptively: `notification_failure_2025-01-XX.txt`
3. Keep it for reference

### Tip 4: Use Logcat's Search
- **Cmd+F** (Mac) or **Ctrl+F** (Windows/Linux) in Logcat
- Search for specific terms like "ERROR" or "recipients"
- Select matching lines and copy

### Tip 5: Export for Sharing
1. Right-click in Logcat
2. **"Save Logcat to File"**
3. Share the file with team members
4. They can search through it easily

## Example Workflow for Notification Debugging

### Step-by-Step:
1. **Clear logs**: `adb logcat -c` or click clear button in Android Studio
2. **Set filter**: `OneSignalManager|CliqueAppViewModel`
3. **Perform action**: Send a notification (friend request, chat message, etc.)
4. **Select relevant logs**: Click first line, Shift+Click last line
5. **Copy**: Cmd+C or Ctrl+C
6. **Paste** into a text file or share

### Command Line Alternative:
```bash
# Clear logs
adb logcat -c

# Start capturing (in one terminal)
adb logcat -s OneSignalManager:* CliqueAppViewModel:* > notification_debug.txt

# Perform your action in the app
# Press Ctrl+C when done
# Open notification_debug.txt and copy what you need
```

## Troubleshooting

### Problem: Too many logs, hard to find what you need
**Solution**: Use filters! Start with `tag:OneSignalManager` or `tag:CliqueAppViewModel`

### Problem: Can't select multiple lines
**Solution**: Make sure you're clicking on the log content area, not the header. Try clicking slightly to the left of the text.

### Problem: Logs are scrolling too fast
**Solution**: 
- Pause Logcat (pause button in toolbar)
- Or use filters to reduce noise
- Or save to file and review later

### Problem: Need logs from specific time
**Solution**: 
- Use `adb logcat -v time` to include timestamps
- Or use Android Studio's time filter in Logcat toolbar

