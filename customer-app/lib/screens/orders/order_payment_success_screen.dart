import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../routes/route_args.dart';
import '../../utils/pricing.dart';
import '../home/widgets/home_colors.dart';

class OrderPaymentSuccessScreen extends StatelessWidget {
  final int itemTotal;
  final int handling;
  final int pickup;
  final int delivery;
  final int toPay;
  final int original;
  final OrderTrackingArgs tracking;

  const OrderPaymentSuccessScreen({
    super.key,
    required this.itemTotal,
    required this.handling,
    required this.pickup,
    required this.delivery,
    required this.toPay,
    required this.original,
    required this.tracking,
  });

  String get _transactionId {
    final digits = tracking.orderId.replaceAll(RegExp(r'\D'), '');
    final n = int.tryParse(digits) ?? tracking.orderId.hashCode.abs();
    final tail = (n % 10000000).toString().padLeft(7, '0');
    return 'QUCVG$tail';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 1,
                        shadowColor: const Color(0x14000000),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).maybePop(),
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: Color(0xFF1F2430),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'Payment Successful',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2430),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  Image.asset(
                    'assets/images/payment_successful_image.png',
                    height: 190,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE8ECF4)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Transaction ID: $_transactionId',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2430),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F6FB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE8ECF4)),
                              ),
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                size: 20,
                                color: Color(0xFF344054),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bill Summary',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1F2430),
                                    ),
                                  ),
                                  Text(
                                    'Incl. all taxes & charges',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF98A2B3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Pricing.inr(toPay),
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: HomeColors.primary,
                                  ),
                                ),
                                Text(
                                  Pricing.inr(original),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF98A2B3),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _Row(label: 'Item Total', value: Pricing.inr(itemTotal)),
                        const SizedBox(height: 12),
                        _Row(label: 'Handling Fee', value: Pricing.inr(handling)),
                        const SizedBox(height: 12),
                        _Row(
                          label: 'Pickup Fee: Free',
                          value: Pricing.inr(pickup),
                          struck: true,
                          trailing: Pricing.inr(0),
                        ),
                        const SizedBox(height: 12),
                        _Row(label: 'Delivery Fee', value: Pricing.inr(delivery)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: Color(0xFFE8ECF4)),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To Pay',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2430),
                              ),
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      Pricing.inr(original),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF16A34A),
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor: const Color(0xFF16A34A),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      Pricing.inr(toPay),
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: HomeColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'You saved ${Pricing.inr(pickup)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.orderTracking,
                                arguments: tracking,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F6BFF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              'Track your Laundry',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool struck;
  final String? trailing;

  const _Row({
    required this.label,
    required this.value,
    this.struck = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F2430),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: struck ? const Color(0xFF98A2B3) : HomeColors.primary,
            decoration: struck ? TextDecoration.lineThrough : null,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Text(
            trailing!,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2430),
            ),
          ),
        ],
      ],
    );
  }
}
