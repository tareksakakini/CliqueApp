# CliqueApp Manual Test Cases

**Test Date:** 10/29/2025  
**Tester:** Tarek  
**App Version:** Dunno  
**Device/iOS Version:** Dunno

---

## Test Accounts Setup
- **User A Email:** tarek.sakakini@gmail.com
- **User A Phone:** 2176210670
- **User B Email:** tek.tech.inc@gmail.com
- **User B Phone:** NA

---

Collection of all notes:

------------------------------------

TODO:

1. [Authentication/Phone Linking - Major] This whole feature needs rethinking. There is no verification for the phone number which is a security risk. Switching to sign up by phone number fixes a lot of this.

9. [New Feature - Major] Add chat feature

2. [Pictures - Medium] image syncing is not smooth, aspect ratio has issues

3. [Notifications - Medium] I still need to work on making sure I stop receiving notifications on a device I'm logged out of

6. [Notifications - Medium] It would be nice for the click on the notification to lead you to the right place

7. [Error Handling - Medium] This whole section needs rethinking. We have no error handling and we should. 

8. [Realtime updates - Medium] This needs rethinking. Now I mostly have to manually refresh 

DONE:

10. [Design - Minor] The way the host is indicated on the outside card needs adjustment
11. [Design - Minor] Auto capitalize for event title
12. [Design - Minor] Would be nice to show a badge on "Invites" to show the number of unanswered invites
13. [UI - Minor] Make the top right profile picture clickable and take you to the settings tab
14. [Design - Minor] Would be nice to make the attendees clickable to view their profile 
15. [UX minor] I need to check why sometimes the default time for the start time is not as refreshed
16. [Design - Minor] Some wrapping happens in the event details in the card at the top when the details are lengthy. Should figure that out 
17. [Design - Minor] Showing the duration of the event ... I should consider not only using hours and minutes but also days
18. [Design - Minor] Would be good to fix the aesthetics of the "Not a user? Add by phone" button
19. [Notifications - Minor] One issue observed is that invitees are not getting updates when outing details are changed or outing deleted 
4. [Phone Invite - Major] Event is created with phone contact even when sending out the message is cancelled
5. [Time Zone - Medium] I need to check how are we handling time zone differences

------------------------------------

## 1. AUTHENTICATION & ACCOUNT MANAGEMENT

### 1.1 Sign Up Flow

-- FULLY DONE --

#### Test 1.1.1: New User Registration (User A)
- [ ] **Steps:**
  1. Open app on Device A
  2. Tap "Sign Up"
  3. Enter valid email, password, full name, username, gender
  4. Tap "Create Account"
- [ ] **Expected:** Account created successfully, redirected to email verification screen
- [ ] **Actual:** Account created successfully, redirected to email verification screen
- [ ] **Pass/Fail:** Pass

#### Test 1.1.2: Duplicate Email Registration
- [ ] **Steps:**
  1. On Device B, attempt to sign up with User A's email
- [ ] **Expected:** Error message indicating email is already in use
- [ ] **Actual:** Error message indicating email is already in use
- [ ] **Pass/Fail:** Pass

#### Test 1.1.3: Invalid Email Format
- [ ] **Steps:**
  1. Attempt to sign up with invalid email format (e.g., "test@")
- [ ] **Expected:** Validation error before submission
- [ ] **Actual:** Validation error before submission
- [ ] **Pass/Fail:** Pass

#### Test 1.1.4: Weak Password
- [ ] **Steps:**
  1. Attempt to sign up with password less than 6 characters
- [ ] **Expected:** Error message about password strength
- [ ] **Actual:** Error message about password strength
- [ ] **Pass/Fail:** Pass

#### Test 1.1.5: New User Registration (User B)
- [ ] **Steps:**
  1. On Device B, sign up with unique User B credentials
- [ ] **Expected:** Account created successfully
- [ ] **Actual:** Account created successfully
- [ ] **Pass/Fail:** Pass

---

### 1.2 Email Verification

-- FULLY DONE --

#### Test 1.2.1: Email Verification Flow (User A)
- [ ] **Steps:**
  1. After signup, check User A's email inbox
  2. Open verification email from Firebase/CliqueApp
  3. Click verification link
  4. Return to app and tap "I've verified my email"
- [ ] **Expected:** Successfully verified, can access main app
- [ ] **Actual:** Successfully verified, can access main app
- [ ] **Pass/Fail:** Pass

#### Test 1.2.2: Resend Verification Email
- [ ] **Steps:**
  1. On Device B (User B), before verifying, tap "Resend Verification Email"
  2. Check email inbox
- [ ] **Expected:** New verification email received
- [ ] **Actual:** New verification email received
- [ ] **Pass/Fail:** Pass

#### Test 1.2.3: Verify User B Email
- [ ] **Steps:**
  1. Complete email verification for User B
- [ ] **Expected:** User B can access main app
- [ ] **Actual:** User B can access main app
- [ ] **Pass/Fail:** Pass

---

### 1.3 Login Flow

-- FULLY DONE --

#### Test 1.3.1: Successful Login
- [ ] **Steps:**
  1. Logout from User A's account
  2. Login with User A's credentials
- [ ] **Expected:** Successful login, redirected to main view
- [ ] **Actual:** Successful login, redirected to main view
- [ ] **Pass/Fail:** Pass

#### Test 1.3.2: Invalid Password
- [ ] **Steps:**
  1. Attempt login with correct email but wrong password
- [ ] **Expected:** Error message "Invalid credentials"
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 1.3.3: Non-existent Email
- [ ] **Steps:**
  1. Attempt login with non-existent email
- [ ] **Expected:** Error message
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 1.3.4: Empty Fields
- [ ] **Steps:**
  1. Attempt login with empty email or password
- [ ] **Expected:** Validation error
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 1.4 Password Reset

-- FULLY DONE --

#### Test 1.4.1: Password Reset Request
- [ ] **Steps:**
  1. From login screen, tap "Forgot Password"
  2. Enter User A's email
  3. Submit password reset request
- [ ] **Expected:** Success message, reset email sent
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 1.4.2: Reset Email Received
- [ ] **Steps:**
  1. Check User A's email inbox
  2. Verify password reset email received
- [ ] **Expected:** Email contains reset link
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 1.4.3: Reset Password and Login
- [ ] **Steps:**
  1. Click reset link from email
  2. Set new password
  3. Login with new password
