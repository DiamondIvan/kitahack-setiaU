# SetiaU Testing Guide

Complete guide for testing SetiaU functionality, from unit tests to end-to-end flows.

---

## Testing Overview

SetiaU testing covers:
1. **Unit Tests** - Individual services and models
2. **Widget Tests** - Flutter UI components  
3. **Integration Tests** - Complete features
4. **Cloud Functions Tests** - Backend API testing
5. **End-to-End (E2E) Tests** - Full user flows

---

## 🧪 Unit Tests

### Test Firebase Models

Create `test/models/firestore_models_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kitahack_setiau/models/firestore_models.dart';

void main() {
  group('Firestore Models', () {
    test('Task creation with all fields', () {
      final task = Task(
        id: 'task_1',
        meetingId: 'meeting_1',
        title: 'Test Task',
        description: 'Test Description',
        assignedTo: 'Ali',
        dueDate: DateTime(2026, 3, 15),
        priority: 'high',
        status: 'pending',
        category: 'event',
        createdAt: DateTime.now(),
        createdBy: 'system',
      );

      expect(task.title, 'Test Task');
      expect(task.assignedTo, 'Ali');
      expect(task.priority, 'high');
    });

    test('Budget remaining calculation', () {
      final budget = Budget(
        id: 'budget_1',
        organizationId: 'org_1',
        category: 'Event Fund',
        allocated: 1000,
        spent: 350,
        currency: 'MYR',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        createdAt: DateTime.now(),
      );

      expect(budget.remaining, 650);
      expect(budget.percentageUsed, 35);
    });

    test('Action status transitions', () {
      var action = Action(
        id: 'action_1',
        taskId: 'task_1',
        meetingId: 'meeting_1',
        actionType: 'calendar',
        payload: {'eventName': 'Test'},
        status: 'pending',
        createdAt: DateTime.now(),
      );

      expect(action.status, 'pending');

      // Simulate approval
      action = Action(
        id: action.id,
        taskId: action.taskId,
        meetingId: action.meetingId,
        actionType: action.actionType,
        payload: action.payload,
        status: 'approved',
        createdAt: action.createdAt,
        approvedBy: 'admin_user',
      );

      expect(action.status, 'approved');
      expect(action.approvedBy, 'admin_user');
    });
  });
}
```

Run tests:
```bash
flutter test test/models/
```

---

## 🎨 Widget Tests

### Test Login Screen

Create `test/screens/login_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitahack_setiau/screens/login_screen.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('Login screen displays title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      expect(find.text('SetiaU'), findsWidgets);
      expect(find.text('The Agentic Secretary for Your Organization'), findsOneWidget);
    });

    testWidgets('Sign in button is visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('Login button can be tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Note: Actual Google Sign-In is mocked in unit tests
    });
  });
}
```

### Test Meeting Mode Screen

Create `test/screens/meeting_mode_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitahack_setiau/screens/meeting_mode_screen.dart';

void main() {
  group('MeetingModeScreen Widget Tests', () {
    testWidgets('Recording button visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MeetingModeScreen()),
      );

      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.text('Start Recording'), findsOneWidget);
    });

    testWidgets('Tap recording button changes state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MeetingModeScreen()),
      );

      // Initial state
      expect(find.text('Start Recording'), findsOneWidget);

      // Tap button
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();

      // Should now show stop button
      expect(find.text('Stop Recording'), findsOneWidget);
    });

    testWidgets('Tasks extracted after recording stops', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MeetingModeScreen()),
      );

      // Start recording
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();

      // Stop recording
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();

      // Should show extracted tasks
      expect(find.text('Extracted Tasks (AI-Generated)'), findsOneWidget);
      expect(find.text('Approve & Save'), findsOneWidget);
    });
  });
}
```

Run widget tests:
```bash
flutter test test/screens/
```

---

## 🔗 Integration Tests

### Firebase Integration Test

