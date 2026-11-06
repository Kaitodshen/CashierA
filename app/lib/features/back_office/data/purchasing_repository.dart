import 'package:cashiera_core/cashiera_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Qty _q(Object? v) => Qty(((v as num? ?? 0) * 1000).round());
Money _m(Object? v) => Money((v as num? ?? 0).toInt());
Map<String, dynamic> _o(Object? v) =>
    (v as Map? ?? const {}).cast<String, dynamic>();
DateTime? _d(Object? v) => v == null ? null : DateTime.parse('$v');

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// A stock-tracked variant that can be bought or moved.
class StockVariant {
  const new({
    required this.id,
    required this.name,
    required this.cost,
    required this.unit,
    this.sku,
  });

  final String id;
  final String name;
  final String? sku;
  final Money cost;
  final String unit;
}

/// A line being edited: [quantity] in thousandths, [unitCost] in rupiah.
class PoLineDraft {
  new({required this.variant, required this.quantity, required this.unitCost});

  final StockVariant variant;
  Qty quantity;
  Money unitCost;

  Money get total => quantity.times(unitCost);
}

class PoListRow {
  new fromJson(Map<String, dynamic> j)
    : id = j['purchase_order_id'] as String,
      number = j['po_number'] as String,
      storeCode = j['store_code'] as String,
      supplierName = j['supplier_name'] as String,
      status = j['status'] as String,
      orderDate = j['order_date'] as String,
      expectedDate = j['expected_date'] as String?,
      total = Money((j['total_amount'] as num? ?? 0).toInt()),
      lines = (j['line_count'] as num? ?? 0).toInt(),
      receivedRatio = (j['received_ratio'] as num? ?? 0).toDouble();

  final String id;
  final String number;
  final String storeCode;
  final String supplierName;

  /// `draft`, `ordered`, `partially_received`, `received` or `cancelled`.
  final String status;
  final String orderDate;
  final String? expectedDate;
  final Money total;
  final int lines;
  final double receivedRatio;
}

class PoLine {
  const new({
    required this.id,
    required this.variantId,
    required this.name,
    required this.unit,
    required this.ordered,
    required this.received,
    required this.unitCost,
    required this.lineTotal,
    this.sku,
  });

  factory fromJson(Map<String, dynamic> j) => PoLine(
    id: j['id'] as String,
    variantId: j['variant_id'] as String,
    name: j['name'] as String,
    sku: j['sku'] as String?,
    unit: j['unit'] as String? ?? 'pcs',
    ordered: _q(j['quantity_ordered']),
    received: _q(j['quantity_received']),
    unitCost: _m(j['unit_cost']),
    lineTotal: _m(j['line_total']),
  );

  final String id;
  final String variantId;
  final String name;
  final String? sku;
  final String unit;
  final Qty ordered;
  final Qty received;
  final Money unitCost;
  final Money lineTotal;

  Qty get open => Qty(ordered.milli - received.milli);
}

class PoDetail {
  const new({
    required this.id,
    required this.number,
    required this.status,
    required this.storeId,
    required this.storeName,
    required this.supplierId,
    required this.supplierName,
    required this.orderDate,
    required this.total,
    required this.lines,
    required this.receipts,
    this.supplierPhone,
    this.supplierAddress,
    this.expectedDate,
    this.note,
    this.createdBy,
  });

  factory fromJson(Map<String, dynamic> j) {
    final s = _o(j['supplier']);
    return PoDetail(
      id: j['purchase_order_id'] as String,
      number: j['po_number'] as String,
      status: j['status'] as String,
      storeId: j['store_id'] as String,
      storeName: j['store_name'] as String,
      supplierId: j['supplier_id'] as String,
      supplierName: s['name'] as String,
      supplierPhone: s['phone'] as String?,
      supplierAddress: s['address'] as String?,
      orderDate: j['order_date'] as String,
      expectedDate: _d(j['expected_date']),
      note: j['note'] as String?,
      total: _m(j['total_amount']),
      createdBy: j['created_by_name'] as String?,
      lines: [
        for (final l in j['items'] as List? ?? const []) PoLine.fromJson(_o(l)),
      ],
      receipts: [
        for (final r in j['receipts'] as List? ?? const [])
          (
            number: _o(r)['receipt_number'] as String,
            at: DateTime.parse(_o(r)['received_at'] as String),
            by: _o(r)['received_by_name'] as String?,
            lines: (_o(r)['lines'] as num? ?? 0).toInt(),
          ),
      ],
    );
  }