- [ ] **Expected:** Password updated, login successful
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass 

---

### 1.5 Phone Number Linking

-- This whole feature needs rethinking. There is no verification for the phone number which is a security risk. Switching to sign up by phone number fixes a lot of this. --

#### Test 1.5.1: Link Phone Number (User A)
- [ ] **Steps:**
  1. Login as User A
  2. Navigate to Settings
  3. Tap "Link Phone Number"
  4. Enter valid phone number
  5. Submit
- [ ] **Expected:** Phone number linked successfully
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

#### Test 1.5.2: Link Phone Number (User B)
- [ ] **Steps:**
  1. Login as User B
  2. Link User B's phone number
- [ ] **Expected:** Phone number linked successfully
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

---

### 1.6 Profile Picture Management

-- Functional, but user experience poor, and still some issues with pictures not matching selection --

#### Test 1.6.1: Upload Profile Picture (User A)
- [ ] **Steps:**
  1. As User A, go to Settings
  2. Tap profile picture placeholder
  3. Select image from photo library
  4. Crop image using the crop overlay
  5. Save
- [ ] **Expected:** Profile picture uploaded and displayed
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

#### Test 1.6.2: Update Profile Picture
- [ ] **Steps:**
  1. Tap profile picture again
  2. Select different image
  3. Crop and save
- [ ] **Expected:** Profile picture updated
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

#### Test 1.6.3: Upload Profile Picture (User B)
- [ ] **Steps:**
  1. As User B, upload a profile picture
- [ ] **Expected:** Profile picture uploaded successfully
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

---

## 2. FRIEND MANAGEMENT

### 2.1 Friend Search

#### Test 2.1.1: Search for User by Username (User A searches for User B)
- [ ] **Steps:**
  1. Login as User A
  2. Navigate to Friends tab
  3. Tap "Add Friend" button
  4. Search for User B by username
- [ ] **Expected:** User B appears in search results
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Not implement

#### Test 2.1.3: Search by Full Name
- [ ] **Steps:**
  1. Search for User B using their full name
- [ ] **Expected:** User B appears in search results
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 2.1.4: Partial Search Match
- [ ] **Steps:**
  1. Search with partial username (first few characters)
- [ ] **Expected:** User B appears in results if match exists
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 2.1.5: No Results Search
- [ ] **Steps:**
  1. Search for non-existent user "zzznonexistent123"
- [ ] **Expected:** No results shown
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 2.1.6: Clear Search
- [ ] **Steps:**
  1. Enter search term
  2. Tap X button to clear
- [ ] **Expected:** Search cleared, results reset
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 2.2 Friend Requests

#### Test 2.2.1: Send Friend Request (User A to User B)
- [ ] **Steps:**
  1. As User A, search for User B
  2. Tap on User B from search results
  3. In FriendDetailsView, tap "Add Friend" or equivalent button
- [ ] **Expected:** Friend request sent, button changes to "Request Sent" or similar
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 2.2.2: View Pending Request Status (User A)
- [ ] **Steps:**
  1. Go back to search
  2. Search for User B again
- [ ] **Expected:** User B shows "Request Sent" status
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 2.2.3: Receive Friend Request Notification (User B)
- [ ] **Steps:**
  1. On Device B, check if notification received (if push notifications enabled)
  2. Open app as User B
  3. Check for friend request indicator
- [ ] **Expected:** Push notification received (if enabled), friend request visible in app
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 2.2.4: View Friend Request Details (User B)
- [ ] **Steps:**
  1. As User B, navigate to friend requests section
  2. Tap on User A's request
- [ ] **Expected:** User A's profile details shown
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 2.2.5: Accept Friend Request (User B accepts User A)
- [ ] **Steps:**
  1. As User B, tap "Accept" on User A's friend request
- [ ] **Expected:** Request accepted, User A added to friends list
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 2.2.6: Verify Friendship (User A)
- [ ] **Steps:**
  1. On Device A, refresh or navigate to Friends tab
  2. Check if User B appears in friends list
- [ ] **Expected:** User B is now in User A's friends list
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 2.2.7: Mutual Friendship Status
- [ ] **Steps:**
  1. As User A, search for User B
  2. Verify friend status indicator
- [ ] **Expected:** Shows "Friends" status, not "Add Friend"
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 2.3 Friend Request Rejection

#### Test 2.3.1: Send Another Friend Request (User B to test account)
- [ ] **Steps:**
  1. Create a temporary third test account OR
  2. As User B, send friend request to User A (if you previously removed friendship)
- [ ] **Expected:** Request sent
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 2.3.2: Decline Friend Request
- [ ] **Steps:**
  1. As receiving user, tap "Decline" on friend request
- [ ] **Expected:** Request declined and removed
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 2.3.3: Verify Decline Reflected
- [ ] **Steps:**
  1. As requesting user, search for the other user
- [ ] **Expected:** Shows "Add Friend" again (can re-request)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 2.4 Friend List Management

#### Test 2.4.1: View Friends List (User A)
- [ ] **Steps:**
  1. As User A, navigate to Friends tab
- [ ] **Expected:** User B appears in friends list with profile picture and details
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 2.4.2: View Friend Profile
- [ ] **Steps:**
  1. Tap on User B in friends list
- [ ] **Expected:** User B's profile details displayed
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 2.4.3: Remove Friend
- [ ] **Steps:**
  1. In friend details view, tap "Remove Friend"
  2. Confirm removal
- [ ] **Expected:** Friend removed from list
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 2.4.4: Re-add Removed Friend
- [ ] **Steps:**
  1. Search for removed friend
  2. Send friend request again
  3. Have them accept
- [ ] **Expected:** Successfully re-added as friends
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

## 3. EVENT CREATION

### 3.1 Basic Event Creation

-- The way the host is indicated on the outside card needs adjustment --
-- Auto capitalize for event title --

#### Test 3.1.1: Create Event with Minimum Required Fields (User A)
- [ ] **Steps:**
  1. As User A, navigate to "New Event" tab
  2. Enter event title: "Coffee Meetup"
  3. Select location: Search and select a valid location
  4. Set start date/time: Tomorrow at 2:00 PM
  5. Check "No end time"
  6. Tap "Create Event" (without adding invitees)
