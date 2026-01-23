import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../routes/app_routes.dart';
import '../../../../providers/delivery_provider.dart';
import '../../../../utils/role_manager.dart';
import '../../../common/widgets/order_summary_card.dart';
import '../../../common/widgets/task_card.dart';
import '../../../common/widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0; // 0: Today's Tasks, 1: Completed
  int _bottomNavIndex = 0;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  // Profile Section
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icons/profile_pic_demo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, Nadaan',
                            style: AppTextStyles.title(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: AB1234',
                            style: AppTextStyles.subtitle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // End Shift Button
                  InkWell(
                    onTap: () async {
                      // Get role before clearing, then navigate to login with role argument
                      final role = await RoleManager.getRole();
                      await RoleManager.clearRole();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.login,
                          (route) => false,
                          arguments: {'role': role},
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(26),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: SizedBox(
                      height: 44,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/icons/home_screen/end_shift.png',
                                  width: 18,
                                  height: 18,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'End Shift',
                                  style: AppTextStyles.button(
                                    color: AppColors.error,
                                  ).copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 0,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0x00FF3B30),
                                    Color(0xFFFF3B30),
                                    Color(0x00FF3B30),
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Orders Summary Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orders',
                    style: AppTextStyles.header(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OrderSummaryCard(
                        label: 'In Progress',
                        count: 2,
                        iconAsset: 'assets/icons/home_screen/in_progress.png',
                      ),
                      const SizedBox(width: 12),
                      OrderSummaryCard(
                        label: 'Completed',
                        count: 26,
                        iconAsset: 'assets/icons/home_screen/completed.png',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Task Filter Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E0FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        label: "Today's Tasks",
                        isSelected: _selectedTabIndex == 0,
                        onTap: () => setState(() => _selectedTabIndex = 0),
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        label: 'Completed',
                        isSelected: _selectedTabIndex == 1,
                        onTap: () => setState(() => _selectedTabIndex = 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Task List
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildTodaysTasks()
                  : _buildCompletedTasks(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          setState(() => _bottomNavIndex = index);
          // Handle navigation
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.pushReplacementNamed(context, AppRoutes.orders);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, AppRoutes.help);
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.profile);
              break;
          }
        },
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF283897),
                      Color(0xFF0F73F7),
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.button(
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysTasks() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        GestureDetector(
          onTap: () => _showTaskDialog('Tom Cruise'),
          child: TaskCard(
            taskType: 'Pickup',
            scheduledTime: '10:00 AM',
            customerName: 'Tom Cruise',
            address: '123 MG Road, Bangalore...',
            phoneNumber: '+91 98456 32654',
            itemCount: 15,
            amount: '₹12.00',
            buttonText: 'Mark as Picked Up',
            iconPath: 'assets/icons/pickup.png',
            onButtonPressed: () => _showTaskDialog('Tom Cruise'),
            onMapPressed: () {
              // Handle map navigation
            },
          ),
        ),
        GestureDetector(
          onTap: () => _showTaskDialog('Brad Pitt'),
          child: TaskCard(
            taskType: 'Delivery',
            scheduledTime: '11:30 AM',
            customerName: 'Brad Pitt',
            address: '45 Park Street, Bangalore...',
            phoneNumber: '+91 98456 56489',
            itemCount: 12,
            amount: '₹15.00',
            buttonText: 'Start Delivery',
            iconPath: 'assets/icons/out_for_delivery.png',
            onButtonPressed: () => _showTaskDialog('Brad Pitt'),
            onMapPressed: () {
              // Handle map navigation
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedTasks() {
    return Center(
      child: Text(
        'No completed tasks',
        style: AppTextStyles.subtitle(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  void _showTaskDialog(String customerName) {
    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        XFile? pickedImage;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pickup Details',
                          style: AppTextStyles.header(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          splashRadius: 20,
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        text: 'Customer: ',
                        style: AppTextStyles.body(
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: customerName,
                            style: AppTextStyles.title(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Weight of Cloths (kg)*',
                      style: AppTextStyles.subtitle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter weight in kg',
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Upload Photo*',
                      style: AppTextStyles.subtitle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        final status = await Permission.camera.request();
                        if (!status.isGranted) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Camera permission is required to take photos'),
                              ),
                            );
                          }
                          return;
                        }
                        final image = await _imagePicker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                        );
                        if (image != null) {
                          setState(() => pickedImage = image);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Photo captured successfully'),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.divider.withOpacity(0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                  color:
                                      AppColors.divider.withOpacity(0.8),
                                ),
                              ),
                              child: Icon(
                                pickedImage == null
                                    ? Icons.photo_camera_outlined
                                    : Icons.check,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              pickedImage == null
                                  ? 'Take a Photo'
                                  : 'Photo Added',
                              style: AppTextStyles.subtitle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFF283897),
                              Color(0xFF0F73F7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(
                            'Confirm Pickup',
                            style: AppTextStyles.button(
                              color: Colors.white,
                            ).copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

