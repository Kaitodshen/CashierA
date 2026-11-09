// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'CashierA';

  @override
  String get commonRetry => 'Coba lagi';

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonClose => 'Tutup';

  @override
  String commonError(String message) {
    return 'Terjadi kesalahan: $message';
  }

  @override
  String get setupTitle => 'Konfigurasi belum lengkap';

  @override
  String get setupBody =>
      'Jalankan aplikasi dengan --dart-define=SUPABASE_URL=... dan --dart-define=SUPABASE_ANON_KEY=... agar terhubung ke server.';

  @override
  String get welcomeTitle => 'Selamat datang di CashierA';

  @override
  String get welcomeSubtitle => 'Pilih cara menggunakan perangkat ini.';

  @override
  String get welcomePairTerminal => 'Pasangkan terminal kasir';

  @override
  String get welcomePairTerminalHint =>
      'Untuk tablet atau PC di toko. Minta kode dari manajer.';

  @override
  String get welcomeBackOffice => 'Masuk back office';

  @override
  String get welcomeBackOfficeHint =>
      'Untuk pemilik dan manajer: laporan, produk, staf.';

  @override
  String get pairTitle => 'Pasangkan terminal';

  @override
  String get pairBody =>
      'Masukkan kode 8 karakter yang dibuat manajer di back office. Kode berlaku 15 menit.';

  @override
  String get pairCodeLabel => 'Kode pasangan';

  @override
  String get pairButton => 'Pasangkan';

  @override
  String get pairInvalidCode =>
      'Kode terdiri dari 8 huruf/angka (tanpa O, 0, I, 1).';

  @override
  String pairSuccess(String code, String store) {
    return 'Terminal $code terpasang di $store.';
  }

  @override
  String get lockTitle => 'Siapa yang bertugas?';

  @override
  String lockEnterPin(String name) {
    return 'PIN untuk $name';
  }

  @override
  String get lockNoStaff =>
      'Belum ada daftar staf. Sambungkan ke internet lalu perbarui.';

  @override
  String get lockRefreshStaff => 'Perbarui daftar staf';

  @override
  String get lockStaffRefreshed => 'Daftar staf diperbarui.';

  @override
  String pinWrong(int count) {
    return 'PIN salah. Sisa $count percobaan.';
  }

  @override
  String pinLocked(String time) {
    return 'Terlalu banyak percobaan. Coba lagi pukul $time.';
  }

  @override
  String get pinNoPin =>
      'Belum ada PIN. Minta manajer mengaturnya di back office.';

  @override
  String get pinTooShort => 'PIN minimal 4 angka.';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusOffline => 'Offline';

  @override
  String statusPending(int count) {
    return '$count tertunda';
  }

  @override
  String get posTitle => 'Kasir';

  @override
  String posOnDuty(String name) {
    return 'Bertugas: $name';
  }

  @override
  String posTerminal(String code) {
    return 'Terminal $code';
  }

  @override
  String get posLock => 'Kunci / ganti kasir';

  @override
  String get posOpenSync => 'Status sinkronisasi';

  @override
  String get posStoreSettings => 'Pengaturan toko';

  @override
  String posTaxLine(String tax, String rate, String mode) {
    return '$tax $rate% · $mode';
  }

  @override
  String get posTaxInclusive => 'termasuk harga';

  @override
  String get posTaxExclusive => 'ditambahkan';

  @override
  String posPaper(int mm) {
    return 'Struk $mm mm';
  }

  @override
  String get syncTitle => 'Sinkronisasi';

  @override
  String get syncNow => 'Sinkronkan sekarang';

  @override
  String get syncEmpty => 'Semua data sudah terkirim ke server.';

  @override
  String get syncStatusPending => 'Menunggu';

  @override
  String get syncStatusSyncing => 'Mengirim';

  @override
  String get syncStatusFailed => 'Gagal';

  @override
  String get syncStatusDone => 'Terkirim';

  @override
  String syncAttempts(int count) {
    return 'Percobaan: $count';
  }

  @override
  String get syncRetried => 'Dijadwalkan ulang.';

  @override
  String syncRunResult(int sent, int failed) {
    return '$sent terkirim, $failed gagal';
  }

  @override
  String get syncOfflineNow =>
      'Server tidak terjangkau. Akan dicoba lagi otomatis.';

  @override
  String get adminSignInTitle => 'Masuk back office';

  @override
  String get adminEmail => 'Email';

  @override
  String get adminPassword => 'Kata sandi';

  @override
  String get adminSignIn => 'Masuk';

  @override
  String get adminEmailInvalid => 'Masukkan email yang valid.';

  @override
  String get adminPasswordShort => 'Kata sandi minimal 8 karakter.';

  @override
  String get adminNotStaff => 'Akun ini belum terdaftar sebagai karyawan.';

  @override
  String get adminTitle => 'Back office';

  @override
  String get adminSignOut => 'Keluar';

  @override
  String adminRole(String role, int stores) {
    return '$role · $stores toko';
  }

  @override
  String get adminStores => 'Toko';

  @override
  String get adminNoStores => 'Belum ada toko yang bisa Anda akses.';

  @override
  String get adminPairTerminal => 'Buat kode pasangan';

  @override
  String get adminDeviceName => 'Nama terminal';

  @override
  String get adminDeviceNameHint => 'mis. Kasir 2';

  @override
  String get adminCreateCode => 'Buat kode';

  @override
  String get adminCodeTitle => 'Kode pasangan';

  @override
  String adminCodeBody(String time) {
    return 'Ketik kode ini di terminal baru sebelum pukul $time.';
  }

  @override
  String get posCatalog => 'Produk & stok';

  @override
  String get posCatalogHint => 'Cari produk, cek stok, catat stok masuk/keluar';

  @override
  String get catalogTitle => 'Produk & stok';

  @override
  String get catalogSearchHint => 'Cari nama, SKU, atau scan barcode';

  @override
  String get catalogAll => 'Semua';

  @override
  String get catalogEmpty =>
      'Katalog belum ada di terminal ini. Sinkronkan saat online.';

  @override
  String get catalogNoMatch => 'Tidak ada produk yang cocok.';

  @override
  String get catalogRefresh => 'Sinkronkan katalog';

  @override
  String catalogLastSync(String time) {
    return 'Terakhir disinkronkan $time';
  }

  @override
  String catalogStock(String qty, String unit) {
    return 'Stok $qty $unit';
  }

  @override
  String get catalogLow => 'Stok menipis';

  @override
  String catalogCodeNotFound(String code) {
    return 'Kode $code tidak ditemukan.';
  }

  @override
  String catalogSynced(int rows) {
    return 'Katalog diperbarui ($rows perubahan).';
  }

  @override
  String get stockIn => 'Stok masuk';

  @override
  String get stockOut => 'Stok keluar';

  @override
  String get stockQuantity => 'Jumlah';

  @override
  String get stockReason => 'Alasan';

  @override
  String get stockNote => 'Catatan (opsional)';

  @override
  String get reasonStockIn => 'Barang masuk';

  @override
  String get reasonStockOut => 'Barang keluar';

  @override
  String get reasonDamaged => 'Rusak';

  @override
  String get reasonExpired => 'Kedaluwarsa';

  @override
  String get reasonLost => 'Hilang';

  @override
  String get stockSave => 'Simpan';

  @override
  String stockSaved(String name) {
    return 'Stok $name diperbarui.';
  }

  @override
  String get stockInvalidQty =>
      'Masukkan jumlah lebih dari 0 (maks. 3 desimal).';

  @override
  String get stockWholeOnly => 'Satuan ini harus bilangan bulat.';

  @override
  String get opnameTitle => 'Stok opname';

  @override
  String get opnameHint =>
      'Isi jumlah yang dihitung. Baris kosong tidak diubah.';

  @override
  String opnameSubmit(int count) {
    return 'Kirim opname ($count item)';
  }

  @override
  String opnameConfirm(int count) {
    return 'Stok $count item akan diganti dengan hasil hitungan. Lanjutkan?';
  }

  @override
  String get opnameDone => 'Opname disimpan dan masuk antrean sinkronisasi.';

  @override
  String opnameSystem(String qty) {
    return 'Sistem: $qty';
  }

  @override
  String get commonContinue => 'Lanjutkan';

  @override
  String get navHome => 'Ringkasan';

  @override
  String get navProducts => 'Produk';

  @override
  String get navCategories => 'Kategori';

  @override
  String get navSuppliers => 'Pemasok';

  @override
  String get navStock => 'Stok';

  @override
  String get navImport => 'Impor & ekspor';

  @override
  String get commonSave => 'Simpan';

  @override
  String get commonAdd => 'Tambah';

  @override
  String get commonEdit => 'Ubah';

  @override
  String get commonSaved => 'Tersimpan.';

  @override
  String get commonActive => 'Aktif';

  @override
  String get commonInactive => 'Nonaktif';

  @override
  String get commonRequired => 'Wajib diisi';

  @override
  String get productsNew => 'Produk baru';

  @override
  String get productsEmpty =>
      'Belum ada produk. Tambah satu atau impor dari file.';

  @override
  String productsVariants(int count) {
    return '$count varian';
  }

  @override
  String get productsAllCategories => 'Semua kategori';

  @override
  String get productsReadOnly => 'Hanya pemilik yang bisa mengubah katalog.';

  @override
  String get productEditTitle => 'Ubah produk';

  @override
  String get productNewTitle => 'Produk baru';

  @override
  String get productName => 'Nama produk';

  @override
  String get productCategory => 'Kategori';

  @override
  String get productUnit => 'Satuan';

  @override
  String get productTaxable => 'Kena PPN';

  @override
  String get productTaxableHint =>
      'Matikan untuk barang bebas PPN (beras, gula, telur ...)';

  @override
  String get productTrackStock => 'Lacak stok';

  @override
  String get productVariants => 'Varian';

  @override
  String get productAddVariant => 'Tambah varian';

  @override
  String get variantName => 'Nama varian';

  @override
  String get variantSku => 'SKU';

  @override
  String get variantBarcode => 'Barcode';

  @override
  String get variantPrice => 'Harga jual';

  @override
  String get variantCost => 'HPP';

  @override
  String get variantRemove => 'Hapus varian';

  @override
  String get productStoreSettings => 'Harga & stok minimum per toko';

  @override
  String get storePriceOverride => 'Harga khusus';

  @override
  String get storeReorderPoint => 'Stok minimum';

  @override
  String get validationMoney => 'Angka rupiah tanpa titik, mis. 25000';

  @override
  String get validationSku => 'Huruf/angka . _ - (maks. 40)';

  @override
  String get categoriesEmpty => 'Belum ada kategori.';

  @override
  String get categoryName => 'Nama kategori';

  @override
  String get categoryColor => 'Warna (#RRGGBB)';

  @override
  String get categoryOrderHint => 'Seret untuk mengatur urutan di layar kasir.';

  @override
  String get suppliersEmpty => 'Belum ada pemasok.';

  @override
  String get supplierName => 'Nama pemasok';

  @override
  String get supplierContact => 'Kontak';

  @override
  String get supplierPhone => 'Telepon';

  @override
  String get supplierEmail => 'Email';

  @override
  String get supplierAddress => 'Alamat';

  @override
  String get stockStore => 'Toko';

  @override
  String get stockLowOnly => 'Hanya stok menipis';

  @override
  String get stockEmpty => 'Belum ada produk yang dilacak stoknya.';

  @override
  String stockReorder(String qty) {
    return 'Min. $qty';
  }

  @override
  String stockAlerts(int count) {
    return '$count peringatan terbuka';
  }

  @override
  String get stockResolve => 'Selesai';

  @override
  String get stockMovements => 'Riwayat mutasi';

  @override
  String get stockNoMovements => 'Belum ada mutasi.';

  @override
  String get movementType_initial => 'Stok awal';

  @override
  String get movementType_sale => 'Penjualan';

  @override
  String get movementType_sale_void => 'Batal jual';

  @override
  String get movementType_refund => 'Retur';

  @override
  String get movementType_purchase_receive => 'Penerimaan barang';

  @override
  String get movementType_adjustment => 'Penyesuaian';

  @override
  String get movementType_waste => 'Rusak/hilang';

  @override
  String get movementType_opname => 'Opname';

  @override
  String get movementType_transfer_out => 'Transfer keluar';

  @override
  String get movementType_transfer_in => 'Transfer masuk';

  @override
  String get importTitle => 'Impor & ekspor katalog';

  @override
  String get importHelp =>
      'Isi template, lalu unggah sebagai CSV atau XLSX. Kolom stock_<KODE> menetapkan stok hasil hitung di toko itu.';

  @override
  String get importDownloadTemplate => 'Unduh template';

  @override
  String get importExportCsv => 'Ekspor CSV';

  @override
  String get importExportXlsx => 'Ekspor XLSX';

  @override
  String get importPick => 'Pilih file';

  @override
  String importRun(int count) {
    return 'Impor $count baris';
  }

  @override
  String importPreview(int rows, int products) {
    return '$rows baris · $products produk';
  }

  @override
  String importIssues(int count) {
    return '$count masalah harus diperbaiki dulu';
  }

  @override
  String importDone(int created, int updated, int stock) {
    return 'Impor selesai: $created varian baru, $updated diperbarui, $stock baris stok.';
  }

  @override
  String importFileError(String message) {
    return 'File tidak bisa dibaca: $message';
  }

  @override
  String get importSaved => 'File disimpan.';

  @override
  String importRowLabel(int row) {
    return 'Baris $row';
  }

  @override
  String get importFileLevel => 'File';

  @override
  String get issue_emptyFile => 'File kosong.';

  @override
  String issue_missingColumn(String column) {
    return 'Kolom $column tidak ada.';
  }

  @override
  String issue_unknownStore(String column) {
    return 'Kolom $column: kode toko tidak dikenal.';
  }

  @override
  String get issue_tooManyRows => 'Maksimal 5.000 baris per impor.';

  @override
  String issue_requiredValue(String column) {
    return '$column wajib diisi.';
  }

  @override
  String issue_skuFormat(String value) {
    return 'SKU \"$value\" hanya boleh huruf, angka, . _ -';
  }

  @override
  String issue_barcodeFormat(String value) {
    return 'Barcode \"$value\" tidak valid.';
  }

  @override
  String issue_priceFormat(String column, String value) {
    return '$column \"$value\": tulis angka saja, mis. 25000 (tanpa Rp atau titik).';
  }

  @override
  String issue_quantityFormat(String column, String value) {
    return '$column \"$value\" bukan jumlah yang valid (maks. 3 desimal, tidak negatif).';
  }

  @override
  String issue_booleanFormat(String column, String value) {
    return '$column \"$value\": isi yes/no atau ya/tidak.';
  }

  @override
  String issue_unknownUnit(String value) {
    return 'Satuan \"$value\" tidak dikenal.';
  }

  @override
  String issue_duplicateSku(String value) {
    return 'SKU \"$value\" muncul lebih dari sekali.';
  }

  @override
  String issue_duplicateBarcode(String value) {
    return 'Barcode \"$value\" muncul lebih dari sekali.';
  }

  @override
  String issue_productMismatch(String value) {
    return '\"$value\": kategori, satuan, PPN atau lacak stok berbeda dari baris sebelumnya.';
  }

  @override
  String productSaveFailed(String message) {
    return 'Gagal menyimpan: $message';
  }

  @override
  String get commonNone => 'Tidak ada';

  @override
  String get posSell => 'Kasir';

  @override
  String get posSellHint =>
      'Scan atau pilih barang, terima pembayaran, cetak struk';

  @override
  String get sellTitle => 'Kasir';

  @override
  String get sellFavorites => 'Favorit';

  @override
  String sellNotFound(String code) {
    return 'Kode \"$code\" tidak ditemukan.';
  }

  @override
  String get sellUnavailable => 'Tidak dijual';

  @override
  String sellCartSummary(int count, String total) {
    return '$count item · $total';
  }

  @override
  String get sellPay => 'Bayar';

  @override
  String sellPayAmount(String amount) {
    return 'Bayar $amount';
  }

  @override
  String get sellNewBill => 'Tagihan baru';

  @override
  String get sellClear => 'Kosongkan';

  @override
  String get sellClearTitle => 'Kosongkan tagihan?';

  @override
  String get sellClearHint => 'Semua barang di tagihan ini dihapus.';

  @override
  String get sellClearHeldHint =>
      'Perubahan sejak disimpan dibuang. Tagihan tetap tersimpan di daftar Ditahan.';

  @override
  String get sellAddCustomer => 'Tambah pelanggan';

  @override
  String get sellEmpty => 'Belum ada barang. Scan barcode atau ketuk produk.';

  @override
  String get sellChangeQuantity => 'Ubah jumlah';

  @override
  String get sellLineDiscount => 'Diskon barang';

  @override
  String get sellBillDiscount => 'Diskon tagihan';

  @override
  String get sellNote => 'Catatan';

  @override
  String get sellRemove => 'Hapus';

  @override
  String get sellItemDiscounts => 'Diskon barang';

  @override
  String sellTaxIncluded(String tax) {
    return 'Termasuk $tax';
  }

  @override
  String get sellNeedsApproval => 'Diskon melebihi batas: perlu persetujuan';

  @override
  String get sellDiscount => 'Diskon';

  @override
  String get sellHold => 'Tahan';

  @override
  String sellHeld(String number) {
    return 'Tagihan $number ditahan.';
  }

  @override
  String get discountManualLine => 'Diskon';

  @override
  String get discountManualBill => 'Diskon tagihan';

  @override
  String get discountVoucher => 'Voucher';

  @override
  String get discountPoints => 'Tukar poin';

  @override
  String get discountPercent => 'Persen';

  @override
  String get discountAmount => 'Rupiah';

  @override
  String get discountValue => 'Besar diskon';

  @override
  String get discountInvalid => 'Isi persen 0,01–100 atau rupiah di atas 0.';

  @override
  String get discountRemove => 'Hapus diskon';

  @override
  String get voucherTitle => 'Voucher';

  @override
  String get voucherCode => 'Kode voucher';

  @override
  String get voucherCodeShort => 'Kode minimal 3 karakter.';

  @override
  String voucherUnknown(String code) {
    return 'Voucher $code tidak dikenal.';
  }

  @override
  String get voucherInactive => 'Voucher ini sudah tidak aktif.';

  @override
  String get voucherNotStarted => 'Voucher ini belum berlaku.';

  @override
  String get voucherExpired => 'Voucher ini sudah kedaluwarsa.';

  @override
  String get voucherUsedUp => 'Kuota voucher ini sudah habis.';

  @override
  String get voucherBelowMinimum => 'Belanja belum mencapai minimum voucher.';

  @override
  String modifierRequired(int count) {
    return 'pilih $count';
  }

  @override
  String modifierOptional(int count) {
    return 'opsional, maks. $count';
  }

  @override
  String modifierAdd(String price) {
    return 'Tambahkan · $price';
  }

  @override
  String get approvalTitle => 'Persetujuan';

  @override
  String approvalDiscountReason(String percent, String limit) {
    return 'Diskon $percent% melebihi batas $limit%.';
  }

  @override
  String approvalCancelReason(String number) {
    return 'Membatalkan tagihan $number.';
  }

  @override
  String get approvalNobody =>
      'Tidak ada staf di toko ini yang boleh menyetujui.';

  @override
  String approvalEnterPin(String name) {
    return '$name, masukkan PIN Anda.';
  }

  @override
  String get approvalLocked =>
      'PIN terkunci 5 menit karena terlalu banyak percobaan.';

  @override
  String get approvalNoPin => 'Staf ini belum punya PIN.';

  @override
  String get approvalOther => 'Staf lain';

  @override
  String get customerAdd => 'Pelanggan baru';

  @override
  String get customerName => 'Nama';

  @override
  String get customerPhone => 'No. HP (opsional)';

  @override
  String get customerPhoneInvalid => 'Nomor HP 8–15 angka.';

  @override
  String get customerSearchHint => 'Cari nama atau nomor HP';

  @override
  String get customerNoPermission => 'Anda tidak boleh menambah pelanggan.';

  @override
  String get shiftOpenTitle => 'Buka shift';

  @override
  String get shiftOpenHint => 'Hitung uang di laci, lalu isi kas awal.';

  @override
  String get shiftOpeningCash => 'Kas awal';

  @override
  String get shiftOpen => 'Buka shift';

  @override
  String get shiftNoPermission =>
      'Minta manajer atau kasir yang berwenang membuka shift.';

  @override
  String payTitle(String number) {
    return 'Pembayaran $number';
  }

  @override
  String get payDue => 'Total tagihan';

  @override
  String payCustomer(String name) {
    return 'Pelanggan: $name';
  }

  @override
  String payRemaining(String amount) {
    return 'Sisa $amount';
  }

  @override
  String payChange(String amount) {
    return 'Kembalian $amount';
  }

  @override
  String payKasbonNote(String amount, int days) {
    return 'Kasbon $amount, jatuh tempo $days hari.';
  }

  @override
  String get payFinish => 'Selesaikan transaksi';

  @override
  String get payMethod => 'Metode pembayaran';

  @override
  String get payQuickCash => 'Uang diterima';

  @override
  String get payExact => 'Uang pas';

  @override
  String get payTendered => 'Uang diterima';

  @override
  String get payAmount => 'Jumlah';

  @override
  String get payReference => 'No. referensi / approval';

  @override
  String get payReferenceOptional => 'No. referensi (opsional)';

  @override
  String payReferenceRequired(String method) {
    return '$method butuh nomor referensi.';
  }

  @override
  String payAdd(String method) {
    return 'Tambah $method';
  }

  @override
  String get payInvalidAmount => 'Isi jumlah di atas 0.';

  @override
  String get payNonCashTooMuch =>
      'Pembayaran non-tunai melebihi tagihan. Kembalian hanya dari tunai.';

  @override
  String get payOneKasbon => 'Kasbon hanya boleh satu kali per tagihan.';

  @override
  String get payUnneeded => 'Tunai ini tidak diperlukan, tagihan sudah lunas.';

  @override
  String get payShiftRequired =>
      'Buka shift dulu sebelum menyelesaikan transaksi.';

  @override
  String get payNotPaid => 'Pembayaran belum sama dengan tagihan.';

  @override
  String get payKasbonCustomer => 'Kasbon butuh pelanggan.';

  @override
  String get receiptTitle => 'Struk';

  @override
  String get receiptCashier => 'Kasir';

  @override
  String get receiptCustomer => 'Pelanggan';

  @override
  String get receiptSubtotal => 'Subtotal';

  @override
  String get receiptService => 'Biaya layanan';

  @override
  String receiptTaxIncluded(String tax, String rate) {
    return 'Termasuk $tax $rate';
  }

  @override
  String receiptTaxAdded(String tax, String rate) {
    return '$tax $rate';
  }

  @override
  String get receiptTaxBase => 'DPP';

  @override
  String get receiptRounding => 'Pembulatan';

  @override
  String get receiptTotal => 'Total';

  @override
  String get receiptChange => 'Kembali';

  @override
  String get receiptTendered => 'Diterima';

  @override
  String receiptKasbonDue(String date) {
    return 'Kasbon jatuh tempo $date';
  }

  @override
  String get receiptCancelled => 'DIBATALKAN';

  @override
  String get receiptHeld => 'BELUM DIBAYAR';

  @override
  String receiptItems(int count) {
    return '$count item';
  }

  @override
  String get receiptShare => 'Bagikan PDF';

  @override
  String get receiptPrint => 'Cetak';

  @override
  String get receiptReprint => 'Cetak ulang';

  @override
  String get receiptNewSale => 'Transaksi baru';

  @override
  String get receiptMissing => 'Struk tidak ditemukan di terminal ini.';

  @override
  String get ordersTitle => 'Transaksi';

  @override
  String get ordersToday => 'Hari ini';

  @override
  String ordersHeld(int count) {
    return 'Ditahan ($count)';
  }

  @override
  String get ordersTodayTotal => 'Penjualan hari ini';

  @override
  String ordersTodayCount(int count) {
    return '$count transaksi lunas di terminal ini';
  }

  @override
  String get ordersNone => 'Belum ada transaksi hari ini.';

  @override
  String get ordersNoHeld => 'Tidak ada tagihan yang ditahan.';

  @override
  String get ordersStatusHeld => 'Ditahan';

  @override
  String get ordersStatusCancelled => 'Batal';

  @override
  String get ordersStatusPaid => 'Lunas';

  @override
  String get ordersResumeTitle => 'Lanjutkan tagihan?';

  @override
  String get ordersResumeReplace =>
      'Tagihan yang sedang dibuka akan dikosongkan. Tahan dulu jika masih dipakai.';

  @override
  String get ordersCancel => 'Batalkan';

  @override
  String ordersCancelTitle(String number) {
    return 'Batalkan $number?';
  }

  @override
  String get ordersCancelReason => 'Alasan';

  @override
  String get ordersCancelReasonShort => 'Tulis alasan minimal 3 huruf.';

  @override
  String ordersCancelled(String number) {
    return 'Tagihan $number dibatalkan.';
  }

  @override
  String get commonDone => 'Selesai';

  @override
  String get commonSearch => 'Cari';

  @override
  String get navPromotions => 'Promo';

  @override
  String get navVouchers => 'Voucher';

  @override
  String get navSettings => 'Pengaturan toko';

  @override
  String get promosEmpty => 'Belum ada promo.';

  @override
  String get promoMissing => 'Promo ini tidak ditemukan.';

  @override
  String get promoNew => 'Promo baru';

  @override
  String get promoGeneral => 'Umum';

  @override
  String get promoName => 'Nama promo';

  @override
  String get promoDescription => 'Keterangan';

  @override
  String get promoType => 'Jenis promo';

  @override
  String get promoTypeHappyHour => 'Diskon jam tertentu';

  @override
  String get promoTypeBuyXGetY => 'Beli X gratis/diskon Y';

  @override
  String get promoTypeBundle => 'Paket harga';

  @override
  String get promoTypeTiered => 'Diskon grosir (jumlah)';

  @override
  String get promoTypeMinPurchase => 'Minimal belanja';

  @override
  String get promoPriority => 'Prioritas';

  @override
  String get promoPriorityHint => 'Angka kecil dijalankan lebih dulu.';

  @override
  String get promoStackable => 'Bisa digabung';

  @override
  String get promoStackableHint =>
      'Jika mati, barang yang sudah kena promo lain tidak ikut, dan promo sesudahnya tidak berlaku untuk barang ini.';

  @override
  String get promoRules => 'Aturan';

  @override
  String get promoScope => 'Berlaku untuk';

  @override
  String get promoScopeAll => 'Semua produk';

  @override
  String get promoScopeCategories => 'Kategori';

  @override
  String get promoScopeProducts => 'Produk';

  @override
  String get promoScopeVariants => 'Varian (SKU)';

  @override
  String get promoDiscountPerUnit => 'Diskon (Rp per unit)';

  @override
  String get promoBuyScope => 'Beli barang';

  @override
  String get promoBuyQuantity => 'Jumlah beli';

  @override
  String get promoGetScope => 'Dapat barang';

  @override
  String get promoGetQuantity => 'Jumlah dapat';

  @override
  String get promoGetDiscount => 'Diskon barang yang didapat (100% = gratis)';

  @override
  String get promoMaxApplications => 'Maks. berlaku per transaksi';

  @override
  String get promoUnlimitedHint => 'Kosongkan untuk tanpa batas';

  @override
  String promoComponent(int index) {
    return 'Isi paket $index';
  }

  @override
  String get promoQty => 'Jumlah';

  @override
  String get promoAddComponent => 'Tambah isi paket';

  @override
  String get promoBundlePrice => 'Harga paket';

  @override
  String get promoMinQuantity => 'Mulai jumlah';

  @override
  String get promoAddTier => 'Tambah tingkat';

  @override
  String get promoMinSubtotal => 'Minimal belanja';

  @override
  String get promoBillDiscount => 'Potongan tagihan';

  @override
  String get promoWhen => 'Waktu berlaku';

  @override
  String get promoStartsAnytime => 'Mulai: kapan saja';

  @override
  String promoStarts(String date) {
    return 'Mulai $date';
  }

  @override
  String get promoEndsNever => 'Selesai: tidak ada';

  @override
  String promoEnds(String date) {
    return 'Sampai $date';
  }

  @override
  String get promoClearPeriod => 'Hapus tanggal';

  @override
  String get promoDays => 'Hari (kosong = setiap hari)';

  @override
  String get promoEveryDay => 'Berlaku setiap hari.';

  @override
  String get promoHours => 'Jam';

  @override
  String get promoAllDay => 'Sepanjang hari';

  @override
  String get promoStores => 'Toko';

  @override
  String get promoAllStores => 'Tidak ada yang dipilih: berlaku di semua toko.';

  @override
  String promoStoreCount(int count) {
    return '$count toko';
  }

  @override
  String get promoPeriodInvalid =>
      'Tanggal selesai harus setelah tanggal mulai.';

  @override
  String get promoProblemName => 'Isi nama promo.';

  @override
  String get promoProblemWindow =>
      'Isi jam mulai dan jam selesai, atau kosongkan keduanya.';

  @override
  String get promoProblemHappyHour =>
      'Diskon jam tertentu butuh jam mulai dan selesai.';

  @override
  String get promoProblemScope => 'Pilih barang yang berlaku.';

  @override
  String get promoProblemQuantity => 'Jumlah harus angka bulat di atas 0.';

  @override
  String get promoProblemComponents => 'Paket butuh minimal 2 isi.';

  @override
  String get promoProblemTiers => 'Tingkat jumlah harus naik, mulai dari 1.';

  @override
  String promoSummaryDiscount(String discount) {
    return 'diskon $discount';
  }

  @override
  String promoSummaryBuyGet(int buy, int get, String discount) {
    return 'beli $buy dapat $get diskon $discount';
  }

  @override
  String promoSummaryBundle(int count, String price) {
    return '$count barang jadi $price';
  }

  @override
  String promoSummaryMinPurchase(String min, String discount) {
    return 'belanja $min hemat $discount';
  }

  @override
  String get vouchersEmpty => 'Belum ada voucher.';

  @override
  String get voucherNew => 'Voucher baru';

  @override
  String get voucherCodeHint => '3–32 huruf besar, angka, - atau _';

  @override
  String voucherMinSubtotal(String amount) {
    return 'min. $amount';
  }

  @override
  String voucherMaxDiscount(String amount) {
    return 'maks. $amount';
  }

  @override
  String voucherUsed(int used, String max) {
    return 'dipakai $used/$max';
  }

  @override
  String voucherUntil(String date) {
    return 's.d. $date';
  }

  @override
  String get voucherMaxDiscountLabel => 'Diskon maksimal (opsional)';

  @override
  String get voucherMinSubtotalLabel => 'Minimal belanja (opsional)';

  @override
  String get voucherMaxUses => 'Kuota total (opsional)';

  @override
  String get voucherPerCustomer => 'Maks. per pelanggan (opsional)';

  @override
  String get voucherCountInvalid => 'Angka bulat di atas 0.';

  @override
  String get settingsTax => 'Pajak';

  @override
  String get settingsTaxEnabled => 'Kenakan pajak';

  @override
  String get settingsTaxName => 'Nama pajak';

  @override
  String get settingsRate => 'Tarif';

  @override
  String get settingsTaxInclusive => 'Harga sudah termasuk pajak';

  @override
  String get settingsTaxInclusiveHint =>
      'Rp 25.000 dengan PPN 11% berisi PPN Rp 2.477.';

  @override
  String get settingsTaxExclusiveHint => 'Pajak ditambahkan di atas harga.';

  @override
  String get settingsServiceCharge => 'Biaya layanan';

  @override
  String get settingsServiceChargeEnabled => 'Kenakan biaya layanan';

  @override
  String get settingsServiceChargeTaxable => 'Biaya layanan kena pajak';

  @override
  String get settingsCashier => 'Kasir';

  @override
  String get settingsRounding => 'Pembulatan total';

  @override
  String get settingsRoundingNone => 'Tidak dibulatkan';

  @override
  String get settingsRoundingNearest => 'Terdekat';

  @override
  String get settingsRoundingUp => 'Ke atas';

  @override
  String get settingsRoundingDown => 'Ke bawah';

  @override
  String get settingsRoundingUnit => 'Kelipatan';

  @override
  String get settingsDiscountLimit => 'Batas diskon tanpa persetujuan';

  @override
  String get settingsDiscountLimitHint =>
      'Diskon manual di atas batas ini perlu PIN manajer.';

  @override
  String get settingsKasbon => 'Izinkan kasbon';

  @override
  String get settingsReceipt => 'Struk';

  @override
  String get settingsReceiptHeader => 'Judul struk';

  @override
  String get settingsReceiptFooter => 'Catatan kaki struk';

  @override
  String get settingsPaymentMethods => 'Metode pembayaran';

  @override
  String get settingsPaymentMethodsHint =>
      'Yang aktif muncul di layar pembayaran toko ini.';

  @override
  String get settingsNeedsReference => 'perlu no. referensi';

  @override
  String get settingsPercentInvalid => 'Isi persen 0–100.';

  @override
  String get posShift => 'Shift';

  @override
  String posShiftOpenSince(String time, String name) {
    return 'Buka sejak $time · $name';
  }

  @override
  String get posShiftNone => 'Belum ada shift terbuka';

  @override
  String get posPrinter => 'Printer';

  @override
  String get posPrinterNone => 'Belum diatur';

  @override
  String get shiftTitle => 'Shift';

  @override
  String get shiftNoneOpen =>
      'Belum ada shift terbuka. Buka shift di layar Kasir.';

  @override
  String get shiftGoSell => 'Ke Kasir';

  @override
  String get shiftDrawerExpected => 'Uang di laci seharusnya';

  @override
  String shiftOpenedBy(String time, String name) {
    return 'Dibuka $time oleh $name';
  }

  @override
  String get shiftCashIn => 'Kas masuk';

  @override
  String get shiftCashOut => 'Kas keluar';

  @override
  String get shiftOpenDrawer => 'Buka laci';

  @override
  String get shiftPrintX => 'Cetak X';

  @override
  String get shiftClose => 'Tutup shift';

  @override
  String get shiftMovements => 'Kas masuk & keluar';

  @override
  String get shiftNoMovements => 'Belum ada kas masuk atau keluar.';

  @override
  String get shiftHistory => 'Shift sebelumnya';

  @override
  String shiftHistoryLine(String date, String name) {
    return '$date · $name';
  }

  @override
  String get shiftMovementAmount => 'Jumlah';

  @override
  String get shiftMovementReason => 'Keterangan';

  @override
  String shiftMovementSaved(String kind, String amount) {
    return '$kind $amount dicatat.';
  }

  @override
  String shiftDrawerShort(String amount) {
    return 'Uang di laci hanya $amount.';
  }

  @override
  String get shiftReport => 'Laporan shift';

  @override
  String get drawerReasonTitle => 'Buka laci tanpa transaksi';

  @override
  String drawerApprovalReason(String reason) {
    return 'Membuka laci tanpa transaksi: $reason';
  }

  @override
  String get drawerOpened => 'Laci dibuka.';

  @override
  String get drawerNotSet =>
      'Printer ini tidak diatur untuk membuka laci. Ubah di Pengaturan printer.';

  @override
  String get closeTitle => 'Tutup shift';

  @override
  String get closeCountByNotes => 'Hitung per pecahan';

  @override
  String get closeEnterTotal => 'Masukkan total';

  @override
  String get closeCounted => 'Uang dihitung';

  @override
  String get closeExpected => 'Seharusnya';

  @override
  String get closeDifference => 'Selisih';

  @override
  String get closeEven => 'Pas';

  @override
  String closeOver(String amount) {
    return 'Lebih $amount';
  }

  @override
  String closeShort(String amount) {
    return 'Kurang $amount';
  }

  @override
  String get closeNote => 'Catatan';

  @override
  String get closeNoteRequired => 'Jelaskan selisihnya.';

  @override
  String closeHeldWarning(int count) {
    return '$count tagihan masih ditahan. Tagihan itu tetap ditahan setelah shift ditutup.';
  }

  @override
  String closePending(int count) {
    return '$count transaksi belum terkirim. Semuanya dikirim sebelum penutupan shift.';
  }

  @override
  String get closeConfirmTitle => 'Tutup shift sekarang?';

  @override
  String closeConfirmBody(String counted, String expected) {
    return 'Uang dihitung $counted, seharusnya $expected. Setelah ditutup, penjualan perlu shift baru.';
  }

  @override
  String get closeDone => 'Shift ditutup.';

  @override
  String get reportTitleX => 'Laporan X';

  @override
  String get reportTitleZ => 'Laporan Z';

  @override
  String get reportTerminal => 'Terminal';

  @override
  String get reportOpened => 'Dibuka';

  @override
  String get reportClosed => 'Ditutup';

  @override
  String get reportSales => 'Penjualan';

  @override
  String get reportTransactions => 'Transaksi';

  @override
  String get reportGross => 'Penjualan kotor';

  @override
  String get reportDiscounts => 'Diskon';

  @override
  String get reportNet => 'Penjualan bersih';

  @override
  String get reportService => 'Biaya layanan';

  @override
  String get reportTax => 'Pajak';

  @override
  String get reportRounding => 'Pembulatan';

  @override
  String get reportTotal => 'Total';

  @override
  String get reportAverage => 'Rata-rata per transaksi';

  @override
  String get reportPayments => 'Pembayaran';

  @override
  String get reportCorrections => 'Koreksi';

  @override
  String get reportVoids => 'Void';

  @override
  String get reportCancelled => 'Tagihan dibatalkan';

  @override
  String get reportRefunds => 'Refund';

  @override
  String get reportKasbonIssued => 'Kasbon baru';

  @override
  String get reportKasbonRepaid => 'Kasbon dibayar';

  @override
  String get reportCash => 'Kas';

  @override
  String get reportOpeningCash => 'Kas awal';

  @override
  String get reportCashSales => 'Penjualan tunai';

  @override
  String get reportVoidedCash => 'Void tunai';

  @override
  String get reportCashRefunds => 'Refund tunai';

  @override
  String get reportKasbonCash => 'Kasbon dibayar tunai';

  @override
  String get reportCashIn => 'Kas masuk';

  @override
  String get reportCashOut => 'Kas keluar';

  @override
  String get reportExpected => 'Kas seharusnya';

  @override
  String get reportCounted => 'Kas dihitung';

  @override
  String get reportDifference => 'Selisih';

  @override
  String get reportTopItems => 'Produk terlaris';

  @override
  String reportPrintedAt(String time) {
    return 'Dicetak $time';
  }

  @override
  String get reportPrint => 'Cetak';

  @override
  String get reportShare => 'Bagikan PDF';

  @override
  String get reportMissing => 'Shift tidak ditemukan.';

  @override
  String get receiptVoided => 'VOID - DIBATALKAN';

  @override
  String get receiptCopy => 'SALINAN';

  @override
  String get receiptVoid => 'Void';

  @override
  String get receiptRefund => 'Refund';

  @override
  String receiptRefundLine(String number, String method) {
    return '$number · $method';
  }

  @override
  String receiptVoidedLine(String time, String name, String reason) {
    return 'Di-void $time oleh $name: $reason';
  }

  @override
  String get receiptPrinted => 'Struk dikirim ke printer.';

  @override
  String voidTitle(String number) {
    return 'Void $number?';
  }

  @override
  String get voidReason => 'Alasan void';

  @override
  String voidApproval(String number) {
    return 'Void $number.';
  }

  @override
  String voidApprovalPrinted(String number) {
    return 'Void $number setelah struk dicetak.';
  }

  @override
  String voidDone(String number) {
    return '$number di-void. Stok dikembalikan.';
  }

  @override
  String get reasonShort => 'Tulis alasan, minimal 3 huruf.';

  @override
  String printFailed(String reason) {
    return 'Gagal mencetak: $reason';
  }

  @override
  String get printNotConfigured =>
      'Belum ada printer. Atur di Pengaturan printer, atau bagikan PDF.';

  @override
  String get printUnsupported => 'Printer ini tidak didukung di perangkat ini.';

  @override
  String get printConnectFailed =>
      'Tidak bisa terhubung ke printer. Pastikan printer menyala dan dekat.';

  @override
  String get printSendFailed => 'Data gagal dikirim ke printer.';

  @override
  String get printInvalidAddress => 'Alamat printer tidak valid.';

  @override
  String get printSystemDialog => 'Cetak lewat dialog sistem';

  @override
  String refundTitle(String number) {
    return 'Refund $number';
  }

  @override
  String get refundPickItems => 'Pilih barang yang dikembalikan';

  @override
  String get refundAll => 'Semua';

  @override
  String refundLeft(String left, String sold) {
    return 'Sisa $left dari $sold';
  }

  @override
  String get refundRestock => 'Kembalikan ke stok';

  @override
  String get refundRestockHint => 'Matikan untuk barang rusak yang dibuang.';

  @override
  String get refundMethod => 'Dikembalikan lewat';

  @override
  String get refundViaCash => 'Tunai';

  @override
  String get refundViaQris => 'QRIS';

  @override
  String get refundViaCard => 'Kartu';

  @override
  String get refundViaTransfer => 'Transfer';

  @override
  String get refundViaEwallet => 'E-wallet';

  @override
  String get refundReason => 'Alasan refund';

  @override
  String get refundTotal => 'Total refund';

  @override
  String refundRefundable(String amount) {
    return 'Bisa dikembalikan: $amount';
  }

  @override
  String refundSubmit(String amount) {
    return 'Refund $amount';
  }

  @override
  String refundApproval(String amount, String number) {
    return 'Refund $amount untuk $number.';
  }

  @override
  String refundDone(String number) {
    return 'Refund $number tercatat.';
  }

  @override
  String get refundNothing => 'Pilih minimal satu barang.';

  @override
  String get refundExceedsPaid =>
      'Melebihi uang yang diterima. Bagian kasbon belum bisa di-refund.';

  @override
  String get refundZero =>
      'Barang ini gratis; tidak ada uang untuk dikembalikan.';

  @override
  String get refundQuantity => 'Jumlah melebihi sisa yang bisa dikembalikan.';

  @override
  String get refundFull => 'Semua sudah di-refund.';

  @override
  String get refundSlipTitle => 'REFUND';

  @override
  String refundSlipOrder(String number) {
    return 'Dari transaksi $number';
  }

  @override
  String refundSlipStaff(String name) {
    return 'Kasir: $name';
  }

  @override
  String refundSlipApprover(String name) {
    return 'Disetujui: $name';
  }

  @override
  String refundSlipMethod(String method) {
    return 'Dikembalikan: $method';
  }

  @override
  String refundSlipReason(String reason) {
    return 'Alasan: $reason';
  }

  @override
  String get posErrShiftClosed => 'Shift sudah ditutup.';

  @override
  String get posErrNotCompleted =>
      'Hanya transaksi selesai yang bisa di-void atau di-refund.';

  @override
  String get posErrVoidAfterRefund =>
      'Transaksi yang sudah di-refund tidak bisa di-void.';

  @override
  String get posErrRefundMethod => 'Metode refund tidak valid.';

  @override
  String posErrPermission(String permission) {
    return 'Perlu izin $permission.';
  }

  @override
  String get printerTitle => 'Pengaturan printer';

  @override
  String get printerNone => 'Belum ada printer struk.';

  @override
  String get printerConnection => 'Sambungan';

  @override
  String get printerBluetooth => 'Bluetooth';

  @override
  String get printerUsb => 'USB';

  @override
  String get printerNetwork => 'Jaringan';

  @override
  String get printerSearch => 'Cari printer';

  @override
  String get printerSearching => 'Mencari printer…';

  @override
  String get printerFoundNone =>
      'Tidak ada printer ditemukan. Nyalakan printer dan Bluetooth, lalu coba lagi.';

  @override
  String get printerName => 'Nama printer';

  @override
  String get printerAddress => 'Alamat';

  @override
  String get printerAddressHint => 'Contoh 192.168.1.50 atau 192.168.1.50:9100';

  @override
  String get printerPaper => 'Lebar kertas';

  @override
  String printerPaperMm(int mm) {
    return '$mm mm';
  }

  @override
  String get printerOpensDrawer => 'Buka laci kas lewat printer';

  @override
  String get printerAutoPrint => 'Cetak struk otomatis setelah bayar';

  @override
  String get printerTest => 'Tes cetak';

  @override
  String get printerTestTitle => 'TES PRINTER';

  @override
  String printerTestLine(int mm, int columns) {
    return 'Kertas $mm mm · $columns kolom';
  }

  @override
  String get printerTestSent => 'Halaman tes dikirim.';

  @override
  String get printerSaved => 'Printer disimpan.';

  @override
  String get printerRemove => 'Hapus printer';

  @override
  String get printerRemoved => 'Printer dihapus.';

  @override
  String get printerAddressRequired => 'Pilih atau isi alamat printer.';

  @override
  String get printerDiscoverUnsupported =>
      'Pencarian printer tidak tersedia di perangkat ini. Pakai printer jaringan.';

  @override
  String get navShifts => 'Shift';

  @override
  String get navAudit => 'Log audit';

  @override
  String get adminAllStores => 'Semua toko';

  @override
  String adminPeriod(String from, String to) {
    return '$from – $to';
  }

  @override
  String get shiftsEmpty => 'Tidak ada shift di periode ini.';

  @override
  String get shiftsOpen => 'Masih buka';

  @override
  String shiftsSales(String amount) {
    return 'Penjualan $amount';
  }

  @override
  String get auditOnlyApprovals => 'Hanya persetujuan';

  @override
  String get auditKind => 'Jenis';

  @override
  String get auditAll => 'Semua';

  @override
  String get auditKindOrders => 'Penjualan';

  @override
  String get auditKindShifts => 'Shift';

  @override
  String get auditKindCash => 'Kas';

  @override
  String get auditKindPos => 'Laci kas';

  @override
  String get auditKindReceipts => 'Struk';

  @override
  String get auditKindDevices => 'Terminal';

  @override
  String get auditKindData => 'Perubahan data';

  @override
  String get auditEmpty => 'Tidak ada catatan.';

  @override
  String get auditLoadMore => 'Muat lagi';

  @override
  String auditApprovedBy(String name) {
    return 'disetujui $name';
  }

  @override
  String get auditSystem => 'Sistem';

  @override
  String auditActionName(String action) {
    String _temp0 = intl.Intl.selectLogic(action, {
      'shift_opened': 'Shift dibuka',
      'shift_closed': 'Shift ditutup',
      'cash_movement_in': 'Kas masuk',
      'cash_movement_out': 'Kas keluar',
      'order_voided': 'Transaksi di-void',
      'order_refunded': 'Refund',
      'order_cancelled': 'Tagihan dibatalkan',
      'order_discount_approved': 'Diskon disetujui',
      'pos_drawer_open_no_sale': 'Laci dibuka tanpa transaksi',
      'receipt_reprinted': 'Struk dicetak ulang',
      'device_paired': 'Terminal dipasangkan',
      'device_revoked': 'Terminal dicabut',
      'device_pairing_code_created': 'Kode pasang dibuat',
      'employee_pin_set': 'PIN diatur',
      'catalog_imported': 'Katalog diimpor',
      'kasbon_repayment': 'Pembayaran kasbon',
      'other': '$action',
    });
    return '$_temp0';
  }

  @override
  String get pointsTitle => 'Tukar poin';

  @override
  String pointsBalance(int points) {
    return 'Saldo $points poin';
  }

  @override
  String pointsMax(int points, String amount) {
    return 'Maksimal $points poin ($amount)';
  }

  @override
  String pointsMin(int points) {
    return 'Minimal $points poin';
  }

  @override
  String get pointsField => 'Jumlah poin';

  @override
  String get pointsAll => 'Maks';

  @override
  String get pointsRemove => 'Hapus';

  @override
  String get pointsUse => 'Pakai';

  @override
  String pointsTooMany(int points) {
    return 'Paling banyak $points poin.';
  }

  @override
  String pointsBelowMin(int points) {
    return 'Paling sedikit $points poin.';
  }

  @override
  String pointsUsed(int points) {
    return '−$points poin';
  }

  @override
  String pointsButton(int points) {
    return '$points poin';
  }

  @override
  String get posErrPoints => 'Poin tidak cukup atau di bawah minimum.';

  @override
  String get posErrVoidKasbonPaid =>
      'Kasbon ini sudah dicicil; lakukan refund, bukan void.';

  @override
  String receiptPointsEarned(int points) {
    return 'Poin didapat: $points';
  }

  @override
  String get posCustomers => 'Pelanggan';

  @override
  String get posCustomersHint => 'Poin, kasbon dan cicilan';

  @override
  String get customersTitle => 'Pelanggan';

  @override
  String get customersSearch => 'Cari nama, nomor HP atau kode';

  @override
  String get customersEmpty => 'Tidak ada pelanggan.';

  @override
  String customersPoints(int points) {
    return '$points poin';
  }

  @override
  String customersOwes(String amount) {
    return 'Kasbon $amount';
  }

  @override
  String get customerEdit => 'Ubah pelanggan';

  @override
  String get customerSaved => 'Pelanggan disimpan.';

  @override
  String customerTotalOwed(String amount) {
    return 'Kasbon $amount';
  }

  @override
  String get customerPay => 'Bayar kasbon';

  @override
  String get customerKasbon => 'Kasbon';

  @override
  String get customerNoKasbon => 'Tidak ada kasbon.';

  @override
  String customerKasbonLine(String left, String amount) {
    return 'Sisa $left dari $amount';
  }

  @override
  String customerDue(String date) {
    return 'Jatuh tempo $date';
  }

  @override
  String customerOverdue(int days) {
    return 'Terlambat $days hari';
  }

  @override
  String get customerInstallments => 'Cicilan di terminal ini';

  @override
  String repayTitle(String name) {
    return 'Bayar kasbon $name';
  }

  @override
  String repayOwed(String amount) {
    return 'Kasbon $amount';
  }

  @override
  String get repayAmount => 'Jumlah';

  @override
  String get repayAll => 'Lunasi';

  @override
  String get repayMethod => 'Metode';

  @override
  String get repayReference => 'Referensi';

  @override
  String get repayInvalid => 'Isi jumlah.';

  @override
  String get repayNothing => 'Tidak ada kasbon.';

  @override
  String get repayExceeds => 'Melebihi sisa kasbon.';

  @override
  String repayDone(String amount, String left) {
    return 'Cicilan $amount diterima. Sisa kasbon $left.';
  }

  @override
  String get kasbonSlipTitle => 'PEMBAYARAN KASBON';

  @override
  String kasbonSlipCustomer(String name) {
    return 'Pelanggan: $name';
  }

  @override
  String kasbonSlipCashier(String name) {
    return 'Kasir: $name';
  }

  @override
  String get kasbonSlipBefore => 'Kasbon sebelumnya';

  @override
  String get kasbonSlipPaid => 'Dibayar';

  @override
  String get kasbonSlipAfter => 'Sisa kasbon';

  @override
  String kasbonSlipMethod(String method) {
    return 'Metode: $method';
  }

  @override
  String get kasbonSlipSettled => 'LUNAS';

  @override
  String get navCustomers => 'Pelanggan';

  @override
  String get navKasbon => 'Kasbon';

  @override
  String get navLoyalty => 'Loyalti & kasbon';

  @override
  String ledgerEntryType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'earn': 'Poin didapat',
      'redeem': 'Poin ditukar',
      'reverse_earn': 'Poin dibatalkan',
      'reverse_redeem': 'Poin dikembalikan',
      'adjust': 'Penyesuaian',
      'other': '$type',
    });
    return '$_temp0';
  }

  @override
  String kasbonStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'open': 'Belum dibayar',
      'partial': 'Dicicil',
      'paid': 'Lunas',
      'void': 'Batal',
      'other': '$status',
    });
    return '$_temp0';
  }

  @override
  String get adminCustomerEmail => 'E-mail';

  @override
  String get adminCustomerLimit => 'Batas kasbon';

  @override
  String get adminCustomerLimitHint => 'Kosongkan untuk tanpa batas';

  @override
  String adminCustomerLimitShort(String amount) {
    return 'Batas $amount';
  }

  @override
  String get adminAdjustPoints => 'Sesuaikan poin';

  @override
  String get adminAdjustPointsField => 'Poin (+ atau −)';

  @override
  String get adminAdjustNote => 'Alasan';

  @override
  String adminAdjustDone(int points) {
    return 'Saldo poin sekarang $points.';
  }

  @override
  String get adminPointsHistory => 'Riwayat poin';

  @override
  String adminKasbonPaidLine(String paid, String amount) {
    return 'Dibayar $paid dari $amount';
  }

  @override
  String adminKasbonTotal(String total, String overdue) {
    return 'Total $total · terlambat $overdue';
  }

  @override
  String get adminKasbonEmpty => 'Tidak ada kasbon terbuka.';

  @override
  String adminKasbonOldest(String date) {
    return 'Tertua $date';
  }

  @override
  String adminKasbonOverdue(String amount) {
    return 'Terlambat $amount';
  }

  @override
  String get loyaltyEnabled => 'Program poin aktif';

  @override
  String get loyaltyEarn => 'Belanja untuk 1 poin';

  @override
  String get loyaltyValue => 'Nilai 1 poin saat ditukar';

  @override
  String get loyaltyMin => 'Minimal poin sekali tukar';

  @override
  String get loyaltyDueDays => 'Jatuh tempo kasbon (hari)';

  @override
  String loyaltyRange(int min, int max) {
    return 'Isi angka $min–$max.';
  }

  @override
  String get loyaltyOwnerOnly =>
      'Hanya pemilik yang bisa mengubah pengaturan ini.';

  @override
  String get loyaltyHint =>
      'Berlaku untuk semua toko. Terminal memakai pengaturan baru setelah sinkron berikutnya.';

  @override
  String cashMovementApproval(String kind, String amount, String reason) {
    return '$kind $amount membuka laci: $reason';
  }

  @override
  String get navReports => 'Laporan';

  @override
  String get reportTabSales => 'Penjualan';

  @override
  String get reportTabPayments => 'Pembayaran';

  @override
  String get reportTabProducts => 'Produk';

  @override
  String get reportTabStaff => 'Staf';

  @override
  String get reportTabTax => 'Pajak';

  @override
  String get reportTabStock => 'Nilai stok';

  @override
  String get periodToday => 'Hari ini';

  @override
  String get periodYesterday => 'Kemarin';

  @override
  String get periodLast7 => '7 hari';

  @override
  String get periodThisMonth => 'Bulan ini';

  @override
  String get periodLastMonth => 'Bulan lalu';

  @override
  String get periodCustom => 'Pilih tanggal';

  @override
  String get exportPdf => 'PDF';

  @override
  String get exportExcel => 'Excel';

  @override
  String get exportSaved => 'File disimpan.';

  @override
  String get reportEmpty => 'Tidak ada data di periode ini.';

  @override
  String reportStockSubtitle(String store, String time) {
    return '$store · per $time';
  }

  @override
  String get reportSummary => 'Ringkasan';

  @override
  String get reportItem => 'Rincian';

  @override
  String get summaryGross => 'Penjualan kotor';

  @override
  String get summaryDiscounts => 'Diskon';

  @override
  String get summaryNet => 'Penjualan setelah diskon';

  @override
  String get summaryService => 'Biaya layanan';

  @override
  String get summaryTax => 'Pajak ditambahkan atau termasuk';

  @override
  String get summaryRounding => 'Pembulatan';

  @override
  String get reportByHour => 'Penjualan per jam';

  @override
  String get reportSalesNote =>
      'Penjualan = transaksi selesai. Void tidak termasuk penjualan. Refund dihitung pada tanggal refund.';

  @override
  String get reportProductsNote =>
      'Bersih sebelum refund; refund ditampilkan sebagai qty refund.';

  @override
  String reportProductsMore(int shown, int total) {
    return 'Menampilkan $shown dari $total produk. Ekspor berisi daftar yang sama.';
  }

  @override
  String get reportTaxNote =>
      'Harga termasuk pajak: DPP = dasar pajak − PPN. Barang bebas pajak (sembako) tidak masuk dasar pajak.';

  @override
  String get reportStockNote =>
      'Nilai = stok × HPP saat ini. Stok minus tidak menambah nilai.';

  @override
  String get reportNegativeNote => 'Periksa dengan stok opname.';

  @override
  String get colDate => 'Tanggal';

  @override
  String get colOrders => 'Transaksi';

  @override
  String get colSales => 'Penjualan';

  @override
  String get colRefunds => 'Refund';

  @override
  String get colNetSales => 'Penjualan bersih';

  @override
  String get colStore => 'Toko';

  @override
  String get colMethod => 'Metode';

  @override
  String get colCount => 'Jumlah';

  @override
  String get colAmount => 'Nilai';

  @override
  String get colShare => 'Porsi';

  @override
  String get colProduct => 'Produk';

  @override
  String get colSku => 'SKU';

  @override
  String get colCategory => 'Kategori';

  @override
  String get colQty => 'Qty';

  @override
  String get colRefundedQty => 'Qty refund';

  @override
  String get colNet => 'Bersih';

  @override
  String get colCost => 'HPP';

  @override
  String get colMargin => 'Margin';

  @override
  String get colStaff => 'Staf';

  @override
  String get colAverage => 'Rata-rata';

  @override
  String get colDiscounts => 'Diskon';

  @override
  String get colVoids => 'Void';

  @override
  String get colBase => 'Dasar pajak';

  @override
  String get colDpp => 'DPP';

  @override
  String get colTax => 'PPN';

  @override
  String get colExempt => 'Bebas pajak';

  @override
  String get colStock => 'Stok';

  @override
  String get colValue => 'Nilai';

  @override
  String get totalRow => 'Total';

  @override
  String get sumItems => 'Barang terjual';

  @override
  String get sumKasbonIssued => 'Kasbon baru';

  @override
  String get sumKasbonRepaid => 'Kasbon dibayar';

  @override
  String get sumMargin => 'Margin kotor';

  @override
  String get sumStockValue => 'Nilai stok';

  @override
  String get sumNegative => 'Stok minus';

  @override
  String get sumLow => 'Stok menipis';

  @override
  String get dashTitle => 'Hari ini';

  @override
  String dashVsYesterday(String value) {
    return 'Kemarin $value';
  }

  @override
  String get dashLast7 => 'Penjualan 7 hari terakhir';

  @override
  String get dashTop => 'Produk terlaris hari ini';

  @override
  String get dashPayments => 'Pembayaran hari ini';

  @override
  String dashOpenShifts(int count) {
    return '$count shift terbuka';
  }

  @override
  String dashLowStock(int count) {
    return '$count stok menipis';
  }

  @override
  String dashAlerts(int count) {
    return '$count peringatan';
  }

  @override
  String dashOverdue(String amount) {
    return 'Kasbon terlambat $amount';
  }

  @override
  String get dashNothing => 'Belum ada penjualan hari ini.';

  @override
  String get dashAllReports => 'Semua laporan';

  @override
  String get navPurchasing => 'Pembelian';

  @override
  String get navTransfers => 'Transfer';

  @override
  String get navTables => 'Meja';

  @override
  String poStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'draft': 'Draf',
      'ordered': 'Dipesan',
      'partially_received': 'Diterima sebagian',
      'received': 'Diterima',
      'cancelled': 'Dibatalkan',
      'other': '$status',
    });
    return '$_temp0';
  }

  @override
  String get purchaseNew => 'PO baru';

  @override
  String get purchaseEmpty => 'Belum ada purchase order.';

  @override
  String purchaseLines(int count) {
    return '$count baris';
  }

  @override
  String get purchaseExpected => 'Tanggal diharapkan';

  @override
  String purchaseExpectedShort(String date) {
    return 'Diharapkan $date';
  }

  @override
  String get purchaseSupplier => 'Pemasok';

  @override
  String get purchaseAddItem => 'Tambah barang';

  @override
  String get purchaseSearchItem => 'Cari nama atau SKU';

  @override
  String get purchaseIncomplete =>
      'Pilih toko, pemasok dan minimal satu barang.';

  @override
  String purchaseQtyInvalid(String name) {
    return 'Periksa angka untuk $name.';
  }

  @override
  String purchaseQtyTooMuch(String name, String max) {
    return '$name: maksimal $max.';
  }

  @override
  String get purchaseQtyNone => 'Isi minimal satu jumlah.';

  @override
  String purchaseMax(String max) {
    return 'maks $max';
  }

  @override
  String get purchaseOrder => 'Pesan';

  @override
  String get purchaseOrdered => 'Pesanan dikirim';

  @override
  String get purchaseCancel => 'Batalkan';

  @override
  String get purchaseCancelled => 'PO dibatalkan';

  @override
  String get purchaseReceive => 'Terima barang';

  @override
  String purchaseReceiveTitle(String number) {
    return 'Terima barang · $number';
  }

  @override
  String purchaseReceived(String number) {
    return 'Diterima dengan nomor $number';
  }

  @override
  String get purchaseReceipts => 'Penerimaan barang';

  @override
  String get purchaseOrderedCol => 'Dipesan';

  @override
  String get purchaseReceivedCol => 'Diterima';

  @override
  String get purchaseCost => 'Harga beli';

  @override
  String get purchaseUnit => 'Satuan';

  @override
  String purchasePdfTitle(String number) {
    return 'Purchase order $number';
  }

  @override
  String get transferNew => 'Minta transfer';

  @override
  String get transferEmpty => 'Belum ada transfer.';

  @override
  String get transferIncoming => 'Masuk';

  @override
  String get transferOutgoing => 'Keluar';

  @override
  String transferStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'requested': 'Diminta',
      'approved': 'Disetujui',
      'in_transit': 'Dikirim',
      'received': 'Diterima',
      'rejected': 'Ditolak',
      'cancelled': 'Dibatalkan',
      'other': '$status',
    });
    return '$_temp0';
  }

  @override
  String transferEvent(String event) {
    String _temp0 = intl.Intl.selectLogic(event, {
      'requested': 'Diminta',
      'approved': 'Disetujui',
      'shipped': 'Dikirim',
      'received': 'Diterima',
      'rejected': 'Ditolak',
      'cancelled': 'Dibatalkan',
      'other': '$event',
    });
    return '$_temp0';
  }

  @override
  String get transferFrom => 'Dari toko (pengirim)';

  @override
  String get transferTo => 'Ke toko (penerima)';

  @override
  String get transferIncomplete =>
      'Pilih dua toko yang berbeda dan minimal satu barang.';

  @override
  String get transferSubmit => 'Kirim permintaan';

  @override
  String get transferApprove => 'Setujui';

  @override
  String get transferReject => 'Tolak';

  @override
  String get transferRejectReason => 'Alasan';

  @override
  String transferRejectedBecause(String reason) {
    return 'Ditolak: $reason';
  }

  @override
  String get transferShip => 'Kirim barang';

  @override
  String transferShipTitle(String number) {
    return 'Kirim barang · $number';
  }

  @override
  String transferReceiveTitle(String number) {
    return 'Terima · $number';
  }

  @override
  String get transferCancel => 'Batalkan transfer';

  @override
  String get transferRequested => 'Diminta';

  @override
  String get transferShipped => 'Dikirim';

  @override
  String get transferSenderStock => 'Stok pengirim';

  @override
  String get transferHistory => 'Riwayat';

  @override
  String get fnbMode => 'Mode F&B (resto/kafe)';

  @override
  String get fnbModeHint =>
      'Mengaktifkan meja, tiket dapur dan layar dapur di terminal toko ini.';

  @override
  String get fnbModeOwnerOnly => 'Hanya pemilik yang dapat mengubah ini.';

  @override
  String get tablesEmpty => 'Belum ada meja.';

  @override
  String get tableNew => 'Meja baru';

  @override
  String get tableEdit => 'Ubah meja';

  @override
  String get tableName => 'Nama';

  @override
  String get tableArea => 'Area (opsional)';

  @override
  String get tableCapacity => 'Jumlah kursi';

  @override
  String tableSeats(int count) {
    return '$count kursi';
  }

  @override
  String get tableInvalid => 'Isi nama dan minimal 1 kursi.';

  @override
  String get kitchenTitle => 'Dapur';

  @override
  String get kitchenRefresh => 'Muat ulang';

  @override
  String get kitchenEmpty => 'Tidak ada pesanan.';

  @override
  String get kitchenOffline =>
      'Tidak terhubung ke server. Menampilkan daftar terakhir.';

  @override
  String kitchenAge(int minutes) {
    return '$minutes\'';
  }

  @override
  String kitchenStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'new': 'Baru',
      'preparing': 'Dimasak',
      'ready': 'Siap',
      'served': 'Disajikan',
      'other': '$status',
    });
    return '$_temp0';
  }

  @override
  String get kitchenStart => 'Mulai';

  @override
  String get kitchenReady => 'Siap';

  @override
  String get kitchenServed => 'Disajikan';

  @override
  String get kitchenSend => 'Kirim ke dapur';

  @override
  String kitchenSent(String number) {
    return 'Terkirim ke dapur: $number';
  }

  @override
  String kitchenNoPrinter(String stations) {
    return 'Tidak ada printer untuk $stations: pesanan tampil di layar dapur.';
  }

  @override
  String get stationKitchen => 'Dapur';

  @override
  String get stationBar => 'Bar';

  @override
  String get orderTakeaway => 'Bawa pulang';

  @override
  String ticketTable(String table, int guests) {
    return '$table · $guests tamu';
  }

  @override
  String get ticketAddition => '-- TAMBAHAN --';

  @override
  String get posErrTableOccupied =>
      'Meja ini sudah punya bill terbuka. Lanjutkan bill tersebut.';

  @override
  String get posErrTableHasBill =>
      'Selesaikan atau batalkan bill di meja ini dulu.';

  @override
  String get posTablesHint => 'Bill makan di tempat per meja';

  @override
  String get posKitchenHint => 'Pesanan untuk dapur dan bar';

  @override
  String get printerSlotReceipt => 'Struk';

  @override
  String get printerSlotKitchen => 'Dapur';

  @override
  String get printerSlotBar => 'Bar';

  @override
  String get tablesEmptyTerminal =>
      'Belum ada meja. Tambahkan di back office (Meja).';

  @override
  String tableStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'available': 'Kosong',
      'occupied': 'Terisi',
      'reserved': 'Dipesan',
      'cleaning': 'Perlu dibereskan',
      'other': '$status',
    });
    return '$_temp0';
  }

  @override
  String get tableClear => 'Kosongkan meja';

  @override
  String tableCleared(String table) {
    return '$table kosong kembali';
  }

  @override
  String get tableFinishCurrent =>
      'Tahan atau selesaikan bill yang sedang dibuka dulu.';

  @override
  String tableOccupiedElsewhere(String table) {
    return '$table punya bill di terminal lain.';
  }

  @override
  String get tableGuests => 'Jumlah tamu';

  @override
  String tableGuestsTitle(String table) {
    return 'Tamu di $table';
  }

  @override
  String get tableSeat => 'Mulai bill';

  @override
  String get navGatewayPayments => 'Pembayaran QRIS';

  @override
  String get payQrisCreate => 'Buat QR';

  @override
  String qrisTitle(String amount) {
    return 'QRIS $amount';
  }

  @override
  String get qrisScan =>
      'Minta pelanggan memindai dengan aplikasi QRIS apa saja.';

  @override
  String qrisExpiresIn(String time) {
    return 'Berlaku $time';
  }

  @override
  String qrisPaid(String amount) {
    return 'Pembayaran QRIS diterima: $amount';
  }

  @override
  String get qrisExpired => 'QR kedaluwarsa. Tidak ada yang ditagih.';

  @override
  String get qrisCancelled => 'QR dibatalkan.';

  @override
  String get qrisFailed => 'Pembayaran gagal.';

  @override
  String get qrisNewQr => 'QR baru';

  @override
  String get qrisCancel => 'Batalkan QR';

  @override
  String get qrisOffline =>
      'Tidak ada koneksi. QRIS dinamis butuh internet; pakai tunai atau stiker QRIS.';

  @override
  String get qrisNotConfigured => 'Payment gateway belum diatur.';

  @override
  String qrisError(String code) {
    return 'Gagal membuat QR ($code).';
  }

  @override
  String get sellClearPaidQris =>
      'Pembayaran QRIS untuk bill ini sudah diterima. Selesaikan penjualannya.';

  @override
  String get gatewayOnlyUnmatched => 'Dibayar tanpa penjualan';

  @override
  String gatewayPaidTotal(String amount, int count) {
    return 'Dibayar $amount ($count)';
  }

  @override
  String gatewayUnmatchedTotal(String amount, int count) {
    return 'Tanpa penjualan $amount ($count)';
  }

  @override
  String get gatewayUnmatchedHint =>
      'Pelanggan sudah membayar tetapi tidak ada penjualan (bill tidak diselesaikan). Selesaikan bill di terminal, atau kembalikan dana dari dashboard Midtrans.';

  @override
  String get gatewayEmpty => 'Tidak ada pembayaran QRIS pada periode ini.';

  @override
  String get gatewayUnmatched => 'Dibayar, tanpa penjualan';

  @override
  String gatewayStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'pending': 'Menunggu',
      'paid': 'Dibayar',
      'failed': 'Gagal',
      'expired': 'Kedaluwarsa',
      'cancelled': 'Dibatalkan',
      'other': '$status',
    });
    return '$_temp0';
  }

  @override
  String get navRegister => 'Kasir & Pembayaran';

  @override
  String get navRegisterShort => 'Kasir';

  @override
  String get sectionOverview => 'Ringkasan';

  @override
  String get sectionCatalog => 'Katalog';

  @override
  String get sectionSales => 'Penjualan';

  @override
  String get sectionMembers => 'Member';

  @override
  String get sectionSettings => 'Pengaturan';

  @override
  String get shellRetailPos => 'POS Ritel';

  @override
  String get shellTagline => 'Kasir Ritel';

  @override
  String get shellHeldOrders => 'Pesanan ditahan';

  @override
  String get shellKitchen => 'Dapur';

  @override
  String get shellLock => 'Kunci';

  @override
  String get shellCollapse => 'Ciutkan menu';

  @override
  String get shellExpand => 'Lebarkan menu';

  @override
  String get shellMore => 'Lainnya';

  @override
  String get shellSearchHint => 'Pindai barcode atau cari SKU / barang';
}
