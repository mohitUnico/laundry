import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../utils/validators.dart';
import 'widgets/auth_colors.dart';
import 'widgets/auth_illustration.dart';
import 'widgets/labeled_divider.dart';
import 'widgets/otp_input_row.dart' show OtpInputRow, OtpInputRowState;
import 'widgets/pill_text_field.dart';
import 'widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<OtpInputRowState> _otpInputKey = GlobalKey<OtpInputRowState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _otpRequested = false;
  String _otp = '';
  bool _otpAutoSubmitting = false;
  String? _emailError;
  String? _otpError;

  @override
  void initState() {
    super.initState();
    // Clear email error when user starts typing
    _emailController.addListener(() {
      if (_emailError != null && _emailController.text.isNotEmpty) {
        setState(() => _emailError = null);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleGetOtp() {
    // Validate email
    final emailError = Validators.email(_emailController.text);
    setState(() {
      _emailError = emailError;
    });

    if (emailError != null) {
      return;
    }
    
    setState(() {
      _otpRequested = true;
      _otpError = null;
    });

    // Auto-focus the first OTP field after a short delay to ensure it's rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpInputKey.currentState?.focusFirst();
    });

    _maybeAutoSubmitOtp();
  }

  void _maybeAutoSubmitOtp() {
    if (!_otpRequested) return;

    // Reset guard if user edits OTP (e.g., deletes a digit).
    if (_otp.length != 6) {
      _otpAutoSubmitting = false;
      setState(() {
        _otpError = null;
      });
      return;
    }

    // Validate OTP
    final otpError = Validators.otp(_otp);
    if (otpError != null) {
      setState(() {
        _otpError = otpError;
        _otpAutoSubmitting = false;
      });
      return;
    }

    if (_otpAutoSubmitting) return;
    _otpAutoSubmitting = true;

    FocusScope.of(context).unfocus();
    Navigator.of(context).pushNamed(AppRoutes.signup);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: AuthIllustration()),
                      const SizedBox(height: 18),
                      const Text(
                        'Welcome!',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your next pickup is just a tap away',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AuthColors.primary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const LabeledDivider(label: 'Email'),
                      const SizedBox(height: 10),
                      PillTextField(
                        controller: _emailController,
                        hintText: 'Enter Your Email',
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                      ),
                      const SizedBox(height: 14),
                      PrimaryButton(
                        label: 'Get OTP',
                        onPressed: () {
                          // Clear email error when user starts typing
                          if (_emailError != null) {
                            setState(() => _emailError = null);
                          }
                          _handleGetOtp();
                        },
                      ),
                      if (_otpRequested) ...[
                        const SizedBox(height: 22),
                        const LabeledDivider(label: 'Enter OTP'),
                        const SizedBox(height: 12),
                        OtpInputRow(
                          key: _otpInputKey,
                          length: 6,
                          onChanged: (value) {
                            setState(() {
                              _otp = value;
                              _otpError = null;
                            });
                            _maybeAutoSubmitOtp();
                          },
                          onCompleted: (value) {
                            // This also handles paste-to-fill scenarios.
                            setState(() {
                              _otp = value;
                              _otpError = null;
                            });
                            _maybeAutoSubmitOtp();
                          },
                        ),
                        if (_otpError != null) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 18),
                            child: Text(
                              _otpError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
