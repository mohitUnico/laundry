import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../utils/validators.dart';
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
  
  String? _firstNameError;
  String? _lastNameError;
  String? _phoneError;

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

  void _handleNext() {
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
      Navigator.of(context).pushNamed(AppRoutes.profilePhoto);
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
                      PillTextField(
                        controller: _phoneController,
                        hintText: 'Enter your phone number',
                        keyboardType: TextInputType.phone,
                        errorText: _phoneError,
                      ),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: 'Next',
                        onPressed: () {
                          // Clear errors when user clicks next
                          setState(() {
                            _firstNameError = null;
                            _lastNameError = null;
                            _phoneError = null;
                          });
                          _handleNext();
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


