import 'dart:convert';

import 'package:contractor_mobile/src/core/app_config.dart';
import 'package:contractor_mobile/src/core/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final mobileRepositoryProvider = Provider<MobileRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {
    client = null;
  }
  return MobileRepository(
    config: config,
    client: client,
  );
});

class MobileRepository {
  MobileRepository({
    required this.config,
    required this.client,
  });

  final AppConfig config;
  final SupabaseClient? client;

  String get organizationId => config.defaultOrganizationId;

  Future<UserProfileModel?> fetchProfile() async {
    final supabase = _requireClient();
    final session = _requireSession();
    final response = await supabase
        .from('user_profiles')
        .select('id, full_name, email')
        .eq('id', session.user.id)
        .maybeSingle();

    if (response == null) {
      final metadata = session.user.userMetadata ?? const {};
      return UserProfileModel(
        id: session.user.id,
        fullName: metadata['full_name'] as String? ?? session.user.email?.split('@').first ?? 'Crew member',
        email: session.user.email ?? '',
      );
    }

    return UserProfileModel(
      id: response['id'] as String,
      fullName: response['full_name'] as String? ?? session.user.email ?? 'Crew member',
      email: response['email'] as String? ?? session.user.email ?? '',
    );
  }

  Future<OrganizationModel?> fetchOrganization() async {
    final supabase = _requireClient();
    final response = await supabase
        .from('organizations')
        .select('id, name, timezone')
        .eq('id', organizationId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return OrganizationModel.fromMap(response);
  }

  Future<MembershipModel?> fetchMembership() async {
    final supabase = _requireClient();
    final session = _requireSession();
    final response = await supabase
        .from('memberships')
        .select('role, hourly_rate_cents')
        .eq('organization_id', organizationId)
        .eq('user_id', session.user.id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return MembershipModel.fromMap(response);
  }

  Future<List<ProjectModel>> fetchProjects() async {
    final supabase = _requireClient();
    final response = await supabase
        .from('projects')
        .select('id, name, code, status, budget_cents, client_id')
        .eq('organization_id', organizationId)
        .order('created_at');

    final rows = List<Map<String, dynamic>>.from(response as List);
    final clientIds = rows
        .map((item) => item['client_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    Map<String, String> clientNames = const {};
    if (clientIds.isNotEmpty) {
      final clientsResponse = await supabase
          .from('clients')
          .select('id, name')
          .inFilter('id', clientIds);
      clientNames = {
        for (final row in List<Map<String, dynamic>>.from(clientsResponse as List))
          row['id'] as String: row['name'] as String? ?? 'Client',
      };
    }

    return rows
        .map(
          (row) => ProjectModel(
            id: row['id'] as String,
            name: row['name'] as String? ?? 'Project',
            clientName: clientNames[row['client_id'] as String?] ?? 'Unassigned client',
            code: row['code'] as String?,
            status: row['status'] as String? ?? 'active',
            budgetCents: (row['budget_cents'] as num?)?.toInt(),
          ),
        )
        .toList();
  }

  Future<List<TaskModel>> fetchTasks() async {
    final supabase = _requireClient();
    final response = await supabase
        .from('tasks')
        .select('id, project_id, name, is_billable')
        .eq('organization_id', organizationId)
        .order('created_at');

    return List<Map<String, dynamic>>.from(response as List)
        .map(TaskModel.fromMap)
        .toList();
  }

  Future<DashboardSummary> fetchSummary() async {
    final token = _requireAccessToken();
    final uri = Uri.parse(
      '${config.supabaseUrl}/functions/v1/reports-summary?organization_id=$organizationId',
    );

    final response = await http.get(uri, headers: _headers(token));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(body['error'] ?? 'Failed to load summary.');
    }

    return DashboardSummary.fromMap(body);
  }

  Future<WorkSessionModel?> fetchActiveSession() async {
    final supabase = _requireClient();
    final session = _requireSession();
    final response = await supabase
        .from('work_sessions')
        .select('id, project_id, task_id, note, billable, started_at')
        .eq('organization_id', organizationId)
        .eq('user_id', session.user.id)
        .isFilter('ended_at', null)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return WorkSessionModel.fromMap(response);
  }

  Future<WeekBundle> fetchCurrentWeekBundle() async {
    final supabase = _requireClient();
    final session = _requireSession();
    final weekStart = _startOfWeek(DateTime.now());
    final weekEndExclusive = weekStart.add(const Duration(days: 7));
    final weekStartKey = DateFormat('yyyy-MM-dd').format(weekStart);

    final timesheetResponse = await supabase
        .from('timesheets')
        .select('id, week_start, week_end, status, rejection_reason')
        .eq('organization_id', organizationId)
        .eq('user_id', session.user.id)
        .eq('week_start', weekStartKey)
        .maybeSingle();

    final entriesResponse = await supabase
        .from('time_entries')
        .select('id, project_id, task_id, note, minutes, status, billable, started_at, ended_at')
        .eq('organization_id', organizationId)
        .eq('user_id', session.user.id)
        .gte('started_at', weekStart.toUtc().toIso8601String())
        .lt('started_at', weekEndExclusive.toUtc().toIso8601String())
        .order('started_at', ascending: false);

    return WeekBundle(
      timesheet: timesheetResponse == null ? null : TimesheetModel.fromMap(timesheetResponse),
      entries: List<Map<String, dynamic>>.from(entriesResponse as List)
          .map(TimeEntryModel.fromMap)
          .toList(),
    );
  }

  Future<void> startTimer({
    required String projectId,
    required String? taskId,
    required String note,
    required bool billable,
  }) async {
    final token = _requireAccessToken();
    final response = await http.post(
      Uri.parse('${config.supabaseUrl}/functions/v1/timer-start'),
      headers: _headers(token),
      body: jsonEncode({
        'organization_id': organizationId,
        'project_id': projectId,
        'task_id': taskId,
        'note': note.isEmpty ? null : note,
        'billable': billable,
      }),
    );
    _throwIfBadResponse(response);
  }

  Future<void> stopTimer({
    required String sessionId,
  }) async {
    final token = _requireAccessToken();
    final response = await http.post(
      Uri.parse('${config.supabaseUrl}/functions/v1/timer-stop'),
      headers: _headers(token),
      body: jsonEncode({
        'session_id': sessionId,
      }),
    );
    _throwIfBadResponse(response);
  }

  Future<void> createManualEntry({
    required String projectId,
    required String? taskId,
    required String note,
    required bool billable,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final token = _requireAccessToken();
    final response = await http.post(
      Uri.parse('${config.supabaseUrl}/functions/v1/time-entry-create'),
      headers: _headers(token),
      body: jsonEncode({
        'organization_id': organizationId,
        'project_id': projectId,
        'task_id': taskId,
        'note': note.isEmpty ? null : note,
        'billable': billable,
        'started_at': startedAt.toUtc().toIso8601String(),
        'ended_at': endedAt.toUtc().toIso8601String(),
      }),
    );
    _throwIfBadResponse(response);
  }

  Future<void> submitTimesheet(String timesheetId) async {
    final token = _requireAccessToken();
    final response = await http.post(
      Uri.parse('${config.supabaseUrl}/functions/v1/timesheet-submit'),
      headers: _headers(token),
      body: jsonEncode({
        'timesheet_id': timesheetId,
      }),
    );
    _throwIfBadResponse(response);
  }

  Future<AssistantReplyModel> askAssistant(String message) async {
    final token = _requireAccessToken();
    final response = await http.post(
      Uri.parse('${config.supabaseUrl}/functions/v1/ai-assistant'),
      headers: _headers(token),
      body: jsonEncode({
        'organization_id': organizationId,
        'message': message,
      }),
    );
    _throwIfBadResponse(response);

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return AssistantReplyModel.fromMap(payload);
  }

  Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  void _throwIfBadResponse(http.Response response) {
    if (response.statusCode < 400) {
      return;
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(payload['error'] ?? 'Request failed.');
  }

  SupabaseClient _requireClient() {
    final supabase = client;
    if (supabase == null) {
      throw Exception('Supabase is not configured for this build.');
    }
    return supabase;
  }

  Session _requireSession() {
    final session = _requireClient().auth.currentSession;
    if (session == null) {
      throw Exception('No authenticated session found.');
    }
    return session;
  }

  String _requireAccessToken() {
    final token = _requireSession().accessToken;
    if (token.isEmpty) {
      throw Exception('Missing access token.');
    }
    return token;
  }
}

DateTime _startOfWeek(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}
