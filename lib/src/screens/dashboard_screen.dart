import 'package:contractor_mobile/src/core/models.dart';
import 'package:contractor_mobile/src/state/mobile_providers.dart';
import 'package:contractor_mobile/src/theme/app_theme.dart';
import 'package:contractor_mobile/src/widgets/project_task_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _noteController = TextEditingController();
  bool _billable = true;

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
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProvider);
    final projectsAsync = ref.watch(projectsProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final activeSessionAsync = ref.watch(activeSessionProvider);
    final weekBundleAsync = ref.watch(currentWeekBundleProvider);
    final selection = ref.watch(selectionProvider);
    final actionState = ref.watch(worklogControllerProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF7F9FD),
            Color(0xFFF1F6FB),
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            profile.when(
              data: (user) => _HeroHeader(user: user),
              error: (error, stackTrace) => _HeroHeader(
                user: UserProfileModel(id: 'fallback', fullName: 'Crew member', email: ''),
              ),
              loading: () => const SizedBox(height: 94),
            ),
            const SizedBox(height: 18),
            projectsAsync.when(
              data: (projects) {
                return tasksAsync.when(
                  data: (tasks) {
                    final effectiveSelection = _resolveSelection(
                      projects: projects,
                      tasks: tasks,
                      current: selection,
                    );
                    if (selection == null && effectiveSelection != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ref.read(selectionProvider.notifier).select(effectiveSelection);
                      });
                    }

                    return _ProjectTimerCard(
                      projects: projects,
                      tasks: tasks,
                      selection: effectiveSelection,
                      activeSessionAsync: activeSessionAsync,
                      noteController: _noteController,
                      billable: _billable,
                      onBillableChanged: (value) => setState(() => _billable = value),
                      onChooseProject: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => ProjectTaskSheet(
                            projects: projects,
                            tasks: tasks,
                            currentSelection: effectiveSelection,
                            onSelected: (nextSelection) {
                              ref.read(selectionProvider.notifier).select(nextSelection);
                            },
                          ),
                        );
                      },
                      busy: actionState.isLoading,
                      onPrimaryAction: () async {
                        final activeSession = ref.read(activeSessionProvider).asData?.value;
                        if (activeSession != null) {
                          await ref.read(worklogControllerProvider.notifier).stopTimer(activeSession.id);
                          return;
                        }

                        if (effectiveSelection == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Select a project before starting the timer.')),
                          );
                          return;
                        }

                        await ref.read(worklogControllerProvider.notifier).startTimer(
                              projectId: effectiveSelection.projectId,
                              taskId: effectiveSelection.taskId,
                              note: _noteController.text,
                              billable: _billable,
                            );
                      },
                    );
                  },
                  error: (error, stackTrace) => _InlineErrorCard(message: error.toString()),
                  loading: () => const _LoadingCard(height: 320),
                );
              },
              error: (error, stackTrace) => _InlineErrorCard(message: error.toString()),
              loading: () => const _LoadingCard(height: 320),
            ),
            const SizedBox(height: 18),
            summaryAsync.when(
              data: (summary) => _StatsGrid(summary: summary),
              error: (error, stackTrace) => _InlineErrorCard(message: error.toString()),
              loading: () => const _LoadingCard(height: 164),
            ),
            const SizedBox(height: 18),
            _QuickActions(
              onAssistantTap: () => context.push('/assistant'),
              onManualEntryTap: () => context.push('/manual-entry'),
            ),
            const SizedBox(height: 18),
            weekBundleAsync.when(
              data: (bundle) => _RecentEntries(entries: bundle.entries, projectsAsync: projectsAsync, tasksAsync: tasksAsync),
              error: (error, stackTrace) => _InlineErrorCard(message: error.toString()),
              loading: () => const _LoadingCard(height: 250),
            ),
          ],
        ),
      ),
    );
  }
}

TaskSelection? _resolveSelection({
  required List<ProjectModel> projects,
  required List<TaskModel> tasks,
  required TaskSelection? current,
}) {
  if (projects.isEmpty) {
    return null;
  }

  if (current != null && projects.any((project) => project.id == current.projectId)) {
    return current;
  }

  final firstProject = projects.first;
  final firstTask = tasks.where((task) => task.projectId == firstProject.id).cast<TaskModel?>().firstOrNull;
  return TaskSelection(
    projectId: firstProject.id,
    taskId: firstTask?.id,
  );
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.user,
  });

  final UserProfileModel? user;

  @override
  Widget build(BuildContext context) {
    final firstName = user?.fullName.split(' ').first ?? 'Crew';

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.ink,
            AppColors.deepOcean,
            Color(0xFF1F4572),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.electric.withValues(alpha: 0.18),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good shift, $firstName',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'Today is built for one-tap timers, clean weekly submissions, and quick AI help when notes get messy.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(color: Colors.white24),
            ),
            alignment: Alignment.center,
            child: Text(
              firstName.characters.take(1).toString().toUpperCase(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 420.ms).moveY(begin: 18, end: 0);
  }
}

class _ProjectTimerCard extends ConsumerWidget {
  const _ProjectTimerCard({
    required this.projects,
    required this.tasks,
    required this.selection,
    required this.activeSessionAsync,
    required this.noteController,
    required this.billable,
    required this.onBillableChanged,
    required this.onChooseProject,
    required this.busy,
    required this.onPrimaryAction,
  });

