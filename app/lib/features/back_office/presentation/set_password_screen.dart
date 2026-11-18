import 'dart:async';

import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/flow.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _Stage { checking, expired, form }

/// Opened from an invitation email: accepts the link once, then lets the
/// person choose a password and lands them in the back office.
class SetPasswordScreen extends ConsumerStatefulWidget {
  const new({this.tokenHash, super.key});

  /// From the link's `token_hash` query parameter; null means a bad link.
  final String? tokenHash;

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _second = TextEditingController();
  _Stage _stage = _Stage.checking;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_accept());
  }

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    final token = widget.tokenHash;
    if (token == null || token.isEmpty) {
      setState(() => _stage = _Stage.expired);
      return;
    }
    try {
      await ref.read(backOfficeBackendProvider).acceptInvite(token);
      if (mounted) setState(() => _stage = _Stage.form);
    } on BackendException {
      if (mounted) setState(() => _stage = _Stage.expired);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(backOfficeBackendProvider).setPassword(_first.text);
      ref.read(sessionControllerProvider.notifier).enterBackOffice();
      if (mounted) context.go(AppRoutes.admin);
    } on BackendException catch (e) {
      if (mounted) setState(() => _error = l10n.commonError(e.message));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final header = [
      const Align(alignment: Alignment.centerLeft, child: AppLogoTile()),
      const SizedBox(height: AppSpacing.lg),
      Text(l10n.setPasswordTitle, style: theme.textTheme.headlineMedium),
      const SizedBox(height: AppSpacing.sm),
    ];
    return CenteredGlassPage(
      maxWidth: 440,
      child: switch (_stage) {
        _Stage.checking => const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
        _Stage.expired => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...header,
            Text(l10n.setPasswordLinkExpired),
            const SizedBox(height: AppSpacing.xl),
            SecondaryButton(
              key: const Key('set-password-sign-in'),
              onPressed: () => context.go(AppRoutes.adminSignIn),
              icon: Icons.login,
              label: l10n.setPasswordToSignIn,
            ),
          ],
        ),
        _Stage.form => Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...header,
              Text(
                l10n.setPasswordBody,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                key: const Key('set-password-1'),
                controller: _first,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(labelText: l10n.setPasswordNew),
                validator: (v) =>
                    (v ?? '').length < 8 ? l10n.setPasswordTooShort : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                key: const Key('set-password-2'),
                controller: _second,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.setPasswordAgain),
                validator: (v) =>
                    v != _first.text ? l10n.setPasswordMismatch : null,
                onFieldSubmitted: (_) => _save(),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                key: const Key('set-password-save'),
                expand: true,
                onPressed: _busy ? null : _save,
                icon: Icons.lock_reset,
                label: l10n.setPasswordSave,
              ),
            ],
          ),
        ),
      },
    );
  }
}
