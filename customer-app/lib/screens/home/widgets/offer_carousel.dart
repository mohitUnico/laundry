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
    if (widget.banners.isEmpty) return;
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
    if (widget.banners.isNotEmpty) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth * 0.88 - 12;
    final bannerHeight = cardWidth * 196 / 383;
    final totalPages = widget.banners.length * _loopMultiplier;

    // Indicator sits just under the banner, clear of the code pill.
    return SizedBox(
      height: bannerHeight + 22,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: bannerHeight,
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Transform.scale(
                          scale: 1.12,
                          child: Image.asset(
                            'assets/images/coupon_1.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(120, 18, 16, 62),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.headline,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.offerHeadline(
                                  color: Colors.white,
                                ).copyWith(fontSize: 26, height: 1.05),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                b.subhead,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.offerSubhead(
                                  color: Colors.white,
                                ).copyWith(fontSize: 13, height: 1.2),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 12,
                          child: _CodePill(code: b.code),
                        ),
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
            bottom: 0,
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
                Icons.chevron_right_rounded,
                size: 18,
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


