import 'dart:convert';

import 'package:cashiera/core/database/app_database.dart';
import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera/core/pos/money_input.dart';
import 'package:cashiera/core/pos/pos_config.dart';
import 'package:cashiera/core/pos/receipt.dart';
import 'package:cashiera/features/sell/presentation/payment_screen.dart';
import 'package:cashiera/features/sell/presentation/receipt_screen.dart';
import 'package:cashiera_core/cashiera_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const config = PosConfig(
  storeId: 'store-pst',
  storeCode: 'PST',
  storeName: 'CashierA Pusat',
  storeAddress: 'Jl. Merdeka 1, Jakarta',
  utcOffsetMinutes: 7 * 60,
  pricing: PricingSettings(taxRateBps: 1100),
  taxName: 'PPN',
  taxEnabled: true,
  discountApprovalBps: 2000,
  kasbonEnabled: true,
  receiptHeader: 'CashierA',
  receiptFooter: 'Terima kasih',
  paperMm: 58,
  business: BusinessInfo(name: 'CashierA', npwp: '01.234.567.8-901.000'),
  paymentOptions: [
    PaymentOption(
      id: 'm-cash',
      code: 'cash',
      name: 'Tunai',
      kind: TenderKind.cash,
      requiresReference: false,
    ),
    PaymentOption(
      id: 'm-debit',
      code: 'debit_card',
      name: 'Kartu Debit',
      kind: TenderKind.card,
      requiresReference: true,
    ),
  ],
);

/// The pgTAP 130 sale as the terminal stores it.
LocalOrderRow order() => LocalOrderRow(
  id: 'o-1',
  orderNumber: 'PST-T1-261106-0001',
  status: 'completed',
  version: 2,
  cartJson: '{}',
  payloadJson: jsonEncode({
    'order_number': 'PST-T1-261106-0001',
    'status': 'completed',
    'ordered_at': '2026-11-06T02:15:00.000Z',
    'gross_total': 88500,
    'net_total': 80000,
    'service_charge_total': 0,
    'service_charge_taxable': true,
    'tax_total': 653,
    'tax_inclusive': true,
    'tax_rate_bps': 1100,
    'rounding_amount': 0,
    'grand_total': 80000,
    'items': [
      {
        'id': 'l-mie',
        'product_name': 'Mie Goreng Instan',
        'variant_name': 'Original',
        'quantity': '3.000',
        'unit_price': 3500,
        'modifiers_unit_total': 0,
        'gross_amount': 10500,
        'net_amount': 6588,
        'is_taxable': true,
        'modifiers': <Object>[],
      },
      {
        'id': 'l-beras',
        'product_name': 'Beras Premium 5 kg',
        'variant_name': 'Default',
        'quantity': '1.000',
        'unit_price': 78000,
        'modifiers_unit_total': 0,
        'gross_amount': 78000,
        'net_amount': 73412,
        'is_taxable': false,
        'note': 'kirim sore',
      },
    ],
    'discounts': [
      {
        'order_item_id': 'l-mie',
        'description': 'Beli 2 Gratis 1 Mie Goreng',
        'amount': 3500,
      },
      {'order_item_id': null, 'description': 'Diskon tagihan', 'amount': 5000},
    ],
    'payments': [
      {
        'payment_method_id': 'm-debit',
        'method_type': 'card',
        'amount': 50000,
        'tendered_amount': null,
        'change_amount': 0,
      },
      {
        'payment_method_id': 'm-cash',
        'method_type': 'cash',
        'amount': 30000,
        'tendered_amount': 50000,
        'change_amount': 20000,
      },
    ],
  }),
  grandTotal: 80000,
  itemCount: 4,
  cashierName: 'Eko Saputra',
  createdAt: DateTime.utc(2026, 11, 6, 2, 10),
  updatedAt: DateTime.utc(2026, 11, 6, 2, 15),
);

void main() {
  test('rupiah and percent as cashiers type them', () {
    expect(parseRupiah('25000'), 25000);
    expect(parseRupiah('Rp 25.000'), 25000);
    expect(parseRupiah(''), isNull);
    expect(parsePercentBps('10'), 1000);
    expect(parsePercentBps('12,5'), 1250);
    expect(parsePercentBps('7.25 %'), 725);
    expect(parsePercentBps('0'), isNull);
    expect(parsePercentBps('101'), isNull);
    expect(parsePercentBps('abc'), isNull);
  });

  test('quick cash amounts', () {
    expect(quickCashAmounts(10500), [10500, 15000, 20000, 50000]);
    expect(quickCashAmounts(20000), [20000, 50000, 100000]);
    expect(quickCashAmounts(0), isEmpty);
  });

  group('receipt', () {
    final l10n = lookupAppLocalizations(const Locale('id'));
    final receipt = ReceiptData.fromOrder(order(), config);

    test('reads back what was booked', () {
      expect(receipt.headerLines, [
        'CashierA',
        'CashierA Pusat',
        'Jl. Merdeka 1, Jakarta',
        'NPWP 01.234.567.8-901.000',
      ]);
      expect(receipt.dateText, '06/11/2026 09:15', reason: 'store time');
      expect(receipt.lines.first.name, 'Mie Goreng Instan Original');
      expect(receipt.lines.first.quantityText, '3 x Rp 3.500');
      expect(receipt.lines.first.discounts.single.$2, const Money(3500));
      expect(receipt.lines.last.name, 'Beras Premium 5 kg');
      expect(receipt.lines.last.details, ['"kirim sore"']);
      expect(receipt.changeTotal, const Money(20000));
      expect(receipt.taxBase, const Money(6588));
    });

    test('totals in print order, with DPP for PPN included', () {
      final rows = receiptTotals(
        receipt,
        receiptLabels(l10n),
      ).map((r) => '${r.$1}=${r.$2}').toList();
      expect(rows, [
        'Subtotal=Rp 88.500',
        'Diskon tagihan=-Rp 5.000',
        'Total=Rp 80.000',
        'Kartu Debit=Rp 50.000',
        'Tunai=Rp 50.000',
        'Kembali=Rp 20.000',
        'Termasuk PPN 11%=Rp 653',
        'DPP=Rp 5.935',
      ]);
    });

    test('renders to a PDF on roll paper', () async {
      final bytes = await buildReceiptPdf(receipt, receiptLabels(l10n));
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });
  });
}
