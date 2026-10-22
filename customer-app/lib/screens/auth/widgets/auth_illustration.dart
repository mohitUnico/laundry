import 'package:flutter/material.dart';

class AuthIllustration extends StatelessWidget {
  final String asset;

  const AuthIllustration({
    super.key,
    this.asset = 'assets/images/auth/person.png',
  });

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final height = (h * 0.32).clamp(220.0, 320.0);

    return Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
    );
  }
}


