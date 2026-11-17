import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/auth/pairing_code.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/flow.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    try {
      final device = await ref
          .read(sessionControllerProvider.notifier)
          .pair(_code.text);
      if (!mounted) return;
      final store = ref.read(sessionControllerProvider).value?.store;
      AppToast.success(
        context,
        l10n.pairSuccess(device.deviceCode, store?.store.name ?? ''),
      );
    } on BackendException catch (e) {
      if (mounted) AppToast.error(context, l10n.commonError(e.message));
    } on Exception catch (e) {
      if (mounted) AppToast.error(context, l10n.commonError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CenteredGlassPage(
      maxWidth: 460,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(alignment: Alignment.centerLeft, child: AppLogoTile()),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.pairTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.pairBody),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              key: const Key('pairing-code'),
              controller: _code,
              enabled: !_busy,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                letterSpacing: 6,
                fontWeight: FontWeight.w600,
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(10)],
              decoration: InputDecoration(labelText: l10n.pairCodeLabel),
              validator: (value) =>
                  isValidPairingCode(value ?? '') ? null : l10n.pairInvalidCode,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              key: const Key('pairing-submit'),
              onPressed: _busy ? null : _submit,
              icon: Icons.link,
              label: l10n.pairButton,
              expand: true,
            ),
            if (_busy) ...[
              const SizedBox(height: AppSpacing.md),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
