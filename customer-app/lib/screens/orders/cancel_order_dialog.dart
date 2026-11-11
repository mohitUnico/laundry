import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../home/widgets/home_colors.dart';

const _otherReason = 'Something else';

const _cancelReasons = [
  'Change of plans',
  'Booked by mistake',
  'Pickup is taking too long',
  _otherReason,
];

/// "Are you sure you want to cancel?" pop-up with the reason options.
/// Returns the reason when the customer taps Yes, or null when they keep the order.
Future<String?> showCancelOrderDialog(
  BuildContext context, {
  required String orderCode,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CancelOrderDialog(orderCode: orderCode),
  );
}

class _CancelOrderDialog extends StatefulWidget {
  final String orderCode;

  const _CancelOrderDialog({required this.orderCode});

  @override
  State<_CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<_CancelOrderDialog> {
  final _otherController = TextEditingController();
  String? _reason;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  /// The text sent as `reason`: the preset label, or what was typed for "Something else".
  /// Null until it is valid (3 to 500 characters, as in the orders contract).
  String? get _finalReason {
    final reason = _reason;
    if (reason == null) return null;
    if (reason != _otherReason) return reason;
    final typed = _otherController.text.trim();
    return typed.length >= 3 ? typed : null;
  }

  @override
  Widget build(BuildContext context) {
    final reason = _finalReason;
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Are you sure you want to cancel?',
        style: AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.orderCode} - cancelling now is free, nothing has been charged. Tell us why.',
              style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            for (final option in _cancelReasons)
              _ReasonRow(
                label: option,
                selected: _reason == option,
                onTap: () => setState(() => _reason = option),
              ),
            if (_reason == _otherReason) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _otherController,
                maxLength: 500,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Tell us more',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'No, keep it',
            style: AppTextStyles.header(color: HomeColors.muted).copyWith(fontSize: 14),
          ),
        ),
        TextButton(
          onPressed: reason == null ? null : () => Navigator.of(context).pop(reason),
          child: Text(
            'Yes, cancel',
            style: AppTextStyles.header(
              color: reason == null ? HomeColors.muted : HomeColors.primary,
            ).copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _ReasonRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? HomeColors.primary : HomeColors.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body(color: HomeColors.text).copyWith(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
