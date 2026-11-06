// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CashierA';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String commonError(String message) {
    return 'Something went wrong: $message';
  }

  @override
  String get setupTitle => 'Setup incomplete';

  @override
  String get setupBody =>
      'Run the app with --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=... to connect it to the server.';

  @override
  String get welcomeTitle => 'Welcome to CashierA';

  @override
  String get welcomeSubtitle => 'Choose how this device will be used.';

  @override
  String get welcomePairTerminal => 'Pair a cashier terminal';

  @override
  String get welcomePairTerminalHint =>
      'For the tablet or PC in a store. Ask a manager for a code.';

  @override
  String get welcomeBackOffice => 'Sign in to the back office';

  @override
  String get welcomeBackOfficeHint =>
      'For owners and managers: reports, products, staff.';

  @override
  String get pairTitle => 'Pair terminal';

  @override
  String get pairBody =>
      'Enter the 8-character code a manager created in the back office. Codes are valid for 15 minutes.';

  @override
  String get pairCodeLabel => 'Pairing code';

  @override
  String get pairButton => 'Pair';

  @override
  String get pairInvalidCode => 'Codes are 8 letters/digits (no O, 0, I or 1).';

  @override
  String pairSuccess(String code, String store) {
    return 'Terminal $code is paired to $store.';
  }

  @override
  String get lockTitle => 'Who is on duty?';

  @override
  String lockEnterPin(String name) {
    return 'PIN for $name';
  }

  @override
  String get lockNoStaff =>
      'No staff list yet. Connect to the internet and refresh.';

  @override
  String get lockRefreshStaff => 'Refresh staff list';

  @override
  String get lockStaffRefreshed => 'Staff list refreshed.';

  @override
  String pinWrong(int count) {
    return 'Wrong PIN. $count attempts left.';
  }

  @override
  String pinLocked(String time) {
    return 'Too many attempts. Try again at $time.';
  }

  @override
  String get pinNoPin =>
      'No PIN yet. Ask a manager to set one in the back office.';

  @override
  String get pinTooShort => 'PINs have at least 4 digits.';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusOffline => 'Offline';

  @override
  String statusPending(int count) {
    return '$count pending';
  }

  @override
  String get posTitle => 'Cashier';

  @override
  String posOnDuty(String name) {
    return 'On duty: $name';
  }

  @override
  String posTerminal(String code) {
    return 'Terminal $code';
  }

  @override
  String get posLock => 'Lock / switch cashier';

  @override
  String get posOpenSync => 'Sync status';

  @override
  String get posStoreSettings => 'Store settings';

  @override
  String posTaxLine(String tax, String rate, String mode) {
    return '$tax $rate% · $mode';
  }

  @override
  String get posTaxInclusive => 'included in price';

  @override
  String get posTaxExclusive => 'added on top';

  @override
  String posPaper(int mm) {
    return '$mm mm receipts';
  }

  @override
  String get syncTitle => 'Sync';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncEmpty => 'Everything has been sent to the server.';

  @override
  String get syncStatusPending => 'Waiting';

  @override
  String get syncStatusSyncing => 'Sending';

  @override
  String get syncStatusFailed => 'Failed';

  @override
  String get syncStatusDone => 'Sent';

  @override
  String syncAttempts(int count) {
    return 'Attempts: $count';
  }

  @override
  String get syncRetried => 'Scheduled again.';

  @override
  String syncRunResult(int sent, int failed) {
    return '$sent sent, $failed failed';
  }

  @override
  String get syncOfflineNow => 'Server unreachable. Retrying automatically.';

  @override
  String get adminSignInTitle => 'Back office sign-in';

  @override
  String get adminEmail => 'Email';

  @override
  String get adminPassword => 'Password';

  @override
  String get adminSignIn => 'Sign in';

  @override
  String get adminEmailInvalid => 'Enter a valid email address.';

  @override
  String get adminPasswordShort => 'Passwords have at least 8 characters.';

  @override
  String get adminNotStaff => 'This account is not registered as an employee.';

  @override
  String get adminTitle => 'Back office';

  @override
  String get adminSignOut => 'Sign out';

  @override
  String adminRole(String role, int stores) {
    return '$role · $stores stores';
  }

  @override
  String get adminStores => 'Stores';

  @override
  String get adminNoStores => 'You don\'t have access to any store yet.';

  @override
  String get adminPairTerminal => 'Create pairing code';

  @override
  String get adminDeviceName => 'Terminal name';

  @override
  String get adminDeviceNameHint => 'e.g. Cashier 2';

  @override
  String get adminCreateCode => 'Create code';

  @override
  String get adminCodeTitle => 'Pairing code';

  @override
  String adminCodeBody(String time) {
    return 'Type this code on the new terminal before $time.';
  }

  @override
  String get posCatalog => 'Products & stock';

  @override
  String get posCatalogHint =>
      'Find products, check stock, record stock in/out';

  @override
  String get catalogTitle => 'Products & stock';

  @override
  String get catalogSearchHint => 'Search name, SKU or scan a barcode';

  @override
  String get catalogAll => 'All';

  @override
  String get catalogEmpty =>
      'No catalog on this terminal yet. Sync while online.';

  @override
  String get catalogNoMatch => 'No matching products.';

  @override
  String get catalogRefresh => 'Sync catalog';

  @override
  String catalogLastSync(String time) {
    return 'Last synced $time';
  }

  @override
  String catalogStock(String qty, String unit) {
    return 'Stock $qty $unit';
  }

  @override
  String get catalogLow => 'Low stock';

  @override
  String catalogCodeNotFound(String code) {
    return 'Code $code not found.';
  }

  @override
  String catalogSynced(int rows) {
    return 'Catalog updated ($rows changes).';
  }

  @override
  String get stockIn => 'Stock in';

  @override
  String get stockOut => 'Stock out';

  @override
  String get stockQuantity => 'Quantity';

  @override
  String get stockReason => 'Reason';

  @override
  String get stockNote => 'Note (optional)';

  @override
  String get reasonStockIn => 'Goods received';

  @override
  String get reasonStockOut => 'Goods out';

  @override
  String get reasonDamaged => 'Damaged';

  @override
  String get reasonExpired => 'Expired';

  @override
  String get reasonLost => 'Lost';

  @override
  String get stockSave => 'Save';

  @override
  String stockSaved(String name) {
    return 'Stock of $name updated.';
  }

  @override
  String get stockInvalidQty => 'Enter a quantity above 0 (max 3 decimals).';

  @override
  String get stockWholeOnly => 'This unit needs a whole number.';

  @override
  String get opnameTitle => 'Stock count';

  @override
  String get opnameHint =>
      'Enter counted quantities. Empty rows are left unchanged.';

  @override
  String opnameSubmit(int count) {
    return 'Submit count ($count items)';
  }

  @override
  String opnameConfirm(int count) {
    return 'Stock of $count items will be replaced by the counted quantities. Continue?';
  }

  @override
  String get opnameDone => 'Count saved and queued for sync.';

  @override
  String opnameSystem(String qty) {
    return 'System: $qty';
  }

  @override
  String get commonContinue => 'Continue';

  @override
  String get navHome => 'Overview';

  @override
  String get navProducts => 'Products';

  @override
  String get navCategories => 'Categories';

  @override
  String get navSuppliers => 'Suppliers';

  @override
  String get navStock => 'Stock';

  @override
  String get navImport => 'Import & export';

  @override
  String get commonSave => 'Save';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonSaved => 'Saved.';

  @override
  String get commonActive => 'Active';

  @override
  String get commonInactive => 'Inactive';

  @override
  String get commonRequired => 'Required';

  @override
  String get productsNew => 'New product';

  @override
  String get productsEmpty => 'No products yet. Add one or import a file.';

  @override
  String productsVariants(int count) {
    return '$count variants';
  }

  @override
  String get productsAllCategories => 'All categories';

  @override
  String get productsReadOnly => 'Only owners can change the catalog.';

  @override
  String get productEditTitle => 'Edit product';

  @override
  String get productNewTitle => 'New product';

  @override
  String get productName => 'Product name';

  @override
  String get productCategory => 'Category';

  @override
  String get productUnit => 'Unit';

  @override
  String get productTaxable => 'Charge PPN';

  @override
  String get productTaxableHint =>
      'Turn off for PPN-exempt goods (rice, sugar, eggs ...)';

  @override
  String get productTrackStock => 'Track stock';

  @override
  String get productVariants => 'Variants';

  @override
  String get productAddVariant => 'Add variant';

  @override
  String get variantName => 'Variant name';

  @override
  String get variantSku => 'SKU';

  @override
  String get variantBarcode => 'Barcode';

  @override
  String get variantPrice => 'Price';

  @override
  String get variantCost => 'Cost';

  @override
  String get variantRemove => 'Remove variant';

  @override
  String get productStoreSettings => 'Per-store price and minimum stock';

  @override
  String get storePriceOverride => 'Store price';

  @override
  String get storeReorderPoint => 'Minimum stock';

  @override
  String get validationMoney => 'Whole rupiah without dots, e.g. 25000';

  @override
  String get validationSku => 'Letters/digits . _ - (max 40)';

  @override
  String get categoriesEmpty => 'No categories yet.';

  @override
  String get categoryName => 'Category name';

  @override
  String get categoryColor => 'Color (#RRGGBB)';

  @override
  String get categoryOrderHint =>
      'Drag to set the order on the cashier screen.';

  @override
  String get suppliersEmpty => 'No suppliers yet.';

  @override
  String get supplierName => 'Supplier name';

  @override
  String get supplierContact => 'Contact';

  @override
  String get supplierPhone => 'Phone';

  @override
  String get supplierEmail => 'Email';

  @override
  String get supplierAddress => 'Address';

  @override
  String get stockStore => 'Store';

  @override
  String get stockLowOnly => 'Low stock only';

  @override
  String get stockEmpty => 'No stock-tracked products yet.';

  @override
  String stockReorder(String qty) {
    return 'Min. $qty';
  }

  @override
  String stockAlerts(int count) {
    return '$count open alerts';
  }

  @override
  String get stockResolve => 'Resolve';

  @override
  String get stockMovements => 'Movement history';

  @override
  String get stockNoMovements => 'No movements yet.';

  @override
  String get movementType_initial => 'Opening stock';

  @override
  String get movementType_sale => 'Sale';

  @override
  String get movementType_sale_void => 'Sale voided';

  @override
  String get movementType_refund => 'Refund';

  @override
  String get movementType_purchase_receive => 'Goods received';

  @override
  String get movementType_adjustment => 'Adjustment';

  @override
  String get movementType_waste => 'Damaged/lost';

  @override
  String get movementType_opname => 'Stock count';

  @override
  String get movementType_transfer_out => 'Transfer out';

  @override
  String get movementType_transfer_in => 'Transfer in';

  @override
  String get importTitle => 'Catalog import & export';

  @override
  String get importHelp =>
      'Fill in the template and upload it as CSV or XLSX. stock_<CODE> columns set the counted stock in that store.';

  @override
  String get importDownloadTemplate => 'Download template';

  @override
  String get importExportCsv => 'Export CSV';

  @override
  String get importExportXlsx => 'Export XLSX';

  @override
  String get importPick => 'Choose file';

  @override
  String importRun(int count) {
    return 'Import $count rows';
  }

  @override
  String importPreview(int rows, int products) {
    return '$rows rows · $products products';
  }

  @override
  String importIssues(int count) {
    return '$count problems to fix first';
  }

  @override
  String importDone(int created, int updated, int stock) {
    return 'Import done: $created new variants, $updated updated, $stock stock lines.';
  }

  @override
  String importFileError(String message) {
    return 'Could not read the file: $message';
  }

  @override
  String get importSaved => 'File saved.';

  @override
  String importRowLabel(int row) {
    return 'Row $row';
  }

  @override
  String get importFileLevel => 'File';

  @override
  String get issue_emptyFile => 'The file is empty.';

  @override
  String issue_missingColumn(String column) {
    return 'Column $column is missing.';
  }

  @override
  String issue_unknownStore(String column) {
    return 'Column $column: unknown store code.';
  }

  @override
  String get issue_tooManyRows => 'At most 5,000 rows per import.';

  @override
  String issue_requiredValue(String column) {
    return '$column is required.';
  }

  @override
  String issue_skuFormat(String value) {
    return 'SKU \"$value\" may only use letters, digits, . _ -';
  }

  @override
  String issue_barcodeFormat(String value) {
    return 'Barcode \"$value\" is not valid.';
  }

  @override
  String issue_priceFormat(String column, String value) {
    return '$column \"$value\": digits only, e.g. 25000 (no Rp or dots).';
  }

  @override
  String issue_quantityFormat(String column, String value) {
    return '$column \"$value\" is not a valid quantity (max 3 decimals, not negative).';
  }

  @override
  String issue_booleanFormat(String column, String value) {
    return '$column \"$value\": use yes/no.';
  }

  @override
  String issue_unknownUnit(String value) {
    return 'Unknown unit \"$value\".';
  }

  @override
  String issue_duplicateSku(String value) {
    return 'SKU \"$value\" appears more than once.';
  }

  @override
  String issue_duplicateBarcode(String value) {
    return 'Barcode \"$value\" appears more than once.';
  }

  @override
  String issue_productMismatch(String value) {
    return '\"$value\": category, unit, PPN or stock tracking differs from an earlier row.';
  }

  @override
  String productSaveFailed(String message) {
    return 'Could not save: $message';
  }

  @override
  String get commonNone => 'None';

  @override
  String get posSell => 'Cashier';

  @override
  String get posSellHint =>
      'Scan or pick items, take payment, print the receipt';

  @override
  String get sellTitle => 'Cashier';

  @override
  String get sellFavorites => 'Favorites';

  @override
  String sellNotFound(String code) {
    return 'No item with code \"$code\".';
  }

  @override
  String get sellUnavailable => 'Not sold here';

  @override
  String sellCartSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0 · $total';
  }

  @override
  String get sellPay => 'Pay';

  @override
  String sellPayAmount(String amount) {
    return 'Pay $amount';
  }

  @override
  String get sellNewBill => 'New bill';

  @override
  String get sellClear => 'Clear';

  @override
  String get sellClearTitle => 'Clear this bill?';

  @override
  String get sellClearHint => 'Every item on this bill will be removed.';

  @override
  String get sellClearHeldHint =>
      'Changes since it was held are dropped. The bill stays on the Held list.';

  @override
  String get sellAddCustomer => 'Add customer';

  @override
  String get sellEmpty => 'No items yet. Scan a barcode or tap a product.';

  @override
  String get sellChangeQuantity => 'Change quantity';

  @override
  String get sellLineDiscount => 'Item discount';

  @override
  String get sellBillDiscount => 'Bill discount';

  @override
  String get sellNote => 'Note';

  @override
  String get sellRemove => 'Remove';

  @override
  String get sellItemDiscounts => 'Item discounts';

  @override
  String sellTaxIncluded(String tax) {
    return '$tax included';
  }

  @override
  String get sellNeedsApproval => 'Discount above the limit: approval needed';

  @override
  String get sellDiscount => 'Discount';

  @override
  String get sellHold => 'Hold';

  @override
  String sellHeld(String number) {
    return 'Bill $number is on hold.';
  }

  @override
  String get discountManualLine => 'Discount';

  @override
  String get discountManualBill => 'Bill discount';

  @override
  String get discountVoucher => 'Voucher';

  @override
  String get discountPoints => 'Points redeemed';

  @override
  String get discountPercent => 'Percent';

  @override
  String get discountAmount => 'Rupiah';

  @override
  String get discountValue => 'Discount';

  @override
  String get discountInvalid => 'Enter 0.01–100 percent or rupiah above 0.';

  @override
  String get discountRemove => 'Remove discount';

  @override
  String get voucherTitle => 'Voucher';

  @override
  String get voucherCode => 'Voucher code';

  @override
  String get voucherCodeShort => 'Codes have at least 3 characters.';

  @override
  String voucherUnknown(String code) {
    return 'Unknown voucher $code.';
  }

  @override
  String get voucherInactive => 'This voucher is no longer active.';

  @override
  String get voucherNotStarted => 'This voucher is not valid yet.';

  @override
  String get voucherExpired => 'This voucher has expired.';

  @override
  String get voucherUsedUp => 'This voucher has been used up.';

  @override
  String get voucherBelowMinimum => 'The bill is below the voucher minimum.';

  @override
  String modifierRequired(int count) {
    return 'choose $count';
  }

  @override
  String modifierOptional(int count) {
    return 'optional, up to $count';
  }

  @override
  String modifierAdd(String price) {
    return 'Add · $price';
  }

  @override
  String get approvalTitle => 'Approval';

  @override
  String approvalDiscountReason(String percent, String limit) {
    return 'A $percent% discount is above the $limit% limit.';
  }

  @override
  String approvalCancelReason(String number) {
    return 'Cancelling bill $number.';
  }

  @override
  String get approvalNobody => 'Nobody at this store may approve this.';

  @override
  String approvalEnterPin(String name) {
    return '$name, enter your PIN.';
  }

  @override
  String get approvalLocked => 'PIN locked for 5 minutes after too many tries.';

  @override
  String get approvalNoPin => 'This person has no PIN yet.';

  @override
  String get approvalOther => 'Someone else';

  @override
  String get customerAdd => 'New customer';

  @override
  String get customerName => 'Name';

  @override
  String get customerPhone => 'Phone (optional)';

  @override
  String get customerPhoneInvalid => 'Phone numbers have 8–15 digits.';

  @override
  String get customerSearchHint => 'Search name or phone';

  @override
  String get customerNoPermission => 'You may not add customers.';

  @override
  String get shiftOpenTitle => 'Open the shift';

  @override
  String get shiftOpenHint =>
      'Count the cash in the drawer and enter the opening cash.';

  @override
  String get shiftOpeningCash => 'Opening cash';

  @override
  String get shiftOpen => 'Open shift';

  @override
  String get shiftNoPermission =>
      'Ask a manager or an authorised cashier to open the shift.';

  @override
  String payTitle(String number) {
    return 'Payment $number';
  }

  @override
  String get payDue => 'Amount due';

  @override
  String payCustomer(String name) {
    return 'Customer: $name';
  }

  @override
  String payRemaining(String amount) {
    return '$amount left to pay';
  }

  @override
  String payChange(String amount) {
    return 'Change $amount';
  }

  @override
  String payKasbonNote(String amount, int days) {
    return 'Kasbon $amount, due in $days days.';
  }

  @override
  String get payFinish => 'Complete sale';

  @override
  String get payMethod => 'Payment method';

  @override
  String get payQuickCash => 'Cash received';

  @override
  String get payExact => 'Exact';

  @override
  String get payTendered => 'Cash received';

  @override
  String get payAmount => 'Amount';

  @override
  String get payReference => 'Reference / approval code';

  @override
  String get payReferenceOptional => 'Reference (optional)';

  @override
  String payReferenceRequired(String method) {
    return '$method needs a reference number.';
  }

  @override
  String payAdd(String method) {
    return 'Add $method';
  }

  @override
  String get payInvalidAmount => 'Enter an amount above 0.';

  @override
  String get payNonCashTooMuch =>
      'Non-cash payments exceed the bill. Only cash gives change.';

  @override
  String get payOneKasbon => 'Only one kasbon per bill.';

  @override
  String get payUnneeded =>
      'This cash is not needed; the bill is already covered.';

  @override
  String get payShiftRequired => 'Open the shift before completing a sale.';

  @override
  String get payNotPaid => 'Payments do not match the bill yet.';

  @override
  String get payKasbonCustomer => 'Kasbon needs a customer.';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get receiptCashier => 'Cashier';

  @override
  String get receiptCustomer => 'Customer';

  @override
  String get receiptSubtotal => 'Subtotal';

  @override
  String get receiptService => 'Service charge';

  @override
  String receiptTaxIncluded(String tax, String rate) {
    return '$tax $rate included';
  }

  @override
  String receiptTaxAdded(String tax, String rate) {
    return '$tax $rate';
  }

  @override
  String get receiptTaxBase => 'Tax base (DPP)';

  @override
  String get receiptRounding => 'Rounding';

  @override
  String get receiptTotal => 'Total';

  @override
  String get receiptChange => 'Change';

  @override
  String get receiptTendered => 'Received';

  @override
  String receiptKasbonDue(String date) {
    return 'Kasbon due $date';
  }

  @override
  String get receiptCancelled => 'CANCELLED';

  @override
  String get receiptHeld => 'NOT PAID';

  @override
  String receiptItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get receiptShare => 'Share PDF';

  @override
  String get receiptPrint => 'Print';

  @override
  String get receiptReprint => 'Reprint';

  @override
  String get receiptNewSale => 'New sale';

  @override
  String get receiptMissing => 'This receipt is not on this terminal.';

  @override
  String get ordersTitle => 'Sales';

  @override
  String get ordersToday => 'Today';

  @override
  String ordersHeld(int count) {
    return 'Held ($count)';
  }

  @override
  String get ordersTodayTotal => 'Sales today';

  @override
  String ordersTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paid sales',
      one: '1 paid sale',
    );
    return '$_temp0 on this terminal';
  }

  @override
  String get ordersNone => 'No sales yet today.';

  @override
  String get ordersNoHeld => 'No bills on hold.';

  @override
  String get ordersStatusHeld => 'Held';

  @override
  String get ordersStatusCancelled => 'Cancelled';

  @override
  String get ordersStatusPaid => 'Paid';

  @override
  String get ordersResumeTitle => 'Resume this bill?';

  @override
  String get ordersResumeReplace =>
      'The bill on screen will be cleared. Hold it first if you still need it.';

  @override
  String get ordersCancel => 'Cancel bill';

  @override
  String ordersCancelTitle(String number) {
    return 'Cancel $number?';
  }

  @override
  String get ordersCancelReason => 'Reason';

  @override
  String get ordersCancelReasonShort => 'Give a reason of at least 3 letters.';

  @override
  String ordersCancelled(String number) {
    return 'Bill $number cancelled.';
  }

  @override
  String get commonDone => 'Done';

  @override
  String get commonSearch => 'Search';

  @override
  String get navPromotions => 'Promotions';

  @override
  String get navVouchers => 'Vouchers';

  @override
  String get navSettings => 'Store settings';

  @override
  String get promosEmpty => 'No promotions yet.';

  @override
  String get promoMissing => 'This promotion was not found.';

  @override
  String get promoNew => 'New promotion';

  @override
  String get promoGeneral => 'General';

  @override
  String get promoName => 'Promotion name';

  @override
  String get promoDescription => 'Description';

  @override
  String get promoType => 'Promotion type';

  @override
  String get promoTypeHappyHour => 'Happy hour';

  @override
  String get promoTypeBuyXGetY => 'Buy X get Y';

  @override
  String get promoTypeBundle => 'Bundle price';

  @override
  String get promoTypeTiered => 'Quantity tiers';

  @override
  String get promoTypeMinPurchase => 'Minimum purchase';

  @override
  String get promoPriority => 'Priority';

  @override
  String get promoPriorityHint => 'Lower numbers run first.';

  @override
  String get promoStackable => 'Stackable';

  @override
  String get promoStackableHint =>
      'When off, items that already have a promotion are skipped, and later promotions do not apply to the items this one discounts.';

  @override
  String get promoRules => 'Rules';

  @override
  String get promoScope => 'Applies to';

  @override
  String get promoScopeAll => 'All products';

  @override
  String get promoScopeCategories => 'Categories';

  @override
  String get promoScopeProducts => 'Products';

  @override
  String get promoScopeVariants => 'Variants (SKU)';

  @override
  String get promoDiscountPerUnit => 'Discount (Rp per unit)';

  @override
  String get promoBuyScope => 'Buy items';

  @override
  String get promoBuyQuantity => 'Buy quantity';

  @override
  String get promoGetScope => 'Get items';

  @override
  String get promoGetQuantity => 'Get quantity';

  @override
  String get promoGetDiscount => 'Discount on the items got (100% = free)';

  @override
  String get promoMaxApplications => 'Max uses per bill';

  @override
  String get promoUnlimitedHint => 'Leave empty for no limit';

  @override
  String promoComponent(int index) {
    return 'Bundle item $index';
  }

  @override
  String get promoQty => 'Quantity';

  @override
  String get promoAddComponent => 'Add bundle item';

  @override
  String get promoBundlePrice => 'Bundle price';

  @override
  String get promoMinQuantity => 'From quantity';

  @override
  String get promoAddTier => 'Add tier';

  @override
  String get promoMinSubtotal => 'Minimum spend';

  @override
  String get promoBillDiscount => 'Bill discount';

  @override
  String get promoWhen => 'When';

  @override
  String get promoStartsAnytime => 'Starts: any time';

  @override
  String promoStarts(String date) {
    return 'Starts $date';
  }

  @override
  String get promoEndsNever => 'Ends: never';

  @override
  String promoEnds(String date) {
    return 'Until $date';
  }

  @override
  String get promoClearPeriod => 'Clear dates';

  @override
  String get promoDays => 'Days (none = every day)';

  @override
  String get promoEveryDay => 'Every day.';

  @override
  String get promoHours => 'Hours';

  @override
  String get promoAllDay => 'All day';

  @override
  String get promoStores => 'Stores';

  @override
  String get promoAllStores => 'None selected: valid in every store.';

  @override
  String promoStoreCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stores',
      one: '1 store',
    );
    return '$_temp0';
  }

  @override
  String get promoPeriodInvalid => 'The end date must be after the start date.';

  @override
  String get promoProblemName => 'Enter a promotion name.';

  @override
  String get promoProblemWindow =>
      'Set both a start and an end time, or neither.';

  @override
  String get promoProblemHappyHour =>
      'Happy hour needs a start and an end time.';

  @override
  String get promoProblemScope => 'Choose which items it applies to.';

  @override
  String get promoProblemQuantity =>
      'Quantities must be whole numbers above 0.';

  @override
  String get promoProblemComponents => 'A bundle needs at least 2 items.';

  @override
  String get promoProblemTiers =>
      'Tier quantities must go up, starting from 1.';

  @override
  String promoSummaryDiscount(String discount) {
    return '$discount off';
  }

  @override
  String promoSummaryBuyGet(int buy, int get, String discount) {
    return 'buy $buy get $get at $discount off';
  }

  @override
  String promoSummaryBundle(int count, String price) {
    return '$count items for $price';
  }

  @override
  String promoSummaryMinPurchase(String min, String discount) {
    return 'spend $min, save $discount';
  }

  @override
  String get vouchersEmpty => 'No vouchers yet.';

  @override
  String get voucherNew => 'New voucher';

  @override
  String get voucherCodeHint => '3–32 capital letters, digits, - or _';

  @override
  String voucherMinSubtotal(String amount) {
    return 'min. $amount';
  }

  @override
  String voucherMaxDiscount(String amount) {
    return 'max. $amount';
  }

  @override
  String voucherUsed(int used, String max) {
    return 'used $used/$max';
  }

  @override
  String voucherUntil(String date) {
    return 'until $date';
  }

  @override
  String get voucherMaxDiscountLabel => 'Maximum discount (optional)';

  @override
  String get voucherMinSubtotalLabel => 'Minimum spend (optional)';

  @override
  String get voucherMaxUses => 'Total uses (optional)';

  @override
  String get voucherPerCustomer => 'Per customer (optional)';

  @override
  String get voucherCountInvalid => 'A whole number above 0.';

  @override
  String get settingsTax => 'Tax';

  @override
  String get settingsTaxEnabled => 'Charge tax';

  @override
  String get settingsTaxName => 'Tax name';

  @override
  String get settingsRate => 'Rate';

  @override
  String get settingsTaxInclusive => 'Prices include tax';

  @override
  String get settingsTaxInclusiveHint =>
      'Rp 25.000 with 11% PPN contains Rp 2.477 PPN.';

  @override
  String get settingsTaxExclusiveHint => 'Tax is added on top of prices.';

  @override
  String get settingsServiceCharge => 'Service charge';

  @override
  String get settingsServiceChargeEnabled => 'Charge a service charge';

  @override
  String get settingsServiceChargeTaxable => 'Service charge is taxed';

  @override
  String get settingsCashier => 'Cashier';

  @override
  String get settingsRounding => 'Round the total';

  @override
  String get settingsRoundingNone => 'No rounding';

  @override
  String get settingsRoundingNearest => 'Nearest';

  @override
  String get settingsRoundingUp => 'Up';

  @override
  String get settingsRoundingDown => 'Down';

  @override
  String get settingsRoundingUnit => 'To the nearest';

  @override
  String get settingsDiscountLimit => 'Discount limit without approval';

  @override
  String get settingsDiscountLimitHint =>
      'Manual discounts above this need a manager PIN.';

  @override
  String get settingsKasbon => 'Allow kasbon';

  @override
  String get settingsReceipt => 'Receipt';

  @override
  String get settingsReceiptHeader => 'Receipt header';

  @override
  String get settingsReceiptFooter => 'Receipt footer';

  @override
  String get settingsPaymentMethods => 'Payment methods';

  @override
  String get settingsPaymentMethodsHint =>
      'Methods switched on appear on this store\'s payment screen.';

  @override
  String get settingsNeedsReference => 'needs a reference';

  @override
  String get settingsPercentInvalid => 'Enter 0–100 percent.';

  @override
  String get posShift => 'Shift';

  @override
  String posShiftOpenSince(String time, String name) {
    return 'Open since $time · $name';
  }

  @override
  String get posShiftNone => 'No open shift';

  @override
  String get posPrinter => 'Printer';

  @override
  String get posPrinterNone => 'Not set up';

  @override
  String get shiftTitle => 'Shift';

  @override
  String get shiftNoneOpen =>
      'No shift is open. Open one on the cashier screen.';

  @override
  String get shiftGoSell => 'Go to cashier';

  @override
  String get shiftDrawerExpected => 'Cash that should be in the drawer';

  @override
  String shiftOpenedBy(String time, String name) {
    return 'Opened $time by $name';
  }

  @override
  String get shiftCashIn => 'Cash in';

  @override
  String get shiftCashOut => 'Cash out';

  @override
  String get shiftOpenDrawer => 'Open drawer';

  @override
  String get shiftPrintX => 'Print X';

  @override
  String get shiftClose => 'Close shift';

  @override
  String get shiftMovements => 'Cash in & out';

  @override
  String get shiftNoMovements => 'No cash in or out yet.';

  @override
  String get shiftHistory => 'Earlier shifts';

  @override
  String shiftHistoryLine(String date, String name) {
    return '$date · $name';
  }

  @override
  String get shiftMovementAmount => 'Amount';

  @override
  String get shiftMovementReason => 'Reason';

  @override
  String shiftMovementSaved(String kind, String amount) {
    return '$kind of $amount recorded.';
  }

  @override
  String shiftDrawerShort(String amount) {
    return 'There is only $amount in the drawer.';
  }

  @override
  String get shiftReport => 'Shift report';

  @override
  String get drawerReasonTitle => 'Open the drawer without a sale';

  @override
  String drawerApprovalReason(String reason) {
    return 'Opening the drawer without a sale: $reason';
  }

  @override
  String get drawerOpened => 'Drawer opened.';

  @override
  String get drawerNotSet =>
      'This printer isn\'t set to open the drawer. Change it in the printer settings.';

  @override
  String get closeTitle => 'Close shift';

  @override
  String get closeCountByNotes => 'Count by note';

  @override
  String get closeEnterTotal => 'Enter the total';

  @override
  String get closeCounted => 'Cash counted';

  @override
  String get closeExpected => 'Expected';

  @override
  String get closeDifference => 'Difference';

  @override
  String get closeEven => 'Even';

  @override
  String closeOver(String amount) {
    return '$amount over';
  }

  @override
  String closeShort(String amount) {
    return '$amount short';
  }

  @override
  String get closeNote => 'Note';

  @override
  String get closeNoteRequired => 'Explain the difference.';

  @override
  String closeHeldWarning(int count) {
    return 'Held bills: $count. They stay held after the shift is closed.';
  }

  @override
  String closePending(int count) {
    return 'Not sent yet: $count. They are sent before the shift close.';
  }

  @override
  String get closeConfirmTitle => 'Close the shift now?';

  @override
  String closeConfirmBody(String counted, String expected) {
    return 'Counted $counted, expected $expected. After closing, sales need a new shift.';
  }

  @override
  String get closeDone => 'Shift closed.';

  @override
  String get reportTitleX => 'X report';

  @override
  String get reportTitleZ => 'Z report';

  @override
  String get reportTerminal => 'Terminal';

  @override
  String get reportOpened => 'Opened';

  @override
  String get reportClosed => 'Closed';

  @override
  String get reportSales => 'Sales';

  @override
  String get reportTransactions => 'Transactions';

  @override
  String get reportGross => 'Gross sales';

  @override
  String get reportDiscounts => 'Discounts';

  @override
  String get reportNet => 'Net sales';

  @override
  String get reportService => 'Service charge';

  @override
  String get reportTax => 'Tax';

  @override
  String get reportRounding => 'Rounding';

  @override
  String get reportTotal => 'Total';

  @override
  String get reportAverage => 'Average sale';

  @override
  String get reportPayments => 'Payments';

  @override
  String get reportCorrections => 'Corrections';

  @override
  String get reportVoids => 'Voids';

  @override
  String get reportCancelled => 'Bills cancelled';

  @override
  String get reportRefunds => 'Refunds';

  @override
  String get reportKasbonIssued => 'Kasbon issued';

  @override
  String get reportKasbonRepaid => 'Kasbon repaid';

  @override
  String get reportCash => 'Cash';

  @override
  String get reportOpeningCash => 'Opening cash';

  @override
  String get reportCashSales => 'Cash sales';

  @override
  String get reportVoidedCash => 'Cash voids';

  @override
  String get reportCashRefunds => 'Cash refunds';

  @override
  String get reportKasbonCash => 'Kasbon repaid in cash';

  @override
  String get reportCashIn => 'Cash in';

  @override
  String get reportCashOut => 'Cash out';

  @override
  String get reportExpected => 'Expected cash';

  @override
  String get reportCounted => 'Counted cash';

  @override
  String get reportDifference => 'Difference';

  @override
  String get reportTopItems => 'Top items';

  @override
  String reportPrintedAt(String time) {
    return 'Printed $time';
  }

  @override
  String get reportPrint => 'Print';

  @override
  String get reportShare => 'Share PDF';

  @override
  String get reportMissing => 'Shift not found.';

  @override
  String get receiptVoided => 'VOIDED';

  @override
  String get receiptCopy => 'COPY';

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
    return 'Voided $time by $name: $reason';
  }

  @override
  String get receiptPrinted => 'Receipt sent to the printer.';

  @override
  String voidTitle(String number) {
    return 'Void $number?';
  }

  @override
  String get voidReason => 'Reason for the void';

  @override
  String voidApproval(String number) {
    return 'Void $number.';
  }

  @override
  String voidApprovalPrinted(String number) {
    return 'Void $number after its receipt was printed.';
  }

  @override
  String voidDone(String number) {
    return '$number is voided. The stock is back.';
  }

  @override
  String get reasonShort => 'Write a reason of at least 3 characters.';

  @override
  String printFailed(String reason) {
    return 'Couldn\'t print: $reason';
  }

  @override
  String get printNotConfigured =>
      'No printer set up. Set one up in the printer settings, or share the PDF.';

  @override
  String get printUnsupported =>
      'This printer isn\'t supported on this device.';

  @override
  String get printConnectFailed =>
      'Couldn\'t reach the printer. Check that it\'s on and close by.';

  @override
  String get printSendFailed => 'The data couldn\'t be sent to the printer.';

  @override
  String get printInvalidAddress => 'The printer address is not valid.';

  @override
  String get printSystemDialog => 'Print with the system dialog';

  @override
  String refundTitle(String number) {
    return 'Refund $number';
  }

  @override
  String get refundPickItems => 'Pick the items being returned';

  @override
  String get refundAll => 'All';

  @override
  String refundLeft(String left, String sold) {
    return '$left of $sold left';
  }

  @override
  String get refundRestock => 'Put back in stock';

  @override
  String get refundRestockHint =>
      'Turn off for damaged goods that are thrown away.';

  @override
  String get refundMethod => 'Paid back by';

  @override
  String get refundViaCash => 'Cash';

  @override
  String get refundViaQris => 'QRIS';

  @override
  String get refundViaCard => 'Card';

  @override
  String get refundViaTransfer => 'Transfer';

  @override
  String get refundViaEwallet => 'E-wallet';

  @override
  String get refundReason => 'Reason for the refund';

  @override
  String get refundTotal => 'Refund total';

  @override
  String refundRefundable(String amount) {
    return 'Can be refunded: $amount';
  }

  @override
  String refundSubmit(String amount) {
    return 'Refund $amount';
  }

  @override
  String refundApproval(String amount, String number) {
    return 'Refund of $amount for $number.';
  }

  @override
  String refundDone(String number) {
    return 'Refund $number recorded.';
  }

  @override
  String get refundNothing => 'Pick at least one item.';

  @override
  String get refundExceedsPaid =>
      'That\'s more than was paid. The kasbon part can\'t be refunded.';

  @override
  String get refundZero =>
      'These items were free; there is no money to give back.';

  @override
  String get refundQuantity => 'More than is left to refund.';

  @override
  String get refundFull => 'Everything has been refunded.';

  @override
  String get refundSlipTitle => 'REFUND';

  @override
  String refundSlipOrder(String number) {
    return 'For sale $number';
  }

  @override
  String refundSlipStaff(String name) {
    return 'Cashier: $name';
  }

  @override
  String refundSlipApprover(String name) {
    return 'Approved by: $name';
  }

  @override
  String refundSlipMethod(String method) {
    return 'Paid back by: $method';
  }

  @override
  String refundSlipReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get posErrShiftClosed => 'The shift is already closed.';

  @override
  String get posErrNotCompleted =>
      'Only finished sales can be voided or refunded.';

  @override
  String get posErrVoidAfterRefund => 'A sale with refunds can\'t be voided.';

  @override
  String get posErrRefundMethod => 'Not a valid refund method.';

  @override
  String posErrPermission(String permission) {
    return 'This needs the $permission permission.';
  }

  @override
  String get printerTitle => 'Printer settings';

  @override
  String get printerNone => 'No receipt printer yet.';

  @override
  String get printerConnection => 'Connection';

  @override
  String get printerBluetooth => 'Bluetooth';

  @override
  String get printerUsb => 'USB';

  @override
  String get printerNetwork => 'Network';

  @override
  String get printerSearch => 'Find printers';

  @override
  String get printerSearching => 'Looking for printers…';

  @override
  String get printerFoundNone =>
      'No printers found. Turn on the printer and Bluetooth, then try again.';

  @override
  String get printerName => 'Printer name';

  @override
  String get printerAddress => 'Address';

  @override
  String get printerAddressHint =>
      'For example 192.168.1.50 or 192.168.1.50:9100';

  @override
  String get printerPaper => 'Paper width';

  @override
  String printerPaperMm(int mm) {
    return '$mm mm';
  }

  @override
  String get printerOpensDrawer => 'Open the cash drawer through the printer';

  @override
  String get printerAutoPrint => 'Print the receipt after every sale';

  @override
  String get printerTest => 'Test print';

  @override
  String get printerTestTitle => 'PRINTER TEST';

  @override
  String printerTestLine(int mm, int columns) {
    return '$mm mm paper · $columns columns';
  }

  @override
  String get printerTestSent => 'Test page sent.';

  @override
  String get printerSaved => 'Printer saved.';

  @override
  String get printerRemove => 'Remove printer';

  @override
  String get printerRemoved => 'Printer removed.';

  @override
  String get printerAddressRequired => 'Pick a printer or enter its address.';

  @override
  String get printerDiscoverUnsupported =>
      'Finding printers isn\'t available on this device. Use a network printer.';

  @override
  String get navShifts => 'Shifts';

  @override
  String get navAudit => 'Audit log';

  @override
  String get adminAllStores => 'All stores';

  @override
  String adminPeriod(String from, String to) {
    return '$from – $to';
  }

  @override
  String get shiftsEmpty => 'No shifts in this period.';

  @override
  String get shiftsOpen => 'Still open';

  @override
  String shiftsSales(String amount) {
    return 'Sales $amount';
  }

  @override
  String get auditOnlyApprovals => 'Approvals only';

  @override
  String get auditKind => 'Kind';

  @override
  String get auditAll => 'All';

  @override
  String get auditKindOrders => 'Sales';

  @override
  String get auditKindShifts => 'Shifts';

  @override
  String get auditKindCash => 'Cash';

  @override
  String get auditKindPos => 'Cash drawer';

  @override
  String get auditKindReceipts => 'Receipts';

  @override
  String get auditKindDevices => 'Terminals';

  @override
  String get auditKindData => 'Data changes';

  @override
  String get auditEmpty => 'No entries.';

  @override
  String get auditLoadMore => 'Load more';

  @override
  String auditApprovedBy(String name) {
    return 'approved by $name';
  }

  @override
  String get auditSystem => 'System';

  @override
  String auditActionName(String action) {
    String _temp0 = intl.Intl.selectLogic(action, {
      'shift_opened': 'Shift opened',
      'shift_closed': 'Shift closed',
      'cash_movement_in': 'Cash in',
      'cash_movement_out': 'Cash out',
      'order_voided': 'Sale voided',
      'order_refunded': 'Refund',
      'order_cancelled': 'Bill cancelled',
      'order_discount_approved': 'Discount approved',
      'pos_drawer_open_no_sale': 'Drawer opened without a sale',
      'receipt_reprinted': 'Receipt reprinted',
      'device_paired': 'Terminal paired',
      'device_revoked': 'Terminal revoked',
      'device_pairing_code_created': 'Pairing code created',
      'employee_pin_set': 'PIN set',
      'catalog_imported': 'Catalog imported',
      'kasbon_repayment': 'Kasbon repayment',
      'other': '$action',
    });
    return '$_temp0';
  }

  @override
  String get pointsTitle => 'Redeem points';

  @override
  String pointsBalance(int points) {
    return 'Balance $points points';
  }

  @override
  String pointsMax(int points, String amount) {
    return 'At most $points points ($amount)';
  }

  @override
  String pointsMin(int points) {
    return 'At least $points points';
  }

  @override
  String get pointsField => 'Points';

  @override
  String get pointsAll => 'Max';

  @override
  String get pointsRemove => 'Remove';

  @override
  String get pointsUse => 'Use';

  @override
  String pointsTooMany(int points) {
    return 'At most $points points.';
  }

  @override
  String pointsBelowMin(int points) {
    return 'At least $points points.';
  }

  @override
  String pointsUsed(int points) {
    return '−$points points';
  }

  @override
  String pointsButton(int points) {
    return '$points points';
  }

  @override
  String get posErrPoints => 'Not enough points, or below the minimum.';

  @override
  String get posErrVoidKasbonPaid =>
      'This kasbon has installments; refund instead of voiding.';

  @override
  String receiptPointsEarned(int points) {
    return 'Points earned: $points';
  }

  @override
  String get posCustomers => 'Customers';

  @override
  String get posCustomersHint => 'Points, kasbon and installments';

  @override
  String get customersTitle => 'Customers';

  @override
  String get customersSearch => 'Search name, phone or code';

  @override
  String get customersEmpty => 'No customers.';

  @override
  String customersPoints(int points) {
    return '$points points';
  }

  @override
  String customersOwes(String amount) {
    return 'Owes $amount';
  }

  @override
  String get customerEdit => 'Edit customer';

  @override
  String get customerSaved => 'Customer saved.';

  @override
  String customerTotalOwed(String amount) {
    return 'Kasbon $amount';
  }

  @override
  String get customerPay => 'Pay kasbon';

  @override
  String get customerKasbon => 'Kasbon';

  @override
  String get customerNoKasbon => 'No kasbon.';

  @override
  String customerKasbonLine(String left, String amount) {
    return '$left left of $amount';
  }

  @override
  String customerDue(String date) {
    return 'Due $date';
  }

  @override
  String customerOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days late',
      one: '1 day late',
    );
    return '$_temp0';
  }

  @override
  String get customerInstallments => 'Installments on this terminal';

  @override
  String repayTitle(String name) {
    return 'Kasbon payment from $name';
  }

  @override
  String repayOwed(String amount) {
    return 'Owes $amount';
  }

  @override
  String get repayAmount => 'Amount';

  @override
  String get repayAll => 'Pay all';

  @override
  String get repayMethod => 'Method';

  @override
  String get repayReference => 'Reference';

  @override
  String get repayInvalid => 'Enter an amount.';

  @override
  String get repayNothing => 'Nothing is owed.';

  @override
  String get repayExceeds => 'More than is owed.';

  @override
  String repayDone(String amount, String left) {
    return 'Received $amount. $left is still owed.';
  }

  @override
  String get kasbonSlipTitle => 'KASBON PAYMENT';

  @override
  String kasbonSlipCustomer(String name) {
    return 'Customer: $name';
  }

  @override
  String kasbonSlipCashier(String name) {
    return 'Cashier: $name';
  }

  @override
  String get kasbonSlipBefore => 'Owed before';

  @override
  String get kasbonSlipPaid => 'Paid';

  @override
  String get kasbonSlipAfter => 'Still owed';

  @override
  String kasbonSlipMethod(String method) {
    return 'Method: $method';
  }

  @override
  String get kasbonSlipSettled => 'PAID IN FULL';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navKasbon => 'Kasbon';

  @override
  String get navLoyalty => 'Loyalty & kasbon';

  @override
  String ledgerEntryType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'earn': 'Earned',
      'redeem': 'Redeemed',
      'reverse_earn': 'Earning reversed',
      'reverse_redeem': 'Redemption reversed',
      'adjust': 'Adjustment',
      'other': '$type',
    });
    return '$_temp0';
  }

  @override
  String kasbonStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'open': 'Unpaid',
      'partial': 'Part paid',
      'paid': 'Paid',
      'void': 'Void',
      'other': '$status',
    });
    return '$_temp0';
  }

  @override
  String get adminCustomerEmail => 'E-mail';

  @override
  String get adminCustomerLimit => 'Kasbon limit';

  @override
  String get adminCustomerLimitHint => 'Leave empty for no limit';

  @override
  String adminCustomerLimitShort(String amount) {
    return 'Limit $amount';
  }

  @override
  String get adminAdjustPoints => 'Adjust points';

  @override
  String get adminAdjustPointsField => 'Points (+ or −)';

  @override
  String get adminAdjustNote => 'Reason';

  @override
  String adminAdjustDone(int points) {
    return 'The balance is now $points points.';
  }

  @override
  String get adminPointsHistory => 'Points history';

  @override
  String adminKasbonPaidLine(String paid, String amount) {
    return 'Paid $paid of $amount';
  }

  @override
  String adminKasbonTotal(String total, String overdue) {
    return 'Total $total · overdue $overdue';
  }

  @override
  String get adminKasbonEmpty => 'No open kasbon.';

  @override
  String adminKasbonOldest(String date) {
    return 'Oldest $date';
  }

  @override
  String adminKasbonOverdue(String amount) {
    return 'Overdue $amount';
  }

  @override
  String get loyaltyEnabled => 'Points programme on';

  @override
  String get loyaltyEarn => 'Spend for 1 point';

  @override
  String get loyaltyValue => 'Value of 1 point when redeemed';

  @override
  String get loyaltyMin => 'Minimum points per redemption';

  @override
  String get loyaltyDueDays => 'Kasbon due after (days)';

  @override
  String loyaltyRange(int min, int max) {
    return 'Enter a number from $min to $max.';
  }

  @override
  String get loyaltyOwnerOnly => 'Only the owner can change these settings.';

  @override
  String get loyaltyHint =>
      'Applies to every store. Terminals use new settings after their next refresh.';

  @override
  String cashMovementApproval(String kind, String amount, String reason) {
    return '$kind of $amount opens the drawer: $reason';
  }
}
