import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android main manifest does not request INTERNET permission', () async {
    final manifest = await File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsString();

    expect(manifest.contains('android.permission.INTERNET'), isFalse);
    expect(manifest.contains('android:allowBackup="false"'), isTrue);
  });
}
