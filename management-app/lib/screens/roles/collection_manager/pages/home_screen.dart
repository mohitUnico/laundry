import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/role_manager.dart';
import '../../../common/widgets/bottom_nav_bar.dart';
import 'delivery_partners_screen.dart';
import 'history_screen.dart';

class CollectionManagerHomeScreen extends StatefulWidget {
  const CollectionManagerHomeScreen({super.key});

  @override
  State<CollectionManagerHomeScreen> createState() => _CollectionManagerHomeScreenState();
}

class _CollectionManagerHomeScreenState extends State<CollectionManagerHomeScreen> {
  int _selectedTabIndex = 0; // 0: New Orders, 1: Received

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                  // History Icon
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                    },
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    splashRadius: 20,
                  ),
                  const SizedBox(width: 8),
                  // Log Out Button
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
            // Orders List
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildNewOrdersList()
                  : _buildReceivedOrdersList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _CollectionManagerBottomNavBar(
        selectedIndex: _selectedTabIndex,
        onTabSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildNewOrdersList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _NewOrderCard(
          orderId: 'ORD035',
          customerName: 'Mike Wheelers',
          date: '10-04-2025',
          time: '10:16 AM',
          itemCount: 12,
          isAssigned: false,
          deliveryPerson: null,
          deliveryPersonId: null,
          items: const [
            _OrderItem(name: 'Top Wear', quantity: 5),
            _OrderItem(name: 'Bottom Wear', quantity: 5),
            _OrderItem(name: 'Kurta', quantity: 2),
          ],
        ),
        const SizedBox(height: 12),
        _NewOrderCard(
          orderId: 'ORD033',
          customerName: 'Jim Hopper',
          date: '10-04-2025',
          time: '09:15 AM',
          itemCount: 15,
          isAssigned: true,
          deliveryPerson: 'Dustin Henderson',
          deliveryPersonId: 'EM056',
          items: const [
            _OrderItem(name: 'Top Wear', quantity: 5),
            _OrderItem(name: 'Bottom Wear', quantity: 6),
            _OrderItem(name: 'Kurta', quantity: 2),
            _OrderItem(name: 'Saree', quantity: 2),
          ],
        ),
        const SizedBox(height: 12),
        _NewOrderCard(
          orderId: 'ORD035',
          customerName: 'Joyce Byers',
          date: '09-04-2025',
          time: '04:20 PM',
          itemCount: 21,
          isAssigned: true,
          deliveryPerson: 'Will Byers',
          deliveryPersonId: 'EM072',
          items: const [
            _OrderItem(name: 'Top Wear', quantity: 5),
            _OrderItem(name: 'Bottom Wear', quantity: 5),
            _OrderItem(name: 'Kurta', quantity: 2),
            _OrderItem(name: 'Saree', quantity: 3),
          ],
          isExpanded: true,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildReceivedOrdersList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _ReceivedOrderCard(
          orderId: 'ORD035',
          customerName: 'Mike Wheelers',
          date: '10-04-2025',
          time: '10:16 AM',
          itemCount: 12,
          deliveryPerson: 'Lucas Sinclair',
          deliveryPersonId: 'EM045',
          items: const [
            _OrderItem(name: 'Top Wear', quantity: 5),
            _OrderItem(name: 'Bottom Wear', quantity: 5),
            _OrderItem(name: 'Kurta', quantity: 2),
          ],
        ),
        const SizedBox(height: 12),
        _ReceivedOrderCard(
          orderId: 'ORD033',
          customerName: 'Jim Hopper',
          date: '10-04-2025',
          time: '09:15 AM',
          itemCount: 15,
          deliveryPerson: 'Dustin Henderson',
          deliveryPersonId: 'EM056',
          items: const [
            _OrderItem(name: 'Top Wear', quantity: 5),
            _OrderItem(name: 'Bottom Wear', quantity: 6),
            _OrderItem(name: 'Kurta', quantity: 2),
            _OrderItem(name: 'Saree', quantity: 2),
          ],
        ),
        const SizedBox(height: 12),
        _ReceivedOrderCard(
          orderId: 'ORD035',
          customerName: 'Joyce Byers',
          date: '09-04-2025',
          time: '04:20 PM',
          itemCount: 21,
          deliveryPerson: 'Will Byers',
          deliveryPersonId: 'EM072',
          items: const [
            _OrderItem(name: 'Top Wear', quantity: 5),
            _OrderItem(name: 'Bottom Wear', quantity: 5),
            _OrderItem(name: 'Kurta', quantity: 2),
            _OrderItem(name: 'Saree', quantity: 3),
          ],
          isExpanded: true,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _OrderItem {
  final String name;
  final int quantity;

  const _OrderItem({required this.name, required this.quantity});
}

class _NewOrderCard extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String date;
  final String time;
  final int itemCount;
  final bool isAssigned;
  final String? deliveryPerson;
  final String? deliveryPersonId;
  final List<_OrderItem> items;
  final bool isExpanded;

  const _NewOrderCard({
    required this.orderId,
    required this.customerName,
    required this.date,
    required this.time,
    required this.itemCount,
    required this.isAssigned,
    this.deliveryPerson,
    this.deliveryPersonId,
    required this.items,
    this.isExpanded = false,
  });

  @override
  State<_NewOrderCard> createState() => _NewOrderCardState();
}

class _NewOrderCardState extends State<_NewOrderCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final orderIdColor = widget.isAssigned ? AppColors.primary : AppColors.error;
    final itemCountColor = widget.isAssigned ? AppColors.primary : AppColors.error;

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
              Text(
                widget.orderId,
                style: AppTextStyles.subtitle(
                  color: orderIdColor,
                ).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.itemCount.toString().padLeft(2, '0'),
                    style: AppTextStyles.largeNumber(
                      color: itemCountColor,
                    ),
                  ),
                  Text(
                    'items',
                    style: AppTextStyles.subtitle(
                      color: itemCountColor,
                    ),
                  ),
                ],
              ),
            ],
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
          // Date & Time
          Row(
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
          const SizedBox(height: 10),
          // Delivery Status
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: widget.isAssigned ? AppColors.textSecondary : AppColors.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.isAssigned
                      ? 'Delivered by : ${widget.deliveryPerson} (${widget.deliveryPersonId})'
                      : 'Delivered by : Not Assigned (10 mins)',
                  style: AppTextStyles.subtitle(
                    color: widget.isAssigned ? AppColors.textSecondary : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons
          if (!widget.isAssigned)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeliveryPartnersScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary, width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  'Assign >>>',
                  style: AppTextStyles.button(
                    color: AppColors.primary,
                  ).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
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
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () {
                          // Handle verified & received action
                        },
                        child: Text(
                          'Verified & Received',
                          style: AppTextStyles.button(
                            color: Colors.white,
                          ).copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.4,
                    ),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // Handle phone call
                    },
                    icon: Icon(
                      Icons.phone,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    splashRadius: 20,
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
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.textSecondary,
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

class _ReceivedOrderCard extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String date;
  final String time;
  final int itemCount;
  final String deliveryPerson;
  final String deliveryPersonId;
  final List<_OrderItem> items;
  final bool isExpanded;

  const _ReceivedOrderCard({
    required this.orderId,
    required this.customerName,
    required this.date,
    required this.time,
    required this.itemCount,
    required this.deliveryPerson,
    required this.deliveryPersonId,
    required this.items,
    this.isExpanded = false,
  });

  @override
  State<_ReceivedOrderCard> createState() => _ReceivedOrderCardState();
}

class _ReceivedOrderCardState extends State<_ReceivedOrderCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

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
              Text(
                widget.orderId,
                style: AppTextStyles.subtitle(
                  color: AppColors.primary,
                ).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
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
          // Date & Time
          Row(
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
          const SizedBox(height: 10),
          // Delivery Information
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Delivered by : ${widget.deliveryPerson}(${widget.deliveryPersonId})',
                style: AppTextStyles.subtitle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Assign to Service Man Button
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
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  // Handle assign to service man action
                },
                child: Text(
                  'Assign to Service Man',
                  style: AppTextStyles.button(
                    color: Colors.white,
                  ).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
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
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
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
                    const SizedBox(width: 6),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
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
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
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

class _CollectionManagerBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _CollectionManagerBottomNavBar({
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
                              icon: Icons.home_rounded,
                              label: 'Home',
                              isSelected: selectedIndex == 0,
                              onTap: () => onTabSelected(0),
                            ),
                          ),
                          Expanded(
                            child: _NavTab(
                              icon: Icons.access_time_rounded,
                              label: 'Received',
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

