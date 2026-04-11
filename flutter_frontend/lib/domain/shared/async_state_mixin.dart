// NEW FILE: lib/domain/shared/async_state_mixin.dart

import 'package:flutter/cupertino.dart';

mixin AsyncStateMixin on ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  /// Wraps [action] in the standard loading/error lifecycle.
  /// Callers replace the try/catch/finally block with a single call.
  Future<T?> runAsync<T>(Future<T> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await action();
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}