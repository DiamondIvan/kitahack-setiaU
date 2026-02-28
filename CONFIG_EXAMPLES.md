# SetiaU Configuration Examples

This file provides example configurations for local development and production.

---

## Firebase Configuration (firebase.json)

```json
{
  "projects": {
    "default": "kitahack-setiau-2026"
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "functions": {
    "predeploy": ["npm --prefix \"$RESOURCE_DIR\" run lint"],
    "source": "functions",
    "codebase": "default"
  },
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "functions": {
      "port": 5001
    },
    "pubsub": {
      "port": 8085
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  },
  "hosting": {
    "public": "web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

---

## Firestore Security Rules (firestore.rules)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper: Check if user is authenticated
    function isAuth() {
      return request.auth != null;
    }

    // Helper: Check if user is organization admin
    function isOrgAdmin(orgId) {
      return isAuth() &&
             get(/databases/$(database)/documents/organizations/$(orgId)).data.admin == request.auth.uid;
    }

    // Helper: Check if user is org member
    function isOrgMember(orgId) {
      return isAuth() &&
             request.auth.uid in get(/databases/$(database)/documents/organizations/$(orgId)).data.members;
    }

    // Organizations: Admin can create/update, members can read
    match /organizations/{orgId} {
      allow read: if isAuth() && isOrgMember(orgId);
      allow create: if isAuth();
      allow update, delete: if isAuth() && isOrgAdmin(orgId);
    }

    // Meetings: Members can create/read, admin can update
    match /meetings/{meetingId} {
      allow create, read: if isAuth() &&
                            isOrgMember(get(resource.data).organizationId);
      allow update: if isAuth() &&
                       isOrgAdmin(get(resource.data).organizationId);
      allow delete: if isAuth() &&
                       isOrgAdmin(get(resource.data).organizationId);
    }

    // Tasks: Members can create/read, assigned users can update
    match /tasks/{taskId} {
      allow create, read: if isAuth() &&
                            isOrgMember(
                              get(/databases/$(database)/documents/meetings/
                                $(get(resource.data).meetingId)).data.organizationId
                            );
      allow update: if isAuth() &&
                       (request.auth.uid == resource.data.assignedTo ||
                        isOrgAdmin(
                          get(/databases/$(database)/documents/meetings/
                            $(get(resource.data).meetingId)).data.organizationId
                        ));
    }

    // Actions: Authenticated users can read, approval required to update
    match /actions/{actionId} {
      allow read: if isAuth();
      allow create: if isAuth();
      allow update: if isAuth() &&
                       (request.auth.uid == get(resource.data).approvedBy ||
                        request.auth.uid == 'cloud-function-service');
    }

    // Budgets: Members can read, admin can update
    match /budgets/{budgetId} {
      allow read: if isAuth() &&
                     isOrgMember(resource.data.organizationId);
      allow update: if isAuth() &&
                       isOrgAdmin(resource.data.organizationId);
    }

    // Action Logs: Immutable, append-only
    match /action_logs/{logId} {
      allow read: if isAuth();
      allow create: if isAuth();
      allow update, delete: never;
    }
  }
}
```

---

## Cloud Functions Configuration (.env)

Store these securely in Firebase Remote Config:

```bash
# Google AI/Gemini Configuration
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-2.0-pro

# Google Cloud Configuration
GCP_PROJECT_ID=kitahack-setiau-2026
GCP_SERVICE_ACCOUNT_EMAIL=setiau-service@kitahack-setiau-2026.iam.gserviceaccount.com

# Firebase Configuration
FIREBASE_AUTH_DOMAIN=kitahack-setiau-2026.firebaseapp.com
FIREBASE_DATABASE_URL=https://kitahack-setiau-2026.firebaseio.com

# Google Workspace Configuration
GOOGLE_WORKSPACE_DOMAIN=organization.com

# Application Configuration
ENVIRONMENT=production
LOG_LEVEL=info
```

---

## Flutter Environment Configuration (lib/config/firebase_config.dart)

```dart
class FirebaseConfig {
  // Development
  static const String devProjectId = 'kitahack-setiau-dev';
  static const String devDatabaseURL = 'https://kitahack-setiau-dev.firebaseio.com';

  // Production
  static const String prodProjectId = 'kitahack-setiau-2026';
  static const String prodDatabaseURL = 'https://kitahack-setiau-2026.firebaseio.com';

  // Current environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static String get projectId {
    return environment == 'production' ? prodProjectId : devProjectId;
  }

  static String get databaseUrl {
    return environment == 'production' ? prodDatabaseURL : devDatabaseURL;
  }
}
```

