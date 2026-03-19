import 'package:contractor_mobile/src/core/models.dart';
import 'package:contractor_mobile/src/state/mobile_providers.dart';
import 'package:contractor_mobile/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<void>>(authControllerProvider, (previous, next) {
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
    final user = ref.watch(currentUserProvider).asData?.value;
    final organization = ref.watch(organizationProvider).asData?.value;
    final membership = ref.watch(membershipProvider).asData?.value;
    final authState = ref.watch(authControllerProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium)
              .animate()
              .fadeIn(duration: 320.ms)
              .moveY(begin: 10, end: 0),
          const SizedBox(height: 18),
          _ProfileCard(user: user, membership: membership).animate(delay: 60.ms).fadeIn(duration: 360.ms).moveY(begin: 12, end: 0),
          const SizedBox(height: 14),
          _WorkspaceCard(organization: organization, membership: membership).animate(delay: 120.ms).fadeIn(duration: 360.ms).moveY(begin: 12, end: 0),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Backend status', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  _StatusRow(label: 'Supabase Auth', value: 'Connected'),
                  _StatusRow(label: 'Timer endpoints', value: 'Live'),
                  _StatusRow(label: 'Weekly timesheets', value: 'Live'),
                  _StatusRow(label: 'Gemini assistant', value: 'Live'),
                ],
              ),
            ),
          ).animate(delay: 180.ms).fadeIn(duration: 360.ms).moveY(begin: 12, end: 0),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: authState.isLoading
                ? null
                : () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                  },
            style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
            icon: authState.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.membership,
  });

  final UserProfileModel? user;
  final MembershipModel? membership;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [
                    AppColors.electric,
                    AppColors.deepOcean,
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                (user?.fullName.characters.firstOrNull ?? 'C').toUpperCase(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.fullName ?? 'Crew member', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(user?.email ?? 'No email available', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.mist,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      membership?.role.toUpperCase() ?? 'NO MEMBERSHIP',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.organization,
    required this.membership,
  });

  final OrganizationModel? organization;
  final MembershipModel? membership;

  @override
  Widget build(BuildContext context) {
    final hourlyRate = (membership?.hourlyRateCents ?? 0) / 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Workspace', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _StatusRow(label: 'Organization', value: organization?.name ?? 'Unknown workspace'),
            _StatusRow(label: 'Timezone', value: organization?.timezone ?? 'Not available'),
            _StatusRow(label: 'Hourly rate', value: hourlyRate > 0 ? '\$${hourlyRate.toStringAsFixed(0)}/h' : 'Not set'),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}