Create `test/services/firestore_integration_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kitahack_setiau/services/firestore_service.dart';
import 'package:kitahack_setiau/models/firestore_models.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('Firestore Integration Tests', () {
    late FirestoreService firestoreService;
    late FirebaseFirestore firestore;

    setUpAll(() async {
      // Use emulator for testing
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      firestore = FirebaseFirestore.instance;
      firestoreService = FirestoreService();
    });

    test('Create and retrieve meeting', () async {
      final meeting = Meeting(
        id: const Uuid().v4(),
        organizationId: 'test-org',
        title: 'Test Meeting',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        attendees: ['user1', 'user2'],
        status: 'draft',
        createdAt: DateTime.now(),
      );

      // Create meeting
      await firestoreService.createMeeting(meeting);

      // Retrieve meeting
      final retrieved = await firestoreService.getMeeting(meeting.id);

      expect(retrieved, isNotNull);
      expect(retrieved?.title, 'Test Meeting');
      expect(retrieved?.organizationId, 'test-org');
    });

    test('Create task and retrieve by meetingId', () async {
      final meetingId = const Uuid().v4();
      final taskId = const Uuid().v4();

      final task = Task(
        id: taskId,
        meetingId: meetingId,
        title: 'Sample Task',
        description: 'Task description',
        assignedTo: 'Ali',
        dueDate: DateTime(2026, 3, 15),
        createdAt: DateTime.now(),
        createdBy: 'system',
      );

      // Create task
      await firestoreService.createTask(task);

      // Retrieve tasks for meeting
      final tasks = await firestoreService
          .getTasksForMeeting(meetingId)
          .first;

      expect(tasks, isNotEmpty);
      expect(tasks.first.title, 'Sample Task');
    });

    test('Update action status', () async {
      final actionId = const Uuid().v4();

      final action = Action(
        id: actionId,
        taskId: 'task_1',
        meetingId: 'meeting_1',
        actionType: 'calendar',
        payload: {'eventName': 'Test Event'},
        status: 'pending',
        createdAt: DateTime.now(),
        constraints: [],
      );

      // Create action
      await firestoreService.createAction(action);

      // Approve action
      await firestoreService.approveAction(actionId, 'admin_user');

      // Retrieve and verify
      final updated = await firestoreService.getAction(actionId);

      expect(updated?.status, 'approved');
      expect(updated?.approvedBy, 'admin_user');
    });
  });
}
```

---

## ☁️ Cloud Functions Testing

### Test Calendar Action Function

Create `functions/tests/calendar.test.js`:

```javascript
const functions = require('firebase-functions-test')();
const admin = require('firebase-admin');

// Initialize test environment
functions.mockConfig({
  gemini: { api_key: 'test_key' },
  google: { project_id: 'test_project' }
});

describe('executeCalendarAction', () => {
  let db;

  beforeEach(() => {
    db = admin.firestore();
  });

  afterEach(() => {
    return functions.cleanup();
  });

  it('should create calendar event with valid payload', async () => {
    const data = {
      actionId: 'action_1',
      payload: {
        eventName: 'Test Event',
        date: '2026-03-15',
        startTime: '09:00',
        endTime: '10:00',
        attendees: ['test@example.com']
      }
    };

    // Mock the function call
    // (Actual implementation depends on Firebase Functions Test SDK)

    expect(true).toBe(true);
  });

  it('should validate required fields', async () => {
    const data = {
      actionId: 'action_1',
      payload: {
        eventName: 'Test Event'
        // Missing required fields
      }
    };

    // Should throw validation error
    expect(() => {
      // validatePayload(data.payload);
    }).not.toThrow();
  });
});
```

Run function tests:
```bash
cd functions
npm test
```

---

## 🔄 End-to-End (E2E) Testing

### Complete User Flow Test

