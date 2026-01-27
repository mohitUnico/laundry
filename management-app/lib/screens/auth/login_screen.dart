import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../utils/role_constants.dart';
import '../../providers/auth_provider.dart';

import 'widgets/otp_input_row.dart' show OtpInputRow, OtpInputRowState;
import 'widgets/pill_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _serviceIdController = TextEditingController();
  final GlobalKey<OtpInputRowState> _otpInputKey = GlobalKey<OtpInputRowState>();

  bool _otpRequested = false;
  String _otp = '';
  bool _otpAutoSubmitting = false;
  String? _emailError;
  String? _serviceIdError;
  String? _otpError;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _serviceIdController.dispose();
    super.dispose();
  }

  Future<void> _showNewUserDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.support_agent,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Profile Required',
                style: AppTextStyles.header(color: AppColors.textPrimary).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            'Please contact support team for profile creation',
            style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(
              fontSize: 13,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: AppTextStyles.body(color: AppColors.primary).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleGetOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _emailError = 'Please enter a valid email';
      });
      return;
    }

    final role =
        (ModalRoute.of(context)?.settings.arguments as Map?)?['role'] as String?;
    if (role == null) {
      setState(() {
        _otpError = 'Role not selected';
      });
      return;
    }

    String? serviceId;
    if (role == RoleConstants.serviceMan) {
      final raw = _serviceIdController.text.trim();
      final uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      if (raw.isEmpty || !uuid.hasMatch(raw)) {
        setState(() {
          _serviceIdError = 'Please enter a valid Service ID (UUID)';
        });
        return;
      }
      serviceId = raw;
    }

    setState(() {
      _emailError = null;
      _serviceIdError = null;
      _otpError = null;
      _isSendingOtp = true;
    });

    try {
      await context.read<AuthProvider>().sendOtpForRole(
            role: role,
            email: email,
            serviceId: serviceId,
          );
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
      final role =
          (ModalRoute.of(context)?.settings.arguments as Map?)?['role'] as String?;
      if (role == null) {
        throw Exception('Role not selected');
      }

      final isNewUser = await context.read<AuthProvider>().verifyOtpForRole(
            role: role,
            email: email,
            otp: _otp,
            serviceId: role == RoleConstants.serviceMan ? _serviceIdController.text.trim() : null,
          );
      if (!mounted) return;
      if (isNewUser) {
        if (role == RoleConstants.deliveryPartner) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.userDetails);
        } else if (role == RoleConstants.collectionManager ||
            role == RoleConstants.distributionManager ||
            role == RoleConstants.serviceMan) {
          await _showNewUserDialog();
          if (!mounted) return;
          setState(() {
            _otp = '';
            _otpRequested = false;
            _otpAutoSubmitting = false;
          });
        } else {
          await _showNewUserDialog();
        }
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

  @override
  Widget build(BuildContext context) {
    final role =
        (ModalRoute.of(context)?.settings.arguments as Map?)?['role'] as String?;
    
    final isDeliveryPartner = role == RoleConstants.deliveryPartner;
    final isServiceMan = role == RoleConstants.serviceMan;
    // We no longer use User ID / Password login for any role.
    const usesOtpLogin = true;

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
                      // OTP-based login for all roles
                      if (usesOtpLogin) ...[
                        if (role == null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE6E3FF)),
                            ),
                            child: Text(
                              'Please go back and select your role again.',
                              style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(
                                fontSize: 13,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        if (isServiceMan) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Service ID',
                              style: AppTextStyles.body(color: AppColors.textPrimary).copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          PillTextField(
                            controller: _serviceIdController,
                            hintText: 'Enter Service ID (UUID)',
                            keyboardType: TextInputType.text,
                            errorText: _serviceIdError,
                          ),
                          const SizedBox(height: 18),
                        ],
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

