import 'package:cashiera/app/app_mode.dart';
import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/toasts.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/money_input.dart';
import 'package:cashiera/features/back_office/data/pos_admin_repository.dart';
import 'package:cashiera/features/back_office/presentation/back_office_providers.dart';
import 'package:cashiera/features/back_office/presentation/promotions_screen.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Which lines a rule targets, while editing.
class ScopeDraft {
  new all() : all = true;

  new from(PromoScope s)
    : all = s.all,
      categories = {...s.categoryIds},
      products = {...s.productIds},
      variants = {...s.variantIds};

  bool all;
  Set<String> categories = {};
  Set<String> products = {};
  Set<String> variants = {};

  bool get isEmpty =>
      !all && categories.isEmpty && products.isEmpty && variants.isEmpty;

  PromoScope toScope() => all
      ? const PromoScope.all()
      : PromoScope(
          categoryIds: {...categories},
          productIds: {...products},
          variantIds: {...variants},
        );
}

class TierDraft {
  new(this.minQuantity, this.discount);
  int? minQuantity;
  DiscountSpec? discount;
}

class ComponentDraft {
  new(this.scope, this.quantity);
  ScopeDraft scope;
  int? quantity;
}

/// A promotion while it is edited; [toPromotion] checks the same rules as
/// `app.promotion_rules_valid` and names the first problem.
class PromotionDraft {
  new empty()
    : id = const Uuid().v7(),
      isNew = true,
      type = PromoType.happyHour;

  new from(Promotion p)
    : id = p.id,
      isNew = false,
      name = p.name,
      description = p.description ?? '',
      type = p.type,
      priority = p.priority,
      isStackable = p.isStackable,
      isActive = p.isActive,
      storeIds = {...p.storeIds},
      startsAt = p.startsAt,
      endsAt = p.endsAt,
      days = {...?p.daysOfWeek},
      startMinute = p.startMinute,
      endMinute = p.endMinute {
    switch (p.rules) {
      case HappyHourRules(:final scope, :final discount):
        this.scope = ScopeDraft.from(scope);
        this.discount = discount;
      case final BuyXGetYRules r:
        buyScope = ScopeDraft.from(r.buyScope);
        buyQuantity = r.buyQuantity;
        getScope = ScopeDraft.from(r.getScope);
        getQuantity = r.getQuantity;
        discount = r.getDiscount;
        maxApplications = r.maxApplications;
      case final BundleRules r:
        components = [
          for (final c in r.components)
            ComponentDraft(ScopeDraft.from(c.scope), c.quantity),
        ];
        bundlePrice = r.bundlePrice;
        maxApplications = r.maxApplications;
      case final TieredQtyRules r:
        scope = ScopeDraft.from(r.scope);
        tiers = [for (final t in r.tiers) TierDraft(t.minQuantity, t.discount)];
      case final MinPurchaseRules r:
        minSubtotal = r.minSubtotal;
        discount = r.discount;
        maxDiscount = r.maxDiscount;
    }
  }

  final String id;
  final bool isNew;
  String name = '';
  String description = '';
  PromoType type;
  int priority = 100;
  bool isStackable = false;
  bool isActive = true;
  Set<String> storeIds = {};
  DateTime? startsAt;
  DateTime? endsAt;
  Set<int> days = {};
  int? startMinute;
  int? endMinute;

  ScopeDraft scope = ScopeDraft.all();
  DiscountSpec? discount = const PercentDiscount(1000);
  ScopeDraft buyScope = ScopeDraft.all();
  int? buyQuantity = 2;
  ScopeDraft getScope = ScopeDraft.all();
  int? getQuantity = 1;
  int? maxApplications;
  List<ComponentDraft> components = [
    ComponentDraft(ScopeDraft.all(), 1),
    ComponentDraft(ScopeDraft.all(), 1),
  ];
  int? bundlePrice;
  List<TierDraft> tiers = [TierDraft(12, const PercentDiscount(500))];
  int? minSubtotal;
  int? maxDiscount;

