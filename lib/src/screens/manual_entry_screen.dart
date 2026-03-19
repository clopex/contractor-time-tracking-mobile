import 'package:contractor_mobile/src/core/models.dart';
import 'package:contractor_mobile/src/state/mobile_providers.dart';
import 'package:contractor_mobile/src/theme/app_theme.dart';
import 'package:contractor_mobile/src/widgets/project_task_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _noteController = TextEditingController();
  late DateTime _startedAt;
  late DateTime _endedAt;
  bool _billable = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endedAt = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    _startedAt = _endedAt.subtract(const Duration(hours: 2));
    ref.listenManual<AsyncValue<void>>(worklogControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          if (previous?.isLoading == true && context.mounted) {
            context.pop();
          }
        },
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
    final projects = ref.watch(projectsProvider).asData?.value ?? const <ProjectModel>[];
    final tasks = ref.watch(tasksProvider).asData?.value ?? const <TaskModel>[];
    final selection = ref.watch(selectionProvider);
    final effectiveSelection = _resolveSelection(
      projects: projects,
      tasks: tasks,
      current: selection,
    );
    final actionState = ref.watch(worklogControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual entry'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Log time without the timer', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Use this when field work happened before the app was opened.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: () {
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
                      icon: const Icon(Icons.layers_outlined),
                      label: Text(
                        effectiveSelection == null
                            ? 'Select project'
                            : projects.where((item) => item.id == effectiveSelection.projectId).firstOrNull?.name ?? 'Select project',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Work note',
                        hintText: 'What exactly was done during this block?',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _DateTimeTile(
                            label: 'Started',
                            value: _startedAt,
                            onTap: () async {
                              final picked = await _pickDateTime(context, _startedAt);
                              if (picked != null) {
                                setState(() => _startedAt = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateTimeTile(
                            label: 'Ended',
                            value: _endedAt,
                            onTap: () async {
                              final picked = await _pickDateTime(context, _endedAt);
                              if (picked != null) {
                                setState(() => _endedAt = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile.adaptive(
                      value: _billable,
                      activeTrackColor: AppColors.mint,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Billable work'),
                      subtitle: const Text('Turn off for internal admin or planning time.'),
                      onChanged: (value) => setState(() => _billable = value),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: actionState.isLoading
                          ? null
                          : () async {
                              if (effectiveSelection == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Select a project first.')),
                                );
                                return;
                              }
                              if (!_endedAt.isAfter(_startedAt)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('End time must be after start time.')),
                                );
                                return;
                              }

                              await ref.read(worklogControllerProvider.notifier).createManualEntry(
                                    projectId: effectiveSelection.projectId,
                                    taskId: effectiveSelection.taskId,
                                    note: _noteController.text,
                                    billable: _billable,
                                    startedAt: _startedAt,
                                    endedAt: _endedAt,
                                  );
                            },
                      icon: actionState.isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: const Text('Save manual entry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDateTime(BuildContext context, DateTime initialValue) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialValue,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate == null || !context.mounted) {
      return null;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialValue),
    );

    if (pickedTime == null) {
      return null;
    }

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(DateFormat('MMM d').format(value), style: Theme.of(context).textTheme.titleMedium),
            Text(DateFormat('HH:mm').format(value), style: Theme.of(context).textTheme.bodyMedium),
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
  return TaskSelection(projectId: firstProject.id, taskId: firstTask?.id);
}
