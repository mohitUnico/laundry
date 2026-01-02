import 'package:flutter/material.dart';

import '../home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../routes/app_routes.dart';
import 'schedule_date_time_screen.dart';

enum DeliveryOptionType { pickupOnly, deliveryOnly, pickupAndDelivery }

class DeliveryOptionsScreen extends StatefulWidget {
  const DeliveryOptionsScreen({super.key});

  @override
  State<DeliveryOptionsScreen> createState() => _DeliveryOptionsScreenState();
}

class _DeliveryOptionsScreenState extends State<DeliveryOptionsScreen> {
  DeliveryOptionType _selected = DeliveryOptionType.pickupOnly;
  final Set<DeliveryOptionType> _expanded = {DeliveryOptionType.pickupOnly};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HomeColors.borderSoft),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: HomeColors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Delivery Options',
                  style: AppTextStyles.header(color: HomeColors.text),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Choose how you want to receive\nyour laundry',
                style: AppTextStyles.body(color: HomeColors.text).copyWith(
                  fontSize: 13,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 18),
              _DeliveryOptionCard(
                title: 'Pickup Only',
                priceText: 'FREE',
                description: 'We collect laundry from your doorstep',
                details: const [
                  'Free pickup from your doorstep',
                  'choose your pickup slot',
                  'Real time pickup address',
                ],
                isSelected: _selected == DeliveryOptionType.pickupOnly,
                isExpanded: _expanded.contains(DeliveryOptionType.pickupOnly),
                onTap: () => setState(() => _selected = DeliveryOptionType.pickupOnly),
                onToggleExpand: () => setState(() {
                  if (_expanded.contains(DeliveryOptionType.pickupOnly)) {
                    _expanded.remove(DeliveryOptionType.pickupOnly);
                  } else {
                    _expanded.add(DeliveryOptionType.pickupOnly);
                    _selected = DeliveryOptionType.pickupOnly;
                  }
                }),
              ),
              const SizedBox(height: 12),
              _DeliveryOptionCard(
                title: 'Delivery Only',
                priceText: 'FREE',
                description: 'We deliver to your location',
                details: const [
                  'Free delivery to your doorstep',
                  'choose your delivery slot',
                  'Real time delivery address',
                ],
                isSelected: _selected == DeliveryOptionType.deliveryOnly,
                isExpanded: _expanded.contains(DeliveryOptionType.deliveryOnly),
                onTap: () => setState(() => _selected = DeliveryOptionType.deliveryOnly),
                onToggleExpand: () => setState(() {
                  if (_expanded.contains(DeliveryOptionType.deliveryOnly)) {
                    _expanded.remove(DeliveryOptionType.deliveryOnly);
                  } else {
                    _expanded.add(DeliveryOptionType.deliveryOnly);
                    _selected = DeliveryOptionType.deliveryOnly;
                  }
                }),
              ),
              const SizedBox(height: 12),
              _DeliveryOptionCard(
                title: 'Pickup & Delivery',
                priceText: 'FREE',
                description: 'We pickup and deliver',
                details: const [
                  'Free pickup & delivery included',
                  'choose your pickup slot',
                  'Real time pickup & delivery address',
                ],
                isSelected: _selected == DeliveryOptionType.pickupAndDelivery,
                isExpanded: _expanded.contains(DeliveryOptionType.pickupAndDelivery),
                onTap: () =>
                    setState(() => _selected = DeliveryOptionType.pickupAndDelivery),
                onToggleExpand: () => setState(() {
                  if (_expanded.contains(DeliveryOptionType.pickupAndDelivery)) {
                    _expanded.remove(DeliveryOptionType.pickupAndDelivery);
                  } else {
                    _expanded.add(DeliveryOptionType.pickupAndDelivery);
                    _selected = DeliveryOptionType.pickupAndDelivery;
                  }
                }),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.scheduleDateTime,
                          arguments: ScheduleDateTimeArgs(option: _selected),
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2437B6), Color(0xFF2C3CA5)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Schedule Date & Time',
                            style: AppTextStyles.header(color: Colors.white)
                                .copyWith(fontSize: 14),
                          ),
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
  }
}

class _DeliveryOptionCard extends StatelessWidget {
  final String title;
  final String priceText;
  final String description;
  final List<String> details;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onToggleExpand;

  const _DeliveryOptionCard({
    required this.title,
    required this.priceText,
    required this.description,
    required this.details,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? HomeColors.primary : const Color(0xFFE5E7EB);
    final titleStyle = AppTextStyles.stepTitle(color: HomeColors.text);
    final descStyle = AppTextStyles.body(color: HomeColors.muted).copyWith(
      fontSize: 10,
      height: 1.15,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? HomeColors.primary : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: HomeColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  priceText,
                  style: AppTextStyles.stepTitle(color: HomeColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text(description, style: descStyle)),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onToggleExpand,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: HomeColors.muted,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(left: 28, top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final line in details) ...[
                            Text(line, style: descStyle),
                            const SizedBox(height: 6),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}


