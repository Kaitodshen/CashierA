import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

enum PrintAlign { left, center, right }

/// One piece of a printed slip.
@immutable
sealed class PrintBlock {
  const new();
}

/// A paragraph, word-wrapped to the paper. [large] is double width and
/// height, so it fits half the columns.
final class PrintText extends PrintBlock {
  const new(
    this.text, {
    this.align = PrintAlign.left,
    this.bold = false,
    this.large = false,
  });

  final String text;
  final PrintAlign align;
  final bool bold;
  final bool large;
}

/// A label on the left and a value on the right (amounts). The label wraps;
/// the value stays on the first line.
final class PrintRow extends PrintBlock {
  const new(this.left, this.right, {this.bold = false, this.large = false});

  final String left;
  final String right;
  final bool bold;
  final bool large;
}

/// A full-width line of [char].
final class PrintRule extends PrintBlock {
  const new({this.char = '-'});
  final String char;
}

final class PrintFeed extends PrintBlock {
  const new([this.lines = 1]);
  final int lines;
}

/// A centred QR code (model 2, error level M). [size] is the module size,
/// 1 to 16 dots.
final class PrintQr extends PrintBlock {
  const new(this.data, {this.size = 6});
  final String data;
  final int size;
}

/// Feed a little and cut (partial cut where the printer has a cutter).
final class PrintCut extends PrintBlock {
  const new();
}

/// Pulse the cash drawer connected to the printer.
final class PrintDrawer extends PrintBlock {
  const new();
}

/// A receipt, report or test page, independent of the printer.
@immutable
class ReceiptDocument {
  const new(this.blocks);
  final List<PrintBlock> blocks;
}

/// Turns a [ReceiptDocument] into ESC/POS bytes for a printer with
/// [columns] characters per line (Font A).
@immutable
class EscPosEncoder {
  const new(this.columns);

  /// 58 mm paper prints 32 columns, 80 mm prints 48.
  factory forPaper(int paperMm) => EscPosEncoder(paperMm >= 80 ? 48 : 32);

  static const _esc = 0x1B;
  static const _gs = 0x1D;
  static const _lf = 0x0A;

  /// `ESC @` then `ESC p 0 25 250`: pin 2, 50 ms on, 500 ms off.
  static Uint8List drawerKick() =>
      Uint8List.fromList(const [_esc, 0x40, _esc, 0x70, 0, 25, 250]);

  final int columns;

  Uint8List encode(ReceiptDocument doc) {
    // Reset, then code page 0 (PC437): plain ASCII is the same everywhere.
    final out = BytesBuilder(copy: false)..add([_esc, 0x40, _esc, 0x74, 0]);
    for (final block in doc.blocks) {
      switch (block) {
        case PrintText(:final text, :final align, :final bold, :final large):
          _modes(out, align: align, bold: bold, large: large);
          final width = large ? columns ~/ 2 : columns;
          for (final line in wrapText(foldToAscii(text), width)) {
            _line(out, line);
          }
          _modes(out);
        case PrintRow(:final left, :final right, :final bold, :final large):
          _modes(out, bold: bold, large: large);
          final width = large ? columns ~/ 2 : columns;
          for (final line in _rowLines(
            foldToAscii(left),
            foldToAscii(right),
            width,
          )) {
            _line(out, line);
          }
          _modes(out);
        case PrintRule(:final char):
          _line(out, foldToAscii(char).padRight(1).substring(0, 1) * columns);
        case PrintFeed(:final lines):
          out.add([_esc, 0x64, lines.clamp(0, 255)]);
        case PrintQr(:final data, :final size):
          _qr(out, data, size.clamp(1, 16));
        case PrintCut():
          out.add([_gs, 0x56, 0x42, 3]);
        case PrintDrawer():
          out.add([_esc, 0x70, 0, 25, 250]);
      }
    }
    return out.takeBytes();
  }

  void _modes(
    BytesBuilder out, {
    PrintAlign align = PrintAlign.left,
    bool bold = false,
    bool large = false,
  }) => out
    ..add([_esc, 0x61, align.index])
    ..add([_esc, 0x45, if (bold) 1 else 0])
    ..add([_gs, 0x21, if (large) 0x11 else 0]);

  void _line(BytesBuilder out, String text) => out
    ..add(latin1.encode(text))
    ..addByte(_lf);

  List<String> _rowLines(String left, String right, int width) {
    if (right.length >= width - 1) {
      return [...wrapText(left, width), right.padLeft(width)];
    }
    final labelWidth = width - right.length - 1;
    final label = wrapText(left, labelWidth);
    return [label.first.padRight(labelWidth + 1) + right, ...label.skip(1)];
  }

  void _qr(BytesBuilder out, String data, int size) {
    final bytes = latin1.encode(foldToAscii(data));
    final length = bytes.length + 3;
    out
      ..add([_esc, 0x61, 1])
      // Model 2.
      ..add([_gs, 0x28, 0x6B, 4, 0, 49, 65, 50, 0])
      // Module size.
      ..add([_gs, 0x28, 0x6B, 3, 0, 49, 67, size])
      // Error correction M.
      ..add([_gs, 0x28, 0x6B, 3, 0, 49, 69, 49])
      // Store the data.
      ..add([_gs, 0x28, 0x6B, length & 0xFF, length >> 8, 49, 80, 48])
      ..add(bytes)
      // Print it.
      ..add([_gs, 0x28, 0x6B, 3, 0, 49, 81, 48])
      ..addByte(_lf)
      ..add([_esc, 0x61, 0]);
  }
}

/// Splits [text] into lines of at most [width] characters, on spaces where
/// possible. Explicit line breaks are kept.
List<String> wrapText(String text, int width) {
  if (width < 1) throw ArgumentError.value(width, 'width');
  final lines = <String>[];
  for (final paragraph in text.split('\n')) {
    var current = '';
    for (final word in paragraph.split(' ').where((w) => w.isNotEmpty)) {
      var rest = word;
      if (current.isNotEmpty && current.length + 1 + rest.length <= width) {
        current = '$current $rest';
        continue;
      }
      if (current.isNotEmpty) lines.add(current);
      current = '';
      while (rest.length > width) {
        lines.add(rest.substring(0, width));
        rest = rest.substring(width);
      }
      current = rest;
    }
    lines.add(current);
  }
  return lines;
}

const _fold = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', //
  'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ü': 'U',
  'ñ': 'n', 'Ñ': 'N', 'ç': 'c', 'Ç': 'C', 'ß': 'ss',
  '‘': "'", '’': "'", '“': '"', '”': '"', '–': '-', '—': '-',
  '…': '...', '•': '*', '·': '-', '×': 'x', '°': 'o', ' ': ' ',
};

/// Printer-safe text: accents dropped, typographic quotes and dashes made
/// plain, tabs and other control characters turned into spaces, and
/// anything else outside ASCII printed as `?`.
String foldToAscii(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    final folded = _fold[char];
    if (folded != null) {
      out.write(folded);
    } else if (rune == 0x0A) {
      out.write('\n');
    } else if (rune < 0x20 || rune == 0x7F) {
      out.write(' ');
    } else if (rune > 0x7E) {
      out.write('?');
    } else {
      out.write(char);
    }
  }
  return out.toString();
}
