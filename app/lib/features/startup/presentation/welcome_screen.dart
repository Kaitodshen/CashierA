import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.welcomeTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.welcomeSubtitle, style: theme.textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.xl),
                _ChoiceCard(
                  key: const Key('welcome-pair'),
                  icon: Icons.point_of_sale_outlined,
                  title: l10n.welcomePairTerminal,
                  subtitle: l10n.welcomePairTerminalHint,
                  onTap: () => context.go(AppRoutes.pair),
                ),
                const SizedBox(height: AppSpacing.lg),
                _ChoiceCard(
                  key: const Key('welcome-back-office'),
                  icon: Icons.insights_outlined,
                  title: l10n.welcomeBackOffice,
                  subtitle: l10n.welcomeBackOfficeHint,
                  onTap: () => context.go(AppRoutes.adminSignIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        leading: Icon(icon, size: 32, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
