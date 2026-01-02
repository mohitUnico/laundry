import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_colors.dart';
import '../../../theme/app_text_styles.dart';

class OfferBannerData {
  final String headline;
  final String subhead;
  final String code;

  const OfferBannerData({
    required this.headline,
    required this.subhead,
    required this.code,
  });
}

class OfferCarousel extends StatefulWidget {
  final List<OfferBannerData> banners;

  const OfferCarousel({
    super.key,
    required this.banners,
  });

  @override
  State<OfferCarousel> createState() => _OfferCarouselState();
}

class _OfferCarouselState extends State<OfferCarousel> {
  late final PageController _controller;
  int _index = 0;

  static const int _loopMultiplier = 1000;

  @override
  void initState() {
    super.initState();
    // < 1.0 so users can peek previous/next banner.
    final initial = (widget.banners.length * _loopMultiplier) ~/ 2;
    final alignedInitial = initial - (initial % widget.banners.length);
    _controller = PageController(
      viewportFraction: 0.88,
      initialPage: alignedInitial,
    );
    _index = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    // Taller banners per design request.
    final bannerHeight = (160 * textScale).clamp(160.0, 210.0);
    final totalPages = widget.banners.length * _loopMultiplier;

    // Indicator should feel "attached" to the banner, so we overlay it inside
    // the banner area instead of putting it below the banner.
    return SizedBox(
      height: bannerHeight + 40, // content + container padding
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _controller,
              itemCount: totalPages,
              padEnds: true,
              onPageChanged: (v) =>
                  setState(() => _index = v % widget.banners.length),
              itemBuilder: (context, i) {
                final b = widget.banners[i % widget.banners.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                    color: Colors.white,
                    border: Border.all(color: HomeColors.borderSoft),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          b.headline,
                          style: AppTextStyles.offerHeadline(
                            color: HomeColors.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          b.subhead,
                          style: AppTextStyles.offerSubhead(
                            color: HomeColors.muted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Flexible(child: _CodePill(code: b.code)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: IgnorePointer(
              child: _Indicator(
                currentIndex: _index,
                count: widget.banners.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodePill extends StatelessWidget {
  final String code;
  const _CodePill({required this.code});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: code));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied coupon code: $code'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: HomeColors.primary,
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Text(
              'Code: $code',
              style: AppTextStyles.couponCode(color: Colors.white),
            ),
            const Spacer(),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.copy_rounded,
                size: 16,
                color: HomeColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final int currentIndex;
  final int count;

  const _Indicator({
    required this.currentIndex,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: isActive ? 16 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? HomeColors.primary : const Color(0xFFD6D9E7),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}


