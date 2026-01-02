import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../utils/role_manager.dart';

class AddressAndIdScreen extends StatefulWidget {
  const AddressAndIdScreen({super.key});

  @override
  State<AddressAndIdScreen> createState() => _AddressAndIdScreenState();
}

class _AddressAndIdScreenState extends State<AddressAndIdScreen> {
  final _addressController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _idProofImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);

      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Camera permission is required to take photos'),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      } else {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo library permission is required'),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _idProofImage = File(image.path);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
          ),
        );
      }
    }
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
                          height: 280,
                          child: Image.asset(
                            'assets/images/auth/registration.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Add your Address',
                        style: AppTextStyles.header(
                                color: AppColors.textPrimary)
                            .copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Enter Your Address',
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primary, width: 1.6),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primary, width: 2.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Submit ID Proof',
                        style: AppTextStyles.header(
                                color: AppColors.textPrimary)
                            .copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 120),
                        padding: _idProofImage != null
                            ? EdgeInsets.zero
                            : const EdgeInsets.symmetric(vertical: 26),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.6,
                          ),
                        ),
                        child: _idProofImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: Image.file(
                                  _idProofImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.upload_rounded,
                                    size: 34,
                                    color: Color(0xFF8B90A4),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Upload your ID Proof',
                                    style: AppTextStyles.body(
                                            color: const Color(0xFF8B90A4))
                                        .copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () => _pickImage(ImageSource.camera),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child:
                                          CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(
                                      Icons.photo_camera_outlined,
                                      size: 16,
                                    ),
                              label: Text(
                                'Take a Picture',
                                style: AppTextStyles.button(
                                        color: AppColors.primary)
                                    .copyWith(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () => _pickImage(ImageSource.gallery),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child:
                                          CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(
                                      Icons.photo_library_outlined,
                                      size: 16,
                                    ),
                              label: Text(
                                'Upload from Gallery',
                                style: AppTextStyles.button(
                                        color: AppColors.primary)
                                    .copyWith(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Check role and navigate accordingly
                            final isDelivery = await RoleManager.isDeliveryPartner();
                            if (isDelivery) {
                              // Delivery partners need driving license
                              Navigator.of(context)
                                  .pushNamed(AppRoutes.drivingLicense);
                            } else {
                              // Other roles skip driving license and go to profile location
                              Navigator.of(context)
                                  .pushNamed(AppRoutes.profileLocation);
                            }
                          },
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
                                'Next',
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
