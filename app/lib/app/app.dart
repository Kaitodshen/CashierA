import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/app/router.dart';
import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

class CashierApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(
      sessionControllerProvider.select((s) => s.value?.mode),
    );
    final terminal = mode != null && isTerminalMode(mode);
    return ToastificationWrapper(
      child: MaterialApp.router(
        onGenerateTitle: (context) => context.l10n.appTitle,
        debugShowCheckedModeBanner: false,
        theme: terminal ? AppTheme.pos() : AppTheme.backOffice(),
        routerConfig: ref.watch(routerProvider),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Bahasa Indonesia unless the device is set to English.
        localeResolutionCallback: (locale, supported) =>
            locale?.languageCode == 'en'
            ? const Locale('en')
            : const Locale('id'),
      ),
    );
  }
}
