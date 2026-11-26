import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/constants/app_constants.dart';
import '../../../../injection/dependency_injection.dart';

class UnsavedDraftStore {
  UnsavedDraftStore._();

  static String? _inMemoryTitle;
  static String? _inMemoryDescription;

  static String getSavedTitle() {
    try {
      final prefs = sl<SharedPreferences>();
      return prefs.getString(AppConstants.keyUnsavedCreateTitle) ??
          _inMemoryTitle ??
          '';
    } catch (_) {
      return _inMemoryTitle ?? '';
    }
  }

  static String getSavedDescription() {
    try {
      final prefs = sl<SharedPreferences>();
      return prefs.getString(AppConstants.keyUnsavedCreateDescription) ??
          _inMemoryDescription ??
          '';
    } catch (_) {
      return _inMemoryDescription ?? '';
    }
  }

  static void saveDraft(String title, String description) {
    _inMemoryTitle = title;
    _inMemoryDescription = description;
    try {
      final prefs = sl<SharedPreferences>();
      prefs.setString(AppConstants.keyUnsavedCreateTitle, title);
      prefs.setString(AppConstants.keyUnsavedCreateDescription, description);
    } catch (_) {}
  }

  static void clearDraft() {
    _inMemoryTitle = null;
    _inMemoryDescription = null;
    try {
      final prefs = sl<SharedPreferences>();
      prefs.remove(AppConstants.keyUnsavedCreateTitle);
      prefs.remove(AppConstants.keyUnsavedCreateDescription);
    } catch (_) {}
  }
}
