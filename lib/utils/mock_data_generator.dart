import 'package:kitahack_setiau/models/firestore_models.dart';
import 'package:uuid/uuid.dart' as uuid;

/// Mock data generator for testing SetiaU functionality
/// Used in development, widget tests, and integration tests
class MockDataGenerator {
  static const _uuid = uuid.Uuid();

  /// Generate mock meeting
  static Meeting generateMeeting({
    String? id,
    String organizationId = 'org_001',
    String title = 'Team Meeting',
    DateTime? startTime,
    DateTime? endTime,
    List<String>? attendees,
  }) {
    final now = DateTime.now();
    return Meeting(
      id: id ?? _uuid.v4(),
      organizationId: organizationId,
      title: title,
      startTime: startTime ?? now,
      endTime: endTime ?? now.add(const Duration(hours: 1)),
      attendees: attendees ?? ['Ali', 'Sarah', 'John'],
      status: 'draft',
      createdAt: now,
      metadata: {
        'location': 'Virtual',
        'meetingType': 'sync',
      },
    );
  }

  /// Generate mock task
  static Task generateTask({
    String? id,
    String meetingId = 'meeting_001',
    String title = 'Sample Task',
    String description = 'Task description',
    String assignedTo = 'Ali',
    DateTime? dueDate,
    String priority = 'medium',
    String status = 'pending',
    String category = 'event',
  }) {
    final now = DateTime.now();
    return Task(
      id: id ?? _uuid.v4(),
      meetingId: meetingId,
      title: title,
      description: description,
      assignedTo: assignedTo,
      dueDate: dueDate ?? now.add(const Duration(days: 7)),
      priority: priority,
      status: status,
      category: category,
      createdAt: now,
      createdBy: 'system',
    );
  }

  /// Generate mock action
  static Action generateAction({
    String? id,
    String taskId = 'task_001',
    String meetingId = 'meeting_001',
    String actionType = 'calendar',
    Map<String, dynamic>? payload,
    String status = 'pending',
    List<String>? constraints,
  }) {
    final now = DateTime.now();
    
    final defaultPayload = _getDefaultPayload(actionType);
    
    return Action(
      id: id ?? _uuid.v4(),
      taskId: taskId,
      meetingId: meetingId,
      actionType: actionType,
      payload: payload ?? defaultPayload,
      status: status,
      createdAt: now,
      constraints: constraints ?? [],
    );
  }

