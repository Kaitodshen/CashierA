import 'dart:convert';

import 'package:cashiera_core/cashiera_core.dart';
import 'package:test/test.dart';

const esc = 0x1B;
const gs = 0x1D;
const lf = 0x0A;

/// The printable text of [bytes] with ESC/POS commands removed, by line.
List<String> textLines(List<int> bytes) {
  final text = <int>[];
  var i = 0;
  while (i < bytes.length) {
    final b = bytes[i];
    if (b == esc) {
      final cmd = bytes[i + 1];
      i += switch (cmd) {
        0x40 => 2,
        0x70 => 5,
        _ => 3,
      };
    } else if (b == gs) {
      final cmd = bytes[i + 1];
      i += switch (cmd) {
        0x21 => 3,
        0x56 => 4,
        0x28 => 5 + bytes[i + 3] + bytes[i + 4] * 256,
        _ => 3,
      };
    } else {
      text.add(b);
      i++;
    }
  }
  return latin1.decode(text).split(String.fromCharCode(lf));
}

bool containsSeq(List<int> bytes, List<int> seq) {
  for (var i = 0; i + seq.length <= bytes.length; i++) {
    var ok = true;
    for (var j = 0; j < seq.length; j++) {
      if (bytes[i + j] != seq[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}

void main() {
  test('paper width picks the columns', () {
    expect(EscPosEncoder.forPaper(58).columns, 32);
    expect(EscPosEncoder.forPaper(80).columns, 48);
  });

  test('starts with init and the code page, and ends with a cut', () {
    final bytes = const EscPosEncoder(32)
        .encode(const ReceiptDocument([PrintText('Halo'), PrintCut()]));
    expect(bytes.sublist(0, 5), [esc, 0x40, esc, 0x74, 0]);
    expect(containsSeq(bytes, [gs, 0x56, 0x42, 3]), isTrue);
    expect(textLines(bytes).first, 'Halo');
  });

  test('align, bold and large set and reset their modes', () {
    final bytes = const EscPosEncoder(32).encode(
      const ReceiptDocument([
        PrintText('TOKO', align: PrintAlign.center, bold: true, large: true),
      ]),
    );
    expect(containsSeq(bytes, [esc, 0x61, 1]), isTrue);
    expect(containsSeq(bytes, [esc, 0x45, 1]), isTrue);
    expect(containsSeq(bytes, [gs, 0x21, 0x11]), isTrue);
    // Back to normal afterwards.
    expect(containsSeq(bytes, [esc, 0x45, 0]), isTrue);
    expect(containsSeq(bytes, [gs, 0x21, 0]), isTrue);
    expect(containsSeq(bytes, [esc, 0x61, 0]), isTrue);
  });

  test('rows put the amount on the right, wrapping the label', () {
    final bytes = const EscPosEncoder(32).encode(
      const ReceiptDocument([
        PrintRow('Total', 'Rp 25.000'),
        PrintRow('Indomie Goreng Rendang Spesial Jumbo', 'Rp 3.500'),
        PrintRule(),
      ]),
    );
    final lines = textLines(bytes);
    expect(lines[0], 'Total${' ' * 18}Rp 25.000');
    expect(lines[0].length, 32);
    expect(lines[1], 'Indomie Goreng Rendang  Rp 3.500');
    expect(lines[2], 'Spesial Jumbo');
    expect(lines[3], '-' * 32);
  });

  test('a large row uses half the columns', () {
    final lines = textLines(
      const EscPosEncoder(32).encode(
        const ReceiptDocument([PrintRow('TOTAL', 'Rp 9.000', large: true)]),
      ),
    );
    expect(lines[0].length, 16);
  });

  test('text wraps on words and breaks words longer than a line', () {
    expect(wrapText('Terima kasih atas kunjungan Anda', 12), [
      'Terima kasih',
      'atas',
      'kunjungan',
      'Anda',
    ]);
    expect(wrapText('ABCDEFGHIJ', 4), ['ABCD', 'EFGH', 'IJ']);
    expect(wrapText('baris 1\nbaris 2', 32), ['baris 1', 'baris 2']);
    expect(wrapText('', 10), ['']);
  });

  test('non-ASCII text is folded so every printer shows it', () {
    expect(foldToAscii('Café “Bunda” – 50%'), 'Cafe "Bunda" - 50%');
    expect(foldToAscii('58 mm · 32'), '58 mm - 32');
    expect(foldToAscii('日本'), '??');
    expect(foldToAscii('a\tb'), 'a b');
  });

  test('drawer pulse, feed and QR code', () {
    final bytes = const EscPosEncoder(48).encode(
      const ReceiptDocument([
        PrintDrawer(),
        PrintFeed(2),
        PrintQr('PST-T1-261106-0001'),
      ]),
    );
    expect(containsSeq(bytes, [esc, 0x70, 0, 25, 250]), isTrue);
    expect(containsSeq(bytes, [esc, 0x64, 2]), isTrue);
    // Store the data: GS ( k pL pH 49 80 48 data (length + 3).
    const data = 'PST-T1-261106-0001';
    expect(
      containsSeq(bytes, [gs, 0x28, 0x6B, data.length + 3, 0, 49, 80, 48]),
      isTrue,
    );
    expect(containsSeq(bytes, [gs, 0x28, 0x6B, 3, 0, 49, 81, 48]), isTrue);
  });

  test('the drawer alone can be kicked without paper', () {
    expect(EscPosEncoder.drawerKick(), [esc, 0x40, esc, 0x70, 0, 25, 250]);
  });
}
