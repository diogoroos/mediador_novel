import 'package:flutter/foundation.dart';

bool controlesToque() {
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
