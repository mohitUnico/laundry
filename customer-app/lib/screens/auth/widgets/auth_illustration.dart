import 'package:flutter/material.dart';

class AuthIllustration extends StatelessWidget {
  const AuthIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final height = (h * 0.32).clamp(220.0, 320.0);

    return Image.asset(
      'assets/images/auth/person.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}


