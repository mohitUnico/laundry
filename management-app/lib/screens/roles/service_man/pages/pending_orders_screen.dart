import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/role_manager.dart';

class PendingOrdersServicemenScreen extends StatefulWidget {
  const PendingOrdersServicemenScreen({super.key});

  @override
  State<PendingOrdersServicemenScreen> createState() => _PendingOrdersServicemenScreenState();
}

class _PendingOrdersServicemenScreenState extends State<PendingOrdersServicemenScreen> {
  int _selectedTabIndex = 0; // 0: Pending, 1: Completed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTabIndex,
          children: [
            _PendingOrdersView(),
            _CompletedOrdersView(),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedTabIndex,
        onTabSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
      ),
    );
  }
}

class _PendingOrdersView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
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
              // Log Out Button
              InkWell(
                onTap: () async {
                  // Clear role and navigate to login
                  await RoleManager.clearRole();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
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
                              'Log Out',
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
        // Title Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Center(
            child: Text(
              'Category: Wash & Fold',
              style: AppTextStyles.header(
                color: AppColors.textPrimary,
              ).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        // Orders List
        Expanded(
          child: _buildPendingOrdersList(),
        ),
      ],
    );
  }

  Widget _buildPendingOrdersList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      children: [
        _OrderCard(
          orderId: 'ORD033',
          customerName: 'Jim Hopper',
          date: '10-04-2025',
          time: '10:26 AM',
          itemCount: 15,
          items: const [
            _OrderItem(name: 'Top Wear', quantity: 5),
            _OrderItem(name: 'Bottom Wear', quantity: 6),
            _OrderItem(name: 'Kurta', quantity: 2),
            _OrderItem(name: 'Saree', quantity: 2),
          ],
          onInProgress: () {
            // Handle in-progress action
          },
          onMarkComplete: () {
            // Handle mark as complete action
          },
        ),
        const SizedBox(height: 12),
        _OrderCard(
          orderId: 'ORD035',
          customerName: 'Mike Wheelers',
          date: '10-04-2025',
          time: '11:16 AM',
          itemCount: 12,
          items: const [
            _OrderItem(name: 'Top Wear', quantity: 5),
            _OrderItem(name: 'Bottom Wear', quantity: 5),
            _OrderItem(name: 'Kurta', quantity: 2),
            _OrderItem(name: 'Saree', quantity: 3),
          ],
          onInProgress: () {
            // Handle in-progress action
          },
          onMarkComplete: () {
            // Handle mark as complete action
          },
        ),
        const SizedBox(height: 12),
        _OrderCard(
          orderId: 'ORD039',
          customerName: 'Joyce',
          date: '09-04-2025',
          time: '05:20 PM',
          itemCount: 08,
          items: const [
            _OrderItem(name: 'Top Wear', quantity: 3),
            _OrderItem(name: 'Bottom Wear', quantity: 3),
            _OrderItem(name: 'Kurta', quantity: 2),
          ],
          onInProgress: () {
            // Handle in-progress action
          },
          onMarkComplete: () {
            // Handle mark as complete action
          },
        ),
      ],
    );
  }
}

class _CompletedOrdersView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Center(
            child: Text(
              'Service Man Completed',
              style: AppTextStyles.header(
                color: AppColors.textPrimary,
              ).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        // Completed Orders List
        Expanded(
          child: _buildCompletedOrdersList(),
        ),
      ],
    );
  }

  Widget _buildCompletedOrdersList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      children: [
        _CompletedOrderCard(
          orderId: 'ORD033',
          customerName: 'Jim Hopper',
          addedDate: '10-04-2025',
          addedTime: '05:26 PM',
          completedDate: '11-04-2025',
          completedTime: '12:20 PM',
          itemCount: 15,
        ),
        const SizedBox(height: 12),
        _CompletedOrderCard(
          orderId: 'ORD026',
          customerName: 'Mike Wheelers',
          addedDate: '10-04-2025',
          addedTime: '11:16 AM',
          completedDate: '11-04-2025',
          completedTime: '09:20 AM',
          itemCount: 12,
        ),
        const SizedBox(height: 12),
        _CompletedOrderCard(
          orderId: 'ORD022',
          customerName: 'Joyce',
          addedDate: '09-04-2025',
          addedTime: '05:20 PM',
          completedDate: '10-04-2025',
          completedTime: '12:20 PM',
          itemCount: 08,
        ),
        const SizedBox(height: 12),
        _CompletedOrderCard(
          orderId: 'ORD020',
          customerName: 'Eleven',
          addedDate: '09-04-2025',
          addedTime: '03:26 PM',
          completedDate: '10-04-2025',
          completedTime: '02:20 PM',
          itemCount: 20,
        ),
      ],
    );
  }
}

class _OrderItem {
  final String name;
  final int quantity;

  const _OrderItem({required this.name, required this.quantity});
}

