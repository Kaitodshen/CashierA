import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/catalog/catalog_item.dart';
import 'package:cashiera/core/catalog/qty_input.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/buttons.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/flow.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/catalog/presentation/catalog_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Stock count on the terminal: type what is on the shelf, submit once.
/// Only the rows filled in are changed. Works offline.
class OpnameScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<OpnameScreen> createState() => _OpnameScreenState();
}

class _OpnameScreenState extends ConsumerState<OpnameScreen> {
  final _counts = <String, Qty>{};
  final _invalid = <String>{};
  bool _busy = false;

  void _onChanged(CatalogItem item, String text) {
    setState(() {
      if (text.trim().isEmpty) {
        _counts.remove(item.variantId);
        _invalid.remove(item.variantId);
        return;
      }
      final parsed = parseQtyInput(
        text,
        allowDecimal: item.allowDecimal,
        allowZero: true,
      );
      if (parsed.qty == null) {
        _counts.remove(item.variantId);
        _invalid.add(item.variantId);
      } else {
        _counts[item.variantId] = parsed.qty!;
        _invalid.remove(item.variantId);
      }
    });
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => GlassDialog(
        title: Text(l10n.opnameTitle),
        content: SingleChildScrollView(
          child: Text(l10n.opnameConfirm(_counts.length)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonContinue),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;

    final session = ref.read(sessionControllerProvider).value;
    final device = session?.device;
    final staff = session?.staff;
    if (device == null || staff == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(stockServiceProvider)
          .submitOpname(
            storeId: device.storeId,
            deviceCode: device.deviceCode,
            staff: staff,
            counts: Map.of(_counts),
          );
      ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
      if (!mounted) return;
      AppToast.success(context, l10n.opnameDone);
      context.go(AppRoutes.catalog);
    } on Exception catch (e) {
      if (mounted) AppToast.error(context, l10n.commonError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items =
        (ref.watch(catalogItemsProvider).value ?? const <CatalogItem>[])
            .where((i) => i.trackStock)
            .toList();
    final canSubmit = _counts.isNotEmpty && _invalid.isEmpty && !_busy;

    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.textMuted);

    String onHand(CatalogItem i) => '${i.stock.toPlain()} ${i.unitCode}';

    Widget row(CatalogItem item) {
      final counted = _counts[item.variantId];
      final diff = counted == null ? null : counted.milli - item.stock.milli;
      return Padding(
        key: Key('opname-${item.sku}'),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${item.sku} · '
                    '${l10n.opnameSystem(onHand(item))}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                ],
              ),
            ),
            if (diff != null && diff != 0) ...[
              const SizedBox(width: AppSpacing.sm),
              StatusChip(
                label: '${diff > 0 ? '+' : ''}${Qty(diff).toPlain()}',
                tone: diff > 0 ? StatusTone.warning : StatusTone.error,
              ),
            ],
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 112,
              child: TextField(
                key: Key('opname-count-${item.sku}'),
                textAlign: TextAlign.end,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: item.allowDecimal,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  suffixText: item.unitCode,
                  errorText: _invalid.contains(item.variantId) ? '!' : null,
                ),
                onChanged: (text) => _onChanged(item, text),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              FlowHeader(
                title: l10n.opnameTitle,
                subtitle: l10n.opnameHint,
                onBack: () => context.go(AppRoutes.catalog),
                backKey: const Key('opname-back'),
                actions: [
                  PrimaryButton(
                    key: const Key('opname-submit'),
                    onPressed: canSubmit ? _submit : null,
                    icon: Icons.fact_check_outlined,
                    label: l10n.opnameSubmit(_counts.length),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassCard(
                level: GlassLevel.solid,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.catalogSearchHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: ref.read(catalogQueryProvider.notifier).setSearch,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassCard(
                level: GlassLevel.solid,
                child: items.isEmpty
                    ? EmptyState(
                        icon: Icons.inventory_2_outlined,
                        message: l10n.catalogNoMatch,
                      )
                    : Column(
                        children: [
                          for (final (i, item) in items.indexed) ...[
                            if (i > 0) const Divider(height: 1),
                            row(item),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
