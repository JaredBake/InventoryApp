import 'package:flutter/foundation.dart';

class ScannerCameraService {
  const ScannerCameraService();

  bool get supportsLiveScanning {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  String get unsupportedMessage =>
      'Barcode scanning needs a working camera on iPhone, iPad, or Android. Use manual entry instead.';
}
