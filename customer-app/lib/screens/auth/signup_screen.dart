import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';

import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../routes/route_args.dart';
import '../../utils/validators.dart';
import '../../widgets/phone_field_with_country_picker.dart';
import 'widgets/auth_colors.dart';
import 'widgets/auth_illustration.dart';
import 'widgets/labeled_divider.dart';
import 'widgets/pill_text_field.dart';
import 'widgets/primary_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  Country _selectedCountry = Country.parse('IN'); // Default to India
  
  String? _firstNameError;
  String? _lastNameError;
  String? _phoneError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Clear errors when user starts typing
    _firstNameController.addListener(() {
      if (_firstNameError != null && _firstNameController.text.isNotEmpty) {
        setState(() => _firstNameError = null);
      }
    });
    _lastNameController.addListener(() {
      if (_lastNameError != null && _lastNameController.text.isNotEmpty) {
        setState(() => _lastNameError = null);
      }
    });
    _phoneController.addListener(() {
      if (_phoneError != null && _phoneController.text.isNotEmpty) {
        setState(() => _phoneError = null);
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    final args = ModalRoute.of(context)?.settings.arguments as SignupArgs?;
    if (args == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing signup session. Please login again.')),
      );
      return;
    }

    // Validate all fields
    final firstNameError = Validators.firstName(_firstNameController.text);
    final lastNameError = Validators.lastName(_lastNameController.text);
    final phoneError = Validators.phoneNumber(_phoneController.text);

    setState(() {
      _firstNameError = firstNameError;
      _lastNameError = lastNameError;
      _phoneError = phoneError;
    });

    // Only proceed if all validations pass
    if (firstNameError == null && lastNameError == null && phoneError == null) {
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
      // Format phone with country code: "+91 9876543210"
      final phone = PhoneFieldWithCountryPicker.formatPhoneForStorage(
        _selectedCountry,
        _phoneController.text.trim(),
      );

      setState(() => _isSubmitting = true);
      try {
        await context.read<AuthProvider>().completeCustomerRegistration(
              sessionToken: args.sessionToken,
              fullName: fullName,
              phone: phone,
            );

        if (!mounted) return;
        Navigator.of(context).pushNamed(AppRoutes.profilePhoto);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
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
                        'Join the fresh side!',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign up and make laundry effortless.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AuthColors.primary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const LabeledDivider(label: 'First Name'),
                      const SizedBox(height: 10),
                      PillTextField(
                        controller: _firstNameController,
                        hintText: 'Enter your first name',
                        errorText: _firstNameError,
                      ),
                      const SizedBox(height: 14),
                      const LabeledDivider(label: 'Last Name'),
                      const SizedBox(height: 10),
                      PillTextField(
                        controller: _lastNameController,
                        hintText: 'Enter your Last name',
                        errorText: _lastNameError,
                      ),
                      const SizedBox(height: 14),
                      const LabeledDivider(label: 'Phone No'),
                      const SizedBox(height: 10),
                      PhoneFieldWithCountryPicker(
                        controller: _phoneController,
                        hintText: 'Enter your phone number',
                        errorText: _phoneError,
                        initialCountry: _selectedCountry,
                        onCountryChanged: (Country country) {
                          setState(() {
                            _selectedCountry = country;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: 'Next',
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                          // Clear errors when user clicks next
                          setState(() {
                            _firstNameError = null;
                            _lastNameError = null;
                            _phoneError = null;
                          });
                          await _handleNext();
                        },
                      ),
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


