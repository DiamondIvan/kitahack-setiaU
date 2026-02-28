# SetiaU Developer Quick Reference

Fast lookup guide for common development tasks and APIs in SetiaU.

---

## 🚀 Quick Start Commands

```bash
# Clone and setup
git clone <repo> kitahack-setiaU
cd kitahack-setiaU
flutter pub get

# Configure Firebase
flutterfire configure

# Run app
flutter run

# Required local config
# Create `.env` with GEMINI_API_KEY=... (see .env.example)

# Hot reload during development
r (in terminal while running)

# Deploy functions
firebase deploy --only functions

# View logs
firebase functions:log --limit 50
```

---

## 📁 File Structure Quick Reference

| File                 | Purpose                                      |
| -------------------- | -------------------------------------------- |
| `lib/main.dart`      | App entry point, routes                      |
| `lib/screens/`       | UI screens (login, home, meeting, dashboard) |
| `lib/services/`      | Business logic (auth, firestore, gemini)     |
| `lib/models/`        | Data models (Meeting, Task, Action, Budget)  |
| `lib/utils/`         | Utilities, helpers, mock data                |
| `functions/index.js` | Cloud Functions backend                      |
| `firebase.json`      | Firebase configuration                       |

---

## 🔑 Core Services

### AuthService

```dart
import 'package:kitahack_setiau/services/auth_service.dart';

final auth = AuthService();

// Sign in
await auth.signInWithGoogle();

// Get current user
final user = auth.currentUser;
final email = auth.getUserEmail();

// Sign out
await auth.signOut();

// Listen to auth changes
auth.authStateChanges.listen((user) {...});
```

### FirestoreService

```dart
import 'package:kitahack_setiau/services/firestore_service.dart';

final db = FirestoreService();

// Create
await db.createMeeting(meeting);
await db.createTask(task);
await db.createAction(action);

// Read
final meeting = await db.getMeeting(meetingId);
final tasks = await db.getTasksForMeeting(meetingId).first;

// Update
await db.updateTask(taskId, {'status': 'completed'});

// Approve action
await db.approveAction(actionId, userId);
```

### GeminiService

```dart
import 'package:kitahack_setiau/services/gemini_service.dart';

final gemini = GeminiService(apiKey: 'YOUR_KEY');

// Extract tasks from transcript
final tasks = await gemini.extractTasksFromTranscript(
  transcript,
  meetingId,
  userId,
);

// Detect constraints
final constraints = await gemini.detectConstraints(task, members, budgets);

// Propose alternative
final solution = await gemini.proposeAlternativeSolution(task, constraints);

// Generate action payload
final payload = await gemini.generateActionPayload(task, 'calendar');
```

---

## 🏗️ Data Models

### Meeting

```dart
Meeting(
  id: 'unique_id',
  organizationId: 'org_id',
  title: 'Meeting Title',
  startTime: DateTime.now(),
  endTime: DateTime.now().add(Duration(hours: 1)),
  attendees: ['Ali', 'Sarah'],
  transcriptUrl: 'gs://bucket/file.txt',
  status: 'draft', // or 'completed', 'ongoing'
  createdAt: DateTime.now(),
)
```

### Task

```dart
Task(
  id: 'unique_id',
  meetingId: 'meeting_id',
  title: 'Task Title',
  description: 'Full description',
  assignedTo: 'Ali',
  dueDate: DateTime(2026, 3, 15),
  priority: 'high', // 'high', 'medium', 'low'
  status: 'pending', // 'pending', 'approved', 'completed'
  category: 'event', // 'meeting', 'budget', 'event', 'other'
  createdAt: DateTime.now(),
  createdBy: 'user_id',
)
```

### Action

```dart
Action(
  id: 'unique_id',
  taskId: 'task_id',
  meetingId: 'meeting_id',
  actionType: 'calendar', // 'calendar', 'email', 'sheets', 'docs'
  payload: {
    'eventName': 'Event',
    'date': '2026-03-15',
    // ... type-specific fields
  },
  status: 'pending', // 'pending', 'approved', 'executed', 'rejected'
  createdAt: DateTime.now(),
  constraints: ['Constraint 1', 'Constraint 2'],
)
```

### Budget

```dart
Budget(
  id: 'unique_id',
  organizationId: 'org_id',
  category: 'Event Fund',
  allocated: 5000,
  spent: 1500,
  currency: 'MYR',
  startDate: DateTime(2026, 1, 1),
  endDate: DateTime(2026, 12, 31),
  createdAt: DateTime.now(),
)
```

---

## 🎨 Common UI Patterns

### Navigation

```dart
// Push new screen
Navigator.pushNamed(context, '/home');

// Replace navigation stack
Navigator.pushReplacementNamed(context, '/dashboard');

// Pop back
Navigator.pop(context);
```

### Show SnackBar

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Success message'),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 2),
  ),
);
```

### Permission Handling

```dart
// Request permission (example for microphone)
import 'package:permission_handler/permission_handler.dart';

final status = await Permission.microphone.request();
if (status.isGranted) {
  // Microphone permission granted
}
```

### Async Operations with Loading State

```dart
setState(() => isLoading = true);
try {
  final result = await someAsyncOperation();
  setState(() => data = result);
} catch (e) {
  print('Error: $e');
} finally {
  setState(() => isLoading = false);
}
```

---

## 📊 Firestore Query Patterns

### Get single document

```dart
final doc = await FirebaseFirestore.instance
    .collection('tasks')
    .doc(taskId)
    .get();
