class ValidationHelpers {
  // Email validation regex
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Phone validation regex (supports international formats)
  static final RegExp _phoneRegex = RegExp(
    r'^[\+]?[(]?[0-9]{1,4}[)]?[-\s\.]?[(]?[0-9]{1,4}[)]?[-\s\.]?[0-9]{1,9}$',
  );

  /// Validates email format
  /// Returns null if valid, error message if invalid
  static String? validateEmail(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'Unesite email adresu' : null;
    }

    if (!_emailRegex.hasMatch(value)) {
      return 'Unesite valjanu email adresu (npr. korisnik@example.com)';
    }

    return null;
  }

  /// Validates phone number format
  /// Returns null if valid, error message if invalid
  static String? validatePhone(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'Unesite broj telefona' : null;
    }

    // Remove spaces and common phone formatting characters
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleaned.length < 6 || cleaned.length > 15) {
      return 'Broj telefona mora imati između 6 i 15 cifara (npr. +387 33 123 456 ili 061 123 456)';
    }

    if (!_phoneRegex.hasMatch(value)) {
      return 'Unesite valjan broj telefona (npr. +387 33 123 456 ili 061 123 456)';
    }

    return null;
  }

  /// Validates password
  /// Returns null if valid, error message if invalid
  static String? validatePassword(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'Unesite lozinku' : null;
    }

    if (value.length < 6) {
      return 'Lozinka mora imati najmanje 6 karaktera';
    }

    if (value.length > 100) {
      return 'Lozinka ne smije biti duža od 100 karaktera';
    }

    return null;
  }

  /// Validates password confirmation
  /// Returns null if valid, error message if invalid
  static String? validatePasswordConfirmation(
    String? value,
    String password, {
    bool required = true,
  }) {
    if (value == null || value.isEmpty) {
      return required ? 'Potvrdite lozinku' : null;
    }

    if (value != password) {
      return 'Lozinke se ne poklapaju. Unesite istu lozinku u oba polja.';
    }

    return null;
  }

  /// Validates required text field
  /// Returns null if valid, error message if invalid
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Unesite $fieldName';
    }
    return null;
  }

  /// Validates text length
  /// Returns null if valid, error message if invalid
  static String? validateLength(
    String? value,
    String fieldName, {
    int? minLength,
    int? maxLength,
    bool required = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Unesite $fieldName' : null;
    }

    final trimmed = value.trim();

    if (minLength != null && trimmed.length < minLength) {
      return '$fieldName mora imati najmanje $minLength karaktera';
    }

    if (maxLength != null && trimmed.length > maxLength) {
      return '$fieldName ne smije biti duže od $maxLength karaktera';
    }

    return null;
  }

  /// Validates username
  /// Returns null if valid, error message if invalid
  static String? validateUsername(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'Unesite korisničko ime' : null;
    }

    if (value.length < 3) {
      return 'Korisničko ime mora imati najmanje 3 karaktera';
    }

    if (value.length > 20) {
      return 'Korisničko ime ne smije biti duže od 20 karaktera';
    }

    // Username can contain letters, numbers, and underscores
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Korisničko ime može sadržavati samo slova, brojeve i donje crte (_)';
    }

    return null;
  }
}

