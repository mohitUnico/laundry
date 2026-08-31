import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../routes/app_routes.dart';
import '../../../../services/delivery_shift_service.dart';
import '../../../../services/delivery_staff_app_service.dart';
import '../../../../services/delivery_events_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../utils/auth_storage.dart';
import '../../../../utils/date_time_ist.dart';
import '../../../../utils/polling_config.dart';
import '../../../common/widgets/order_summary_card.dart';
import '../../../common/widgets/task_card.dart';
import '../../../common/widgets/bottom_nav_bar.dart';
import '../../../common/widgets/success_popup.dart';
import '../../../common/widgets/assignment_request_popup.dart';
import '../../../common/widgets/direct_assignment_popup.dart';

class HomeScreen extends StatefulWidget {
  final bool showBottomNav;

  const HomeScreen({
    super.key,
    this.showBottomNav = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedTabIndex = 0; // 0: Today's Tasks, 1: Completed
  int _bottomNavIndex = 0;
  final ImagePicker _imagePicker = ImagePicker();
  final DeliveryShiftService _shiftService = DeliveryShiftService();
  final DeliveryStaffAppService _deliveryStaffAppService = DeliveryStaffAppService();
  final DeliveryEventsService _eventsService = DeliveryEventsService();

  bool _isShiftActive = false; // Driven by GET /delivery-staff/shift/status; default Start Shift
  bool _isShiftToggling = false;
  bool _shiftStatusLoaded = false; // true after first shift status fetch
  String? _currentShiftId;
  Future<Map<String, dynamic>?> _userFuture = _loadStoredUser();
  Future<_HomeStatsUi> _statsFuture = Future.value(const _HomeStatsUi(inProgress: 0, completed: 0));
  Future<List<_AcceptedTaskUi>> _acceptedFuture = Future.value(const <_AcceptedTaskUi>[]);

  // Cache the latest UI data so we don't "blank" the screen on every refresh.
  _HomeStatsUi _statsCache = const _HomeStatsUi(inProgress: 0, completed: 0);
  List<_AcceptedTaskUi> _acceptedCache = const <_AcceptedTaskUi>[];
  bool _refreshingAccepted = false;

  Timer? _locationTimer;
  StreamSubscription<DeliverySseEvent>? _eventsSub;
  OverlayEntry? _incomingOverlay;
  OverlayEntry? _directAssignmentOverlay;
  bool _eventsConnecting = false;
  bool _isProcessingAssignment = false;
  final List<Map<String, dynamic>> _pendingAssignmentRequests = [];
  final Set<String> _processingRequestIds = {};
  PageController? _requestPageController;
  Timer? _homePollTimer;
  Timer? _refreshDebounce;
  Position? _lastPosition;
  DateTime? _lastPositionAt;
  Position? _lastSentPosition;
  DateTime? _lastSentAt;

  bool _isFirstBuild = true;

  static Future<Map<String, dynamic>?> _loadStoredUser() async {
    // Prefer delivery staff profile (snake_case, richer fields),
    // fallback to generic current user (camelCase from auth).
    final staff = await AuthStorage.getDeliveryStaff();
    return staff ?? await AuthStorage.getCurrentUser();
  }

  static String _readString(Map<String, dynamic>? map, String key) {
    final v = map?[key];
    return v == null ? '' : v.toString().trim();
  }

  @override
  void initState() {
    super.initState();
    // Always fetch fresh data when home screen initializes
    _userFuture = _loadStoredUser();
    _statsFuture = _loadStats().then((v) {
      if (mounted) {
        setState(() {
          _statsCache = v;
        });
      }
      return v;
    });
    _acceptedFuture = Future.wait<List<_AcceptedTaskUi>>([
      _loadAcceptedOrders(),
      _loadCompletedOrders(),
    ]).then((results) {
      final active = results[0];
      final completed = results[1];
      if (mounted) {
        setState(() {
          // Start with active orders, then merge completed ones
          _acceptedCache = active;
          _mergeAcceptedTasks(completed);
          _statsCache = _computeStatsFromAccepted(_acceptedCache);
        });
      }
      return active;
    });

    WidgetsBinding.instance.addObserver(this);
    // Register FCM token so backend can send assignment request push when app is closed
    NotificationService().refreshAndSaveToken();
    // Fetch shift status and then start location/events/polling if shift is active
    _loadShiftStatus();
  }

  /// Load GET /delivery-staff/shift/status and set _isShiftActive, _currentShiftId.
  /// If data is null or isActive is false → show Start Shift; else show Stop Shift and start services.
  Future<void> _loadShiftStatus() async {
    try {
      final body = await _shiftService.getShiftStatus();
      if (!mounted) return;
      final data = body['data'];
      final isActive = (data is Map) ? data['isActive'] : null;
      final hasActiveShift = isActive == true && data is Map;
      final shiftId = hasActiveShift
          ? ((data['shiftId'] ?? '').toString().trim())
          : '';
      setState(() {
        _shiftStatusLoaded = true;
        _isShiftActive = hasActiveShift;
        _currentShiftId = shiftId.isNotEmpty ? shiftId : null;
      });
      if (_isShiftActive) {
        _startLiveLocation();
        _startEvents();
        _startHomePolling();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _shiftStatusLoaded = true;
        _isShiftActive = false;
        _currentShiftId = null;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When shift is active and screen is visible, ensure SSE is subscribed so real-time notifications show
    if (!_isFirstBuild && _isShiftActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isShiftActive) {
          _startEvents(); // no-op if already subscribed
          _refreshHomeData();
        }
      });
    }
    _isFirstBuild = false;
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _stopLiveLocation();
    _stopEvents();
    _stopHomePolling();
    _refreshDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _removeIncomingPopup();
    _removeDirectAssignmentPopup();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isShiftActive) {
      _refreshHomeData();
      _startEvents();
      _startLiveLocation();
      _startHomePolling();
    } else if (state == AppLifecycleState.paused) {
      _stopHomePolling();
    }
  }

