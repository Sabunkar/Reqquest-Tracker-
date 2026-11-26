class RequestValidator {
  const RequestValidator._();

  static const int minTitleLength = 3;
  static const int maxTitleLength = 120;
  static const int maxDescriptionLength = 2000;

  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < minTitleLength) {
      return 'Title must be at least $minTitleLength characters';
    }
    if (trimmed.length > maxTitleLength) {
      return 'Title must not exceed $maxTitleLength characters';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      // Empty description is allowed unless otherwise specified.
      return null;
    }
    if (value.trim().length > maxDescriptionLength) {
      return 'Description must not exceed $maxDescriptionLength characters';
    }
    return null;
  }

  static String? validateRejectionReason(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Rejection reason is required';
    }
    if (value.trim().length < 3) {
      return 'Rejection reason must be at least 3 characters';
    }
    if (value.trim().length > 500) {
      return 'Rejection reason must not exceed 500 characters';
    }
    return null;
  }
}