  /// The promotion, or the first problem (as a message key the screen
  /// translates).
  (Promotion?, PromoProblem?) toPromotion() {
    if (name.trim().isEmpty) return (null, PromoProblem.name);
    if ((startMinute == null) != (endMinute == null)) {
      return (null, PromoProblem.window);
    }
    if (type == PromoType.happyHour && startMinute == null) {
      return (null, PromoProblem.happyHourWindow);
    }
    if (startsAt != null && endsAt != null && !endsAt!.isAfter(startsAt!)) {
      return (null, PromoProblem.period);
    }
    final PromoRules rules;
    switch (type) {
      case PromoType.happyHour:
        if (scope.isEmpty) return (null, PromoProblem.scope);
        if (discount == null) return (null, PromoProblem.discount);
        rules = HappyHourRules(scope: scope.toScope(), discount: discount!);
      case PromoType.buyXGetY:
        if (buyScope.isEmpty || getScope.isEmpty) {
          return (null, PromoProblem.scope);
        }
        if ((buyQuantity ?? 0) < 1 || (getQuantity ?? 0) < 1) {
          return (null, PromoProblem.quantity);
        }
        if (discount == null) return (null, PromoProblem.discount);
        rules = BuyXGetYRules(
          buyScope: buyScope.toScope(),
          buyQuantity: buyQuantity!,
          getScope: getScope.toScope(),
          getQuantity: getQuantity!,
          getDiscount: discount!,
          maxApplications: maxApplications,
        );
      case PromoType.bundle:
        if (components.length < 2) return (null, PromoProblem.components);
        if (components.any((c) => c.scope.isEmpty)) {
          return (null, PromoProblem.scope);
        }
        if (components.any((c) => (c.quantity ?? 0) < 1)) {
          return (null, PromoProblem.quantity);
        }
        if ((bundlePrice ?? 0) < 1) return (null, PromoProblem.price);
        rules = BundleRules(
          components: [
            for (final c in components)
              BundleComponent(scope: c.scope.toScope(), quantity: c.quantity!),
          ],
          bundlePrice: bundlePrice!,
          maxApplications: maxApplications,
        );
      case PromoType.tieredQty:
        if (scope.isEmpty) return (null, PromoProblem.scope);
        if (tiers.isEmpty) return (null, PromoProblem.tiers);
        var previous = 0;
        for (final t in tiers) {
          if (t.discount == null) return (null, PromoProblem.discount);
          if ((t.minQuantity ?? 0) <= previous) {
            return (null, PromoProblem.tiers);
          }
          previous = t.minQuantity!;
        }
        rules = TieredQtyRules(
          scope: scope.toScope(),
          tiers: [
            for (final t in tiers)
              QtyTier(minQuantity: t.minQuantity!, discount: t.discount!),
          ],
        );
      case PromoType.minPurchase:
        if ((minSubtotal ?? 0) < 1) return (null, PromoProblem.price);
        if (discount == null) return (null, PromoProblem.discount);
        rules = MinPurchaseRules(
          minSubtotal: minSubtotal!,
          discount: discount!,
          maxDiscount: discount is PercentDiscount ? maxDiscount : null,
        );
    }
    return (
      Promotion(
        id: id,
        name: name.trim(),
        description: description.trim().isEmpty ? null : description.trim(),
        type: type,
        rules: rules,
        priority: priority,
        isStackable: isStackable,
        startsAt: startsAt,
        endsAt: endsAt,
        daysOfWeek: days.isEmpty ? null : (days.toList()..sort()),
        startMinute: startMinute,
        endMinute: endMinute,
        isActive: isActive,
        storeIds: {...storeIds},
      ),
      null,
    );
  }
}

enum PromoProblem {
  name,
  window,
  happyHourWindow,
  period,
  scope,
  discount,
  quantity,
  components,
  price,
  tiers,
}

String promoProblemText(AppLocalizations l10n, PromoProblem p) => switch (p) {
  PromoProblem.name => l10n.promoProblemName,
  PromoProblem.window => l10n.promoProblemWindow,
  PromoProblem.happyHourWindow => l10n.promoProblemHappyHour,
  PromoProblem.period => l10n.promoPeriodInvalid,
  PromoProblem.scope => l10n.promoProblemScope,
  PromoProblem.discount => l10n.discountInvalid,
  PromoProblem.quantity => l10n.promoProblemQuantity,
  PromoProblem.components => l10n.promoProblemComponents,
  PromoProblem.price => l10n.validationMoney,
  PromoProblem.tiers => l10n.promoProblemTiers,
};

