import 'package:flutter/material.dart';

import '../../../theme/app_text_styles.dart';
import 'home_colors.dart';

enum LuxuryCarePricingType { kgWise, perPiece }

class LuxuryCareSelection {
  final String serviceName;
  final LuxuryCarePricingType pricingType;

  const LuxuryCareSelection({
    required this.serviceName,
    required this.pricingType,
  });
}

class LuxuryCareBottomSheet extends StatefulWidget {
  const LuxuryCareBottomSheet({super.key});

  static Future<LuxuryCareSelection?> show(BuildContext context) {
    return showModalBottomSheet<LuxuryCareSelection?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LuxuryCareBottomSheet(),
    );
  }

  @override
  State<LuxuryCareBottomSheet> createState() => _LuxuryCareBottomSheetState();
}

class _LuxuryCareBottomSheetState extends State<LuxuryCareBottomSheet> {
  String _selectedService = _services.first.title;
  LuxuryCarePricingType _pricingType = LuxuryCarePricingType.kgWise;

  static const _services = <_LuxuryCareService>[
    _LuxuryCareService(
      title: 'Steam Press',
      subtitle: 'Steam press for non iron friendly clothes',
      imageAsset: 'assets/images/luxury_care/steam_press.png',
    ),
    _LuxuryCareService(
      title: 'Designer Wear',
      subtitle: 'Heavy designer or festive or occasional wear',
      imageAsset: 'assets/images/luxury_care/designer_wear.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose the service',
                  style: AppTextStyles.header(color: HomeColors.text)
                      .copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              for (final s in _services) ...[
                _ServiceRow(
                  title: s.title,
                  subtitle: s.subtitle,
                  imageAsset: s.imageAsset,
                  isSelected: s.title == _selectedService,
                  onTap: () => setState(() => _selectedService = s.title),
                ),
                const SizedBox(height: 12),
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
                      isSelected: _pricingType == LuxuryCarePricingType.kgWise,
                      onTap: () => setState(
                        () => _pricingType = LuxuryCarePricingType.kgWise,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PricingRow(
                      title: 'Per-Piece',
                      subtitle: 'Pay per individual item',
                      isSelected: _pricingType == LuxuryCarePricingType.perPiece,
                      onTap: () => setState(
                        () => _pricingType = LuxuryCarePricingType.perPiece,
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
                      onTap: () => Navigator.of(context).pop(
                        LuxuryCareSelection(
                          serviceName: _selectedService,
                          pricingType: _pricingType,
                        ),
                      ),
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

class _LuxuryCareService {
  final String title;
  final String subtitle;
  final String imageAsset;

  const _LuxuryCareService({
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
    final titleStyle = AppTextStyles.listItemTitle(color: HomeColors.text);
    final subtitleStyle = AppTextStyles.body(color: HomeColors.muted);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: Image.asset(imageAsset, fit: BoxFit.contain),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.header(color: HomeColors.text)
                        .copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
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


