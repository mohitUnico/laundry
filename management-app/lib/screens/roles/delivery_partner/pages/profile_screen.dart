import 'package:flutter/material.dart';

import '../../../../routes/app_routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../utils/auth_storage.dart';
import '../../../../utils/role_manager.dart';
import '../../../../utils/role_constants.dart';
import '../../../../services/delivery_staff_app_service.dart';
import '../../../common/widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBottomNav;

  const ProfileScreen({
    super.key,
    this.showBottomNav = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DeliveryStaffAppService _deliveryStaffAppService = DeliveryStaffAppService();
  late final Future<Map<String, dynamic>?> _profileFuture;
  late final Future<_HomeStatsUi> _statsFuture;

  static String _readString(Map<String, dynamic>? map, String key) {
    final v = map?[key];
    return v == null ? '' : v.toString().trim();
  }

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    _statsFuture = _loadStats();
  }

  Future<_HomeStatsUi> _loadStats() async {
    try {
      final body = await _deliveryStaffAppService.getHomeStats();
      final data = body['data'];
      if (data is! Map) return const _HomeStatsUi(inProgress: 0, completed: 0);
      final map = data.cast<String, dynamic>();
      final inProgressRaw = map['inProgress'];
      final completedRaw = map['completed'];
      final inProgress =
          (inProgressRaw is num) ? inProgressRaw.toInt() : int.tryParse(inProgressRaw?.toString() ?? '') ?? 0;
      final completed =
          (completedRaw is num) ? completedRaw.toInt() : int.tryParse(completedRaw?.toString() ?? '') ?? 0;
      return _HomeStatsUi(inProgress: inProgress, completed: completed);
    } catch (_) {
      return const _HomeStatsUi(inProgress: 0, completed: 0);
    }
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    // 1) Try network (most accurate)
    try {
      final body = await _deliveryStaffAppService.getProfile();
      final data = body['data'];
      if (data is Map) {
        final profile = data.cast<String, dynamic>();
        // Persist for other screens and offline use.
        await Future.wait([
          AuthStorage.saveDeliveryStaff(profile),
          AuthStorage.saveCurrentUser(profile),
        ]);
        return profile;
      }
    } catch (_) {
      // ignore and fallback to storage
    }

    // 2) Fallback to storage
    final stored = await AuthStorage.getDeliveryStaff();
    return stored ?? await AuthStorage.getCurrentUser();
  }

  Future<void> _logout(BuildContext context) async {
    final role = await RoleManager.getRole();
    await Future.wait([
      RoleManager.clearRole(),
      AuthStorage.clearAll(),
    ]);

    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
      arguments: {'role': role ?? RoleConstants.deliveryPartner},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;

            final staffId = _readString(user, 'staff_id').isNotEmpty ? _readString(user, 'staff_id') : _readString(user, 'userId');
            final fullName = _readString(user, 'full_name').isNotEmpty ? _readString(user, 'full_name') : _readString(user, 'fullName');

            final phone = _readString(user, 'phone');
            final email = _readString(user, 'email');
            final address = _readString(user, 'address');
            final vehicleType = _readString(user, 'vehicle_type');
            final vehicleNumber = _readString(user, 'vehicle_number');

            final verificationStatus = _readString(user, 'verification_status');
            final isVerifiedByAdmin = _readString(user, 'is_verified_by_admin');
            final totalDeliveries = _readString(user, 'total_deliveries');
            final averageRating = _readString(user, 'average_rating');

            final profileImageUrl = _readString(user, 'profile_image_url');
            final idProofType = _readString(user, 'id_proof_type');
            final idProofUrl = _readString(user, 'id_proof_url');
            final drivingLicenseUrl = _readString(user, 'driving_license_url');

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                children: [
                  _AccountHeader(),
                  Expanded(child: Center(child: CircularProgressIndicator())),
                ],
              );
            }

            return Column(
              children: [
                const _AccountHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const SizedBox(height: 16),
                      _AccountSummaryCard(
                        staffId: staffId,
                        fullName: fullName,
                        phone: phone,
                        email: email,
                        profileImageUrl: profileImageUrl,
                        totalDeliveries: totalDeliveries,
                        averageRating: averageRating,
                        verificationStatus: verificationStatus,
                        isVerifiedByAdmin: isVerifiedByAdmin,
                        statsFuture: _statsFuture,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            onPressed: () => _logout(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.logout, color: AppColors.error, size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  'Log Out',
                                  style: AppTextStyles.button(color: AppColors.error).copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle('Account Details'),
                      const SizedBox(height: 16),
                      _AccountDetailItem(
                        icon: Icons.phone_outlined,
                        label: 'Phone Number',
                        value: phone.isNotEmpty ? phone : '—',
                      ),
                      const SizedBox(height: 16),
                      _AccountDetailItem(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: email.isNotEmpty ? email : '—',
                      ),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _AccountDetailItem(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: address,
                        ),
                      ],
                      if (vehicleType.isNotEmpty || vehicleNumber.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _AccountDetailItem(
                          icon: Icons.directions_bike_outlined,
                          label: 'Vehicle',
                          value: [vehicleType, vehicleNumber].where((s) => s.isNotEmpty).join(' • '),
                        ),
                      ],
                      // Verification intentionally hidden from UI (still stored in profile JSON).
                      const SizedBox(height: 24),
                      const _SectionTitle('Uploaded Documents'),
                      const SizedBox(height: 16),
                      _DocumentCard(
                        imagePath: 'assets/images/documents/aadhaar.png',
                        title: 'ID Proof',
                        subtitle: idProofType.isNotEmpty
                            ? idProofType
                            : (idProofUrl.isNotEmpty ? 'Uploaded' : 'Not uploaded'),
                      ),
                      const SizedBox(height: 12),
                      _DocumentCard(
                        imagePath: 'assets/images/documents/driving_license.png',
                        title: 'Driving License',
                        subtitle: drivingLicenseUrl.isNotEmpty ? 'Uploaded' : 'Not uploaded',
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavBar(
              currentIndex: 3,
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                    break;
                  case 1:
                    Navigator.pushReplacementNamed(context, AppRoutes.orders);
                    break;
                  case 2:
                    Navigator.pushReplacementNamed(context, AppRoutes.help);
                    break;
                  case 3:
                    break;
                }
              },
            )
          : null,
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            splashRadius: 20,
          ),
          Text(
            'Account',
            style: AppTextStyles.title(
              color: AppColors.textPrimary,
            ).copyWith(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: () {
              // TODO: Show options menu
            },
            icon: const Icon(Icons.more_vert, size: 20),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _AccountSummaryCard extends StatelessWidget {
  final String staffId;
  final String fullName;
  final String phone;
  final String email;
  final String profileImageUrl;
  final String totalDeliveries;
  final String averageRating;
  final String verificationStatus;
  final String isVerifiedByAdmin;
  final Future<_HomeStatsUi> statsFuture;

  const _AccountSummaryCard({
    required this.staffId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.profileImageUrl,
    required this.totalDeliveries,
    required this.averageRating,
    required this.verificationStatus,
    required this.isVerifiedByAdmin,
    required this.statsFuture,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = <String>[
      if (phone.isNotEmpty) phone,
      if (email.isNotEmpty) email,
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture (use uploaded URL if available)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: (profileImageUrl.isNotEmpty && profileImageUrl.startsWith('http'))
                  ? Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Name
          Text(
            fullName.isNotEmpty ? fullName : '—',
            style: AppTextStyles.title(
              color: AppColors.textPrimary,
            ).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          // ID (scrollable)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ID: ',
                style: AppTextStyles.subtitle(
                  color: AppColors.textSecondary,
                ).copyWith(fontSize: 13),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: staffId.isNotEmpty
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          staffId,
                          maxLines: 1,
                          softWrap: false,
                          style: AppTextStyles.subtitle(
                            color: AppColors.textSecondary,
                          ).copyWith(fontSize: 13),
                        ),
                      )
                    : Text(
                        '—',
                        style: AppTextStyles.subtitle(
                          color: AppColors.textSecondary,
                        ).copyWith(fontSize: 13),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (secondary.isNotEmpty) ...[
            Text(
              secondary,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle(color: AppColors.textSecondary).copyWith(fontSize: 12),
            ),
            const SizedBox(height: 12),
          ] else ...[
            const SizedBox(height: 12),
          ],
          FutureBuilder<_HomeStatsUi>(
            future: statsFuture,
            builder: (context, snapshot) {
              final stats = snapshot.data ?? const _HomeStatsUi(inProgress: 0, completed: 0);
              final widgets = <Widget>[
                _StatItem(value: '${stats.inProgress}', label: 'In Progress'),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.divider.withValues(alpha: 0.3),
                ),
                _StatItem(value: '${stats.completed}', label: 'Completed'),
              ];

              if (totalDeliveries.isNotEmpty) {
                widgets.addAll([
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.divider.withValues(alpha: 0.3),
                  ),
                  _StatItem(value: totalDeliveries, label: 'Total Deliveries'),
                ]);
              }
              if (averageRating.isNotEmpty) {
                widgets.addAll([
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.divider.withValues(alpha: 0.3),
                  ),
                  _StatItem(value: averageRating, label: 'Avg Rating'),
                ]);
              }
              // Verification intentionally hidden from UI.

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widgets
                      .map((w) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: w,
                          ))
                      .toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeStatsUi {
  final int inProgress;
  final int completed;

  const _HomeStatsUi({required this.inProgress, required this.completed});
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.title(
            color: AppColors.textPrimary,
          ).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.subtitle(
            color: AppColors.textSecondary,
          ).copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.title(
        color: AppColors.textPrimary,
      ).copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _AccountDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AccountDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.subtitle(
                  color: AppColors.textSecondary,
                ).copyWith(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.title(
                  color: AppColors.textPrimary,
                ).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;

  const _DocumentCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Document thumbnail
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.background,
                    child: const Icon(
                      Icons.description,
                      size: 30,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Document info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.title(
                    color: AppColors.textPrimary,
                  ).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.subtitle(
                      color: AppColors.textSecondary,
                    ).copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

