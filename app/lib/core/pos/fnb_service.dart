import 'dart:async';
import 'dart:convert';

import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/pos/cart.dart';
import 'package:cashiera/core/pos/pos_errors.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// A dining table as the terminal sees it: the mirrored row plus the local
/// held bill on it, if any.
@immutable
class DiningTable {
  const new({
    required this.id,
    required this.name,
    required this.capacity,
    required this.serverStatus,
    this.area,
    this.heldOrder,
  });

  final String id;
  final String name;
  final String? area;
  final int capacity;

  /// `available`, `occupied`, `reserved` or `cleaning` (last pull).
  final String serverStatus;

  /// The open bill on this table rung up on this terminal.
  final LocalOrderRow? heldOrder;

  /// A local bill is on it, or the server says another terminal's is.
  bool get occupied => heldOrder != null || serverStatus == 'occupied';

  /// What the table grid shows: local knowledge first.
  String get status => heldOrder != null ? 'occupied' : serverStatus;
}

/// One station's ticket on the kitchen display (`kitchen_queue`).
@immutable
class KitchenTicket {
  const new({
    required this.orderId,
    required this.orderNumber,
    required this.station,
    required this.status,
    required this.orderType,
    required this.createdAt,
    required this.items,
    this.tableName,
    this.guestCount,
    this.note,
  });

  factory fromJson(Map<String, dynamic> j) => KitchenTicket(
    orderId: j['order_id'] as String,
    orderNumber: j['order_number'] as String,
    station: j['station'] as String,
    status: j['status'] as String,
    orderType: j['order_type'] as String? ?? 'takeaway',
    tableName: j['table_name'] as String?,
    guestCount: (j['guest_count'] as num?)?.toInt(),
    note: j['note'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
    items: [
      for (final i in j['items'] as List? ?? const [])
        KitchenTicketItem.fromJson((i as Map).cast<String, dynamic>()),
    ],
  );

  final String orderId;
  final String orderNumber;

  /// `kitchen` or `bar`.
  final String station;

  /// `new`, `preparing` or `ready`.
  final String status;
  final String orderType;
  final String? tableName;
  final int? guestCount;
  final String? note;
  final DateTime createdAt;
  final List<KitchenTicketItem> items;

  /// The next status the cook moves it to, or null at the end.
  String? get nextStatus => switch (status) {
    'new' => 'preparing',
    'preparing' => 'ready',
    'ready' => 'served',
    _ => null,
  };
}

@immutable
class KitchenTicketItem {
  const new({
    required this.name,
    required this.quantity,
    this.note,
    this.modifiers = const [],
  });

  factory fromJson(Map<String, dynamic> j) => KitchenTicketItem(
    name: j['name'] as String,
    quantity: Qty(((j['quantity'] as num) * 1000).round()),
    note: j['note'] as String?,
    modifiers: [for (final m in j['modifiers'] as List? ?? const []) '$m'],
  );

  final String name;
  final Qty quantity;
  final String? note;
  final List<String> modifiers;
}

/// What still has to go to each station: per line the quantity not sent
/// yet. Stations in a fixed order (kitchen, then bar).
Map<String, List<(CartLine, Qty)>> pendingKitchenLines(Cart cart) {
  final out = <String, List<(CartLine, Qty)>>{};
  for (final l in cart.lines) {
    final station = l.kitchenStation;
    if (station == null) continue;
    final open = l.quantity.milli - (cart.kitchenSent[l.id] ?? 0);
    if (open <= 0) continue;
    out.putIfAbsent(station, () => []).add((l, Qty(open)));
  }
  return {
    for (final s in [...out.keys]..sort()) s: out[s]!,
  };
}

/// [cart] with every kitchen line marked as sent in full.
Cart markKitchenSent(Cart cart) => cart.copyWith(
  kitchenSent: {
    ...cart.kitchenSent,
    for (final l in cart.lines)
      if (l.kitchenStation != null) l.id: l.quantity.milli,
  },
);

/// Tables and kitchen tickets on the terminal (F&B stores). Table changes
/// and ticket progress go through the outbox like everything else.
class FnbService {
  new(this._db, {this._uuid = const Uuid()});

  final AppDatabase _db;
  final Uuid _uuid;