```

### Get filtered documents

```dart
final snapshot = await FirebaseFirestore.instance
    .collection('tasks')
    .where('meetingId', isEqualTo: meetingId)
    .where('status', isNotEqualTo: 'completed')
    .orderBy('dueDate')
    .limit(10)
    .get();
```

### Listen for real-time updates

```dart
FirebaseFirestore.instance
    .collection('actions')
    .where('status', isEqualTo: 'pending')
    .snapshots()
    .listen((snapshot) {
      final actions = snapshot.docs
          .map((doc) => Action.fromFirestore(doc))
          .toList();
    });
```

### Batch write operations

```dart
final batch = FirebaseFirestore.instance.batch();

batch.set(doc1Ref, data1);
batch.update(doc2Ref, data2);
batch.delete(doc3Ref);

await batch.commit();
```

---

## ☁️ Cloud Functions Patterns

### Call function from Flutter

```dart
final functions = FirebaseFunctions.instance;

final result = await functions
    .httpsCallable('executeCalendarAction')
    .call({
      'actionId': 'action_123',
      'payload': {
        'eventName': 'Meeting',
        'date': '2026-03-15',
      },
    });

print(result.data);
```

### Cloud Function template

```javascript
exports.myFunction = functions.https.onCall(async (data, context) => {
  // Verify auth
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated",
    );
  }

  try {
    // Process data
    const result = await processData(data);

    // Return result
    return { success: true, data: result };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});
```

---

## 🧪 Testing Quick Ref

### Run tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/models/firestore_models_test.dart

# Watch mode
flutter test --watch

# With coverage
flutter test --coverage
```

### Mock data for testing

```dart
import 'package:kitahack_setiau/utils/mock_data_generator.dart';

final task = MockDataGenerator.generateTask();
final tasks = MockDataGenerator.generateCharityRunTasks();
final scenario = MockDataGenerator.generateCompleteScenario();
```

### Firestore emulator

```bash
# Start emulator
firebase emulators:start

# Reset emulator
firebase emulators:start --import=./data --export-on-exit
```

---

## 🔐 Authentication

### Check if user is logged in

```dart
final user = FirebaseAuth.instance.currentUser;
if (user != null) {
  // User is logged in
  print('User: ${user.email}');
} else {
  // User not logged in
}
```

### Get auth token (for Cloud Functions)

```dart
final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
```

### Sign out

```dart
await FirebaseAuth.instance.signOut();
await GoogleSignIn().signOut();
```

---

## 🎯 State Management

### Using Provider (recommended for SetiaU)

```dart
// Define provider
final userProvider = StateNotifierProvider<User>((ref) {
  return FirebaseAuth.instance.currentUser;
});

// Use in widget
final user = ref.watch(userProvider);

// Update state
ref.read(userProvider.notifier).state = newUser;
```

### Using Stream

```dart
StreamBuilder<List<Task>>(
  stream: FirestoreService().getTasksForMeeting(meetingId),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }

    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }

    final tasks = snapshot.data ?? [];
    return ListView(children: tasks.map((task) => TaskTile(task)).toList());
  },
)
```

---

## 🐛 Debugging

### Print to console

```dart
print('Debug message');
debugPrint('Debug message');
```

### Inspect Firebase data

```dart
// In Firebase Console or CLI
firebase firestore:inspect
```

### Check app logs in Android Studio

```
View → Tool Windows → Logcat
```

### Enable Flutter verbose logging

```bash
flutter run -v
```

### Breakpoints in VS Code

- Click line number to set breakpoint
- Run → Start Debugging (F5)
- Step over (F10), Step into (F11)

---

## 📦 Useful Packages

| Package                | Purpose              |
| ---------------------- | -------------------- |
| `firebase_core`        | Initialize Firebase  |
| `firebase_auth`        | Authentication       |
| `cloud_firestore`      | Database             |
| `google_sign_in`       | Google auth          |
| `google_generative_ai` | Gemini API           |
| `record`               | Audio recording      |
| `speech_to_text`       | Speech recognition   |
| `provider`             | State management     |
| `uuid`                 | Generate unique IDs  |
| `intl`                 | Internationalization |

---

## 🚀 Performance Tips

1. **Optimize Firestore queries** - Use `.limit()`, `.orderBy()`, add indexes
2. **Lazy load images** - Use `cached_network_image`
3. **Batch operations** - Group Firestore writes with batch
4. **Debounce search** - Use `debounceTime` for search/filter
5. **Cache responses** - Avoid repeated API calls
6. **Use StreamBuilder wisely** - Can cause performance issues if not careful

---

## 📚 API Reference Links

- [Flutter Docs](https://flutter.dev/docs)
- [Firebase Docs](https://firebase.google.com/docs)
- [Gemini API](https://ai.google.dev/docs)
- [Google Workspace API](https://developers.google.com/workspace)
- [Dart API Reference](https://api.dart.dev)

---

## ❓ FAQ

**Q: How do I add a new screen?**
A: Create file in `lib/screens/`, create StatefulWidget, add route in `main.dart`

**Q: How do I add a new data model?**
A: Create class in `lib/models/firestore_models.dart`, add fromFirestore() and toFirestore() methods

**Q: Where do I store API keys?**
A: Use Firebase Remote Config, never hardcode in source

**Q: How do I test Firestore locally?**
A: Run `firebase emulators:start`, configure emulator in code

**Q: Can I use multiple screens in a test?**
A: Yes, use `Navigator` with named routes and `pumpAndSettle()`

---

**SetiaU Developer Quick Reference v1.0**
_KitaHack 2026 - The Agentic Secretary_
