import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class AssignmentRequestPopup extends StatefulWidget {
  final String taskType; // 'Pickup' or 'Delivery'
  final String customerName;
  final String address;
  final int itemCount;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isProcessing;
  /// Optional title shown above the card (e.g. "Notification for delivery boy, to Accept or Reject order").
  final String? title;
  /// Optional time shown top-right (e.g. "10:00 AM").
  final String? scheduledTime;
  /// Optional amount/earning (e.g. "\$12.00" or "₹120").
  final String? amount;
  /// Optional note shown in the card (e.g. "Need to carry weight machine" for pickup + per_kg).
  final String? extraNote;
  /// When true, show item count (per_unit/per_piece orders). When false (per_kg), hide item count.
  final bool showItemCount;
  /// Optional pickup address for expanded view.
  final String? pickupAddress;
  /// Optional drop address for expanded view.
  final String? dropAddress;
  /// Optional pickup lat/lng for map URL.
  final double? pickupLat;
  final double? pickupLng;
  /// Optional drop lat/lng for map URL.
  final double? dropLat;
  final double? dropLng;
  /// Optional order ID for expanded view.
  final String? orderId;
  /// Optional request counter (e.g. "1 of 3").
  final String? requestCounter;
  /// Optional callback to dismiss all current assignment requests from the queue.
  /// This is wired from the delivery partner home screen and clears all pending
  /// requests when the user taps the bottom "Dismiss all" button.
  final VoidCallback? onDismissAll;
  /// Index of the current request in the carousel (0-based). Used to render
  /// page indicators directly under the dismiss button.
  final int? currentIndex;
  /// Total number of pending requests in the carousel.
  final int? totalCount;

  const AssignmentRequestPopup({
    super.key,
    required this.taskType,
    required this.customerName,
    required this.address,
    required this.itemCount,
    required this.onAccept,
    required this.onReject,
    this.isProcessing = false,
    this.title,
    this.scheduledTime,
    this.amount,
    this.extraNote,
    this.showItemCount = true,
    this.pickupAddress,
    this.dropAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.orderId,
    this.requestCounter,
    this.onDismissAll,
    this.currentIndex,
    this.totalCount,
  });

  @override
  State<AssignmentRequestPopup> createState() => _AssignmentRequestPopupState();
}

class _AssignmentRequestPopupState extends State<AssignmentRequestPopup> {
  bool _isExpanded = false;

  bool get _hasLocationDetails =>
      ((widget.pickupLat != null && widget.pickupLng != null) ||
          (widget.dropLat != null && widget.dropLng != null)) &&
      ((widget.pickupAddress != null && widget.pickupAddress!.isNotEmpty) ||
          (widget.dropAddress != null && widget.dropAddress!.isNotEmpty));

