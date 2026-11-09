import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In id, this message translates to:
  /// **'CashierA'**
  String get appTitle;

  /// No description provided for @commonRetry.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get commonClose;

  /// No description provided for @commonError.
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan: {message}'**
  String commonError(String message);

  /// No description provided for @setupTitle.
  ///
  /// In id, this message translates to:
  /// **'Konfigurasi belum lengkap'**
  String get setupTitle;

  /// No description provided for @setupBody.
  ///
  /// In id, this message translates to:
  /// **'Jalankan aplikasi dengan --dart-define=SUPABASE_URL=... dan --dart-define=SUPABASE_ANON_KEY=... agar terhubung ke server.'**
  String get setupBody;

  /// No description provided for @welcomeTitle.
  ///
  /// In id, this message translates to:
  /// **'Selamat datang di CashierA'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih cara menggunakan perangkat ini.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomePairTerminal.
  ///
  /// In id, this message translates to:
  /// **'Pasangkan terminal kasir'**
  String get welcomePairTerminal;

  /// No description provided for @welcomePairTerminalHint.
  ///
  /// In id, this message translates to:
  /// **'Untuk tablet atau PC di toko. Minta kode dari manajer.'**
  String get welcomePairTerminalHint;

  /// No description provided for @welcomeBackOffice.
  ///
  /// In id, this message translates to:
  /// **'Masuk back office'**
  String get welcomeBackOffice;

  /// No description provided for @welcomeBackOfficeHint.
  ///
  /// In id, this message translates to:
  /// **'Untuk pemilik dan manajer: laporan, produk, staf.'**
  String get welcomeBackOfficeHint;

  /// No description provided for @pairTitle.
  ///
  /// In id, this message translates to:
  /// **'Pasangkan terminal'**
  String get pairTitle;

  /// No description provided for @pairBody.
  ///
  /// In id, this message translates to:
  /// **'Masukkan kode 8 karakter yang dibuat manajer di back office. Kode berlaku 15 menit.'**
  String get pairBody;

  /// No description provided for @pairCodeLabel.
  ///
  /// In id, this message translates to:
  /// **'Kode pasangan'**
  String get pairCodeLabel;

  /// No description provided for @pairButton.
  ///
  /// In id, this message translates to:
  /// **'Pasangkan'**
  String get pairButton;

  /// No description provided for @pairInvalidCode.
  ///
  /// In id, this message translates to:
  /// **'Kode terdiri dari 8 huruf/angka (tanpa O, 0, I, 1).'**
  String get pairInvalidCode;

  /// No description provided for @pairSuccess.
  ///
  /// In id, this message translates to:
  /// **'Terminal {code} terpasang di {store}.'**
  String pairSuccess(String code, String store);

  /// No description provided for @lockTitle.
  ///
  /// In id, this message translates to:
  /// **'Siapa yang bertugas?'**
  String get lockTitle;

  /// No description provided for @lockEnterPin.
  ///
  /// In id, this message translates to:
  /// **'PIN untuk {name}'**
  String lockEnterPin(String name);

  /// No description provided for @lockNoStaff.
  ///
  /// In id, this message translates to:
  /// **'Belum ada daftar staf. Sambungkan ke internet lalu perbarui.'**
  String get lockNoStaff;

  /// No description provided for @lockRefreshStaff.
  ///
  /// In id, this message translates to:
  /// **'Perbarui daftar staf'**
  String get lockRefreshStaff;

  /// No description provided for @lockStaffRefreshed.
  ///
  /// In id, this message translates to:
  /// **'Daftar staf diperbarui.'**
  String get lockStaffRefreshed;

  /// No description provided for @pinWrong.
  ///
  /// In id, this message translates to:
  /// **'PIN salah. Sisa {count} percobaan.'**
  String pinWrong(int count);

  /// No description provided for @pinLocked.
  ///
  /// In id, this message translates to:
  /// **'Terlalu banyak percobaan. Coba lagi pukul {time}.'**
  String pinLocked(String time);

  /// No description provided for @pinNoPin.
  ///
  /// In id, this message translates to:
  /// **'Belum ada PIN. Minta manajer mengaturnya di back office.'**
  String get pinNoPin;

  /// No description provided for @pinTooShort.
  ///
  /// In id, this message translates to:
  /// **'PIN minimal 4 angka.'**
  String get pinTooShort;

  /// No description provided for @statusOnline.
  ///
  /// In id, this message translates to:
  /// **'Online'**
  String get statusOnline;

  /// No description provided for @statusOffline.
  ///
  /// In id, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// No description provided for @statusPending.
  ///
  /// In id, this message translates to:
  /// **'{count} tertunda'**
  String statusPending(int count);

  /// No description provided for @posTitle.
  ///
  /// In id, this message translates to:
  /// **'Kasir'**
  String get posTitle;

  /// No description provided for @posOnDuty.
  ///
  /// In id, this message translates to:
  /// **'Bertugas: {name}'**
  String posOnDuty(String name);

  /// No description provided for @posTerminal.
  ///
  /// In id, this message translates to:
  /// **'Terminal {code}'**
  String posTerminal(String code);

  /// No description provided for @posLock.
  ///
  /// In id, this message translates to:
  /// **'Kunci / ganti kasir'**
  String get posLock;

  /// No description provided for @posOpenSync.
  ///
  /// In id, this message translates to:
  /// **'Status sinkronisasi'**
  String get posOpenSync;

  /// No description provided for @posStoreSettings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan toko'**
  String get posStoreSettings;

  /// No description provided for @posTaxLine.
  ///
  /// In id, this message translates to:
  /// **'{tax} {rate}% · {mode}'**
  String posTaxLine(String tax, String rate, String mode);

  /// No description provided for @posTaxInclusive.
  ///
  /// In id, this message translates to:
  /// **'termasuk harga'**
  String get posTaxInclusive;

  /// No description provided for @posTaxExclusive.
  ///
  /// In id, this message translates to:
  /// **'ditambahkan'**
  String get posTaxExclusive;

  /// No description provided for @posPaper.
  ///
  /// In id, this message translates to:
  /// **'Struk {mm} mm'**
  String posPaper(int mm);

  /// No description provided for @syncTitle.
  ///
  /// In id, this message translates to:
  /// **'Sinkronisasi'**
  String get syncTitle;

  /// No description provided for @syncNow.
  ///
  /// In id, this message translates to:
  /// **'Sinkronkan sekarang'**
  String get syncNow;

  /// No description provided for @syncEmpty.
  ///
  /// In id, this message translates to:
  /// **'Semua data sudah terkirim ke server.'**
  String get syncEmpty;

  /// No description provided for @syncStatusPending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu'**
  String get syncStatusPending;

  /// No description provided for @syncStatusSyncing.
  ///
  /// In id, this message translates to:
  /// **'Mengirim'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal'**
  String get syncStatusFailed;

  /// No description provided for @syncStatusDone.
  ///
  /// In id, this message translates to:
  /// **'Terkirim'**
  String get syncStatusDone;

  /// No description provided for @syncAttempts.
  ///
  /// In id, this message translates to:
  /// **'Percobaan: {count}'**
  String syncAttempts(int count);

  /// No description provided for @syncRetried.
  ///
  /// In id, this message translates to:
  /// **'Dijadwalkan ulang.'**
  String get syncRetried;

  /// No description provided for @syncRunResult.
  ///
  /// In id, this message translates to:
  /// **'{sent} terkirim, {failed} gagal'**
  String syncRunResult(int sent, int failed);

  /// No description provided for @syncOfflineNow.
  ///
  /// In id, this message translates to:
  /// **'Server tidak terjangkau. Akan dicoba lagi otomatis.'**
  String get syncOfflineNow;

  /// No description provided for @adminSignInTitle.
  ///
  /// In id, this message translates to:
  /// **'Masuk back office'**
  String get adminSignInTitle;

  /// No description provided for @adminEmail.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get adminEmail;

  /// No description provided for @adminPassword.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi'**
  String get adminPassword;

  /// No description provided for @adminSignIn.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get adminSignIn;

  /// No description provided for @adminEmailInvalid.
  ///
  /// In id, this message translates to:
  /// **'Masukkan email yang valid.'**
  String get adminEmailInvalid;

  /// No description provided for @adminPasswordShort.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi minimal 8 karakter.'**
  String get adminPasswordShort;

  /// No description provided for @adminNotStaff.
  ///
  /// In id, this message translates to:
  /// **'Akun ini belum terdaftar sebagai karyawan.'**
  String get adminNotStaff;

  /// No description provided for @adminTitle.
  ///
  /// In id, this message translates to:
  /// **'Back office'**
  String get adminTitle;

  /// No description provided for @adminSignOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get adminSignOut;

  /// No description provided for @adminRole.
  ///
  /// In id, this message translates to:
  /// **'{role} · {stores} toko'**
  String adminRole(String role, int stores);

  /// No description provided for @adminStores.
  ///
  /// In id, this message translates to:
  /// **'Toko'**
  String get adminStores;

  /// No description provided for @adminNoStores.
  ///
  /// In id, this message translates to:
  /// **'Belum ada toko yang bisa Anda akses.'**
  String get adminNoStores;

  /// No description provided for @adminPairTerminal.
  ///
  /// In id, this message translates to:
  /// **'Buat kode pasangan'**
  String get adminPairTerminal;

  /// No description provided for @adminDeviceName.
  ///
  /// In id, this message translates to:
  /// **'Nama terminal'**
  String get adminDeviceName;

  /// No description provided for @adminDeviceNameHint.
  ///
  /// In id, this message translates to:
  /// **'mis. Kasir 2'**
  String get adminDeviceNameHint;

  /// No description provided for @adminCreateCode.
  ///
  /// In id, this message translates to:
  /// **'Buat kode'**
  String get adminCreateCode;

  /// No description provided for @adminCodeTitle.
  ///
  /// In id, this message translates to:
  /// **'Kode pasangan'**
  String get adminCodeTitle;

  /// No description provided for @adminCodeBody.
  ///
  /// In id, this message translates to:
  /// **'Ketik kode ini di terminal baru sebelum pukul {time}.'**
  String adminCodeBody(String time);

  /// No description provided for @posCatalog.
  ///
  /// In id, this message translates to:
  /// **'Produk & stok'**
  String get posCatalog;

  /// No description provided for @posCatalogHint.
  ///
  /// In id, this message translates to:
  /// **'Cari produk, cek stok, catat stok masuk/keluar'**
  String get posCatalogHint;

  /// No description provided for @catalogTitle.
  ///
  /// In id, this message translates to:
  /// **'Produk & stok'**
  String get catalogTitle;

  /// No description provided for @catalogSearchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari nama, SKU, atau scan barcode'**
  String get catalogSearchHint;

  /// No description provided for @catalogAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get catalogAll;

  /// No description provided for @catalogEmpty.
  ///
  /// In id, this message translates to:
  /// **'Katalog belum ada di terminal ini. Sinkronkan saat online.'**
  String get catalogEmpty;

  /// No description provided for @catalogNoMatch.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada produk yang cocok.'**
  String get catalogNoMatch;

  /// No description provided for @catalogRefresh.
  ///
  /// In id, this message translates to:
  /// **'Sinkronkan katalog'**
  String get catalogRefresh;

  /// No description provided for @catalogLastSync.
  ///
  /// In id, this message translates to:
  /// **'Terakhir disinkronkan {time}'**
  String catalogLastSync(String time);

  /// No description provided for @catalogStock.
  ///
  /// In id, this message translates to:
  /// **'Stok {qty} {unit}'**
  String catalogStock(String qty, String unit);

  /// No description provided for @catalogLow.
  ///
  /// In id, this message translates to:
  /// **'Stok menipis'**
  String get catalogLow;

  /// No description provided for @catalogCodeNotFound.
  ///
  /// In id, this message translates to:
  /// **'Kode {code} tidak ditemukan.'**
  String catalogCodeNotFound(String code);

  /// No description provided for @catalogSynced.
  ///
  /// In id, this message translates to:
  /// **'Katalog diperbarui ({rows} perubahan).'**
  String catalogSynced(int rows);

  /// No description provided for @stockIn.
  ///
  /// In id, this message translates to:
  /// **'Stok masuk'**
  String get stockIn;

  /// No description provided for @stockOut.
  ///
  /// In id, this message translates to:
  /// **'Stok keluar'**
  String get stockOut;

  /// No description provided for @stockQuantity.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get stockQuantity;

  /// No description provided for @stockReason.
  ///
  /// In id, this message translates to:
  /// **'Alasan'**
  String get stockReason;

  /// No description provided for @stockNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan (opsional)'**
  String get stockNote;

  /// No description provided for @reasonStockIn.
  ///
  /// In id, this message translates to:
  /// **'Barang masuk'**
  String get reasonStockIn;

  /// No description provided for @reasonStockOut.
  ///
  /// In id, this message translates to:
  /// **'Barang keluar'**
  String get reasonStockOut;

  /// No description provided for @reasonDamaged.
  ///
  /// In id, this message translates to:
  /// **'Rusak'**
  String get reasonDamaged;

  /// No description provided for @reasonExpired.
  ///
  /// In id, this message translates to:
  /// **'Kedaluwarsa'**
  String get reasonExpired;

  /// No description provided for @reasonLost.
  ///
  /// In id, this message translates to:
  /// **'Hilang'**
  String get reasonLost;

  /// No description provided for @stockSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get stockSave;

  /// No description provided for @stockSaved.
  ///
  /// In id, this message translates to:
  /// **'Stok {name} diperbarui.'**
  String stockSaved(String name);

  /// No description provided for @stockInvalidQty.
  ///
  /// In id, this message translates to:
  /// **'Masukkan jumlah lebih dari 0 (maks. 3 desimal).'**
  String get stockInvalidQty;

  /// No description provided for @stockWholeOnly.
  ///
  /// In id, this message translates to:
  /// **'Satuan ini harus bilangan bulat.'**
  String get stockWholeOnly;

  /// No description provided for @opnameTitle.
  ///
  /// In id, this message translates to:
  /// **'Stok opname'**
  String get opnameTitle;

  /// No description provided for @opnameHint.
  ///
  /// In id, this message translates to:
  /// **'Isi jumlah yang dihitung. Baris kosong tidak diubah.'**
  String get opnameHint;

  /// No description provided for @opnameSubmit.
  ///
  /// In id, this message translates to:
  /// **'Kirim opname ({count} item)'**
  String opnameSubmit(int count);

  /// No description provided for @opnameConfirm.
  ///
  /// In id, this message translates to:
  /// **'Stok {count} item akan diganti dengan hasil hitungan. Lanjutkan?'**
  String opnameConfirm(int count);

  /// No description provided for @opnameDone.
  ///
  /// In id, this message translates to:
  /// **'Opname disimpan dan masuk antrean sinkronisasi.'**
  String get opnameDone;

  /// No description provided for @opnameSystem.
  ///
  /// In id, this message translates to:
  /// **'Sistem: {qty}'**
  String opnameSystem(String qty);

  /// No description provided for @commonContinue.
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan'**
  String get commonContinue;

  /// No description provided for @navHome.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan'**
  String get navHome;

  /// No description provided for @navProducts.
  ///
  /// In id, this message translates to:
  /// **'Produk'**
  String get navProducts;

  /// No description provided for @navCategories.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get navCategories;

  /// No description provided for @navSuppliers.
  ///
  /// In id, this message translates to:
  /// **'Pemasok'**
  String get navSuppliers;

  /// No description provided for @navStock.
  ///
  /// In id, this message translates to:
  /// **'Stok'**
  String get navStock;

  /// No description provided for @navImport.
  ///
  /// In id, this message translates to:
  /// **'Impor & ekspor'**
  String get navImport;

  /// No description provided for @commonSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get commonSave;

  /// No description provided for @commonAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get commonAdd;

  /// No description provided for @commonEdit.
  ///
  /// In id, this message translates to:
  /// **'Ubah'**
  String get commonEdit;

  /// No description provided for @commonSaved.
  ///
  /// In id, this message translates to:
  /// **'Tersimpan.'**
  String get commonSaved;

  /// No description provided for @commonActive.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get commonActive;

  /// No description provided for @commonInactive.
  ///
  /// In id, this message translates to:
  /// **'Nonaktif'**
  String get commonInactive;

  /// No description provided for @commonRequired.
  ///
  /// In id, this message translates to:
  /// **'Wajib diisi'**
  String get commonRequired;

  /// No description provided for @productsNew.
  ///
  /// In id, this message translates to:
  /// **'Produk baru'**
  String get productsNew;

  /// No description provided for @productsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada produk. Tambah satu atau impor dari file.'**
  String get productsEmpty;

  /// No description provided for @productsVariants.
  ///
  /// In id, this message translates to:
  /// **'{count} varian'**
  String productsVariants(int count);

  /// No description provided for @productsAllCategories.
  ///
  /// In id, this message translates to:
  /// **'Semua kategori'**
  String get productsAllCategories;

  /// No description provided for @productsReadOnly.
  ///
  /// In id, this message translates to:
  /// **'Hanya pemilik yang bisa mengubah katalog.'**
  String get productsReadOnly;

  /// No description provided for @productEditTitle.
  ///
  /// In id, this message translates to:
  /// **'Ubah produk'**
  String get productEditTitle;

  /// No description provided for @productNewTitle.
  ///
  /// In id, this message translates to:
  /// **'Produk baru'**
  String get productNewTitle;

  /// No description provided for @productName.
  ///
  /// In id, this message translates to:
  /// **'Nama produk'**
  String get productName;

  /// No description provided for @productCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get productCategory;

  /// No description provided for @productUnit.
  ///
  /// In id, this message translates to:
  /// **'Satuan'**
  String get productUnit;

  /// No description provided for @productTaxable.
  ///
  /// In id, this message translates to:
  /// **'Kena PPN'**
  String get productTaxable;

  /// No description provided for @productTaxableHint.
  ///
  /// In id, this message translates to:
  /// **'Matikan untuk barang bebas PPN (beras, gula, telur ...)'**
  String get productTaxableHint;

  /// No description provided for @productTrackStock.
  ///
  /// In id, this message translates to:
  /// **'Lacak stok'**
  String get productTrackStock;

  /// No description provided for @productVariants.
  ///
  /// In id, this message translates to:
  /// **'Varian'**
  String get productVariants;

  /// No description provided for @productAddVariant.
  ///
  /// In id, this message translates to:
  /// **'Tambah varian'**
  String get productAddVariant;

  /// No description provided for @variantName.
  ///
  /// In id, this message translates to:
  /// **'Nama varian'**
  String get variantName;

  /// No description provided for @variantSku.
  ///
  /// In id, this message translates to:
  /// **'SKU'**
  String get variantSku;

  /// No description provided for @variantBarcode.
  ///
  /// In id, this message translates to:
  /// **'Barcode'**
  String get variantBarcode;

  /// No description provided for @variantPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga jual'**
  String get variantPrice;

  /// No description provided for @variantCost.
  ///
  /// In id, this message translates to:
  /// **'HPP'**
  String get variantCost;

  /// No description provided for @variantRemove.
  ///
  /// In id, this message translates to:
  /// **'Hapus varian'**
  String get variantRemove;

  /// No description provided for @productStoreSettings.
  ///
  /// In id, this message translates to:
  /// **'Harga & stok minimum per toko'**
  String get productStoreSettings;

  /// No description provided for @storePriceOverride.
  ///
  /// In id, this message translates to:
  /// **'Harga khusus'**
  String get storePriceOverride;

  /// No description provided for @storeReorderPoint.
  ///
  /// In id, this message translates to:
  /// **'Stok minimum'**
  String get storeReorderPoint;

  /// No description provided for @validationMoney.
  ///
  /// In id, this message translates to:
  /// **'Angka rupiah tanpa titik, mis. 25000'**
  String get validationMoney;

  /// No description provided for @validationSku.
  ///
  /// In id, this message translates to:
  /// **'Huruf/angka . _ - (maks. 40)'**
  String get validationSku;

  /// No description provided for @categoriesEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kategori.'**
  String get categoriesEmpty;

  /// No description provided for @categoryName.
  ///
  /// In id, this message translates to:
  /// **'Nama kategori'**
  String get categoryName;

  /// No description provided for @categoryColor.
  ///
  /// In id, this message translates to:
  /// **'Warna (#RRGGBB)'**
  String get categoryColor;

  /// No description provided for @categoryOrderHint.
  ///
  /// In id, this message translates to:
  /// **'Seret untuk mengatur urutan di layar kasir.'**
  String get categoryOrderHint;

  /// No description provided for @suppliersEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pemasok.'**
  String get suppliersEmpty;

  /// No description provided for @supplierName.
  ///
  /// In id, this message translates to:
  /// **'Nama pemasok'**
  String get supplierName;

  /// No description provided for @supplierContact.
  ///
  /// In id, this message translates to:
  /// **'Kontak'**
  String get supplierContact;

  /// No description provided for @supplierPhone.
  ///
  /// In id, this message translates to:
  /// **'Telepon'**
  String get supplierPhone;

  /// No description provided for @supplierEmail.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get supplierEmail;

  /// No description provided for @supplierAddress.
  ///
  /// In id, this message translates to:
  /// **'Alamat'**
  String get supplierAddress;

  /// No description provided for @stockStore.
  ///
  /// In id, this message translates to:
  /// **'Toko'**
  String get stockStore;

  /// No description provided for @stockLowOnly.
  ///
  /// In id, this message translates to:
  /// **'Hanya stok menipis'**
  String get stockLowOnly;

  /// No description provided for @stockEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada produk yang dilacak stoknya.'**
  String get stockEmpty;

  /// No description provided for @stockReorder.
  ///
  /// In id, this message translates to:
  /// **'Min. {qty}'**
  String stockReorder(String qty);

  /// No description provided for @stockAlerts.
  ///
  /// In id, this message translates to:
  /// **'{count} peringatan terbuka'**
  String stockAlerts(int count);

  /// No description provided for @stockResolve.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get stockResolve;

  /// No description provided for @stockMovements.
  ///
  /// In id, this message translates to:
  /// **'Riwayat mutasi'**
  String get stockMovements;

  /// No description provided for @stockNoMovements.
  ///
  /// In id, this message translates to:
  /// **'Belum ada mutasi.'**
  String get stockNoMovements;

  /// No description provided for @movementType_initial.
  ///
  /// In id, this message translates to:
  /// **'Stok awal'**
  String get movementType_initial;

  /// No description provided for @movementType_sale.
  ///
  /// In id, this message translates to:
  /// **'Penjualan'**
  String get movementType_sale;

  /// No description provided for @movementType_sale_void.
  ///
  /// In id, this message translates to:
  /// **'Batal jual'**
  String get movementType_sale_void;

  /// No description provided for @movementType_refund.
  ///
  /// In id, this message translates to:
  /// **'Retur'**
  String get movementType_refund;

  /// No description provided for @movementType_purchase_receive.
  ///
  /// In id, this message translates to:
  /// **'Penerimaan barang'**
  String get movementType_purchase_receive;

  /// No description provided for @movementType_adjustment.
  ///
  /// In id, this message translates to:
  /// **'Penyesuaian'**
  String get movementType_adjustment;

  /// No description provided for @movementType_waste.
  ///
  /// In id, this message translates to:
  /// **'Rusak/hilang'**
  String get movementType_waste;

  /// No description provided for @movementType_opname.
  ///
  /// In id, this message translates to:
  /// **'Opname'**
  String get movementType_opname;

  /// No description provided for @movementType_transfer_out.
  ///
  /// In id, this message translates to:
  /// **'Transfer keluar'**
  String get movementType_transfer_out;

  /// No description provided for @movementType_transfer_in.
  ///
  /// In id, this message translates to:
  /// **'Transfer masuk'**
  String get movementType_transfer_in;

  /// No description provided for @importTitle.
  ///
  /// In id, this message translates to:
  /// **'Impor & ekspor katalog'**
  String get importTitle;

  /// No description provided for @importHelp.
  ///
  /// In id, this message translates to:
  /// **'Isi template, lalu unggah sebagai CSV atau XLSX. Kolom stock_<KODE> menetapkan stok hasil hitung di toko itu.'**
  String get importHelp;

  /// No description provided for @importDownloadTemplate.
  ///
  /// In id, this message translates to:
  /// **'Unduh template'**
  String get importDownloadTemplate;

  /// No description provided for @importExportCsv.
  ///
  /// In id, this message translates to:
  /// **'Ekspor CSV'**
  String get importExportCsv;

  /// No description provided for @importExportXlsx.
  ///
  /// In id, this message translates to:
  /// **'Ekspor XLSX'**
  String get importExportXlsx;

  /// No description provided for @importPick.
  ///
  /// In id, this message translates to:
  /// **'Pilih file'**
  String get importPick;

  /// No description provided for @importRun.
  ///
  /// In id, this message translates to:
  /// **'Impor {count} baris'**
  String importRun(int count);

  /// No description provided for @importPreview.
  ///
  /// In id, this message translates to:
  /// **'{rows} baris · {products} produk'**
  String importPreview(int rows, int products);

  /// No description provided for @importIssues.
  ///
  /// In id, this message translates to:
  /// **'{count} masalah harus diperbaiki dulu'**
  String importIssues(int count);

  /// No description provided for @importDone.
  ///
  /// In id, this message translates to:
  /// **'Impor selesai: {created} varian baru, {updated} diperbarui, {stock} baris stok.'**
  String importDone(int created, int updated, int stock);

  /// No description provided for @importFileError.
  ///
  /// In id, this message translates to:
  /// **'File tidak bisa dibaca: {message}'**
  String importFileError(String message);

  /// No description provided for @importSaved.
  ///
  /// In id, this message translates to:
  /// **'File disimpan.'**
  String get importSaved;

  /// No description provided for @importRowLabel.
  ///
  /// In id, this message translates to:
  /// **'Baris {row}'**
  String importRowLabel(int row);

  /// No description provided for @importFileLevel.
  ///
  /// In id, this message translates to:
  /// **'File'**
  String get importFileLevel;

  /// No description provided for @issue_emptyFile.
  ///
  /// In id, this message translates to:
  /// **'File kosong.'**
  String get issue_emptyFile;

  /// No description provided for @issue_missingColumn.
  ///
  /// In id, this message translates to:
  /// **'Kolom {column} tidak ada.'**
  String issue_missingColumn(String column);

  /// No description provided for @issue_unknownStore.
  ///
  /// In id, this message translates to:
  /// **'Kolom {column}: kode toko tidak dikenal.'**
  String issue_unknownStore(String column);

  /// No description provided for @issue_tooManyRows.
  ///
  /// In id, this message translates to:
  /// **'Maksimal 5.000 baris per impor.'**
  String get issue_tooManyRows;

  /// No description provided for @issue_requiredValue.
  ///
  /// In id, this message translates to:
  /// **'{column} wajib diisi.'**
  String issue_requiredValue(String column);

  /// No description provided for @issue_skuFormat.
  ///
  /// In id, this message translates to:
  /// **'SKU \"{value}\" hanya boleh huruf, angka, . _ -'**
  String issue_skuFormat(String value);

  /// No description provided for @issue_barcodeFormat.
  ///
  /// In id, this message translates to:
  /// **'Barcode \"{value}\" tidak valid.'**
  String issue_barcodeFormat(String value);

  /// No description provided for @issue_priceFormat.
  ///
  /// In id, this message translates to:
  /// **'{column} \"{value}\": tulis angka saja, mis. 25000 (tanpa Rp atau titik).'**
  String issue_priceFormat(String column, String value);

  /// No description provided for @issue_quantityFormat.
  ///
  /// In id, this message translates to:
  /// **'{column} \"{value}\" bukan jumlah yang valid (maks. 3 desimal, tidak negatif).'**
  String issue_quantityFormat(String column, String value);

  /// No description provided for @issue_booleanFormat.
  ///
  /// In id, this message translates to:
  /// **'{column} \"{value}\": isi yes/no atau ya/tidak.'**
  String issue_booleanFormat(String column, String value);

  /// No description provided for @issue_unknownUnit.
  ///
  /// In id, this message translates to:
  /// **'Satuan \"{value}\" tidak dikenal.'**
  String issue_unknownUnit(String value);

  /// No description provided for @issue_duplicateSku.
  ///
  /// In id, this message translates to:
  /// **'SKU \"{value}\" muncul lebih dari sekali.'**
  String issue_duplicateSku(String value);

  /// No description provided for @issue_duplicateBarcode.
  ///
  /// In id, this message translates to:
  /// **'Barcode \"{value}\" muncul lebih dari sekali.'**
  String issue_duplicateBarcode(String value);

  /// No description provided for @issue_productMismatch.
  ///
  /// In id, this message translates to:
  /// **'\"{value}\": kategori, satuan, PPN atau lacak stok berbeda dari baris sebelumnya.'**
  String issue_productMismatch(String value);

  /// No description provided for @productSaveFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan: {message}'**
  String productSaveFailed(String message);

  /// No description provided for @commonNone.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada'**
  String get commonNone;

  /// No description provided for @posSell.
  ///
  /// In id, this message translates to:
  /// **'Kasir'**
  String get posSell;

  /// No description provided for @posSellHint.
  ///
  /// In id, this message translates to:
  /// **'Scan atau pilih barang, terima pembayaran, cetak struk'**
  String get posSellHint;

  /// No description provided for @sellTitle.
  ///
  /// In id, this message translates to:
  /// **'Kasir'**
  String get sellTitle;

  /// No description provided for @sellFavorites.
  ///
  /// In id, this message translates to:
  /// **'Favorit'**
  String get sellFavorites;

  /// No description provided for @sellNotFound.
  ///
  /// In id, this message translates to:
  /// **'Kode \"{code}\" tidak ditemukan.'**
  String sellNotFound(String code);

  /// No description provided for @sellUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Tidak dijual'**
  String get sellUnavailable;

  /// No description provided for @sellCartSummary.
  ///
  /// In id, this message translates to:
  /// **'{count} item · {total}'**
  String sellCartSummary(int count, String total);

  /// No description provided for @sellPay.
  ///
  /// In id, this message translates to:
  /// **'Bayar'**
  String get sellPay;

  /// No description provided for @sellPayAmount.
  ///
  /// In id, this message translates to:
  /// **'Bayar {amount}'**
  String sellPayAmount(String amount);

  /// No description provided for @sellNewBill.
  ///
  /// In id, this message translates to:
  /// **'Tagihan baru'**
  String get sellNewBill;

  /// No description provided for @sellClear.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan'**
  String get sellClear;

  /// No description provided for @sellClearTitle.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan tagihan?'**
  String get sellClearTitle;

  /// No description provided for @sellClearHint.
  ///
  /// In id, this message translates to:
  /// **'Semua barang di tagihan ini dihapus.'**
  String get sellClearHint;

  /// No description provided for @sellClearHeldHint.
  ///
  /// In id, this message translates to:
  /// **'Perubahan sejak disimpan dibuang. Tagihan tetap tersimpan di daftar Ditahan.'**
  String get sellClearHeldHint;

  /// No description provided for @sellAddCustomer.
  ///
  /// In id, this message translates to:
  /// **'Tambah pelanggan'**
  String get sellAddCustomer;

  /// No description provided for @sellEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada barang. Scan barcode atau ketuk produk.'**
  String get sellEmpty;

  /// No description provided for @sellChangeQuantity.
  ///
  /// In id, this message translates to:
  /// **'Ubah jumlah'**
  String get sellChangeQuantity;

  /// No description provided for @sellLineDiscount.
  ///
  /// In id, this message translates to:
  /// **'Diskon barang'**
  String get sellLineDiscount;

  /// No description provided for @sellBillDiscount.
  ///
  /// In id, this message translates to:
  /// **'Diskon tagihan'**
  String get sellBillDiscount;

  /// No description provided for @sellNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get sellNote;

  /// No description provided for @sellRemove.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get sellRemove;

  /// No description provided for @sellItemDiscounts.
  ///
  /// In id, this message translates to:
  /// **'Diskon barang'**
  String get sellItemDiscounts;

  /// No description provided for @sellTaxIncluded.
  ///
  /// In id, this message translates to:
  /// **'Termasuk {tax}'**
  String sellTaxIncluded(String tax);

  /// No description provided for @sellNeedsApproval.
  ///
  /// In id, this message translates to:
  /// **'Diskon melebihi batas: perlu persetujuan'**
  String get sellNeedsApproval;

  /// No description provided for @sellDiscount.
  ///
  /// In id, this message translates to:
  /// **'Diskon'**
  String get sellDiscount;

  /// No description provided for @sellHold.
  ///
  /// In id, this message translates to:
  /// **'Tahan'**
  String get sellHold;

  /// No description provided for @sellHeld.
  ///
  /// In id, this message translates to:
  /// **'Tagihan {number} ditahan.'**
  String sellHeld(String number);

  /// No description provided for @discountManualLine.
  ///
  /// In id, this message translates to:
  /// **'Diskon'**
  String get discountManualLine;

  /// No description provided for @discountManualBill.
  ///
  /// In id, this message translates to:
  /// **'Diskon tagihan'**
  String get discountManualBill;

  /// No description provided for @discountVoucher.
  ///
  /// In id, this message translates to:
  /// **'Voucher'**
  String get discountVoucher;

  /// No description provided for @discountPoints.
  ///
  /// In id, this message translates to:
  /// **'Tukar poin'**
  String get discountPoints;

  /// No description provided for @discountPercent.
  ///
  /// In id, this message translates to:
  /// **'Persen'**
  String get discountPercent;

  /// No description provided for @discountAmount.
  ///
  /// In id, this message translates to:
  /// **'Rupiah'**
  String get discountAmount;

  /// No description provided for @discountValue.
  ///
  /// In id, this message translates to:
  /// **'Besar diskon'**
  String get discountValue;

  /// No description provided for @discountInvalid.
  ///
  /// In id, this message translates to:
  /// **'Isi persen 0,01–100 atau rupiah di atas 0.'**
  String get discountInvalid;

  /// No description provided for @discountRemove.
  ///
  /// In id, this message translates to:
  /// **'Hapus diskon'**
  String get discountRemove;

  /// No description provided for @voucherTitle.
  ///
  /// In id, this message translates to:
  /// **'Voucher'**
  String get voucherTitle;

  /// No description provided for @voucherCode.
  ///
  /// In id, this message translates to:
  /// **'Kode voucher'**
  String get voucherCode;

  /// No description provided for @voucherCodeShort.
  ///
  /// In id, this message translates to:
  /// **'Kode minimal 3 karakter.'**
  String get voucherCodeShort;

  /// No description provided for @voucherUnknown.
  ///
  /// In id, this message translates to:
  /// **'Voucher {code} tidak dikenal.'**
  String voucherUnknown(String code);

  /// No description provided for @voucherInactive.
  ///
  /// In id, this message translates to:
  /// **'Voucher ini sudah tidak aktif.'**
  String get voucherInactive;

  /// No description provided for @voucherNotStarted.
  ///
  /// In id, this message translates to:
  /// **'Voucher ini belum berlaku.'**
  String get voucherNotStarted;

  /// No description provided for @voucherExpired.
  ///
  /// In id, this message translates to:
  /// **'Voucher ini sudah kedaluwarsa.'**
  String get voucherExpired;

  /// No description provided for @voucherUsedUp.
  ///
  /// In id, this message translates to:
  /// **'Kuota voucher ini sudah habis.'**
  String get voucherUsedUp;

  /// No description provided for @voucherBelowMinimum.
  ///
  /// In id, this message translates to:
  /// **'Belanja belum mencapai minimum voucher.'**
  String get voucherBelowMinimum;

  /// No description provided for @modifierRequired.
  ///
  /// In id, this message translates to:
  /// **'pilih {count}'**
  String modifierRequired(int count);

  /// No description provided for @modifierOptional.
  ///
  /// In id, this message translates to:
  /// **'opsional, maks. {count}'**
  String modifierOptional(int count);

  /// No description provided for @modifierAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan · {price}'**
  String modifierAdd(String price);

  /// No description provided for @approvalTitle.
  ///
  /// In id, this message translates to:
  /// **'Persetujuan'**
  String get approvalTitle;

  /// No description provided for @approvalDiscountReason.
  ///
  /// In id, this message translates to:
  /// **'Diskon {percent}% melebihi batas {limit}%.'**
  String approvalDiscountReason(String percent, String limit);

  /// No description provided for @approvalCancelReason.
  ///
  /// In id, this message translates to:
  /// **'Membatalkan tagihan {number}.'**
  String approvalCancelReason(String number);

  /// No description provided for @approvalNobody.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada staf di toko ini yang boleh menyetujui.'**
  String get approvalNobody;

  /// No description provided for @approvalEnterPin.
  ///
  /// In id, this message translates to:
  /// **'{name}, masukkan PIN Anda.'**
  String approvalEnterPin(String name);

  /// No description provided for @approvalLocked.
  ///
  /// In id, this message translates to:
  /// **'PIN terkunci 5 menit karena terlalu banyak percobaan.'**
  String get approvalLocked;

  /// No description provided for @approvalNoPin.
  ///
  /// In id, this message translates to:
  /// **'Staf ini belum punya PIN.'**
  String get approvalNoPin;

  /// No description provided for @approvalOther.
  ///
  /// In id, this message translates to:
  /// **'Staf lain'**
  String get approvalOther;

  /// No description provided for @customerAdd.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan baru'**
  String get customerAdd;

  /// No description provided for @customerName.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get customerName;

  /// No description provided for @customerPhone.
  ///
  /// In id, this message translates to:
  /// **'No. HP (opsional)'**
  String get customerPhone;

  /// No description provided for @customerPhoneInvalid.
  ///
  /// In id, this message translates to:
  /// **'Nomor HP 8–15 angka.'**
  String get customerPhoneInvalid;

  /// No description provided for @customerSearchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari nama atau nomor HP'**
  String get customerSearchHint;

  /// No description provided for @customerNoPermission.
  ///
  /// In id, this message translates to:
  /// **'Anda tidak boleh menambah pelanggan.'**
  String get customerNoPermission;

  /// No description provided for @shiftOpenTitle.
  ///
  /// In id, this message translates to:
  /// **'Buka shift'**
  String get shiftOpenTitle;

  /// No description provided for @shiftOpenHint.
  ///
  /// In id, this message translates to:
  /// **'Hitung uang di laci, lalu isi kas awal.'**
  String get shiftOpenHint;

  /// No description provided for @shiftOpeningCash.
  ///
  /// In id, this message translates to:
  /// **'Kas awal'**
  String get shiftOpeningCash;

  /// No description provided for @shiftOpen.
  ///
  /// In id, this message translates to:
  /// **'Buka shift'**
  String get shiftOpen;

  /// No description provided for @shiftNoPermission.
  ///
  /// In id, this message translates to:
  /// **'Minta manajer atau kasir yang berwenang membuka shift.'**
  String get shiftNoPermission;

  /// No description provided for @payTitle.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran {number}'**
  String payTitle(String number);

  /// No description provided for @payDue.
  ///
  /// In id, this message translates to:
  /// **'Total tagihan'**
  String get payDue;

  /// No description provided for @payCustomer.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan: {name}'**
  String payCustomer(String name);

  /// No description provided for @payRemaining.
  ///
  /// In id, this message translates to:
  /// **'Sisa {amount}'**
  String payRemaining(String amount);

  /// No description provided for @payChange.
  ///
  /// In id, this message translates to:
  /// **'Kembalian {amount}'**
  String payChange(String amount);

  /// No description provided for @payKasbonNote.
  ///
  /// In id, this message translates to:
  /// **'Kasbon {amount}, jatuh tempo {days} hari.'**
  String payKasbonNote(String amount, int days);

  /// No description provided for @payFinish.
  ///
  /// In id, this message translates to:
  /// **'Selesaikan transaksi'**
  String get payFinish;

  /// No description provided for @payMethod.
  ///
  /// In id, this message translates to:
  /// **'Metode pembayaran'**
  String get payMethod;

  /// No description provided for @payQuickCash.
  ///
  /// In id, this message translates to:
  /// **'Uang diterima'**
  String get payQuickCash;

  /// No description provided for @payExact.
  ///
  /// In id, this message translates to:
  /// **'Uang pas'**
  String get payExact;

  /// No description provided for @payTendered.
  ///
  /// In id, this message translates to:
  /// **'Uang diterima'**
  String get payTendered;

  /// No description provided for @payAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get payAmount;

  /// No description provided for @payReference.
  ///
  /// In id, this message translates to:
  /// **'No. referensi / approval'**
  String get payReference;

  /// No description provided for @payReferenceOptional.
  ///
  /// In id, this message translates to:
  /// **'No. referensi (opsional)'**
  String get payReferenceOptional;

  /// No description provided for @payReferenceRequired.
  ///
  /// In id, this message translates to:
  /// **'{method} butuh nomor referensi.'**
  String payReferenceRequired(String method);

  /// No description provided for @payAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah {method}'**
  String payAdd(String method);

  /// No description provided for @payInvalidAmount.
  ///
  /// In id, this message translates to:
  /// **'Isi jumlah di atas 0.'**
  String get payInvalidAmount;

  /// No description provided for @payNonCashTooMuch.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran non-tunai melebihi tagihan. Kembalian hanya dari tunai.'**
  String get payNonCashTooMuch;

  /// No description provided for @payOneKasbon.
  ///
  /// In id, this message translates to:
  /// **'Kasbon hanya boleh satu kali per tagihan.'**
  String get payOneKasbon;

  /// No description provided for @payUnneeded.
  ///
  /// In id, this message translates to:
  /// **'Tunai ini tidak diperlukan, tagihan sudah lunas.'**
  String get payUnneeded;

  /// No description provided for @payShiftRequired.
  ///
  /// In id, this message translates to:
  /// **'Buka shift dulu sebelum menyelesaikan transaksi.'**
  String get payShiftRequired;

  /// No description provided for @payNotPaid.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran belum sama dengan tagihan.'**
  String get payNotPaid;

  /// No description provided for @payKasbonCustomer.
  ///
  /// In id, this message translates to:
  /// **'Kasbon butuh pelanggan.'**
  String get payKasbonCustomer;

  /// No description provided for @receiptTitle.
  ///
  /// In id, this message translates to:
  /// **'Struk'**
  String get receiptTitle;

  /// No description provided for @receiptCashier.
  ///
  /// In id, this message translates to:
  /// **'Kasir'**
  String get receiptCashier;

  /// No description provided for @receiptCustomer.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get receiptCustomer;

  /// No description provided for @receiptSubtotal.
  ///
  /// In id, this message translates to:
  /// **'Subtotal'**
  String get receiptSubtotal;

  /// No description provided for @receiptService.
  ///
  /// In id, this message translates to:
  /// **'Biaya layanan'**
  String get receiptService;

  /// No description provided for @receiptTaxIncluded.
  ///
  /// In id, this message translates to:
  /// **'Termasuk {tax} {rate}'**
  String receiptTaxIncluded(String tax, String rate);

  /// No description provided for @receiptTaxAdded.
  ///
  /// In id, this message translates to:
  /// **'{tax} {rate}'**
  String receiptTaxAdded(String tax, String rate);

  /// No description provided for @receiptTaxBase.
  ///
  /// In id, this message translates to:
  /// **'DPP'**
  String get receiptTaxBase;

  /// No description provided for @receiptRounding.
  ///
  /// In id, this message translates to:
  /// **'Pembulatan'**
  String get receiptRounding;

  /// No description provided for @receiptTotal.
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get receiptTotal;

  /// No description provided for @receiptChange.
  ///
  /// In id, this message translates to:
  /// **'Kembali'**
  String get receiptChange;

  /// No description provided for @receiptTendered.
  ///
  /// In id, this message translates to:
  /// **'Diterima'**
  String get receiptTendered;

  /// No description provided for @receiptKasbonDue.
  ///
  /// In id, this message translates to:
  /// **'Kasbon jatuh tempo {date}'**
  String receiptKasbonDue(String date);

  /// No description provided for @receiptCancelled.
  ///
  /// In id, this message translates to:
  /// **'DIBATALKAN'**
  String get receiptCancelled;

  /// No description provided for @receiptHeld.
  ///
  /// In id, this message translates to:
  /// **'BELUM DIBAYAR'**
  String get receiptHeld;

  /// No description provided for @receiptItems.
  ///
  /// In id, this message translates to:
  /// **'{count} item'**
  String receiptItems(int count);

  /// No description provided for @receiptShare.
  ///
  /// In id, this message translates to:
  /// **'Bagikan PDF'**
  String get receiptShare;

  /// No description provided for @receiptPrint.
  ///
  /// In id, this message translates to:
  /// **'Cetak'**
  String get receiptPrint;

  /// No description provided for @receiptReprint.
  ///
  /// In id, this message translates to:
  /// **'Cetak ulang'**
  String get receiptReprint;

  /// No description provided for @receiptNewSale.
  ///
  /// In id, this message translates to:
  /// **'Transaksi baru'**
  String get receiptNewSale;

  /// No description provided for @receiptMissing.
  ///
  /// In id, this message translates to:
  /// **'Struk tidak ditemukan di terminal ini.'**
  String get receiptMissing;

  /// No description provided for @ordersTitle.
  ///
  /// In id, this message translates to:
  /// **'Transaksi'**
  String get ordersTitle;

  /// No description provided for @ordersToday.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get ordersToday;

  /// No description provided for @ordersHeld.
  ///
  /// In id, this message translates to:
  /// **'Ditahan ({count})'**
  String ordersHeld(int count);

  /// No description provided for @ordersTodayTotal.
  ///
  /// In id, this message translates to:
  /// **'Penjualan hari ini'**
  String get ordersTodayTotal;

  /// No description provided for @ordersTodayCount.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi lunas di terminal ini'**
  String ordersTodayCount(int count);

  /// No description provided for @ordersNone.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi hari ini.'**
  String get ordersNone;

  /// No description provided for @ordersNoHeld.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada tagihan yang ditahan.'**
  String get ordersNoHeld;

  /// No description provided for @ordersStatusHeld.
  ///
  /// In id, this message translates to:
  /// **'Ditahan'**
  String get ordersStatusHeld;

  /// No description provided for @ordersStatusCancelled.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get ordersStatusCancelled;

  /// No description provided for @ordersStatusPaid.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get ordersStatusPaid;

  /// No description provided for @ordersResumeTitle.
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan tagihan?'**
  String get ordersResumeTitle;

  /// No description provided for @ordersResumeReplace.
  ///
  /// In id, this message translates to:
  /// **'Tagihan yang sedang dibuka akan dikosongkan. Tahan dulu jika masih dipakai.'**
  String get ordersResumeReplace;

  /// No description provided for @ordersCancel.
  ///
  /// In id, this message translates to:
  /// **'Batalkan'**
  String get ordersCancel;

  /// No description provided for @ordersCancelTitle.
  ///
  /// In id, this message translates to:
  /// **'Batalkan {number}?'**
  String ordersCancelTitle(String number);

  /// No description provided for @ordersCancelReason.
  ///
  /// In id, this message translates to:
  /// **'Alasan'**
  String get ordersCancelReason;

  /// No description provided for @ordersCancelReasonShort.
  ///
  /// In id, this message translates to:
  /// **'Tulis alasan minimal 3 huruf.'**
  String get ordersCancelReasonShort;

  /// No description provided for @ordersCancelled.
  ///
  /// In id, this message translates to:
  /// **'Tagihan {number} dibatalkan.'**
  String ordersCancelled(String number);

  /// No description provided for @commonDone.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get commonDone;

  /// No description provided for @commonSearch.
  ///
  /// In id, this message translates to:
  /// **'Cari'**
  String get commonSearch;

  /// No description provided for @navPromotions.
  ///
  /// In id, this message translates to:
  /// **'Promo'**
  String get navPromotions;

  /// No description provided for @navVouchers.
  ///
  /// In id, this message translates to:
  /// **'Voucher'**
  String get navVouchers;

  /// No description provided for @navSettings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan toko'**
  String get navSettings;

  /// No description provided for @promosEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada promo.'**
  String get promosEmpty;

  /// No description provided for @promoMissing.
  ///
  /// In id, this message translates to:
  /// **'Promo ini tidak ditemukan.'**
  String get promoMissing;

  /// No description provided for @promoNew.
  ///
  /// In id, this message translates to:
  /// **'Promo baru'**
  String get promoNew;

  /// No description provided for @promoGeneral.
  ///
  /// In id, this message translates to:
  /// **'Umum'**
  String get promoGeneral;

  /// No description provided for @promoName.
  ///
  /// In id, this message translates to:
  /// **'Nama promo'**
  String get promoName;

  /// No description provided for @promoDescription.
  ///
  /// In id, this message translates to:
  /// **'Keterangan'**
  String get promoDescription;

  /// No description provided for @promoType.
  ///
  /// In id, this message translates to:
  /// **'Jenis promo'**
  String get promoType;

  /// No description provided for @promoTypeHappyHour.
  ///
  /// In id, this message translates to:
  /// **'Diskon jam tertentu'**
  String get promoTypeHappyHour;

  /// No description provided for @promoTypeBuyXGetY.
  ///
  /// In id, this message translates to:
  /// **'Beli X gratis/diskon Y'**
  String get promoTypeBuyXGetY;

  /// No description provided for @promoTypeBundle.
  ///
  /// In id, this message translates to:
  /// **'Paket harga'**
  String get promoTypeBundle;

  /// No description provided for @promoTypeTiered.
  ///
  /// In id, this message translates to:
  /// **'Diskon grosir (jumlah)'**
  String get promoTypeTiered;

  /// No description provided for @promoTypeMinPurchase.
  ///
  /// In id, this message translates to:
  /// **'Minimal belanja'**
  String get promoTypeMinPurchase;

  /// No description provided for @promoPriority.
  ///
  /// In id, this message translates to:
  /// **'Prioritas'**
  String get promoPriority;

  /// No description provided for @promoPriorityHint.
  ///
  /// In id, this message translates to:
  /// **'Angka kecil dijalankan lebih dulu.'**
  String get promoPriorityHint;

  /// No description provided for @promoStackable.
  ///
  /// In id, this message translates to:
  /// **'Bisa digabung'**
  String get promoStackable;

  /// No description provided for @promoStackableHint.
  ///
  /// In id, this message translates to:
  /// **'Jika mati, barang yang sudah kena promo lain tidak ikut, dan promo sesudahnya tidak berlaku untuk barang ini.'**
  String get promoStackableHint;

  /// No description provided for @promoRules.
  ///
  /// In id, this message translates to:
  /// **'Aturan'**
  String get promoRules;

  /// No description provided for @promoScope.
  ///
  /// In id, this message translates to:
  /// **'Berlaku untuk'**
  String get promoScope;

  /// No description provided for @promoScopeAll.
  ///
  /// In id, this message translates to:
  /// **'Semua produk'**
  String get promoScopeAll;

  /// No description provided for @promoScopeCategories.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get promoScopeCategories;

  /// No description provided for @promoScopeProducts.
  ///
  /// In id, this message translates to:
  /// **'Produk'**
  String get promoScopeProducts;

  /// No description provided for @promoScopeVariants.
  ///
  /// In id, this message translates to:
  /// **'Varian (SKU)'**
  String get promoScopeVariants;

  /// No description provided for @promoDiscountPerUnit.
  ///
  /// In id, this message translates to:
  /// **'Diskon (Rp per unit)'**
  String get promoDiscountPerUnit;

  /// No description provided for @promoBuyScope.
  ///
  /// In id, this message translates to:
  /// **'Beli barang'**
  String get promoBuyScope;

  /// No description provided for @promoBuyQuantity.
  ///
  /// In id, this message translates to:
  /// **'Jumlah beli'**
  String get promoBuyQuantity;

  /// No description provided for @promoGetScope.
  ///
  /// In id, this message translates to:
  /// **'Dapat barang'**
  String get promoGetScope;

  /// No description provided for @promoGetQuantity.
  ///
  /// In id, this message translates to:
  /// **'Jumlah dapat'**
  String get promoGetQuantity;

  /// No description provided for @promoGetDiscount.
  ///
  /// In id, this message translates to:
  /// **'Diskon barang yang didapat (100% = gratis)'**
  String get promoGetDiscount;

  /// No description provided for @promoMaxApplications.
  ///
  /// In id, this message translates to:
  /// **'Maks. berlaku per transaksi'**
  String get promoMaxApplications;

  /// No description provided for @promoUnlimitedHint.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan untuk tanpa batas'**
  String get promoUnlimitedHint;

  /// No description provided for @promoComponent.
  ///
  /// In id, this message translates to:
  /// **'Isi paket {index}'**
  String promoComponent(int index);

  /// No description provided for @promoQty.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get promoQty;

  /// No description provided for @promoAddComponent.
  ///
  /// In id, this message translates to:
  /// **'Tambah isi paket'**
  String get promoAddComponent;

  /// No description provided for @promoBundlePrice.
  ///
  /// In id, this message translates to:
  /// **'Harga paket'**
  String get promoBundlePrice;

  /// No description provided for @promoMinQuantity.
  ///
  /// In id, this message translates to:
  /// **'Mulai jumlah'**
  String get promoMinQuantity;

  /// No description provided for @promoAddTier.
  ///
  /// In id, this message translates to:
  /// **'Tambah tingkat'**
  String get promoAddTier;

  /// No description provided for @promoMinSubtotal.
  ///
  /// In id, this message translates to:
  /// **'Minimal belanja'**
  String get promoMinSubtotal;

  /// No description provided for @promoBillDiscount.
  ///
  /// In id, this message translates to:
  /// **'Potongan tagihan'**
  String get promoBillDiscount;

  /// No description provided for @promoWhen.
  ///
  /// In id, this message translates to:
  /// **'Waktu berlaku'**
  String get promoWhen;

  /// No description provided for @promoStartsAnytime.
  ///
  /// In id, this message translates to:
  /// **'Mulai: kapan saja'**
  String get promoStartsAnytime;

  /// No description provided for @promoStarts.
  ///
  /// In id, this message translates to:
  /// **'Mulai {date}'**
  String promoStarts(String date);

  /// No description provided for @promoEndsNever.
  ///
  /// In id, this message translates to:
  /// **'Selesai: tidak ada'**
  String get promoEndsNever;

  /// No description provided for @promoEnds.
  ///
  /// In id, this message translates to:
  /// **'Sampai {date}'**
  String promoEnds(String date);

  /// No description provided for @promoClearPeriod.
  ///
  /// In id, this message translates to:
  /// **'Hapus tanggal'**
  String get promoClearPeriod;

  /// No description provided for @promoDays.
  ///
  /// In id, this message translates to:
  /// **'Hari (kosong = setiap hari)'**
  String get promoDays;

  /// No description provided for @promoEveryDay.
  ///
  /// In id, this message translates to:
  /// **'Berlaku setiap hari.'**
  String get promoEveryDay;

  /// No description provided for @promoHours.
  ///
  /// In id, this message translates to:
  /// **'Jam'**
  String get promoHours;

  /// No description provided for @promoAllDay.
  ///
  /// In id, this message translates to:
  /// **'Sepanjang hari'**
  String get promoAllDay;

  /// No description provided for @promoStores.
  ///
  /// In id, this message translates to:
  /// **'Toko'**
  String get promoStores;

  /// No description provided for @promoAllStores.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada yang dipilih: berlaku di semua toko.'**
  String get promoAllStores;

  /// No description provided for @promoStoreCount.
  ///
  /// In id, this message translates to:
  /// **'{count} toko'**
  String promoStoreCount(int count);

  /// No description provided for @promoPeriodInvalid.
  ///
  /// In id, this message translates to:
  /// **'Tanggal selesai harus setelah tanggal mulai.'**
  String get promoPeriodInvalid;

  /// No description provided for @promoProblemName.
  ///
  /// In id, this message translates to:
  /// **'Isi nama promo.'**
  String get promoProblemName;

  /// No description provided for @promoProblemWindow.
  ///
  /// In id, this message translates to:
  /// **'Isi jam mulai dan jam selesai, atau kosongkan keduanya.'**
  String get promoProblemWindow;

  /// No description provided for @promoProblemHappyHour.
  ///
  /// In id, this message translates to:
  /// **'Diskon jam tertentu butuh jam mulai dan selesai.'**
  String get promoProblemHappyHour;

  /// No description provided for @promoProblemScope.
  ///
  /// In id, this message translates to:
  /// **'Pilih barang yang berlaku.'**
  String get promoProblemScope;

  /// No description provided for @promoProblemQuantity.
  ///
  /// In id, this message translates to:
  /// **'Jumlah harus angka bulat di atas 0.'**
  String get promoProblemQuantity;

  /// No description provided for @promoProblemComponents.
  ///
  /// In id, this message translates to:
  /// **'Paket butuh minimal 2 isi.'**
  String get promoProblemComponents;

  /// No description provided for @promoProblemTiers.
  ///
  /// In id, this message translates to:
  /// **'Tingkat jumlah harus naik, mulai dari 1.'**
  String get promoProblemTiers;

  /// No description provided for @promoSummaryDiscount.
  ///
  /// In id, this message translates to:
  /// **'diskon {discount}'**
  String promoSummaryDiscount(String discount);

  /// No description provided for @promoSummaryBuyGet.
  ///
  /// In id, this message translates to:
  /// **'beli {buy} dapat {get} diskon {discount}'**
  String promoSummaryBuyGet(int buy, int get, String discount);

  /// No description provided for @promoSummaryBundle.
  ///
  /// In id, this message translates to:
  /// **'{count} barang jadi {price}'**
  String promoSummaryBundle(int count, String price);

  /// No description provided for @promoSummaryMinPurchase.
  ///
  /// In id, this message translates to:
  /// **'belanja {min} hemat {discount}'**
  String promoSummaryMinPurchase(String min, String discount);

  /// No description provided for @vouchersEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada voucher.'**
  String get vouchersEmpty;

  /// No description provided for @voucherNew.
  ///
  /// In id, this message translates to:
  /// **'Voucher baru'**
  String get voucherNew;

  /// No description provided for @voucherCodeHint.
  ///
  /// In id, this message translates to:
  /// **'3–32 huruf besar, angka, - atau _'**
  String get voucherCodeHint;

  /// No description provided for @voucherMinSubtotal.
  ///
  /// In id, this message translates to:
  /// **'min. {amount}'**
  String voucherMinSubtotal(String amount);

  /// No description provided for @voucherMaxDiscount.
  ///
  /// In id, this message translates to:
  /// **'maks. {amount}'**
  String voucherMaxDiscount(String amount);

  /// No description provided for @voucherUsed.
  ///
  /// In id, this message translates to:
  /// **'dipakai {used}/{max}'**
  String voucherUsed(int used, String max);

  /// No description provided for @voucherUntil.
  ///
  /// In id, this message translates to:
  /// **'s.d. {date}'**
  String voucherUntil(String date);

  /// No description provided for @voucherMaxDiscountLabel.
  ///
  /// In id, this message translates to:
  /// **'Diskon maksimal (opsional)'**
  String get voucherMaxDiscountLabel;

  /// No description provided for @voucherMinSubtotalLabel.
  ///
  /// In id, this message translates to:
  /// **'Minimal belanja (opsional)'**
  String get voucherMinSubtotalLabel;

  /// No description provided for @voucherMaxUses.
  ///
  /// In id, this message translates to:
  /// **'Kuota total (opsional)'**
  String get voucherMaxUses;

  /// No description provided for @voucherPerCustomer.
  ///
  /// In id, this message translates to:
  /// **'Maks. per pelanggan (opsional)'**
  String get voucherPerCustomer;

  /// No description provided for @voucherCountInvalid.
  ///
  /// In id, this message translates to:
  /// **'Angka bulat di atas 0.'**
  String get voucherCountInvalid;

  /// No description provided for @settingsTax.
  ///
  /// In id, this message translates to:
  /// **'Pajak'**
  String get settingsTax;

  /// No description provided for @settingsTaxEnabled.
  ///
  /// In id, this message translates to:
  /// **'Kenakan pajak'**
  String get settingsTaxEnabled;

  /// No description provided for @settingsTaxName.
  ///
  /// In id, this message translates to:
  /// **'Nama pajak'**
  String get settingsTaxName;

  /// No description provided for @settingsRate.
  ///
  /// In id, this message translates to:
  /// **'Tarif'**
  String get settingsRate;

  /// No description provided for @settingsTaxInclusive.
  ///
  /// In id, this message translates to:
  /// **'Harga sudah termasuk pajak'**
  String get settingsTaxInclusive;

  /// No description provided for @settingsTaxInclusiveHint.
  ///
  /// In id, this message translates to:
  /// **'Rp 25.000 dengan PPN 11% berisi PPN Rp 2.477.'**
  String get settingsTaxInclusiveHint;

  /// No description provided for @settingsTaxExclusiveHint.
  ///
  /// In id, this message translates to:
  /// **'Pajak ditambahkan di atas harga.'**
  String get settingsTaxExclusiveHint;

  /// No description provided for @settingsServiceCharge.
  ///
  /// In id, this message translates to:
  /// **'Biaya layanan'**
  String get settingsServiceCharge;

  /// No description provided for @settingsServiceChargeEnabled.
  ///
  /// In id, this message translates to:
  /// **'Kenakan biaya layanan'**
  String get settingsServiceChargeEnabled;

  /// No description provided for @settingsServiceChargeTaxable.
  ///
  /// In id, this message translates to:
  /// **'Biaya layanan kena pajak'**
  String get settingsServiceChargeTaxable;

  /// No description provided for @settingsCashier.
  ///
  /// In id, this message translates to:
  /// **'Kasir'**
  String get settingsCashier;

  /// No description provided for @settingsRounding.
  ///
  /// In id, this message translates to:
  /// **'Pembulatan total'**
  String get settingsRounding;

  /// No description provided for @settingsRoundingNone.
  ///
  /// In id, this message translates to:
  /// **'Tidak dibulatkan'**
  String get settingsRoundingNone;

  /// No description provided for @settingsRoundingNearest.
  ///
  /// In id, this message translates to:
  /// **'Terdekat'**
  String get settingsRoundingNearest;

  /// No description provided for @settingsRoundingUp.
  ///
  /// In id, this message translates to:
  /// **'Ke atas'**
  String get settingsRoundingUp;

  /// No description provided for @settingsRoundingDown.
  ///
  /// In id, this message translates to:
  /// **'Ke bawah'**
  String get settingsRoundingDown;

  /// No description provided for @settingsRoundingUnit.
  ///
  /// In id, this message translates to:
  /// **'Kelipatan'**
  String get settingsRoundingUnit;

  /// No description provided for @settingsDiscountLimit.
  ///
  /// In id, this message translates to:
  /// **'Batas diskon tanpa persetujuan'**
  String get settingsDiscountLimit;

  /// No description provided for @settingsDiscountLimitHint.
  ///
  /// In id, this message translates to:
  /// **'Diskon manual di atas batas ini perlu PIN manajer.'**
  String get settingsDiscountLimitHint;

  /// No description provided for @settingsKasbon.
  ///
  /// In id, this message translates to:
  /// **'Izinkan kasbon'**
  String get settingsKasbon;

  /// No description provided for @settingsReceipt.
  ///
  /// In id, this message translates to:
  /// **'Struk'**
  String get settingsReceipt;

  /// No description provided for @settingsReceiptHeader.
  ///
  /// In id, this message translates to:
  /// **'Judul struk'**
  String get settingsReceiptHeader;

  /// No description provided for @settingsReceiptFooter.
  ///
  /// In id, this message translates to:
  /// **'Catatan kaki struk'**
  String get settingsReceiptFooter;

  /// No description provided for @settingsPaymentMethods.
  ///
  /// In id, this message translates to:
  /// **'Metode pembayaran'**
  String get settingsPaymentMethods;

  /// No description provided for @settingsPaymentMethodsHint.
  ///
  /// In id, this message translates to:
  /// **'Yang aktif muncul di layar pembayaran toko ini.'**
  String get settingsPaymentMethodsHint;

  /// No description provided for @settingsNeedsReference.
  ///
  /// In id, this message translates to:
  /// **'perlu no. referensi'**
  String get settingsNeedsReference;

  /// No description provided for @settingsPercentInvalid.
  ///
  /// In id, this message translates to:
  /// **'Isi persen 0–100.'**
  String get settingsPercentInvalid;

  /// No description provided for @posShift.
  ///
  /// In id, this message translates to:
  /// **'Shift'**
  String get posShift;

  /// No description provided for @posShiftOpenSince.
  ///
  /// In id, this message translates to:
  /// **'Buka sejak {time} · {name}'**
  String posShiftOpenSince(String time, String name);

  /// No description provided for @posShiftNone.
  ///
  /// In id, this message translates to:
  /// **'Belum ada shift terbuka'**
  String get posShiftNone;

  /// No description provided for @posPrinter.
  ///
  /// In id, this message translates to:
  /// **'Printer'**
  String get posPrinter;

  /// No description provided for @posPrinterNone.
  ///
  /// In id, this message translates to:
  /// **'Belum diatur'**
  String get posPrinterNone;

  /// No description provided for @shiftTitle.
  ///
  /// In id, this message translates to:
  /// **'Shift'**
  String get shiftTitle;

  /// No description provided for @shiftNoneOpen.
  ///
  /// In id, this message translates to:
  /// **'Belum ada shift terbuka. Buka shift di layar Kasir.'**
  String get shiftNoneOpen;

  /// No description provided for @shiftGoSell.
  ///
  /// In id, this message translates to:
  /// **'Ke Kasir'**
  String get shiftGoSell;

  /// No description provided for @shiftDrawerExpected.
  ///
  /// In id, this message translates to:
  /// **'Uang di laci seharusnya'**
  String get shiftDrawerExpected;

  /// No description provided for @shiftOpenedBy.
  ///
  /// In id, this message translates to:
  /// **'Dibuka {time} oleh {name}'**
  String shiftOpenedBy(String time, String name);

  /// No description provided for @shiftCashIn.
  ///
  /// In id, this message translates to:
  /// **'Kas masuk'**
  String get shiftCashIn;

  /// No description provided for @shiftCashOut.
  ///
  /// In id, this message translates to:
  /// **'Kas keluar'**
  String get shiftCashOut;

  /// No description provided for @shiftOpenDrawer.
  ///
  /// In id, this message translates to:
  /// **'Buka laci'**
  String get shiftOpenDrawer;

  /// No description provided for @shiftPrintX.
  ///
  /// In id, this message translates to:
  /// **'Cetak X'**
  String get shiftPrintX;

  /// No description provided for @shiftClose.
  ///
  /// In id, this message translates to:
  /// **'Tutup shift'**
  String get shiftClose;

  /// No description provided for @shiftMovements.
  ///
  /// In id, this message translates to:
  /// **'Kas masuk & keluar'**
  String get shiftMovements;

  /// No description provided for @shiftNoMovements.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kas masuk atau keluar.'**
  String get shiftNoMovements;

  /// No description provided for @shiftHistory.
  ///
  /// In id, this message translates to:
  /// **'Shift sebelumnya'**
  String get shiftHistory;

  /// No description provided for @shiftHistoryLine.
  ///
  /// In id, this message translates to:
  /// **'{date} · {name}'**
  String shiftHistoryLine(String date, String name);

  /// No description provided for @shiftMovementAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get shiftMovementAmount;

  /// No description provided for @shiftMovementReason.
  ///
  /// In id, this message translates to:
  /// **'Keterangan'**
  String get shiftMovementReason;

  /// No description provided for @shiftMovementSaved.
  ///
  /// In id, this message translates to:
  /// **'{kind} {amount} dicatat.'**
  String shiftMovementSaved(String kind, String amount);

  /// No description provided for @shiftDrawerShort.
  ///
  /// In id, this message translates to:
  /// **'Uang di laci hanya {amount}.'**
  String shiftDrawerShort(String amount);

  /// No description provided for @shiftReport.
  ///
  /// In id, this message translates to:
  /// **'Laporan shift'**
  String get shiftReport;

  /// No description provided for @drawerReasonTitle.
  ///
  /// In id, this message translates to:
  /// **'Buka laci tanpa transaksi'**
  String get drawerReasonTitle;

  /// No description provided for @drawerApprovalReason.
  ///
  /// In id, this message translates to:
  /// **'Membuka laci tanpa transaksi: {reason}'**
  String drawerApprovalReason(String reason);

  /// No description provided for @drawerOpened.
  ///
  /// In id, this message translates to:
  /// **'Laci dibuka.'**
  String get drawerOpened;

  /// No description provided for @drawerNotSet.
  ///
  /// In id, this message translates to:
  /// **'Printer ini tidak diatur untuk membuka laci. Ubah di Pengaturan printer.'**
  String get drawerNotSet;

  /// No description provided for @closeTitle.
  ///
  /// In id, this message translates to:
  /// **'Tutup shift'**
  String get closeTitle;

  /// No description provided for @closeCountByNotes.
  ///
  /// In id, this message translates to:
  /// **'Hitung per pecahan'**
  String get closeCountByNotes;

  /// No description provided for @closeEnterTotal.
  ///
  /// In id, this message translates to:
  /// **'Masukkan total'**
  String get closeEnterTotal;

  /// No description provided for @closeCounted.
  ///
  /// In id, this message translates to:
  /// **'Uang dihitung'**
  String get closeCounted;

  /// No description provided for @closeExpected.
  ///
  /// In id, this message translates to:
  /// **'Seharusnya'**
  String get closeExpected;

  /// No description provided for @closeDifference.
  ///
  /// In id, this message translates to:
  /// **'Selisih'**
  String get closeDifference;

  /// No description provided for @closeEven.
  ///
  /// In id, this message translates to:
  /// **'Pas'**
  String get closeEven;

  /// No description provided for @closeOver.
  ///
  /// In id, this message translates to:
  /// **'Lebih {amount}'**
  String closeOver(String amount);

  /// No description provided for @closeShort.
  ///
  /// In id, this message translates to:
  /// **'Kurang {amount}'**
  String closeShort(String amount);

  /// No description provided for @closeNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get closeNote;

  /// No description provided for @closeNoteRequired.
  ///
  /// In id, this message translates to:
  /// **'Jelaskan selisihnya.'**
  String get closeNoteRequired;

  /// No description provided for @closeHeldWarning.
  ///
  /// In id, this message translates to:
  /// **'{count} tagihan masih ditahan. Tagihan itu tetap ditahan setelah shift ditutup.'**
  String closeHeldWarning(int count);

  /// No description provided for @closePending.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi belum terkirim. Semuanya dikirim sebelum penutupan shift.'**
  String closePending(int count);

  /// No description provided for @closeConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Tutup shift sekarang?'**
  String get closeConfirmTitle;

  /// No description provided for @closeConfirmBody.
  ///
  /// In id, this message translates to:
  /// **'Uang dihitung {counted}, seharusnya {expected}. Setelah ditutup, penjualan perlu shift baru.'**
  String closeConfirmBody(String counted, String expected);

  /// No description provided for @closeDone.
  ///
  /// In id, this message translates to:
  /// **'Shift ditutup.'**
  String get closeDone;

  /// No description provided for @reportTitleX.
  ///
  /// In id, this message translates to:
  /// **'Laporan X'**
  String get reportTitleX;

  /// No description provided for @reportTitleZ.
  ///
  /// In id, this message translates to:
  /// **'Laporan Z'**
  String get reportTitleZ;

  /// No description provided for @reportTerminal.
  ///
  /// In id, this message translates to:
  /// **'Terminal'**
  String get reportTerminal;

  /// No description provided for @reportOpened.
  ///
  /// In id, this message translates to:
  /// **'Dibuka'**
  String get reportOpened;

  /// No description provided for @reportClosed.
  ///
  /// In id, this message translates to:
  /// **'Ditutup'**
  String get reportClosed;

  /// No description provided for @reportSales.
  ///
  /// In id, this message translates to:
  /// **'Penjualan'**
  String get reportSales;

  /// No description provided for @reportTransactions.
  ///
  /// In id, this message translates to:
  /// **'Transaksi'**
  String get reportTransactions;

  /// No description provided for @reportGross.
  ///
  /// In id, this message translates to:
  /// **'Penjualan kotor'**
  String get reportGross;

  /// No description provided for @reportDiscounts.
  ///
  /// In id, this message translates to:
  /// **'Diskon'**
  String get reportDiscounts;

  /// No description provided for @reportNet.
  ///
  /// In id, this message translates to:
  /// **'Penjualan bersih'**
  String get reportNet;

  /// No description provided for @reportService.
  ///
  /// In id, this message translates to:
  /// **'Biaya layanan'**
  String get reportService;

  /// No description provided for @reportTax.
  ///
  /// In id, this message translates to:
  /// **'Pajak'**
  String get reportTax;

  /// No description provided for @reportRounding.
  ///
  /// In id, this message translates to:
  /// **'Pembulatan'**
  String get reportRounding;

  /// No description provided for @reportTotal.
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get reportTotal;

  /// No description provided for @reportAverage.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata per transaksi'**
  String get reportAverage;

  /// No description provided for @reportPayments.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran'**
  String get reportPayments;

  /// No description provided for @reportCorrections.
  ///
  /// In id, this message translates to:
  /// **'Koreksi'**
  String get reportCorrections;

  /// No description provided for @reportVoids.
  ///
  /// In id, this message translates to:
  /// **'Void'**
  String get reportVoids;

  /// No description provided for @reportCancelled.
  ///
  /// In id, this message translates to:
  /// **'Tagihan dibatalkan'**
  String get reportCancelled;

  /// No description provided for @reportRefunds.
  ///
  /// In id, this message translates to:
  /// **'Refund'**
  String get reportRefunds;

  /// No description provided for @reportKasbonIssued.
  ///
  /// In id, this message translates to:
  /// **'Kasbon baru'**
  String get reportKasbonIssued;

  /// No description provided for @reportKasbonRepaid.
  ///
  /// In id, this message translates to:
  /// **'Kasbon dibayar'**
  String get reportKasbonRepaid;

  /// No description provided for @reportCash.
  ///
  /// In id, this message translates to:
  /// **'Kas'**
  String get reportCash;

  /// No description provided for @reportOpeningCash.
  ///
  /// In id, this message translates to:
  /// **'Kas awal'**
  String get reportOpeningCash;

  /// No description provided for @reportCashSales.
  ///
  /// In id, this message translates to:
  /// **'Penjualan tunai'**
  String get reportCashSales;

  /// No description provided for @reportVoidedCash.
  ///
  /// In id, this message translates to:
  /// **'Void tunai'**
  String get reportVoidedCash;

  /// No description provided for @reportCashRefunds.
  ///
  /// In id, this message translates to:
  /// **'Refund tunai'**
  String get reportCashRefunds;

  /// No description provided for @reportKasbonCash.
  ///
  /// In id, this message translates to:
  /// **'Kasbon dibayar tunai'**
  String get reportKasbonCash;

  /// No description provided for @reportCashIn.
  ///
  /// In id, this message translates to:
  /// **'Kas masuk'**
  String get reportCashIn;

  /// No description provided for @reportCashOut.
  ///
  /// In id, this message translates to:
  /// **'Kas keluar'**
  String get reportCashOut;

  /// No description provided for @reportExpected.
  ///
  /// In id, this message translates to:
  /// **'Kas seharusnya'**
  String get reportExpected;

  /// No description provided for @reportCounted.
  ///
  /// In id, this message translates to:
  /// **'Kas dihitung'**
  String get reportCounted;

  /// No description provided for @reportDifference.
  ///
  /// In id, this message translates to:
  /// **'Selisih'**
  String get reportDifference;

  /// No description provided for @reportTopItems.
  ///
  /// In id, this message translates to:
  /// **'Produk terlaris'**
  String get reportTopItems;

  /// No description provided for @reportPrintedAt.
  ///
  /// In id, this message translates to:
  /// **'Dicetak {time}'**
  String reportPrintedAt(String time);

  /// No description provided for @reportPrint.
  ///
  /// In id, this message translates to:
  /// **'Cetak'**
  String get reportPrint;

  /// No description provided for @reportShare.
  ///
  /// In id, this message translates to:
  /// **'Bagikan PDF'**
  String get reportShare;

  /// No description provided for @reportMissing.
  ///
  /// In id, this message translates to:
  /// **'Shift tidak ditemukan.'**
  String get reportMissing;

  /// No description provided for @receiptVoided.
  ///
  /// In id, this message translates to:
  /// **'VOID - DIBATALKAN'**
  String get receiptVoided;

  /// No description provided for @receiptCopy.
  ///
  /// In id, this message translates to:
  /// **'SALINAN'**
  String get receiptCopy;

  /// No description provided for @receiptVoid.
  ///
  /// In id, this message translates to:
  /// **'Void'**
  String get receiptVoid;

  /// No description provided for @receiptRefund.
  ///
  /// In id, this message translates to:
  /// **'Refund'**
  String get receiptRefund;

  /// No description provided for @receiptRefundLine.
  ///
  /// In id, this message translates to:
  /// **'{number} · {method}'**
  String receiptRefundLine(String number, String method);

  /// No description provided for @receiptVoidedLine.
  ///
  /// In id, this message translates to:
  /// **'Di-void {time} oleh {name}: {reason}'**
  String receiptVoidedLine(String time, String name, String reason);

  /// No description provided for @receiptPrinted.
  ///
  /// In id, this message translates to:
  /// **'Struk dikirim ke printer.'**
  String get receiptPrinted;

  /// No description provided for @voidTitle.
  ///
  /// In id, this message translates to:
  /// **'Void {number}?'**
  String voidTitle(String number);

  /// No description provided for @voidReason.
  ///
  /// In id, this message translates to:
  /// **'Alasan void'**
  String get voidReason;

  /// No description provided for @voidApproval.
  ///
  /// In id, this message translates to:
  /// **'Void {number}.'**
  String voidApproval(String number);

  /// No description provided for @voidApprovalPrinted.
  ///
  /// In id, this message translates to:
  /// **'Void {number} setelah struk dicetak.'**
  String voidApprovalPrinted(String number);

  /// No description provided for @voidDone.
  ///
  /// In id, this message translates to:
  /// **'{number} di-void. Stok dikembalikan.'**
  String voidDone(String number);

  /// No description provided for @reasonShort.
  ///
  /// In id, this message translates to:
  /// **'Tulis alasan, minimal 3 huruf.'**
  String get reasonShort;

  /// No description provided for @printFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal mencetak: {reason}'**
  String printFailed(String reason);

  /// No description provided for @printNotConfigured.
  ///
  /// In id, this message translates to:
  /// **'Belum ada printer. Atur di Pengaturan printer, atau bagikan PDF.'**
  String get printNotConfigured;

  /// No description provided for @printUnsupported.
  ///
  /// In id, this message translates to:
  /// **'Printer ini tidak didukung di perangkat ini.'**
  String get printUnsupported;

  /// No description provided for @printConnectFailed.
  ///
  /// In id, this message translates to:
  /// **'Tidak bisa terhubung ke printer. Pastikan printer menyala dan dekat.'**
  String get printConnectFailed;

  /// No description provided for @printSendFailed.
  ///
  /// In id, this message translates to:
  /// **'Data gagal dikirim ke printer.'**
  String get printSendFailed;

  /// No description provided for @printInvalidAddress.
  ///
  /// In id, this message translates to:
  /// **'Alamat printer tidak valid.'**
  String get printInvalidAddress;

  /// No description provided for @printSystemDialog.
  ///
  /// In id, this message translates to:
  /// **'Cetak lewat dialog sistem'**
  String get printSystemDialog;

  /// No description provided for @refundTitle.
  ///
  /// In id, this message translates to:
  /// **'Refund {number}'**
  String refundTitle(String number);

  /// No description provided for @refundPickItems.
  ///
  /// In id, this message translates to:
  /// **'Pilih barang yang dikembalikan'**
  String get refundPickItems;

  /// No description provided for @refundAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get refundAll;

  /// No description provided for @refundLeft.
  ///
  /// In id, this message translates to:
  /// **'Sisa {left} dari {sold}'**
  String refundLeft(String left, String sold);

  /// No description provided for @refundRestock.
  ///
  /// In id, this message translates to:
  /// **'Kembalikan ke stok'**
  String get refundRestock;

  /// No description provided for @refundRestockHint.
  ///
  /// In id, this message translates to:
  /// **'Matikan untuk barang rusak yang dibuang.'**
  String get refundRestockHint;

  /// No description provided for @refundMethod.
  ///
  /// In id, this message translates to:
  /// **'Dikembalikan lewat'**
  String get refundMethod;

  /// No description provided for @refundViaCash.
  ///
  /// In id, this message translates to:
  /// **'Tunai'**
  String get refundViaCash;

  /// No description provided for @refundViaQris.
  ///
  /// In id, this message translates to:
  /// **'QRIS'**
  String get refundViaQris;

  /// No description provided for @refundViaCard.
  ///
  /// In id, this message translates to:
  /// **'Kartu'**
  String get refundViaCard;

  /// No description provided for @refundViaTransfer.
  ///
  /// In id, this message translates to:
  /// **'Transfer'**
  String get refundViaTransfer;

  /// No description provided for @refundViaEwallet.
  ///
  /// In id, this message translates to:
  /// **'E-wallet'**
  String get refundViaEwallet;

  /// No description provided for @refundReason.
  ///
  /// In id, this message translates to:
  /// **'Alasan refund'**
  String get refundReason;

  /// No description provided for @refundTotal.
  ///
  /// In id, this message translates to:
  /// **'Total refund'**
  String get refundTotal;

  /// No description provided for @refundRefundable.
  ///
  /// In id, this message translates to:
  /// **'Bisa dikembalikan: {amount}'**
  String refundRefundable(String amount);

  /// No description provided for @refundSubmit.
  ///
  /// In id, this message translates to:
  /// **'Refund {amount}'**
  String refundSubmit(String amount);

  /// No description provided for @refundApproval.
  ///
  /// In id, this message translates to:
  /// **'Refund {amount} untuk {number}.'**
  String refundApproval(String amount, String number);

  /// No description provided for @refundDone.
  ///
  /// In id, this message translates to:
  /// **'Refund {number} tercatat.'**
  String refundDone(String number);

  /// No description provided for @refundNothing.
  ///
  /// In id, this message translates to:
  /// **'Pilih minimal satu barang.'**
  String get refundNothing;

  /// No description provided for @refundExceedsPaid.
  ///
  /// In id, this message translates to:
  /// **'Melebihi uang yang diterima. Bagian kasbon belum bisa di-refund.'**
  String get refundExceedsPaid;

  /// No description provided for @refundZero.
  ///
  /// In id, this message translates to:
  /// **'Barang ini gratis; tidak ada uang untuk dikembalikan.'**
  String get refundZero;

  /// No description provided for @refundQuantity.
  ///
  /// In id, this message translates to:
  /// **'Jumlah melebihi sisa yang bisa dikembalikan.'**
  String get refundQuantity;

  /// No description provided for @refundFull.
  ///
  /// In id, this message translates to:
  /// **'Semua sudah di-refund.'**
  String get refundFull;

  /// No description provided for @refundSlipTitle.
  ///
  /// In id, this message translates to:
  /// **'REFUND'**
  String get refundSlipTitle;

  /// No description provided for @refundSlipOrder.
  ///
  /// In id, this message translates to:
  /// **'Dari transaksi {number}'**
  String refundSlipOrder(String number);

  /// No description provided for @refundSlipStaff.
  ///
  /// In id, this message translates to:
  /// **'Kasir: {name}'**
  String refundSlipStaff(String name);

  /// No description provided for @refundSlipApprover.
  ///
  /// In id, this message translates to:
  /// **'Disetujui: {name}'**
  String refundSlipApprover(String name);

  /// No description provided for @refundSlipMethod.
  ///
  /// In id, this message translates to:
  /// **'Dikembalikan: {method}'**
  String refundSlipMethod(String method);

  /// No description provided for @refundSlipReason.
  ///
  /// In id, this message translates to:
  /// **'Alasan: {reason}'**
  String refundSlipReason(String reason);

  /// No description provided for @posErrShiftClosed.
  ///
  /// In id, this message translates to:
  /// **'Shift sudah ditutup.'**
  String get posErrShiftClosed;

  /// No description provided for @posErrNotCompleted.
  ///
  /// In id, this message translates to:
  /// **'Hanya transaksi selesai yang bisa di-void atau di-refund.'**
  String get posErrNotCompleted;

  /// No description provided for @posErrVoidAfterRefund.
  ///
  /// In id, this message translates to:
  /// **'Transaksi yang sudah di-refund tidak bisa di-void.'**
  String get posErrVoidAfterRefund;

  /// No description provided for @posErrRefundMethod.
  ///
  /// In id, this message translates to:
  /// **'Metode refund tidak valid.'**
  String get posErrRefundMethod;

  /// No description provided for @posErrPermission.
  ///
  /// In id, this message translates to:
  /// **'Perlu izin {permission}.'**
  String posErrPermission(String permission);

  /// No description provided for @printerTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan printer'**
  String get printerTitle;

  /// No description provided for @printerNone.
  ///
  /// In id, this message translates to:
  /// **'Belum ada printer struk.'**
  String get printerNone;

  /// No description provided for @printerConnection.
  ///
  /// In id, this message translates to:
  /// **'Sambungan'**
  String get printerConnection;

  /// No description provided for @printerBluetooth.
  ///
  /// In id, this message translates to:
  /// **'Bluetooth'**
  String get printerBluetooth;

  /// No description provided for @printerUsb.
  ///
  /// In id, this message translates to:
  /// **'USB'**
  String get printerUsb;

  /// No description provided for @printerNetwork.
  ///
  /// In id, this message translates to:
  /// **'Jaringan'**
  String get printerNetwork;

  /// No description provided for @printerSearch.
  ///
  /// In id, this message translates to:
  /// **'Cari printer'**
  String get printerSearch;

  /// No description provided for @printerSearching.
  ///
  /// In id, this message translates to:
  /// **'Mencari printer…'**
  String get printerSearching;

  /// No description provided for @printerFoundNone.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada printer ditemukan. Nyalakan printer dan Bluetooth, lalu coba lagi.'**
  String get printerFoundNone;

  /// No description provided for @printerName.
  ///
  /// In id, this message translates to:
  /// **'Nama printer'**
  String get printerName;

  /// No description provided for @printerAddress.
  ///
  /// In id, this message translates to:
  /// **'Alamat'**
  String get printerAddress;

  /// No description provided for @printerAddressHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh 192.168.1.50 atau 192.168.1.50:9100'**
  String get printerAddressHint;

  /// No description provided for @printerPaper.
  ///
  /// In id, this message translates to:
  /// **'Lebar kertas'**
  String get printerPaper;

  /// No description provided for @printerPaperMm.
  ///
  /// In id, this message translates to:
  /// **'{mm} mm'**
  String printerPaperMm(int mm);

  /// No description provided for @printerOpensDrawer.
  ///
  /// In id, this message translates to:
  /// **'Buka laci kas lewat printer'**
  String get printerOpensDrawer;

  /// No description provided for @printerAutoPrint.
  ///
  /// In id, this message translates to:
  /// **'Cetak struk otomatis setelah bayar'**
  String get printerAutoPrint;

  /// No description provided for @printerTest.
  ///
  /// In id, this message translates to:
  /// **'Tes cetak'**
  String get printerTest;

  /// No description provided for @printerTestTitle.
  ///
  /// In id, this message translates to:
  /// **'TES PRINTER'**
  String get printerTestTitle;

  /// No description provided for @printerTestLine.
  ///
  /// In id, this message translates to:
  /// **'Kertas {mm} mm · {columns} kolom'**
  String printerTestLine(int mm, int columns);

  /// No description provided for @printerTestSent.
  ///
  /// In id, this message translates to:
  /// **'Halaman tes dikirim.'**
  String get printerTestSent;

  /// No description provided for @printerSaved.
  ///
  /// In id, this message translates to:
  /// **'Printer disimpan.'**
  String get printerSaved;

  /// No description provided for @printerRemove.
  ///
  /// In id, this message translates to:
  /// **'Hapus printer'**
  String get printerRemove;

  /// No description provided for @printerRemoved.
  ///
  /// In id, this message translates to:
  /// **'Printer dihapus.'**
  String get printerRemoved;

  /// No description provided for @printerAddressRequired.
  ///
  /// In id, this message translates to:
  /// **'Pilih atau isi alamat printer.'**
  String get printerAddressRequired;

  /// No description provided for @printerDiscoverUnsupported.
  ///
  /// In id, this message translates to:
  /// **'Pencarian printer tidak tersedia di perangkat ini. Pakai printer jaringan.'**
  String get printerDiscoverUnsupported;

  /// No description provided for @navShifts.
  ///
  /// In id, this message translates to:
  /// **'Shift'**
  String get navShifts;

  /// No description provided for @navAudit.
  ///
  /// In id, this message translates to:
  /// **'Log audit'**
  String get navAudit;

  /// No description provided for @adminAllStores.
  ///
  /// In id, this message translates to:
  /// **'Semua toko'**
  String get adminAllStores;

  /// No description provided for @adminPeriod.
  ///
  /// In id, this message translates to:
  /// **'{from} – {to}'**
  String adminPeriod(String from, String to);

  /// No description provided for @shiftsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada shift di periode ini.'**
  String get shiftsEmpty;

  /// No description provided for @shiftsOpen.
  ///
  /// In id, this message translates to:
  /// **'Masih buka'**
  String get shiftsOpen;

  /// No description provided for @shiftsSales.
  ///
  /// In id, this message translates to:
  /// **'Penjualan {amount}'**
  String shiftsSales(String amount);

  /// No description provided for @auditOnlyApprovals.
  ///
  /// In id, this message translates to:
  /// **'Hanya persetujuan'**
  String get auditOnlyApprovals;

  /// No description provided for @auditKind.
  ///
  /// In id, this message translates to:
  /// **'Jenis'**
  String get auditKind;

  /// No description provided for @auditAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get auditAll;

  /// No description provided for @auditKindOrders.
  ///
  /// In id, this message translates to:
  /// **'Penjualan'**
  String get auditKindOrders;

  /// No description provided for @auditKindShifts.
  ///
  /// In id, this message translates to:
  /// **'Shift'**
  String get auditKindShifts;

  /// No description provided for @auditKindCash.
  ///
  /// In id, this message translates to:
  /// **'Kas'**
  String get auditKindCash;

  /// No description provided for @auditKindPos.
  ///
  /// In id, this message translates to:
  /// **'Laci kas'**
  String get auditKindPos;

  /// No description provided for @auditKindReceipts.
  ///
  /// In id, this message translates to:
  /// **'Struk'**
  String get auditKindReceipts;

  /// No description provided for @auditKindDevices.
  ///
  /// In id, this message translates to:
  /// **'Terminal'**
  String get auditKindDevices;

  /// No description provided for @auditKindData.
  ///
  /// In id, this message translates to:
  /// **'Perubahan data'**
  String get auditKindData;

  /// No description provided for @auditEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada catatan.'**
  String get auditEmpty;

  /// No description provided for @auditLoadMore.
  ///
  /// In id, this message translates to:
  /// **'Muat lagi'**
  String get auditLoadMore;

  /// No description provided for @auditApprovedBy.
  ///
  /// In id, this message translates to:
  /// **'disetujui {name}'**
  String auditApprovedBy(String name);

  /// No description provided for @auditSystem.
  ///
  /// In id, this message translates to:
  /// **'Sistem'**
  String get auditSystem;

  /// No description provided for @auditActionName.
  ///
  /// In id, this message translates to:
  /// **'{action, select, shift_opened{Shift dibuka} shift_closed{Shift ditutup} cash_movement_in{Kas masuk} cash_movement_out{Kas keluar} order_voided{Transaksi di-void} order_refunded{Refund} order_cancelled{Tagihan dibatalkan} order_discount_approved{Diskon disetujui} pos_drawer_open_no_sale{Laci dibuka tanpa transaksi} receipt_reprinted{Struk dicetak ulang} device_paired{Terminal dipasangkan} device_revoked{Terminal dicabut} device_pairing_code_created{Kode pasang dibuat} employee_pin_set{PIN diatur} catalog_imported{Katalog diimpor} kasbon_repayment{Pembayaran kasbon} other{{action}}}'**
  String auditActionName(String action);

  /// No description provided for @pointsTitle.
  ///
  /// In id, this message translates to:
  /// **'Tukar poin'**
  String get pointsTitle;

  /// No description provided for @pointsBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo {points} poin'**
  String pointsBalance(int points);

  /// No description provided for @pointsMax.
  ///
  /// In id, this message translates to:
  /// **'Maksimal {points} poin ({amount})'**
  String pointsMax(int points, String amount);

  /// No description provided for @pointsMin.
  ///
  /// In id, this message translates to:
  /// **'Minimal {points} poin'**
  String pointsMin(int points);

  /// No description provided for @pointsField.
  ///
  /// In id, this message translates to:
  /// **'Jumlah poin'**
  String get pointsField;

  /// No description provided for @pointsAll.
  ///
  /// In id, this message translates to:
  /// **'Maks'**
  String get pointsAll;

  /// No description provided for @pointsRemove.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get pointsRemove;

  /// No description provided for @pointsUse.
  ///
  /// In id, this message translates to:
  /// **'Pakai'**
  String get pointsUse;

  /// No description provided for @pointsTooMany.
  ///
  /// In id, this message translates to:
  /// **'Paling banyak {points} poin.'**
  String pointsTooMany(int points);

  /// No description provided for @pointsBelowMin.
  ///
  /// In id, this message translates to:
  /// **'Paling sedikit {points} poin.'**
  String pointsBelowMin(int points);

  /// No description provided for @pointsUsed.
  ///
  /// In id, this message translates to:
  /// **'−{points} poin'**
  String pointsUsed(int points);

  /// No description provided for @pointsButton.
  ///
  /// In id, this message translates to:
  /// **'{points} poin'**
  String pointsButton(int points);

  /// No description provided for @posErrPoints.
  ///
  /// In id, this message translates to:
  /// **'Poin tidak cukup atau di bawah minimum.'**
  String get posErrPoints;

  /// No description provided for @posErrVoidKasbonPaid.
  ///
  /// In id, this message translates to:
  /// **'Kasbon ini sudah dicicil; lakukan refund, bukan void.'**
  String get posErrVoidKasbonPaid;

  /// No description provided for @receiptPointsEarned.
  ///
  /// In id, this message translates to:
  /// **'Poin didapat: {points}'**
  String receiptPointsEarned(int points);

  /// No description provided for @posCustomers.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get posCustomers;

  /// No description provided for @posCustomersHint.
  ///
  /// In id, this message translates to:
  /// **'Poin, kasbon dan cicilan'**
  String get posCustomersHint;

  /// No description provided for @customersTitle.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get customersTitle;

  /// No description provided for @customersSearch.
  ///
  /// In id, this message translates to:
  /// **'Cari nama, nomor HP atau kode'**
  String get customersSearch;

  /// No description provided for @customersEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pelanggan.'**
  String get customersEmpty;

  /// No description provided for @customersPoints.
  ///
  /// In id, this message translates to:
  /// **'{points} poin'**
  String customersPoints(int points);

  /// No description provided for @customersOwes.
  ///
  /// In id, this message translates to:
  /// **'Kasbon {amount}'**
  String customersOwes(String amount);

  /// No description provided for @customerEdit.
  ///
  /// In id, this message translates to:
  /// **'Ubah pelanggan'**
  String get customerEdit;

  /// No description provided for @customerSaved.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan disimpan.'**
  String get customerSaved;

  /// No description provided for @customerTotalOwed.
  ///
  /// In id, this message translates to:
  /// **'Kasbon {amount}'**
  String customerTotalOwed(String amount);

  /// No description provided for @customerPay.
  ///
  /// In id, this message translates to:
  /// **'Bayar kasbon'**
  String get customerPay;

  /// No description provided for @customerKasbon.
  ///
  /// In id, this message translates to:
  /// **'Kasbon'**
  String get customerKasbon;

  /// No description provided for @customerNoKasbon.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada kasbon.'**
  String get customerNoKasbon;

  /// No description provided for @customerKasbonLine.
  ///
  /// In id, this message translates to:
  /// **'Sisa {left} dari {amount}'**
  String customerKasbonLine(String left, String amount);

  /// No description provided for @customerDue.
  ///
  /// In id, this message translates to:
  /// **'Jatuh tempo {date}'**
  String customerDue(String date);

  /// No description provided for @customerOverdue.
  ///
  /// In id, this message translates to:
  /// **'Terlambat {days} hari'**
  String customerOverdue(int days);

  /// No description provided for @customerInstallments.
  ///
  /// In id, this message translates to:
  /// **'Cicilan di terminal ini'**
  String get customerInstallments;

  /// No description provided for @repayTitle.
  ///
  /// In id, this message translates to:
  /// **'Bayar kasbon {name}'**
  String repayTitle(String name);

  /// No description provided for @repayOwed.
  ///
  /// In id, this message translates to:
  /// **'Kasbon {amount}'**
  String repayOwed(String amount);

  /// No description provided for @repayAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get repayAmount;

  /// No description provided for @repayAll.
  ///
  /// In id, this message translates to:
  /// **'Lunasi'**
  String get repayAll;

  /// No description provided for @repayMethod.
  ///
  /// In id, this message translates to:
  /// **'Metode'**
  String get repayMethod;

  /// No description provided for @repayReference.
  ///
  /// In id, this message translates to:
  /// **'Referensi'**
  String get repayReference;

  /// No description provided for @repayInvalid.
  ///
  /// In id, this message translates to:
  /// **'Isi jumlah.'**
  String get repayInvalid;

  /// No description provided for @repayNothing.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada kasbon.'**
  String get repayNothing;

  /// No description provided for @repayExceeds.
  ///
  /// In id, this message translates to:
  /// **'Melebihi sisa kasbon.'**
  String get repayExceeds;

  /// No description provided for @repayDone.
  ///
  /// In id, this message translates to:
  /// **'Cicilan {amount} diterima. Sisa kasbon {left}.'**
  String repayDone(String amount, String left);

  /// No description provided for @kasbonSlipTitle.
  ///
  /// In id, this message translates to:
  /// **'PEMBAYARAN KASBON'**
  String get kasbonSlipTitle;

  /// No description provided for @kasbonSlipCustomer.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan: {name}'**
  String kasbonSlipCustomer(String name);

  /// No description provided for @kasbonSlipCashier.
  ///
  /// In id, this message translates to:
  /// **'Kasir: {name}'**
  String kasbonSlipCashier(String name);

  /// No description provided for @kasbonSlipBefore.
  ///
  /// In id, this message translates to:
  /// **'Kasbon sebelumnya'**
  String get kasbonSlipBefore;

  /// No description provided for @kasbonSlipPaid.
  ///
  /// In id, this message translates to:
  /// **'Dibayar'**
  String get kasbonSlipPaid;

  /// No description provided for @kasbonSlipAfter.
  ///
  /// In id, this message translates to:
  /// **'Sisa kasbon'**
  String get kasbonSlipAfter;

  /// No description provided for @kasbonSlipMethod.
  ///
  /// In id, this message translates to:
  /// **'Metode: {method}'**
  String kasbonSlipMethod(String method);

  /// No description provided for @kasbonSlipSettled.
  ///
  /// In id, this message translates to:
  /// **'LUNAS'**
  String get kasbonSlipSettled;

  /// No description provided for @navCustomers.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get navCustomers;

  /// No description provided for @navKasbon.
  ///
  /// In id, this message translates to:
  /// **'Kasbon'**
  String get navKasbon;

  /// No description provided for @navLoyalty.
  ///
  /// In id, this message translates to:
  /// **'Loyalti & kasbon'**
  String get navLoyalty;

  /// No description provided for @ledgerEntryType.
  ///
  /// In id, this message translates to:
  /// **'{type, select, earn{Poin didapat} redeem{Poin ditukar} reverse_earn{Poin dibatalkan} reverse_redeem{Poin dikembalikan} adjust{Penyesuaian} other{{type}}}'**
  String ledgerEntryType(String type);

  /// No description provided for @kasbonStatus.
  ///
  /// In id, this message translates to:
  /// **'{status, select, open{Belum dibayar} partial{Dicicil} paid{Lunas} void{Batal} other{{status}}}'**
  String kasbonStatus(String status);

  /// No description provided for @adminCustomerEmail.
  ///
  /// In id, this message translates to:
  /// **'E-mail'**
  String get adminCustomerEmail;

  /// No description provided for @adminCustomerLimit.
  ///
  /// In id, this message translates to:
  /// **'Batas kasbon'**
  String get adminCustomerLimit;

  /// No description provided for @adminCustomerLimitHint.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan untuk tanpa batas'**
  String get adminCustomerLimitHint;

  /// No description provided for @adminCustomerLimitShort.
  ///
  /// In id, this message translates to:
  /// **'Batas {amount}'**
  String adminCustomerLimitShort(String amount);

  /// No description provided for @adminAdjustPoints.
  ///
  /// In id, this message translates to:
  /// **'Sesuaikan poin'**
  String get adminAdjustPoints;

  /// No description provided for @adminAdjustPointsField.
  ///
  /// In id, this message translates to:
  /// **'Poin (+ atau −)'**
  String get adminAdjustPointsField;

  /// No description provided for @adminAdjustNote.
  ///
  /// In id, this message translates to:
  /// **'Alasan'**
  String get adminAdjustNote;

  /// No description provided for @adminAdjustDone.
  ///
  /// In id, this message translates to:
  /// **'Saldo poin sekarang {points}.'**
  String adminAdjustDone(int points);

  /// No description provided for @adminPointsHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat poin'**
  String get adminPointsHistory;

  /// No description provided for @adminKasbonPaidLine.
  ///
  /// In id, this message translates to:
  /// **'Dibayar {paid} dari {amount}'**
  String adminKasbonPaidLine(String paid, String amount);

  /// No description provided for @adminKasbonTotal.
  ///
  /// In id, this message translates to:
  /// **'Total {total} · terlambat {overdue}'**
  String adminKasbonTotal(String total, String overdue);

  /// No description provided for @adminKasbonEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada kasbon terbuka.'**
  String get adminKasbonEmpty;

  /// No description provided for @adminKasbonOldest.
  ///
  /// In id, this message translates to:
  /// **'Tertua {date}'**
  String adminKasbonOldest(String date);

  /// No description provided for @adminKasbonOverdue.
  ///
  /// In id, this message translates to:
  /// **'Terlambat {amount}'**
  String adminKasbonOverdue(String amount);

  /// No description provided for @loyaltyEnabled.
  ///
  /// In id, this message translates to:
  /// **'Program poin aktif'**
  String get loyaltyEnabled;

  /// No description provided for @loyaltyEarn.
  ///
  /// In id, this message translates to:
  /// **'Belanja untuk 1 poin'**
  String get loyaltyEarn;

  /// No description provided for @loyaltyValue.
  ///
  /// In id, this message translates to:
  /// **'Nilai 1 poin saat ditukar'**
  String get loyaltyValue;

  /// No description provided for @loyaltyMin.
  ///
  /// In id, this message translates to:
  /// **'Minimal poin sekali tukar'**
  String get loyaltyMin;

  /// No description provided for @loyaltyDueDays.
  ///
  /// In id, this message translates to:
  /// **'Jatuh tempo kasbon (hari)'**
  String get loyaltyDueDays;

  /// No description provided for @loyaltyRange.
  ///
  /// In id, this message translates to:
  /// **'Isi angka {min}–{max}.'**
  String loyaltyRange(int min, int max);

  /// No description provided for @loyaltyOwnerOnly.
  ///
  /// In id, this message translates to:
  /// **'Hanya pemilik yang bisa mengubah pengaturan ini.'**
  String get loyaltyOwnerOnly;

  /// No description provided for @loyaltyHint.
  ///
  /// In id, this message translates to:
  /// **'Berlaku untuk semua toko. Terminal memakai pengaturan baru setelah sinkron berikutnya.'**
  String get loyaltyHint;

  /// No description provided for @cashMovementApproval.
  ///
  /// In id, this message translates to:
  /// **'{kind} {amount} membuka laci: {reason}'**
  String cashMovementApproval(String kind, String amount, String reason);

  /// No description provided for @navReports.
  ///
  /// In id, this message translates to:
  /// **'Laporan'**
  String get navReports;

  /// No description provided for @reportTabSales.
  ///
  /// In id, this message translates to:
  /// **'Penjualan'**
  String get reportTabSales;

  /// No description provided for @reportTabPayments.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran'**
  String get reportTabPayments;

  /// No description provided for @reportTabProducts.
  ///
  /// In id, this message translates to:
  /// **'Produk'**
  String get reportTabProducts;

  /// No description provided for @reportTabStaff.
  ///
  /// In id, this message translates to:
  /// **'Staf'**
  String get reportTabStaff;

  /// No description provided for @reportTabTax.
  ///
  /// In id, this message translates to:
  /// **'Pajak'**
  String get reportTabTax;

  /// No description provided for @reportTabStock.
  ///
  /// In id, this message translates to:
  /// **'Nilai stok'**
  String get reportTabStock;

  /// No description provided for @periodToday.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get periodToday;

  /// No description provided for @periodYesterday.
  ///
  /// In id, this message translates to:
  /// **'Kemarin'**
  String get periodYesterday;

  /// No description provided for @periodLast7.
  ///
  /// In id, this message translates to:
  /// **'7 hari'**
  String get periodLast7;

  /// No description provided for @periodThisMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan ini'**
  String get periodThisMonth;

  /// No description provided for @periodLastMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan lalu'**
  String get periodLastMonth;

  /// No description provided for @periodCustom.
  ///
  /// In id, this message translates to:
  /// **'Pilih tanggal'**
  String get periodCustom;

  /// No description provided for @exportPdf.
  ///
  /// In id, this message translates to:
  /// **'PDF'**
  String get exportPdf;

  /// No description provided for @exportExcel.
  ///
  /// In id, this message translates to:
  /// **'Excel'**
  String get exportExcel;

  /// No description provided for @exportSaved.
  ///
  /// In id, this message translates to:
  /// **'File disimpan.'**
  String get exportSaved;

  /// No description provided for @reportEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada data di periode ini.'**
  String get reportEmpty;

  /// No description provided for @reportStockSubtitle.
  ///
  /// In id, this message translates to:
  /// **'{store} · per {time}'**
  String reportStockSubtitle(String store, String time);

  /// No description provided for @reportSummary.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan'**
  String get reportSummary;

  /// No description provided for @reportItem.
  ///
  /// In id, this message translates to:
  /// **'Rincian'**
  String get reportItem;

  /// No description provided for @summaryGross.
  ///
  /// In id, this message translates to:
  /// **'Penjualan kotor'**
  String get summaryGross;

  /// No description provided for @summaryDiscounts.
  ///
  /// In id, this message translates to:
  /// **'Diskon'**
  String get summaryDiscounts;

  /// No description provided for @summaryNet.
  ///
  /// In id, this message translates to:
  /// **'Penjualan setelah diskon'**
  String get summaryNet;

  /// No description provided for @summaryService.
  ///
  /// In id, this message translates to:
  /// **'Biaya layanan'**
  String get summaryService;

  /// No description provided for @summaryTax.
  ///
  /// In id, this message translates to:
  /// **'Pajak ditambahkan atau termasuk'**
  String get summaryTax;

  /// No description provided for @summaryRounding.
  ///
  /// In id, this message translates to:
  /// **'Pembulatan'**
  String get summaryRounding;

  /// No description provided for @reportByHour.
  ///
  /// In id, this message translates to:
  /// **'Penjualan per jam'**
  String get reportByHour;

  /// No description provided for @reportSalesNote.
  ///
  /// In id, this message translates to:
  /// **'Penjualan = transaksi selesai. Void tidak termasuk penjualan. Refund dihitung pada tanggal refund.'**
  String get reportSalesNote;

  /// No description provided for @reportProductsNote.
  ///
  /// In id, this message translates to:
  /// **'Bersih sebelum refund; refund ditampilkan sebagai qty refund.'**
  String get reportProductsNote;

  /// No description provided for @reportProductsMore.
  ///
  /// In id, this message translates to:
  /// **'Menampilkan {shown} dari {total} produk. Ekspor berisi daftar yang sama.'**
  String reportProductsMore(int shown, int total);

  /// No description provided for @reportTaxNote.
  ///
  /// In id, this message translates to:
  /// **'Harga termasuk pajak: DPP = dasar pajak − PPN. Barang bebas pajak (sembako) tidak masuk dasar pajak.'**
  String get reportTaxNote;

  /// No description provided for @reportStockNote.
  ///
  /// In id, this message translates to:
  /// **'Nilai = stok × HPP saat ini. Stok minus tidak menambah nilai.'**
  String get reportStockNote;

  /// No description provided for @reportNegativeNote.
  ///
  /// In id, this message translates to:
  /// **'Periksa dengan stok opname.'**
  String get reportNegativeNote;

  /// No description provided for @colDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get colDate;

  /// No description provided for @colOrders.
  ///
  /// In id, this message translates to:
  /// **'Transaksi'**
  String get colOrders;

  /// No description provided for @colSales.
  ///
  /// In id, this message translates to:
  /// **'Penjualan'**
  String get colSales;

  /// No description provided for @colRefunds.
  ///
  /// In id, this message translates to:
  /// **'Refund'**
  String get colRefunds;

  /// No description provided for @colNetSales.
  ///
  /// In id, this message translates to:
  /// **'Penjualan bersih'**
  String get colNetSales;

  /// No description provided for @colStore.
  ///
  /// In id, this message translates to:
  /// **'Toko'**
  String get colStore;

  /// No description provided for @colMethod.
  ///
  /// In id, this message translates to:
  /// **'Metode'**
  String get colMethod;

  /// No description provided for @colCount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get colCount;

  /// No description provided for @colAmount.
  ///
  /// In id, this message translates to:
  /// **'Nilai'**
  String get colAmount;

  /// No description provided for @colShare.
  ///
  /// In id, this message translates to:
  /// **'Porsi'**
  String get colShare;

  /// No description provided for @colProduct.
  ///
  /// In id, this message translates to:
  /// **'Produk'**
  String get colProduct;

  /// No description provided for @colSku.
  ///
  /// In id, this message translates to:
  /// **'SKU'**
  String get colSku;

  /// No description provided for @colCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get colCategory;

  /// No description provided for @colQty.
  ///
  /// In id, this message translates to:
  /// **'Qty'**
  String get colQty;

  /// No description provided for @colRefundedQty.
  ///
  /// In id, this message translates to:
  /// **'Qty refund'**
  String get colRefundedQty;

  /// No description provided for @colNet.
  ///
  /// In id, this message translates to:
  /// **'Bersih'**
  String get colNet;

  /// No description provided for @colCost.
  ///
  /// In id, this message translates to:
  /// **'HPP'**
  String get colCost;

  /// No description provided for @colMargin.
  ///
  /// In id, this message translates to:
  /// **'Margin'**
  String get colMargin;

  /// No description provided for @colStaff.
  ///
  /// In id, this message translates to:
  /// **'Staf'**
  String get colStaff;

  /// No description provided for @colAverage.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata'**
  String get colAverage;

  /// No description provided for @colDiscounts.
  ///
  /// In id, this message translates to:
  /// **'Diskon'**
  String get colDiscounts;

  /// No description provided for @colVoids.
  ///
  /// In id, this message translates to:
  /// **'Void'**
  String get colVoids;

  /// No description provided for @colBase.
  ///
  /// In id, this message translates to:
  /// **'Dasar pajak'**
  String get colBase;

  /// No description provided for @colDpp.
  ///
  /// In id, this message translates to:
  /// **'DPP'**
  String get colDpp;

  /// No description provided for @colTax.
  ///
  /// In id, this message translates to:
  /// **'PPN'**
  String get colTax;

  /// No description provided for @colExempt.
  ///
  /// In id, this message translates to:
  /// **'Bebas pajak'**
  String get colExempt;

  /// No description provided for @colStock.
  ///
  /// In id, this message translates to:
  /// **'Stok'**
  String get colStock;

  /// No description provided for @colValue.
  ///
  /// In id, this message translates to:
  /// **'Nilai'**
  String get colValue;

  /// No description provided for @totalRow.
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get totalRow;

  /// No description provided for @sumItems.
  ///
  /// In id, this message translates to:
  /// **'Barang terjual'**
  String get sumItems;

  /// No description provided for @sumKasbonIssued.
  ///
  /// In id, this message translates to:
  /// **'Kasbon baru'**
  String get sumKasbonIssued;

  /// No description provided for @sumKasbonRepaid.
  ///
  /// In id, this message translates to:
  /// **'Kasbon dibayar'**
  String get sumKasbonRepaid;

  /// No description provided for @sumMargin.
  ///
  /// In id, this message translates to:
  /// **'Margin kotor'**
  String get sumMargin;

  /// No description provided for @sumStockValue.
  ///
  /// In id, this message translates to:
  /// **'Nilai stok'**
  String get sumStockValue;

  /// No description provided for @sumNegative.
  ///
  /// In id, this message translates to:
  /// **'Stok minus'**
  String get sumNegative;

  /// No description provided for @sumLow.
  ///
  /// In id, this message translates to:
  /// **'Stok menipis'**
  String get sumLow;

  /// No description provided for @dashTitle.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get dashTitle;

  /// No description provided for @dashVsYesterday.
  ///
  /// In id, this message translates to:
  /// **'Kemarin {value}'**
  String dashVsYesterday(String value);

  /// No description provided for @dashLast7.
  ///
  /// In id, this message translates to:
  /// **'Penjualan 7 hari terakhir'**
  String get dashLast7;

  /// No description provided for @dashTop.
  ///
  /// In id, this message translates to:
  /// **'Produk terlaris hari ini'**
  String get dashTop;

  /// No description provided for @dashPayments.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran hari ini'**
  String get dashPayments;

  /// No description provided for @dashOpenShifts.
  ///
  /// In id, this message translates to:
  /// **'{count} shift terbuka'**
  String dashOpenShifts(int count);

  /// No description provided for @dashLowStock.
  ///
  /// In id, this message translates to:
  /// **'{count} stok menipis'**
  String dashLowStock(int count);

  /// No description provided for @dashAlerts.
  ///
  /// In id, this message translates to:
  /// **'{count} peringatan'**
  String dashAlerts(int count);

  /// No description provided for @dashOverdue.
  ///
  /// In id, this message translates to:
  /// **'Kasbon terlambat {amount}'**
  String dashOverdue(String amount);

  /// No description provided for @dashNothing.
  ///
  /// In id, this message translates to:
  /// **'Belum ada penjualan hari ini.'**
  String get dashNothing;

  /// No description provided for @dashAllReports.
  ///
  /// In id, this message translates to:
  /// **'Semua laporan'**
  String get dashAllReports;

  /// No description provided for @navPurchasing.
  ///
  /// In id, this message translates to:
  /// **'Pembelian'**
  String get navPurchasing;

  /// No description provided for @navTransfers.
  ///
  /// In id, this message translates to:
  /// **'Transfer'**
  String get navTransfers;

  /// No description provided for @navTables.
  ///
  /// In id, this message translates to:
  /// **'Meja'**
  String get navTables;

  /// No description provided for @poStatus.
  ///
  /// In id, this message translates to:
  /// **'{status, select, draft{Draf} ordered{Dipesan} partially_received{Diterima sebagian} received{Diterima} cancelled{Dibatalkan} other{{status}}}'**
  String poStatus(String status);

  /// No description provided for @purchaseNew.
  ///
  /// In id, this message translates to:
  /// **'PO baru'**
  String get purchaseNew;

  /// No description provided for @purchaseEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada purchase order.'**
  String get purchaseEmpty;

  /// No description provided for @purchaseLines.
  ///
  /// In id, this message translates to:
  /// **'{count} baris'**
  String purchaseLines(int count);

  /// No description provided for @purchaseExpected.
  ///
  /// In id, this message translates to:
  /// **'Tanggal diharapkan'**
  String get purchaseExpected;

  /// No description provided for @purchaseExpectedShort.
  ///
  /// In id, this message translates to:
  /// **'Diharapkan {date}'**
  String purchaseExpectedShort(String date);

  /// No description provided for @purchaseSupplier.
  ///
  /// In id, this message translates to:
  /// **'Pemasok'**
  String get purchaseSupplier;

  /// No description provided for @purchaseAddItem.
  ///
  /// In id, this message translates to:
  /// **'Tambah barang'**
  String get purchaseAddItem;

  /// No description provided for @purchaseSearchItem.
  ///
  /// In id, this message translates to:
  /// **'Cari nama atau SKU'**
  String get purchaseSearchItem;

  /// No description provided for @purchaseIncomplete.
  ///
  /// In id, this message translates to:
  /// **'Pilih toko, pemasok dan minimal satu barang.'**
  String get purchaseIncomplete;

  /// No description provided for @purchaseQtyInvalid.
  ///
  /// In id, this message translates to:
  /// **'Periksa angka untuk {name}.'**
  String purchaseQtyInvalid(String name);

  /// No description provided for @purchaseQtyTooMuch.
  ///
  /// In id, this message translates to:
  /// **'{name}: maksimal {max}.'**
  String purchaseQtyTooMuch(String name, String max);

  /// No description provided for @purchaseQtyNone.
  ///
  /// In id, this message translates to:
  /// **'Isi minimal satu jumlah.'**
  String get purchaseQtyNone;

  /// No description provided for @purchaseMax.
  ///
  /// In id, this message translates to:
  /// **'maks {max}'**
  String purchaseMax(String max);

  /// No description provided for @purchaseOrder.
  ///
  /// In id, this message translates to:
  /// **'Pesan'**
  String get purchaseOrder;

  /// No description provided for @purchaseOrdered.
  ///
  /// In id, this message translates to:
  /// **'Pesanan dikirim'**
  String get purchaseOrdered;

  /// No description provided for @purchaseCancel.
  ///
  /// In id, this message translates to:
  /// **'Batalkan'**
  String get purchaseCancel;

  /// No description provided for @purchaseCancelled.
  ///
  /// In id, this message translates to:
  /// **'PO dibatalkan'**
  String get purchaseCancelled;

  /// No description provided for @purchaseReceive.
  ///
  /// In id, this message translates to:
  /// **'Terima barang'**
  String get purchaseReceive;

  /// No description provided for @purchaseReceiveTitle.
  ///
  /// In id, this message translates to:
  /// **'Terima barang · {number}'**
  String purchaseReceiveTitle(String number);

  /// No description provided for @purchaseReceived.
  ///
  /// In id, this message translates to:
  /// **'Diterima dengan nomor {number}'**
  String purchaseReceived(String number);

  /// No description provided for @purchaseReceipts.
  ///
  /// In id, this message translates to:
  /// **'Penerimaan barang'**
  String get purchaseReceipts;

  /// No description provided for @purchaseOrderedCol.
  ///
  /// In id, this message translates to:
  /// **'Dipesan'**
  String get purchaseOrderedCol;

  /// No description provided for @purchaseReceivedCol.
  ///
  /// In id, this message translates to:
  /// **'Diterima'**
  String get purchaseReceivedCol;

  /// No description provided for @purchaseCost.
  ///
  /// In id, this message translates to:
  /// **'Harga beli'**
  String get purchaseCost;

  /// No description provided for @purchaseUnit.
  ///
  /// In id, this message translates to:
  /// **'Satuan'**
  String get purchaseUnit;

  /// No description provided for @purchasePdfTitle.
  ///
  /// In id, this message translates to:
  /// **'Purchase order {number}'**
  String purchasePdfTitle(String number);

  /// No description provided for @transferNew.
  ///
  /// In id, this message translates to:
  /// **'Minta transfer'**
  String get transferNew;

  /// No description provided for @transferEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transfer.'**
  String get transferEmpty;

  /// No description provided for @transferIncoming.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get transferIncoming;

  /// No description provided for @transferOutgoing.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get transferOutgoing;

  /// No description provided for @transferStatus.
  ///
  /// In id, this message translates to:
  /// **'{status, select, requested{Diminta} approved{Disetujui} in_transit{Dikirim} received{Diterima} rejected{Ditolak} cancelled{Dibatalkan} other{{status}}}'**
  String transferStatus(String status);

  /// No description provided for @transferEvent.
  ///
  /// In id, this message translates to:
  /// **'{event, select, requested{Diminta} approved{Disetujui} shipped{Dikirim} received{Diterima} rejected{Ditolak} cancelled{Dibatalkan} other{{event}}}'**
  String transferEvent(String event);

  /// No description provided for @transferFrom.
  ///
  /// In id, this message translates to:
  /// **'Dari toko (pengirim)'**
  String get transferFrom;

  /// No description provided for @transferTo.
  ///
  /// In id, this message translates to:
  /// **'Ke toko (penerima)'**
  String get transferTo;

  /// No description provided for @transferIncomplete.
  ///
  /// In id, this message translates to:
  /// **'Pilih dua toko yang berbeda dan minimal satu barang.'**
  String get transferIncomplete;

  /// No description provided for @transferSubmit.
  ///
  /// In id, this message translates to:
  /// **'Kirim permintaan'**
  String get transferSubmit;

  /// No description provided for @transferApprove.
  ///
  /// In id, this message translates to:
  /// **'Setujui'**
  String get transferApprove;

  /// No description provided for @transferReject.
  ///
  /// In id, this message translates to:
  /// **'Tolak'**
  String get transferReject;

  /// No description provided for @transferRejectReason.
  ///
  /// In id, this message translates to:
  /// **'Alasan'**
  String get transferRejectReason;

  /// No description provided for @transferRejectedBecause.
  ///
  /// In id, this message translates to:
  /// **'Ditolak: {reason}'**
  String transferRejectedBecause(String reason);

  /// No description provided for @transferShip.
  ///
  /// In id, this message translates to:
  /// **'Kirim barang'**
  String get transferShip;

  /// No description provided for @transferShipTitle.
  ///
  /// In id, this message translates to:
  /// **'Kirim barang · {number}'**
  String transferShipTitle(String number);

  /// No description provided for @transferReceiveTitle.
  ///
  /// In id, this message translates to:
  /// **'Terima · {number}'**
  String transferReceiveTitle(String number);

  /// No description provided for @transferCancel.
  ///
  /// In id, this message translates to:
  /// **'Batalkan transfer'**
  String get transferCancel;

  /// No description provided for @transferRequested.
  ///
  /// In id, this message translates to:
  /// **'Diminta'**
  String get transferRequested;

  /// No description provided for @transferShipped.
  ///
  /// In id, this message translates to:
  /// **'Dikirim'**
  String get transferShipped;

  /// No description provided for @transferSenderStock.
  ///
  /// In id, this message translates to:
  /// **'Stok pengirim'**
  String get transferSenderStock;

  /// No description provided for @transferHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat'**
  String get transferHistory;

  /// No description provided for @fnbMode.
  ///
  /// In id, this message translates to:
  /// **'Mode F&B (resto/kafe)'**
  String get fnbMode;

  /// No description provided for @fnbModeHint.
  ///
  /// In id, this message translates to:
  /// **'Mengaktifkan meja, tiket dapur dan layar dapur di terminal toko ini.'**
  String get fnbModeHint;

  /// No description provided for @fnbModeOwnerOnly.
  ///
  /// In id, this message translates to:
  /// **'Hanya pemilik yang dapat mengubah ini.'**
  String get fnbModeOwnerOnly;

  /// No description provided for @tablesEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada meja.'**
  String get tablesEmpty;

  /// No description provided for @tableNew.
  ///
  /// In id, this message translates to:
  /// **'Meja baru'**
  String get tableNew;

  /// No description provided for @tableEdit.
  ///
  /// In id, this message translates to:
  /// **'Ubah meja'**
  String get tableEdit;

  /// No description provided for @tableName.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get tableName;

  /// No description provided for @tableArea.
  ///
  /// In id, this message translates to:
  /// **'Area (opsional)'**
  String get tableArea;

  /// No description provided for @tableCapacity.
  ///
  /// In id, this message translates to:
  /// **'Jumlah kursi'**
  String get tableCapacity;

  /// No description provided for @tableSeats.
  ///
  /// In id, this message translates to:
  /// **'{count} kursi'**
  String tableSeats(int count);

  /// No description provided for @tableInvalid.
  ///
  /// In id, this message translates to:
  /// **'Isi nama dan minimal 1 kursi.'**
  String get tableInvalid;

  /// No description provided for @kitchenTitle.
  ///
  /// In id, this message translates to:
  /// **'Dapur'**
  String get kitchenTitle;

  /// No description provided for @kitchenRefresh.
  ///
  /// In id, this message translates to:
  /// **'Muat ulang'**
  String get kitchenRefresh;

  /// No description provided for @kitchenEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pesanan.'**
  String get kitchenEmpty;

  /// No description provided for @kitchenOffline.
  ///
  /// In id, this message translates to:
  /// **'Tidak terhubung ke server. Menampilkan daftar terakhir.'**
  String get kitchenOffline;

  /// No description provided for @kitchenAge.
  ///
  /// In id, this message translates to:
  /// **'{minutes}\''**
  String kitchenAge(int minutes);

  /// No description provided for @kitchenStatus.
  ///
  /// In id, this message translates to:
  /// **'{status, select, new{Baru} preparing{Dimasak} ready{Siap} served{Disajikan} other{{status}}}'**
  String kitchenStatus(String status);

  /// No description provided for @kitchenStart.
  ///
  /// In id, this message translates to:
  /// **'Mulai'**
  String get kitchenStart;

  /// No description provided for @kitchenReady.
  ///
  /// In id, this message translates to:
  /// **'Siap'**
  String get kitchenReady;

  /// No description provided for @kitchenServed.
  ///
  /// In id, this message translates to:
  /// **'Disajikan'**
  String get kitchenServed;

  /// No description provided for @kitchenSend.
  ///
  /// In id, this message translates to:
  /// **'Kirim ke dapur'**
  String get kitchenSend;

  /// No description provided for @kitchenSent.
  ///
  /// In id, this message translates to:
  /// **'Terkirim ke dapur: {number}'**
  String kitchenSent(String number);

  /// No description provided for @kitchenNoPrinter.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada printer untuk {stations}: pesanan tampil di layar dapur.'**
  String kitchenNoPrinter(String stations);

  /// No description provided for @stationKitchen.
  ///
  /// In id, this message translates to:
  /// **'Dapur'**
  String get stationKitchen;

  /// No description provided for @stationBar.
  ///
  /// In id, this message translates to:
  /// **'Bar'**
  String get stationBar;

  /// No description provided for @orderTakeaway.
  ///
  /// In id, this message translates to:
  /// **'Bawa pulang'**
  String get orderTakeaway;

  /// No description provided for @ticketTable.
  ///
  /// In id, this message translates to:
  /// **'{table} · {guests} tamu'**
  String ticketTable(String table, int guests);

  /// No description provided for @ticketAddition.
  ///
  /// In id, this message translates to:
  /// **'-- TAMBAHAN --'**
  String get ticketAddition;

  /// No description provided for @posErrTableOccupied.
  ///
  /// In id, this message translates to:
  /// **'Meja ini sudah punya bill terbuka. Lanjutkan bill tersebut.'**
  String get posErrTableOccupied;

  /// No description provided for @posErrTableHasBill.
  ///
  /// In id, this message translates to:
  /// **'Selesaikan atau batalkan bill di meja ini dulu.'**
  String get posErrTableHasBill;

  /// No description provided for @posTablesHint.
  ///
  /// In id, this message translates to:
  /// **'Bill makan di tempat per meja'**
  String get posTablesHint;

  /// No description provided for @posKitchenHint.
  ///
  /// In id, this message translates to:
  /// **'Pesanan untuk dapur dan bar'**
  String get posKitchenHint;

  /// No description provided for @printerSlotReceipt.
  ///
  /// In id, this message translates to:
  /// **'Struk'**
  String get printerSlotReceipt;

  /// No description provided for @printerSlotKitchen.
  ///
  /// In id, this message translates to:
  /// **'Dapur'**
  String get printerSlotKitchen;

  /// No description provided for @printerSlotBar.
  ///
  /// In id, this message translates to:
  /// **'Bar'**
  String get printerSlotBar;

  /// No description provided for @tablesEmptyTerminal.
  ///
  /// In id, this message translates to:
  /// **'Belum ada meja. Tambahkan di back office (Meja).'**
  String get tablesEmptyTerminal;

  /// No description provided for @tableStatus.
  ///
  /// In id, this message translates to:
  /// **'{status, select, available{Kosong} occupied{Terisi} reserved{Dipesan} cleaning{Perlu dibereskan} other{{status}}}'**
  String tableStatus(String status);

  /// No description provided for @tableClear.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan meja'**
  String get tableClear;

  /// No description provided for @tableCleared.
  ///
  /// In id, this message translates to:
  /// **'{table} kosong kembali'**
  String tableCleared(String table);

  /// No description provided for @tableFinishCurrent.
  ///
  /// In id, this message translates to:
  /// **'Tahan atau selesaikan bill yang sedang dibuka dulu.'**
  String get tableFinishCurrent;

  /// No description provided for @tableOccupiedElsewhere.
  ///
  /// In id, this message translates to:
  /// **'{table} punya bill di terminal lain.'**
  String tableOccupiedElsewhere(String table);

  /// No description provided for @tableGuests.
  ///
  /// In id, this message translates to:
  /// **'Jumlah tamu'**
  String get tableGuests;

  /// No description provided for @tableGuestsTitle.
  ///
  /// In id, this message translates to:
  /// **'Tamu di {table}'**
  String tableGuestsTitle(String table);

  /// No description provided for @tableSeat.
  ///
  /// In id, this message translates to:
  /// **'Mulai bill'**
  String get tableSeat;

  /// No description provided for @navGatewayPayments.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran QRIS'**
  String get navGatewayPayments;

  /// No description provided for @payQrisCreate.
  ///
  /// In id, this message translates to:
  /// **'Buat QR'**
  String get payQrisCreate;

  /// No description provided for @qrisTitle.
  ///
  /// In id, this message translates to:
  /// **'QRIS {amount}'**
  String qrisTitle(String amount);

  /// No description provided for @qrisScan.
  ///
  /// In id, this message translates to:
  /// **'Minta pelanggan memindai dengan aplikasi QRIS apa saja.'**
  String get qrisScan;

  /// No description provided for @qrisExpiresIn.
  ///
  /// In id, this message translates to:
  /// **'Berlaku {time}'**
  String qrisExpiresIn(String time);

  /// No description provided for @qrisPaid.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran QRIS diterima: {amount}'**
  String qrisPaid(String amount);

  /// No description provided for @qrisExpired.
  ///
  /// In id, this message translates to:
  /// **'QR kedaluwarsa. Tidak ada yang ditagih.'**
  String get qrisExpired;

  /// No description provided for @qrisCancelled.
  ///
  /// In id, this message translates to:
  /// **'QR dibatalkan.'**
  String get qrisCancelled;

  /// No description provided for @qrisFailed.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran gagal.'**
  String get qrisFailed;

  /// No description provided for @qrisNewQr.
  ///
  /// In id, this message translates to:
  /// **'QR baru'**
  String get qrisNewQr;

  /// No description provided for @qrisCancel.
  ///
  /// In id, this message translates to:
  /// **'Batalkan QR'**
  String get qrisCancel;

  /// No description provided for @qrisOffline.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada koneksi. QRIS dinamis butuh internet; pakai tunai atau stiker QRIS.'**
  String get qrisOffline;

  /// No description provided for @qrisNotConfigured.
  ///
  /// In id, this message translates to:
  /// **'Payment gateway belum diatur.'**
  String get qrisNotConfigured;

  /// No description provided for @qrisError.
  ///
  /// In id, this message translates to:
  /// **'Gagal membuat QR ({code}).'**
  String qrisError(String code);

  /// No description provided for @sellClearPaidQris.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran QRIS untuk bill ini sudah diterima. Selesaikan penjualannya.'**
  String get sellClearPaidQris;

  /// No description provided for @gatewayOnlyUnmatched.
  ///
  /// In id, this message translates to:
  /// **'Dibayar tanpa penjualan'**
  String get gatewayOnlyUnmatched;

  /// No description provided for @gatewayPaidTotal.
  ///
  /// In id, this message translates to:
  /// **'Dibayar {amount} ({count})'**
  String gatewayPaidTotal(String amount, int count);

  /// No description provided for @gatewayUnmatchedTotal.
  ///
  /// In id, this message translates to:
  /// **'Tanpa penjualan {amount} ({count})'**
  String gatewayUnmatchedTotal(String amount, int count);

  /// No description provided for @gatewayUnmatchedHint.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan sudah membayar tetapi tidak ada penjualan (bill tidak diselesaikan). Selesaikan bill di terminal, atau kembalikan dana dari dashboard Midtrans.'**
  String get gatewayUnmatchedHint;

  /// No description provided for @gatewayEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pembayaran QRIS pada periode ini.'**
  String get gatewayEmpty;

  /// No description provided for @gatewayUnmatched.
  ///
  /// In id, this message translates to:
  /// **'Dibayar, tanpa penjualan'**
  String get gatewayUnmatched;

  /// No description provided for @gatewayStatus.
  ///
  /// In id, this message translates to:
  /// **'{status, select, pending{Menunggu} paid{Dibayar} failed{Gagal} expired{Kedaluwarsa} cancelled{Dibatalkan} other{{status}}}'**
  String gatewayStatus(String status);

  /// No description provided for @navRegister.
  ///
  /// In id, this message translates to:
  /// **'Kasir & Pembayaran'**
  String get navRegister;

  /// No description provided for @navRegisterShort.
  ///
  /// In id, this message translates to:
  /// **'Kasir'**
  String get navRegisterShort;

  /// No description provided for @sectionOverview.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan'**
  String get sectionOverview;

  /// No description provided for @sectionCatalog.
  ///
  /// In id, this message translates to:
  /// **'Katalog'**
  String get sectionCatalog;

  /// No description provided for @sectionSales.
  ///
  /// In id, this message translates to:
  /// **'Penjualan'**
  String get sectionSales;

  /// No description provided for @sectionMembers.
  ///
  /// In id, this message translates to:
  /// **'Member'**
  String get sectionMembers;

  /// No description provided for @sectionSettings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get sectionSettings;

  /// No description provided for @shellRetailPos.
  ///
  /// In id, this message translates to:
  /// **'POS Ritel'**
  String get shellRetailPos;

  /// No description provided for @shellTagline.
  ///
  /// In id, this message translates to:
  /// **'Kasir Ritel'**
  String get shellTagline;

  /// No description provided for @shellHeldOrders.
  ///
  /// In id, this message translates to:
  /// **'Pesanan ditahan'**
  String get shellHeldOrders;

  /// No description provided for @shellKitchen.
  ///
  /// In id, this message translates to:
  /// **'Dapur'**
  String get shellKitchen;

  /// No description provided for @shellLock.
  ///
  /// In id, this message translates to:
  /// **'Kunci'**
  String get shellLock;

  /// No description provided for @shellCollapse.
  ///
  /// In id, this message translates to:
  /// **'Ciutkan menu'**
  String get shellCollapse;

  /// No description provided for @shellExpand.
  ///
  /// In id, this message translates to:
  /// **'Lebarkan menu'**
  String get shellExpand;

  /// No description provided for @shellMore.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get shellMore;

  /// No description provided for @shellSearchHint.
  ///
  /// In id, this message translates to:
  /// **'Pindai barcode atau cari SKU / barang'**
  String get shellSearchHint;

  /// No description provided for @sellItemsTitle.
  ///
  /// In id, this message translates to:
  /// **'Barang dagangan'**
  String get sellItemsTitle;

  /// No description provided for @sellItemsCount.
  ///
  /// In id, this message translates to:
  /// **'{count} barang'**
  String sellItemsCount(int count);

  /// No description provided for @sellStockBadge.
  ///
  /// In id, this message translates to:
  /// **'Stok {qty}'**
  String sellStockBadge(String qty);

  /// No description provided for @sellPriceLabel.
  ///
  /// In id, this message translates to:
  /// **'Harga'**
  String get sellPriceLabel;

  /// No description provided for @sellAddTooltip.
  ///
  /// In id, this message translates to:
  /// **'Tambah ke tagihan'**
  String get sellAddTooltip;

  /// No description provided for @cartTitle.
  ///
  /// In id, this message translates to:
  /// **'Tiket aktif'**
  String get cartTitle;

  /// No description provided for @cartWalkIn.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan umum'**
  String get cartWalkIn;

  /// No description provided for @cartTotalDue.
  ///
  /// In id, this message translates to:
  /// **'Total tagihan'**
  String get cartTotalDue;

  /// No description provided for @cartQuickCash.
  ///
  /// In id, this message translates to:
  /// **'Uang cepat:'**
  String get cartQuickCash;

  /// No description provided for @cartExact.
  ///
  /// In id, this message translates to:
  /// **'Uang pas'**
  String get cartExact;

  /// No description provided for @cartPaymentMethod.
  ///
  /// In id, this message translates to:
  /// **'Metode pembayaran'**
  String get cartPaymentMethod;

  /// No description provided for @cartChange.
  ///
  /// In id, this message translates to:
  /// **'Ganti'**
  String get cartChange;

  /// No description provided for @commonRemove.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get commonRemove;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
