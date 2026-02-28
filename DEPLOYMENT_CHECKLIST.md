# SetiaU Deployment Checklist

## Pre-Launch Checklist

Use this guide to verify SetiaU is properly configured before launch.

---

## ✅ Phase 1: Local Development (Days 1-2)

### Flutter Setup

- [ ] Flutter 3.11+ installed (`flutter --version`)
- [ ] Android SDK/iOS Xcode configured
- [ ] Device/emulator available for testing
- [ ] `flutter pub get` completed without errors
- [ ] `flutter doctor` shows all green

### Firebase Project Created

- [ ] Firebase project created in [console.firebase.google.com](https://console.firebase.google.com)
- [ ] Google Sign-In enabled in Authentication
- [ ] Firestore Database created (test mode initially)
- [ ] Project ID noted (e.g., `kitahack-setiau-2026`)

### Dependencies Installed

- [ ] Core packages: `firebase_core`, `firebase_auth`, `cloud_firestore`
- [ ] Google: `google_sign_in`, `google_generative_ai`
- [ ] Audio: `record`, `speech_to_text`
- [ ] Utilities: `provider`, `uuid`, `intl`
- [ ] Dev: `flutter_lints`

### Google Cloud Project

- [ ] Google Cloud project created and linked to Firebase
- [ ] Gemini 2.0 Pro API enabled
- [ ] Service account created
- [ ] Service account key downloaded and secured

---

## ✅ Phase 2: Firebase Integration (Days 2-3)

### Firestore Database

- [ ] Main collections created:
  - [ ] `organizations`
  - [ ] `meetings`
  - [ ] `tasks`
  - [ ] `actions`
  - [ ] `budgets`
- [ ] Firestore indexes created (if needed for complex queries)
- [ ] Backup enabled in GCP Console

### Firestore Security Rules

- [ ] Authentication rules enforced (only authenticated users)
- [ ] Organization membership validation
- [ ] Admin-only write access to certain collections
- [ ] Read-only access for archive collections
- [ ] Rules tested in Firestore emulator

### Firebase Authentication

- [ ] Google Sign-In provider enabled
- [ ] OAuth client IDs configured:
  - [ ] Web client ID (for emulator)
  - [ ] Android client ID (SHA-1 fingerprint obtained)
  - [ ] iOS client ID
- [ ] Test accounts created for testing

### Cloud Functions

- [ ] Cloud Functions enabled in GCP
- [ ] `functions/package.json` dependencies installed
- [ ] Firebase Secret set (required for Google Workspace execution):
  ```bash
  firebase functions:secrets:set GOOGLE_SERVICE_ACCOUNT_KEY
  ```
- [ ] Test deployment successful (`firebase deploy --only functions --dry-run`)

---

## ✅ Phase 3: Google Workspace Integration (Days 3-4)

### APIs Enabled in GCP Console

- [ ] Google Calendar API
- [ ] Gmail API
- [ ] Google Docs API
- [ ] Google Sheets API
- [ ] Google Drive API

### Service Account Configuration

- [ ] Service account email created
- [ ] Domain-wide delegation enabled in Google Workspace Admin
- [ ] OAuth scopes granted to service account:
  ```
  https://www.googleapis.com/auth/calendar
  https://www.googleapis.com/auth/gmail.send
  https://www.googleapis.com/auth/drive
  https://www.googleapis.com/auth/spreadsheets
  https://www.googleapis.com/auth/documents
  ```
- [ ] Service account key securely stored in Cloud Functions config

### Test Google Workspace Account

- [ ] Test organization created in Google Workspace
- [ ] Test users created (Ali, Sarah, John)
- [ ] Test calendar shared with service account
- [ ] Test Gmail account configured
- [ ] Test Google Sheets created for budget tracking

---

## ✅ Phase 4: Gemini AI Integration (Day 4)

### Gemini API Configuration

- [ ] API key obtained from [Google AI Studio](https://aistudio.google.com/app/apikey)
- [ ] API key stored locally for development in `.env` (git-ignored)
- [ ] Quota limits checked (request rate, daily limit)
- [ ] Test prompts validated in Google AI Studio

### Gemini Service Testing

- [ ] Task extraction prompts tested with sample transcripts
- [ ] Constraint detection prompts validated
- [ ] JSON parsing logic implemented for responses
- [ ] Fallback behavior defined (if API rate limited)
- [ ] Error handling for API failures

### Evaluation Model

- [ ] Model confirmed (see `lib/services/gemini_service.dart`, currently `gemini-2.5-flash`)
- [ ] Token limits understood (context window ~100k tokens)
- [ ] Cost estimation done (pricing confirmed)

---

## ✅ Phase 5: App Testing (Day 5)

### Local App Testing

- [ ] App launches without errors
- [ ] Login screen appears
- [ ] Google Sign-In button works
- [ ] User successfully authenticates
- [ ] Home screen displays with two tabs

### Meeting Mode Testing

- [ ] Recording button visible and clickable
- [ ] Stop button appears when recording
- [ ] Mock task extraction shows on stop
- [ ] Task list displays with proper formatting
- [ ] Approve/Save button saves to Firestore

### Dashboard Mode Testing

- [ ] Pending actions list shows (3 items for MVP)
- [ ] Action expansion shows full details
- [ ] Constraints display when present
- [ ] Approve button removes action from list
- [ ] Reject button handles rejection
- [ ] Success messages appear after actions

### Firebase Integration Testing

- [ ] Data appears in Firestore after approval
- [ ] Collections properly structured
- [ ] Timestamps saved correctly
- [ ] User ID recorded with actions
- [ ] Sign-out clears auth state

---

## ✅ Phase 6: Cloud Functions Testing (Day 6)

### Function Deployment

- [ ] `executeCalendarAction` deployed and callable
- [ ] `executeEmailAction` deployed and callable
- [ ] `executeSheetsAction` deployed and callable
- [ ] `executeDocsAction` deployed and callable
- [ ] All functions accessible from Flutter app

### Function Testing

- [ ] Calendar function creates test event in Google Calendar
- [ ] Email function sends test email
- [ ] Sheets function updates test sheet
- [ ] Docs function creates test document
- [ ] All functions return proper success responses
- [ ] Error handling works for invalid inputs

### Authentication in Functions

- [ ] Firebase Auth tokens verified in each function
- [ ] Unauthorized requests rejected properly
- [ ] User IDs correctly extracted from tokens

---

## ✅ Phase 7: End-to-End Testing (Day 6)

### Complete Flow Test 1: Basic Task Extraction

1. [ ] Start with fresh login
2. [ ] Navigate to Meeting Mode
3. [ ] Tap "Start Recording"
4. [ ] Wait 3 seconds
5. [ ] Tap "Stop Recording"
6. [ ] Verify 3 tasks extracted
7. [ ] Check task details are populated
8. [ ] Tap "Approve & Save"
9. [ ] Verify Firestore has task documents

### Complete Flow Test 2: Action Approval

1. [ ] Navigate to Dashboard Mode
2. [ ] Verify 3 pending actions visible
3. [ ] Expand first action (calendar event)
4. [ ] Note constraints if present
5. [ ] Tap "Approve"
6. [ ] Verify action removed from list
7. [ ] Check Google Calendar for event
8. [ ] Verify Firestore shows `status: executed`

### Complete Flow Test 3: Rejection Flow

1. [ ] See pending action in Dashboard
2. [ ] Tap "Reject" button
3. [ ] Verify action stays in list (changes status)
4. [ ] Check Firestore shows `status: rejected`
5. [ ] Verify rejection reason logged

---

## ✅ Phase 8: Production Hardening (Day 7)

### Security Review

- [ ] API keys not exposed in code (using Remote Config)
- [ ] Firestore rules properly restrict access
- [ ] Authentication enforced on all endpoints
- [ ] Sensitive data encrypted (if applicable)
- [ ] Rate limiting configured
- [ ] Input validation on all user inputs

### Performance Testing

- [ ] App response time < 500ms for UI actions
- [ ] Task extraction completes within 10 seconds
- [ ] Firebase queries optimized with indexes
- [ ] Cloud Functions cold start time noted
- [ ] Firestore read/write quotas monitored

### Error Handling

- [ ] Network errors handled gracefully
- [ ] API timeout errors show user message
- [ ] Invalid input shows helpful error
- [ ] Partial failures logged but don't crash app
- [ ] User can retry failed actions

### Monitoring Setup

- [ ] Firebase Console dashboards opened
- [ ] Cloud Functions error logs viewed
- [ ] Firestore quota dashboard set up
- [ ] Firebase Performance Monitoring enabled
- [ ] Crash reporting configured

---

## ✅ Phase 9: Documentation Review

### Code Documentation

- [ ] main.dart has comments explaining structure
- [ ] Service classes documented with JSDoc
- [ ] Model classes properly commented
- [ ] Firebase schema documented in README
- [ ] API function signatures clear

### User Documentation

- [ ] README.md complete and accurate
- [ ] SETUP_GUIDE.md updated with actual project IDs
- [ ] Troubleshooting section populated
- [ ] Screenshots added (if available)
- [ ] Quick start guide tested independently

### Deployment Documentation

- [ ] Firebase deployment steps documented
- [ ] Cloud Functions deployment tested with instructions
- [ ] All API keys noted (but not in README)
- [ ] Configuration examples provided
- [ ] Rollback procedures documented

---

## ✅ Phase 10: Launch Preparation

### Pre-Launch

- [ ] Git repository created and committed
- [ ] `.gitignore` configured (no keys exposed)
- [ ] README.md reviewed for accuracy
- [ ] SETUP_GUIDE.md complete and tested
- [ ] All sensitive credentials removed from code
- [ ] Project tagged with version number

### Launch

- [ ] Final end-to-end test completed
- [ ] Stakeholders notified of launch
- [ ] Monitoring dashboards active
- [ ] Support contact information available
- [ ] Post-launch support plan ready

### Post-Launch

- [ ] Daily log review for errors
- [ ] User feedback collection set up
- [ ] Performance metrics tracked
- [ ] Security monitoring active
- [ ] Backup verification completed

---

## ✅ Success Criteria

Launch is successful when:

✅ User can login with Google  
✅ User can start/stop recording in Meeting Mode  
✅ 3 tasks extracted on stop  
✅ User can navigate to Dashboard  
✅ 3 pending actions visible  
✅ User can approve action  
✅ Firestore shows saved data with correct structure  
✅ Application doesn't crash on normal usage  
✅ All screens accessible without errors

---

## ⚠️ Known Limitations (MVP Phase)

- [ ] Audio recording not actually implemented (mock only)
- [ ] Gemini JSON parsing incomplete (mock responses used)
- [ ] Google Workspace API calls stubbed (not executed)
- [ ] Single organization only (no multi-org support)
- [ ] No offline functionality
- [ ] No data sync for offline changes

---

## 🔄 Post-MVP Roadmap

After successful launch, implement:

1. **Real Audio Processing**
   - [ ] Integrate speech-to-text service
   - [ ] Store transcripts in Cloud Storage
   - [ ] Real Gemini API calls

2. **Google Workspace Execution**
   - [ ] Implement service account OAuth
   - [ ] Real Calendar API calls
   - [ ] Real Gmail API calls
   - [ ] Real Sheets/Docs integration

3. **Advanced Features**
   - [ ] Multi-organization support
   - [ ] Role-based permissions
   - [ ] Budget forecasting
   - [ ] Meeting analytics

4. **Performance & Scaling**
   - [ ] Firestore database optimization
   - [ ] Cloud Functions scaling
   - [ ] Caching strategy
   - [ ] CDN for static assets

---

## 📞 Support Contacts

- **Firebase Issues**: Firebase Console → Support or [Firebase Docs](https://firebase.google.com/docs)
- **Gemini API Issues**: [Google AI Forum](https://discuss.ai.google.dev/)
- **Flutter Issues**: [Flutter Docs](https://flutter.dev/docs)
- **Deployment Help**: See SETUP_GUIDE.md troubleshooting

---

**SetiaU Launch Checklist v1.0**  
_KitaHack 2026 - The Agentic Secretary_

Last Updated: February 23, 2026