class PromotionEditorScreen extends ConsumerStatefulWidget {
  const new({required this.promotionId, super.key});

  /// `new` for a new promotion.
  final String promotionId;

  @override
  ConsumerState<PromotionEditorScreen> createState() =>
      _PromotionEditorScreenState();
}

class _PromotionEditorScreenState extends ConsumerState<PromotionEditorScreen> {
  PromotionDraft? _draft;
  bool _saving = false;

  Future<void> _save() async {
    final l10n = context.l10n;
    final (promotion, problem) = _draft!.toPromotion();
    if (problem != null) {
      AppToast.error(context, promoProblemText(l10n, problem));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(posAdminProvider).savePromotion(promotion!);
      ref.invalidate(adminPromotionsProvider);
      if (!mounted) return;
      AppToast.success(context, l10n.commonSaved);
      context.go(AppRoutes.adminPromotions);
    } on BackendException catch (e) {
      if (mounted) AppToast.error(context, l10n.commonError(e.message));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_draft == null) {
      if (widget.promotionId == 'new') {
        _draft = PromotionDraft.empty();
      } else {
        final all = ref.watch(adminPromotionsProvider);
        final found = all.value?.where((p) => p.id == widget.promotionId);
        if (found == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (found.isEmpty) return Center(child: Text(l10n.promoMissing));
        _draft = PromotionDraft.from(found.first);
      }
    }
    final d = _draft!;
    final options = ref.watch(promotionScopeOptionsProvider).value;
    final stores = ref.watch(backOfficeStoresProvider).value ?? const [];
    final date = DateFormat.yMMMd();
    final time = MaterialLocalizations.of(context);
    String minuteText(int? m) => m == null
        ? '--:--'
        : time.formatTimeOfDay(
            TimeOfDay(hour: m ~/ 60, minute: m % 60),
            alwaysUse24HourFormat: true,
          );

    Future<void> pickTime({required bool start}) async {
      final current = start ? d.startMinute : d.endMinute;
      final picked = await showTimePicker(
        context: context,
        initialTime: current == null
            ? TimeOfDay(hour: start ? 14 : 16, minute: 0)
            : TimeOfDay(hour: current ~/ 60, minute: current % 60),
      );
      if (picked == null) return;
      setState(() {
        final m = picked.hour * 60 + picked.minute;
        start ? d.startMinute = m : d.endMinute = m;
      });
    }

    Future<void> pickDate({required bool start}) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: (start ? d.startsAt : d.endsAt)?.toLocal() ?? now,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 5),
      );
      if (picked == null) return;
      setState(() {
        if (start) {
          d.startsAt = picked;
        } else {
          d.endsAt = picked.add(const Duration(days: 1));
        }
      });
    }

    Widget section(String title, List<Widget> children) => Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final (i, c) in children.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              c,
            ],
          ],
        ),
      ),
    );

    Widget intField(
      String label,
      int? value,
      ValueChanged<int?> onChanged, {
      Key? key,
      bool money = false,
      String? helper,
    }) => TextFormField(
      key: key,
      initialValue: value?.toString() ?? '',
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        prefixText: money ? 'Rp ' : null,
      ),
      onChanged: (v) => onChanged(
        v.trim().isEmpty ? null : (money ? parseRupiah(v) : int.tryParse(v)),
      ),
    );

    final rules = switch (d.type) {
      PromoType.happyHour => [
        ScopeField(
          label: l10n.promoScope,
          scope: d.scope,
          options: options,
          onChanged: () => setState(() {}),
        ),
        DiscountField(
          key: const Key('promo-discount'),
          label: l10n.promoDiscountPerUnit,
          value: d.discount,
          onChanged: (v) => d.discount = v,
        ),
      ],
      PromoType.buyXGetY => [
        ScopeField(
          label: l10n.promoBuyScope,
          scope: d.buyScope,
          options: options,
          onChanged: () => setState(() {}),
        ),
        intField(
          l10n.promoBuyQuantity,
          d.buyQuantity,
          (v) => d.buyQuantity = v,
        ),
        ScopeField(
          label: l10n.promoGetScope,
          scope: d.getScope,
          options: options,
          onChanged: () => setState(() {}),
        ),
        intField(
          l10n.promoGetQuantity,
          d.getQuantity,
          (v) => d.getQuantity = v,
        ),
        DiscountField(
          label: l10n.promoGetDiscount,
          value: d.discount,
          onChanged: (v) => d.discount = v,
        ),
        intField(
          l10n.promoMaxApplications,
          d.maxApplications,
          (v) => d.maxApplications = v,
          helper: l10n.promoUnlimitedHint,
        ),
      ],
      PromoType.bundle => [
        for (final (i, c) in d.components.indexed)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ScopeField(
                  label: l10n.promoComponent(i + 1),
                  scope: c.scope,
                  options: options,
                  onChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 96,
                child: intField(
                  l10n.promoQty,
                  c.quantity,
                  (v) => c.quantity = v,
                  key: ValueKey('component-qty-$i-${d.components.length}'),
                ),
              ),
              IconButton(
                onPressed: d.components.length > 2
                    ? () => setState(() => d.components.removeAt(i))
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(
              () => d.components.add(ComponentDraft(ScopeDraft.all(), 1)),
            ),
            icon: const Icon(Icons.add),
            label: Text(l10n.promoAddComponent),
          ),
        ),
        intField(
          l10n.promoBundlePrice,
          d.bundlePrice,
          (v) => d.bundlePrice = v,
          money: true,
        ),
        intField(
          l10n.promoMaxApplications,
          d.maxApplications,
          (v) => d.maxApplications = v,
          helper: l10n.promoUnlimitedHint,
        ),
      ],
      PromoType.tieredQty => [
        ScopeField(
          label: l10n.promoScope,
          scope: d.scope,
          options: options,
          onChanged: () => setState(() {}),
        ),
        for (final (i, t) in d.tiers.indexed)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: intField(
                  l10n.promoMinQuantity,
                  t.minQuantity,
                  (v) => t.minQuantity = v,
                  key: ValueKey('tier-min-$i-${d.tiers.length}'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DiscountField(
                  key: ValueKey('tier-discount-$i-${d.tiers.length}'),
                  label: l10n.promoDiscountPerUnit,
                  value: t.discount,
                  onChanged: (v) => t.discount = v,
                ),
              ),
              IconButton(
                onPressed: d.tiers.length > 1
                    ? () => setState(() => d.tiers.removeAt(i))
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(
              () => d.tiers.add(
                TierDraft(
                  (d.tiers.lastOrNull?.minQuantity ?? 0) + 12,
                  const PercentDiscount(1000),
                ),
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text(l10n.promoAddTier),
          ),
        ),
      ],
      PromoType.minPurchase => [
        intField(
          l10n.promoMinSubtotal,
          d.minSubtotal,
          (v) => d.minSubtotal = v,
          money: true,
          key: const Key('promo-min-subtotal'),
        ),
        DiscountField(
          label: l10n.promoBillDiscount,
          value: d.discount,
          onChanged: (v) => setState(() => d.discount = v),
        ),
        if (d.discount is PercentDiscount)
          intField(
            l10n.voucherMaxDiscountLabel,
            d.maxDiscount,
            (v) => d.maxDiscount = v,
            money: true,
          ),
      ],
    };

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          96,
        ),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.go(AppRoutes.adminPromotions),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  d.isNew ? l10n.promoNew : d.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          section(l10n.promoGeneral, [
            TextFormField(
              key: const Key('promo-name'),
              initialValue: d.name,
              decoration: InputDecoration(labelText: l10n.promoName),
              onChanged: (v) => d.name = v,
            ),
            TextFormField(
              initialValue: d.description,
              decoration: InputDecoration(labelText: l10n.promoDescription),
              onChanged: (v) => d.description = v,
            ),
            DropdownButtonFormField<PromoType>(
              key: const Key('promo-type'),
              initialValue: d.type,
              decoration: InputDecoration(labelText: l10n.promoType),
              items: [
                for (final t in PromoType.values)
                  DropdownMenuItem(
                    value: t,
                    child: Text(promoTypeLabel(l10n, t)),
                  ),
              ],
              onChanged: d.isNew ? (t) => setState(() => d.type = t!) : null,
            ),
            Row(
              children: [
                SizedBox(
                  width: 140,
                  child: intField(
                    l10n.promoPriority,
                    d.priority,
                    (v) => d.priority = v ?? 100,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(l10n.promoPriorityHint)),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.promoStackable),
              subtitle: Text(l10n.promoStackableHint),
              value: d.isStackable,
              onChanged: (v) => setState(() => d.isStackable = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.commonActive),
              value: d.isActive,
              onChanged: (v) => setState(() => d.isActive = v),
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          section(l10n.promoRules, rules),
          const SizedBox(height: AppSpacing.md),
          section(l10n.promoWhen, [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.event, size: 18),
                  label: Text(
                    d.startsAt == null
                        ? l10n.promoStartsAnytime
                        : l10n.promoStarts(date.format(d.startsAt!.toLocal())),
                  ),
                  onPressed: () => pickDate(start: true),
                ),
                ActionChip(
                  avatar: const Icon(Icons.event_busy, size: 18),
                  label: Text(
                    d.endsAt == null
                        ? l10n.promoEndsNever
                        : l10n.promoEnds(
                            date.format(
                              d.endsAt!.toLocal().subtract(
                                const Duration(days: 1),
                              ),
                            ),
                          ),
                  ),
                  onPressed: () => pickDate(start: false),
                ),
                if (d.startsAt != null || d.endsAt != null)
                  TextButton(
                    onPressed: () => setState(() {
                      d
                        ..startsAt = null
                        ..endsAt = null;
                    }),
                    child: Text(l10n.promoClearPeriod),
                  ),
              ],
            ),
            Text(l10n.promoDays),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    label: Text(
                      DateFormat.E().format(DateTime(2026, 11, 1 + day)),
                    ),
                    selected: d.days.contains(day),
                    onSelected: (on) => setState(
                      () => on ? d.days.add(day) : d.days.remove(day),
                    ),
                  ),
              ],
            ),
            Text(d.days.isEmpty ? l10n.promoEveryDay : ''),
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l10n.promoHours),
                ActionChip(
                  key: const Key('promo-start-time'),
                  label: Text(minuteText(d.startMinute)),
                  onPressed: () => pickTime(start: true),
                ),
                const Text('–'),
                ActionChip(
                  key: const Key('promo-end-time'),
                  label: Text(minuteText(d.endMinute)),
                  onPressed: () => pickTime(start: false),
                ),
                if (d.startMinute != null || d.endMinute != null)
                  TextButton(
                    onPressed: () => setState(() {
                      d
                        ..startMinute = null
                        ..endMinute = null;
                    }),
                    child: Text(l10n.promoAllDay),
                  ),
              ],
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          section(l10n.promoStores, [
            Text(d.storeIds.isEmpty ? l10n.promoAllStores : ''),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final s in stores)
                  FilterChip(
                    label: Text('${s.code} · ${s.name}'),
                    selected: d.storeIds.contains(s.id),
                    onSelected: (on) => setState(
                      () => on ? d.storeIds.add(s.id) : d.storeIds.remove(s.id),
                    ),
                  ),
              ],
            ),
          ]),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('promo-save'),
        onPressed: _saving ? null : _save,
        icon: const Icon(Icons.save_outlined),
        label: Text(l10n.commonSave),
      ),
    );
  }
}

