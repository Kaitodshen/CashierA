import 'package:cashiera/core/design_system/tokens.dart';
import 'package:cashiera/core/design_system/widgets/glass.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/material.dart';

/// The glass header of every page: title, subtitle, a status line and
/// actions. Actions move under the title below 720 px.
class PageHeader extends StatelessWidget {
  const new({
    required this.title,
    this.subtitle,
    this.status,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? status;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: theme.textTheme.headlineLarge),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
        if (status != null) ...[const SizedBox(height: AppSpacing.sm), status!],
      ],
    );
    final buttons = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: actions,
    );
    return GlassCard(
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth < 720 || actions.isEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  texts,
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    buttons,
                  ],
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: texts),
                  const SizedBox(width: AppSpacing.lg),
                  Flexible(child: buttons),
                ],
              ),
      ),
    );
  }
}

/// Tone of a status chip or stock bar.
enum StatusTone {
  success(AppColors.success, Color(0xFFD1FAE5), Color(0xFF047857)),
  warning(AppColors.warning, AppColors.warningSoft, AppColors.warningText),
  error(AppColors.error, Color(0xFFFEE2E2), Color(0xFFB91C1C)),
  neutral(AppColors.textMuted, Color(0xFFF1F5F9), AppColors.textSecondary),
  primary(AppColors.primary, AppColors.primarySoft, AppColors.primaryPressed);

  new(this.color, this.soft, this.text);
  final Color color;
  final Color soft;
  final Color text;
}

/// A small pill: Paid, Held, Low stock, QRIS, …
class StatusChip extends StatelessWidget {
  const new({required this.label, this.tone = StatusTone.neutral, super.key});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.label,
            fontWeight: FontWeight.w600,
            fontSize: 11,
            letterSpacing: 0.3,
            color: tone.text,
          ),
        ),
      ),
    );
  }
}

/// A thin stock-level bar.
class StockBar extends StatelessWidget {
  const new({required this.fraction, required this.tone, super.key});

  final double fraction;
  final StatusTone tone;

  double get clampedFraction => fraction.clamp(0, 1).toDouble();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        height: 4,
        child: LinearProgressIndicator(
          value: clampedFraction,
          color: tone.color,
          backgroundColor: AppColors.hairline,
        ),
      ),
    );
  }
}

/// Rupiah with fixed-width digits.
class MoneyText extends StatelessWidget {
  const new(this.amount, {this.style, super.key});

  final Money amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      amount.format(),
      style: (style ?? const TextStyle()).copyWith(
        fontFeatures: AppTypography.tabular,
      ),
    );
  }
}

/// Up to two initials of [name]; `?` when blank.
String initialsOf(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '?';
  return words.take(2).map((w) => w.characters.first.toUpperCase()).join();
}

const _avatarTints = [
  [Color(0xFFFB7185), Color(0xFFE11D48)],
  [Color(0xFFFBBF24), Color(0xFFF59E0B)],
  [Color(0xFF94A3B8), Color(0xFF64748B)],
  [Color(0xFF60A5FA), Color(0xFF3B82F6)],
  [Color(0xFFF472B6), Color(0xFFDB2777)],
  [Color(0xFF34D399), Color(0xFF10B981)],
];

/// A rounded square with the person's or product's initials.
class InitialsAvatar extends StatelessWidget {
  const new({required this.name, this.size = 48, super.key});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = _avatarTints[name.trim().hashCode.abs() % _avatarTints.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tint,
        ),
      ),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
          color: AppColors.white,
        ),
      ),
    );
  }
}

/// The product picture, or a soft initials tile when there is none or it
/// cannot load (offline terminals).
class ProductThumb extends StatelessWidget {
  const new({
    required this.name,
    this.imageUrl,
    this.size = 96,
    this.fill = false,
    super.key,
  });

  final String name;
  final String? imageUrl;
  final double size;

  /// Fill the parent instead of a [size] square (product tiles).
  final bool fill;

  @override
  Widget build(BuildContext context) {
    if (!fill) return _thumb(size, size);
    return LayoutBuilder(
      builder: (context, c) => _thumb(
        c.maxWidth.isFinite ? c.maxWidth : size,
        c.maxHeight.isFinite ? c.maxHeight : size,
      ),
    );
  }

  Widget _thumb(double width, double height) {
    final side = width < height ? width : height;
    final fallback = Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE4E6), Color(0xFFF5F3FF)],
        ),
      ),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: side * 0.3,
          color: AppColors.primary.withValues(alpha: 0.7),
        ),
      ),
    );
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.tile - 6),
      child: url == null || url.isEmpty
          ? fallback
          : Image.network(
              url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

/// A KPI card: icon tile, optional change badge, label, value, footnote.
class StatCard extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.value,
    this.tint = AppColors.primary,
    this.badge,
    this.footnote,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final String? badge;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.control - 2),
                ),
                child: Icon(icon, color: tint, size: 22),
              ),
              const Spacer(),
              if (badge != null)
                Flexible(
                  child: StatusChip(label: badge!, tone: StatusTone.success),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.displayMedium?.copyWith(
              fontFeatures: AppTypography.tabular,
              fontSize: 24,
            ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              footnote!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
