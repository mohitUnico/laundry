import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_colors.dart';

class HowLaundrySheet extends StatelessWidget {
  const HowLaundrySheet({super.key});

  static const _steps = <_LaundryStep>[
    _LaundryStep(
      imageAsset: 'assets/images/how_we_do_laundry/book_in_a_minute.png',
      title: '1. Book in a minute.',
      body:
          'Pick your services, choose per kg or per item, and set a pickup time. Choose Express if you need it now.',
    ),
    _LaundryStep(
      imageAsset: 'assets/images/how_we_do_laundry/we_come_to_your_door.png',
      title: '2. We come to your door.',
      body:
          'A nearby pickup partner is assigned and you can track them live.',
    ),
    _LaundryStep(
      imageAsset:
          'assets/images/how_we_do_laundry/counted_in_front_of_you.png',
      title: '3. Counted in front of you.',
      body:
          'Your clothes are counted or weighed at your door, and your bill is ready to view in the app. You don\'t pay yet.',
    ),
    _LaundryStep(
      imageAsset: 'assets/images/how_we_do_laundry/checked_at_our_hub.png',
      title: '4. Checked at our hub.',
      body:
          'Our team verifies your order and sends each item to the right specialist.',
    ),
    _LaundryStep(
      imageAsset: 'assets/images/how_we_do_laundry/cleaned_with_care.png',
      title: '5. Cleaned with care.',
      body:
          'Each service, such as wash, iron or dry clean, is done by a dedicated expert.',
    ),
    _LaundryStep(
      imageAsset: 'assets/images/how_we_do_laundry/ready_and_on_its_way.png',
      title: '6. Ready and on its way.',
      body:
          'When everything is finished, a delivery partner brings it back to you. You can see their name and live location.',
    ),
    _LaundryStep(
      imageAsset:
          'assets/images/how_we_do_laundry/pay_on_delivery_or_your_way.png',
      title: '7. Pay on delivery, your way.',
      body:
          'Pay by UPI in the app, or give cash to the delivery partner. Your clothes are handed over once payment is done.',
    ),
  ];

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x33000000),
      builder: (_) => const HowLaundrySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topGap = media.padding.top + 78;
    final sheetHeight = media.size.height - topGap;

    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: SizedBox(
        height: sheetHeight,
        child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: HomeColors.primary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    media.padding.bottom + 28,
                  ),
                  children: [
                    Text(
                      'How your laundry gets done',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: HomeColors.text,
                      ),
                    ),
                    const SizedBox(height: 18),
                    for (var i = 0; i < _steps.length; i++) ...[
                      _StepBlock(step: _steps[i]),
                      if (i != _steps.length - 1) const SizedBox(height: 22),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _StepBlock extends StatelessWidget {
  final _LaundryStep step;

  const _StepBlock({required this.step});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: 361 / 223,
            child: Image.asset(
              step.imageAsset,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          step.title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: HomeColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          step.body,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            height: 1.45,
            color: const Color(0xFF667085),
          ),
        ),
      ],
    );
  }
}

class _LaundryStep {
  final String imageAsset;
  final String title;
  final String body;

  const _LaundryStep({
    required this.imageAsset,
    required this.title,
    required this.body,
  });
}