---

## Firestore Indexes (firestore.indexes.json)

```json
{
  "indexes": [
    {
      "collectionGroup": "meetings",
      "queryScope": "Collection",
      "fields": [
        { "fieldPath": "organizationId", "order": "ASCENDING" },
        { "fieldPath": "startTime", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "tasks",
      "queryScope": "Collection",
      "fields": [
        { "fieldPath": "meetingId", "order": "ASCENDING" },
        { "fieldPath": "dueDate", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "tasks",
      "queryScope": "Collection",
      "fields": [
        { "fieldPath": "assignedTo", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "dueDate", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "actions",
      "queryScope": "Collection",
      "fields": [
        { "fieldPath": "meetingId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "budgets",
      "queryScope": "Collection",
      "fields": [
        { "fieldPath": "organizationId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

---

## Google Cloud Functions Configuration (functions/.runtimeconfig.json)

```json
{
  "gemini": {
    "api_key": "your_gemini_api_key_here",
    "model": "gemini-2.0-pro",
    "max_tokens": 2048
  },
  "google": {
    "project_id": "kitahack-setiau-2026",
    "cloud_region": "us-central1"
  },
  "app": {
    "environment": "production",
    "timezone": "Asia/Kuala_Lumpur",
    "approval_required": true
  },
  "workspace": {
    "domain": "organization.com",
    "calendar_timezone": "Asia/Kuala_Lumpur"
  }
}
```

Deploy with:

```bash
firebase functions:config:set gemini.api_key="YOUR_KEY"
firebase functions:config:set google.project_id="YOUR_PROJECT_ID"
```

---

## Local Development Setup (.env.local)

```bash
# Development environment
FLUTTER_ENV=development
FIREBASE_EMULATOR_HOST=localhost:9099
FIRESTORE_EMULATOR_HOST=localhost:8080
FUNCTIONS_EMULATOR_HOST=localhost:5001

# Gemini API (get from https://aistudio.google.com/app/apikey)
GEMINI_API_KEY=your_development_api_key

# Firebase Dev Project
FIREBASE_PROJECT_ID=kitahack-setiau-dev

# Logging
LOG_LEVEL=debug
ENABLE_CONSOLE_LOGS=true
```

Load in Flutter:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  // ...
}
```

---

## Android Configuration (android/app/build.gradle.kts)

```kotlin
android {
    compileSdk 34

    defaultConfig {
        applicationId "com.setiau.app"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0.0"

        // Google Sign-In
        resValue "string", "google_app_id", "YOUR_GOOGLE_APP_ID"

        // Firebase
        manifestPlaceholders = [
            googlePlayServicesVersion: "21.0.1"
        ]
    }

}
```

Note: In this repo the Google Services Gradle plugin is applied via:

- `plugins { id("com.google.gms.google-services") }` in `android/app/build.gradle.kts`

You do **not** add `com.google.gms:google-services` as an `implementation` dependency.

---

## iOS Configuration (ios/Runner/Info.plist)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Google Sign-In -->
    <key>GIDClientID</key>
    <string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>

    <!-- Firebase -->
    <key>FirebaseAppID</key>
    <string>YOUR_FIREBASE_APP_ID</string>

    <!-- Microphone Permission -->
    <key>NSMicrophoneUsageDescription</key>
    <string>SetiaU needs microphone access to record meetings</string>

    <!-- Camera Permission (for future features) -->
    <key>NSCameraUsageDescription</key>
    <string>SetiaU needs camera access for video meetings</string>
</dict>
</plist>
```

---

## Production Deployment Commands

```bash
# Build and deploy Flutter app
flutter build apk --release
flutter build ios --release

# Deploy Cloud Functions to production
firebase deploy --only functions --project kitahack-setiau-2026

# Backup Firestore before major updates
gcloud firestore export gs://kitahack-setiau-2026-backups/backup-$(date +%Y%m%d-%H%M%S) \
  --project kitahack-setiau-2026

# Monitor functions
firebase functions:log --limit 100 --project kitahack-setiau-2026
```

---

## Testing Configuration (test/setUp.dart)

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void setupFirebaseEmulator() {
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseAuth.instance.tenantId = null;
}

void setupTestData(FirebaseFirestore firestore) {
  // Create test organization
  firestore.collection('organizations').doc('test-org-1').set({
    'name': 'Test Organization',
    'members': ['test-user-1', 'test-user-2'],
    'admin': 'test-user-1',
  });
}
```

---

**Configuration Examples v1.0**  
_KitaHack 2026 - SetiaU Setup_
