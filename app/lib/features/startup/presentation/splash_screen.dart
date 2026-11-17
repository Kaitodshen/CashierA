import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/flow.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return CenteredGlassPage(
      maxWidth: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogoTile(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.appTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }
}
