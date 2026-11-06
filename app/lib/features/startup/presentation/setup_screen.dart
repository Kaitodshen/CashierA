import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Shown when the app was built without SUPABASE_URL / SUPABASE_ANON_KEY.
class SetupScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.setupTitle)),
      body: EmptyState(
        icon: Icons.settings_suggest_outlined,
        message: l10n.setupBody,
      ),
    );
  }
}
