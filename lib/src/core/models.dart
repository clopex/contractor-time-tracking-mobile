class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final String id;
  final String fullName;
  final String email;
}

class OrganizationModel {
  const OrganizationModel({
    required this.id,
    required this.name,
    required this.timezone,
  });

  final String id;
  final String name;
  final String timezone;

  factory OrganizationModel.fromMap(Map<String, dynamic> map) {
    return OrganizationModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Workspace',
      timezone: map['timezone'] as String? ?? 'UTC',
    );
  }
}

class MembershipModel {
  const MembershipModel({
    required this.role,
    required this.hourlyRateCents,
  });

  final String role;
  final int hourlyRateCents;

  factory MembershipModel.fromMap(Map<String, dynamic> map) {
    return MembershipModel(
      role: map['role'] as String? ?? 'contractor',
      hourlyRateCents: (map['hourly_rate_cents'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.name,
    required this.clientName,
    required this.code,
    required this.status,
    required this.budgetCents,
  });

  final String id;
  final String name;
  final String clientName;
  final String? code;
  final String status;
  final int? budgetCents;
}

class TaskModel {
  const TaskModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.isBillable,
  });

  final String id;
  final String projectId;
  final String name;
  final bool isBillable;

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      name: map['name'] as String? ?? 'Task',
      isBillable: map['is_billable'] as bool? ?? true,
    );
  }
}

class WorkSessionModel {
  const WorkSessionModel({
    required this.id,
    required this.projectId,
    required this.taskId,
    required this.note,
    required this.billable,
    required this.startedAt,
  });

  final String id;
  final String projectId;
  final String? taskId;
  final String? note;
  final bool billable;
  final DateTime startedAt;

  Duration elapsedAt(DateTime now) => now.toUtc().difference(startedAt.toUtc());

  factory WorkSessionModel.fromMap(Map<String, dynamic> map) {
    return WorkSessionModel(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      taskId: map['task_id'] as String?,
      note: map['note'] as String?,
      billable: map['billable'] as bool? ?? true,
      startedAt: DateTime.parse(map['started_at'] as String),
    );
  }
}

class TimesheetModel {
  const TimesheetModel({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.status,
    required this.rejectionReason,
  });

  final String id;
  final DateTime weekStart;
  final DateTime weekEnd;
  final String status;
  final String? rejectionReason;

  factory TimesheetModel.fromMap(Map<String, dynamic> map) {
    return TimesheetModel(
      id: map['id'] as String,
      weekStart: DateTime.parse(map['week_start'] as String),
      weekEnd: DateTime.parse(map['week_end'] as String),
      status: map['status'] as String? ?? 'draft',
      rejectionReason: map['rejection_reason'] as String?,
    );
  }
}

class TimeEntryModel {
  const TimeEntryModel({
    required this.id,
    required this.projectId,
    required this.taskId,
    required this.note,
    required this.minutes,
    required this.status,
    required this.billable,
    required this.startedAt,
    required this.endedAt,
  });

  final String id;
  final String projectId;
  final String? taskId;
  final String? note;
  final int minutes;
  final String status;
  final bool billable;
  final DateTime startedAt;
  final DateTime endedAt;

  double get hours => minutes / 60;

  factory TimeEntryModel.fromMap(Map<String, dynamic> map) {
    return TimeEntryModel(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      taskId: map['task_id'] as String?,
      note: map['note'] as String?,
      minutes: (map['minutes'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'draft',
      billable: map['billable'] as bool? ?? true,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: DateTime.parse(map['ended_at'] as String),
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.activeProjects,
    required this.submittedTimesheets,
    required this.approvedTimesheets,
    required this.totalHours,
    required this.billableHours,
  });

  final int activeProjects;
  final int submittedTimesheets;
  final int approvedTimesheets;
  final double totalHours;
  final double billableHours;

  factory DashboardSummary.empty() {
    return const DashboardSummary(
      activeProjects: 0,
      submittedTimesheets: 0,
      approvedTimesheets: 0,
      totalHours: 0,
      billableHours: 0,
    );
  }

  factory DashboardSummary.fromMap(Map<String, dynamic> map) {
    return DashboardSummary(
      activeProjects: (map['active_projects'] as num?)?.toInt() ?? 0,
      submittedTimesheets: (map['submitted_timesheets'] as num?)?.toInt() ?? 0,
      approvedTimesheets: (map['approved_timesheets'] as num?)?.toInt() ?? 0,
      totalHours: (map['total_hours'] as num?)?.toDouble() ?? 0,
      billableHours: (map['billable_hours'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AssistantActionModel {
  const AssistantActionModel({
    required this.type,
    required this.label,
    required this.payload,
  });

  final String type;
  final String label;
  final Map<String, dynamic> payload;

  factory AssistantActionModel.fromMap(Map<String, dynamic> map) {
    return AssistantActionModel(
      type: map['type'] as String? ?? 'note',
      label: map['label'] as String? ?? 'Suggestion',
      payload: Map<String, dynamic>.from(map['payload'] as Map? ?? const {}),
    );
  }
}

class AssistantReplyModel {
  const AssistantReplyModel({
    required this.reply,
    required this.actions,
  });

  final String reply;
  final List<AssistantActionModel> actions;

  factory AssistantReplyModel.fromMap(Map<String, dynamic> map) {
    final actions = (map['suggested_actions'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => AssistantActionModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    return AssistantReplyModel(
      reply: map['reply'] as String? ?? 'No reply generated.',
      actions: actions,
    );
  }
}

class WeekBundle {
  const WeekBundle({
    required this.timesheet,
    required this.entries,
  });

  final TimesheetModel? timesheet;
  final List<TimeEntryModel> entries;
}

class TaskSelection {
  const TaskSelection({
    required this.projectId,
    this.taskId,
  });

  final String projectId;
  final String? taskId;
}
