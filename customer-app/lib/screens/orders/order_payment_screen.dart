import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../repositories/payment_repository.dart';
import '../../services/checkout_session.dart';
import '../../services/payment_service.dart';
import '../../routes/route_args.dart';
import '../../utils/pricing.dart';
import '../home/widgets/home_colors.dart';
import 'order_payment_success_screen.dart';

class OrderPaymentScreen extends StatefulWidget {
  final String? orderId;
  final int itemTotal;
  final int handling;
  final int pickup;
  final int delivery;
  final int toPay;
  final int original;
  final OrderTrackingArgs tracking;

  const OrderPaymentScreen({
    super.key,
    this.orderId,
    required this.itemTotal,
    required this.handling,
    required this.pickup,
    required this.delivery,
    required this.toPay,
    required this.original,
    required this.tracking,
  });

  @override
  State<OrderPaymentScreen> createState() => _OrderPaymentScreenState();
}

enum _PayMode { visa, mastercard, cod }

class _OrderPaymentScreenState extends State<OrderPaymentScreen> with WidgetsBindingObserver {
  _PayMode _mode = _PayMode.visa;
  String? _notice;
  final CheckoutSession _checkout = CheckoutSession();
  late final Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onRazorpayWallet);
    _refreshStatus(navigateOnPaid: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _razorpay.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _checkout.pausedForExternalApp();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _refreshStatus(navigateOnPaid: true);
    }
  }

  void _setNotice(String message) {
    if (!mounted) return;
    setState(() => _notice = message);
  }

  String _noticeFor(PayIntentResult result) {
    switch (result.verificationState) {
      case 'paid':
        return 'Payment successful';
      case 'paid_cash':
        return 'Payment already completed';
      case 'failed':
        return 'Payment failed';
      case 'cancelled':
        return 'Payment cancelled';
      case 'refund_pending':
        return 'Refund pending';
      case 'refund_completed':
        return 'Refund completed';
      case 'verifying':
      case 'unknown':
        return paymentVerificationMessage;
      default:
        return '';
    }
  }

  Future<void> _refreshStatus({required bool navigateOnPaid}) async {
    final orderId = widget.orderId;
    if (orderId == null || orderId.isEmpty) return;
    try {
      final result = await PaymentRepository().paymentStatus(orderId: orderId);
      if (!mounted) return;
      _checkout.applyServerResult(result);
      final text = _checkout.message.isNotEmpty ? _checkout.message : _noticeFor(result);
      if (text.isNotEmpty && text != 'Pay Now') _setNotice(text);
      if (navigateOnPaid && result.isPaidOnline) _openSuccess();
    } catch (_) {}
  }

  Future<void> _pay() async {
    final orderId = widget.orderId;
    if (_mode == _PayMode.cod) {
      _setNotice('Cash is collected by the captain after an online payment fails. It is not marked paid here.');
      return;
    }
    if (!_checkout.begin()) {
      _setNotice(_checkout.message);
      return;
    }
    setState(() {});
    if (orderId == null || orderId.isEmpty) {
      _checkout.fail('Order ID missing for bill payment');
      _setNotice(_checkout.message);
      return;
    }
    try {
      final intent = await PaymentRepository().createPayIntent(orderId: orderId);
      if (!mounted) return;
      _checkout.applyServerResult(intent);
      if (_checkout.message.isNotEmpty && _checkout.message != 'Pay Now') _setNotice(_checkout.message);
      if (intent.isPaidOnline) {
        _openSuccess();
        return;
      }
      if (intent.verificationState == 'unknown' ||
          intent.verificationState == 'verifying' ||
          intent.verificationState == 'refund_pending' ||
          intent.verificationState == 'refund_completed') {
        return;
      }
      final launch = launchFromIntent(intent);
      if (launch == null) {
        _checkout.fail('Payment could not be started. Check the Razorpay keys and try again.');
        _setNotice(_checkout.message);
        return;
      }
      _checkout.awaitingExternalApp();
      _setNotice(_checkout.message);
      _razorpay.open(launch.toOptions());
    } catch (error) {
      if (!mounted) return;
      _checkout.unknown(describePaymentError(error));
      _setNotice(_checkout.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_checkout.message)),
      );
    }
  }

  Future<void> _onRazorpaySuccess(PaymentSuccessResponse response) async {
    final orderId = widget.orderId;
    if (orderId == null || !mounted) return;
    _checkout.verifying();
    _setNotice(_checkout.message);
    try {
      final result = await PaymentRepository().confirmRazorpay(
        orderId: orderId,
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );
      if (!mounted) return;
      _checkout.applyServerResult(result);
      if (result.verificationState == 'refund_pending' || result.verificationState == 'refund_completed') {
        _setNotice(_checkout.message);
        return;
      }
      if (!result.isPaidOnline) {
        _checkout.unknown(paymentVerificationMessage);
        _setNotice(_checkout.message);
        return;
      }
      _openSuccess();
    } catch (error) {
      if (!mounted) return;
      _checkout.unknown(describePaymentError(error));
      _setNotice(_checkout.message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_checkout.message)));
    }
  }

  Future<void> _onRazorpayError(PaymentFailureResponse response) async {
    if (!mounted) return;
    final orderId = widget.orderId;
    if (response.code == Razorpay.PAYMENT_CANCELLED && orderId != null && orderId.isNotEmpty) {
      try {
        final result = await PaymentRepository().cancelAttempt(orderId: orderId);
        if (!mounted) return;
        _checkout.applyServerResult(result);
        if (result.isPaidOnline) {
          _openSuccess();
          return;
        }
        if (result.verificationState == 'pending' ||
            result.verificationState == 'verifying' ||
            result.verificationState == 'unknown') {
          _checkout.unknown(paymentVerificationMessage);
        } else if (_checkout.phase == CheckoutPhase.idle || _checkout.phase == CheckoutPhase.awaiting) {
          _checkout.cancelled();
        }
        _setNotice(_checkout.message);
      } catch (error) {
        _checkout.unknown(describePaymentError(error));
        _setNotice(_checkout.message);
      }
      return;
    }
    final sdkMessage = (response.message ?? '').trim();
    _checkout.unknown(sdkMessage.isEmpty ? paymentVerificationMessage : sdkMessage);
    _setNotice(_checkout.message);
    await _refreshStatus(navigateOnPaid: true);
  }

  void _onRazorpayWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Continue in ${response.walletName ?? 'your wallet'}')),
    );
  }

  void _openSuccess() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderPaymentSuccessScreen(
          itemTotal: widget.itemTotal,
          handling: widget.handling,
          pickup: widget.pickup,
          delivery: widget.delivery,
          toPay: widget.toPay,
          original: widget.original,
          tracking: widget.tracking,
        ),
      ),
    );
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
                      'Payment',
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  _BillCard(
                    itemTotal: widget.itemTotal,
                    handling: widget.handling,
                    pickup: widget.pickup,
                    delivery: widget.delivery,
                    toPay: widget.toPay,
                    original: widget.original,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Choose Payment Mode',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2430),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ModeTile(
                    asset: 'assets/images/visa_icon.png',
                    title: 'Visa ending in 2361',
                    subtitle: 'Expiry 03/2028',
                    selected: _mode == _PayMode.visa,
                    onTap: () => setState(() => _mode = _PayMode.visa),
                  ),
                  const SizedBox(height: 10),
                  _ModeTile(
                    asset: 'assets/images/mastercard_icon.png',
                    title: 'Master ending in 4227',
                    subtitle: 'Expiry 11/2027',
                    selected: _mode == _PayMode.mastercard,
                    onTap: () => setState(() => _mode = _PayMode.mastercard),
                  ),
                  const SizedBox(height: 10),
                  _ModeTile(
                    asset: 'assets/images/cod_icon.png',
                    title: 'COD',
                    subtitle: 'Pay later',
                    selected: _mode == _PayMode.cod,
                    onTap: () => setState(() => _mode = _PayMode.cod),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_notice != null && _notice!.isNotEmpty) ...[
                    Text(
                      _notice!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF1F2430), fontSize: 13),
                    ),
                    if (_checkout.showRefresh)
                      TextButton(
                        onPressed: () => _refreshStatus(navigateOnPaid: true),
                        child: const Text('Refresh status'),
                      ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _checkout.blocksAnotherCheckout ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F6BFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _checkout.buttonLabel == 'Pay Now'
                            ? 'Pay ${Pricing.inr(widget.toPay)}'
                            : _checkout.buttonLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_double_arrow_right_rounded, size: 22),
                    ],
                  ),
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

class _BillCard extends StatelessWidget {
  final int itemTotal;
  final int handling;
  final int pickup;
  final int delivery;
  final int toPay;
  final int original;

  const _BillCard({
    required this.itemTotal,
    required this.handling,
    required this.pickup,
    required this.delivery,
    required this.toPay,
    required this.original,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF4)),
      ),
      child: Column(
        children: [
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
                        fontWeight: FontWeight.w400,
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
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF98A2B3),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AmountRow(label: 'Item Total', value: Pricing.inr(itemTotal)),
          const SizedBox(height: 12),
          _AmountRow(label: 'Handling Fee', value: Pricing.inr(handling)),
          const SizedBox(height: 12),
          _AmountRow(
            label: 'Pickup Fee: Free',
            value: Pricing.inr(pickup),
            struck: true,
            trailing: Pricing.inr(0),
          ),
          const SizedBox(height: 12),
          _AmountRow(label: 'Delivery Fee', value: Pricing.inr(delivery)),
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
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool struck;
  final String? trailing;

  const _AmountRow({
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

class _ModeTile extends StatelessWidget {
  final String asset;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTile({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8ECF4)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                height: 32,
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2430),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF98A2B3),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 22)
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD0D5DD), width: 1.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
