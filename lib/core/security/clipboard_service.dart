import 'dart:async';

import 'package:flutter/services.dart';

class ClipboardService {
  Timer? _clearTimer;

  Future<void> copySecret(String value, Duration timeout) async {
    await Clipboard.setData(ClipboardData(text: value));
    _clearTimer?.cancel();
    _clearTimer = Timer(timeout, () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
  }

  Future<void> copyNonSecret(String value) {
    return Clipboard.setData(ClipboardData(text: value));
  }

  void dispose() {
    _clearTimer?.cancel();
  }
}