  Future<void> _openMapUrl() async {
    final pickLat = widget.pickupLat;
    final pickLng = widget.pickupLng;
    final dropLat = widget.dropLat;
    final dropLng = widget.dropLng;
    String? url;
    if (pickLat != null && pickLng != null && dropLat != null && dropLng != null) {
      url = 'https://www.google.com/maps/dir/$pickLat,$pickLng/$dropLat,$dropLng';
    } else if (pickLat != null && pickLng != null) {
      url = 'https://www.google.com/maps?q=$pickLat,$pickLng';
    } else if (dropLat != null && dropLng != null) {
      url = 'https://www.google.com/maps?q=$dropLat,$dropLng';
    }
    if (url != null) {
      final uri = Uri.parse(url);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        try {
          await launchUrl(uri);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open Maps. Please check your device settings.'),
              ),
            );
          }
        }
      }
    }
  }

  Widget _buildLocationRow(IconData icon, String label, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.subtitle(color: color).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: AppTextStyles.subtitle(color: AppColors.textSecondary).copyWith(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Derive a short, human-friendly order ID similar to the customer app (e.g. ORDC1C24E)
    String? shortOrderId;
    final fullOrderId = widget.orderId ?? '';
    if (fullOrderId.isNotEmpty) {
      final normalized = fullOrderId.replaceAll('-', '').toUpperCase().trim();
      if (normalized.length >= 6) {
        shortOrderId = 'ORD${normalized.substring(0, 6)}';
      } else if (normalized.isNotEmpty) {
        shortOrderId = 'ORD$normalized';
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null && widget.title!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title!,
                    style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (widget.requestCounter != null && widget.requestCounter!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.requestCounter!,
                      style: AppTextStyles.subtitle(color: AppColors.primary).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.divider.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Pickup/Delivery (left), Time (right)
                Row(
                  children: [
                    Text(
                      widget.taskType,
                      style: AppTextStyles.stepTitle(
                        color: AppColors.primary,
                      ).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.scheduledTime ?? '—',
                      style: AppTextStyles.body(
                        color: AppColors.primaryLight,
                      ).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: AppColors.divider.withOpacity(0.3),
                ),
                const SizedBox(height: 14),
                // Customer row: avatar, name + address + items, amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.12),
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            // When collapsed, show short order ID (like "ORDC1C24E") instead of
                            // "New request". When expanded, show "Customer Name • ORDC1C24E"
                            // so staff can see both who the order belongs to and the order id.
                            () {
                              final name = widget.customerName;
                              if (_isExpanded) {
                                if (name.isNotEmpty && shortOrderId != null) {
                                  return '$name • $shortOrderId';
                                }
                                if (name.isNotEmpty) return name;
                                return shortOrderId ?? 'New request';
                              } else {
                                return shortOrderId ?? (name.isNotEmpty ? name : 'New request');
                              }
                            }(),
                            style: AppTextStyles.listItemTitle(
                              color: AppColors.textPrimary,
                            ).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _hasLocationDetails ? () => setState(() => _isExpanded = !_isExpanded) : null,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.address.isNotEmpty ? widget.address : 'Address not available',
                                    style: AppTextStyles.subtitle(
                                      color: AppColors.textSecondary,
                                    ).copyWith(fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  _hasLocationDetails
                                      ? (_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down)
                                      : Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                          if (_hasLocationDetails) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => setState(() => _isExpanded = !_isExpanded),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.expand_more,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isExpanded ? 'Hide details' : 'View pickup & drop on map',
                                    style: AppTextStyles.subtitle(color: AppColors.primary).copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isExpanded) ...[
                              const SizedBox(height: 12),
                              if (widget.pickupAddress != null && widget.pickupAddress!.isNotEmpty)
                                _buildLocationRow(
                                  Icons.trip_origin,
                                  'Pickup',
                                  widget.pickupAddress!,
                                  AppColors.primary,
                                ),
                              if (widget.dropAddress != null && widget.dropAddress!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _buildLocationRow(
                                  Icons.location_on,
                                  'Drop',
                                  widget.dropAddress!,
                                  AppColors.success,
                                ),
                              ],
                              if ((widget.pickupLat != null && widget.pickupLng != null) ||
                                  (widget.dropLat != null && widget.dropLng != null)) ...[
                                const SizedBox(height: 10),
                                InkWell(
                                  onTap: _openMapUrl,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.info.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.info.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.map_outlined, size: 20, color: AppColors.info),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Open in Google Maps',
                                          style: AppTextStyles.subtitle(color: AppColors.info).copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              if (widget.orderId != null && widget.orderId!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Order #${widget.orderId!.length > 8 ? widget.orderId!.substring(0, 8) : widget.orderId}',
                                  style: AppTextStyles.subtitle(color: AppColors.textSecondary).copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ],
                          if (widget.showItemCount) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.itemCount} ${widget.itemCount == 1 ? 'item' : 'items'}',
                                  style: AppTextStyles.subtitle(
                                    color: AppColors.textSecondary,
                                  ).copyWith(fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                          if (widget.extraNote != null && widget.extraNote!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.scale_outlined,
                                  size: 16,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.extraNote!,
                                    style: AppTextStyles.subtitle(
                                      color: AppColors.warning,
                                    ).copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.amount != null && widget.amount!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        widget.amount!,
                        style: AppTextStyles.listItemTitle(
                          color: AppColors.textPrimary,
                        ).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                // Accept & Reject buttons
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.isProcessing ? null : widget.onAccept,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryDark,
                                  AppColors.primary,
                                  AppColors.primaryLight,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: widget.isProcessing
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Accept',
                                    style: AppTextStyles.button(
                                      color: Colors.white,
                                    ).copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.isProcessing ? null : widget.onReject,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          backgroundColor: Colors.white,
                        ),
                        child: Text(
                          'Reject',
                          style: AppTextStyles.button(
                            color: AppColors.primary,
                          ).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.onDismissAll != null) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: widget.isProcessing ? null : widget.onDismissAll,
                      child: Text(
                        'Dismiss all',
                        style: AppTextStyles.subtitle(color: AppColors.textSecondary).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
                if (widget.currentIndex != null &&
                    widget.totalCount != null &&
                    widget.totalCount! > 1) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.totalCount!,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.currentIndex == index
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