  void _refreshHomeData() {
    if (!mounted) return;
    // Refresh in-place: keep existing UI list and only merge new/updated items.
    _refreshStatsInPlace();
    _refreshAcceptedInPlace();
  }

  void _optimisticallyMarkPickupSubmitted(String deliveryId) {
    // Update local cache so button text changes immediately after marking pickup.
    setState(() {
      _acceptedCache = _acceptedCache.map((task) {
        if (task.deliveryId != deliveryId) return task;
        return _AcceptedTaskUi(
          deliveryId: task.deliveryId,
          orderId: task.orderId,
          taskType: task.taskType,
          scheduledTime: task.scheduledTime,
          customerName: task.customerName,
          address: task.address,
          phoneNumber: task.phoneNumber,
          itemCount: task.itemCount,
          amount: task.amount,
          buttonText: task.taskType == 'Pickup' ? 'Mark Submitted' : task.buttonText,
          iconPath: task.iconPath,
          destinationLat: task.destinationLat,
          destinationLng: task.destinationLng,
          orderStatus: 'picked_up',
        );
      }).toList(growable: false);
    });
  }

  void _scheduleHomeRefresh({bool forceApiCall = false}) {
    _refreshDebounce?.cancel();
    if (forceApiCall) {
      _refreshDebounce = Timer(const Duration(milliseconds: 400), _refreshHomeData);
    }
  }

  void _startHomePolling() {
    _homePollTimer?.cancel();
    if (!_isShiftActive) return;
    _homePollTimer = Timer.periodic(PollingConfig.deliveryHome, (_) {
      if (mounted && _isShiftActive) _refreshHomeData();
    });
  }

  void _stopHomePolling() {
    _homePollTimer?.cancel();
    _homePollTimer = null;
  }

  Future<void> _refreshStatsInPlace() async {
    if (!mounted) return;
    setState(() {
      _statsCache = _computeStatsFromAccepted(_acceptedCache);
    });
  }

  static String _acceptedTaskKey(_AcceptedTaskUi t) {
    final deliveryId = t.deliveryId.trim();
    if (deliveryId.isNotEmpty) return 'd:$deliveryId';
    final orderId = t.orderId.trim();
    return 'o:$orderId:${t.taskType}';
  }

  _HomeStatsUi _computeStatsFromAccepted(List<_AcceptedTaskUi> list) {
    var inProgress = 0;
    var completed = 0;
    for (final t in list) {
      // In-progress: only pickup leg orders in 'pickup_assigned' or 'picked_up' status.
      if (t.orderStatus == 'pickup_assigned' || t.orderStatus == 'picked_up') {
        inProgress++;
      }
      // Completed: orders that have reached submitted_to_cm or delivered.
      if (t.orderStatus == 'submitted_to_cm' || t.orderStatus == 'delivered') {
        completed++;
      }
    }
    return _HomeStatsUi(inProgress: inProgress, completed: completed);
  }

  void _mergeAcceptedTasks(List<_AcceptedTaskUi> fresh) {
    if (_acceptedCache.isEmpty) {
      _acceptedCache = fresh;
      return;
    }

    final existingKeys = <String>{};
    for (final t in _acceptedCache) {
      existingKeys.add(_acceptedTaskKey(t));
    }

    final freshByKey = <String, _AcceptedTaskUi>{};
    for (final t in fresh) {
      freshByKey[_acceptedTaskKey(t)] = t;
    }

    // Update existing items in-place. Keep items that are:
    // 1. Still in fresh list (active deliveries) - will be updated
    // 2. Completed (submitted_to_cm or delivered) - keep for Completed tab even if backend stops returning them
    // 3. Other statuses (might be temporary network issue) - keep for now
    final updatedExisting = _acceptedCache.where((t) {
      final k = _acceptedTaskKey(t);
      final isInFresh = freshByKey.containsKey(k);
      // If item is in fresh list, keep it (will be updated)
      if (isInFresh) return true;
      // If item is completed, KEEP it (needed for Completed tab even after backend stops returning it)
      if (t.orderStatus == 'submitted_to_cm' || t.orderStatus == 'delivered') {
        return true;
      }
      // Otherwise keep it (might be a temporary network issue)
      return true;
    }).map((t) {
      final next = freshByKey[_acceptedTaskKey(t)];
      return next ?? t;
    }).toList(growable: false);

    // Prepend any new items (keep order as returned by API: newest first).
    final newOnes = <_AcceptedTaskUi>[];
    for (final t in fresh) {
      final k = _acceptedTaskKey(t);
      if (!existingKeys.contains(k)) {
        newOnes.add(t);
      }
    }

    _acceptedCache = [...newOnes, ...updatedExisting];
  }

  Future<void> _refreshAcceptedInPlace() async {
    if (_refreshingAccepted) return;
    _refreshingAccepted = true;
    try {
      // Load both active and completed orders in parallel
      final activeFuture = _loadAcceptedOrders();
      final completedFuture = _loadCompletedOrders();
      final fresh = await activeFuture;
      final completed = await completedFuture;
      if (!mounted) return;
      setState(() {
        // Merge active orders first
        _mergeAcceptedTasks(fresh);
        // Then merge completed orders (they will be kept even if not in fresh list)
        _mergeAcceptedTasks(completed);
        _statsCache = _computeStatsFromAccepted(_acceptedCache);
      });
    } catch (_) {
      // Keep old list on failure (avoid reloading the whole screen).
    } finally {
      _refreshingAccepted = false;
    }
  }

