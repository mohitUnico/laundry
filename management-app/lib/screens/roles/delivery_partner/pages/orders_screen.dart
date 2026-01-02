import 'package:flutter/material.dart';

import '../../../../routes/app_routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../common/widgets/bottom_nav_bar.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => Navigator.pop(context),
              onFilter: () {},
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: const [
                  _OrderCard(
                    orderId: 'ORD001',
                    name: 'Will Smith',
                    date: '12-04-2025',
                    items: 10,
                    status: OrderStatus.inProgress,
                    serviceType: 'Pickup',
                    amount: '\$12.00',
                  ),
                  _OrderCard(
                    orderId: 'ORD002',
                    name: 'Keanu Reeves',
                    date: '12-04-2025',
                    items: 12,
                    status: OrderStatus.completed,
                    serviceType: 'Delivery',
                    amount: '\$16.00',
                  ),
                  _OrderCard(
                    orderId: 'ORD021',
                    name: 'Ryan Reynolds',
                    date: '11-04-2025',
                    items: 2,
                    status: OrderStatus.rejected,
                    serviceType: 'Delivery',
                    amount: '\$6.00',
                  ),
                  _OrderCard(
                    orderId: 'ORD032',
                    name: 'Chris Hemsworth',
                    date: '10-04-2025',
                    items: 15,
                    status: OrderStatus.completed,
                    serviceType: 'Delivery',
                    amount: '\$18.00',
                  ),
                  _OrderCard(
                    orderId: 'ORD026',
                    name: 'Chris Hemsworth',
                    date: '10-04-2025',
                    items: 24,
                    status: OrderStatus.completed,
                    serviceType: 'Pickup',
                    amount: '\$25.00',
                  ),
                  _OrderCard(
                    orderId: 'ORD033',
                    name: 'Dwayne Johnson',
                    date: '10-04-2025',
                    items: 2,
                    status: OrderStatus.rejected,
                    serviceType: 'Delivery',
                    amount: '\$5.00',
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutes.home);
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacementNamed(context, AppRoutes.help);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, AppRoutes.profile);
              break;
          }
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onFilter;

  const _Header({
    required this.onBack,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            splashRadius: 20,
          ),
          Text(
            'Order History',
            style: AppTextStyles.title(color: AppColors.textPrimary),
          ),
          IconButton(
            onPressed: onFilter,
            icon: const Icon(Icons.more_horiz, size: 22),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

enum OrderStatus { inProgress, completed, rejected }

class _OrderCard extends StatelessWidget {
  final String orderId;
  final String name;
  final String date;
  final int items;
  final OrderStatus status;
  final String serviceType;
  final String amount;

  const _OrderCard({
    required this.orderId,
    required this.name,
    required this.date,
    required this.items,
    required this.status,
    required this.serviceType,
    required this.amount,
  });

  Color get _statusColor {
    switch (status) {
      case OrderStatus.inProgress:
        return const Color(0xFFF5A623);
      case OrderStatus.completed:
        return const Color(0xFF2DBE7F);
      case OrderStatus.rejected:
        return const Color(0xFFE74C3C);
    }
  }

  String get _statusLabel {
    switch (status) {
      case OrderStatus.inProgress:
        return 'In progress';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(minHeight: 126),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                orderId,
                style: AppTextStyles.subtitle(
                  color: const Color(0xFF2B59FF),
                ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status == OrderStatus.inProgress
                          ? Icons.timelapse
                          : status == OrderStatus.completed
                              ? Icons.check_circle
                              : Icons.close,
                      size: 14,
                      color: _statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _statusLabel,
                      style: AppTextStyles.smallText(
                        color: _statusColor,
                      ).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.title(
                        color: AppColors.textPrimary,
                      ).copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: AppTextStyles.smallText(
                            color: AppColors.textSecondary,
                      ).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.shopping_bag_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${items.toString().padLeft(2, '0')} items',
                          style: AppTextStyles.smallText(
                            color: AppColors.textSecondary,
                          ).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    serviceType,
                    style: AppTextStyles.subtitle(
                      color: AppColors.textSecondary,
                    ).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    amount,
                    style: AppTextStyles.price(
                      color: AppColors.primary,
                    ).copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

