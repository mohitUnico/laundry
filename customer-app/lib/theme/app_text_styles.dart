import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Per design spec:
  // - font-family: Poppins
  // - font-weight: 600 (SemiBold)
  // - font-size: 16px
  // - line-height: 100% (height: 1.0)
  // - letter-spacing: 0%
  static TextStyle header({
    Color? color,
  }) {
    return GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  // Per design spec:
  // - font-family: Poppins
  // - font-weight: 400 (Regular)
  // - font-size: 10px
  // - line-height: 100% (height: 1.0)
  // - letter-spacing: 0%
  static TextStyle body({
    Color? color,
  }) {
    return GoogleFonts.poppins(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  // Per design spec (buttons):
  // - font-family: Poppins
  // - font-weight: 500 (Medium)
  // - font-size: 12px
  // - line-height: 100% (height: 1.0)
  // - letter-spacing: 0%
  static TextStyle button({
    Color? color,
  }) {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  // Per design spec (account list items):
  // - font-family: Poppins
  // - font-weight: 500 (Medium)
  // - font-size: 15px
  // - line-height: 100% (height: 1.0)
  // - letter-spacing: 0%
  static TextStyle listItemTitle({
    Color? color,
  }) {
    return GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  // Per design spec (order tracking step labels):
  // - font-family: Poppins
  // - font-weight: 600 (SemiBold)
  // - font-size: 15px
  // - line-height: 100% (height: 1.0)
  // - letter-spacing: 0%
  static TextStyle stepTitle({
    Color? color,
  }) {
    return GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  // Per design spec (home offer banners):
  // - font-family: Poppins
  // - font-weight: 600 (SemiBold)
  // - font-size: 30px
  // - line-height: 100% (height: 1.0)
  // - letter-spacing: 0%
  static TextStyle offerHeadline({
    Color? color,
  }) {
    return GoogleFonts.poppins(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  // Per design spec (home offer banners subhead):
  // - font-family: Poppins
  // - font-weight: 400 (Regular)
  // - font-size: 16px
  // - line-height: 100% (height: 1.0)
  // - letter-spacing: 0%
  static TextStyle offerSubhead({
    Color? color,
  }) {
    return GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  // Per design spec (coupon code text):
  // - font-family: Poppins
  // - font-weight: 400 (Regular)
  // - font-size: 12px
  // - line-height: 100% (height: 1.0)
  // - letter-spacing: 0%
  static TextStyle couponCode({
    Color? color,
  }) {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }
}