  /// Generate mock budget
  static Budget generateBudget({
    String? id,
    String organizationId = 'org_001',
    String category = 'Event Fund',
    double allocated = 5000,
    double spent = 1500,
    String currency = 'MYR',
  }) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, 1, 1);
    final endDate = DateTime(now.year, 12, 31);

    return Budget(
      id: id ?? _uuid.v4(),
      organizationId: organizationId,
      category: category,
      allocated: allocated,
      spent: spent,
      currency: currency,
      startDate: startDate,
      endDate: endDate,
      createdAt: now,
    );
  }

  /// Generate mock organization
  static Organization generateOrganization({
    String? id,
    String name = 'Test Organization',
    String description = 'A test organization',
    List<String>? members,
    String admin = 'admin_user',
  }) {
    return Organization(
      id: id ?? _uuid.v4(),
      name: name,
      description: description,
      members: members ?? ['admin_user', 'Ali', 'Sarah', 'John'],
      admin: admin,
      createdAt: DateTime.now(),
      settings: {
        'timezone': 'Asia/Kuala_Lumpur',
        'language': 'en',
        'requiresApproval': true,
      },
    );
  }

  /// Generate list of mock tasks (charity run scenario)
  static List<Task> generateCharityRunTasks({
    String meetingId = 'meeting_charity_001',
  }) {
    final now = DateTime.now();
    final marchDate = DateTime(2026, 3, 13);

    return [
      Task(
        id: _uuid.v4(),
        meetingId: meetingId,
        title: 'Plan Charity Run Event',
        description: 'Organize charity run on March 13, 2026',
        assignedTo: 'Ali',
        dueDate: marchDate,
        priority: 'high',
        status: 'pending',
        category: 'event',
        createdAt: now,
        createdBy: 'system',
      ),
      Task(
        id: _uuid.v4(),
        meetingId: meetingId,
        title: 'Design Event Poster',
        description: 'Create promotional poster for the charity run',
        assignedTo: 'Sarah',
        dueDate: DateTime(2026, 3, 6),
        priority: 'high',
        status: 'pending',
        category: 'event',
        createdAt: now,
        createdBy: 'system',
      ),
      Task(
        id: _uuid.v4(),
        meetingId: meetingId,
        title: 'Manage Water Supplies',
        description: 'Source and manage water for the charity run',
        assignedTo: 'Ali',
        dueDate: marchDate,
        priority: 'medium',
        status: 'pending',
        category: 'event',
        createdAt: now,
        createdBy: 'system',
      ),
    ];
  }

  /// Generate list of mock actions (charity run scenario)
  static List<Action> generateCharityRunActions({
    String meetingId = 'meeting_charity_001',
  }) {
    final now = DateTime.now();

    return [
      Action(
        id: _uuid.v4(),
        taskId: 'task_plan_001',
        meetingId: meetingId,
        actionType: 'calendar',
        payload: {
          'eventName': 'Charity Run - Updated',
          'date': '2026-03-13',
          'startTime': '09:00',
          'endTime': '12:00',
          'attendees': ['Ali', 'Sarah', 'John'],
          'description': 'Charity run to support education',
        },
        status: 'pending',
        createdAt: now,
        constraints: [
          'Date conflict: Original date (March 12) is Sunday. Multiple members unavailable.',
          'Constraint: Need 48 hours notice for venue booking.',
        ],
      ),
      Action(
        id: _uuid.v4(),
        taskId: 'task_email_001',
        meetingId: meetingId,
        actionType: 'email',
        payload: {
          'to': 'team@organization.com',
          'subject': 'Charity Run - Saturday March 13',
          'body': '''Dear Team,

The charity run has been scheduled for Saturday, March 13, 2026 at 09:00 AM.

Key Details:
- Date: Saturday, March 13, 2026
- Time: 09:00 AM - 12:00 PM
- Organizer: Ali
- Poster Design: Sarah (due March 6)

Please confirm your attendance.

Thank you,
SetiaU Secretary''',
        },
        status: 'pending',
        createdAt: now,
        constraints: [],
      ),
      Action(
        id: _uuid.v4(),
        taskId: 'task_budget_001',
        meetingId: meetingId,
        actionType: 'sheets',
        payload: {
          'sheetName': 'Event Budget',
          'action': 'update',
          'category': 'Water Supplies',
          'amount': 100.0,
          'currency': 'MYR',
          'reason': 'Increase water budget allocation',
        },
        status: 'pending',
        createdAt: now,
        constraints: [
          'Budget Warning: This purchase would use 85% of water supplies budget.',
          'Current: RM 400/500',
          'Proposed: RM 500/500',
        ],
      ),
    ];
  }

  /// Get default payload based on action type
  static Map<String, dynamic> _getDefaultPayload(String actionType) {
    switch (actionType) {
      case 'calendar':
        return {
          'eventName': 'New Event',
          'date': '2026-03-15',
          'startTime': '10:00 AM',
          'endTime': '11:00 AM',
          'attendees': [],
          'description': 'Meeting agenda',
        };
      case 'email':
        return {
          'to': 'recipient@example.com',
          'subject': 'Meeting Summary',
          'body': 'Here is the meeting summary...',
          'cc': [],
        };
      case 'sheets':
        return {
          'sheetName': 'Data Sheet',
          'action': 'append',
          'data': {
            'row': 1,
            'values': ['Value1', 'Value2', 'Value3'],
          },
        };
      case 'docs':
        return {
          'documentName': 'New Document',
          'content': 'Document content goes here.',
          'sharing': [],
        };
      default:
        return {};
    }
  }

  /// Generate complete mock scenario with organization, meeting, tasks, actions
  static Map<String, dynamic> generateCompleteScenario({
    String organizationName = 'Test Organization',
    String meetingTitle = 'Weekly Planning',
  }) {
    final org = generateOrganization(name: organizationName);
    final meeting = generateMeeting(
      organizationId: org.id,
      title: meetingTitle,
    );
    final tasks = generateCharityRunTasks(meetingId: meeting.id);
    final actions = generateCharityRunActions(meetingId: meeting.id);

    return {
      'organization': org,
      'meeting': meeting,
      'tasks': tasks,
      'actions': actions,
    };
  }

  /// Generate mock meeting transcript for testing AI extraction
  static String generateMockTranscript() {
    return '''
Sarah: "Thanks everyone for joining. Let's discuss the upcoming charity run."

Ali: "I think we should plan the charity run for March. How about March 12?"

John: "March 12... that's a Sunday, right? I won't be available that day."

Sarah: "He's right. Sundays are usually low attendance. Let's move to Saturday, March 13."

Ali: "That works for me. Sarah, can you handle the poster design?"

Sarah: "Sure, I'll design the poster. I need about a week, so I'll have it ready by March 6."

Ali: "Great. And I'll handle the water supplies for the run. We'll need a decent budget for that."

John: "How much are we allocating for water?"

Ali: "Current budget is RM 500. But I think we should increase it to RM 600 to be safe."

Sarah: "That's a good increase. Let's go with that."

Ali: "Perfect. I'll also send out invitations once Sarah has the poster ready."

John: "Should I help with organizing the route?"

Ali: "Yes please. Can you handle that?"

John: "No problem. I'll map out a 5km route."

Sarah: "Excellent. So to summarize: Charity run on March 13, poster by March 6, water budget RM 600, route planning by John."

Ali: "And I'll coordinate everything and send out the final invitations."
    ''';
  }
}
