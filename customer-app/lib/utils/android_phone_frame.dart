import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Fits every screen to the current Android phone.
///
/// Layout is done at one phone width, then scaled to the real display.
/// That covers small, normal, and large phones, plus Android display-size
/// and font-size settings. Tablets and other platforms are left unchanged.
class AndroidPhoneFrame extends StatelessWidget {
  final Widget child;

  const AndroidPhoneFrame({super.key, required this.child});

  /// Width the screens were built around.
  static const double designWidth = 390;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) return child;

    final media = MediaQuery.of(context);
    final size = media.size;
    if (size.width < 200 || size.height < 200) return child;

    // Android's tablet breakpoint. This app is for phones only.
    if (size.shortestSide >= 600) return child;

    final portrait = size.height >= size.width;
    final scale = portrait
        ? size.width / designWidth
        : math.min(size.width / designWidth, size.height / 780);
    if (scale <= 0) return child;

    final layoutHeight = size.height / scale;
    final text = media.textScaler.scale(1).clamp(0.92, 1.12);

    final framed = MediaQuery(
      data: media.copyWith(
        size: Size(designWidth, layoutHeight),
        padding: media.padding / scale,
        viewPadding: media.viewPadding / scale,
        viewInsets: media.viewInsets / scale,
        systemGestureInsets: media.systemGestureInsets / scale,
        textScaler: TextScaler.linear(text),
      ),
      child: child,
    );

    return Center(
      child: SizedBox(
        width: designWidth * scale,
        height: size.height,
        child: FittedBox(
          fit: BoxFit.fill,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: designWidth,
            height: layoutHeight,
            child: framed,
          ),
        ),
      ),
    );
  }
}
