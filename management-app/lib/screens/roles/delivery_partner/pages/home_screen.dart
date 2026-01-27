import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../routes/app_routes.dart';
import '../../../../services/delivery_shift_service.dart';
import '../../../../services/delivery_staff_app_service.dart';
import '../../../../services/delivery_location_service.dart';
import '../../../../services/delivery_events_service.dart';
import '../../../../utils/auth_storage.dart';
import '../../../common/widgets/order_summary_card.dart';
import '../../../common/widgets/task_card.dart';
import '../../../common/widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedTabIndex = 0; // 0: Today's Tasks, 1: Completed
  int _bottomNavIndex = 0;
  final ImagePicker _imagePicker = ImagePicker();
  final DeliveryShiftService _shiftService = DeliveryShiftService();
  final DeliveryStaffAppService _deliveryStaffAppService = DeliveryStaffAppService();
  final DeliveryLocationService _locationService = DeliveryLocationService();
  final DeliveryEventsService _eventsService = DeliveryEventsService();

  bool _isShiftActive = true;
  bool _isShiftToggling = false;
  String? _currentShiftId; // Track active shift ID for Supabase location inserts
  Future<Map<String, dynamic>?> _userFuture = AuthStorage.getCurrentUser();
  Future<_HomeStatsUi> _statsFuture = Future.value(const _HomeStatsUi(inProgress: 0, completed: 0));
  Future<List<_AcceptedTaskUi>> _acceptedFuture = Future.value(const <_AcceptedTaskUi>[]);

  Timer? _locationTimer;
  StreamSubscription<DeliverySseEvent>? _eventsSub;
  OverlayEntry? _incomingOverlay;
  bool _eventsConnecting = false;
  Timer? _refreshDebounce;
  DateTime? _lastRealtimeEventAt;
  Position? _lastPosition;
  DateTime? _lastPositionAt;
  Position? _lastSentPosition;
  DateTime? _lastSentAt;

  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    // Always fetch fresh data when home screen initializes
    _userFuture = AuthStorage.getCurrentUser();
    _statsFuture = _loadStats();
    _acceptedFuture = _loadAcceptedOrders();

    WidgetsBinding.instance.addObserver(this);
    if (_isShiftActive) {
      _startLiveLocation();
      _startEvents();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible after first build (e.g., navigating back from orders screen)
    // This ensures fresh data is always shown, not cached from other screens
    if (!_isFirstBuild && _isShiftActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshHomeData();
        }
      });
    }
    _isFirstBuild = false;
  }

  @override
  void dispose() {
    _stopLiveLocation();
    _stopEvents();
    _refreshDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _removeIncomingPopup();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isShiftActive) {
      _refreshHomeData();
      _startEvents(); // if stream died in background, ensure reconnect
      _startLiveLocation(); // ensure continuous DB updates after background
    }
  }

  void _refreshHomeData() {
    if (!mounted) return;
    setState(() {
      _statsFuture = _loadStats();
      _acceptedFuture = _loadAcceptedOrders();
    });
  }

  void _scheduleHomeRefresh() {
    _lastRealtimeEventAt = DateTime.now();
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 400), _refreshHomeData);
  }

  static double? _parseDouble(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String && raw.isNotEmpty) return double.tryParse(raw);
    return null;
  }

  Future<void> _openDirectionsTo({
    required double destinationLat,
    required double destinationLng,
  }) async {
    if (!mounted) return;
    final loader = _showBlockingLoader(context, message: 'Opening Maps...');
    try {
      await _ensureLocationPermission();
      final cached = _lastPosition;
      final cachedAt = _lastPositionAt;
      final isCacheFresh =
          cached != null && cachedAt != null && DateTime.now().difference(cachedAt) <= const Duration(seconds: 20);

      final pos = isCacheFresh
          ? cached
          : await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Push latest position to backend immediately (in addition to periodic updates).
      final user = await _userFuture;
      final staffId = (user?['userId'] ?? '').toString().trim();
      if (staffId.isNotEmpty) {
        await _locationService.updateLocation(
          staffId: staffId,
          shiftId: _currentShiftId,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      }
      _lastPosition = pos;
      _lastPositionAt = DateTime.now();

      // Launch Google Maps directions (no API key required for external navigation).
      final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${pos.latitude},${pos.longitude}'
        '&destination=$destinationLat,$destinationLng'
        '&travelmode=driving',
      );

      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps for directions')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '').trim())),
      );
    } finally {
      loader();
    }
  }

  Future<void> _ensureLocationPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Please enable location services');
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      throw Exception('Location permission is required');
    }
  }

  void _startLiveLocation() {
    _stopLiveLocation();

    // Send one immediately so tracking starts right away.
    () async {
      if (!_isShiftActive) return;
      try {
        await _ensureLocationPermission();
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        await _sendLocationIfNeeded(pos, force: true);
        _lastPosition = pos;
        _lastPositionAt = DateTime.now();
      } catch (_) {
        // ignore
      }
    }();

    // Send location periodically while shift is active, but throttled to avoid rate limiting.
    // Also skip sending if driver hasn't moved enough.
    _locationTimer = Timer.periodic(const Duration(seconds: 25), (_) async {
      if (!_isShiftActive) return;
      try {
        await _ensureLocationPermission();
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        await _sendLocationIfNeeded(pos);
        _lastPosition = pos;
        _lastPositionAt = DateTime.now();
      } catch (_) {
        // keep silent to avoid spamming; user will see errors when needed elsewhere
      }
    });
  }

  Future<void> _sendLocationIfNeeded(Position pos, {bool force = false}) async {
    final now = DateTime.now();
    final lastAt = _lastSentAt;
    final lastPos = _lastSentPosition;

    if (!force) {
      // Time-based throttle: never send more frequently than every 20 seconds.
      if (lastAt != null && now.difference(lastAt) < const Duration(seconds: 20)) {
        return;
      }

      // Distance-based throttle: if we have a previous sent position, only send after moving ~25m.
      if (lastPos != null) {
        final meters = Geolocator.distanceBetween(
          lastPos.latitude,
          lastPos.longitude,
          pos.latitude,
          pos.longitude,
        );
        if (meters < 25) return;
      }
    }

    // Get staffId from current user
    final user = await _userFuture;
    final staffId = (user?['userId'] ?? '').toString().trim();
    if (staffId.isEmpty) return; // Can't update location without staffId

    await _locationService.updateLocation(
      staffId: staffId,
      shiftId: _currentShiftId,
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
    _lastSentPosition = pos;
    _lastSentAt = now;
  }

  /// Shows a small blocking loader overlay; returns a function to close it safely.
  VoidCallback _showBlockingLoader(BuildContext context, {required String message}) {
    var closed = false;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    message,
                    style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return () {
      if (closed) return;
      closed = true;
      if (!mounted) return;
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) nav.pop();
    };
  }

  void _stopLiveLocation() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  void _startEvents() {
    if (_eventsSub != null || _eventsConnecting) return;
    _eventsConnecting = true;

    _eventsSub = _eventsService.connect().listen(
      (evt) {
        _lastRealtimeEventAt = DateTime.now();

        // Known events emitted by backend realtime hub:
        // - connected
        // - notification (type: assignment_request, direct_assignment, assignment_cancelled, ...)
        // - direct_assignment
        // - assignment_accepted
        // - assignment_cancelled
        if (evt.event == 'notification') {
          final type = (evt.data['type'] ?? '').toString();
          if (type == 'assignment_request') {
            _showIncomingRequestPopup(evt.data);
            _scheduleHomeRefresh(); // keep stats/list updated
            return;
          }
          if (type == 'direct_assignment' || type == 'assignment_cancelled') {
            _scheduleHomeRefresh();
            return;
          }
          return;
        }

        if (evt.event == 'direct_assignment' ||
            evt.event == 'assignment_accepted' ||
            evt.event == 'assignment_cancelled' ||
            evt.event == 'connected') {
          _scheduleHomeRefresh();
        }
      },
      onError: (_) async {
        _eventsSub?.cancel();
        _eventsSub = null;
        _eventsConnecting = false;

        // Basic reconnect while shift is active.
        if (_isShiftActive) {
          await Future.delayed(const Duration(seconds: 3));
          if (mounted && _isShiftActive) {
            _startEvents();
            _scheduleHomeRefresh();
          }
        }
      },
      onDone: () async {
        _eventsSub = null;
        _eventsConnecting = false;

        if (_isShiftActive) {
          await Future.delayed(const Duration(seconds: 3));
          if (mounted && _isShiftActive) {
            _startEvents();
            _scheduleHomeRefresh();
          }
        }
      },
      cancelOnError: false,
    );

    _eventsConnecting = false;
  }

  void _stopEvents() {
    _eventsSub?.cancel();
    _eventsSub = null;
    _eventsConnecting = false;
  }

  void _removeIncomingPopup() {
    _incomingOverlay?.remove();
    _incomingOverlay = null;
  }

  void _showIncomingRequestPopup(Map<String, dynamic> notification) {
    _removeIncomingPopup();

    // notification payload comes from backend delivery-operations service
    final payload = (notification['payload'] is Map) ? (notification['payload'] as Map).cast<String, dynamic>() : <String, dynamic>{};
    final deliveryType = (payload['deliveryType'] ?? '').toString(); // pickup/drop
    final itemCountRaw = payload['itemCount'];
    final itemCount = (itemCountRaw is num) ? itemCountRaw.toInt() : int.tryParse(itemCountRaw?.toString() ?? '') ?? 0;
    final pickup = payload['pickup'];
    final drop = payload['drop'];
    final address = (deliveryType == 'pickup')
        ? (pickup is Map ? pickup['address'] : null)?.toString()
        : (drop is Map ? drop['address'] : null)?.toString();

    final customerName = 'New request';
    final taskType = deliveryType == 'pickup' ? 'Pickup' : 'Delivery';

    final entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: _TopSlidePopup(
              onClose: _removeIncomingPopup,
              child: TaskCard(
                taskType: taskType,
                scheduledTime: 'Now',
                customerName: customerName,
                address: (address ?? '').isNotEmpty ? address! : '—',
                phoneNumber: '—',
                itemCount: itemCount,
                amount: '',
                buttonText: 'OK',
                iconPath: deliveryType == 'pickup' ? 'assets/icons/pickup.png' : 'assets/icons/out_for_delivery.png',
                onButtonPressed: _removeIncomingPopup,
                onMapPressed: () {
                  // TODO: map navigation using payload coordinates
                },
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(entry);
    _incomingOverlay = entry;

    // Auto-dismiss after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) _removeIncomingPopup();
    });
  }

  Future<_HomeStatsUi> _loadStats() async {
    final body = await _deliveryStaffAppService.getHomeStats();
    final data = body['data'];
    if (data is! Map) throw Exception('Invalid response: missing data');
    final map = data.cast<String, dynamic>();
    final inProgressRaw = map['inProgress'];
    final completedRaw = map['completed'];
    final inProgress = (inProgressRaw is num) ? inProgressRaw.toInt() : int.tryParse(inProgressRaw?.toString() ?? '') ?? 0;
    final completed = (completedRaw is num) ? completedRaw.toInt() : int.tryParse(completedRaw?.toString() ?? '') ?? 0;
    return _HomeStatsUi(inProgress: inProgress, completed: completed);
  }

  Future<List<_AcceptedTaskUi>> _loadAcceptedOrders() async {
    final body = await _deliveryStaffAppService.listAcceptedOrders(page: 1, limit: 20);
    final data = body['data'];
    if (data is! List) throw Exception('Invalid response: missing data list');

    final list = data.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList()
      ..sort((a, b) {
        final adt = _parseDate(a['assignedAt']);
        final bdt = _parseDate(b['assignedAt']);
        if (adt == null && bdt == null) return 0;
        if (adt == null) return 1;
        if (bdt == null) return -1;
        return bdt.compareTo(adt); // newest first
      });

    return list.map<_AcceptedTaskUi>((d) {
      final deliveryType = (d['deliveryType'] ?? '').toString();
      final deliveryId = (d['deliveryId'] ?? '').toString();

      final order = d['order'];
      final orderId = (order is Map ? order['orderId'] : null)?.toString() ?? '';
      final customer = (order is Map ? order['customer'] : null);
      final customerName = (customer is Map ? customer['fullName'] : null)?.toString() ?? 'Customer';
      final phone = (customer is Map ? customer['phone'] : null)?.toString() ?? '—';

      final pickup = d['pickup'];
      final drop = d['drop'];
      final address = (deliveryType == 'pickup')
          ? (pickup is Map ? pickup['address'] : null)?.toString()
          : (drop is Map ? drop['address'] : null)?.toString();

      final destinationLat =
          _parseDouble((deliveryType == 'pickup' && pickup is Map) ? pickup['latitude'] : (drop is Map ? drop['latitude'] : null));
      final destinationLng =
          _parseDouble((deliveryType == 'pickup' && pickup is Map) ? pickup['longitude'] : (drop is Map ? drop['longitude'] : null));

      final assignedAt = _parseDate(d['assignedAt']);
      DateTime? preferredFrom;
      DateTime? preferredTo;
      if (deliveryType == 'pickup' && pickup is Map) {
        preferredFrom = _parseDate(pickup['preferredFrom']);
        preferredTo = _parseDate(pickup['preferredTo']);
        preferredFrom ??= _parseDate(pickup['time']);
      } else if (deliveryType != 'pickup' && drop is Map) {
        preferredFrom = _parseDate(drop['preferredFrom']);
        preferredTo = _parseDate(drop['preferredTo']);
        preferredFrom ??= _parseDate(drop['time']);
      }
      final scheduledTime = _formatTimeRange(preferredFrom, preferredTo, fallback: assignedAt);

      // Amount intentionally not shown for delivery staff (salary-based).
      const amountText = '';

      final itemCountRaw = d['itemCount'];
      final itemCount = (itemCountRaw is num) ? itemCountRaw.toInt() : int.tryParse(itemCountRaw?.toString() ?? '') ?? 0;

      final isPickup = deliveryType == 'pickup';
      return _AcceptedTaskUi(
        deliveryId: deliveryId,
        orderId: orderId,
        taskType: isPickup ? 'Pickup' : 'Delivery',
        scheduledTime: scheduledTime,
        customerName: customerName,
        address: (address ?? '').isNotEmpty ? address! : '—',
        phoneNumber: phone,
        itemCount: itemCount,
        amount: amountText,
        buttonText: isPickup ? 'Mark as Picked Up' : 'Start Delivery',
        iconPath: isPickup ? 'assets/icons/pickup.png' : 'assets/icons/out_for_delivery.png',
        destinationLat: destinationLat,
        destinationLng: destinationLng,
      );
    }).toList();
  }

  static String _formatTimeRange(DateTime? from, DateTime? to, {DateTime? fallback}) {
    final start = from ?? fallback;
    if (start == null) return '--';
    if (to == null) return _formatTime(start);
    return '${_formatTime(start)} - ${_formatTime(to)}';
  }

  Future<void> _toggleShift() async {
    if (_isShiftToggling) return;
    setState(() {
      _isShiftToggling = true;
    });

    try {
      if (_isShiftActive) {
        final body = await _shiftService.stopShift();
        final data = body['data'];
        final isActive = (data is Map) ? data['isActive'] : null;
        setState(() {
          _isShiftActive = isActive is bool ? isActive : false;
          _currentShiftId = null; // Clear shift ID when shift stops
        });
        _stopLiveLocation();
        _stopEvents();
        _removeIncomingPopup();
      } else {
        final body = await _shiftService.startShift();
        final data = body['data'];
        final isActive = (data is Map) ? data['isActive'] : null;
        final shiftId = (data is Map) ? (data['shiftId'] ?? '').toString().trim() : null;
        setState(() {
          _isShiftActive = isActive is bool ? isActive : true;
          _currentShiftId = shiftId?.isNotEmpty == true ? shiftId : null;
        });
        // Start continuous location updates + SSE events stream until end shift.
        _startLiveLocation();
        _startEvents();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isShiftActive ? 'Shift started' : 'Shift stopped')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '').trim())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isShiftToggling = false;
          _userFuture = AuthStorage.getCurrentUser();
          _statsFuture = _loadStats();
          _acceptedFuture = _loadAcceptedOrders();
        });
      }
    }
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  static String _formatTime(DateTime? dt) {
    if (dt == null) return '--';
    int hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '${hour.toString().padLeft(2, '0')}:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  // Profile Section
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/icons/profile_pic_demo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FutureBuilder<Map<String, dynamic>?>(
                            future: _userFuture,
                            builder: (context, snapshot) {
                              final user = snapshot.data;
                              final fullName = (user?['fullName'] ?? '').toString().trim();
                              final firstName = fullName.isNotEmpty
                                  ? fullName.split(RegExp(r'\s+')).first.trim()
                                  : '';
                              final userId = (user?['userId'] ?? '').toString().trim();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    firstName.isNotEmpty ? 'Hi, $firstName' : 'Hi',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.title(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        'ID: ',
                                        style: AppTextStyles.subtitle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 160),
                                        child: userId.isNotEmpty
                                            ? SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: Text(
                                                  userId,
                                                  maxLines: 1,
                                                  softWrap: false,
                                                  style: AppTextStyles.subtitle(
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                '—',
                                                style: AppTextStyles.subtitle(
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // End Shift Button
                  InkWell(
                    onTap: _toggleShift,
                    borderRadius: BorderRadius.circular(26),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: SizedBox(
                      height: 44,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/icons/home_screen/end_shift.png',
                                  width: 18,
                                  height: 18,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 12),
                                _isShiftToggling
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
                                        ),
                                      )
                                    : Text(
                                        _isShiftActive ? 'End Shift' : 'Start Shift',
                                        style: AppTextStyles.button(
                                          color: _isShiftActive ? AppColors.error : AppColors.primary,
                                        ).copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 0,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0x00FF3B30),
                                    Color(0xFFFF3B30),
                                    Color(0x00FF3B30),
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Orders Summary Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orders',
                    style: AppTextStyles.header(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<_HomeStatsUi>(
                    future: _statsFuture,
                    builder: (context, snapshot) {
                      final stats = snapshot.data ?? const _HomeStatsUi(inProgress: 0, completed: 0);
                      return Row(
                        children: [
                          OrderSummaryCard(
                            label: 'In Progress',
                            count: stats.inProgress,
                            iconAsset: 'assets/icons/home_screen/in_progress.png',
                          ),
                          const SizedBox(width: 12),
                          OrderSummaryCard(
                            label: 'Completed',
                            count: stats.completed,
                            iconAsset: 'assets/icons/home_screen/completed.png',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Task Filter Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E0FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        label: "Today's Tasks",
                        isSelected: _selectedTabIndex == 0,
                        onTap: () => setState(() => _selectedTabIndex = 0),
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        label: 'Completed',
                        isSelected: _selectedTabIndex == 1,
                        onTap: () => setState(() => _selectedTabIndex = 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Task List
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildTodaysTasks()
                  : _buildCompletedTasks(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          setState(() => _bottomNavIndex = index);
          // Handle navigation
          switch (index) {
            case 0:
              // Refresh home data when tapping home tab
              if (_isShiftActive) {
                _refreshHomeData();
              }
              break;
            case 1:
              Navigator.pushReplacementNamed(context, AppRoutes.orders);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, AppRoutes.help);
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.profile);
              break;
          }
        },
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF283897),
                      Color(0xFF0F73F7),
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.button(
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysTasks() {
    return FutureBuilder<List<_AcceptedTaskUi>>(
      future: _acceptedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                snapshot.error.toString().replaceFirst('Exception: ', ''),
                style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final list = snapshot.data ?? const <_AcceptedTaskUi>[];
        if (list.isEmpty) {
          return Center(
            child: Text(
              'No accepted orders',
              style: AppTextStyles.subtitle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final t = list[index];
            return GestureDetector(
              onTap: () => _showTaskDialog(t.deliveryId, t.orderId, t.customerName, t.taskType == 'Pickup'),
              child: TaskCard(
                taskType: t.taskType,
                scheduledTime: t.scheduledTime,
                customerName: t.customerName,
                address: t.address,
                phoneNumber: t.phoneNumber,
                itemCount: t.itemCount,
                amount: t.amount,
                buttonText: t.buttonText,
                iconPath: t.iconPath,
                onButtonPressed: () => _showTaskDialog(t.deliveryId, t.orderId, t.customerName, t.taskType == 'Pickup'),
                onMapPressed: () {
                   final lat = t.destinationLat;
                   final lng = t.destinationLng;
                   if (lat == null || lng == null) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Location coordinates not available for this order')),
                     );
                     return;
                   }
                   _openDirectionsTo(destinationLat: lat, destinationLng: lng);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedTasks() {
    return Center(
      child: Text(
        'No completed tasks',
        style: AppTextStyles.subtitle(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  void _showTaskDialog(String deliveryId, String orderId, String customerName, bool isPickup) async {
    // Fetch per-kg items if it's a pickup order
    List<Map<String, dynamic>>? perKgItems;
    if (isPickup && orderId.isNotEmpty) {
      try {
        final body = await _deliveryStaffAppService.getPerKgItems(orderId: orderId);
        final data = body['data'];
        if (data is Map) {
          final items = data['perKgItems'];
          if (items is List) {
            perKgItems = items.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
          }
        }
      } catch (e) {
        // If fetch fails, continue without per-kg items
        perKgItems = null;
      }
    }

    if (!mounted) return;
    _showTaskDialogInternal(deliveryId, orderId, customerName, isPickup, perKgItems);
  }

  void _showTaskDialogInternal(
    String deliveryId,
    String orderId,
    String customerName,
    bool isPickup,
    List<Map<String, dynamic>>? perKgItems,
  ) {
    final Map<String, TextEditingController> weightControllers = {};
    if (perKgItems != null && perKgItems.isNotEmpty) {
      for (final item in perKgItems) {
        final itemId = (item['orderItemId'] ?? '').toString();
        final currentWeight = item['weightKg'];
        final weightStr = (currentWeight is num) ? currentWeight.toString() : (currentWeight?.toString() ?? '');
        weightControllers[itemId] = TextEditingController(text: weightStr);
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        XFile? pickedImage;
        bool weightsSaved = perKgItems == null || perKgItems.isEmpty;
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isPickup ? 'Pickup Details' : 'Delivery Details',
                          style: AppTextStyles.header(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          splashRadius: 20,
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        text: 'Customer: ',
                        style: AppTextStyles.body(
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: customerName,
                            style: AppTextStyles.title(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Show per-kg weight fields only if there are per-kg items
                    if (perKgItems != null && perKgItems.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Item Weights (kg)*',
                        style: AppTextStyles.subtitle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...perKgItems.map((item) {
                        final itemId = (item['orderItemId'] ?? '').toString();
                        final serviceName = (item['serviceName'] ?? 'Item').toString();
                        final categoryName = (item['categoryName'] ?? '').toString();
                        final itemName = categoryName.isNotEmpty ? '$categoryName • $serviceName' : serviceName;
                        final controller = weightControllers[itemId] ?? TextEditingController();
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemName,
                                style: AppTextStyles.body(color: AppColors.textPrimary).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: controller,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: 'Enter weight in kg',
                                  filled: true,
                                  fillColor: AppColors.background,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Validate all weights are entered
                            bool allValid = true;
                            final itemsToUpdate = <Map<String, dynamic>>[];
                            
                            for (final item in perKgItems!) {
                              final itemId = (item['orderItemId'] ?? '').toString();
                              final controller = weightControllers[itemId];
                              final weightStr = controller?.text.trim() ?? '';
                              final weight = double.tryParse(weightStr);
                              
                              if (weight == null || weight <= 0) {
                                allValid = false;
                                break;
                              }
                              
                              itemsToUpdate.add({
                                'orderItemId': itemId,
                                'weightKg': weight,
                              });
                            }
                            
                            if (!allValid || itemsToUpdate.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter valid weights for all items')),
                              );
                              return;
                            }
                            
                            // Save weights
                            try {
                              await _deliveryStaffAppService.updatePerKgWeights(
                                orderId: orderId,
                                items: itemsToUpdate,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Weights saved successfully')),
                                );
                              }
                              setState(() => weightsSaved = true);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                                );
                              }
                              setState(() => weightsSaved = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            'Save Weights',
                            style: AppTextStyles.button(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      'Upload Photo*',
                      style: AppTextStyles.subtitle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        final status = await Permission.camera.request();
                        if (!status.isGranted) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Camera permission is required to take photos'),
                              ),
                            );
                          }
                          return;
                        }
                        final image = await _imagePicker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                        );
                        if (image != null) {
                          setState(() => pickedImage = image);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Photo captured successfully'),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.divider.withOpacity(0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                  color:
                                      AppColors.divider.withOpacity(0.8),
                                ),
                              ),
                              child: Icon(
                                pickedImage == null
                                    ? Icons.photo_camera_outlined
                                    : Icons.check,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              pickedImage == null
                                  ? 'Take a Photo'
                                  : 'Photo Added',
                              style: AppTextStyles.subtitle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFF283897),
                              Color(0xFF0F73F7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (pickedImage == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please take a photo first')),
                                    );
                                    return;
                                  }
                                  if (!weightsSaved) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please save weights before confirming pickup')),
                                    );
                                    return;
                                  }

                                  setState(() => isSubmitting = true);
                                  try {
                                    if (isPickup) {
                                      await _deliveryStaffAppService.markPickedUpWithProof(
                                        deliveryId: deliveryId,
                                        file: pickedImage!,
                                      );
                                    } else {
                                      await _deliveryStaffAppService.markDeliveredWithProof(
                                        deliveryId: deliveryId,
                                        file: pickedImage!,
                                      );
                                    }

                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(isPickup ? 'Pickup marked successfully' : 'Delivered successfully')),
                                      );
                                    }

                                    Navigator.of(dialogContext).pop();
                                    _refreshHomeData();
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                                      );
                                    }
                                  } finally {
                                    if (mounted) setState(() => isSubmitting = false);
                                  }
                                },
                          child: Text(
                            isSubmitting
                                ? (isPickup ? 'Confirming...' : 'Saving...')
                                : (isPickup ? 'Confirm Pickup' : 'Confirm Delivery'),
                            style: AppTextStyles.button(
                              color: Colors.white,
                            ).copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HomeStatsUi {
  final int inProgress;
  final int completed;

  const _HomeStatsUi({required this.inProgress, required this.completed});
}

class _AcceptedTaskUi {
  final String deliveryId;
  final String orderId;
  final String taskType;
  final String scheduledTime;
  final String customerName;
  final String address;
  final String phoneNumber;
  final int itemCount;
  final String amount;
  final String buttonText;
  final String iconPath;
  final double? destinationLat;
  final double? destinationLng;

  const _AcceptedTaskUi({
    required this.deliveryId,
    required this.orderId,
    required this.taskType,
    required this.scheduledTime,
    required this.customerName,
    required this.address,
    required this.phoneNumber,
    required this.itemCount,
    required this.amount,
    required this.buttonText,
    required this.iconPath,
    required this.destinationLat,
    required this.destinationLng,
  });
}

class _TopSlidePopup extends StatefulWidget {
  final Widget child;
  final VoidCallback onClose;

  const _TopSlidePopup({
    required this.child,
    required this.onClose,
  });

  @override
  State<_TopSlidePopup> createState() => _TopSlidePopupState();
}

class _TopSlidePopupState extends State<_TopSlidePopup> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onClose,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

