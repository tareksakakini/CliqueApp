# International Country Code Support

## Overview
The app now supports international phone numbers with country code selection for all authentication and phone-related features. Users can select their country from a comprehensive list and enter their phone number accordingly.

## Implementation

### Components Created

#### 1. `Country.swift` (Model)
- **Location:** `CliqueApp/Models/Country.swift`
- **Purpose:** Defines the Country model with dial codes, country names, flags, and ISO codes
- **Features:**
  - List of 90+ countries with their dial codes
  - Most commonly used countries appear first (US, Canada, UK, Australia, India, etc.)
  - Default country is United States (+1)
  - Helper methods to find countries by dial code or ISO code

#### 2. `CountryCodePicker.swift` (View Component)
- **Location:** `CliqueApp/Views/HelperViews/CountryCodePicker.swift`
- **Purpose:** A searchable picker for selecting countries
- **Features:**
  - Displays country flag, name, and dial code
  - Searchable by country name, dial code, or ISO code
  - Shows checkmark for currently selected country
  - Clean, modern UI design

#### 3. `PhoneNumberFieldWithCountryCode.swift` (Reusable Component)
- **Location:** `CliqueApp/Views/HelperViews/PhoneNumberFieldWithCountryCode.swift`
- **Purpose:** A reusable phone number input field with country code picker
- **Features:**
  - Country code button that opens the picker
  - Phone number text field
  - Consistent styling with the app's design
  - Helper method to get full E.164 formatted number

### Updated Components

#### 1. `PhoneNumberFormatter.swift`
- **Enhanced:** Added support for international phone numbers
- **New Method:** `e164(countryCode:phoneNumber:)` - Builds E.164 format from separate components
- **Improved:** Existing methods now handle international numbers better

#### 2. `LoginView.swift`
- **Updated:** Now uses `PhoneNumberFieldWithCountryCode`
- **Change:** Users select country code before entering phone number
- **Behavior:** Full phone number with country code is sent to verification

#### 3. `SignUpView.swift`
- **Updated:** Now uses `PhoneNumberFieldWithCountryCode`
- **Change:** Users select country code before entering phone number
- **Behavior:** Full phone number with country code is used for account creation

#### 4. `MySettingsView.swift` (PhoneLinkingSheet)
- **Updated:** Phone linking now supports international numbers
- **Change:** Users can select country code when linking phone numbers
- **Behavior:** Searches for event invitations with full international number

## User Flow

### Sign Up Flow
1. User opens Sign Up screen
2. User taps country code button (shows US +1 by default)
3. User searches/selects their country from the picker
4. User enters their phone number (without country code)
5. App combines country code + phone number into E.164 format
6. Verification code is sent to the complete number
7. User enters code and proceeds with account creation

### Login Flow
1. User opens Login screen
2. User taps country code button (shows US +1 by default)
3. User searches/selects their country from the picker
4. User enters their phone number (without country code)
5. App combines country code + phone number into E.164 format
6. Verification code is sent to the complete number
7. User enters code and signs in

### Phone Linking Flow
1. User goes to Settings → Link Phone Number
2. User taps country code button (shows US +1 by default)
3. User searches/selects their country from the picker
4. User enters their phone number (without country code)
5. App combines country code + phone number into E.164 format
6. App searches for event invitations sent to that number
7. App links any found invitations to the user's account

## Technical Details

### E.164 Format
All phone numbers are stored and used in E.164 format:
- Format: `+[country code][phone number]`
- Example: `+14155551234` (US), `+447911123456` (UK)
- No spaces, dashes, or parentheses

### Phone Number Validation
- User must enter at least one digit
- Leading zeros are automatically removed from phone numbers
- Country code is always included in the final format
- Firebase handles the actual phone number validation

### Supported Countries
The app includes 90+ countries including:
- **North America:** US, Canada, Mexico
- **Europe:** UK, France, Germany, Spain, Italy, and more
- **Asia:** India, China, Japan, South Korea, Singapore, and more
- **Middle East:** UAE, Saudi Arabia, Lebanon, Israel, and more
- **Africa:** South Africa, Nigeria, Kenya, Egypt, and more
- **Oceania:** Australia, New Zealand
- **South America:** Brazil, Argentina, Chile, Colombia, and more

### Backward Compatibility
- Existing users with US numbers continue to work seamlessly
- The system defaults to US (+1) for users who don't explicitly select a country
- Phone number matching logic handles both old and new formats

## Testing

### Test Cases
1. **Sign up with international number:**
   - Select a non-US country
   - Enter a valid phone number for that country
   - Verify code is received
   - Complete account creation
   - Verify account works correctly

2. **Login with international number:**
   - Select your country
   - Enter your phone number
   - Verify code is received
   - Complete login

3. **Link international phone number:**
   - Go to Settings
   - Select "Link Phone Number"
   - Choose your country
   - Enter phone number
   - Verify linking works

4. **Country picker search:**
   - Open country picker
   - Search by country name
   - Search by dial code
   - Verify results are correct

5. **Backward compatibility:**
   - Existing US users should be able to login without issues
   - US +1 should be the default selection

## Future Enhancements

### Potential Improvements
1. **Auto-detect country:** Use device locale to auto-select country
2. **Recent countries:** Show recently selected countries at the top
3. **Popular countries:** Section for most commonly selected countries
4. **Phone format preview:** Show how the number should be formatted for selected country
5. **Number length validation:** Validate number length based on country
6. **Contact picker integration:** Parse country code from contacts

## Notes

### Firebase Phone Auth
- Firebase Phone Auth supports international numbers
- Ensure APNs is properly configured for iOS to avoid reCAPTCHA
- Test phone numbers can be configured in Firebase Console for any country

### Database Considerations
- All phone numbers in Firestore should now include country code
- Canonical format may vary by country (US uses 10 digits, others include country code)
- Phone matching logic accounts for different formats

### UI/UX Considerations
- Country picker is searchable for ease of use
- Flag emojis provide visual recognition
- Dial code is displayed prominently
- Consistent design throughout the app

## Migration

### No Migration Required
- New feature is additive
- Existing phone numbers continue to work
- Users can update their phone number format by:
  1. Linking a new phone number with country code
  2. Or continuing to use existing US number

## Support

### Common Issues
1. **Verification not received:** Check Firebase Phone Auth configuration
2. **Invalid number error:** Ensure country code matches the phone number
3. **Rate limiting:** Use Firebase test phone numbers during development

### Debug Tips
- Check console logs for E.164 formatted numbers
- Verify country code is included in the phone number string
- Ensure Firebase project supports international SMS