- [ ] **Expected:** Successful creation of event
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.1.2: Create Event with All Fields (User A invites User B)
- [ ] **Steps:**
  1. Enter event title: "Beach Day"
  2. Select location: "Santa Monica Beach, CA" (or any valid location)
  3. Enter description: "Let's enjoy the sun and surf!"
  4. Upload event photo from gallery
  5. Crop the photo
  6. Set start date/time: This Saturday at 10:00 AM
  7. Uncheck "No end time"
  8. Set end date/time: This Saturday at 5:00 PM
  9. Tap "Add People" for invitees
  10. Search and select User B
  11. Tap "Create Event"
- [ ] **Expected:** Event created successfully, redirected to "My Events" tab
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.1.3: View Created Event (User A)
- [ ] **Steps:**
  1. In "My Events" tab, locate "Beach Day" event
  2. Tap on it to view details
- [ ] **Expected:** All event details displayed correctly (title, location, description, time, image, attendees)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 3.2 Event Validation

#### Test 3.2.1: Event Title Too Short
- [ ] **Steps:**
  1. Try to create event with title "Ab" (2 characters)
  2. Fill other required fields
  3. Tap "Create Event"
- [ ] **Expected:** Error: "Event title must be at least 3 characters long"
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.2.2: Missing Location
- [ ] **Steps:**
  1. Create event with title but no location
  2. Tap "Create Event"
- [ ] **Expected:** Error: "Please select a location for your event"
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.2.3: Past Start Time
- [ ] **Steps:**
  1. Create event with start time in the past
  2. Tap "Create Event"
- [ ] **Expected:** Error: "Event start time cannot be in the past"
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.2.4: End Time Before Start Time
- [ ] **Steps:**
  1. Set start time: 5:00 PM
  2. Set end time: 3:00 PM (same day)
  3. Tap "Create Event"
- [ ] **Expected:** Error: "Event end time must be after the start time"
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.2.5: Description Character Limit
- [ ] **Steps:**
  1. Start typing description
  2. Continue past 1000 characters
- [ ] **Expected:** Character counter turns red, typing stops at 1000 characters
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 3.3 Location Search

#### Test 3.3.1: Location Search Autocomplete
- [ ] **Steps:**
  1. In location field, type "Starbucks"
  2. Wait for suggestions
- [ ] **Expected:** List of nearby Starbucks locations appears
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.3.2: Select Location from Suggestions
- [ ] **Steps:**
  1. Tap on one of the location suggestions
- [ ] **Expected:** Location field populated with selected location (title and address)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.3.3: Clear Selected Location
- [ ] **Steps:**
  1. After selecting location, tap X button
- [ ] **Expected:** Location cleared, can search again
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.3.4: Location with Full Address
- [ ] **Steps:**
  1. Search for complete address
  2. Select it
  3. View in event details after creation
- [ ] **Expected:** Full address stored and displayed correctly
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 3.4 Event Image Upload

#### Test 3.4.1: Upload Event Image from Gallery
- [ ] **Steps:**
  1. In create event, tap event photo placeholder
  2. Select image from photo library
- [ ] **Expected:** Image crop view appears
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.4.2: Crop Event Image
- [ ] **Steps:**
  1. In crop view, adjust crop area
  2. Tap "Done" or equivalent
- [ ] **Expected:** Cropped image shown in event form
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.4.3: Cancel Image Selection
- [ ] **Steps:**
  1. Tap image placeholder
  2. Select image
  3. In crop view, tap "Cancel"
- [ ] **Expected:** Returns to form without image
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.4.4: Replace Event Image
- [ ] **Steps:**
  1. After selecting image, tap on it again
  2. Select different image
- [ ] **Expected:** New image replaces old one
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.4.5: Create Event with Large Image
- [ ] **Steps:**
  1. Select a very high-resolution image (>5MB)
  2. Crop and create event
- [ ] **Expected:** Image uploaded successfully (may be compressed)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 3.5 Inviting Users to Events

-- Would be good to fix the aesthetics of the "Not a user? Add by phone" button --
-- I still need to work on making sure I stop receiving notifications on a device I'm logged out of --

#### Test 3.5.1: Add Single Friend as Invitee
- [ ] **Steps:**
  1. In create event, tap "Add People"
  2. In "Friends" tab, select User B
  3. Tap "Done"
- [ ] **Expected:** User B appears in invitees list
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.5.2: Remove Invitee Before Creating
- [ ] **Steps:**
  1. In invitees list, tap X on User B
- [ ] **Expected:** User B removed from invitees
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.5.3: Add Multiple Friends
- [ ] **Steps:**
  1. If you have more test accounts, add multiple friends as invitees
- [ ] **Expected:** All selected friends appear in invitees list
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.5.4: Search Friend in Invitees Sheet
- [ ] **Steps:**
  1. Tap "Add People"
  2. Use search field to find specific friend
- [ ] **Expected:** Search filters friends list
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 3.6 SMS Invites (Phone Contacts)

