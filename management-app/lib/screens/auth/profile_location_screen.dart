import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../routes/app_routes.dart';
import 'verification_in_progress_screen.dart';

class ProfileLocationScreen extends StatefulWidget {
  const ProfileLocationScreen({super.key});

  @override
  State<ProfileLocationScreen> createState() => _ProfileLocationScreenState();
}

class _ProfileLocationScreenState extends State<ProfileLocationScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  bool _isLoadingImage = false;
  bool _isLoadingLocation = false;
  bool _locationAllowed = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoadingImage = true);

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
          setState(() => _isLoadingImage = false);
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
          setState(() => _isLoadingImage = false);
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
          _profileImage = File(image.path);
          _isLoadingImage = false;
        });
      } else {
        setState(() => _isLoadingImage = false);
      }
    } catch (e) {
      setState(() => _isLoadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      setState(() => _isLoadingLocation = true);

      // Check current permission status first
      PermissionStatus currentStatus = await Permission.location.status;
      
      // If permanently denied, guide user to settings
      if (currentStatus.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permission is permanently denied. Please enable it in app settings.'),
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        // Optionally open app settings
        await openAppSettings();
        return;
      }

      // Request permission - this will show the system dialog if not granted
      PermissionStatus status = await Permission.location.request();

      // Verify permission status after user interaction
      // Re-check status to ensure it's up to date
      final verifiedStatus = await Permission.location.status;
      
      if (verifiedStatus.isPermanentlyDenied) {
        setState(() => _isLoadingLocation = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permission is permanently denied. Please enable it in app settings.'),
            ),
          );
        }
        await openAppSettings();
        return;
      }

      if (!verifiedStatus.isGranted) {
        setState(() => _isLoadingLocation = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Location permission is required. Please allow access.'),
            ),
          );
        }
        return;
      }

      // Permission is granted - update state immediately
      if (mounted) {
        setState(() {
          _locationAllowed = true;
        });
      }

      // Verify location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Try to get current position to verify everything works
      try {
        await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        // Even if getting position fails (timeout, GPS issues), 
        // permission is still granted, so we keep _locationAllowed = true
        // Just log the error but don't change the permission status
        debugPrint('Error getting location: $e');
      }

      // Update loading state
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      debugPrint('Error requesting location: $e');
    }
  }

  Future<void> _handleNext() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const VerificationInProgressDialog(),
    );
    if (!mounted) return;
    if (result == true) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.registerSuccess);
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 18),
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
                        'Upload your pic',
                        style: AppTextStyles.header(
                                color: AppColors.textPrimary)
                            .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 140),
                        padding: _profileImage != null
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
                        child: _profileImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: Image.file(
                                  _profileImage!,
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
                                    'Upload your Profile Picture',
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
                              onPressed: _isLoadingImage
                                  ? null
                                  : () => _pickImage(ImageSource.camera),
                              icon: _isLoadingImage
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
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoadingImage
                                  ? null
                                  : () => _pickImage(ImageSource.gallery),
                              icon: _isLoadingImage
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
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Allow Location Access',
                        style: AppTextStyles.header(
                                color: AppColors.textPrimary)
                            .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 26),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.6,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 34,
                              color: Color(0xFF8B90A4),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Allow your Location',
                              style: AppTextStyles.body(
                                      color: const Color(0xFF8B90A4))
                                  .copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: 120,
                              height: 42,
                              child: ElevatedButton(
                                onPressed: _isLoadingLocation
                                    ? null
                                    : _requestLocationPermission,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _locationAllowed
                                      ? Colors.green
                                      : AppColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                                child: _isLoadingLocation
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        _locationAllowed ? 'Allowed' : 'Allow',
                                        style: AppTextStyles.button(
                                                color: Colors.white)
                                            .copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
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