  final String id;
  final String number;
  final String status;
  final String storeId;
  final String storeName;
  final String supplierId;
  final String supplierName;
  final String? supplierPhone;
  final String? supplierAddress;
  final String orderDate;
  final DateTime? expectedDate;
  final String? note;
  final Money total;
  final String? createdBy;
  final List<PoLine> lines;
  final List<({String number, DateTime at, String? by, int lines})> receipts;

  bool get editable =>
      (status == 'draft' || status == 'ordered') &&
      lines.every((l) => l.received.milli == 0);
  bool get receivable => status == 'ordered' || status == 'partially_received';
}

class TransferListRow {
  new fromJson(Map<String, dynamic> j)
    : id = j['transfer_id'] as String,
      number = j['transfer_number'] as String,
      fromStoreId = j['from_store_id'] as String,
      fromStore = j['from_store'] as String,
      toStoreId = j['to_store_id'] as String,
      toStore = j['to_store'] as String,
      status = j['status'] as String,
      requestedAt = DateTime.parse(j['requested_at'] as String),
      requestedBy = j['requested_by_name'] as String?,
      lines = (j['line_count'] as num? ?? 0).toInt();

  final String id;
  final String number;
  final String fromStoreId;
  final String fromStore;
  final String toStoreId;
  final String toStore;

  /// `requested`, `approved`, `in_transit`, `received`, `rejected`,
  /// `cancelled`.
  final String status;
  final DateTime requestedAt;
  final String? requestedBy;
  final int lines;
}

class TransferLine {
  new fromJson(Map<String, dynamic> j)
    : variantId = j['variant_id'] as String,
      name = j['name'] as String,
      sku = j['sku'] as String?,
      requested = _q(j['quantity_requested']),
      shipped = j['quantity_shipped'] == null
          ? null
          : _q(j['quantity_shipped']),
      received = j['quantity_received'] == null
          ? null
          : _q(j['quantity_received']),
      stockAtSender = j['stock_at_sender'] == null
          ? null
          : _q(j['stock_at_sender']);

  final String variantId;
  final String name;
  final String? sku;
  final Qty requested;
  final Qty? shipped;
  final Qty? received;
  final Qty? stockAtSender;
}

class TransferDetail {
  new fromJson(Map<String, dynamic> j)
    : id = j['transfer_id'] as String,
      number = j['transfer_number'] as String,
      status = j['status'] as String,
      note = j['note'] as String?,
      fromStoreId = j['from_store_id'] as String,
      fromStore = j['from_store'] as String,
      toStoreId = j['to_store_id'] as String,
      toStore = j['to_store'] as String,
      rejectReason = j['reject_reason'] as String?,
      events = {
        for (final MapEntry(:key, :value) in _o(j['events']).entries)
          key: (
            at: DateTime.parse(_o(value)['at'] as String),
            by: _o(value)['by'] as String?,
          ),
      },
      lines = [
        for (final l in j['items'] as List? ?? const [])
          TransferLine.fromJson(_o(l)),
      ];

  final String id;
  final String number;
  final String status;
  final String? note;
  final String fromStoreId;
  final String fromStore;
  final String toStoreId;
  final String toStore;
  final String? rejectReason;

  /// requested / approved / shipped / received / rejected / cancelled.
  final Map<String, ({DateTime at, String? by})> events;
  final List<TransferLine> lines;
}

/// Back-office purchasing and transfers (migration 2000 and the transfer
/// RPCs of 1100).
class PurchasingRepository {
  new(this._client);

  final SupabaseClient _client;

