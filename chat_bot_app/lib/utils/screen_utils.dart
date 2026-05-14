import 'package:flutter/material.dart';

extension ScreenSizeUtil on BuildContext {
  double get height => MediaQuery.of(this).size.height;

  double get width => MediaQuery.of(this).size.width;

  bool get isMobile => MediaQuery.of(this).orientation == Orientation.portrait
      ? width < ScreenUtil.maxMobileWidth
      : height < ScreenUtil.maxMobileWidth;
}

class ScreenUtil {
  ScreenUtil._();

  static const double maxMobileWidth = 600;

  static double getSafeMinimumHeight(BuildContext context, double height) =>
      height < context.height ? height : context.height;
}
