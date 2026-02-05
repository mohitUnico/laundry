import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../routes/app_routes.dart';
import '../../../../services/delivery_shift_service.dart';
import '../../../../services/delivery_staff_app_service.dart';
import '../../../../services/delivery_location_service.dart';
import '../../../../services/delivery_events_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../utils/auth_storage.dart';
import '../../../../utils/supabase_config.dart';
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
  final DeliveryLocationService _locationService = DeliveryLocationService();
  final DeliveryEventsService _eventsService = DeliveryEventsService();

  bool _isShiftActive = false; // Driven by GET /delivery-staff/shift/status; default Start Shift
  bool _isShiftToggling = false;
  bool _shiftStatusLoaded = false; // true after first shift status fetch
  String? _currentShiftId; // Track active shift ID for Supabase location inserts
  Future<Map<String, dynamic>?> _userFuture = _loadStoredUser();
  Future<_HomeStatsUi> _statsFuture = Future.value(const _HomeStatsUi(inProgress: 0, completed: 0));
  Future<List<_AcceptedTaskUi>> _acceptedFuture = Future.value(const <_AcceptedTaskUi>[]);

  // Cache the latest UI data so we don't "blank" the screen on every refresh.
  _HomeStatsUi _statsCache = const _HomeStatsUi(inProgress: 0, completed: 0);
  List<_AcceptedTaskUi> _acceptedCache = const <_AcceptedTaskUi>[];
  bool _refreshingStats = false;
  bool _refreshingAccepted = false;

  Timer? _locationTimer;
  StreamSubscription<DeliverySseEvent>? _eventsSub;
  OverlayEntry? _incomingOverlay;
  OverlayEntry? _directAssignmentOverlay;
  bool _eventsConnecting = false;
  bool _isProcessingAssignment = false;
  String? _currentRequestId;
  Timer? _refreshDebounce;
  DateTime? _lastRealtimeEventAt;
  Position? _lastPosition;
  DateTime? _lastPositionAt;
  Position? _lastSentPosition;
  DateTime? _lastSentAt;
  RealtimeChannel? _deliveriesChannel;
  RealtimeChannel? _ordersChannel;

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
    _acceptedFuture = _loadAcceptedOrders().then((v) {
      if (mounted) {
        setState(() {
          _acceptedCache = v;
        });
      }
      return v;
    });

    WidgetsBinding.instance.addObserver(this);
    // Register FCM token so backend can send assignment request push when app is closed
    NotificationService().refreshAndSaveToken();
    // Fetch shift status and then start location/events/realtime if shift is active
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
        _subscribeToRealtime();
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
    _stopLiveLocation();
    _stopEvents();
    _unsubscribeFromRealtime();
    _refreshDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _removeIncomingPopup();
    _removeDirectAssignmentPopup();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isShiftActive) {
      // Only refresh if we haven't received realtime updates recently
      // This avoids unnecessary API calls when realtime is working
      final lastEvent = _lastRealtimeEventAt;
      if (lastEvent == null || DateTime.now().difference(lastEvent).inSeconds > 30) {
        _refreshHomeData();
      }
      _startEvents(); // if stream died in background, ensure reconnect
      _startLiveLocation(); // ensure continuous DB updates after background
      _subscribeToRealtime(); // ensure realtime subscriptions are active
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
    _lastRealtimeEventAt = DateTime.now();
    _refreshDebounce?.cancel();
    // Only make API calls when forceApiCall is true (e.g., new assignment needs full data)
    // Otherwise, rely on Supabase realtime to update UI directly
    if (forceApiCall) {
      _refreshDebounce = Timer(const Duration(milliseconds: 400), _refreshHomeData);
    }
  }

  Future<void> _refreshStatsInPlace() async {
    if (_refreshingStats) return;
    _refreshingStats = true;
    try {
      final next = await _loadStats();
      if (!mounted) return;
      setState(() {
        _statsCache = next;
      });
    } catch (_) {
      // Keep old stats on failure (avoid screen jitter).
    } finally {
      _refreshingStats = false;
    }
  }

  static String _acceptedTaskKey(_AcceptedTaskUi t) {
    final deliveryId = t.deliveryId.trim();
    if (deliveryId.isNotEmpty) return 'd:$deliveryId';
    final orderId = t.orderId.trim();
    return 'o:$orderId:${t.taskType}';
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

    // Update existing items in-place, but only keep items that are still in fresh list
    // OR items that are not completed (submitted_to_cm or delivered)
    final updatedExisting = _acceptedCache.where((t) {
      final k = _acceptedTaskKey(t);
      final isInFresh = freshByKey.containsKey(k);
      // If item is in fresh list, keep it (will be updated)
      if (isInFresh) return true;
      // If item is not in fresh list but is completed, remove it
      if (t.orderStatus == 'submitted_to_cm' || t.orderStatus == 'delivered') {
        return false;
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
      final fresh = await _loadAcceptedOrders();
      if (!mounted) return;
      setState(() {
        _mergeAcceptedTasks(fresh);
      });
    } catch (_) {
      // Keep old list on failure (avoid reloading the whole screen).
    } finally {
      _refreshingAccepted = false;
    }
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
        _lastRealtimeEventAt = DateTime.now();

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
          final lastEvent = _lastRealtimeEventAt;
          if (lastEvent == null || DateTime.now().difference(lastEvent).inSeconds > 30) {
            _scheduleHomeRefresh(forceApiCall: true);
          }
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

  void _subscribeToRealtime() {
    if (!SupabaseConfig.isEnabled) return;

    try {
      final client = Supabase.instance.client;
      final user = _userFuture;
      
      // Subscribe to deliveries table changes for this delivery partner
      user.then((u) async {
        if (u == null || !mounted) return;
        final staffId = (u['userId'] ?? '').toString().trim();
        if (staffId.isEmpty) return;

        // Subscribe to deliveries where this staff is assigned
        _deliveriesChannel = client
            .channel('delivery_partner:deliveries:$staffId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'deliveries',
              callback: (payload) {
                if (!mounted) return;
                _lastRealtimeEventAt = DateTime.now();
                
                final eventType = payload.eventType.name.toLowerCase();
                final newRow = (payload.newRecord as Map?)?.cast<String, dynamic>();
                final oldRow = (payload.oldRecord as Map?)?.cast<String, dynamic>();
                
                // Update UI directly from realtime payload (no API call)
                _applyDeliveryRealtimeChange(
                  eventType: eventType,
                  newRow: newRow,
                  oldRow: oldRow,
                  staffId: staffId,
                );
              },
            )
            .subscribe();

        // Subscribe to orders table changes (for order status updates)
        _ordersChannel = client
            .channel('delivery_partner:orders:$staffId')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'orders',
              callback: (payload) {
                if (!mounted) return;
                _lastRealtimeEventAt = DateTime.now();
                
                final newRow = (payload.newRecord as Map?)?.cast<String, dynamic>();
                if (newRow == null) return;
                
                // Update order status in accepted tasks list directly
                _applyOrderRealtimeChange(newRow: newRow);
              },
            )
            .subscribe();
      }).catchError((_) {
        // Ignore errors - app will work without realtime
      });
    } catch (_) {
      // Ignore errors - app will work without realtime
    }
  }

  void _unsubscribeFromRealtime() {
    _deliveriesChannel?.unsubscribe();
    _deliveriesChannel = null;
    _ordersChannel?.unsubscribe();
    _ordersChannel = null;
  }

  void _applyDeliveryRealtimeChange({
    required String eventType,
    required Map<String, dynamic>? newRow,
    required Map<String, dynamic>? oldRow,
    required String staffId,
  }) {
    if (eventType == 'delete') {
      // Remove delivery from accepted tasks
      final deliveryId = _readString(oldRow, 'delivery_id');
      if (deliveryId.isNotEmpty) {
        setState(() {
          _acceptedCache = _acceptedCache.where((t) => t.deliveryId != deliveryId).toList();
          // Update stats - decrement inProgress
          if (_statsCache.inProgress > 0) {
            _statsCache = _HomeStatsUi(
              inProgress: _statsCache.inProgress - 1,
              completed: _statsCache.completed,
            );
          }
        });
      }
      return;
    }

    // INSERT / UPDATE
    final row = newRow ?? const <String, dynamic>{};
    if (row.isEmpty) return;

    final deliveryId = _readString(row, 'delivery_id');
    final assignedStaffId = _readString(row, 'staff_id');
    
    // Only process if this delivery is assigned to current staff
    if (deliveryId.isEmpty || assignedStaffId != staffId) return;

    final deliveryStatus = _readString(row, 'delivery_status');
    final orderId = _readString(row, 'order_id');
    
    // Update existing task in accepted list
    final existingIndex = _acceptedCache.indexWhere((t) => t.deliveryId == deliveryId);
    if (existingIndex >= 0) {
      // Update existing task
      final existing = _acceptedCache[existingIndex];
      setState(() {
        _acceptedCache[existingIndex] = _AcceptedTaskUi(
          deliveryId: deliveryId,
          orderId: orderId.isNotEmpty ? orderId : existing.orderId,
          taskType: existing.taskType,
          scheduledTime: existing.scheduledTime,
          customerName: existing.customerName,
          phoneNumber: existing.phoneNumber,
          address: existing.address,
          itemCount: existing.itemCount,
          amount: existing.amount,
          buttonText: existing.buttonText,
          iconPath: existing.iconPath,
          destinationLat: existing.destinationLat,
          destinationLng: existing.destinationLng,
          orderStatus: deliveryStatus.isNotEmpty ? deliveryStatus : existing.orderStatus,
        );
        
        // Update stats based on status change
        if (deliveryStatus == 'completed' || deliveryStatus == 'delivered') {
          if (existing.orderStatus != 'completed' && existing.orderStatus != 'delivered') {
            _statsCache = _HomeStatsUi(
              inProgress: _statsCache.inProgress > 0 ? _statsCache.inProgress - 1 : 0,
              completed: _statsCache.completed + 1,
            );
          }
        }
      });
    } else if (eventType == 'insert' && deliveryStatus != 'completed' && deliveryStatus != 'delivered') {
      // New delivery assigned - need to fetch full details via API
      _scheduleHomeRefresh(forceApiCall: true);
    }
  }

  void _applyOrderRealtimeChange({required Map<String, dynamic> newRow}) {
    final orderId = _readString(newRow, 'order_id');
    final orderStatus = _readString(newRow, 'order_status');
    
    if (orderId.isEmpty) return;

    // Update order status in accepted tasks
    final updated = _acceptedCache.map<_AcceptedTaskUi>((t) {
      if (t.orderId == orderId) {
        return _AcceptedTaskUi(
          deliveryId: t.deliveryId,
          orderId: t.orderId,
          taskType: t.taskType,
          scheduledTime: t.scheduledTime,
          customerName: t.customerName,
          phoneNumber: t.phoneNumber,
          address: t.address,
          itemCount: t.itemCount,
          amount: t.amount,
          buttonText: t.buttonText,
          iconPath: t.iconPath,
          destinationLat: t.destinationLat,
          destinationLng: t.destinationLng,
          orderStatus: orderStatus.isNotEmpty ? orderStatus : t.orderStatus,
        );
      }
      return t;
    }).toList();

    if (updated != _acceptedCache) {
      setState(() {
        _acceptedCache = updated;
      });
    }
  }

  void _removeIncomingPopup() {
    _incomingOverlay?.remove();
    _incomingOverlay = null;
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
    final assignedAtRaw = payload['assignedAt'];
    final assignedAt = assignedAtRaw is DateTime
        ? assignedAtRaw
        : (assignedAtRaw is String && assignedAtRaw.toString().isNotEmpty
            ? DateTime.tryParse(assignedAtRaw.toString())
            : null);
    final assignedAtStr = assignedAt != null ? _formatTime(assignedAt) : '—';
    final itemCountRaw = payload['itemCount'];
    final itemCount = (itemCountRaw is num)
        ? itemCountRaw.toInt()
        : int.tryParse(itemCountRaw?.toString() ?? '') ?? 0;
    final pricingModel = (payload['pricingModel'] ?? '').toString().toLowerCase();
    final bool isPickupPerKg = deliveryType == 'pickup' && pricingModel == 'per_kg';
    final String? extraNote = isPickupPerKg ? 'Need to carry weight machine' : null;

    final entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 12,
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

  void _showIncomingRequestPopup(Map<String, dynamic> notification) {
    _removeIncomingPopup();

    // Extract requestId from notification payload
    // Backend sends: { type: 'assignment_request', payload: { requestId: ..., ... } }
    final payload = (notification['payload'] is Map) 
        ? (notification['payload'] as Map).cast<String, dynamic>() 
        : <String, dynamic>{};
    final requestId = (payload['requestId'] ?? '').toString();
    
    if (requestId.isEmpty) {
      debugPrint('Warning: assignment_request notification missing requestId in payload: $notification');
      return;
    }

    // Extract data from notification payload (already extracted above)
    final deliveryType = (payload['deliveryType'] ?? '').toString(); // pickup/drop
    final itemCountRaw = payload['itemCount'];
    final itemCount = (itemCountRaw is num) ? itemCountRaw.toInt() : int.tryParse(itemCountRaw?.toString() ?? '') ?? 0;
    final pickup = payload['pickup'];
    final drop = payload['drop'];
    final address = (deliveryType == 'pickup')
        ? (pickup is Map ? pickup['address'] : null)?.toString()
        : (drop is Map ? drop['address'] : null)?.toString();
    final expiresAtRaw = payload['expiresAt'];
    final expiresAt = expiresAtRaw is DateTime
        ? expiresAtRaw
        : (expiresAtRaw is String && expiresAtRaw.toString().isNotEmpty
            ? DateTime.tryParse(expiresAtRaw.toString())
            : null);

    final customerName = 'New request';
    final taskType = deliveryType == 'pickup' ? 'Pickup' : 'Delivery';
    final scheduledTimeStr = expiresAt != null
        ? _formatTime(expiresAt)
        : null;
    final pricingModel = (payload['pricingModel'] ?? '').toString().toLowerCase();
    final bool isPickupPerKg = deliveryType == 'pickup' && pricingModel == 'per_kg';
    final String? extraNote = isPickupPerKg ? 'Need to carry weight machine' : null;
    // Only show item count for per_unit/per_piece; for per_kg don't show "0 items"
    final bool showItemCount = pricingModel == 'per_unit' || pricingModel == 'per_piece';

    _currentRequestId = requestId;

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
              child: AssignmentRequestPopup(
                taskType: taskType,
                customerName: customerName,
                address: (address ?? '').isNotEmpty ? address! : 'Address not available',
                itemCount: itemCount,
                isProcessing: _isProcessingAssignment,
                onAccept: () => _handleAcceptRequest(requestId),
                onReject: () => _handleRejectRequest(requestId),
                title: 'Notification for delivery boy, to Accept or Reject order',
                scheduledTime: scheduledTimeStr,
                amount: null, // Optional: pass from payload if backend sends it
                extraNote: extraNote,
                showItemCount: showItemCount,
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(entry);
    _incomingOverlay = entry;

    // Auto-dismiss after 2 minutes (matches backend assignment request expiry)
    Future.delayed(const Duration(seconds: 120), () {
      if (mounted && !_isProcessingAssignment) {
        _removeIncomingPopup();
      }
    });
  }

  Future<void> _handleAcceptRequest(String requestId) async {
    if (_isProcessingAssignment) return;

    setState(() {
      _isProcessingAssignment = true;
    });

    try {
      await _deliveryStaffAppService.acceptAssignmentRequest(requestId: requestId);
      
      if (mounted) {
        _removeIncomingPopup();
        _currentRequestId = null;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment accepted successfully!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        // Refresh home data to show the new accepted order
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
      if (mounted) {
        setState(() {
          _isProcessingAssignment = false;
        });
      }
    }
  }

  Future<void> _handleRejectRequest(String requestId) async {
    if (_isProcessingAssignment) return;

    setState(() {
      _isProcessingAssignment = true;
    });

    try {
      await _deliveryStaffAppService.rejectAssignmentRequest(requestId: requestId);
      
      if (mounted) {
        _removeIncomingPopup();
        _currentRequestId = null;
        
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
        // Subscribe to SSE event-stream to receive assignment_request notifications; keep until end shift.
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
          _userFuture = _loadStoredUser();
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
                      final stats = snapshot.data ?? _statsCache;
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
    return FutureBuilder<List<_AcceptedTaskUi>>(
      future: _acceptedFuture,
      builder: (context, snapshot) {
        // If we already have items, keep showing them while refresh is in-flight.
        if (snapshot.connectionState == ConnectionState.waiting && _acceptedCache.isEmpty) {
          return const Center(
            child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (snapshot.hasError && _acceptedCache.isEmpty) {
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

        final allList = _acceptedCache.isNotEmpty ? _acceptedCache : (snapshot.data ?? const <_AcceptedTaskUi>[]);
        // Filter out completed orders (submitted_to_cm and delivered status) from today's list
        final list = allList.where((t) {
          // Keep only orders that are NOT submitted to collection manager AND NOT delivered
          return t.orderStatus != 'submitted_to_cm' && t.orderStatus != 'delivered';
        }).toList();
        
        if (list.isEmpty) {
          return Center(
            child: Text(
              'No accepted orders',
              style: AppTextStyles.subtitle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          key: const PageStorageKey<String>('delivery_partner_home_accepted_tasks'),
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
    );
  }

  Widget _buildCompletedTasks() {
    return FutureBuilder<List<_AcceptedTaskUi>>(
      future: _acceptedFuture,
      builder: (context, snapshot) {
        final allList = _acceptedCache.isNotEmpty ? _acceptedCache : (snapshot.data ?? const <_AcceptedTaskUi>[]);
        // Filter only completed orders (submitted_to_cm and delivered status)
        final completedList = allList.where((t) {
          return t.orderStatus == 'submitted_to_cm' || t.orderStatus == 'delivered';
        }).toList();

        if (completedList.isEmpty) {
          return Center(
            child: Text(
              'No completed tasks',
              style: AppTextStyles.subtitle(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.builder(
          key: const PageStorageKey<String>('delivery_partner_home_completed_tasks'),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: completedList.length,
          itemBuilder: (context, index) {
            final t = completedList[index];
            return TaskCard(
              taskType: t.taskType,
              scheduledTime: t.scheduledTime,
              customerName: t.customerName,
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

