import 'dart:async';

import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/printing/printer_setting.dart';
import 'package:cashiera/core/printing/printer_transport.dart';
import 'package:cashiera/core/printing/slips.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/features/printing/print_actions.dart';
import 'package:cashiera/features/sell/presentation/sell_providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

String connectionLabel(AppLocalizations l10n, PrinterConnection c) =>
    switch (c) {
      PrinterConnection.ble => l10n.printerBluetooth,
      PrinterConnection.usb => l10n.printerUsb,
      PrinterConnection.network => l10n.printerNetwork,
    };

/// Sets up the terminal's receipt printer: find a Bluetooth or USB printer
/// or type a network address, paper width, drawer and auto-print, test.
class PrinterScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends ConsumerState<PrinterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  PrinterConnection _connection = PrinterConnection.ble;
  int _paperMm = 58;
  bool _opensDrawer = false;
  bool _autoPrint = false;
  bool _loaded = false;
  bool _busy = false;
  bool _searching = false;
  List<DiscoveredPrinter>? _found;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final current = await ref.read(printerRepositoryProvider).current();
    final paper = ref.read(posConfigProvider).value?.paperMm;
    if (!mounted) return;
    setState(() {
      if (current != null) {
        _name.text = current.name;
        _address.text = current.address;
        _connection = current.connection;
        _paperMm = current.paperMm;
        _opensDrawer = current.opensCashDrawer;
        _autoPrint = current.autoPrint;
      } else if (paper != null) {
        _paperMm = paper;
      }
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  PrinterSetting? _setting() {
    if (!_form.currentState!.validate()) return null;
    final address = _address.text.trim();
    return PrinterSetting(
      name: _name.text.trim().isEmpty ? address : _name.text.trim(),
      connection: _connection,
      address: address,
      paperMm: _paperMm,
      opensCashDrawer: _opensDrawer,
      autoPrint: _autoPrint,
    );
  }

  Future<void> _search() async {
    final l10n = context.l10n;
    setState(() {
      _searching = true;
      _found = null;
    });
    try {
      final found = await ref.read(printerTransportProvider).discover();
      if (mounted) {
        setState(
          () => _found = [
            for (final p in found)
              if (p.connection == _connection) p,
          ],
        );
      }
    } on PrinterException catch (e) {
      if (mounted) AppToast.error(context, printerErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _save() async {
    final setting = _setting();
    if (setting == null) return;
    await ref.read(printerRepositoryProvider).save(setting);
    if (mounted) AppToast.success(context, context.l10n.printerSaved);
  }

  Future<void> _test() async {
    final l10n = context.l10n;
    final setting = _setting();
    if (setting == null) return;
    setState(() => _busy = true);
    try {
      final columns = EscPosEncoder.forPaper(setting.paperMm).columns;
      await ref
          .read(printerServiceProvider)
          .print(
            testPageDocument(
              title: l10n.printerTestTitle,
              lines: [
                setting.name,
                [
                  connectionLabel(l10n, setting.connection),
                  setting.address,
                ].join(' · '),
                l10n.printerTestLine(setting.paperMm, columns),
              ],
              columns: columns,
            ),
            using: setting,
          );
      if (mounted) AppToast.success(context, l10n.printerTestSent);
    } on PrinterException catch (e) {
      if (mounted) AppToast.error(context, printerErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    await ref.read(printerRepositoryProvider).remove();
    if (!mounted) return;
    setState(() {
      _name.clear();
      _address.clear();
      _found = null;
    });
    AppToast.success(context, context.l10n.printerRemoved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = ref.watch(receiptPrinterProvider).value;
    final canDiscover = ref.watch(printerTransportProvider).canDiscover;
    final network = _connection == PrinterConnection.network;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.pos)),
        title: Text(l10n.printerTitle),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _form,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.print_outlined),
                          title: Text(current?.name ?? l10n.printerNone),
                          subtitle: current == null
                              ? null
                              : Text(
                                  '${connectionLabel(l10n, current.connection)}'
                                  ' · ${current.address} · '
                                  '${l10n.printerPaperMm(current.paperMm)}',
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(l10n.printerConnection),
                      const SizedBox(height: AppSpacing.xs),
                      SegmentedButton<PrinterConnection>(
                        segments: [
                          for (final c in PrinterConnection.values)
                            ButtonSegment(
                              value: c,
                              label: Text(connectionLabel(l10n, c)),
                            ),
                        ],
                        selected: {_connection},
                        onSelectionChanged: (v) => setState(() {
                          _connection = v.single;
                          _found = null;
                        }),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (!network) ...[
                        if (canDiscover)
                          OutlinedButton.icon(
                            key: const Key('printer-search'),
                            onPressed: _searching ? null : _search,
                            icon: _searching
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.search),
                            label: Text(
                              _searching
                                  ? l10n.printerSearching
                                  : l10n.printerSearch,
                            ),
                          )
                        else
                          Text(l10n.printerDiscoverUnsupported),
                        if (_found != null && _found!.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(l10n.printerFoundNone),
                          ),
                        for (final p in _found ?? const <DiscoveredPrinter>[])
                          ListTile(
                            key: Key('printer-found-${p.address}'),
                            leading: Icon(
                              p.address == _address.text
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                            ),
                            title: Text(p.name),
                            subtitle: Text(p.address),
                            onTap: () => setState(() {
                              _name.text = p.name;
                              _address.text = p.address;
                            }),
                          ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      TextFormField(
                        key: const Key('printer-address'),
                        controller: _address,
                        decoration: InputDecoration(
                          labelText: l10n.printerAddress,
                          helperText: network ? l10n.printerAddressHint : null,
                        ),
                        validator: (v) {
                          final text = (v ?? '').trim();
                          if (text.isEmpty) return l10n.printerAddressRequired;
                          if (network &&
                              PrinterSetting.parseNetworkAddress(text) ==
                                  null) {
                            return l10n.printInvalidAddress;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        key: const Key('printer-name'),
                        controller: _name,
                        decoration: InputDecoration(
                          labelText: l10n.printerName,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(l10n.printerPaper),
                      const SizedBox(height: AppSpacing.xs),
                      SegmentedButton<int>(
                        segments: [
                          for (final mm in const [58, 80])
                            ButtonSegment(
                              value: mm,
                              label: Text(l10n.printerPaperMm(mm)),
                            ),
                        ],
                        selected: {_paperMm},
                        onSelectionChanged: (v) =>
                            setState(() => _paperMm = v.single),
                      ),
                      SwitchListTile(
                        key: const Key('printer-drawer'),
                        contentPadding: EdgeInsets.zero,
                        value: _opensDrawer,
                        onChanged: (v) => setState(() => _opensDrawer = v),
                        title: Text(l10n.printerOpensDrawer),
                      ),
                      SwitchListTile(
                        key: const Key('printer-auto'),
                        contentPadding: EdgeInsets.zero,
                        value: _autoPrint,
                        onChanged: (v) => setState(() => _autoPrint = v),
                        title: Text(l10n.printerAutoPrint),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: [
                          FilledButton.icon(
                            key: const Key('printer-save'),
                            onPressed: _busy ? null : _save,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(l10n.commonSave),
                          ),
                          OutlinedButton.icon(
                            key: const Key('printer-test'),
                            onPressed: _busy ? null : _test,
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: Text(l10n.printerTest),
                          ),
                          if (current != null)
                            TextButton.icon(
                              key: const Key('printer-remove'),
                              onPressed: _busy ? null : _remove,
                              icon: const Icon(Icons.delete_outline),
                              label: Text(l10n.printerRemove),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
