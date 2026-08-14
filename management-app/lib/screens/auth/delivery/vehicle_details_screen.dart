import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/constants.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/pill_text_field.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final _vehicleNumberController = TextEditingController();

  final Map<String, String> _vehicleTypes = const {
    AppConstants.vehicleTypeBike: 'Bike',
    AppConstants.vehicleTypeScooter: 'Scooter',
    AppConstants.vehicleTypeCar: 'Car',
  };

  String? _selectedVehicleType;
  String? _vehicleNumberError;
  String? _vehicleTypeError;

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    super.dispose();
  }

  void _handleNext() {
    FocusScope.of(context).unfocus();

    final vehicleNumber = _vehicleNumberController.text.trim();
    final vehicleType = _selectedVehicleType;

    final vehicleNumberError =
        vehicleNumber.isEmpty ? 'Vehicle number is required' : null;
    final vehicleTypeError =
        vehicleType == null ? 'Vehicle type is required' : null;

    setState(() {
      _vehicleNumberError = vehicleNumberError;
      _vehicleTypeError = vehicleTypeError;
    });

    if (vehicleNumberError != null || vehicleTypeError != null) return;

    context.read<AuthProvider>().updateDeliveryVehicleDetails(
          vehicleType: vehicleType!,
          vehicleNumber: vehicleNumber,
        );

    Navigator.of(context).pushNamed(AppRoutes.drivingLicense);
  }

  @override
  Widget build(BuildContext context) {
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: SizedBox(
                          height: 240,
                          child: Image.asset(
                            'assets/images/auth/registration.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Vehicle Details',
                        style: AppTextStyles.header(color: AppColors.textPrimary)
                            .copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Make your vehicle easy to identify',
                        style:
                            AppTextStyles.body(color: AppColors.textSecondary)
                                .copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _FieldLabel(text: 'Vehicle Number'),
                      const SizedBox(height: 8),
                      PillTextField(
                        controller: _vehicleNumberController,
                        hintText: 'Enter your vehicle number',
                        errorText: _vehicleNumberError,
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel(text: 'Vehicle Type'),
                      const SizedBox(height: 8),
                      _PillDropdownField(
                        value: _selectedVehicleType,
                        hintText: 'Choose the vehicle type',
                        items: _vehicleTypes,
                        errorText: _vehicleTypeError,
                        onChanged: (value) {
                          setState(() {
                            _selectedVehicleType = value;
                            _vehicleTypeError = null;
                          });
                        },
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _handleNext,
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
                                colors: [
                                  Color(0xFF2437B6),
                                  Color(0xFF2C3CA5),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Next',
                                style:
                                    AppTextStyles.button(color: Colors.white)
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

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.body(color: AppColors.textPrimary).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PillDropdownField extends StatelessWidget {
  final String? value;
  final String hintText;
  final Map<String, String> items;
  final String? errorText;
  final ValueChanged<String?> onChanged;

  const _PillDropdownField({
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(
        color: hasError ? Colors.red : AppColors.primary,
        width: 1.6,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .entries
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: AppTextStyles.body(color: AppColors.textPrimary)
                        .copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFB8BDCF),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppColors.primary,
                width: 2.0,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}


