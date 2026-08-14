import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes/app_routes.dart';
import '../../utils/prefs_keys.dart';
import 'onboarding_page_data.dart';
import 'widgets/onboarding_page_indicator.dart';
import 'widgets/onboarding_title.dart';
import 'widgets/onboarding_page_view_item.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  bool _isNavigating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _setSeenAndGoLogin() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.onboardingSeen, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  Future<void> _handleNext() async {
    if (_isNavigating) return;
    final isLast = _index >= onboardingPages.length - 1;
    if (isLast) {
      await _setSeenAndGoLogin();
      return;
    }

    await _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = onboardingPages[_index];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isNavigating ? null : _setSeenAndGoLogin,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2C3CA5),
                  ),
                  child: _isNavigating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Skip',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardHeight =
                        (constraints.maxHeight * 0.50).clamp(220.0, 360.0);
                    final cardSize = cardHeight.clamp(220.0, 360.0);

                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: cardHeight,
                                child: PageView.builder(
                                  controller: _controller,
                                  itemCount: onboardingPages.length,
                                  onPageChanged: (value) =>
                                      setState(() => _index = value),
                                  itemBuilder: (context, index) {
                                    return Center(
                                      child: OnboardingPageViewItem(
                                        data: onboardingPages[index],
                                        size: cardSize,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 22),
                              OnboardingPageIndicator(
                                currentIndex: _index,
                                itemCount: onboardingPages.length,
                              ),
                              const SizedBox(height: 34),
                              OnboardingTitle(
                                line1: page.titleLine1,
                                line2: page.titleLine2,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                page.subtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFB0B3C3),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isNavigating ? null : _handleNext,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF2C3CA5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isNavigating
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          page.primaryButtonLabel,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


