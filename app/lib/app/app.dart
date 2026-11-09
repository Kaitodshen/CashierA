import 'package:cashiera/app/router.dart';
import 'package:cashiera/core/design_system/theme.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

class CashierApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ToastificationWrapper(
      child: MaterialApp.router(
        onGenerateTitle: (context) => context.l10n.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
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
