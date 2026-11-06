/// The pairing-code alphabet used by `create_device_pairing_code`: no O, 0,
/// I or 1, so codes read aloud or handwritten can't be mistyped.
const pairingAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/// Uppercases and removes spaces and dashes (`abcd-2345` → `ABCD2345`).
String normalizePairingCode(String input) =>
    input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

bool isValidPairingCode(String input) {
  final code = normalizePairingCode(input);
  return code.length == 8 && code.split('').every(pairingAlphabet.contains);
}
