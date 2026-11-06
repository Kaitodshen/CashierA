import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/auth/pairing_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes case, spaces and dashes', () {
    expect(normalizePairingCode(' abcd-2345 '), 'ABCD2345');
    expect(normalizePairingCode('ab cd 23 45'), 'ABCD2345');
  });

  test('accepts the server alphabet, 8 characters', () {
    expect(isValidPairingCode('abcd-2345'), isTrue);
    expect(isValidPairingCode('ZZZZ9999'), isTrue);
  });

  test('rejects look-alike characters and wrong lengths', () {
    expect(isValidPairingCode('ABCD234O'), isFalse, reason: 'letter O');
    expect(isValidPairingCode('ABCD2340'), isFalse, reason: 'digit 0');
    expect(isValidPairingCode('ABCD234I'), isFalse, reason: 'letter I');
    expect(isValidPairingCode('ABCD2341'), isFalse, reason: 'digit 1');
    expect(isValidPairingCode('ABCD234'), isFalse);
    expect(isValidPairingCode('ABCD23456'), isFalse);
    expect(isValidPairingCode(''), isFalse);
  });

  test('server error messages keep their code', () {
    final e = BackendException.fromMessage(
      'pairing_code_invalid: the code is wrong, expired or already used',
    );
    expect(e.code, 'pairing_code_invalid');
    expect(e.message, 'the code is wrong, expired or already used');
    expect(BackendException.fromMessage('Network down').code, 'error');
  });

  test('principal json from current_principal()', () {
    final p = Principal.fromJson({
      'kind': 'employee',
      'employee': {'id': 'e1', 'full_name': 'Budi Santoso'},
      'role': {'code': 'manager', 'name': 'Branch Manager'},
      'permissions': ['device.manage', 'pos.refund'],
      'store_ids': ['s1'],
    });
    expect(p.isEmployee, isTrue);
    expect(p.can('device.manage'), isTrue);
    expect(p.can('catalog.manage'), isFalse);
    expect(p.storeIds, ['s1']);
  });
}
