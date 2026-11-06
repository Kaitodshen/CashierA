import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/money_input.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/printing/print_actions.dart';
import 'package:cashiera/features/sell/presentation/sell_dialogs.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera/features/shift/presentation/report_actions.dart';
import 'package:cashiera/features/shift/presentation/shift_providers.dart';
import 'package:cashiera/features/shift/presentation/shift_widgets.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Counts the drawer (by note or as a total), shows the selisih, and closes
/// the shift. The Z report opens afterwards.
class CloseShiftScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<CloseShiftScreen> createState() => _CloseShiftScreenState();
}

class _CloseShiftScreenState extends ConsumerState<CloseShiftScreen> {
  final _pieces = <int, int>{};
  final _total = TextEditingController();
  final _note = TextEditingController();
  bool _byNotes = true;
  bool _busy = false;

  @override
  void dispose() {
    _total.dispose();
    _note.dispose();
    super.dispose();
  }

  Money? get _counted => _byNotes
      ? CashCount(_pieces).total
      : (parseRupiah(_total.text) == null
            ? null
            : Money(parseRupiah(_total.text)!));

  void _setPieces(int denomination, int count) => setState(() {
    if (count <= 0) {
      _pieces.remove(denomination);
    } else {
      _pieces[denomination] = count;
    }
  });

  Future<void> _close(ShiftRow shift, Money expected, Money counted) async {
    final l10n = context.l10n;
    final ctx = ref.read(saleContextProvider);
    if (ctx == null) return;
    if (counted != expected && _note.text.trim().isEmpty) {
      AppToast.error(context, l10n.closeNoteRequired);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.closeConfirmTitle),
        content: Text(
          l10n.closeConfirmBody(counted.format(), expected.format()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('close-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.shiftClose),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;
    setState(() => _busy = true);
    try {
      final z = await ref
          .read(shiftServiceProvider)
          .close(
            shift: shift,
            staff: ctx.staff,
            counted: counted,
            config: ctx.config,
            deviceCode: ref
                .read(sessionControllerProvider)
                .value
                ?.device
                ?.deviceCode,
            note: _note.text,
          );
      ref.read(syncSchedulerProvider.notifier).syncNow().ignore();
      if (!mounted) return;
      AppToast.success(context, l10n.closeDone);
      if (await ref.read(printerRepositoryProvider).current() != null &&
          mounted) {
        await printShiftReport(context, ref, z, ctx.config);
      }
      if (mounted) context.go(AppRoutes.shiftReport(shift.id));
    } on Exception catch (e) {
      if (mounted) AppToast.error(context, posErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final open = ref.watch(openShiftProvider);
    ref.watch(saleContextProvider);
    final shift = open.value;
    final report = shift == null
        ? null
        : ref.watch(shiftReportProvider(shift.id)).value;
    final held = ref.watch(heldOrdersProvider).value?.length ?? 0;
    final pending = ref.watch(syncOutstandingProvider).value ?? 0;
    final expected = report?.cash.expected;
    final counted = _counted;
    final difference = expected == null || counted == null
        ? null
        : counted - expected;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.shift)),
        title: Text(l10n.closeTitle),
      ),
      body: open.isLoading
          ? const Center(child: CircularProgressIndicator())
          : shift == null
          ? EmptyState(
              icon: Icons.lock_clock_outlined,
              message: l10n.shiftNoneOpen,
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    if (held > 0)
                      _Notice(
                        icon: Icons.pause_circle_outline,
                        text: l10n.closeHeldWarning(held),
                      ),
                    if (pending > 0)
                      _Notice(
                        icon: Icons.cloud_upload_outlined,
                        text: l10n.closePending(pending),
                      ),
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: true,
                          label: Text(l10n.closeCountByNotes),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text(l10n.closeEnterTotal),
                        ),
                      ],
                      selected: {_byNotes},
                      onSelectionChanged: (v) =>
                          setState(() => _byNotes = v.single),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_byNotes)
                      Card(
                        child: Column(
                          children: [
                            for (final d in CashCount.denominations)
                              _DenominationRow(
                                key: Key('denomination-$d'),
                                denomination: d,
                                count: _pieces[d] ?? 0,
                                onChanged: (n) => _setPieces(d, n),
                              ),
                          ],
                        ),
                      )
                    else
                      TextField(
                        key: const Key('close-total'),
                        controller: _total,
                        keyboardType: TextInputType.number,
                        inputFormatters: rupiahInputFormatters,
                        decoration: InputDecoration(
                          labelText: l10n.closeCounted,
                          prefixText: 'Rp ',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            _Line(
                              l10n.closeExpected,
                              expected?.format() ?? '…',
                            ),
                            _Line(
                              l10n.closeCounted,
                              counted?.format() ?? '-',
                              valueKey: const Key('close-counted'),
                            ),
                            const Divider(),
                            _Line(
                              l10n.closeDifference,
                              difference == null
                                  ? '-'
                                  : differenceText(l10n, difference),
                              valueKey: const Key('close-difference'),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: differenceColor(difference),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      key: const Key('close-note'),
                      controller: _note,
                      decoration: InputDecoration(
                        labelText: l10n.closeNote,
                        helperText: difference != null && difference.rupiah != 0
                            ? l10n.closeNoteRequired
                            : null,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      key: const Key('close-submit'),
                      onPressed: _busy || expected == null || counted == null
                          ? null
                          : () => _close(shift, expected, counted),
                      icon: const Icon(Icons.lock_outline),
                      label: Text(l10n.shiftClose),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Notice extends StatelessWidget {
  const new({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.warning.withValues(alpha: 0.15),
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    child: ListTile(
      leading: Icon(icon, color: AppColors.warning),
      title: Text(text),
    ),
  );
}

class _Line extends StatelessWidget {
  const new(this.label, this.value, {this.valueKey, this.style});
  final String label;
  final String value;
  final Key? valueKey;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, key: valueKey, style: style),
      ],
    ),
  );
}

class _DenominationRow extends StatefulWidget {
  const new({
    required this.denomination,
    required this.count,
    required this.onChanged,
    super.key,
  });

  final int denomination;
  final int count;
  final ValueChanged<int> onChanged;

  @override
  State<_DenominationRow> createState() => _DenominationRowState();
}

class _DenominationRowState extends State<_DenominationRow> {
  late final _controller = TextEditingController(
    text: widget.count == 0 ? '' : '${widget.count}',
  );

  @override
  void didUpdateWidget(_DenominationRow old) {
    super.didUpdateWidget(old);
    final text = widget.count == 0 ? '' : '${widget.count}';
    if (_controller.text != text &&
        int.tryParse(_controller.text) != widget.count) {
      _controller.text = text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final next = (widget.count + delta).clamp(0, 99999);
    _controller.text = next == 0 ? '' : '$next';
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final value = Money(widget.denomination);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(value.format())),
          IconButton(
            key: const Key('denomination-minus'),
            onPressed: widget.count > 0 ? () => _step(-1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 64,
            child: TextField(
              key: const Key('denomination-count'),
              controller: _controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(isDense: true, hintText: '0'),
              onChanged: (v) => widget.onChanged(int.tryParse(v) ?? 0),
            ),
          ),
          IconButton(
            key: const Key('denomination-plus'),
            onPressed: () => _step(1),
            icon: const Icon(Icons.add_circle_outline),
          ),
          Expanded(
            child: Text(
              (value * widget.count).format(),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
