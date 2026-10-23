import 'dart:io';

import 'package:flutter/material.dart';

class ProfilePhoto extends StatelessWidget {
  final String? path;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ProfilePhoto({
    super.key,
    this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final value = (path ?? '').trim();
    if (value.isEmpty) return _fallback();
    if (value.startsWith('http')) {
      return Image.network(
        value,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return Image.file(
      File(value),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Image.asset(
      'assets/icons/profile_pic_demo.png',
      width: width,
      height: height,
      fit: fit,
    );
  }
}
