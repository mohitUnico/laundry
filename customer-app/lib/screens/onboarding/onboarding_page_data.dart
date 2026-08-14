class OnboardingPageData {
  final String imageAsset;
  final List<OnboardingTextSegment> titleLine1;
  final List<OnboardingTextSegment> titleLine2;
  final String subtitle;
  final String primaryButtonLabel;

  const OnboardingPageData({
    required this.imageAsset,
    required this.titleLine1,
    required this.titleLine2,
    required this.subtitle,
    required this.primaryButtonLabel,
  });
}

class OnboardingTextSegment {
  final String text;
  final bool isEmphasis;

  const OnboardingTextSegment(this.text, {this.isEmphasis = false});
}

const onboardingPages = <OnboardingPageData>[
  OnboardingPageData(
    imageAsset: 'assets/images/splash1.png',
    titleLine1: [OnboardingTextSegment('Laundry Made')],
    titleLine2: [OnboardingTextSegment('Simple', isEmphasis: true)],
    subtitle: 'Book pickups and get fresh clothes\ndelivered to your door.',
    primaryButtonLabel: 'Next',
  ),
  OnboardingPageData(
    imageAsset: 'assets/images/splash2.png',
    titleLine1: [OnboardingTextSegment('Choose How')],
    titleLine2: [
      OnboardingTextSegment('You '),
      OnboardingTextSegment('Pay', isEmphasis: true),
    ],
    subtitle: 'Select kg wise pricing or pay per\npiece, based on your needs.',
    primaryButtonLabel: 'Next',
  ),
  OnboardingPageData(
    imageAsset: 'assets/images/splash3.png',
    titleLine1: [OnboardingTextSegment('Fresh, Clean.')],
    titleLine2: [OnboardingTextSegment('On-Time.', isEmphasis: true)],
    subtitle: 'Professional care with reliable pickup\nand delivery.',
    primaryButtonLabel: 'Continue',
  ),
];