  final List<ProjectModel> projects;
  final List<TaskModel> tasks;
  final TaskSelection? selection;
  final AsyncValue<WorkSessionModel?> activeSessionAsync;
  final TextEditingController noteController;
  final bool billable;
  final ValueChanged<bool> onBillableChanged;
  final VoidCallback onChooseProject;
  final bool busy;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = activeSessionAsync.asData?.value;
    final effectiveProject = activeSession == null
        ? projects.where((item) => item.id == selection?.projectId).firstOrNull
        : projects.where((item) => item.id == activeSession.projectId).firstOrNull;
    final effectiveTask = activeSession == null
        ? tasks.where((item) => item.id == selection?.taskId).firstOrNull
        : tasks.where((item) => item.id == activeSession.taskId).firstOrNull;
    final now = ref.watch(tickerProvider).asData?.value ?? DateTime.now();
    final elapsed = activeSession?.elapsedAt(now) ?? Duration.zero;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
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
                        activeSession == null ? 'Ready to log' : 'Timer is running',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: activeSession == null ? AppColors.slate : AppColors.mint,
                              letterSpacing: 0.3,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        effectiveProject?.name ?? 'Choose a project',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        effectiveTask?.name ?? (effectiveProject?.clientName ?? 'No task selected yet'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _TimerPulse(elapsed: elapsed, running: activeSession != null),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Shift note',
                hintText: 'Exterior framing, final walkthrough, materials pickup...',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: activeSession == null ? onChooseProject : null,
                    icon: const Icon(Icons.layers_outlined),
                    label: const Text('Select project'),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: Text(billable ? 'Billable' : 'Internal'),
                  selected: billable,
                  onSelected: activeSession == null ? onBillableChanged : null,
                  selectedColor: AppColors.mint.withValues(alpha: 0.14),
                  side: const BorderSide(color: AppColors.frost),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: busy ? null : onPrimaryAction,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(activeSession == null ? Icons.play_arrow_rounded : Icons.stop_rounded),
              label: Text(
                activeSession == null
                    ? 'Start timer'
                    : 'Stop timer • ${_formatDuration(elapsed)}',
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 80.ms).fadeIn(duration: 460.ms).moveY(begin: 18, end: 0);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

class _TimerPulse extends StatelessWidget {
  const _TimerPulse({
    required this.elapsed,
    required this.running,
  });

  final Duration elapsed;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final progress = ((elapsed.inMinutes % 60) / 60).clamp(0.02, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: running ? progress.toDouble() : 0.08),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return SizedBox(
          width: 98,
          height: 98,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 10,
                backgroundColor: AppColors.frost,
                valueColor: AlwaysStoppedAnimation<Color>(
                  running ? AppColors.mint : AppColors.electric,
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      running ? '${elapsed.inHours}h' : 'Idle',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      running ? '${elapsed.inMinutes % 60}m' : 'Ready',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.summary,
  });

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('This week', '${summary.totalHours.toStringAsFixed(1)}h', AppColors.electric),
      ('Billable', '${summary.billableHours.toStringAsFixed(1)}h', AppColors.mint),
      ('Pending', '${summary.submittedTimesheets}', AppColors.amber),
      ('Active jobs', '${summary.activeProjects}', AppColors.rose),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var index = 0; index < items.length; index++)
          SizedBox(
            width: (MediaQuery.sizeOf(context).width - 52) / 2,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: items[index].$3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(items[index].$2, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Text(items[index].$1, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ).animate(delay: (110 + (index * 60)).ms).fadeIn(duration: 380.ms).moveY(begin: 12, end: 0),
          ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAssistantTap,
    required this.onManualEntryTap,
  });

  final VoidCallback onAssistantTap;
  final VoidCallback onManualEntryTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Jump into AI notes or add a clean manual entry when the timer was not running.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAssistantTap,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.ink),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('AI assistant'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onManualEntryTap,
                    icon: const Icon(Icons.edit_calendar_rounded),
                    label: const Text('Manual entry'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: 160.ms).fadeIn(duration: 380.ms).moveY(begin: 14, end: 0);
  }
}

class _RecentEntries extends StatelessWidget {
  const _RecentEntries({
    required this.entries,
    required this.projectsAsync,
    required this.tasksAsync,
  });

  final List<TimeEntryModel> entries;
  final AsyncValue<List<ProjectModel>> projectsAsync;
  final AsyncValue<List<TaskModel>> tasksAsync;

  @override
  Widget build(BuildContext context) {
    final projects = projectsAsync.asData?.value ?? const <ProjectModel>[];
    final tasks = tasksAsync.asData?.value ?? const <TaskModel>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent entries', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Your newest work logs from the current week.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  'No entries yet. Start the timer or create a manual entry to make this week visible.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            else
              for (var index = 0; index < entries.take(5).length; index++)
                _EntryTile(
                  entry: entries[index],
                  projectName: projects.where((project) => project.id == entries[index].projectId).firstOrNull?.name ?? 'Project',
                  taskName: tasks.where((task) => task.id == entries[index].taskId).firstOrNull?.name,
                ).animate(delay: (90 + (index * 50)).ms).fadeIn(duration: 360.ms).moveX(begin: 12, end: 0),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.projectName,
    required this.taskName,
  });

  final TimeEntryModel entry;
  final String projectName;
  final String? taskName;

  @override
  Widget build(BuildContext context) {
    final range = '${DateFormat.Hm().format(entry.startedAt.toLocal())} - ${DateFormat.Hm().format(entry.endedAt.toLocal())}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: entry.billable ? AppColors.electric.withValues(alpha: 0.12) : AppColors.amber.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(
                entry.billable ? Icons.work_history_rounded : Icons.handyman_outlined,
                color: entry.billable ? AppColors.electric : AppColors.amber,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(projectName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(taskName ?? range, style: Theme.of(context).textTheme.bodyMedium),
                  if (taskName != null)
                    Text(range, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Text('${entry.hours.toStringAsFixed(1)}h', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({
    required this.height,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({
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
