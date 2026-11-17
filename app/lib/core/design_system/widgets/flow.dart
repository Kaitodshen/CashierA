import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// A screen without a shell (splash, setup, welcome, pairing, PIN lock):
/// one centred glass card on the background, scrolling when it is taller
/// than the screen.
class CenteredGlassPage extends StatelessWidget {
  const new({required this.child, this.maxWidth = 480, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: GlassCard(level: GlassLevel.solid, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// The header of a flow screen inside the shell (payment, receipt, refund,
/// close shift): a Back button above the page header. Replaces the inner
/// app bar and its back arrow.
class FlowHeader extends StatelessWidget {
  const new({
    required this.title,
    required this.onBack,
    this.subtitle,
    this.status,
    this.actions = const [],
    this.backKey = const Key('flow-back'),
    super.key,
  });

  final String title;
  final VoidCallback onBack;
  final String? subtitle;
  final Widget? status;
  final List<Widget> actions;
  final Key backKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SecondaryButton(
            key: backKey,
            icon: Icons.arrow_back,
            label: context.l10n.commonBack,
            onPressed: onBack,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PageHeader(
          title: title,
          subtitle: subtitle,
          status: status,
          actions: actions,
        ),
      ],
    );
  }
}
