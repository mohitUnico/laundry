import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../home/widgets/home_colors.dart';
import '../home/widgets/pro_clean_bottom_sheet.dart';

class ProCleanScreen extends StatelessWidget {
  const ProCleanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selection =
        ModalRoute.of(context)?.settings.arguments as ProCleanSelection?;

    final pricingText = switch (selection?.pricingType) {
      ProCleanPricingType.kgWise => 'Kg-Wise',
      ProCleanPricingType.perPiece => 'Per-Piece',
      _ => null,
    };

    return Scaffold(
      backgroundColor: HomeColors.background,
      appBar: AppBar(
        backgroundColor: HomeColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: HomeColors.text,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          selection?.categoryName ?? 'Pro Clean',
          style: AppTextStyles.header(color: HomeColors.text),
        ),
      ),
      body: Center(
        child: Text(
          selection == null
              ? 'Pro Clean - Coming soon'
              : '${selection.categoryName}\nPricing: $pricingText',
          textAlign: TextAlign.center,
          style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 14),
        ),
      ),
    );
  }
}


