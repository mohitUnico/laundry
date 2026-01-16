import 'package:flutter/material.dart';

import '../../../theme/app_text_styles.dart';
import '../../../models/service_item.dart';
import 'home_colors.dart';

enum ProCleanPricingType { kgWise, perPiece }

class ProCleanSelection {
  final String? serviceId;
  final String categoryName;
  final ProCleanPricingType pricingType;

  const ProCleanSelection({
    required this.serviceId,
    required this.categoryName,
    required this.pricingType,
  });
}

class ProCleanBottomSheet extends StatefulWidget {
  const ProCleanBottomSheet({super.key, required this.services, this.isLoading = false});

  static Future<ProCleanSelection?> show(
    BuildContext context, {
    required List<ServiceItem> services,
    bool isLoading = false,
  }) {
    return showModalBottomSheet<ProCleanSelection?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProCleanBottomSheet(services: services, isLoading: isLoading),
    );
  }

  final List<ServiceItem> services;
  final bool isLoading;

  @override
  State<ProCleanBottomSheet> createState() => _ProCleanBottomSheetState();
}

class _ProCleanBottomSheetState extends State<ProCleanBottomSheet> {
  late _ProCleanCategory _selectedCategory;
  ProCleanPricingType _pricingType = ProCleanPricingType.kgWise;

  static const _categories = <_ProCleanCategory>[
    _ProCleanCategory(
      title: 'Dry Cleaning',
      subtitle: 'Deep cleaning required',
      imageAsset: 'assets/images/pro_clean/dry_cleaning.png',
    ),
    _ProCleanCategory(
      title: 'Stain Treatment',
      subtitle: 'Pre-treatment for stains',
      imageAsset: 'assets/images/pro_clean/stain_treatment.png',
    ),
    _ProCleanCategory(
      title: 'Shoe Cleaning',
      subtitle: 'Fresh and spotless shoes',
      imageAsset: 'assets/images/pro_clean/shoe_cleaning.png',
    ),
    _ProCleanCategory(
      title: 'Winter Wear',
      subtitle: 'Clean, cozy, and hot',
      imageAsset: 'assets/images/pro_clean/winter_wear.png',
    ),
    _ProCleanCategory(
      title: 'Delicate Fabrics',
      subtitle: 'Wool, silk, etc.',
      imageAsset: 'assets/images/pro_clean/delicate_fabrics.png',
    ),
  ];

  List<_ProCleanCategory> get _effectiveCategories {
    final services = widget.services;
    if (services.isEmpty) return const [];

    // Keep the design consistent: reuse the existing subtitle/image set by index,
    // but replace the displayed title with backend service names.
    return List.generate(services.length, (i) {
      final template = _categories[i % _categories.length];
      return _ProCleanCategory(
        serviceId: services[i].serviceId,
        title: services[i].serviceName,
        subtitle: template.subtitle,
        imageAsset: template.imageAsset,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    final list = _effectiveCategories;
    _selectedCategory = list.isNotEmpty ? list.first : _categories.first;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isLoading = widget.isLoading;
    final items = _effectiveCategories;
    final canProceed = items.isNotEmpty && !isLoading;

    return SafeArea(
      top: false,
      child: Padding(
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
                for (final c in items) ...[
                  _ServiceRow(
                    title: c.title,
                    subtitle: c.subtitle,
                    imageAsset: c.imageAsset,
                    isSelected: c.title == _selectedCategory.title,
                    onTap: () => setState(() => _selectedCategory = c),
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
                      isSelected: _pricingType == ProCleanPricingType.kgWise,
                      onTap: () => setState(
                        () => _pricingType = ProCleanPricingType.kgWise,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PricingRow(
                      title: 'Per-Piece',
                      subtitle: 'Pay per individual item',
                      isSelected: _pricingType == ProCleanPricingType.perPiece,
                      onTap: () => setState(
                        () => _pricingType = ProCleanPricingType.perPiece,
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
                                ProCleanSelection(
                                  serviceId: _selectedCategory.serviceId?.isEmpty == true
                                      ? null
                                      : _selectedCategory.serviceId,
                                  categoryName: _selectedCategory.title,
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

class _ProCleanCategory {
  final String? serviceId;
  final String title;
  final String subtitle;
  final String imageAsset;

  const _ProCleanCategory({
    this.serviceId,
    required this.title,
    required this.subtitle,
    required this.imageAsset,
  });
}

class _ServiceRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageAsset;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceRow({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? HomeColors.primary : const Color(0xFFE5E7EB);
    const bgColor = Colors.white;
    // Match Regular Wash bottom sheet typography:
    // - Service title uses listItemTitle (Poppins 15, w500)
    // - Subtitle uses body (Poppins 10, w400)
    final titleStyle = AppTextStyles.listItemTitle(color: HomeColors.text);
    final subtitleStyle = AppTextStyles.body(color: HomeColors.muted);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: Image.asset(
                imageAsset,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: subtitleStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: isSelected ? HomeColors.primary : const Color(0xFF9AA3B2),
            ),
          ],
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


