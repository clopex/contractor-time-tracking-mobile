import 'dart:async';

import 'package:contractor_mobile/src/core/models.dart';
import 'package:contractor_mobile/src/data/mobile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
});

final authSessionProvider = StreamProvider<Session?>((ref) async* {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    yield null;
    return;
  }

  yield client.auth.currentSession;
  yield* client.auth.onAuthStateChange.map((event) => event.session);
});

final currentUserProvider = FutureProvider<UserProfileModel?>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) {
    return null;
  }

  return ref.watch(mobileRepositoryProvider).fetchProfile();
});

final organizationProvider = FutureProvider<OrganizationModel?>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) {
    return null;
  }
  return ref.watch(mobileRepositoryProvider).fetchOrganization();
});

final membershipProvider = FutureProvider<MembershipModel?>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) {
    return null;
  }
  return ref.watch(mobileRepositoryProvider).fetchMembership();
});

final projectsProvider = FutureProvider<List<ProjectModel>>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) {
    return const [];
  }
  return ref.watch(mobileRepositoryProvider).fetchProjects();
});

final tasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) {
    return const [];
  }
  return ref.watch(mobileRepositoryProvider).fetchTasks();
});

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) {
    return DashboardSummary.empty();
  }
  return ref.watch(mobileRepositoryProvider).fetchSummary();
});

final activeSessionProvider = FutureProvider<WorkSessionModel?>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) {
    return null;
  }
  return ref.watch(mobileRepositoryProvider).fetchActiveSession();
});

final currentWeekBundleProvider = FutureProvider<WeekBundle>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) {
    return const WeekBundle(timesheet: null, entries: []);
  }
  return ref.watch(mobileRepositoryProvider).fetchCurrentWeekBundle();
});

final tickerProvider = StreamProvider<DateTime>((ref) {
  return Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});

final selectionProvider =
    NotifierProvider<SelectionNotifier, TaskSelection?>(SelectionNotifier.new);

class SelectionNotifier extends Notifier<TaskSelection?> {
  @override
  TaskSelection? build() => null;

  void select(TaskSelection? nextSelection) {
    state = nextSelection;
  }
}

final authControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      throw Exception('Supabase is not configured.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      ref.invalidate(currentUserProvider);
      ref.invalidate(organizationProvider);
      ref.invalidate(membershipProvider);
      ref.invalidate(projectsProvider);
      ref.invalidate(tasksProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(activeSessionProvider);
      ref.invalidate(currentWeekBundleProvider);
    });
  }

  Future<void> signOut() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      throw Exception('Supabase is not configured.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.auth.signOut();
      ref.invalidate(selectionProvider);
    });
  }
}

final worklogControllerProvider =
    AsyncNotifierProvider.autoDispose<WorklogController, void>(WorklogController.new);

class WorklogController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> startTimer({
    required String projectId,
    required String? taskId,
    required String note,
    required bool billable,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(mobileRepositoryProvider).startTimer(
            projectId: projectId,
            taskId: taskId,
            note: note,
            billable: billable,
          );
      _refresh();
    });
  }

  Future<void> stopTimer(String sessionId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(mobileRepositoryProvider).stopTimer(sessionId: sessionId);
      _refresh();
    });
  }

  Future<void> createManualEntry({
    required String projectId,
    required String? taskId,
    required String note,
    required bool billable,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(mobileRepositoryProvider).createManualEntry(
            projectId: projectId,
            taskId: taskId,
            note: note,
            billable: billable,
            startedAt: startedAt,
            endedAt: endedAt,
          );
      _refresh();
    });
  }

  Future<void> submitTimesheet(String timesheetId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(mobileRepositoryProvider).submitTimesheet(timesheetId);
      _refresh();
    });
  }

  void _refresh() {
    ref.invalidate(activeSessionProvider);
    ref.invalidate(currentWeekBundleProvider);
    ref.invalidate(dashboardSummaryProvider);
  }
}

final assistantControllerProvider =
    AsyncNotifierProvider.autoDispose<AssistantController, AssistantReplyModel?>(
  AssistantController.new,
);

class AssistantController extends AsyncNotifier<AssistantReplyModel?> {
  @override
  FutureOr<AssistantReplyModel?> build() => null;

  Future<void> ask(String message) async {
    final previous = state.asData?.value;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(mobileRepositoryProvider).askAssistant(message);
    });
    if (state.hasError && previous != null) {
      state = AsyncData(previous);
    }
  }
}
