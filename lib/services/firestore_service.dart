import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kitahack_setiau/models/firestore_models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createMeetingAndTasks(Meeting meeting, List<Task> tasks) async {
    final batch = _db.batch();
    batch.set(
      _db.collection('meetings').doc(meeting.id),
      meeting.toFirestore(),
    );
    for (final task in tasks) {
      batch.set(_db.collection('tasks').doc(task.id), task.toFirestore());
    }
    await batch.commit().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException(
        'Firestore save timed out after 30 seconds. '
        'Check your internet connection and try again.',
      ),
    );
  }

  // Meetings Collection
  Future<void> createMeeting(Meeting meeting) async {
    await _db.collection('meetings').doc(meeting.id).set(meeting.toFirestore());
  }

  Future<Meeting?> getMeeting(String meetingId) async {
    final doc = await _db.collection('meetings').doc(meetingId).get();
    return doc.exists ? Meeting.fromFirestore(doc) : null;
  }

  Stream<List<Meeting>> getMeetingsForOrganization(String organizationId) {
    return _db
        .collection('meetings')
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Meeting.fromFirestore(doc)).toList(),
        );
  }

  Future<void> updateMeeting(
    String meetingId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('meetings').doc(meetingId).update(data);
  }

  // Tasks Collection
  Future<void> createTask(Task task) async {
    await _db.collection('tasks').doc(task.id).set(task.toFirestore());
  }

  Future<Task?> getTask(String taskId) async {
    final doc = await _db.collection('tasks').doc(taskId).get();
    return doc.exists ? Task.fromFirestore(doc) : null;
  }

  Stream<List<Task>> getTasksForMeeting(String meetingId) {
    return _db
        .collection('tasks')
        .where('meetingId', isEqualTo: meetingId)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Task>> getPendingTasksForUser(String userId) {
    return _db
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .where('status', isNotEqualTo: 'completed')
        .orderBy('status')
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList(),
        );
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    await _db.collection('tasks').doc(taskId).update(data);
  }

  // Actions Collection
  Future<void> createAction(Action action) async {
    await _db.collection('actions').doc(action.id).set(action.toFirestore());
  }

  Future<Action?> getAction(String actionId) async {
    final doc = await _db.collection('actions').doc(actionId).get();
    return doc.exists ? Action.fromFirestore(doc) : null;
  }

  Stream<List<Action>> getPendingActionsForMeeting(String meetingId) {
    return _db
        .collection('actions')
        .where('meetingId', isEqualTo: meetingId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Action.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Action>> getAllPendingActions(String organizationId) {
    return _db
        .collection('actions')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Action.fromFirestore(doc)).toList();
        });
  }

  Future<void> approveAction(String actionId, String approvedBy) async {
    await _db.collection('actions').doc(actionId).update({
      'status': 'approved',
      'approvedBy': approvedBy,
      'approvalTime': Timestamp.now(),
    });
  }

  Future<void> rejectAction(String actionId, String rejectionReason) async {
    await _db.collection('actions').doc(actionId).update({
      'status': 'rejected',
      'executionResult': rejectionReason,
    });
  }

  Future<void> executeAction(String actionId, String result) async {
    await _db.collection('actions').doc(actionId).update({
      'status': 'executed',
      'executionResult': result,
    });
  }

  // Budgets Collection
  Future<void> createBudget(Budget budget) async {
    await _db.collection('budgets').doc(budget.id).set(budget.toFirestore());
  }

  Future<Budget?> getBudget(String budgetId) async {
    final doc = await _db.collection('budgets').doc(budgetId).get();
    return doc.exists ? Budget.fromFirestore(doc) : null;
  }

  Stream<List<Budget>> getBudgetsForOrganization(String organizationId) {
    return _db
        .collection('budgets')
        .where('organizationId', isEqualTo: organizationId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Budget.fromFirestore(doc)).toList(),
        );
  }

  Future<void> updateBudget(String budgetId, Map<String, dynamic> data) async {
    await _db.collection('budgets').doc(budgetId).update(data);
  }

  // Organizations Collection
  Future<void> createOrganization(Organization organization) async {
    await _db
        .collection('organizations')
        .doc(organization.id)
        .set(organization.toFirestore());
  }

  Future<Organization?> getOrganization(String organizationId) async {
    final doc = await _db.collection('organizations').doc(organizationId).get();
    return doc.exists ? Organization.fromFirestore(doc) : null;
  }

  Stream<List<Organization>> getOrganizationsForUser(String userId) {
    return _db
        .collection('organizations')
        .where('members', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Organization.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> updateOrganization(
    String organizationId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('organizations').doc(organizationId).update(data);
  }

  Future<void> addMemberToOrganization(
    String organizationId,
    String userId,
  ) async {
    await _db.collection('organizations').doc(organizationId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }
}
