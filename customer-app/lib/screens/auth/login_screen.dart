import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../providers/auth_provider.dart';
import '../../routes/route_args.dart';
import '../../routes/app_routes.dart';
import '../../utils/validators.dart';
import '../../utils/auth_error_messages.dart';
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
  bool _isRequestingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isResendingOtp = false;
  Timer? _timer;
  int _resendSecondsRemaining = 0;
  int? _otpExpirySecondsRemaining;

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
    _timer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startTimers({required int otpExpiresInSeconds}) {
    _timer?.cancel();
    setState(() {
      _resendSecondsRemaining = 60;
      _otpExpirySecondsRemaining = otpExpiresInSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      setState(() {
        if (_resendSecondsRemaining > 0) _resendSecondsRemaining--;
        if (_otpExpirySecondsRemaining != null && _otpExpirySecondsRemaining! > 0) {
          _otpExpirySecondsRemaining = _otpExpirySecondsRemaining! - 1;
          if (_otpExpirySecondsRemaining == 0) {
            _otpError = 'OTP expired. Please resend OTP.';
          }
        }
      });

      final done =
          _resendSecondsRemaining <= 0 && (_otpExpirySecondsRemaining ?? 0) <= 0;
      if (done) t.cancel();
    });
  }

  String _formatSeconds(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _handleGetOtp() async {
    // Validate email
    final emailError = Validators.email(_emailController.text);
    setState(() {
      _emailError = emailError;
    });

    if (emailError != null) {
      return;
    }

    final email = _emailController.text.trim();

    setState(() {
      _isRequestingOtp = true;
      _otpError = null;
    });

    try {
      final result = await context.read<AuthProvider>().sendCustomerOtp(email);

      if (!mounted) return;
      setState(() {
        _otpRequested = true;
      });
      _startTimers(otpExpiresInSeconds: result.expiresIn);

      // Auto-focus the first OTP field after a short delay to ensure it's rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _otpInputKey.currentState?.focusFirst();
      });

    } catch (e) {
      if (!mounted) return;
      final message = AuthErrorMessages.getAuthErrorMessage(e, operation: 'send OTP');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingOtp = false;
        });
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (_isResendingOtp || _resendSecondsRemaining > 0) return;

    final emailError = Validators.email(_emailController.text);
    setState(() => _emailError = emailError);
    if (emailError != null) return;

    final email = _emailController.text.trim();

    setState(() {
      _isResendingOtp = true;
      _otpError = null;
      _otpAutoSubmitting = false;
    });

    try {
      final result = await context.read<AuthProvider>().resendCustomerOtp(email);
      if (!mounted) return;
      _startTimers(otpExpiresInSeconds: result.expiresIn);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent successfully')),
      );
      _otpInputKey.currentState?.focusFirst();
    } catch (e) {
      if (!mounted) return;
      final message = AuthErrorMessages.getAuthErrorMessage(e, operation: 'resend OTP');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _isResendingOtp = false);
    }
  }

  Future<void> _maybeAutoSubmitOtp({required String otp}) async {
    if (!_otpRequested) return;

    // Reset guard if user edits OTP (e.g., deletes a digit).
    if (otp.length != 6) {
      _otpAutoSubmitting = false;
      setState(() {
        _otpError = null;
      });
      return;
    }

    // Validate OTP
    final otpError = Validators.otp(otp);
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

    final email = _emailController.text.trim().toLowerCase();

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      final result = await context.read<AuthProvider>().verifyCustomerOtp(
            email: email,
            otp: otp,
          );

      if (!mounted) return;

      if (result.isNewUser) {
        final sessionToken = result.sessionToken;
        if (sessionToken == null || sessionToken.isEmpty) {
          throw Exception('Missing sessionToken in verify-otp response');
        }
        Navigator.of(context).pushNamed(
          AppRoutes.signup,
          arguments: SignupArgs(email: email, sessionToken: sessionToken),
        );
      } else {
        // Existing customer: go directly into app shell
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.shell,
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final message = AuthErrorMessages.getAuthErrorMessage(e, operation: 'verify OTP');
      setState(() {
        _otpError = message;
        _otpAutoSubmitting = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
        });
      }
    }
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
                        enabled: !(_isRequestingOtp || _isVerifyingOtp),
                        errorText: _emailError,
                      ),
                      const SizedBox(height: 14),
                      PrimaryButton(
                        label: 'Get OTP',
                        isLoading: _isRequestingOtp,
                        onPressed: (_isRequestingOtp || _isVerifyingOtp)
                            ? null
                            : () async {
                          // Clear email error when user starts typing
                          if (_emailError != null) {
                            setState(() => _emailError = null);
                          }
                          await _handleGetOtp();
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
                            _maybeAutoSubmitOtp(otp: value);
                          },
                          onCompleted: (value) {
                            setState(() {
                              _otp = value;
                              _otpError = null;
                            });
                            _maybeAutoSubmitOtp(otp: value);
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _otpExpirySecondsRemaining != null &&
                                        _otpExpirySecondsRemaining! > 0
                                    ? 'OTP expires in ${_formatSeconds(_otpExpirySecondsRemaining!)}'
                                    : 'OTP expires soon',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8B90A4),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: (_isResendingOtp ||
                                      _resendSecondsRemaining > 0 ||
                                      _isVerifyingOtp)
                                  ? null
                                  : _handleResendOtp,
                              child: _isResendingOtp
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(
                                      _resendSecondsRemaining > 0
                                          ? 'Resend OTP (${_resendSecondsRemaining}s)'
                                          : 'Resend OTP',
                                    ),
                            ),
                          ],
                        ),
                        if (_isVerifyingOtp) ...[
                          const SizedBox(height: 12),
                          const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ],
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
