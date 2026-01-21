import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/phone_field_with_country_picker.dart';
import '../../utils/profile_service_error_messages.dart';
import '../home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 16),
        child: EditProfileDialog(),
      ),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();

  File? _selectedImage;
  bool _saving = false;
  Country? _selectedCountry;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController.text = auth.displayName == 'Guest' ? '' : auth.displayName;
    _emailController.text = auth.displayEmail;
    
    // Parse phone number to extract country code and phone number
    final phoneFromAuth = auth.displayPhone;
    final parsed = PhoneFieldWithCountryPicker.parsePhoneNumber(phoneFromAuth);
    _selectedCountry = parsed[0] as Country;
    _phoneController.text = parsed[1] as String;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<bool> _ensurePermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      return status.isGranted;
    }

    final status = await Permission.photos.request();
    return status.isGranted;
  }

  Future<void> _pick(ImageSource source) async {
    final ok = await _ensurePermission(source);
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission is required to select a photo')),
        );
      }
      return;
    }

    final x = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (x == null) return;
    setState(() => _selectedImage = File(x.path));
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final auth = context.read<AuthProvider>();

    try {
      // Update photo (uses existing backend endpoint already wired)
      final img = _selectedImage;
      if (img != null) {
        await auth.uploadProfileImage(img);
      }

      // Format phone with country code before saving
      final formattedPhone = PhoneFieldWithCountryPicker.formatPhoneForStorage(
        _selectedCountry ?? Country.parse('IN'),
        _phoneController.text.trim(),
      );
      
      // Persist name/phone to backend and update global state from response.
      await auth.updateProfileRemote(
        fullName: _nameController.text.trim(),
        phone: formattedPhone,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final message = ProfileServiceErrorMessages.getProfileErrorMessage(
        e,
        operation: 'update profile',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final imageUrl = auth.profileImageUrl;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HomeColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Edit Profile',
                  style: AppTextStyles.header(color: HomeColors.text),
                ),
              ),
              InkWell(
                onTap: _saving ? null : () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF1FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.close_rounded, size: 18),
                ),
              )
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: HomeColors.borderSoft),
                    color: const Color(0xFFEFF1FF),
                  ),
                  child: ClipOval(
                    child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
                        : (imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/icons/profile_pic_demo.png',
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                            : Image.asset(
                                'assets/icons/profile_pic_demo.png',
                                fit: BoxFit.cover,
                              )),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: InkWell(
                    onTap: _saving
                        ? null
                        : () async {
                            await showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (_) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(18),
                                      topRight: Radius.circular(18),
                                    ),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE5E7EB),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                                await _pick(ImageSource.camera);
                                              },
                                              icon: const Icon(Icons.photo_camera_outlined, size: 16),
                                              label: const Text('Camera'),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                                await _pick(ImageSource.gallery);
                                              },
                                              icon: const Icon(Icons.photo_library_outlined, size: 16),
                                              label: const Text('Gallery'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: HomeColors.primary,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: 'Full Name',
            controller: _nameController,
            hintText: 'Enter your name',
            enabled: !_saving,
          ),
          const SizedBox(height: 10),
          _LabeledField(
            label: 'Email',
            controller: _emailController,
            hintText: 'Email',
            enabled: false,
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone',
                style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 11),
              ),
              const SizedBox(height: 6),
                      PhoneFieldWithCountryPicker(
                        controller: _phoneController,
                        hintText: 'Enter phone number',
                        enabled: !_saving,
                        initialCountry: _selectedCountry,
                        onCountryChanged: (Country country) {
                          setState(() {
                            _selectedCountry = country;
                          });
                        },
                      ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HomeColors.text,
                    side: const BorderSide(color: HomeColors.borderSoft),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Cancel', style: AppTextStyles.button(color: HomeColors.text)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HomeColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Save', style: AppTextStyles.button(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool enabled;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 11),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: const Color(0xFFF8FAFF),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: HomeColors.borderSoft),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: HomeColors.borderSoft),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: HomeColors.primary, width: 1.6),
            ),
          ),
          style: AppTextStyles.listItemTitle(color: HomeColors.text).copyWith(fontSize: 13),
        ),
      ],
    );
  }
}


