import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../services/customer_info_service.dart';
import '../../routes/app_routes.dart';
import '../../utils/location_error_messages.dart';
import '../auth/widgets/auth_colors.dart';
import '../auth/widgets/labeled_divider.dart';
import '../auth/widgets/pill_text_field.dart';
import '../auth/widgets/primary_button.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  final _deliveryNoteController = TextEditingController();
  final _customerInfoService = CustomerInfoService();
  
  double? _latitude;
  double? _longitude;
  String? _initialAddress;
  bool _isDefault = false;
  bool _isLoading = false;
  String? _labelError;
  String? _addressError;
  String? _addressId;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    // Clear errors when user starts typing
    _labelController.addListener(() {
      if (_labelError != null && _labelController.text.isNotEmpty) {
        setState(() => _labelError = null);
      }
    });
    _addressController.addListener(() {
      if (_addressError != null && _addressController.text.isNotEmpty) {
        setState(() => _addressError = null);
      }
    });
    // Get arguments from previous screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _isEditMode = args['isEdit'] as bool? ?? false;
          _addressId = args['addressId'] as String?;
          
          if (_isEditMode && _addressId != null) {
            // Edit mode: populate fields from existing address
            _labelController.text = args['addressLabel'] as String? ?? '';
            _addressController.text = args['fullAddress'] as String? ?? '';
            _deliveryNoteController.text = args['deliveryNote'] as String? ?? '';
            _isDefault = args['isDefault'] as bool? ?? false;
            _latitude = args['latitude'] as double?;
            _longitude = args['longitude'] as double?;
            _initialAddress = args['fullAddress'] as String?;
          } else {
            // Add mode: populate from map picker
            _latitude = args['latitude'] as double?;
            _longitude = args['longitude'] as double?;
            _initialAddress = args['address'] as String?;
            _addressController.text = _initialAddress ?? '';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _deliveryNoteController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    // Validate fields
    String? labelError;
    String? addressError;

    if (_labelController.text.trim().isEmpty) {
      labelError = 'Address label is required';
    } else if (_labelController.text.trim().length > 50) {
      labelError = 'Address label must be 50 characters or less';
    }

    if (_addressController.text.trim().isEmpty) {
      addressError = 'Full address is required';
    } else if (_addressController.text.trim().length < 3) {
      addressError = 'Address must be at least 3 characters';
    }

    if (labelError != null || addressError != null) {
      setState(() {
        _labelError = labelError;
        _addressError = addressError;
      });
      return;
    }

    // For new addresses, latitude and longitude are required
    if (!_isEditMode && (_latitude == null || _longitude == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditMode && _addressId != null) {
        // Update existing address
        await _customerInfoService.updateAddress(
          addressId: _addressId!,
          addressLabel: _labelController.text.trim(),
          fullAddress: _addressController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          isDefault: _isDefault,
          deliveryNote: _deliveryNoteController.text.trim().isEmpty 
              ? null 
              : _deliveryNoteController.text.trim(),
        );
      } else {
        // Create new address
        await _customerInfoService.createAddress(
          addressLabel: _labelController.text.trim(),
          fullAddress: _addressController.text.trim(),
          latitude: _latitude!,
          longitude: _longitude!,
          isDefault: _isDefault,
          deliveryNote: _deliveryNoteController.text.trim().isEmpty 
              ? null 
              : _deliveryNoteController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditMode ? 'Address updated successfully' : 'Address saved successfully')),
        );
        // Navigate back to select location screen
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        final message = LocationErrorMessages.getAddressErrorMessage(
          e,
          operation: _isEditMode ? 'update address' : 'save address',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Bar
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios),
                              onPressed: () => Navigator.of(context).pop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isEditMode ? 'Edit Address' : 'Add Address',
                                // Match header sizing used across screens like Orders/Cart.
                                style: AppTextStyles.header(color: Colors.black).copyWith(
                                  fontSize: 20,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Save your address for quick checkout',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AuthColors.primary,
                          ),
                        ),
                        const SizedBox(height: 22),
                        // Address Label
                        const LabeledDivider(label: 'Address Label'),
                        const SizedBox(height: 10),
                        PillTextField(
                          controller: _labelController,
                          hintText: 'e.g., Home, Work, Office',
                          errorText: _labelError,
                        ),
                        const SizedBox(height: 14),
                        // Full Address
                        const LabeledDivider(label: 'Full Address'),
                        const SizedBox(height: 10),
                        _MultiLineTextField(
                          controller: _addressController,
                          hintText: 'Enter complete address',
                          maxLines: 3,
                          errorText: _addressError,
                        ),
                        const SizedBox(height: 14),
                        // Delivery Note (Optional)
                        const LabeledDivider(label: 'Delivery Note (Optional)'),
                        const SizedBox(height: 10),
                        _MultiLineTextField(
                          controller: _deliveryNoteController,
                          hintText: 'Any special instructions for delivery',
                          maxLines: 2,
                          maxLength: 500,
                        ),
                        const SizedBox(height: 18),
                        // Set as Default
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AuthColors.border,
                              width: 1.6,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Set as Default Address',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Use this address for future orders',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isDefault,
                                onChanged: (value) {
                                  setState(() {
                                    _isDefault = value;
                                  });
                                },
                                activeColor: AuthColors.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Change Location Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () async {
                              final result = await Navigator.of(context).pushNamed(
                                AppRoutes.mapPicker,
                                arguments: {
                                  'latitude': _latitude,
                                  'longitude': _longitude,
                                  'address': _addressController.text,
                                },
                              );
                              if (result != null && mounted) {
                                final resultMap = result as Map<String, dynamic>;
                                setState(() {
                                  _latitude = resultMap['latitude'] as double?;
                                  _longitude = resultMap['longitude'] as double?;
                                  _addressController.text = resultMap['address'] as String? ?? '';
                                });
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AuthColors.border,
                                width: 1.6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              'Change Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AuthColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Save Button
                        PrimaryButton(
                          label: _isEditMode ? 'Update Address' : 'Save Address',
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : () async {
                            // Clear errors when user clicks save
                            setState(() {
                              _labelError = null;
                              _addressError = null;
                            });
                            await _saveAddress();
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
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

class _MultiLineTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final int? maxLength;
  final String? errorText;

  const _MultiLineTextField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.maxLength,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFB8BDCF),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AuthColors.border,
                width: 1.6,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AuthColors.border,
                width: 1.6,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AuthColors.border,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 1.6),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
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
