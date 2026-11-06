import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/auth/pin_verifier.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/empty_state.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          [
            session?.store?.store.name,
            if (session?.device != null)
              l10n.posTerminal(session!.device!.deviceCode),
          ].nonNulls.join(' · '),
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: TerminalStatusChip(),
          ),
          IconButton(
            tooltip: l10n.lockRefreshStaff,
            onPressed: _refreshing ? null : _refreshRoster,
            icon: const Icon(Icons.sync_alt),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: context.isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 65, child: _titled(l10n.lockTitle, grid)),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(flex: 35, child: Center(child: pad)),
                  ],
                )
              : _selected == null
              ? _titled(l10n.lockTitle, grid)
              : Center(child: pad),
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
    final scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.1,
      ),
      itemCount: staff.length,
      itemBuilder: (context, i) {
        final member = staff[i];
        final selected = member.employeeId == selectedId;
        return Card(
          key: Key('staff-${member.employeeId}'),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: BorderSide(
              color: selected ? AppColors.primary : scheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () => onSelected(member),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      member.initials,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
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
              Text(
                l10n.lockEnterPin(staff.fullName),
                style: Theme.of(context).textTheme.titleMedium,
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