  Future<List<StockVariant>> stockVariants() async {
    final rows = await _client
        .from('product_variants')
        .select(
          'id, name, sku, cost, is_active, '
          'products!inner(name, track_stock, is_active, units(code))',
        )
        .eq('is_active', true)
        .eq('products.track_stock', true)
        .eq('products.is_active', true)
        .order('sku');
    return [
      for (final r in rows)
        () {
          final p = _o(r['products']);
          final variant = r['name'] as String;
          return StockVariant(
            id: r['id'] as String,
            name: variant == 'Default'
                ? p['name'] as String
                : '${p['name']} $variant',
            sku: r['sku'] as String?,
            cost: _m(r['cost']),
            unit: _o(p['units'])['code'] as String? ?? 'pcs',
          );
        }(),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<List<PoListRow>> purchaseOrders({
    String? storeId,
    String? status,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'purchase_order_list',
      params: {'p_store_id': storeId, 'p_status': status},
    );
    return [for (final r in rows) PoListRow.fromJson(_o(r))];
  }

  Future<PoDetail> purchaseOrder(String id) async => PoDetail.fromJson(
    _o(
      await _client.rpc<dynamic>('purchase_order_detail', params: {'p_id': id}),
    ),
  );

  /// Creates or replaces a draft/ordered PO. Returns its id.
  Future<String> savePurchaseOrder({
    required String storeId,
    required String supplierId,
    required List<PoLineDraft> lines,
    String? id,
    DateTime? expectedDate,
    String? note,
  }) async {
    final json = await _client.rpc<dynamic>(
      'save_purchase_order',
      params: {
        'p': {
          'id': ?id,
          'store_id': storeId,
          'supplier_id': supplierId,
          'expected_date': expectedDate == null ? null : _date(expectedDate),
          'note': note,
          'items': [
            for (final l in lines)
              {
                'variant_id': l.variant.id,
                'quantity_ordered': l.quantity.toPayload(),
                'unit_cost': l.unitCost.rupiah,
              },
          ],
        },
      },
    );
    return _o(json)['purchase_order_id'] as String;
  }

  Future<void> setPurchaseOrderStatus(String id, String status) =>
      _client.rpc<dynamic>(
        'set_purchase_order_status',
        params: {'p_id': id, 'p_status': status},
      );

  /// Receives [quantities] (PO line id → quantity, with optional new costs).
  Future<String> receive(
    String purchaseOrderId,
    Map<String, (Qty, Money?)> quantities, {
    String? note,
  }) async {
    final json = await _client.rpc<dynamic>(
      'receive_purchase_order',
      params: {
        'p': {
          'purchase_order_id': purchaseOrderId,
          'note': note,
          'items': [
            for (final MapEntry(key: id, value: (qty, cost))
                in quantities.entries)
              if (qty.milli > 0)
                {
                  'purchase_order_item_id': id,
                  'quantity': qty.toPayload(),
                  'unit_cost': cost?.rupiah,
                },
          ],
        },
      },
    );
    return _o(json)['receipt_number'] as String;
  }

  Future<List<TransferListRow>> transfers({
    String? storeId,
    String? direction,
    String? status,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'transfer_list',
      params: {
        'p_store_id': storeId,
        'p_direction': direction,
        'p_status': status,
      },
    );
    return [for (final r in rows) TransferListRow.fromJson(_o(r))];
  }

  Future<TransferDetail> transfer(String id) async => TransferDetail.fromJson(
    _o(await _client.rpc<dynamic>('transfer_detail', params: {'p_id': id})),
  );

  /// The receiving store asks [fromStoreId] for stock. Returns the id.
  Future<String> requestTransfer({
    required String fromStoreId,
    required String toStoreId,
    required Map<String, Qty> quantities,
    String? note,
  }) async {
    final json = await _client.rpc<dynamic>(
      'request_stock_transfer',
      params: {
        'p_from_store_id': fromStoreId,
        'p_to_store_id': toStoreId,
        'p_items': [
          for (final MapEntry(key: id, value: qty) in quantities.entries)
            {'variant_id': id, 'quantity': qty.toPayload()},
        ],
        'p_note': note,
      },
    );
    return _o(json)['transfer_id'] as String;
  }

  /// approved / rejected / in_transit (with shipped [quantities]) /
  /// received (with received [quantities]) / cancelled.
  Future<void> transition(
    String transferId,
    String status, {
    Map<String, Qty>? quantities,
    String? note,
  }) => _client.rpc<dynamic>(
    'transition_stock_transfer',
    params: {
      'p_transfer_id': transferId,
      'p_status': status,
      'p_items': quantities == null
          ? null
          : [
              for (final MapEntry(key: id, value: qty) in quantities.entries)
                {'variant_id': id, 'quantity': qty.toPayload()},
            ],
      'p_note': note,
    },
  );

  // Dining tables (F&B) -----------------------------------------------------

  Future<List<Map<String, dynamic>>> diningTables(String storeId) async =>
      await _client
          .from('dining_tables')
          .select('id, name, area, capacity, is_active, status')
          .eq('store_id', storeId)
          .order('name');

  Future<void> saveDiningTable({
    required String storeId,
    required String name,
    required int capacity,
    String? id,
    String? area,
    bool isActive = true,
  }) async {
    final row = {
      'store_id': storeId,
      'name': name.trim(),
      'area': area?.trim().isEmpty ?? true ? null : area!.trim(),
      'capacity': capacity,
      'is_active': isActive,
    };
    if (id == null) {
      await _client.from('dining_tables').insert(row);
    } else {
      await _client.from('dining_tables').update(row).eq('id', id);
    }
  }

  Future<bool> fnbMode(String storeId) async =>
      (await _client
              .from('stores')
              .select('fnb_mode')
              .eq('id', storeId)
              .single())['fnb_mode']
          as bool;

  Future<void> setFnbMode(String storeId, {required bool on}) =>
      _client.from('stores').update({'fnb_mode': on}).eq('id', storeId);
}
