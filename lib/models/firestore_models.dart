import 'package:cloud_firestore/cloud_firestore.dart';

// Meeting Model
class Meeting {
  final String id;
  final String organizationId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> attendees;
  final String? transcriptUrl;
  final String status; // 'ongoing', 'completed', 'draft'
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  Meeting({
    required this.id,
    required this.organizationId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.attendees,
    this.transcriptUrl,
    this.status = 'draft',
    required this.createdAt,
    this.metadata = const {},
  });

  factory Meeting.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Meeting(
      id: doc.id,
      organizationId: data['organizationId'] ?? '',
      title: data['title'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      attendees: List<String>.from(data['attendees'] ?? []),
      transcriptUrl: data['transcriptUrl'],
      status: data['status'] ?? 'draft',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'organizationId': organizationId,
      'title': title,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'attendees': attendees,
      'transcriptUrl': transcriptUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }
}

// Task Model
class Task {
  final String id;
  final String meetingId;
  final String title;
  final String description;
  final String assignedTo;
  final DateTime dueDate;
  final String priority; // 'high', 'medium', 'low'
  final String status; // 'pending', 'approved', 'in_progress', 'completed', 'rejected'
  final String category; // 'meeting', 'budget', 'event', 'other'
  final DateTime createdAt;
  final String createdBy;
  final String? approvalNotes;

  Task({
    required this.id,
    required this.meetingId,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.dueDate,
    this.priority = 'medium',
    this.status = 'pending',
    this.category = 'other',
    required this.createdAt,
    required this.createdBy,
    this.approvalNotes,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      meetingId: data['meetingId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      priority: data['priority'] ?? 'medium',
      status: data['status'] ?? 'pending',
      category: data['category'] ?? 'other',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      approvalNotes: data['approvalNotes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'meetingId': meetingId,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': priority,
      'status': status,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'approvalNotes': approvalNotes,
    };
  }
}

// Action Model (Gemini-generated, awaiting approval)
class Action {
  final String id;
  final String taskId;
  final String meetingId;
  final String actionType; // 'calendar', 'email', 'docs', 'sheets', 'other'
  final Map<String, dynamic> payload; // Schema varies by actionType
  final String status; // 'pending', 'approved', 'executed', 'rejected'
  final DateTime createdAt;
  final String? approvedBy;
  final DateTime? approvalTime;
  final String? executionResult;
  final List<String> constraints; // Detected conflicts

  Action({
    required this.id,
    required this.taskId,
    required this.meetingId,
    required this.actionType,
    required this.payload,
    this.status = 'pending',
    required this.createdAt,
    this.approvedBy,
    this.approvalTime,
    this.executionResult,
    this.constraints = const [],
  });

  factory Action.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Action(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      meetingId: data['meetingId'] ?? '',
      actionType: data['actionType'] ?? 'other',
      payload: data['payload'] ?? {},
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      approvedBy: data['approvedBy'],
      approvalTime: data['approvalTime'] != null
          ? (data['approvalTime'] as Timestamp).toDate()
          : null,
      executionResult: data['executionResult'],
      constraints: List<String>.from(data['constraints'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'meetingId': meetingId,
      'actionType': actionType,
      'payload': payload,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedBy': approvedBy,
      'approvalTime':
          approvalTime != null ? Timestamp.fromDate(approvalTime!) : null,
      'executionResult': executionResult,
      'constraints': constraints,
    };
  }
}

// Budget Model
class Budget {
  final String id;
  final String organizationId;
  final String category;
  final double allocated;
  final double spent;
  final String currency; // 'MYR', 'USD', etc.
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  Budget({
    required this.id,
    required this.organizationId,
    required this.category,
    required this.allocated,
    this.spent = 0,
    this.currency = 'MYR',
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  double get remaining => allocated - spent;
  double get percentageUsed => (spent / allocated) * 100;

  factory Budget.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Budget(
      id: doc.id,
      organizationId: data['organizationId'] ?? '',
      category: data['category'] ?? '',
      allocated: (data['allocated'] as num).toDouble(),
      spent: (data['spent'] as num).toDouble(),
      currency: data['currency'] ?? 'MYR',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'organizationId': organizationId,
      'category': category,
      'allocated': allocated,
      'spent': spent,
      'currency': currency,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// Organization Model
class Organization {
  final String id;
  final String name;
  final String description;
  final List<String> members;
  final String admin;
  final DateTime createdAt;
  final Map<String, dynamic> settings;

  Organization({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.admin,
    required this.createdAt,
    this.settings = const {},
  });

  factory Organization.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Organization(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      admin: data['admin'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      settings: data['settings'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'members': members,
      'admin': admin,
      'createdAt': Timestamp.fromDate(createdAt),
      'settings': settings,
    };
  }
}
