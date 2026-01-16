import 'package:flutter/material.dart';

import '../../../theme/app_text_styles.dart';
import '../../../models/service_item.dart';
import 'home_colors.dart';

enum RegularWashPricingType { kgWise, perPiece }

class RegularWashSelection {
  final String? serviceId;
  final String serviceName;
  final RegularWashPricingType pricingType;

  const RegularWashSelection({
    required this.serviceId,
    required this.serviceName,
    required this.pricingType,
  });
}

class RegularWashBottomSheet extends StatefulWidget {
  const RegularWashBottomSheet({super.key, required this.services, this.isLoading = false});

  static Future<RegularWashSelection?> show(
    BuildContext context, {
    required List<ServiceItem> services,
    bool isLoading = false,
  }) {
    return showModalBottomSheet<RegularWashSelection?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RegularWashBottomSheet(services: services, isLoading: isLoading),
    );
  }

  final List<ServiceItem> services;
  final bool isLoading;

  @override
  State<RegularWashBottomSheet> createState() => _RegularWashBottomSheetState();
}

class _RegularWashBottomSheetState extends State<RegularWashBottomSheet> {
  late ServiceItem _selectedService;
  RegularWashPricingType _pricingType = RegularWashPricingType.kgWise;

  List<ServiceItem> get _effectiveServices => widget.services;

  @override
  void initState() {
    super.initState();
    _selectedService = _effectiveServices.isNotEmpty
        ? _effectiveServices.first
        : const ServiceItem(
            serviceId: '',
            categoryId: '',
            serviceName: '',
            isActive: true,
            displayOrder: 0,
          );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isLoading = widget.isLoading;
    final items = _effectiveServices;
    final canProceed = items.isNotEmpty && !isLoading;

    return SafeArea(
      top: false,
      child: Padding(
        // keep the sheet flush to bottom, but respect gesture inset
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(26),
              topRight: Radius.circular(26),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose the service',
                textAlign: TextAlign.center,
                style: AppTextStyles.header(color: HomeColors.text)
                    .copyWith(fontSize: 12),
              ),
              const SizedBox(height: 10),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No services available right now. Please try again.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 12),
                  ),
                )
              else
                for (final s in items) ...[
                  _ServicePill(
                    label: s.serviceName,
                    isSelected: s.serviceName == _selectedService.serviceName,
                    onTap: () => setState(() => _selectedService = s),
                  ),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Choose the Pricing Type',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.header(color: HomeColors.text)
                          .copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    _PricingRow(
                      title: 'Kg-Wise',
                      subtitle: 'Pay based on total weight',
                      isSelected: _pricingType == RegularWashPricingType.kgWise,
                      onTap: () => setState(
                        () => _pricingType = RegularWashPricingType.kgWise,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PricingRow(
                      title: 'Per-Piece',
                      subtitle: 'Pay per individual item',
                      isSelected: _pricingType == RegularWashPricingType.perPiece,
                      onTap: () => setState(
                        () => _pricingType = RegularWashPricingType.perPiece,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _BottomButton(
                      label: 'Cancel',
                      variant: _BottomButtonVariant.outline,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BottomButton(
                      label: 'Next',
                      variant: _BottomButtonVariant.filled,
                      onTap: canProceed
                          ? () => Navigator.of(context).pop(
                                RegularWashSelection(
                                  serviceId: _selectedService.serviceId.isEmpty
                                      ? null
                                      : _selectedService.serviceId,
                                  serviceName: _selectedService.serviceName,
                                  pricingType: _pricingType,
                                ),
                              )
                          : () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServicePill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServicePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? HomeColors.primary : const Color(0xFFE5E7EB);
    final bgColor = isSelected ? HomeColors.primary : Colors.white;
    final textColor = isSelected ? Colors.white : HomeColors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Text(
          label,
          // Per design spec: Poppins 15, w500, height 1.0
          style: AppTextStyles.listItemTitle(color: textColor),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _PricingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PricingRow({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isSelected ? HomeColors.primary : const Color(0xFF9AA3B2);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: dotColor, width: 2),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: HomeColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.header(color: HomeColors.text)
                        .copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(color: HomeColors.muted)
                        .copyWith(fontSize: 10),
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

enum _BottomButtonVariant { outline, filled }

class _BottomButton extends StatelessWidget {
  final String label;
  final _BottomButtonVariant variant;
  final VoidCallback onTap;

  const _BottomButton({
    required this.label,
    required this.variant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = variant == _BottomButtonVariant.filled;
    final bg = isFilled ? HomeColors.primary : Colors.white;
    final fg = isFilled ? Colors.white : const Color(0xFF111827);
    final border = isFilled ? Colors.transparent : const Color(0xFFE5E7EB);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: AppTextStyles.button(color: fg).copyWith(fontSize: 13),
        ),
      ),
    );
  }
}