  /// Used by pull-to-refresh: reload stats and accepted orders.
  Future<void> _onPullToRefresh() async {
    await _refreshStatsInPlace();
    await _refreshAcceptedInPlace();
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

      await _deliveryStaffAppService.updateLiveLocation(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
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
    if (!_isShiftActive) return;

    // Send first location immediately, then every 2 seconds via PATCH /api/v1/delivery-staff/location
    Future<void> sendLocationUpdate() async {
      if (!_isShiftActive) return;
      try {
        await _ensureLocationPermission();
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        _lastPosition = pos;
        _lastPositionAt = DateTime.now();
        await _deliveryStaffAppService.updateLiveLocation(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
        _lastSentPosition = pos;
        _lastSentAt = DateTime.now();
      } catch (_) {
        // Fire-and-forget; avoid spamming user
      }
    }

    sendLocationUpdate();

    _locationTimer = Timer.periodic(const Duration(seconds: 2), (_) => sendLocationUpdate());
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

  /// Shows a success popup message matching app theme
  /// Uses the reusable success popup widget
  void _showSuccessPopup(BuildContext context, {required String message, IconData icon = Icons.check_circle_outline}) {
    showSuccessPopup(context, message: message, icon: icon);
  }

  void _stopLiveLocation() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  /// Subscribes to GET /api/v1/delivery-staff/events (Accept: text/event-stream, Bearer token).
  /// Only runs when shift is active. Ensures real-time notifications are shown in the app.
  void _startEvents() {
    if (!_isShiftActive) return;
    if (_eventsSub != null || _eventsConnecting) return;
    _eventsConnecting = true;

    _eventsSub = _eventsService.connect().listen(
      (evt) {
        // Known events from backend SSE:
        // - connected
        // - notification (type: assignment_request, direct_assignment, assignment_cancelled, ...)
        // - direct_assignment, assignment_accepted, assignment_cancelled
        if (evt.event == 'notification') {
          final type = (evt.data['type'] ?? '').toString();
          if (type == 'assignment_request') {
            _showIncomingRequestPopup(evt.data);
            _scheduleHomeRefresh(forceApiCall: true);
            return;
          }
          if (type == 'direct_assignment') {
            _showDirectAssignmentPopup(evt.data);
            _scheduleHomeRefresh(forceApiCall: true);
            return;
          }
          if (type == 'assignment_cancelled') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('An assignment was cancelled'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
            _scheduleHomeRefresh(forceApiCall: true);
            return;
          }
          // Any other notification type - show generic message and refresh
          _showRealtimeNotificationSnackBar(evt.data);
          _scheduleHomeRefresh(forceApiCall: true);
          return;
        }

        if (evt.event == 'direct_assignment') {
          _showDirectAssignmentPopup(evt.data);
          _scheduleHomeRefresh(forceApiCall: true);
        } else if (evt.event == 'assignment_accepted') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Assignment confirmed'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          _scheduleHomeRefresh(forceApiCall: true);
        } else if (evt.event == 'assignment_cancelled') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('An assignment was cancelled'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          _scheduleHomeRefresh(forceApiCall: true);
        } else if (evt.event == 'connected') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connected to delivery updates'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          _scheduleHomeRefresh(forceApiCall: true);
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
    _requestPageController?.dispose();
    _requestPageController = null;
  }

  void _removeExpiredFromQueue() {
    final nowUtc = DateTime.now().toUtc();
    _pendingAssignmentRequests.removeWhere((r) {
      final payload = (r['payload'] is Map) ? (r['payload'] as Map).cast<String, dynamic>() : <String, dynamic>{};
      final expiresAt = parseUtc(payload['expiresAt']);
      return expiresAt != null && expiresAt.isBefore(nowUtc);
    });
  }

  void _removeFromQueue(String requestId) {
    _pendingAssignmentRequests.removeWhere((r) {
      final payload = (r['payload'] is Map) ? (r['payload'] as Map).cast<String, dynamic>() : <String, dynamic>{};
      return (payload['requestId'] ?? '').toString() == requestId;
    });
  }

  void _tryShowNextRequest() {
    if (!mounted) return;
    _removeExpiredFromQueue();
    if (_pendingAssignmentRequests.isEmpty) {
      _removeIncomingPopup();
      return;
    }
    _showIncomingRequestPopupCarousel();
  }

  void _removeDirectAssignmentPopup() {
    _directAssignmentOverlay?.remove();
    _directAssignmentOverlay = null;
  }

  /// Shows popup for direct assignment (manager assigned pickup/delivery). No accept/reject — OK to dismiss.
  void _showDirectAssignmentPopup(Map<String, dynamic> data) {
    if (!mounted) return;
    _removeDirectAssignmentPopup();
    // Payload may be in data.payload (notification) or data itself (event)
    final payload = (data['payload'] is Map)
        ? (data['payload'] as Map).cast<String, dynamic>()
        : data;
    final deliveryType = (payload['deliveryType'] ?? '').toString();
    final taskType = deliveryType == 'pickup' ? 'Pickup' : 'Delivery';
    final assignedAt = parseUtc(payload['assignedAt']);
    final assignedAtStr = assignedAt != null ? formatTimeIst(assignedAt) : '—';
    final itemCountRaw = payload['itemCount'];
    final itemCount = (itemCountRaw is num)
        ? itemCountRaw.toInt()
        : int.tryParse(itemCountRaw?.toString() ?? '') ?? 0;
    final pricingModel = (payload['pricingModel'] ?? '').toString().toLowerCase();
    final bool isPickupPerKg = deliveryType == 'pickup' && pricingModel == 'per_kg';
    final String? extraNote = isPickupPerKg ? 'Need to carry weight machine' : null;

    final entry = OverlayEntry(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final topPadding = mediaQuery.padding.top + 12;
        return Positioned(
          top: topPadding,
          left: 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: _TopSlidePopup(
              onClose: _removeDirectAssignmentPopup,
              child: DirectAssignmentPopup(
                taskType: taskType,
                assignedAtFormatted: assignedAtStr,
                itemCount: itemCount,
                extraNote: extraNote,
                onDismiss: _removeDirectAssignmentPopup,
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    _directAssignmentOverlay = entry;
  }

  /// Shows a short SnackBar for real-time SSE notifications that don't have a dedicated UI.
  void _showRealtimeNotificationSnackBar(Map<String, dynamic> data) {
    if (!mounted) return;
    final title = (data['title'] ?? '').toString().trim();
    final body = (data['body'] ?? '').toString().trim();
    final message = title.isNotEmpty
        ? (body.isNotEmpty ? '$title — $body' : title)
        : (body.isNotEmpty ? body : 'New update');
    if (message.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Enqueues incoming request and shows it (or next in queue). Deduplicates by requestId.
  void _showIncomingRequestPopup(Map<String, dynamic> notification) {
    final payload = (notification['payload'] is Map)
        ? (notification['payload'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final requestId = (payload['requestId'] ?? '').toString();

    if (requestId.isEmpty) {
      debugPrint('Warning: assignment_request notification missing requestId in payload: $notification');
      return;
    }

    // Deduplicate: don't add if already in queue
    final alreadyInQueue = _pendingAssignmentRequests.any((r) {
      final p = (r['payload'] is Map) ? (r['payload'] as Map).cast<String, dynamic>() : <String, dynamic>{};
      return (p['requestId'] ?? '').toString() == requestId;
    });
    if (alreadyInQueue) return;

    _pendingAssignmentRequests.add(notification);
    _removeExpiredFromQueue();

    // If no popup is showing, show the first request in queue.
    // If a popup is already visible (carousel), just rebuild it so the new
    // request appears as an extra page.
    if (_incomingOverlay == null) {
      _tryShowNextRequest();
    } else {
      _incomingOverlay?.markNeedsBuild();
    }
  }

  /// Shows all pending requests in a PageView carousel for swiping between them.
  void _showIncomingRequestPopupCarousel() {
    if (!mounted || _pendingAssignmentRequests.isEmpty) return;

    _removeExpiredFromQueue();
    if (_pendingAssignmentRequests.isEmpty) {
      _removeIncomingPopup();
      return;
    }

    _requestPageController?.dispose();
    _requestPageController = PageController(initialPage: 0);

    final entry = OverlayEntry(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final topPadding = mediaQuery.padding.top + 12;
        return Positioned(
          top: topPadding,
          left: 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: _TopSlidePopup(
              onClose: () {
                final currentIndex = _requestPageController?.page?.round() ?? 0;
                if (currentIndex < _pendingAssignmentRequests.length) {
                  final payload = (_pendingAssignmentRequests[currentIndex]['payload'] is Map)
                      ? (_pendingAssignmentRequests[currentIndex]['payload'] as Map).cast<String, dynamic>()
                      : <String, dynamic>{};
                  final requestId = (payload['requestId'] ?? '').toString();
                  _removeFromQueue(requestId);
                }
                _tryShowNextRequest();
              },
              child: _AssignmentRequestCarousel(
                requests: _pendingAssignmentRequests,
                pageController: _requestPageController!,
                isProcessing: _isProcessingAssignment,
                onAccept: (requestId) => _handleAcceptRequest(requestId),
                onReject: (requestId) => _handleRejectRequest(requestId),
                onPageChanged: () {
                  // Rebuild overlay when page changes to update request counter
                  _incomingOverlay?.markNeedsBuild();
                },
                onDismissAll: _dismissAllAssignmentRequests,
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(entry);
    _incomingOverlay = entry;

    // Auto-dismiss expired requests periodically
    _startExpiryTimer();
  }

  Timer? _expiryTimer;

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || _pendingAssignmentRequests.isEmpty) {
        _expiryTimer?.cancel();
        return;
      }
      final beforeCount = _pendingAssignmentRequests.length;
      _removeExpiredFromQueue();
      if (_pendingAssignmentRequests.length != beforeCount) {
        // Some requests expired, rebuild the carousel
        if (_pendingAssignmentRequests.isEmpty) {
          _removeIncomingPopup();
        } else {
          final currentPage = _requestPageController?.page?.round() ?? 0;
          final newPage = currentPage >= _pendingAssignmentRequests.length
              ? _pendingAssignmentRequests.length - 1
              : currentPage;
          _requestPageController?.animateToPage(
            newPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          _incomingOverlay?.markNeedsBuild();
        }
      }
    });
  }

  void _dismissAllAssignmentRequests() {
    _pendingAssignmentRequests.clear();
    _expiryTimer?.cancel();
    _removeIncomingPopup();
  }

  Future<void> _handleAcceptRequest(String requestId) async {
    if (_isProcessingAssignment || _processingRequestIds.contains(requestId)) return;

    _processingRequestIds.add(requestId);
    setState(() {
      _isProcessingAssignment = true;
    });

    try {
      await _deliveryStaffAppService.acceptAssignmentRequest(requestId: requestId);

      if (mounted) {
        _removeFromQueue(requestId);
        
        // If carousel is showing, rebuild it; otherwise close popup
        if (_incomingOverlay != null && _requestPageController != null) {
          _removeExpiredFromQueue();
          if (_pendingAssignmentRequests.isEmpty) {
            _removeIncomingPopup();
          } else {
            // Adjust page if needed
            final currentPage = _requestPageController!.page?.round() ?? 0;
            final newPage = currentPage >= _pendingAssignmentRequests.length
                ? _pendingAssignmentRequests.length - 1
                : currentPage;
            if (newPage != currentPage) {
              _requestPageController!.animateToPage(
                newPage,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
            _incomingOverlay?.markNeedsBuild();
          }
        } else {
          _removeIncomingPopup();
          _tryShowNextRequest();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment accepted successfully!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        _scheduleHomeRefresh(forceApiCall: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _processingRequestIds.remove(requestId);
      if (mounted) {
        setState(() {
          _isProcessingAssignment = false;
        });
      }
    }
  }

  Future<void> _handleRejectRequest(String requestId) async {
    if (_isProcessingAssignment || _processingRequestIds.contains(requestId)) return;

    _processingRequestIds.add(requestId);
    setState(() {
      _isProcessingAssignment = true;
    });

    try {
      await _deliveryStaffAppService.rejectAssignmentRequest(requestId: requestId);

      if (mounted) {
        _removeFromQueue(requestId);
        
        // If carousel is showing, rebuild it; otherwise close popup
        if (_incomingOverlay != null && _requestPageController != null) {
          _removeExpiredFromQueue();
          if (_pendingAssignmentRequests.isEmpty) {
            _removeIncomingPopup();
          } else {
            // Adjust page if needed
            final currentPage = _requestPageController!.page?.round() ?? 0;
            final newPage = currentPage >= _pendingAssignmentRequests.length
                ? _pendingAssignmentRequests.length - 1
                : currentPage;
            if (newPage != currentPage) {
              _requestPageController!.animateToPage(
                newPage,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
            _incomingOverlay?.markNeedsBuild();
          }
        } else {
          _removeIncomingPopup();
          _tryShowNextRequest();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment rejected'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _processingRequestIds.remove(requestId);
      if (mounted) {
        setState(() {
          _isProcessingAssignment = false;
        });
      }
    }
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
      // NOTE: backend sends orderId at the top-level, not inside `order`
      final orderId = (d['orderId'] ?? '').toString();
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
      final orderStatus = (order is Map ? order['orderStatus'] : null)?.toString() ?? '';
      final pickupButtonText = (orderStatus == 'picked_up') ? 'Mark Submitted' : 'Mark as Picked Up';
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
        buttonText: isPickup ? pickupButtonText : 'Start Delivery',
        iconPath: isPickup ? 'assets/icons/pickup.png' : 'assets/icons/out_for_delivery.png',
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        orderStatus: orderStatus,
      );
    }).toList();
  }

  /// Loads completed orders from history API and transforms them to _AcceptedTaskUi format.
  /// These are orders that have been completed (submitted_to_cm or delivered) by this delivery staff.
  Future<List<_AcceptedTaskUi>> _loadCompletedOrders() async {
    try {
      final body = await _deliveryStaffAppService.listOrderHistory(page: 1, limit: 50);
      final data = body['data'];
      if (data is! List) return const <_AcceptedTaskUi>[];

      final list = data.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList()
        ..sort((a, b) {
          final adt = _parseDate(a['date_of_delivery']);
          final bdt = _parseDate(b['date_of_delivery']);
          if (adt == null && bdt == null) return 0;
          if (adt == null) return 1;
          if (bdt == null) return -1;
          return bdt.compareTo(adt); // newest first
        });

      return list.map<_AcceptedTaskUi>((d) {
        final deliveryId = (d['delivery_id'] ?? '').toString();
        final orderId = (d['order_id'] ?? '').toString();
        final customerName = (d['customer_name'] ?? 'Customer').toString();
        final customerPhone = (d['customer_phone'] ?? '').toString();
        final deliveryType = (d['delivery_type'] ?? '').toString(); // 'pickup' or 'delivery'
        final itemCountRaw = d['number_of_order_items'] ?? d['quantity_count'];
        final itemCount = (itemCountRaw is num) ? itemCountRaw.toInt() : int.tryParse(itemCountRaw?.toString() ?? '') ?? 0;
        final completedAt = _parseDate(d['date_of_delivery']);
        final assignedAt = _parseDate(d['assigned_at']);
        final isPickup = deliveryType == 'pickup';

        // Extract address and coordinates from pickup or drop
        final pickup = d['pickup'];
        final drop = d['drop'];
        final address = (isPickup && pickup is Map)
            ? (pickup['address'] ?? '').toString()
            : (!isPickup && drop is Map)
                ? (drop['address'] ?? '').toString()
                : '—';

        final destinationLat = _parseDouble(
          (isPickup && pickup is Map)
              ? pickup['latitude']
              : (!isPickup && drop is Map)
                  ? drop['latitude']
                  : null,
        );
        final destinationLng = _parseDouble(
          (isPickup && pickup is Map)
              ? pickup['longitude']
              : (!isPickup && drop is Map)
                  ? drop['longitude']
                  : null,
        );

        // Extract preferred time range for display
        DateTime? preferredFrom;
        DateTime? preferredTo;
        if (isPickup && pickup is Map) {
          preferredFrom = _parseDate(pickup['preferredFrom'] ?? pickup['time']);
          preferredTo = _parseDate(pickup['preferredTo']);
        } else if (!isPickup && drop is Map) {
          preferredFrom = _parseDate(drop['preferredFrom'] ?? drop['time']);
          preferredTo = _parseDate(drop['preferredTo']);
        }
        final scheduledTime = _formatTimeRange(preferredFrom, preferredTo, fallback: completedAt ?? assignedAt);

        // For completed orders, use order_status from backend if available, otherwise infer from delivery type
        final orderStatusRaw = (d['order_status'] ?? '').toString();
        final orderStatus = orderStatusRaw.isNotEmpty
            ? orderStatusRaw
            : (isPickup ? 'submitted_to_cm' : 'delivered');

        return _AcceptedTaskUi(
          deliveryId: deliveryId,
          orderId: orderId,
          taskType: isPickup ? 'Pickup' : 'Delivery',
          scheduledTime: scheduledTime,
          customerName: customerName,
          address: (address.isNotEmpty) ? address : '—',
          phoneNumber: (customerPhone.isNotEmpty) ? customerPhone : '—',
          itemCount: itemCount,
          amount: '', // Amount not shown for delivery staff
          buttonText: 'Completed',
          iconPath: isPickup ? 'assets/icons/pickup.png' : 'assets/icons/out_for_delivery.png',
          destinationLat: destinationLat,
          destinationLng: destinationLng,
          orderStatus: orderStatus,
        );
      }).toList();
    } catch (e) {
      // If history API fails, return empty list (don't break the active orders display)
      return const <_AcceptedTaskUi>[];
    }
  }

  static String _formatTimeRange(DateTime? from, DateTime? to, {DateTime? fallback}) {
    final start = from ?? fallback;
    if (start == null) return '--';
    if (to == null) return formatTimeIst(start);
    return '${formatTimeIst(start)} - ${formatTimeIst(to)}';
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
        _stopHomePolling();
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
        _startLiveLocation();
        _startEvents();
        _startHomePolling();
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
          _userFuture = _loadStoredUser();
          _statsFuture = _loadStats();
          _acceptedFuture = _loadAcceptedOrders();
        });
      }
    }
  }

  static DateTime? _parseDate(Object? raw) {
    return parseUtc(raw);
  }

  static String _formatOrderIdDisplay(String orderId) {
    final normalized = orderId.replaceAll('-', '').toUpperCase();
    if (normalized.length >= 6) return 'ORD${normalized.substring(0, 6)}';
    if (normalized.isNotEmpty) return 'ORD$normalized';
    return 'ORDER';
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
                              final fullName = _readString(user, 'full_name').isNotEmpty
                                  ? _readString(user, 'full_name')
                                  : _readString(user, 'fullName');
                              final firstName = fullName.isNotEmpty
                                  ? fullName.split(RegExp(r'\s+')).first.trim()
                                  : '';

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    firstName.isNotEmpty ? 'Hi, $firstName' : 'Hi',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.title(
                                      color: AppColors.primary,
                                    ).copyWith(fontSize: 18, fontWeight: FontWeight.w700),
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
                                (_isShiftToggling || !_shiftStatusLoaded)
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                        ),
                                      )
                                    : Text(
                                        _isShiftActive ? 'Stop Shift' : 'Start Shift',
                                        style: AppTextStyles.button(
                                          color: _isShiftActive ? AppColors.error : AppColors.success,
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
                    final stats = _statsCache;
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
              child: Row(
                children: [
                  Expanded(
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
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 22),
                    splashRadius: 20,
                    color: AppColors.primary,
                    tooltip: 'Refresh',
                    onPressed: _isShiftActive
                        ? () {
                            _refreshHomeData();
                          }
                        : null,
                  ),
                ],
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
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavBar(
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
            )
          : null,
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
    return RefreshIndicator(
      onRefresh: _onPullToRefresh,
      child: FutureBuilder<List<_AcceptedTaskUi>>(
        future: _acceptedFuture,
        builder: (context, snapshot) {
          // If we already have items, keep showing them while refresh is in-flight.
          if (snapshot.connectionState == ConnectionState.waiting && _acceptedCache.isEmpty) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 300,
                child: Center(
                  child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
            );
          }

          if (snapshot.hasError && _acceptedCache.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 300,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }

          final allList = _acceptedCache.isNotEmpty ? _acceptedCache : (snapshot.data ?? const <_AcceptedTaskUi>[]);
          // For today's tasks, show:
          // - pickup leg orders where orderStatus is in the pickup flow (pickup_assigned / picked_up)
          // - drop leg orders that have been directly assigned or are out for delivery
          //   (dispatch_assigned / out_for_delivery)
          // Orders that are already submitted_to_cm or delivered are moved to the
          // Completed tab and should not appear here.
          final list = allList.where((t) {
            return t.orderStatus == 'pickup_assigned' ||
                t.orderStatus == 'picked_up' ||
                t.orderStatus == 'dispatch_assigned' ||
                t.orderStatus == 'out_for_delivery';
          }).toList();
          
          if (list.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 300,
                child: Center(
                  child: Text(
                    'No accepted orders',
                    style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            key: const PageStorageKey<String>('delivery_partner_home_accepted_tasks'),
            physics: const AlwaysScrollableScrollPhysics(),
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
                orderIdDisplay: _formatOrderIdDisplay(t.orderId),
                address: t.address,
                phoneNumber: t.phoneNumber,
                itemCount: t.itemCount,
                amount: t.amount,
                buttonText: t.buttonText,
                iconPath: t.iconPath,
                onButtonPressed: () async {
                  final isPickup = t.taskType == 'Pickup';
                  if (isPickup && t.orderStatus == 'picked_up') {
                    // After pickup is confirmed, delivery staff must "submit" to collection manager.
                    final closeLoader = _showBlockingLoader(context, message: 'Marking submitted...');
                    try {
                      await _deliveryStaffAppService.markSubmittedToCm(deliveryId: t.deliveryId);
                      closeLoader();
                      // Immediately update cache status to submitted_to_cm so it moves to completed tab
                      if (mounted) {
                        setState(() {
                          _acceptedCache = _acceptedCache.map((task) {
                            if (task.deliveryId == t.deliveryId) {
                              return _AcceptedTaskUi(
                                deliveryId: task.deliveryId,
                                orderId: task.orderId,
                                taskType: task.taskType,
                                scheduledTime: task.scheduledTime,
                                customerName: task.customerName,
                                address: task.address,
                                phoneNumber: task.phoneNumber,
                                itemCount: task.itemCount,
                                amount: task.amount,
                                buttonText: task.buttonText,
                                iconPath: task.iconPath,
                                destinationLat: task.destinationLat,
                                destinationLng: task.destinationLng,
                                orderStatus: 'submitted_to_cm', // Update status
                              );
                            }
                            return task;
                          }).toList(growable: false);
                        });
                      }
                      // Show success popup
                      if (mounted) {
                        _showSuccessPopup(context, message: 'Marked as Submitted ✓');
                      }
                      // Wait a bit for backend cache to expire, then refresh
                      await Future.delayed(const Duration(milliseconds: 500));
                      // Refresh data to ensure sync with backend
                      if (mounted) {
                        _refreshHomeData();
                      }
                      // If on today's tab, switch to completed tab to show the moved order
                      if (mounted && _selectedTabIndex == 0) {
                        setState(() {
                          _selectedTabIndex = 1;
                        });
                      }
                    } catch (e) {
                      closeLoader();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                        );
                      }
                    }
                    return;
                  }
                  _showTaskDialog(t.deliveryId, t.orderId, t.customerName, isPickup);
                },
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
    ),
    );
  }

  Widget _buildCompletedTasks() {
    return RefreshIndicator(
      onRefresh: _onPullToRefresh,
      child: FutureBuilder<List<_AcceptedTaskUi>>(
        future: _acceptedFuture,
        builder: (context, snapshot) {
          final allList = _acceptedCache.isNotEmpty ? _acceptedCache : (snapshot.data ?? const <_AcceptedTaskUi>[]);
          // Filter only completed orders (submitted_to_cm and delivered status)
          final completedList = allList.where((t) {
            return t.orderStatus == 'submitted_to_cm' || t.orderStatus == 'delivered';
          }).toList();

          if (completedList.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 300,
                child: Center(
                  child: Text(
                    'No completed tasks',
                    style: AppTextStyles.subtitle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            key: const PageStorageKey<String>('delivery_partner_home_completed_tasks'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: completedList.length,
            itemBuilder: (context, index) {
            final t = completedList[index];
            return TaskCard(
              taskType: t.taskType,
              scheduledTime: t.scheduledTime,
              customerName: t.customerName,
              orderIdDisplay: _formatOrderIdDisplay(t.orderId),
              address: t.address,
              phoneNumber: t.phoneNumber,
              itemCount: t.itemCount,
              amount: t.amount,
              buttonText: 'Completed',
              iconPath: t.iconPath,
              onButtonPressed: null, // Disable button for completed tasks
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
            );
          },
        );
      },
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
        // Handle null response (no per-kg items)
        if (data == null) {
          perKgItems = null;
        } else if (data is Map) {
          final items = data['perKgItems'];
          if (items is List && items.isNotEmpty) {
            perKgItems = items.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
          } else {
            perKgItems = null;
          }
        } else {
          perKgItems = null;
        }
      } catch (e) {
        // If fetch fails, continue without per-kg items
        print('Error fetching per-kg items: $e');
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
                    // Show per-kg weight fields ONLY if there are per-kg items AND weights not yet saved
                    if (perKgItems != null && perKgItems.isNotEmpty && !weightsSaved) ...[
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
                        child: StatefulBuilder(
                          builder: (context, setInnerState) {
                            bool isSaving = false;

                            Future<void> handleSave() async {
                              if (isSaving) return;
                              setInnerState(() => isSaving = true);

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
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter valid weights for all items'),
                                    ),
                                  );
                                }
                                setInnerState(() => isSaving = false);
                                return;
                              }

                              try {
                                await _deliveryStaffAppService.updatePerKgWeights(
                                  orderId: orderId,
                                  items: itemsToUpdate,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Weights saved successfully'),
                                    ),
                                  );
                                }
                                setState(() => weightsSaved = true);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceFirst('Exception: ', ''),
                                      ),
                                    ),
                                  );
                                }
                                setState(() => weightsSaved = false);
                              } finally {
                                if (mounted) {
                                  setInnerState(() => isSaving = false);
                                }
                              }
                            }

                            return ElevatedButton(
                              onPressed: isSaving ? null : handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: AppColors.primary.withOpacity(0.7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Save Weights',
                                      style: AppTextStyles.button(color: Colors.white),
                                    ),
                            );
                          },
                        ),
                      ),
                    ],
                    // Show photo upload ONLY if weights are saved (or no per-kg items)
                    if (weightsSaved) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Upload Photo*',
                        style: AppTextStyles.subtitle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
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
                        child: pickedImage == null
                            ? InkWell(
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
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 140,
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
                                            color: AppColors.divider.withOpacity(0.8),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.photo_camera_outlined,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Take a Photo',
                                        style: AppTextStyles.subtitle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(pickedImage!.path),
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () async {
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
                                            }
                                          },
                                          icon: const Icon(Icons.camera_alt, size: 18),
                                          label: const Text('Retake Photo'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ],
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

                                  setState(() => isSubmitting = true);
                                  try {
                                    if (isPickup) {
                                      await _deliveryStaffAppService.markPickedUpWithProof(
                                        deliveryId: deliveryId,
                                        file: pickedImage!,
                                      );
                                      // Optimistically update UI so button becomes "Mark Submitted"
                                      _optimisticallyMarkPickupSubmitted(deliveryId);
                                      if (mounted) {
                                        Navigator.of(dialogContext).pop();
                                        _showSuccessPopup(context, message: 'Pickup Confirmed ✓');
                                      }
                                      // Refresh data to update button text
                                      _refreshHomeData();
                                    } else {
                                      await _deliveryStaffAppService.markDeliveredWithProof(
                                        deliveryId: deliveryId,
                                        file: pickedImage!,
                                      );
                                      if (mounted) {
                                        Navigator.of(dialogContext).pop();
                                        _showSuccessPopup(context, message: 'Delivery Confirmed ✓');
                                      }
                                      // Immediately update cache status to delivered so it moves to completed tab
                                      if (mounted) {
                                        setState(() {
                                          _acceptedCache = _acceptedCache.map((task) {
                                            if (task.deliveryId == deliveryId) {
                                              return _AcceptedTaskUi(
                                                deliveryId: task.deliveryId,
                                                orderId: task.orderId,
                                                taskType: task.taskType,
                                                scheduledTime: task.scheduledTime,
                                                customerName: task.customerName,
                                                address: task.address,
                                                phoneNumber: task.phoneNumber,
                                                itemCount: task.itemCount,
                                                amount: task.amount,
                                                buttonText: task.buttonText,
                                                iconPath: task.iconPath,
                                                destinationLat: task.destinationLat,
                                                destinationLng: task.destinationLng,
                                                orderStatus: 'delivered', // Update status
                                              );
                                            }
                                            return task;
                                          }).toList(growable: false);
                                        });
                                      }
                                      // Wait a bit for backend cache to expire, then refresh
                                      await Future.delayed(const Duration(milliseconds: 500));
                                      // Refresh data to ensure sync with backend
                                      if (mounted) {
                                        _refreshHomeData();
                                      }
                                      // If on today's tab, switch to completed tab to show the moved order
                                      if (mounted && _selectedTabIndex == 0) {
                                        setState(() {
                                          _selectedTabIndex = 1;
                                        });
                                      }
                                    }
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
  final String orderStatus;

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
    required this.orderStatus,
  });
}

/// Carousel widget that displays multiple assignment requests in a swipeable PageView.
class _AssignmentRequestCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> requests;
  final PageController pageController;
  final bool isProcessing;
  final Function(String requestId) onAccept;
  final Function(String requestId) onReject;
  final VoidCallback onPageChanged;
   /// Callback to dismiss all current assignment requests from the queue.
   final VoidCallback onDismissAll;

  const _AssignmentRequestCarousel({
    required this.requests,
    required this.pageController,
    required this.isProcessing,
    required this.onAccept,
    required this.onReject,
    required this.onPageChanged,
    required this.onDismissAll,
  });

  @override
  State<_AssignmentRequestCarousel> createState() => _AssignmentRequestCarouselState();
}

class _AssignmentRequestCarouselState extends State<_AssignmentRequestCarousel> {
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onPageChanged);
    super.dispose();
  }

  void _onPageChanged() {
    final page = widget.pageController.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
      widget.onPageChanged();
    }
  }

  static double? _parseDouble(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String && raw.isNotEmpty) return double.tryParse(raw);
    return null;
  }

  Widget _buildRequestPopup(int index) {
    if (index >= widget.requests.length) return const SizedBox.shrink();
    
    final notification = widget.requests[index];
    final payload = (notification['payload'] is Map)
        ? (notification['payload'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final requestId = (payload['requestId'] ?? '').toString();
    if (requestId.isEmpty) return const SizedBox.shrink();

    final deliveryType = (payload['deliveryType'] ?? '').toString();
    final itemCountRaw = payload['itemCount'];
    final itemCount = (itemCountRaw is num) ? itemCountRaw.toInt() : int.tryParse(itemCountRaw?.toString() ?? '') ?? 0;
    final pickup = payload['pickup'];
    final drop = payload['drop'];
    final pickupMap = pickup is Map ? Map<String, dynamic>.from(pickup) : <String, dynamic>{};
    final dropMap = drop is Map ? Map<String, dynamic>.from(drop) : <String, dynamic>{};
    final pickupAddress = (pickupMap['address'] ?? '').toString();
    final dropAddress = (dropMap['address'] ?? '').toString();
    final pickupLat = _parseDouble(pickupMap['latitude']);
    final pickupLng = _parseDouble(pickupMap['longitude']);
    final dropLat = _parseDouble(dropMap['latitude']);
    final dropLng = _parseDouble(dropMap['longitude']);
    String address = (deliveryType == 'pickup')
        ? (pickupAddress.isNotEmpty ? pickupAddress : dropAddress)
        : (dropAddress.isNotEmpty ? dropAddress : pickupAddress);
    if (address.isEmpty) {
      address = pickupAddress.isNotEmpty ? pickupAddress : (dropAddress.isNotEmpty ? dropAddress : 'Address not available');
    }
    final expiresAt = parseUtc(payload['expiresAt']);
    final orderId = (payload['orderId'] ?? '').toString();

    // Try to derive customer name from payload where possible so that
    // the popup can show "Customer Name • ORDXYZ" instead of "New request".
    String customerName = '';
    final customerRaw = payload['customer'];
    if (customerRaw is Map) {
      final fullName = customerRaw['fullName'] ?? customerRaw['name'];
      if (fullName != null && fullName.toString().trim().isNotEmpty) {
        customerName = fullName.toString().trim();
      }
    }
    if (customerName.isEmpty) {
      final customerNameField = (payload['customerName'] ?? payload['customer_full_name'])?.toString().trim();
      if (customerNameField != null && customerNameField.isNotEmpty) {
        customerName = customerNameField;
      }
    }

    final taskType = deliveryType == 'pickup' ? 'Pickup' : 'Delivery';
    final scheduledTimeStr = expiresAt != null ? formatTimeIst(expiresAt) : null;
    final pricingModel = (payload['pricingModel'] ?? '').toString().toLowerCase();
    final bool isPickupPerKg = deliveryType == 'pickup' && pricingModel == 'per_kg';
    final String? extraNote = isPickupPerKg ? 'Need to carry weight machine' : null;
    final bool showItemCount = pricingModel == 'per_unit' || pricingModel == 'per_piece';

    final totalPending = widget.requests.length;
    final requestCounter = totalPending > 1 ? '${index + 1} of $totalPending' : null;

    return AssignmentRequestPopup(
      taskType: taskType,
      customerName: customerName.isNotEmpty ? customerName : 'New request',
      address: address.isNotEmpty ? address : 'Address not available',
      itemCount: itemCount,
      isProcessing: widget.isProcessing,
      onAccept: () => widget.onAccept(requestId),
      onReject: () => widget.onReject(requestId),
      title: 'Accept or Reject order',
      scheduledTime: scheduledTimeStr,
      extraNote: extraNote,
      showItemCount: showItemCount,
      pickupAddress: pickupAddress.isNotEmpty ? pickupAddress : null,
      dropAddress: dropAddress.isNotEmpty ? dropAddress : null,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropLat: dropLat,
      dropLng: dropLng,
      orderId: orderId.isNotEmpty ? orderId : null,
      requestCounter: requestCounter,
      onDismissAll: widget.onDismissAll,
      currentIndex: _currentPage,
      totalCount: totalPending,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.requests.isEmpty) return const SizedBox.shrink();

    // PageView requires bounded height; use ~70% of screen or fixed max
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return SizedBox(
      height: maxHeight,
      child: PageView.builder(
        controller: widget.pageController,
        itemCount: widget.requests.length,
        itemBuilder: (context, index) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildRequestPopup(index),
          ),
        ),
      ),
    );
  }
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
      child: widget.child,
    );
  }
}

