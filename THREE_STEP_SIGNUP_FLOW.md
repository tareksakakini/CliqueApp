# Three-Step Sign-Up Flow

## Overview

The sign-up flow has been redesigned to be a three-step process that verifies the phone number first before collecting personal information. This creates a better user experience and ensures the phone number is valid before the user invests time filling out their profile.

## New Sign-Up Flow

### **Step 1: Phone Number Entry (SignUpView)**
- User enters only their phone number
- Taps "Continue"
- System sends verification code via SMS
- Navigates to verification screen

### **Step 2: Code Verification (VerificationCodeView)**
- Shows formatted phone number: "(650) 555-1234"
- User enters 6-digit verification code
- Option to resend code (60-second cooldown)
- Taps "Continue"
- System verifies the code
- Navigates to account information screen

### **Step 3: Profile Completion (AccountInfoView)**
- User enters:
  - Full name
  - Username (with real-time availability check)
  - Gender selection
- User agrees to:
  - Age requirement (16+)
  - Privacy Policy
- Taps "Create Account"
- System creates account and logs in user
- Navigates to MainView

## Files Structure

### **New Files**
- `AccountInfoView.swift` - Screen for entering personal information after phone verification

### **Modified Files**
- `SignUpView.swift` - Now only collects phone number (like LoginView)
- `VerificationCodeView.swift` - Routes to AccountInfoView for sign-up, MainView for login

## Benefits of This Approach

### **User Experience**
1. **Less Commitment** - User doesn't fill out entire profile only to find their phone number is invalid
2. **Better Flow** - One focused task per screen
3. **Clear Progress** - Phone → Verify → Profile
4. **No Wasted Effort** - Phone is validated before profile creation

### **Technical Benefits**
1. **Cleaner Separation** - Each screen has one responsibility
2. **Reusable Components** - Verification screen shared between login and sign-up
3. **Better Error Handling** - Errors are specific to each step
4. **Easier Testing** - Each step can be tested independently

## User Flow Comparison

### Old Flow (2 Steps)
```
Step 1: Enter ALL info + phone
Step 2: Enter verification code → Create account
```
**Problem:** If phone is invalid or verification fails, user wasted time filling out entire profile.

### New Flow (3 Steps)
```
Step 1: Enter phone number
Step 2: Verify phone with code
Step 3: Enter profile info → Create account
```
**Benefit:** Phone is verified BEFORE user fills out profile. No wasted effort.

## Technical Implementation

### State Management

**SignUpView:**
- `phoneNumber`: User input
- `verificationID`: Received from Firebase
- `isSendingCode`: Loading state
- `errorMessage`: Error feedback
- `goToVerificationScreen`: Navigation trigger

**VerificationCodeView:**
- `phoneNumber`, `verificationID`: Passed from previous screen
- `isSignUp`: Boolean flag to determine flow
- `verificationCode`: User input
- `isVerifying`: Loading state
- `goToAccountInfo`: Navigation to profile screen (sign-up)
- `goToMainView`: Navigation to main app (login)

**AccountInfoView:**
- `phoneNumber`, `verificationID`, `verificationCode`: Passed from verification
- `fullname`, `username`, `gender`: User inputs
- `isUsernameTaken`: Real-time availability check
- `isAgeChecked`, `isAgreePolicy`: Consent flags
- `isCreatingAccount`: Loading state
- `goToMainView`: Navigation trigger

### Data Flow

**Sign-Up:**
```
SignUpView 
  → Enter phone
  → Send verification code
  → Navigate to VerificationCodeView(isSignUp: true)
  
VerificationCodeView
  → Verify code
  → Navigate to AccountInfoView
  
AccountInfoView
  → Enter personal info
  → Create account with verified phone
  → Navigate to MainView
```

**Login (Unchanged):**
```
LoginView
  → Enter phone
  → Send verification code
  → Navigate to VerificationCodeView(isSignUp: false)
  
VerificationCodeView
  → Verify code
  → Sign in user
  → Navigate to MainView
```

## Error Handling

Each step has its own error handling:

**Step 1 - Phone Entry:**
- Invalid phone number format
- Network errors sending code
- Rate limiting errors

**Step 2 - Verification:**
- Invalid verification code
- Expired verification code
- Code already used
- Option to resend

**Step 3 - Profile Info:**
- Empty required fields
- Username already taken
- Age/policy agreement required
- Account creation errors

## Validation Logic

### Phone Number (SignUpView)
- Must be at least 10 digits
- Formatted to E.164 standard (+1XXXXXXXXXX)
- Validated before sending code

### Verification Code (VerificationCodeView)
- Must be 6 digits
- Must match code sent to phone
- Expires after a few minutes
- Can request new code after 60 seconds

### Personal Info (AccountInfoView)
- Full name: Cannot be empty
- Username: Must be unique (real-time check)
- Gender: Pre-selected options
- Age checkbox: Must be checked
- Privacy policy: Must be agreed to

## Testing

### With Firebase Test Numbers

Add test numbers in Firebase Console (see FIREBASE_TEST_NUMBERS.md):

**Complete Sign-Up Flow:**
1. **SignUpView:** Enter `650-555-1234` → Tap Continue
2. **VerificationCodeView:** Enter `123456` → Tap Continue
3. **AccountInfoView:** 
   - Name: "Test User"
   - Username: "testuser123"
   - Gender: Select any
   - Check age and policy boxes
   - Tap "Create Account"
4. Success! → MainView ✅

No rate limits, no SMS costs, instant verification at each step.

## UI/UX Design Principles

### Consistency
- All three screens use the same design language
- Card-based form layouts
- Consistent button styling
- Same color scheme and spacing

### Clarity
- Clear headers explain each step
- Progress is evident (phone → verify → profile)
- Error messages are specific and actionable

### Efficiency
- Minimal fields per screen
- Smart defaults (gender)
- Real-time validation (username)
- Auto-formatting (phone display)

### Feedback
- Loading states on all buttons
- Success/error messages
- Timer for code resend
- Username availability indicator

## Future Enhancements

Possible improvements:
- Add progress indicator showing 3 steps
- Auto-advance from Step 2 to Step 3 after verification
- Save partial profile data if user exits
- Add profile picture upload in Step 3
- Social media account linking
- Email as optional backup contact

