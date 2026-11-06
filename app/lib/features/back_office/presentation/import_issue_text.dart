import 'package:cashiera/core/l10n/l10n.dart';
import 'package:cashiera_core/cashiera_core.dart';

/// "Baris 3: Satuan "karung" tidak dikenal." style message for one issue.
String importIssueText(AppLocalizations l10n, ImportIssue issue) {
  final column = issue.column ?? '';
  final value = issue.value ?? '';
  final text = switch (issue.code) {
    ImportIssueCode.emptyFile => l10n.issue_emptyFile,
    ImportIssueCode.missingColumn => l10n.issue_missingColumn(column),
    ImportIssueCode.unknownStore => l10n.issue_unknownStore(column),
    ImportIssueCode.tooManyRows => l10n.issue_tooManyRows,
    ImportIssueCode.requiredValue => l10n.issue_requiredValue(column),
    ImportIssueCode.skuFormat => l10n.issue_skuFormat(value),
    ImportIssueCode.barcodeFormat => l10n.issue_barcodeFormat(value),
    ImportIssueCode.priceFormat => l10n.issue_priceFormat(column, value),
    ImportIssueCode.quantityFormat => l10n.issue_quantityFormat(column, value),
    ImportIssueCode.booleanFormat => l10n.issue_booleanFormat(column, value),
    ImportIssueCode.unknownUnit => l10n.issue_unknownUnit(value),
    ImportIssueCode.duplicateSku => l10n.issue_duplicateSku(value),
    ImportIssueCode.duplicateBarcode => l10n.issue_duplicateBarcode(value),
    ImportIssueCode.productMismatch => l10n.issue_productMismatch(value),
  };
  final where = issue.row <= 1
      ? l10n.importFileLevel
      : l10n.importRowLabel(issue.row);
  return '$where: $text';
}
