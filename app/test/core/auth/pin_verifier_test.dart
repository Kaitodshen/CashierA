import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/auth/pin_verifier.dart';
import 'package:cashiera/core/auth/terminal_repository.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Made by pgcrypto: `select crypt('482913', gen_salt('bf', 10))`, the same
/// call `set_employee_pin` uses on the server.
const pgcryptoHash =
    r'$2a$10$0w7r1OiprK2s9g/F/C15fu/QWtSvugG1vVqWzXF3sdp50WdqEUqbq';

const eko = StaffMember(
  employeeId: 'eko',
  fullName: 'Eko Saputra',
  roleCode: 'cashier',
  permissions: {'pos.sell'},
  pinHash: pgcryptoHash,
);

void main() {
  late AppDatabase db;
  late TerminalRepository repo;
  final t0 = DateTime.utc(2026, 11, 5, 3);

  /// Fast stand-in for bcrypt: the right PIN is 482913.
  Future<bool> fakeCheck(String pin, String hash) async => pin == '482913';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TerminalRepository(db);
    await repo.replaceRoster([eko]);
  });

  tearDown(() => db.close());

  Future<PinResult> verify(String pin, {DateTime? at}) => withClock(
    Clock.fixed(at ?? t0),
    () => PinVerifier(db, check: fakeCheck).verify('eko', pin),
  );

  test('a pgcrypto bcrypt hash verifies offline', () async {
    expect(await PinVerifier.bcryptCheck('482913', pgcryptoHash), isTrue);
    expect(await PinVerifier.bcryptCheck('482914', pgcryptoHash), isFalse);
  });

  test('a garbage hash never verifies (and does not throw)', () async {
    expect(await PinVerifier.bcryptCheck('482913', 'not-a-hash'), isFalse);
  });

  test('correct PIN returns the staff member', () async {
    final result = await verify('482913');
    expect(result, isA<PinOk>());
    expect((result as PinOk).staff.fullName, 'Eko Saputra');
    expect(result.staff.can('pos.sell'), isTrue);
    expect(result.staff.can('pos.refund'), isFalse);
  });

  test('mismatch_counts_down', () async {
    final left = <int>[];
    for (var i = 0; i < 4; i++) {
      left.add(((await verify('000000')) as PinMismatch).attemptsLeft);
    }
    expect(left, [4, 3, 2, 1]);
  });

  test('fifth_wrong_locks_for_5_minutes', () async {
    for (var i = 0; i < 4; i++) {
      await verify('000000');
    }
    final fifth = await verify('000000');
    expect(fifth, isA<PinLocked>());
    expect((fifth as PinLocked).until, t0.add(const Duration(minutes: 5)));
    // Even the right PIN is refused while locked.
    expect(
      await verify('482913', at: t0.add(const Duration(minutes: 4))),
      isA<PinLocked>(),
    );
  });

  test('unlocks_after_5_minutes', () async {
    for (var i = 0; i < 5; i++) {
      await verify('000000');
    }
    final later = t0.add(const Duration(minutes: 5, seconds: 1));
    expect(await verify('482913', at: later), isA<PinOk>());
  });

  test('success_resets_attempts', () async {
    await verify('000000');
    await verify('000000');
    await verify('482913');
    expect(((await verify('000000')) as PinMismatch).attemptsLeft, 4);
  });

  test('roster_refresh_keeps_lockout', () async {
    for (var i = 0; i < 5; i++) {
      await verify('000000');
    }
    await repo.replaceRoster([eko]);
    expect(
      await verify('482913', at: t0.add(const Duration(minutes: 1))),
      isA<PinLocked>(),
    );
  });

  test('staff without a PIN or not on the roster', () async {
    await repo.replaceRoster([
      const StaffMember(
        employeeId: 'fitri',
        fullName: 'Fitri Handayani',
        roleCode: 'cashier',
        permissions: {},
        pinHash: null,
      ),
    ]);
    final verifier = PinVerifier(db, check: fakeCheck);
    expect(await verifier.verify('fitri', '482913'), isA<PinNoPin>());
    expect(await verifier.verify('eko', '482913'), isA<PinNoPin>());
  });

  test('owners hold every permission', () {
    const owner = StaffMember(
      employeeId: 'o',
      fullName: 'Andi Pratama',
      roleCode: 'owner',
      permissions: {},
      pinHash: null,
    );
    expect(owner.can('pos.void_after_print'), isTrue);
    expect(owner.initials, 'AP');
  });
}
