import 'package:contractor_mobile/src/core/models.dart';
import 'package:contractor_mobile/src/state/mobile_providers.dart';
import 'package:contractor_mobile/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TimesheetScreen extends ConsumerStatefulWidget {
  const TimesheetScreen({super.key});

  @override
  ConsumerState<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends ConsumerState<TimesheetScreen> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<void>>(worklogControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bundleAsync = ref.watch(currentWeekBundleProvider);
    final projects = ref.watch(projectsProvider).asData?.value ?? const <ProjectModel>[];
    final tasks = ref.watch(tasksProvider).asData?.value ?? const <TaskModel>[];
    final actionState = ref.watch(worklogControllerProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text('Weekly timesheet', style: Theme.of(context).textTheme.headlineMedium)
              .animate()
              .fadeIn(duration: 360.ms)
              .moveY(begin: 12, end: 0),
          const SizedBox(height: 8),
          Text(
            'Review your draft before sending it to the manager queue.',
            style: Theme.of(context).textTheme.bodyLarge,
          ).animate(delay: 80.ms).fadeIn(duration: 360.ms).moveY(begin: 10, end: 0),
          const SizedBox(height: 18),
          bundleAsync.when(
            data: (bundle) => _TimesheetCard(
              bundle: bundle,
              projects: projects,
              tasks: tasks,
              busy: actionState.isLoading,
              onSubmit: bundle.timesheet == null || bundle.timesheet!.status != 'draft'
                  ? null
                  : () async {
                      await ref.read(worklogControllerProvider.notifier).submitTimesheet(bundle.timesheet!.id);
                    },
            ),
            error: (error, stackTrace) => _ErrorCard(message: error.toString()),
            loading: () => const _LoadingCard(),
          ),
        ],
      ),
    );
  }
}

class _TimesheetCard extends StatelessWidget {
  const _TimesheetCard({
    required this.bundle,
    required this.projects,
    required this.tasks,
    required this.busy,
    required this.onSubmit,
  });

  final WeekBundle bundle;
  final List<ProjectModel> projects;
  final List<TaskModel> tasks;
  final bool busy;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = bundle.entries.fold<int>(0, (sum, entry) => sum + entry.minutes);
    final totalHours = totalMinutes / 60;
    final timesheet = bundle.timesheet;
    final groupedByDay = <String, List<TimeEntryModel>>{};
    for (final entry in bundle.entries) {
      final key = DateFormat('EEE, MMM d').format(entry.startedAt.toLocal());
      groupedByDay.putIfAbsent(key, () => []).add(entry);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timesheet == null
                            ? 'Current week'
                            : '${DateFormat.MMMd().format(timesheet.weekStart)} - ${DateFormat.MMMd().format(timesheet.weekEnd)}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalHours.toStringAsFixed(1)}h tracked this week',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: timesheet?.status ?? 'draft'),
              ],
            ),
            if ((timesheet?.rejectionReason ?? '').isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.rose.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  timesheet!.rejectionReason!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
            const SizedBox(height: 20),
            for (final entry in groupedByDay.entries) ...[
              Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              for (final item in entry.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TimesheetEntryTile(
                    entry: item,
                    projectName: projects.where((project) => project.id == item.projectId).firstOrNull?.name ?? 'Project',
                    taskName: tasks.where((task) => task.id == item.taskId).firstOrNull?.name,
                  ),
                ),
              const SizedBox(height: 8),
            ],
            if (bundle.entries.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  'This week is still empty. Use the timer on the Today tab or add a manual entry.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy ? null : onSubmit,
              child: Text(
                timesheet == null
                    ? 'Nothing to submit yet'
                    : timesheet.status == 'draft'
                        ? 'Submit timesheet'
                        : 'Timesheet ${timesheet.status}',
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 120.ms).fadeIn(duration: 420.ms).moveY(begin: 18, end: 0);
  }
}

class _TimesheetEntryTile extends StatelessWidget {
  const _TimesheetEntryTile({
    required this.entry,
    required this.projectName,
    required this.taskName,
  });

  final TimeEntryModel entry;
  final String projectName;
  final String? taskName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(projectName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  taskName ?? entry.note ?? 'Manual work log',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text('${entry.hours.toStringAsFixed(1)}h', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => AppColors.mint,
      'submitted' => AppColors.amber,
      'rejected' => AppColors.rose,
      _ => AppColors.electric,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
