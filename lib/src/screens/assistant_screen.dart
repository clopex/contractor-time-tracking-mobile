import 'package:contractor_mobile/src/state/mobile_providers.dart';
import 'package:contractor_mobile/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = 'Summarize this week and suggest any missing time entries.';
    ref.listenManual<AsyncValue<dynamic>>(assistantControllerProvider, (previous, next) {
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assistantState = ref.watch(assistantControllerProvider);
    final reply = assistantState.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI assistant'),
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
                    Text('Ask Gemini to help with time tracking', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'The assistant returns suggestions only. Final writes still happen through explicit app actions.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Prompt',
                        hintText: 'Log 2 hours on kitchen remodel yesterday afternoon...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: assistantState.isLoading
                          ? null
                          : () async {
                              if (_controller.text.trim().isEmpty) {
                                return;
                              }
                              await ref.read(assistantControllerProvider.notifier).ask(_controller.text.trim());
                            },
                      icon: assistantState.isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Ask assistant'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (reply != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reply', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Text(reply.reply, style: Theme.of(context).textTheme.bodyLarge),
                      if (reply.actions.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text('Suggested actions', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final action in reply.actions)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.mist,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(action.label),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
