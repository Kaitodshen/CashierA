import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/pos/pos_errors.dart';
import 'package:clock/clock.dart';
import 'package:uuid/uuid.dart';

/// Terminal events for the audit log (`audit.log`): reprints and opening
/// the drawer without a sale. The server re-checks the approval.
class AuditService {
  new(this._db, {this._uuid = const Uuid()});

  final AppDatabase _db;
  final Uuid _uuid;

  static const drawerNoSale = 'pos.drawer_open_no_sale';
  static const receiptReprinted = 'receipt.reprinted';

  Future<void> log({
    required String storeId,
    required String action,
    required StaffMember actor,
    StaffMember? approver,
    String? entityType,
    String? entityId,
    Map<String, Object?> details = const {},
  }) async {
    final approved = approver?.can('pos.open_drawer') ?? false;
    if (action == drawerNoSale && !approved) {
      throw const PosPermissionException('pos.open_drawer');
    }
    await _db.syncQueueDao.enqueue(
      entity: 'audit',
      action: 'log',
      clientUuid: _uuid.v7(),
      payload: {
        'id': _uuid.v7(),
        'store_id': storeId,
        'action': action,
        'actor_employee_id': actor.employeeId,
        'approver_employee_id': approver?.employeeId,
        'entity_type': entityType,
        'entity_id': entityId,
        'details': details,
        'occurred_at': clock.now().toUtc().toIso8601String(),
      },
    );
  }
}
