import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../utils/role_constants.dart';
import '../../providers/auth_provider.dart';

import 'widgets/otp_input_row.dart' show OtpInputRow, OtpInputRowState;
import 'widgets/pill_text_field.dart';
import 'widgets/auth_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<OtpInputRowState> _otpInputKey = GlobalKey<OtpInputRowState>();

  bool _otpRequested = false;
  String _otp = '';
  bool _otpAutoSubmitting = false;
  String? _emailError;
  String? _otpError;
  String? _userIdError;
  String? _passwordError;
  bool _obscurePassword = true;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGetOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _emailError = 'Please enter a valid email';
      });
      return;
    }

    setState(() {
      _emailError = null;
      _otpError = null;
      _isSendingOtp = true;
    });

    try {
      await context.read<AuthProvider>().sendDeliveryOtp(email: email);
      if (!mounted) return;
      setState(() {
        _otpRequested = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _otpError = _friendlyError(e);
      });
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpInputKey.currentState?.focusFirst();
    });

    _maybeAutoSubmitOtp();
  }

  Future<void> _maybeAutoSubmitOtp() async {
    if (!_otpRequested) return;

    if (_otp.length != 6) {
      _otpAutoSubmitting = false;
      setState(() {
        _otpError = null;
      });
      return;
    }

    if (_otpAutoSubmitting) return;
    _otpAutoSubmitting = true;
    setState(() {
      _isVerifyingOtp = true;
      _otpError = null;
    });

    FocusScope.of(context).unfocus();

    try {
      final email = _emailController.text.trim();
      final isNewUser = await context.read<AuthProvider>().verifyDeliveryOtp(
            email: email,
            otp: _otp,
          );
      if (!mounted) return;
      if (isNewUser) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.userDetails);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _otpError = _friendlyError(e);
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

  String _friendlyError(Object e) {
    final text = e.toString();
    // Dio errors often include "Exception:" prefix; keep message readable.
    return text.replaceFirst('Exception: ', '').trim();
  }

  void _handleLogin() {
    final userId = _userIdController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _userIdError = null;
      _passwordError = null;
    });

    if (userId.isEmpty) {
      setState(() {
        _userIdError = 'Please enter your User ID';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Please enter your password';
      });
      return;
    }

    // TODO: Implement actual login logic
    // For now, navigate to role-specific home
    final role =
        (ModalRoute.of(context)?.settings.arguments as Map?)?['role'] as String?;
    
    if (role == RoleConstants.serviceMan) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.pendingOrdersServicemen);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role =
        (ModalRoute.of(context)?.settings.arguments as Map?)?['role'] as String?;
    
    final isDeliveryPartner = role == RoleConstants.deliveryPartner;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: SizedBox(
                          height: 280,
                          child: Image.asset(
                            'assets/images/auth/registration.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isDeliveryPartner
                            ? 'Welcome to your\ndelivery zone!'
                            : 'Welcome back!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.header(
                                color: AppColors.textPrimary)
                            .copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isDeliveryPartner
                            ? 'Time to bring freshness to every doorstep.'
                            : 'Sign in to continue to your workspace.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(color: AppColors.primary)
                            .copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (role != null && isDeliveryPartner) ...[
                        Text(
                          'Selected role: $role',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(
                                  color: AppColors.textSecondary)
                              .copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Delivery Partner: OTP-based login
                      if (isDeliveryPartner) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Email',
                            style: AppTextStyles.body(
                                    color: AppColors.textPrimary)
                                .copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        PillTextField(
                          controller: _emailController,
                          hintText: 'Enter Your Email',
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: (_isSendingOtp || _isVerifyingOtp) ? null : _handleGetOtp,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.zero,
                              elevation: 0,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2437B6), Color(0xFF2C3CA5)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: Center(
                                child: _isSendingOtp
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Get OTP',
                                        style: AppTextStyles.button(color: Colors.white).copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        if (_otpRequested) ...[
                          const SizedBox(height: 22),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Enter OTP',
                              style: AppTextStyles.body(
                                      color: AppColors.textPrimary)
                                  .copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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
                              setState(() {
                                _otp = value;
                                _otpError = null;
                              });
                              _maybeAutoSubmitOtp();
                            },
                          ),
                          if (_isVerifyingOtp) ...[
                            const SizedBox(height: 10),
                            const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ],
                          if (_otpError != null) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
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
                      ] else ...[
                        // Other roles: User ID and Password login
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'User ID',
                            style: AppTextStyles.body(
                                    color: AppColors.textPrimary)
                                .copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        PillTextField(
                          controller: _userIdController,
                          hintText: 'Enter Your User ID',
                          keyboardType: TextInputType.text,
                          errorText: _userIdError,
                        ),
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Password',
                            style: AppTextStyles.body(
                                    color: AppColors.textPrimary)
                                .copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              keyboardType: TextInputType.visiblePassword,
                              decoration: InputDecoration(
                                hintText: 'Enter Your Password',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFB8BDCF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(
                                    color: _passwordError != null
                                        ? Colors.red
                                        : AuthColors.border,
                                    width: 1.6,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(
                                    color: _passwordError != null
                                        ? Colors.red
                                        : AuthColors.border,
                                    width: 1.6,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(
                                    color: _passwordError != null
                                        ? Colors.red
                                        : AuthColors.border,
                                    width: 2.0,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(
                                      color: Colors.red, width: 1.6),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(
                                      color: Colors.red, width: 2.0),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            if (_passwordError != null) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 18),
                                child: Text(
                                  _passwordError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Password visibility toggle
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.zero,
                              elevation: 0,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2437B6), Color(0xFF2C3CA5)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Login',
                                  style: AppTextStyles.button(
                                          color: Colors.white)
                                      .copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