/// A percent-or-rupiah discount input; reports null while the text is
/// not a valid discount.
class DiscountField extends StatefulWidget {
  const new({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final DiscountSpec? value;
  final ValueChanged<DiscountSpec?> onChanged;

  @override
  State<DiscountField> createState() => _DiscountFieldState();
}

class _DiscountFieldState extends State<DiscountField> {
  late bool _percent = widget.value is! FixedDiscount;
  late final _text = TextEditingController(
    text: switch (widget.value) {
      PercentDiscount(:final bps) => bpsToPercentText(bps),
      FixedDiscount(:final amount) => '$amount',
      null => '',
    },
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  DiscountSpec? _parse() {
    if (_percent) {
      final bps = parsePercentBps(_text.text);
      return bps == null ? null : PercentDiscount(bps);
    }
    final amount = parseRupiah(_text.text);
    return amount == null || amount == 0 ? null : FixedDiscount(amount);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('%')),
            ButtonSegment(value: false, label: Text('Rp')),
          ],
          selected: {_percent},
          onSelectionChanged: (s) {
            setState(() => _percent = s.first);
            widget.onChanged(_parse());
          },
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: TextFormField(
            controller: _text,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              labelText: widget.label,
              suffixText: _percent ? '%' : null,
              prefixText: _percent ? null : 'Rp ',
            ),
            validator: (_) => _parse() == null ? l10n.discountInvalid : null,
            onChanged: (_) => widget.onChanged(_parse()),
          ),
        ),
      ],
    );
  }
}

