import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../services/customer_info_service.dart';
import '../../routes/app_routes.dart';

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

  @override
  void initState() {
    super.initState();
    // Get arguments from previous screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _latitude = args['latitude'] as double?;
          _longitude = args['longitude'] as double?;
          _initialAddress = args['address'] as String?;
          _addressController.text = _initialAddress ?? '';
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address saved successfully')),
        );
        // Navigate back to select location screen
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save address: ${e.toString()}')),
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
      backgroundColor: const Color(0xFFF3F4F7),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Add Address',
                      style: AppTextStyles.header(color: const Color(0xFF1B1F2A)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Address Label
                      Text(
                        'Address Label',
                        style: AppTextStyles.body(color: const Color(0xFF1B1F2A)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _labelController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Home, Work, Office',
                          hintStyle: AppTextStyles.body(color: const Color(0xFF98A0B5)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE9ECF3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE9ECF3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2C3CA5), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        style: AppTextStyles.body(color: const Color(0xFF1B1F2A)),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Address label is required';
                          }
                          if (value.trim().length > 50) {
                            return 'Address label must be 50 characters or less';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Full Address
                      Text(
                        'Full Address',
                        style: AppTextStyles.body(color: const Color(0xFF1B1F2A)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter complete address',
                          hintStyle: AppTextStyles.body(color: const Color(0xFF98A0B5)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE9ECF3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE9ECF3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2C3CA5), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        style: AppTextStyles.body(color: const Color(0xFF1B1F2A)),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Full address is required';
                          }
                          if (value.trim().length < 3) {
                            return 'Address must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Delivery Note (Optional)
                      Text(
                        'Delivery Note (Optional)',
                        style: AppTextStyles.body(color: const Color(0xFF1B1F2A)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _deliveryNoteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Any special instructions for delivery',
                          hintStyle: AppTextStyles.body(color: const Color(0xFF98A0B5)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE9ECF3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE9ECF3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2C3CA5), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        style: AppTextStyles.body(color: const Color(0xFF1B1F2A)),
                        maxLength: 500,
                      ),
                      const SizedBox(height: 20),
                      // Set as Default
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE9ECF3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Set as Default Address',
                                    style: AppTextStyles.header(color: const Color(0xFF1B1F2A)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Use this address for future orders',
                                    style: AppTextStyles.body(color: const Color(0xFF7B8296)),
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
                              activeColor: const Color(0xFF2C3CA5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveAddress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C3CA5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: const Color(0xFF98A0B5),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Save Address',
                                  style: AppTextStyles.header(color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

