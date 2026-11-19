/// Shared WhatsApp phone helpers (digits + country code).
class PhoneUtils {
  PhoneUtils._();

  static const int minDigits = 8;
  static const int maxDigits = 15;

  /// Strip to digits only.
  static String normalize(String? raw) =>
      (raw ?? '').replaceAll(RegExp(r'[^\d]'), '');

  /// True when length is in E.164 digit range (no leading +).
  static bool isValid(String? raw) {
    final d = normalize(raw);
    return d.length >= minDigits && d.length <= maxDigits;
  }

  /// User-facing reason, or null when OK.
  static String? validationError(String? raw) {
    final d = normalize(raw);
    if (d.isEmpty) {
      return 'Enter WhatsApp number with country code (e.g. 998901234567)';
    }
    if (d.length < minDigits) {
      return 'Number too short — include country code';
    }
    if (d.length > maxDigits) {
      return 'Number too long — use digits only, max $maxDigits';
    }
    return null;
  }
}
