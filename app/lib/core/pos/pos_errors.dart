import 'package:cashiera_core/cashiera_core.dart';

/// The person on duty lacks a permission (and no approver was given).
class PosPermissionException implements Exception {
  const new(this.permission);
  final String permission;

  @override
  String toString() => 'missing permission $permission';
}

/// An action cannot be done as things stand.
class PosStateException implements Exception {
  const new(this.code);

  /// Sales: `shift_required`, `not_paid`, `kasbon_requires_customer`,
  /// `approval_required`, `empty`.
  /// Shifts and corrections: `shift_closed`, `reason_required`,
  /// `not_completed`, `void_after_refund`, `refund_method`,
  /// `void_with_kasbon_payments`, `points`.
  final String code;

  @override
  String toString() => code;
}

/// A cash out larger than what the drawer should hold.
class DrawerShortException implements Exception {
  const new(this.available);
  final Money available;

  @override
  String toString() => 'only ${available.format()} in the drawer';
}

/// A kasbon installment that breaks one of the repayment rules.
class RepaymentRejected implements Exception {
  const new(this.problem);
  final RepaymentProblem problem;

  @override
  String toString() => 'repayment ${problem.name}';
}

/// A refund that breaks one of the refund rules.
class RefundRejected implements Exception {
  const new(this.problem);
  final RefundProblem problem;

  @override
  String toString() => 'refund ${problem.name}';
}