#### Test 3.6.1: Add Phone Contact as Invitee
- [ ] **Steps:**
  1. In "Add People" sheet, go to "Contacts" tab
  2. Select a contact from device contacts (who doesn't have the app)
  3. Tap "Done"
- [ ] **Expected:** Contact appears in invitees list with phone icon
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.6.2: SMS Composer Opens
- [ ] **Steps:**
  1. With phone contact in invitees, tap "Create Event"
- [ ] **Expected:** SMS message composer opens with pre-filled message including event link
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.6.3: Send SMS Invite
- [ ] **Steps:**
  1. In SMS composer, tap "Send"
- [ ] **Expected:** SMS sent, event created, returned to My Events
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.6.4: Cancel SMS Invite
- [ ] **Steps:**
  1. Create event with phone contact
  2. When SMS composer opens, tap "Cancel"
- [ ] **Expected:** Event is NOT created, user remains on Create Event screen to continue editing
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.6.5: Multiple Phone Contacts
- [ ] **Steps:**
  1. Add multiple phone contacts as invitees
  2. Create event
- [ ] **Expected:** SMS composer opens with all phone numbers
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 3.7 Date and Time Selection

-- I need to check why sometimes the default time for the start time is not as refreshed --
-- I need to check how are we handling time zone differences --
-- Some wrapping happens in the event details in the card at the top when the details are lengthy. Should figure that out --
-- Showing the duration of the event ... I should consider not only using hours and minutes but also days --

#### Test 3.7.1: Set Start Date (Future)
- [ ] **Steps:**
  1. Tap start date picker
  2. Select date 1 week from now
  3. Select time 3:00 PM
- [ ] **Expected:** Date and time updated correctly
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.7.2: Toggle "No End Time"
- [ ] **Steps:**
  1. Check "No end time" checkbox
- [ ] **Expected:** End time picker hidden
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.7.3: Uncheck "No End Time"
- [ ] **Steps:**
  1. Uncheck "No end time" checkbox
- [ ] **Expected:** End time picker appears
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.7.4: Set End Date on Different Day
- [ ] **Steps:**
  1. Set start: Today 11:00 PM
  2. Set end: Tomorrow 2:00 AM
- [ ] **Expected:** Multi-day event accepted
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 3.7.5: Time Zone Consistency
- [ ] **Steps:**
  1. Create event with specific time
  2. Check if time displays correctly in event details
- [ ] **Expected:** Time shown in device's timezone
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

## 4. EVENT INVITATIONS & RESPONSES

### 4.1 Receiving Invitations

-- Image update still doesn't sync smoothly --

#### Test 4.1.1: Receive Event Invitation Notification (User B)
- [ ] **Steps:**
  1. After User A creates event with User B invited
  2. On Device B, check for push notification
- [ ] **Expected:** Push notification received (if enabled)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 4.1.2: View Invitation in Invites Tab (User B)
- [ ] **Steps:**
  1. As User B, navigate to "Invites" tab
- [ ] **Expected:** "Beach Day" event appears in invites list
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 4.1.3: View Invitation Details (User B)
- [ ] **Steps:**
  1. Tap on "Beach Day" event in Invites
- [ ] **Expected:** Event details shown (title, host, location, time, description, image)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 4.2 Accepting Invitations

#### Test 4.2.1: Accept Event Invitation (User B)
- [ ] **Steps:**
  1. As User B, in event details, tap "Accept" or "Going"
- [ ] **Expected:** Status updated to "Accepted", event moves to "My Events" tab
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 4.2.2: Verify Event in My Events (User B)
- [ ] **Steps:**
  1. Navigate to "My Events" tab
- [ ] **Expected:** "Beach Day" event appears with "Going" status
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 4.2.3: Accepted Status Visible to Host (User A)
- [ ] **Steps:**
  1. On Device A, view "Beach Day" event details
  2. Check attendees list
- [ ] **Expected:** User B appears in "Accepted" attendees list
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 4.2.4: Accepted User Receives Updates
- [ ] **Steps:**
  1. As User A, edit the event (change time or location)
  2. On Device B, check if notification received
- [ ] **Expected:** User B notified of event changes (if notifications enabled)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 4.3 Declining Invitations

#### Test 4.3.1: Create Second Event (User A invites User B)
- [ ] **Steps:**
  1. As User A, create event "Movie Night" inviting User B
- [ ] **Expected:** Event created, User B receives invitation
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 4.3.2: Decline Event Invitation (User B)
- [ ] **Steps:**
  1. As User B, view "Movie Night" invitation
  2. Tap "Decline" or "Not Going"
- [ ] **Expected:** Status updated to "Declined", removed from invites
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 4.3.3: Declined Event Not in My Events
- [ ] **Steps:**
  1. Check User B's "My Events" tab
- [ ] **Expected:** "Movie Night" does NOT appear
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 4.3.4: Declined Status Visible to Host (User A)
- [ ] **Steps:**
  1. On Device A, view "Movie Night" event details
  2. Check attendees list
- [ ] **Expected:** User B appears in "Declined" attendees list
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 4.4 Changing Response

#### Test 4.4.1: Change from Accepted to Declined (User B)
- [ ] **Steps:**
  1. As User B, go to "Beach Day" (previously accepted)
  2. Tap "Decline" or "Not Going"
- [ ] **Expected:** Status changed, event may remain visible with declined status
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 4.4.2: Change from Declined to Accepted (User B)
- [ ] **Steps:**
  1. As User B, go to "Movie Night" (previously declined)
  2. Tap "Accept" or "Going"
- [ ] **Expected:** Status changed to accepted, event appears in My Events
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 4.4.3: Host Sees Updated Status
- [ ] **Steps:**
  1. As User A, refresh and check attendee lists for both events
- [ ] **Expected:** Updated statuses reflected accurately
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

## 5. EVENT MANAGEMENT

### 5.1 Editing Events (Host Only)

-- One issue observed is that invitees are not getting updates when outing details are changed or outing deleted --

#### Test 5.1.1: Edit Event Title (User A)
- [ ] **Steps:**
  1. As User A (host), view "Beach Day" event
  2. Tap "Edit" button
  3. Change title to "Beach Day - Updated"
  4. Tap "Update Event"
- [ ] **Expected:** Event title updated successfully
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 5.1.2: Edit Event Description
- [ ] **Steps:**
  1. Edit "Beach Day - Updated"
  2. Change description to "Bring sunscreen and towels!"
  3. Update event
- [ ] **Expected:** Description updated
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 5.1.3: Edit Event Time
- [ ] **Steps:**
  1. Edit event
  2. Change start time to 11:00 AM
  3. Update event
- [ ] **Expected:** Time updated, attendees notified (if enabled)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 5.1.4: Edit Event Location
- [ ] **Steps:**
  1. Edit event
  2. Change location to different beach
  3. Update event
- [ ] **Expected:** Location updated successfully
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 5.1.5: Edit Event Image
- [ ] **Steps:**
  1. Edit event
  2. Tap event image
  3. Select new image and crop
  4. Update event
- [ ] **Expected:** Event image updated
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 5.1.6: Add More Invitees to Existing Event
- [ ] **Steps:**
  1. Edit event
  2. Tap "Add People"
  3. Add additional friends or contacts
  4. Update event
- [ ] **Expected:** New invitees added, receive invitations
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 5.1.7: Remove Invitees (if supported)
- [ ] **Steps:**
  1. Edit event
  2. Try to remove an invitee
- [ ] **Expected:** Invitee removed or feature not available
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 5.1.8: Non-Host Cannot Edit (User B)
- [ ] **Steps:**
  1. As User B (invitee), view event details
  2. Look for edit button
- [ ] **Expected:** No edit button available for non-host
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 5.2 Deleting Events

#### Test 5.2.1: Delete Event (Host)
- [ ] **Steps:**
  1. As User A (host), view "Movie Night" event
  2. Look for delete option (swipe, button, etc.)
  3. Delete event
  4. Confirm deletion
- [ ] **Expected:** Event deleted, removed from all users' views
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 5.2.2: Verify Deletion for Invitees (User B)
- [ ] **Steps:**
  1. On Device B, check if "Movie Night" still appears
- [ ] **Expected:** Event no longer visible
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 5.2.3: Non-Host Cannot Delete
- [ ] **Steps:**
  1. As User B, look for delete option on events they didn't create
- [ ] **Expected:** No delete option available
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 5.3 Viewing Events

-- Would be nice to show a badge on "Invites" to show the number of unanswered invites --
-- Would be nice to make the attendees clickable to view their profile --

#### Test 5.3.1: View Event Details from My Events
- [ ] **Steps:**
  1. As User A, in My Events tab, tap on "Beach Day - Updated"
- [ ] **Expected:** Full event details shown
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 5.3.2: View Attendee List
- [ ] **Steps:**
  1. In event details, view attendees section
- [ ] **Expected:** Shows accepted, invited, and declined lists
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 5.3.3: View Attendee Profile
- [ ] **Steps:**
  1. Tap on User B in attendee list
- [ ] **Expected:** User B's profile shown
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Fail

#### Test 5.3.4: Event Sorting in My Events
- [ ] **Steps:**
  1. Create multiple events with different dates
  2. View My Events tab
- [ ] **Expected:** Events sorted by date (upcoming first)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 5.4 Event List Filtering

#### Test 5.4.1: My Events Shows Hosted Events
- [ ] **Steps:**
  1. As User A, view My Events tab
- [ ] **Expected:** Shows events where User A is host
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 5.4.2: My Events Shows Accepted Events
- [ ] **Steps:**
  1. As User B, view My Events tab
- [ ] **Expected:** Shows events User B has accepted
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 5.4.3: Invites Shows Pending Only
- [ ] **Steps:**
  1. Check Invites tab
- [ ] **Expected:** Only shows events with pending response
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 5.4.4: Past Events Handling
- [ ] **Steps:**
  1. Create event with date in the past (or wait for event to pass)
  2. Check if it still appears or is filtered
- [ ] **Expected:** Past events handled appropriately (hidden or marked)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

## 6. AI EVENT CREATION (If Feature Flag Enabled)

> **Note:** Based on FeatureFlags.swift, AI Event Creation is currently DISABLED (`enableAIEventCreation: false`). These tests should be run if the feature is enabled.

#### Test 6.1.1: Access AI Event Creation
- [ ] **Steps:**
  1. Set `FeatureFlags.enableAIEventCreation = true`
  2. Rebuild app
  3. Go to New Event tab
  4. Tap "Create with AI" button
- [ ] **Expected:** AI chat interface opens
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________
- [ ] **Status:** SKIP (Feature Disabled)

#### Test 6.1.2: AI Event Suggestion
- [ ] **Steps:**
  1. In AI chat, describe event (e.g., "Create a birthday party for Saturday")
  2. Submit
- [ ] **Expected:** AI suggests event details
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________
- [ ] **Status:** SKIP (Feature Disabled)

#### Test 6.1.3: Accept AI Suggestion
- [ ] **Steps:**
  1. Review AI suggestion
  2. Tap accept or create
- [ ] **Expected:** Pre-filled event form shown
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________
- [ ] **Status:** SKIP (Feature Disabled)

#### Test 6.1.4: Modify AI Suggestion
- [ ] **Steps:**
  1. After accepting, edit any field
  2. Create event
- [ ] **Expected:** Event created with modifications
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________
- [ ] **Status:** SKIP (Feature Disabled)

---

## 7. PUSH NOTIFICATIONS (OneSignal)

### 7.1 Notification Permissions

#### Test 7.1.1: Notification Permission Request (First Launch)
- [ ] **Steps:**
  1. Fresh install app
  2. Complete signup/login
  3. Check if notification permission requested
- [ ] **Expected:** System prompts for notification permission
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 7.1.2: Allow Notifications
- [ ] **Steps:**
  1. Tap "Allow" on permission prompt
- [ ] **Expected:** Notifications enabled
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 7.1.3: Deny Notifications
- [ ] **Steps:**
  1. On second device, deny notification permission
- [ ] **Expected:** App still functions, no notifications received
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 7.2 Event Notifications

#### Test 7.2.1: New Event Invitation Notification
- [ ] **Steps:**
  1. User A creates event inviting User B
  2. Check Device B for notification
- [ ] **Expected:** Push notification: "You're invited to [Event Name]"
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 7.2.2: Event Acceptance Notification
- [ ] **Steps:**
  1. User B accepts event
  2. Check Device A for notification
- [ ] **Expected:** Push notification: "[User B] accepted [Event Name]"
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 7.2.3: Event Decline Notification
- [ ] **Steps:**
  1. User B declines event
  2. Check Device A for notification
- [ ] **Expected:** Push notification: "[User B] declined [Event Name]"
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 7.2.4: Event Update Notification
- [ ] **Steps:**
  1. User A edits event (change time/location)
  2. Check Device B for notification
- [ ] **Expected:** Push notification: "[Event Name] has been updated"
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Fail

#### Test 7.2.5: Event Deletion Notification
- [ ] **Steps:**
  1. User A deletes event
  2. Check Device B for notification
- [ ] **Expected:** Push notification: "[Event Name] has been cancelled"
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Fail

---

### 7.3 Friend Notifications

#### Test 7.3.1: Friend Request Notification
- [ ] **Steps:**
  1. User A sends friend request to User B
  2. Check Device B for notification
- [ ] **Expected:** Push notification: "[User A] sent you a friend request"
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 7.3.2: Friend Request Accepted Notification
- [ ] **Steps:**
  1. User B accepts friend request
  2. Check Device A for notification
- [ ] **Expected:** Push notification: "[User B] accepted your friend request"
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 7.4 Notification Actions

-- It would be nice for the click on the notification to lead you to the right place --

#### Test 7.4.1: Tap Notification to Open App
- [ ] **Steps:**
  1. When notification received, tap on it
- [ ] **Expected:** App opens to relevant screen (event details, friend request, etc.)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Fail

#### Test 7.4.2: Notification When App is Open
- [ ] **Steps:**
  1. With app open, trigger notification event
- [ ] **Expected:** In-app notification or silent update
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 7.4.3: Notification When App is Closed
- [ ] **Steps:**
  1. Close app completely
  2. Trigger notification event
  3. Check notification received
- [ ] **Expected:** Push notification appears
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

## 8. USER INTERFACE & EXPERIENCE

### 8.1 Navigation

#### Test 8.1.1: Tab Navigation
- [ ] **Steps:**
  1. Navigate through all 5 tabs (My Events, Invites, New Event, Friends, Settings)
- [ ] **Expected:** Smooth navigation, correct content in each tab
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 8.1.2: Back Navigation
- [ ] **Steps:**
  1. Navigate into detail view
  2. Tap back button
- [ ] **Expected:** Returns to previous screen
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 8.1.3: Tab Persistence
- [ ] **Steps:**
  1. Navigate to specific tab
  2. Go to detail view
  3. Return
- [ ] **Expected:** Returns to same tab
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 8.2 Visual Design

-- Still having issues with aspect ratios with images --

#### Test 8.2.1: Light Mode (Forced)
- [ ] **Steps:**
  1. Check Settings
  2. Verify app appearance
- [ ] **Expected:** App displays in light mode (forceLightMode = true)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 8.2.2: Dark Mode (If Feature Enabled)
- [ ] **Steps:**
  1. Set `FeatureFlags.forceLightMode = false`
  2. Enable dark mode on device
  3. Check app appearance
- [ ] **Expected:** App respects dark mode (if not forced to light)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________
- [ ] **Status:** SKIP (Light Mode Forced)

#### Test 8.2.3: Profile Pictures Display
- [ ] **Steps:**
  1. View various screens with profile pictures (friends list, attendees, etc.)
- [ ] **Expected:** All profile pictures load and display correctly
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 8.2.4: Event Images Display
- [ ] **Steps:**
  1. View events with images
- [ ] **Expected:** Event images load and display with correct aspect ratio
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Fail

#### Test 8.2.5: Placeholder Images
- [ ] **Steps:**
  1. View user without profile picture
  2. View event without image
- [ ] **Expected:** Appropriate placeholder images shown
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 8.3 Loading States

#### Test 8.3.1: Initial App Load
- [ ] **Steps:**
  1. Force quit app
  2. Reopen
- [ ] **Expected:** Loading indicator while data fetches
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 8.3.2: Creating Event Loading
- [ ] **Steps:**
  1. Create event and observe
- [ ] **Expected:** Button shows "Creating..." with spinner
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 8.3.3: Image Upload Loading
- [ ] **Steps:**
  1. Upload large image
  2. Observe upload process
- [ ] **Expected:** Loading indicator during upload
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 8.3.4: Pull to Refresh
- [ ] **Steps:**
  1. In My Events or Invites, pull down to refresh
- [ ] **Expected:** Data refreshes, loading indicator shown
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 8.4 Error Handling

-- This whole section needs rethinking. We have no error handling and we should. --

#### Test 8.4.1: No Internet Connection
- [ ] **Steps:**
  1. Enable airplane mode
  2. Try to create event or perform action
- [ ] **Expected:** Error message about connectivity
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

#### Test 8.4.2: Slow Internet Connection
- [ ] **Steps:**
  1. Use slow network (can simulate in Xcode)
  2. Perform actions
- [ ] **Expected:** Actions complete, appropriate timeouts or loading indicators
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Skipped

#### Test 8.4.3: Failed Image Upload
- [ ] **Steps:**
  1. With poor connection, try uploading very large image
- [ ] **Expected:** Error message if upload fails
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Skipped

#### Test 8.4.4: Server Error Handling
- [ ] **Steps:**
  1. (Difficult to test manually unless you can trigger server errors)
- [ ] **Expected:** Graceful error messages
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Skipped

---

### 8.5 Keyboard & Input

#### Test 8.5.1: Keyboard Appearance
- [ ] **Steps:**
  1. Tap on text fields in various forms
- [ ] **Expected:** Keyboard appears, correct type (email, default, number, etc.)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 8.5.2: Keyboard Dismissal
- [ ] **Steps:**
  1. Tap outside text field or tap return
- [ ] **Expected:** Keyboard dismisses appropriately
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 8.5.3: Field Scrolling with Keyboard
- [ ] **Steps:**
  1. In create event form, tap on field at bottom
- [ ] **Expected:** Form scrolls so field is visible above keyboard
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 8.5.4: Autocorrect and Autocapitalization
- [ ] **Steps:**
  1. Type in various fields
  2. Check for appropriate autocorrect/autocapitalization
- [ ] **Expected:** Email fields have autocorrect off, event titles have autocapitalization on, etc.
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

## 9. PERMISSIONS & PRIVACY

### 9.1 Photo Library Access

#### Test 9.1.1: Photo Library Permission Request
- [ ] **Steps:**
  1. First time tapping image picker
- [ ] **Expected:** System prompts for photo library access
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 9.1.2: Grant Photo Access
- [ ] **Steps:**
  1. Tap "Allow" on permission prompt
- [ ] **Expected:** Can select images from library
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 9.1.3: Deny Photo Access
- [ ] **Steps:**
  1. Deny photo library access
  2. Try to upload image
- [ ] **Expected:** Error message or prompt to go to settings
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 9.2 Contacts Access

#### Test 9.2.1: Contacts Permission Request
- [ ] **Steps:**
  1. First time accessing contacts in Add Invitees
- [ ] **Expected:** System prompts for contacts access
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 9.2.2: Grant Contacts Access
- [ ] **Steps:**
  1. Allow contacts access
  2. View contacts in invitees sheet
- [ ] **Expected:** Device contacts shown
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 9.2.3: Deny Contacts Access
- [ ] **Steps:**
  1. Deny contacts access
  2. Try to view contacts
- [ ] **Expected:** Empty state or prompt to enable in settings
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 9.3 Location Services

#### Test 9.3.1: Location Permission for Location Search
- [ ] **Steps:**
  1. Use location search in create event
  2. Check if permission requested
- [ ] **Expected:** May request location for "nearby" suggestions (implementation dependent)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

## 10. DATA PERSISTENCE & SYNC

### 10.1 Data Persistence

#### Test 10.1.1: App Backgrounding
- [ ] **Steps:**
  1. Create event partially
  2. Home button to background app
  3. Reopen app
- [ ] **Expected:** Draft data may or may not persist (check expected behavior)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 10.1.2: Force Quit and Reopen
- [ ] **Steps:**
  1. Force quit app
  2. Reopen
  3. Check if events and data load
- [ ] **Expected:** All data loads from Firebase
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 10.1.3: Logout and Login
- [ ] **Steps:**
  1. Logout
  2. Login with same credentials
- [ ] **Expected:** All events, friends, and data restored
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 10.2 Real-time Sync

-- This needs rethinking. Now I mostly have to manually refresh --

#### Test 10.2.1: Real-time Event Updates
- [ ] **Steps:**
  1. On Device A (User A), edit event
  2. On Device B (User B), check if event updates automatically
- [ ] **Expected:** Event details update in real-time or on refresh
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Skipped

#### Test 10.2.2: Real-time Friend Request
- [ ] **Steps:**
  1. User A sends friend request
  2. Check if Device B updates immediately
- [ ] **Expected:** Friend request appears in real-time or on refresh
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Skipped

#### Test 10.2.3: Real-time RSVP Updates
- [ ] **Steps:**
  1. User B RSVPs to event
  2. Check if attendee list updates on Device A
- [ ] **Expected:** Attendee list updates in real-time or on refresh
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Skipped

---

### 10.3 Multi-device Usage

#### Test 10.3.1: Same Account on Multiple Devices
- [ ] **Steps:**
  1. Login with same account on 2 devices
  2. Perform actions on one device
  3. Check other device
- [ ] **Expected:** Data syncs across devices
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 10.3.2: OneSignal Device Association
- [ ] **Steps:**
  1. Login on Device A
  2. Logout and login on Device B
  3. Send notification-triggering action
- [ ] **Expected:** Notification only sent to currently logged-in device
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Fail

---

## 11. EDGE CASES & STRESS TESTS

### 11.1 Data Limits (Skipped)

#### Test 11.1.1: Create Many Events
- [ ] **Steps:**
  1. Create 20+ events
  2. Check My Events tab performance
- [ ] **Expected:** All events load, scrolling is smooth
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

#### Test 11.1.2: Many Friends
- [ ] **Steps:**
  1. Add many friends (if possible)
  2. Check friends list performance
- [ ] **Expected:** List loads and scrolls smoothly
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

#### Test 11.1.3: Large Event Description
- [ ] **Steps:**
  1. Create event with maximum 1000 character description
- [ ] **Expected:** Full description saves and displays
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

#### Test 11.1.4: Long Event Title
- [ ] **Steps:**
  1. Create event with very long title (50+ characters)
- [ ] **Expected:** Title doesn't break UI layout
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

---

### 11.2 Special Characters & Internationalization

#### Test 11.2.1: Special Characters in Event Title
- [ ] **Steps:**
  1. Create event with title: "🎉 Birthday Party! @John's Place #2024"
- [ ] **Expected:** Special characters handled correctly
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 11.2.2: Emojis in Description
- [ ] **Steps:**
  1. Use multiple emojis in event description
- [ ] **Expected:** Emojis display correctly
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 11.2.3: Non-English Characters
- [ ] **Steps:**
  1. Create event with title/description in different language (e.g., "Fiesta de Cumpleaños", "パーティー", "الحفلة")
- [ ] **Expected:** Text displays and stores correctly
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

### 11.3 Rapid Actions

#### Test 11.3.1: Rapid Tapping
- [ ] **Steps:**
  1. Rapidly tap "Create Event" button multiple times
- [ ] **Expected:** Only one event created (button disabled during processing)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 11.3.2: Quick Navigation
- [ ] **Steps:**
  1. Rapidly switch between tabs
- [ ] **Expected:** No crashes, smooth navigation
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 11.3.3: Rapid Friend Requests
- [ ] **Steps:**
  1. Quickly send multiple friend requests
- [ ] **Expected:** All requests sent correctly, no duplicates
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Skipped

---

### 11.4 Boundary Conditions

#### Test 11.4.1: Event Exactly at Midnight
- [ ] **Steps:**
  1. Create event starting at 12:00 AM
- [ ] **Expected:** Time handled correctly, no date confusion
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 11.4.2: Event Spanning Daylight Saving Time
- [ ] **Steps:**
  1. Create event during DST transition period
- [ ] **Expected:** Time zones handled correctly
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Skipped

#### Test 11.4.3: Minimum Title Length (3 characters)
- [ ] **Steps:**
  1. Create event with exactly 3 character title: "BBQ"
- [ ] **Expected:** Event created successfully
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

## 12. SECURITY

### 12.1 Authentication Security (Skipped)

#### Test 12.1.1: Session Expiration
- [ ] **Steps:**
  1. Login
  2. Wait extended period (or manipulate session)
  3. Try to perform action
- [ ] **Expected:** Re-authentication required if session expired
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

#### Test 12.1.2: Concurrent Login Sessions
- [ ] **Steps:**
  1. Login on Device A
  2. Login with same account on Device B
- [ ] **Expected:** Both sessions work (or one is invalidated, depending on design)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

---

### 12.2 Data Access Control

#### Test 12.2.1: View Only Own Profile Data
- [ ] **Steps:**
  1. As User A, try to view User B's private data
- [ ] **Expected:** Only public data visible
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 12.2.2: Edit Only Own Events
- [ ] **Steps:**
  1. As User B, verify cannot edit User A's events
- [ ] **Expected:** No edit option available
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

#### Test 12.2.3: View Event Data (Invited Users Only)
- [ ] **Steps:**
  1. Create private event
  2. Verify only invited users can view
- [ ] **Expected:** Proper access control (implementation dependent)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** Pass

---

## 13. COMPATIBILITY & DEVICES

### 13.1 iOS Versions (Skipped)

#### Test 13.1.1: Minimum iOS Version
- [ ] **Steps:**
  1. Test on device with minimum supported iOS version
- [ ] **Expected:** App runs without crashes
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________
- [ ] **Minimum iOS:** _______________

#### Test 13.1.2: Latest iOS Version
- [ ] **Steps:**
  1. Test on device with latest iOS
- [ ] **Expected:** All features work correctly
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________
- [ ] **Latest iOS Tested:** _______________

---

### 13.2 Device Types (Skipped)

#### Test 13.2.1: iPhone SE (Small Screen)
- [ ] **Steps:**
  1. Test on iPhone SE or similar small screen
  2. Check UI layout
- [ ] **Expected:** UI adapts correctly, no cut-off elements
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

#### Test 13.2.2: iPhone Pro Max (Large Screen)
- [ ] **Steps:**
  1. Test on largest iPhone
  2. Check UI scaling
- [ ] **Expected:** UI uses screen space effectively
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

#### Test 13.2.3: iPad (if supported)
- [ ] **Steps:**
  1. Test on iPad
- [ ] **Expected:** App runs (may be iPhone layout scaled)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________
- [ ] **Status:** N/A if iPad not supported

---

### 13.3 Orientation (Skipped)

#### Test 13.3.1: Portrait Mode
- [ ] **Steps:**
  1. Use app in portrait orientation
- [ ] **Expected:** Default expected behavior
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

#### Test 13.3.2: Landscape Mode
- [ ] **Steps:**
  1. Rotate device to landscape
  2. Navigate through app
- [ ] **Expected:** UI adapts or locks to portrait (check design intent)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

---

## 14. PERFORMANCE

### 14.1 App Launch (Skipped)

#### Test 14.1.1: Cold Launch Time
- [ ] **Steps:**
  1. Force quit app
  2. Measure time to launch and reach main screen
- [ ] **Expected:** Launches within reasonable time (< 5 seconds)
- [ ] **Actual Time:** _______________
- [ ] **Pass/Fail:** _______________

#### Test 14.1.2: Memory Usage
- [ ] **Steps:**
  1. Monitor memory usage during normal operation
- [ ] **Expected:** No excessive memory consumption
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

---

### 14.2 Scrolling & Animation (Skipped)

#### Test 14.2.1: Smooth Scrolling in Event Lists
- [ ] **Steps:**
  1. With many events, scroll through list quickly
- [ ] **Expected:** 60 FPS scrolling, no lag
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

#### Test 14.2.2: Image Loading Performance
- [ ] **Steps:**
  1. Scroll through events/friends with images
- [ ] **Expected:** Images load progressively, no janky scrolling
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

#### Test 14.2.3: Animation Smoothness
- [ ] **Steps:**
  1. Observe transitions, sheet presentations, etc.
- [ ] **Expected:** Smooth 60 FPS animations
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

---

## 15. ACCESSIBILITY

### 15.1 VoiceOver (Skipped)

#### Test 15.1.1: VoiceOver Navigation
- [ ] **Steps:**
  1. Enable VoiceOver
  2. Navigate through app
- [ ] **Expected:** All elements properly labeled and accessible
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

#### Test 15.1.2: Button Labels
- [ ] **Steps:**
  1. With VoiceOver, tap buttons
- [ ] **Expected:** Clear, descriptive labels announced
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

---

### 15.2 Dynamic Type (Skipped)

#### Test 15.2.1: Larger Text Sizes
- [ ] **Steps:**
  1. Enable largest text size in iOS settings
  2. Check app layout
- [ ] **Expected:** Text scales, layout doesn't break
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

#### Test 15.2.2: Smaller Text Sizes
- [ ] **Steps:**
  1. Set smallest text size
  2. Check readability
- [ ] **Expected:** Text still readable and UI looks good
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

---

### 15.3 Color Contrast (Skipped)

#### Test 15.3.1: Color Contrast Ratios
- [ ] **Steps:**
  1. Review text on backgrounds throughout app
- [ ] **Expected:** Meets WCAG guidelines (4.5:1 for normal text)
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

---

## 16. APP FLOW INTEGRATION TESTS (Skipped)

### 16.1 Complete User Journey: User A

#### Test 16.1.1: User A Complete Flow
- [ ] **Steps:**
  1. Fresh install app
  2. Sign up as User A
  3. Verify email
  4. Upload profile picture
  5. Link phone number
  6. Search and send friend request to User B
  7. Wait for acceptance
  8. Create event "Dinner at 7PM" inviting User B
  9. View event in My Events
  10. Edit event to change time
  11. View User B's acceptance
  12. Delete event
- [ ] **Expected:** Entire flow completes without errors
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

---

### 16.2 Complete User Journey: User B

#### Test 16.2.1: User B Complete Flow
- [ ] **Steps:**
  1. Fresh install app on Device B
  2. Sign up as User B
  3. Verify email
  4. Upload profile picture
  5. Receive friend request from User A
  6. Accept friend request
  7. Receive event invitation "Dinner at 7PM"
  8. View event details
  9. Accept event
  10. Verify event in My Events
  11. Receive event update notification
  12. Change RSVP to decline
  13. Verify event removed from My Events
- [ ] **Expected:** Entire flow completes without errors
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

---

### 16.3 Complex Multi-Event Scenario

#### Test 16.3.1: Multiple Events & Users
- [ ] **Steps:**
  1. User A creates 3 different events with different dates
  2. Invite User B to all 3
  3. User B accepts 1, declines 1, leaves 1 pending
  4. User A edits accepted event
  5. User A creates new event, invites phone contact
  6. Send SMS
  7. Verify all events show correct status for both users
- [ ] **Expected:** All operations complete correctly, data consistency maintained
- [ ] **Actual:** _______________
- [ ] **Pass/Fail:** _______________

---

## SUMMARY

### Test Statistics
- **Total Tests:** _______________
- **Passed:** _______________
- **Failed:** _______________
- **Skipped:** _______________
- **Pass Rate:** _______________%

### Critical Issues Found
1. _______________
2. _______________
3. _______________

### Minor Issues Found
1. _______________
2. _______________
3. _______________

### Recommendations
1. _______________
2. _______________
3. _______________

### Overall Assessment
[ ] Ready for Production  
[ ] Needs Minor Fixes  
[ ] Needs Major Fixes  

### Tester Notes
_______________________________________________
_______________________________________________
_______________________________________________

---

**Test Completion Date:** _______________  
**Tester Signature:** _______________

