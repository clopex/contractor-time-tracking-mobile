import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.defaultOrganizationId,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
      defaultOrganizationId: const String.fromEnvironment('DEFAULT_ORGANIZATION_ID'),
    );
  }

  final String supabaseUrl;
  final String supabasePublishableKey;
  final String defaultOrganizationId;

  bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabasePublishableKey.isNotEmpty &&
      defaultOrganizationId.isNotEmpty;
}

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());
