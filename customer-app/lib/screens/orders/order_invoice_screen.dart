import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/payment_repository.dart';
import '../../screens/home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/pricing.dart';
import '../home/widgets/home_bottom_nav.dart';
import '../../routes/app_routes.dart';
import '../../services/payment_service.dart';

class OrderInvoiceScreen extends StatefulWidget {
  final String orderId;

  const OrderInvoiceScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderInvoiceScreen> createState() => _OrderInvoiceScreenState();
}

class _OrderInvoiceScreenState extends State<OrderInvoiceScreen> {
  late Future<InvoiceDetails?> _future;

  @override
  void initState() {
    super.initState();
    _future = PaymentRepository().getInvoiceByOrderId(orderId: widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: FutureBuilder<InvoiceDetails?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final invoice = snapshot.data;
            if (invoice == null) {
              return _EmptyState(
                message: 'Invoice not generated yet',
                onBack: () => Navigator.of(context).maybePop(),
              );
            }

            final billTotal = (double.tryParse(invoice.bill.finalAmount) ?? 0).toInt();
            final billingLabel = _formatBillingLabel(invoice);

            return Column(
              children: [
                const SizedBox(height: 10),
                _TopBar(
                  title: 'Invoice',
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MetaRow(label: 'Order ID', value: invoice.orderId),
                        const SizedBox(height: 6),
                        _MetaRow(label: 'Status', value: invoice.orderStatus),
                        const SizedBox(height: 6),
                        _MetaRow(label: 'Billing', value: billingLabel),
                        const SizedBox(height: 16),
                        _ItemsSection(items: invoice.items),
                        const SizedBox(height: 16),
                        _TotalsCard(invoice: invoice),
                        const SizedBox(height: 18),
                        // Use main PaymentScreen for bill payment flow; it already
                        // contains the full invoice + payment UI for new orders.
                        // Here we just navigate to it with a special flag so it can
                        // fetch and display the existing bill for this order.
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
                            onPressed: billTotal <= 0
                                ? null
                                : () {
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.payment,
                                      arguments: {
                                        'mode': 'existingBill',
                                        'orderId': invoice.orderId,
                                      },
                                    );
                                  },
                            child: Text(
                              'Pay ${Pricing.inr(billTotal)}',
                              style: AppTextStyles.button(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: 1,
        onTap: (i) {
          // keep existing behavior
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
    );
  }

  String _formatBillingLabel(InvoiceDetails invoice) {
    final method = (invoice.bill.paymentMethod).toLowerCase();
    final paymentStatus = (invoice.bill.paymentStatus).toLowerCase();
    final methodLabel = method == 'cod' ? 'COD' : 'Card';

    if (paymentStatus == 'completed') {
      return 'Paid ($methodLabel)';
    }

    return 'Pending ($methodLabel)';
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _TopBar({required this.title, required this.onBack});

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
              title,
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

class _EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback onBack;

  const _EmptyState({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        _TopBar(title: 'Invoice', onBack: onBack),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        Expanded(
          child: Center(
            child: Text(
              message,
              style: AppTextStyles.body(color: HomeColors.muted),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 12),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.body(color: HomeColors.text).copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ItemsSection extends StatelessWidget {
  final List<InvoiceItem> items;

  const _ItemsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final perPiece = items.where((x) => x.pricingType == 'per_unit').toList();
    final kgWise = items.where((x) => x.pricingType == 'per_kg').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (perPiece.isNotEmpty) ...[
          Text(
            'Per-Piece Items',
            style: AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 14),
          ),
          const SizedBox(height: 8),
          for (final it in perPiece) _InvoiceItemCard(item: it),
          const SizedBox(height: 14),
        ],
        if (kgWise.isNotEmpty) ...[
          Text(
            'Kg-Wise Items',
            style: AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 14),
          ),
          const SizedBox(height: 8),
          for (final it in kgWise) _InvoiceItemCard(item: it),
        ],
      ],
    );
  }
}

class _InvoiceItemCard extends StatelessWidget {
  final InvoiceItem item;

  const _InvoiceItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final subtotal = (double.tryParse(item.subtotal) ?? 0).toInt();
    final unitPrice = (double.tryParse(item.unitPrice) ?? 0).toInt();
    final isKg = item.pricingType == 'per_kg';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.categoryName,
            style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            item.serviceName,
            style: AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (isKg) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Weight: ${item.weightKg ?? '—'} kg',
                    style: AppTextStyles.body(color: HomeColors.text).copyWith(fontSize: 12),
                  ),
                ),
                Text(
                  '${Pricing.inr(unitPrice)}/kg',
                  style: AppTextStyles.body(color: HomeColors.text).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ] else ...[
            for (final s in item.selections) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${s.clothName} x ${s.quantity}',
                      style: AppTextStyles.body(color: HomeColors.text).copyWith(fontSize: 12),
                    ),
                  ),
                  Text(
                    Pricing.inr((double.tryParse(s.subtotal) ?? 0).toInt()),
                    style: AppTextStyles.body(color: HomeColors.text).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ],
          const Divider(height: 18, thickness: 1, color: Color(0xFFE5E7EB)),
          Row(
            children: [
              Text(
                'Subtotal',
                style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 12),
              ),
              const Spacer(),
              Text(
                Pricing.inr(subtotal),
                style: AppTextStyles.header(color: HomeColors.primary).copyWith(fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final InvoiceDetails invoice;

  const _TotalsCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    int toInr(String v) => (double.tryParse(v) ?? 0).toInt();

    final subtotal = toInr(invoice.bill.subtotal);
    final deliveryFee = toInr(invoice.bill.deliveryFee);
    final tax = toInr(invoice.bill.taxAmount);
    final discount = toInr(invoice.bill.discount);
    final total = toInr(invoice.bill.finalAmount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Column(
        children: [
          _TotalRow(label: 'Subtotal', value: Pricing.inr(subtotal)),
          const SizedBox(height: 8),
          _TotalRow(label: 'Delivery fee', value: Pricing.inr(deliveryFee)),
          const SizedBox(height: 8),
          _TotalRow(label: 'Tax', value: Pricing.inr(tax)),
          const SizedBox(height: 8),
          _TotalRow(label: 'Discount', value: '- ${Pricing.inr(discount)}'),
          const Divider(height: 18, thickness: 1, color: Color(0xFFE5E7EB)),
          _TotalRow(
            label: 'Total',
            value: Pricing.inr(total),
            isEmphasis: true,
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmphasis;

  const _TotalRow({required this.label, required this.value, this.isEmphasis = false});

  @override
  Widget build(BuildContext context) {
    final style = isEmphasis
        ? AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 14)
        : AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 12);

    final valueStyle = isEmphasis
        ? AppTextStyles.header(color: HomeColors.primary).copyWith(fontSize: 14)
        : AppTextStyles.body(color: HomeColors.text).copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          );

    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: valueStyle),
      ],
    );
  }
}


