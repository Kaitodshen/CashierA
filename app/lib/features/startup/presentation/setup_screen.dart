import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/flow.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Shown when the app was built without SUPABASE_URL / SUPABASE_ANON_KEY.
class SetupScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CenteredGlassPage(
      maxWidth: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.setupTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          EmptyState(
            icon: Icons.settings_suggest_outlined,
            message: l10n.setupBody,
          ),
        ],
      ),
    );
  }
}
