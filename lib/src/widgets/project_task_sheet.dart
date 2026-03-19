import 'package:contractor_mobile/src/core/models.dart';
import 'package:contractor_mobile/src/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ProjectTaskSheet extends StatelessWidget {
  const ProjectTaskSheet({
    super.key,
    required this.projects,
    required this.tasks,
    required this.currentSelection,
    required this.onSelected,
  });

  final List<ProjectModel> projects;
  final List<TaskModel> tasks;
  final TaskSelection? currentSelection;
  final ValueChanged<TaskSelection> onSelected;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.55,
      builder: (context, controller) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.frost,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Choose project', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Pick where the timer should run. Tasks are grouped under each project.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              for (final project in projects) ...[
                Text(
                  project.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                _SelectionTile(
                  title: 'No specific task',
                  subtitle: project.clientName,
                  selected: currentSelection?.projectId == project.id && currentSelection?.taskId == null,
                  onTap: () {
                    onSelected(TaskSelection(projectId: project.id));
                    Navigator.of(context).pop();
                  },
                ),
                for (final task in tasks.where((item) => item.projectId == project.id))
                  _SelectionTile(
                    title: task.name,
                    subtitle: task.isBillable ? 'Billable task' : 'Non-billable task',
                    selected: currentSelection?.projectId == project.id && currentSelection?.taskId == task.id,
                    onTap: () {
                      onSelected(TaskSelection(projectId: project.id, taskId: task.id));
                      Navigator.of(context).pop();
                    },
                  ),
                const SizedBox(height: 18),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? AppColors.electric.withValues(alpha: 0.08) : AppColors.mist,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.electric : Colors.white,
                    border: Border.all(
                      color: selected ? AppColors.electric : AppColors.frost,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
