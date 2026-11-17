import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/auth/pin_verifier.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/data_display.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
import 'package:cashiera/core/design_system/widgets/flow.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera/core/design_system/widgets/pin_pad.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera/core/session/session_controller.dart';
import 'package:cashiera/features/pos_home/presentation/widgets/terminal_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Fast staff switching: tap your name, enter your PIN. Works offline.
class PinLockScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  StaffMember? _selected;
  String? _message;
  bool _checking = false;
  bool _refreshing = false;

  Future<void> _verify(String pin) async {
    final staff = _selected;
    if (staff == null) return;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    setState(() {
      _checking = true;
      _message = null;
    });
    final result = await ref
        .read(pinVerifierProvider)
        .verify(staff.employeeId, pin);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _message = switch (result) {
        PinOk() => null,
        PinMismatch(:final attemptsLeft) => l10n.pinWrong(attemptsLeft),
        PinLocked(:final until) => l10n.pinLocked(
          DateFormat.Hm(locale).format(until.toLocal()),
        ),
        PinNoPin() => l10n.pinNoPin,
      };
    });
    if (result case PinOk(:final staff)) {
      ref.read(sessionControllerProvider.notifier).unlock(staff);
    }
  }

  Future<void> _refreshRoster() async {
    final l10n = context.l10n;
    setState(() => _refreshing = true);
    try {
      await ref.read(sessionControllerProvider.notifier).refreshRoster();
      if (mounted) AppToast.success(context, l10n.lockStaffRefreshed);
    } on Exception catch (e) {
      if (mounted) AppToast.error(context, l10n.commonError('$e'));
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(sessionControllerProvider).value;
    final roster = ref.watch(rosterProvider);
    final staffList = roster.value ?? const <StaffMember>[];

    final grid = Skeletonizer(
      enabled: roster.isLoading,
      child: staffList.isEmpty && !roster.isLoading
          ? EmptyState(
              icon: Icons.groups_outlined,
              message: l10n.lockNoStaff,
              action: _refreshButton(l10n),
            )
          : _StaffGrid(
              staff: roster.isLoading ? _placeholders : staffList,
              selectedId: _selected?.employeeId,
              onSelected: (s) => setState(() {
                _selected = s;
                _message = null;
              }),
            ),
    );

    final pad = _selected == null
        ? const SizedBox.shrink()
        : _PinPanel(
            staff: _selected!,
            message: _message,
            checking: _checking,
            onSubmitted: _verify,
            onBack: context.isWide
                ? null
                : () => setState(() => _selected = null),
          );

    final header = GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          if (context.isWide) ...[
            const AppLogoTile(size: 40),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Text(
              [
                session?.store?.store.name,
                if (session?.device != null)
                  l10n.posTerminal(session!.device!.deviceCode),
              ].nonNulls.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Flexible(child: TerminalStatusChip()),
          IconButton(
            tooltip: l10n.lockRefreshStaff,
            onPressed: _refreshing ? null : _refreshRoster,
            icon: const Icon(Icons.sync_alt),
          ),
        ],
      ),
    );
    Widget pane(Widget child) =>
        GlassCard(level: GlassLevel.solid, child: child);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: context.isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 65,
                            child: pane(_titled(l10n.lockTitle, grid)),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(flex: 35, child: pane(Center(child: pad))),
                        ],
                      )
                    : pane(
                        _selected == null
                            ? _titled(l10n.lockTitle, grid)
                            : Center(child: pad),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _refreshButton(AppLocalizations l10n) => OutlinedButton.icon(
    onPressed: _refreshing ? null : _refreshRoster,
    icon: const Icon(Icons.sync_alt),
    label: Text(l10n.lockRefreshStaff),
  );

  Widget _titled(String title, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: AppSpacing.lg),
      Expanded(child: child),
    ],
  );

  static final List<StaffMember> _placeholders = List.generate(
    6,
    (i) => StaffMember(
      employeeId: 'placeholder-$i',
      fullName: 'Nama Karyawan',
      roleCode: 'cashier',
      permissions: const {},
      pinHash: null,
    ),
  );
}

class _StaffGrid extends StatelessWidget {
  const new({
    required this.staff,
    required this.selectedId,
    required this.onSelected,
  });

  final List<StaffMember> staff;
  final String? selectedId;
  final ValueChanged<StaffMember> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
      ),
      itemCount: staff.length,
      itemBuilder: (context, i) {
        final member = staff[i];
        final selected = member.employeeId == selectedId;
        return Container(
          key: Key('staff-${member.employeeId}'),
          foregroundDecoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                  border: Border.all(color: AppColors.primary, width: 2),
                )
              : null,
          child: GlassCard(
            level: selected ? GlassLevel.solid : GlassLevel.regular,
            radius: AppRadius.tile,
            padding: const EdgeInsets.all(AppSpacing.md),
            onTap: () => onSelected(member),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InitialsAvatar(name: member.fullName, size: 44),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  member.fullName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PinPanel extends StatelessWidget {
  const new({
    required this.staff,
    required this.message,
    required this.checking,
    required this.onSubmitted,
    required this.onBack,
  });

  final StaffMember staff;
  final String? message;
  final bool checking;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
              Flexible(
                child: Text(
                  l10n.lockEnterPin(staff.fullName),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSwitcher(
            duration: AppMotion.normal,
            child: message == null
                ? const SizedBox(height: 24)
                : Text(
                    message!,
                    key: ValueKey(message),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          PinPad(
            key: ValueKey(staff.employeeId),
            enabled: !checking,
            onSubmitted: onSubmitted,
          ),
          if (checking) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
