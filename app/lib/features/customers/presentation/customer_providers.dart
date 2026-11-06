import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/providers.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

// Written by hand: riverpod_generator cannot name Drift row types.

/// One customer from the terminal's copy, kept fresh.
final StreamProviderFamily<CustomerRow?, String> customerRowProvider =
    StreamProvider.autoDispose.family<CustomerRow?, String>((ref, id) {
      final db = ref.watch(appDatabaseProvider);
      return (db.select(
        db.localCustomers,
      )..where((c) => c.id.equals(id))).watchSingleOrNull();
    });

/// Active customers whose name or phone contains the query, at most 100.
final StreamProviderFamily<List<CustomerRow>, String> customerSearchProvider =
    StreamProvider.autoDispose.family<List<CustomerRow>, String>((ref, query) {
      final db = ref.watch(appDatabaseProvider);
      final q = query.trim().toLowerCase();
      final select = db.select(db.localCustomers)
        ..where((c) => c.isActive.equals(true))
        ..orderBy([(c) => OrderingTerm.asc(c.name)])
        ..limit(100);
      if (q.isNotEmpty) {
        final digits = q.replaceAll(RegExp(r'[\s-]'), '');
        select.where(
          (c) =>
              c.name.lower().like('%$q%') |
              (digits.isEmpty
                  ? const Constant(false)
                  : c.phone.like('%$digits%')),
        );
      }
      return select.watch();
    });

/// Outstanding kasbon per customer of this store.
final StreamProvider<Map<String, Money>> kasbonOutstandingProvider =
    StreamProvider.autoDispose<Map<String, Money>>(
      (ref) => ref.watch(kasbonServiceProvider).watchOutstanding(),
    );

final StreamProviderFamily<List<ReceivableRow>, String> customerKasbonProvider =
    StreamProvider.autoDispose.family<List<ReceivableRow>, String>(
      (ref, customerId) =>
          ref.watch(kasbonServiceProvider).watchOpen(customerId),
    );

final StreamProviderFamily<List<ReceivablePaymentRow>, String>
customerInstallmentsProvider = StreamProvider.autoDispose
    .family<List<ReceivablePaymentRow>, String>(
      (ref, customerId) =>
          ref.watch(kasbonServiceProvider).watchPayments(customerId),
    );

/// Order numbers of this terminal's sales, to label kasbon.
final StreamProvider<Map<String, String>> localOrderNumbersProvider =
    StreamProvider.autoDispose<Map<String, String>>((ref) {
      final db = ref.watch(appDatabaseProvider);
      final q = db.selectOnly(db.localOrders)
        ..addColumns([db.localOrders.id, db.localOrders.orderNumber]);
      return q.watch().map(
        (rows) => {
          for (final r in rows)
            r.read(db.localOrders.id)!: r.read(db.localOrders.orderNumber)!,
        },
      );
    });
