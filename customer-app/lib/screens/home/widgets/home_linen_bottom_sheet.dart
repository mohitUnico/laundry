import 'package:flutter/material.dart';

import '../../../theme/app_text_styles.dart';
import 'home_colors.dart';

enum HomeLinenPricingType { kgWise, perPiece }

class HomeLinenSelection {
  final String serviceName;
  final HomeLinenPricingType pricingType;

  const HomeLinenSelection({
    required this.serviceName,
    required this.pricingType,
  });
}

class HomeLinenBottomSheet extends StatefulWidget {
  const HomeLinenBottomSheet({super.key});

  static Future<HomeLinenSelection?> show(BuildContext context) {
    return showModalBottomSheet<HomeLinenSelection?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HomeLinenBottomSheet(),
    );
  }

  @override
  State<HomeLinenBottomSheet> createState() => _HomeLinenBottomSheetState();
}

class _HomeLinenBottomSheetState extends State<HomeLinenBottomSheet> {
  static const _serviceName = 'Home Linen';
  HomeLinenPricingType _pricingType = HomeLinenPricingType.kgWise;

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
              const _ServiceRow(
                title: _serviceName,
                subtitle: 'Bedsheets, curtains, and household linen',
                imageAsset: 'assets/images/home_linen/bedsheets.png',
              ),
              const SizedBox(height: 18),
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
                      isSelected: _pricingType == HomeLinenPricingType.kgWise,
                      onTap: () => setState(
                        () => _pricingType = HomeLinenPricingType.kgWise,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PricingRow(
                      title: 'Per-Piece',
                      subtitle: 'Pay per individual item',
                      isSelected: _pricingType == HomeLinenPricingType.perPiece,
                      onTap: () => setState(
                        () => _pricingType = HomeLinenPricingType.perPiece,
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
                      label: 'Add to cart',
                      variant: _BottomButtonVariant.filled,
                      onTap: () => Navigator.of(context).pop(
                        HomeLinenSelection(
                          serviceName: _serviceName,
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

class _ServiceRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageAsset;

  const _ServiceRow({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeColors.primary),
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
                  style: AppTextStyles.listItemTitle(color: HomeColors.text),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(color: HomeColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.radio_button_checked_rounded,
            size: 18,
            color: HomeColors.primary,
          ),
        ],
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
