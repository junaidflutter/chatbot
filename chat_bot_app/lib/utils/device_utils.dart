import 'dart:math';

import 'package:flutter/widgets.dart';

class DeviceUtils {
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diagonal = sqrt(
      (size.width * size.width) + (size.height * size.height),
    );

    return diagonal > 1100.0;
  }

  /// Check for Mobile
  static bool isMobile(BuildContext context) {
    return !isTablet(context);
  }

  /// Return string for debugging
  static String deviceType(BuildContext context) {
    return isTablet(context) ? 'iPad / Tablet View' : 'Mobile View';
  }
}