/// Shows what a scope covers; tapping opens the picker.
class ScopeField extends StatelessWidget {
  const new({
    required this.label,
    required this.scope,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final String label;
  final ScopeDraft scope;
  final ScopeOptions? options;
  final VoidCallback onChanged;

  String _summary(AppLocalizations l10n) {
    if (scope.all) return l10n.promoScopeAll;
    final o = options;
    String names(Set<String> ids, List<ScopeOption>? list) => ids
        .map((id) => list?.where((x) => x.id == id).firstOrNull?.label ?? '?')
        .join(', ');
    final categories = names(scope.categories, o?.categories);
    return [
      if (scope.categories.isNotEmpty)
        '${l10n.promoScopeCategories}: $categories',
      if (scope.products.isNotEmpty)
        '${l10n.promoScopeProducts}: ${names(scope.products, o?.products)}',
      if (scope.variants.isNotEmpty)
        '${l10n.promoScopeVariants}: ${names(scope.variants, o?.variants)}',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        errorText: scope.isEmpty ? l10n.promoProblemScope : null,
      ),
      child: InkWell(
        onTap: options == null
            ? null
            : () async {
                await showDialog<void>(
                  context: context,
                  builder: (_) => _ScopeDialog(scope: scope, options: options!),
                );
                onChanged();
              },
        child: Row(
          children: [
            Expanded(child: Text(_summary(l10n))),
            const Icon(Icons.edit_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ScopeDialog extends StatefulWidget {
  const new({required this.scope, required this.options});

  final ScopeDraft scope;
  final ScopeOptions options;

  @override
  State<_ScopeDialog> createState() => _ScopeDialogState();
}

class _ScopeDialogState extends State<_ScopeDialog> {
  int _tab = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = widget.scope;
    final (list, selected) = switch (_tab) {
      1 => (widget.options.products, s.products),
      2 => (widget.options.variants, s.variants),
      _ => (widget.options.categories, s.categories),
    };
    final q = _query.toLowerCase();
    final shown = list
        .where(
          (o) =>
              q.isEmpty ||
              o.label.toLowerCase().contains(q) ||
              (o.detail?.toLowerCase().contains(q) ?? false),
        )
        .toList();

    return AlertDialog(
      title: Text(l10n.promoScope),
      content: SizedBox(
        width: 480,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              key: const Key('scope-all'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.promoScopeAll),
              value: s.all,
              onChanged: (v) => setState(() => s.all = v),
            ),
            if (!s.all) ...[
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: Text(l10n.promoScopeCategories),
                  ),
                  ButtonSegment(value: 1, label: Text(l10n.promoScopeProducts)),
                  ButtonSegment(value: 2, label: Text(l10n.promoScopeVariants)),
                ],
                selected: {_tab},
                onSelectionChanged: (v) => setState(() => _tab = v.first),
              ),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.commonSearch,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final o in shown)
                      CheckboxListTile(
                        value: selected.contains(o.id),
                        title: Text(o.label),
                        subtitle: o.detail == null ? null : Text(o.detail!),
                        onChanged: (on) => setState(
                          () => on ?? false
                              ? selected.add(o.id)
                              : selected.remove(o.id),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonDone),
        ),
      ],
    );
  }
}
