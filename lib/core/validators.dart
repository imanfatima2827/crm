import 'dart:convert';

class FieldValidators {
  const FieldValidators._();

  static String? requiredText(String? value, {String message = 'Required'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value) {
    final required = requiredText(value);
    if (required != null) return required;
    return optionalEmail(value);
  }

  static String? optionalEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(text)) return 'Enter a valid email';
    return null;
  }

  static String? optionalPhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final digits = text.replaceAll(RegExp(r'\D'), '');
    final allowedCharacters = RegExp(r'^[0-9+\-().\s]+$');
    if (!allowedCharacters.hasMatch(text) ||
        digits.length < 7 ||
        digits.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? positiveNumber(
    String? value, {
    String message = 'Enter a value greater than 0',
  }) {
    final number = _parseNumber(value);
    if (number == null || number <= 0) return message;
    return null;
  }

  static String? nonNegativeNumber(
    String? value, {
    String message = 'Enter zero or a positive number',
  }) {
    final number = _parseNumber(value);
    if (number == null || number < 0) return message;
    return null;
  }

  static String? percentage(String? value) {
    final number = _parseNumber(value);
    if (number == null || number < 0 || number > 100) {
      return 'Enter a percentage from 0 to 100';
    }
    return null;
  }

  static String? jsonObject(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Required';

    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return null;
    } catch (_) {
      return 'Must be a valid JSON object';
    }
    return 'Must be a valid JSON object';
  }

  static double? _parseNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final number = double.tryParse(text);
    if (number == null || !number.isFinite) return null;
    return number;
  }
}
