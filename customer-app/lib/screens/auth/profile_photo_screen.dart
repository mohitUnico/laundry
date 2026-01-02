import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../routes/app_routes.dart';
import 'widgets/auth_colors.dart';
import 'widgets/auth_illustration.dart';
import 'widgets/primary_button.dart';

class ProfilePhotoScreen extends StatefulWidget {
  const ProfilePhotoScreen({super.key});

  @override
  State<ProfilePhotoScreen> createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);

      // Request permission based on source
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
        // Request photos permission (permission_handler handles Android version differences)
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
          _selectedImage = File(image.path);
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
      backgroundColor: AuthColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(AppRoutes.locationPermission),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8B90A4),
                  ),
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(child: AuthIllustration()),
                            const SizedBox(height: 18),
                            const Text(
                              'Show your best smile!',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add your profile photo so we can serve\nyou better.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AuthColors.primary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 18),
                            GestureDetector(
                              onTap: () => _pickImage(ImageSource.gallery),
                              child: Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(
                                  minHeight: 120,
                                ),
                                padding: _selectedImage != null
                                    ? EdgeInsets.zero
                                    : const EdgeInsets.symmetric(vertical: 26),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: AuthColors.primary,
                                    width: 1.6,
                                  ),
                                ),
                                child: _selectedImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(26),
                                        child: Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 200,
                                        ),
                                      )
                                    : const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.upload_rounded,
                                            size: 34,
                                            color: Color(0xFF8B90A4),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            'Upload your Profile Picture',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF8B90A4),
                                            ),
                                          ),
                                        ],
                                      ),
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
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.photo_camera_outlined,
                                            size: 16,
                                          ),
                                    label: const Text('Take a Picture'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AuthColors.primary,
                                      side: const BorderSide(
                                        color: AuthColors.primary,
                                        width: 1.4,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
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
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.photo_library_outlined,
                                            size: 16,
                                          ),
                                    label: const Text('Upload from Gallery'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AuthColors.primary,
                                      side: const BorderSide(
                                        color: AuthColors.primary,
                                        width: 1.4,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            PrimaryButton(
                              label: 'Next',
                              onPressed: () {
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.locationPermission);
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


