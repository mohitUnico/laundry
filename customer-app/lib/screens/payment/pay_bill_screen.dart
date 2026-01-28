import 'package:flutter/material.dart';

import '../../repositories/payment_repository.dart';
import '../../screens/home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/pricing.dart';

enum BillPaymentMethod { card, cod }

class PayBillScreen extends StatefulWidget {
  final String orderId;
  final int amountInr;

  const PayBillScreen({
    super.key,
    required this.orderId,
    required this.amountInr,
  });

  @override
  State<PayBillScreen> createState() => _PayBillScreenState();
}

class _PayBillScreenState extends State<PayBillScreen> {
  BillPaymentMethod _method = BillPaymentMethod.card;
  bool _isPaying = false;

  final TextEditingController _promoController = TextEditingController();
  int _promoDiscount = 0;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = (widget.amountInr - _promoDiscount).clamp(0, 1 << 30);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _TopBar(onBack: () => Navigator.of(context).maybePop()),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    _SummaryCard(
                      orderId: widget.orderId,
                      amountInr: widget.amountInr,
                      promoDiscount: _promoDiscount,
                      finalTotal: total,
                    ),
                    const SizedBox(height: 14),
                    _PromoCard(
                      controller: _promoController,
                      onApply: () {
                        // Keep it simple: any non-empty code => flat ₹50 discount.
                        final code = _promoController.text.trim();
                        setState(() {
                          _promoDiscount = code.isEmpty ? 0 : 50;
                        });
                      },
                      onClear: () {
                        setState(() {
                          _promoController.clear();
                          _promoDiscount = 0;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _PaymentMethodCard(
                      method: _method,
                      onChanged: (m) => setState(() => _method = m),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HomeColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: _isPaying
                            ? null
                            : () async {
                                setState(() {
                                  _isPaying = true;
                                });
                                try {
                                  final repo = PaymentRepository();
                                  final methodBackend =
                                      _method == BillPaymentMethod.card ? 'card' : 'cod';
                                  final statusBackend =
                                      _method == BillPaymentMethod.card ? 'completed' : 'pending';

                                  final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
                                  var transactionId =
                                      'QUCVG${timestamp.length > 7 ? timestamp.substring(timestamp.length - 7) : timestamp.padLeft(7, '0')}';

                                  final result = await repo.processPayment(
                                    orderId: widget.orderId,
                                    paymentMethod: methodBackend,
                                    transactionId: statusBackend == 'completed' ? transactionId : null,
                                    paymentStatus: statusBackend,
                                  );

                                  if (result.transactionId != null &&
                                      result.transactionId!.isNotEmpty) {
                                    transactionId = result.transactionId!;
                                  }

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        statusBackend == 'completed'
                                            ? 'Payment successful'
                                            : 'Payment pending (COD)',
                                      ),
                                    ),
                                  );
                                  Navigator.of(context).pop(true);
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceFirst('Exception: ', '').trim(),
                                      ),
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isPaying = false;
                                    });
                                  }
                                }
                              },
                        child: _isPaying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Pay ${Pricing.inr(total)}',
                                style: AppTextStyles.button(color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: HomeColors.borderSoft),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: HomeColors.text),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pay Bill',
              style: AppTextStyles.header(color: HomeColors.text).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String orderId;
  final int amountInr;
  final int promoDiscount;
  final int finalTotal;

  const _SummaryCard({
    required this.orderId,
    required this.amountInr,
    required this.promoDiscount,
    required this.finalTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order',
            style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            orderId,
            style: AppTextStyles.body(color: HomeColors.text).copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Amount', style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 12)),
              const Spacer(),
              Text(Pricing.inr(amountInr), style: AppTextStyles.body(color: HomeColors.text).copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Discount', style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 12)),
              const Spacer(),
              Text('- ${Pricing.inr(promoDiscount)}', style: AppTextStyles.body(color: HomeColors.text).copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const Divider(height: 18, thickness: 1, color: Color(0xFFE5E7EB)),
          Row(
            children: [
              Text('Payable', style: AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 14)),
              const Spacer(),
              Text(Pricing.inr(finalTotal), style: AppTextStyles.header(color: HomeColors.primary).copyWith(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const _PromoCard({
    required this.controller,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apply coupon',
            style: AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter code',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(backgroundColor: HomeColors.primary),
                child: const Text('Apply'),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: onClear, child: const Text('Clear')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final BillPaymentMethod method;
  final ValueChanged<BillPaymentMethod> onChanged;

  const _PaymentMethodCard({required this.method, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment method',
            style: AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 14),
          ),
          const SizedBox(height: 10),
          RadioListTile<BillPaymentMethod>(
            value: BillPaymentMethod.card,
            groupValue: method,
            onChanged: (v) => v == null ? null : onChanged(v),
            title: const Text('Card'),
          ),
          RadioListTile<BillPaymentMethod>(
            value: BillPaymentMethod.cod,
            groupValue: method,
            onChanged: (v) => v == null ? null : onChanged(v),
            title: const Text('Cash on Delivery'),
          ),
        ],
      ),
    );
  }
}


