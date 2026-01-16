import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../routes/app_routes.dart';
import 'widgets/auth_colors.dart';
import 'widgets/auth_illustration.dart';
import 'widgets/primary_button.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isLoading = false;
  bool _permissionGranted = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // Check permission status when screen loads
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.location.status;
    if (status.isGranted) {
      // Verify location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        setState(() {
          _permissionGranted = true;
        });
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      setState(() => _isLoading = true);

      // Always check current status first
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
        setState(() => _isLoading = false);
        // Optionally open app settings
        await openAppSettings();
        return;
      }

      // Always call request() - this will show the system popup if permission is not granted
      // If already granted, it will return granted status without showing popup again
      // But we still call it to ensure the flow is consistent
      PermissionStatus status = await Permission.location.request();
      
      // Handle the response
      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required. Please allow location access.'),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      if (status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permission is permanently denied. Please enable it in app settings.'),
            ),
          );
        }
        setState(() => _isLoading = false);
        await openAppSettings();
        return;
      }

      // Permission granted (either newly granted or already granted)
      if (status.isGranted) {
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Location services are disabled. Please enable them in device settings.'),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // Verify permission by getting current location
        try {
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 5),
          );
          setState(() {
            _permissionGranted = true;
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission granted!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error getting location: ${e.toString()}'),
              ),
            );
          }
        }
      } else {
        // Handle any other status
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get location permission. Please try again.'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permission: ${e.toString()}'),
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
                        'Help us reach you',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Turn on location so our delivery partners\ncan find you easily.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AuthColors.primary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 26),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border:
                              Border.all(color: AuthColors.primary, width: 1.6),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 38,
                              color: Color(0xFF8B90A4),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Allow your Location',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8B90A4),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: 120,
                              height: 42,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _requestLocationPermission,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _permissionGranted
                                      ? Colors.green
                                      : AuthColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _permissionGranted
                                                ? Icons.check_circle
                                                : Icons.location_on,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              _permissionGranted ? 'Allowed' : 'Allow',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      PrimaryButton(
                        label: 'Done',
                        isLoading: _isNavigating,
                        onPressed: _isNavigating
                            ? null
                            : () async {
                                setState(() => _isNavigating = true);
                                // Clear auth stack so back can never return to auth screens.
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppRoutes.shell,
                                  (route) => false,
                                );
                              },
                      ),
                      const SizedBox(height: 6),
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


