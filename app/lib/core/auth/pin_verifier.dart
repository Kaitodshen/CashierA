import 'package:bcrypt/bcrypt.dart';
import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/core/database/app_database.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

sealed class PinResult {
  const new();
}

final class PinOk extends PinResult {
  const new(this.staff);
  final StaffMember staff;
}

final class PinMismatch extends PinResult {
  const new(this.attemptsLeft);
  final int attemptsLeft;
}

final class PinLocked extends PinResult {
  const new(this.until);
  final DateTime until;
}

final class PinNoPin extends PinResult {
  const new();
}

typedef PinHashCheck = Future<bool> Function(String pin, String hash);

/// Checks a PIN offline against the bcrypt hash the server sent in the
/// roster. Same lockout rule as `verify_employee_pin`: 5 wrong tries lock that
/// person for 5 minutes.
class PinVerifier {
  new(this._db, {PinHashCheck? check}) : _check = check ?? bcryptCheck;

  static const maxAttempts = 5;
  static const lockDuration = Duration(minutes: 5);

  final AppDatabase _db;
  final PinHashCheck _check;

  /// bcrypt is deliberately slow; run it off the UI thread.
  static Future<bool> bcryptCheck(String pin, String hash) =>
      compute(_checkpw, (pin, hash));

  Future<PinResult> verify(String employeeId, String pin) async {
    final staff = await (_db.select(
      _db.localStaff,
    )..where((s) => s.employeeId.equals(employeeId))).getSingleOrNull();
    final hash = staff?.pinHash;
    if (staff == null || hash == null || !staff.isActive) {
      return const PinNoPin();
    }

    final now = clock.now();
    final attempts = await (_db.select(
      _db.pinAttempts,
    )..where((a) => a.employeeId.equals(employeeId))).getSingleOrNull();
    final lockedUntil = attempts?.lockedUntil;
    if (lockedUntil != null && lockedUntil.isAfter(now)) {
      return PinLocked(lockedUntil);
    }

    if (await _check(pin, hash)) {
      await (_db.delete(
        _db.pinAttempts,
      )..where((a) => a.employeeId.equals(employeeId))).go();
      return PinOk(StaffMember.fromRow(staff));
    }

    // An expired lock starts a fresh round of attempts.
    final previous = lockedUntil != null ? 0 : attempts?.failedAttempts ?? 0;
    final failed = previous + 1;
    final lock = failed >= maxAttempts ? now.add(lockDuration) : null;
    await _db
        .into(_db.pinAttempts)
        .insertOnConflictUpdate(
          PinAttemptsCompanion.insert(
            employeeId: employeeId,
            failedAttempts: Value(failed),
            lockedUntil: Value(lock),
          ),
        );
    return lock != null ? PinLocked(lock) : PinMismatch(maxAttempts - failed);
  }
}

bool _checkpw((String, String) args) {
  try {
    return BCrypt.checkpw(args.$1, args.$2);
  } on Object {
    return false;
  }
}