  Future<List<DiningTable>> tables() async {
    final rows = await (_db.select(
      _db.mirrorRecords,
    )..where((r) => r.sourceTable.equals('dining_tables'))).get();
    final held = await (_db.select(
      _db.localOrders,
    )..where((o) => o.status.equals('held'))).get();
    final byTable = <String, LocalOrderRow>{};
    for (final o in held) {
      final tableId = (jsonDecode(o.cartJson) as Map)['table_id'] as String?;
      if (tableId != null) byTable[tableId] = o;
    }
    final tables = [
      for (final r in rows)
        if ((jsonDecode(r.data) as Map).cast<String, dynamic>() case final t
            when t['is_active'] != false)
          DiningTable(
            id: t['id'] as String,
            name: t['name'] as String,
            area: t['area'] as String?,
            capacity: (t['capacity'] as num? ?? 4).toInt(),
            serverStatus: t['status'] as String? ?? 'available',
            heldOrder: byTable[t['id']],
          ),
    ];
    return tables..sort((a, b) => _naturalCompare(a.name, b.name));
  }

  Stream<List<DiningTable>> watchTables() => _db
      .customSelect('SELECT 1', readsFrom: {_db.mirrorRecords, _db.localOrders})
      .watch()
      .asyncMap((_) => tables());

  /// Marks [table] free again (after the guests left). Refused while a bill
  /// of this terminal is still open on it; the server refuses it while
  /// another terminal's bill is.
  Future<void> clearTable({
    required DiningTable table,
    required StaffMember staff,
  }) async {
    if (table.heldOrder != null) {
      throw const PosStateException('table_has_open_order');
    }
    await _db.transaction(() async {
      final row =
          await (_db.select(_db.mirrorRecords)..where(
                (r) =>
                    r.sourceTable.equals('dining_tables') &
                    r.pk.equals(table.id),
              ))
              .getSingleOrNull();
      if (row != null) {
        final data = (jsonDecode(row.data) as Map).cast<String, dynamic>()
          ..['status'] = 'available'
          ..['current_order_id'] = null;
        await (_db.update(_db.mirrorRecords)..where(
              (r) =>
                  r.sourceTable.equals('dining_tables') & r.pk.equals(table.id),
            ))
            .write(MirrorRecordsCompanion(data: Value(jsonEncode(data))));
      }
      await _db.syncQueueDao.enqueue(
        entity: 'dining_table',
        action: 'status',
        clientUuid: _uuid.v7(),
        payload: {
          'table_id': table.id,
          'status': 'available',
          'employee_id': staff.employeeId,
        },
      );
    });
  }

  /// Moves a kitchen ticket on (`kitchen.status`). Needs `kitchen.view`.
  Future<void> setKitchenStatus({
    required String orderId,
    required String station,
    required String status,
    required StaffMember staff,
  }) async {
    if (!staff.can('kitchen.view')) {
      throw const PosPermissionException('kitchen.view');
    }
    await _db.syncQueueDao.enqueue(
      entity: 'kitchen',
      action: 'status',
      clientUuid: _uuid.v7(),
      payload: {
        'order_id': orderId,
        'station': station,
        'status': status,
        'employee_id': staff.employeeId,
        'at': clock.now().toUtc().toIso8601String(),
      },
    );
  }
}

/// "Meja 2" before "Meja 10".
int _naturalCompare(String a, String b) {
  final re = RegExp(r'(\d+)|(\D+)');
  final pa = re.allMatches(a.toLowerCase()).map((m) => m.group(0)!).toList();
  final pb = re.allMatches(b.toLowerCase()).map((m) => m.group(0)!).toList();
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    final na = int.tryParse(pa[i]);
    final nb = int.tryParse(pb[i]);
    final c = na != null && nb != null
        ? na.compareTo(nb)
        : pa[i].compareTo(pb[i]);
    if (c != 0) return c;
  }
  return pa.length.compareTo(pb.length);
}

/// The live kitchen queue (online only: tickets of every terminal).
abstract interface class KitchenQueueSource {
  Future<List<KitchenTicket>> fetch({String? station});

  /// Fires when a ticket of [storeId] changes (Realtime), to refresh early.
  Stream<void> changes(String storeId);
}

class SupabaseKitchenQueueSource implements KitchenQueueSource {
  new(this._client);

  final SupabaseClient _client;

  @override
  Stream<void> changes(String storeId) {
    late final RealtimeChannel channel;
    late final StreamController<void> out;
    out = StreamController<void>(
      onListen: () {
        channel = _client
            .channel('kitchen:$storeId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'order_status',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'store_id',
                value: storeId,
              ),
              callback: (_) => out.add(null),
            )
            .subscribe();
      },
      onCancel: () => _client.removeChannel(channel),
    );
    return out.stream;
  }

  @override
  Future<List<KitchenTicket>> fetch({String? station}) async {
    final json = await _client.rpc<dynamic>(
      'kitchen_queue',
      params: {'p_station': station},
    );
    return [
      for (final t in json as List? ?? const [])
        KitchenTicket.fromJson((t as Map).cast<String, dynamic>()),
    ];
  }
}
