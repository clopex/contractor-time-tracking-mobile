import 'package:contractor_mobile/src/core/app_config.dart';
import 'package:contractor_mobile/src/screens/home_shell.dart';
import 'package:contractor_mobile/src/screens/sign_in_screen.dart';
import 'package:contractor_mobile/src/state/mobile_providers.dart';
import 'package:contractor_mobile/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final sessionAsync = ref.watch(authSessionProvider);

    if (!config.isConfigured) {
      return const _ConfigMissingScreen();
    }

    return sessionAsync.when(
      data: (session) => session == null ? const SignInScreen() : const HomeShell(),
      error: (error, stackTrace) => _ErrorScreen(message: error.toString()),
      loading: () => const _BootScreen(),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.ink,
              AppColors.deepOcean,
              Color(0xFF244A7D),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0x66FFFFFF),
                      Color(0x11FFFFFF),
                    ],
                  ),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(0.94, 0.94), end: const Offset(1.02, 1.02), duration: 1800.ms),
              const SizedBox(height: 28),
              Text(
                'Loading contractor workspace',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .moveY(begin: 10, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigMissingScreen extends StatelessWidget {
  const _ConfigMissingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Missing app configuration', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    Text(
                      'Run the app with --dart-define-from-file=.env so the mobile build gets SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, and DEFAULT_ORGANIZATION_ID.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('App bootstrap failed', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    Text(message, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
