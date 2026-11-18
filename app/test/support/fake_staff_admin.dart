import 'package:cashiera/core/auth/models.dart';
import 'package:cashiera/features/back_office/data/staff_admin_repository.dart';

/// An in-memory StaffAdmin that records calls; a test may script one error
/// per method by name.
class FakeStaffAdmin implements StaffAdmin {
  new({List<AdminStore>? stores, List<AdminStaff>? staff})
    : storeRows = stores ?? [pst],
      staffRows = staff ?? [];

  static const pst = AdminStore(
    id: 's-pst',
    code: 'PST',
    name: 'CashierA Pusat',
    address: 'Jl. Contoh 1',
    phone: '021-1',
    timezone: 'Asia/Jakarta',
    isActive: true,
  );
  static const bks = AdminStore(
    id: 's-bks',
    code: 'BKS',
    name: 'CashierA Bekasi',
    timezone: 'Asia/Jakarta',
    isActive: true,
  );

  List<AdminStore> storeRows;
  List<AdminStaff> staffRows;
  final added = <StoreInput>[];
  final updated = <(String, StoreInput)>[];
  final saved = <(String?, StaffInput)>[];
  final active = <(String, bool)>[];
  final pins = <(String, String)>[];
  final invites = <(String, String)>[];
  final errors = <String, String>{};

  Future<void> _maybeFail(String method) async {
    final code = errors[method];
    if (code != null) throw BackendException(code, code);
  }

  @override
  Future<List<AdminStore>> stores() async => storeRows;

  @override
  Future<void> addStore(StoreInput input) async {
    await _maybeFail('addStore');
    added.add(input);
  }

  @override
  Future<void> updateStore(String id, StoreInput input) async {
    await _maybeFail('updateStore');
    updated.add((id, input));
  }

  @override
  Future<List<AdminStaff>> staff() async => staffRows;

  @override
  Future<void> saveStaff(StaffInput input, {String? id}) async {
    await _maybeFail('saveStaff');
    saved.add((id, input));
  }

  @override
  Future<void> setActive(String id, {required bool isActive}) async {
    await _maybeFail('setActive');
    active.add((id, isActive));
  }

  @override
  Future<void> setPin(String id, String pin) async {
    await _maybeFail('setPin');
    pins.add((id, pin));
  }

  @override
  Future<void> invite(String id, String email) async {
    await _maybeFail('invite');
    invites.add((id, email));
  }
}