class _OrderCard extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String date;
  final String time;
  final int itemCount;
  final List<_OrderItem> items;
  final VoidCallback onInProgress;
  final VoidCallback onMarkComplete;

  const _OrderCard({
    required this.orderId,
    required this.customerName,
    required this.date,
    required this.time,
    required this.itemCount,
    required this.items,
    required this.onInProgress,
    required this.onMarkComplete,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID
          Text(
            widget.orderId,
            style: AppTextStyles.subtitle(
              color: AppColors.primary,
            ).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Customer Name
          Text(
            widget.customerName,
            style: AppTextStyles.title(
              color: AppColors.textPrimary,
            ).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          // Date & Time with Items
          Row(
            children: [
              // Date & Time Section
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.date} at ${widget.time}',
                      style: AppTextStyles.subtitle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Items Count
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.itemCount.toString().padLeft(2, '0'),
                    style: AppTextStyles.largeNumber(
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'items',
                    style: AppTextStyles.subtitle(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _InProgressButton(
                  onTap: widget.onInProgress,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MarkCompleteButton(
                  onTap: widget.onMarkComplete,
                ),
              ),
            ],
          ),
          // Expandable Items List
          if (!_isExpanded) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = true;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Items list',
                    style: AppTextStyles.subtitle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            // Items List
            ...widget.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Bullet point
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Item name
                      Text(
                        item.name,
                        style: AppTextStyles.subtitle(
                          color: AppColors.textPrimary,
                        ).copyWith(
                          fontSize: 13,
                        ),
                      ),
                      // Dotted line
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: CustomPaint(
                            painter: DottedLinePainter(),
                            child: const SizedBox(height: 1),
                          ),
                        ),
                      ),
                      // Quantity
                      Text(
                        item.quantity.toString().padLeft(2, '0'),
                        style: AppTextStyles.subtitle(
                          color: AppColors.textPrimary,
                        ).copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            // Items list footer with upward chevrons
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = false;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.keyboard_arrow_up,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Items list',
                    style: AppTextStyles.subtitle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_up,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InProgressButton extends StatelessWidget {
  final VoidCallback onTap;

  const _InProgressButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primary,
            width: 1.4,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'In-Progress',
          style: AppTextStyles.button(
            color: AppColors.primary,
          ).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MarkCompleteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MarkCompleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF283897),
              Color(0xFF0F73F7),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          'Mark as Complete',
          style: AppTextStyles.button(
            color: Colors.white,
          ).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CompletedOrderCard extends StatelessWidget {
  final String orderId;
  final String customerName;
  final String addedDate;
  final String addedTime;
  final String completedDate;
  final String completedTime;
  final int itemCount;

  const _CompletedOrderCard({
    required this.orderId,
    required this.customerName,
    required this.addedDate,
    required this.addedTime,
    required this.completedDate,
    required this.completedTime,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and Items Count Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID (Green)
              Text(
                orderId,
                style: AppTextStyles.subtitle(
                  color: AppColors.success,
                ).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Items Count (Green)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    itemCount.toString().padLeft(2, '0'),
                    style: AppTextStyles.largeNumber(
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    'items',
                    style: AppTextStyles.subtitle(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Customer Name
          Text(
            customerName,
            style: AppTextStyles.title(
              color: AppColors.textPrimary,
            ).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          // Added Date & Time
          Row(
            children: [
              Text(
                'Added: ',
                style: AppTextStyles.subtitle(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$addedDate at $addedTime',
                style: AppTextStyles.subtitle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Completed Date & Time
          Row(
            children: [
              Text(
                'Completed: ',
                style: AppTextStyles.subtitle(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$completedDate at $completedTime',
                style: AppTextStyles.subtitle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const barHeight = 82.0;
    const topRadius = Radius.circular(36);
    const topOnlyRadius = BorderRadius.only(
      topLeft: topRadius,
      topRight: topRadius,
    );

    return SizedBox(
      height: barHeight + bottomInset,
      child: Material(
        color: AppColors.surface,
        elevation: 14,
        borderRadius: topOnlyRadius,
        shadowColor: const Color(0x26000000),
        child: ClipRRect(
          borderRadius: topOnlyRadius,
          child: Stack(
            children: [
              // Bottom inset filler so bar sits flush with screen bottom.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomInset,
                child: const ColoredBox(color: Colors.white),
              ),
              // Main bar content.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: barHeight,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _NavTab(
                              icon: Icons.access_time_rounded,
                              label: 'Pending',
                              isSelected: selectedIndex == 0,
                              onTap: () => onTabSelected(0),
                            ),
                          ),
                          Expanded(
                            child: _NavTab(
                              icon: Icons.check_circle,
                              label: 'Completed',
                              isSelected: selectedIndex == 1,
                              onTap: () => onTabSelected(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Top accent line (inset from both ends) - rendered on top
                    Positioned(
                      left: 10,
                      right: 10,
                      top: 1,
                      child: IgnorePointer(
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0x002C3CA5), // transparent
                                Color(0xFF2C3CA5), // sharp in center
                                Color(0x002C3CA5), // transparent
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : const Color(0xFF98A0B5);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.0,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

