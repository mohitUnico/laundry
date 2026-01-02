import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Text styles copied from the customer app to keep typography consistent.
class AppTextStyles {
  static TextStyle header({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  static TextStyle body({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  static TextStyle button({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  static TextStyle listItemTitle({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  static TextStyle stepTitle({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  static TextStyle offerHeadline({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  static TextStyle offerSubhead({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  static TextStyle couponCode({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  static TextStyle largeNumber({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  static TextStyle title({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  static TextStyle subtitle({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  static TextStyle smallText({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  static TextStyle price({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  static TextStyle time({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }
}


