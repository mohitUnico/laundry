import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_text_styles.dart';
import '../home/widgets/home_colors.dart';

class CancelPickupScreen extends StatefulWidget {
  final String orderId;
  final String orderCode;

  const CancelPickupScreen({
    super.key,
    required this.orderId,
    required this.orderCode,
  });

  @override
  State<CancelPickupScreen> createState() => _CancelPickupScreenState();
}

class _CancelPickupScreenState extends State<CancelPickupScreen> {
  static const _reasons = [
    'Change of plans',
    'Booked by mistake',
    'Pickup is taking too long',
    'Something else',
  ];

  String? _reason;

  void _cancel() {
    if (_reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a reason first')),
      );
      return;
    }
    final provider = context.read<OrderProvider>();
    final stillPlaced = provider.orders.any(
      (order) => order.id == widget.orderId && order.backendStatus.toLowerCase() == 'placed',
    );
    if (!stillPlaced) {
      Navigator.of(context).pop();
      return;
    }
    provider.cancelPlacedOrder(widget.orderId);
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.orders,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: HomeColors.text),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancel pickup',
                          style: AppTextStyles.header(color: HomeColors.text).copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.orderCode,
                          style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  Text(
                    'Tell us why — cancelling now is free, nothing has been charged.',
                    style: AppTextStyles.body(color: HomeColors.muted).copyWith(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final reason in _reasons) ...[
                    _ReasonTile(
                      label: reason,
                      selected: _reason == reason,
                      onTap: () => setState(() => _reason = reason),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8 + bottom),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: TextButton(
                      onPressed: _cancel,
                      style: TextButton.styleFrom(
                        backgroundColor: HomeColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      child: Text(
                        'Cancel this pickup',
                        style: AppTextStyles.button(color: Colors.white).copyWith(fontSize: 15),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(
                      'Keep my pickup',
                      style: AppTextStyles.button(color: HomeColors.muted).copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? HomeColors.primary : HomeColors.borderSoft,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.header(color: HomeColors.text).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? HomeColors.primary : HomeColors.borderSoft,
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: HomeColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