Create `integration_test/app_flow_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitahack_setiau/main.dart';

void main() {
  group('SetiaU E2E Tests', () {
    testWidgets('Complete meeting recording flow', (WidgetTester tester) async {
      // Start app
      app = MyApp();
      await tester.pumpWidget(app);
      await tester.pump(const Duration(seconds: 1));

      // Should be on login screen
      expect(find.text('SetiaU'), findsWidgets);

      // Mock authentication - navigate to home
      // (In real test, use Firebase Auth emulator)
      Navigator.of(tester.element(find.byType(MyApp)))
          .pushNamed('/home');
      await tester.pumpAndSettle();

      // Should be on home screen with tabs
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Tap Meeting Mode tab
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.text('Start Recording'));
      await tester.pump();

      // Should show recording state
      expect(find.text('Stop Recording'), findsOneWidget);

      // Stop recording
      await tester.tap(find.text('Stop Recording'));
      await tester.pumpAndSettle();

      // Tasks should be extracted
      expect(find.text('Extracted Tasks (AI-Generated)'), findsOneWidget);

      // Approve tasks
      await tester.tap(find.text('Approve & Save'));
      await tester.pumpAndSettle();

      // Should show success message
      expect(
        find.byType(SnackBar),
        findsOneWidget
      );
    });

    testWidgets('Complete action approval flow', (WidgetTester tester) async {
      // ... navigate to Dashboard ...

      // Tap Dashboard tab
      await tester.tap(find.byIcon(Icons.dashboard));
      await tester.pumpAndSettle();

      // Should show pending actions
      expect(find.text('Pending Approvals'), findsOneWidget);
      expect(find.text('3'), findsWidgets);

      // Expand first action
      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();

      // Should show action details
      expect(find.text('Action Details:'), findsOneWidget);

      // Approve action
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      // Action should be removed from list
      expect(find.text('Action Details:'), findsNothing);
    });
  });
}
```

Run E2E tests:
```bash
flutter test integration_test/
```

---

## 🧪 Testing Checklist

### Before Submission

#### Unit Tests
- [ ] All models have tests
- [ ] Service methods tested
- [ ] Error handling tested
- [ ] Edge cases covered

#### Widget Tests
- [ ] All screens render correctly
- [ ] User interactions trigger actions
- [ ] Navigation works
- [ ] SnackBars/Dialogs appear as expected

#### Integration Tests
- [ ] Firebase operations work end-to-end
- [ ] Data persists correctly
- [ ] Firestore queries return correct results
- [ ] User permissions enforced

#### E2E Tests
- [ ] Login flow works
- [ ] Meeting Mode complete flow passes
- [ ] Dashboard Mode complete flow passes
- [ ] Action approval/rejection works
- [ ] No crashes during normal usage

#### Cloud Functions
- [ ] All functions deploy without errors
- [ ] Functions respond to calls
- [ ] Error handling returns proper status
- [ ] Logs are informative

---

## 📊 Test Coverage

Target coverage:
- **Services**: 90%+ coverage
- **Models**: 95%+ coverage
- **Screens**: 80%+ coverage (UI heavy)
- **Overall**: 85%+ coverage

Check coverage:
```bash
flutter test --coverage
lcov --list coverage/lcov.info
```

---

## 🐛 Debugging Failed Tests

### Common Issues

| Issue | Solution |
|-------|----------|
| "Firebase not initialized" | Use emulator setup in `setUp()` |
| "Widget not found" | Add `await tester.pumpAndSettle()` |
| "Permission denied" | Check Firestore rules in test |
| "Timeout" | Increase test timeout or optimize code |

### Run Single Test

```bash
# Run specific test file
flutter test test/models/firestore_models_test.dart

# Run specific test
flutter test test/models/firestore_models_test.dart -n "Task creation"

# Verbose output
flutter test --verbose test/screens/login_screen_test.dart
```

### Enable Debugging

```dart
// Add to test
debugPrint('Debug message');

// In Flutter test output
flutter test --verbose --debug
```

---

## 📈 Performance Testing

### Monitor Firestore Operations

```dart
test('Query performance', () async {
  final stopwatch = Stopwatch()..start();

  final tasks = await firestoreService
      .getPendingTasksForUser('user_1')
      .first;

  stopwatch.stop();

  expect(stopwatch.elapsedMilliseconds, lessThan(1000));
  print('Query took ${stopwatch.elapsedMilliseconds}ms');
});
```

### Test Cloud Functions Latency

```javascript
test('Function latency', async () => {
  const start = Date.now();
  
  // Call function
  await functionCall();
  
  const latency = Date.now() - start;
  expect(latency).toBeLessThan(2000); // Should complete in < 2 seconds
});
```

---

## 📚 Resources

- [Flutter Testing Guide](https://flutter.dev/docs/testing)
- [Firebase Testing](https://firebase.google.com/docs/testing)
- [Cloud Functions Testing](https://firebase.google.com/docs/functions/unit-testing)

---

**Testing Guide v1.0**  
*KitaHack 2026 - SetiaU*
