/// In-memory orders, queues, and profiles for screen development.
/// Service methods keep their real HTTP paths and call this only when mock mode is on.
class MockStore {
  MockStore._();
  static final MockStore instance = MockStore._();

  static const _pause = Duration(milliseconds: 600);

  MockScenario scenario = MockScenario.normal;

  bool shiftActive = false;
  String? shiftId;

  final Map<String, Map<String, dynamic>> _deliveryUsers = {};
  Map<String, dynamic>? currentDeliveryUser;
  String? lastDeliveryEmail;

  late final List<Map<String, dynamic>> _accepted = _seedAccepted();
  late final List<Map<String, dynamic>> _deliveryHistory = _seedDeliveryHistory();
  late final List<Map<String, dynamic>> _cmIncoming = _seedCmIncoming();
  late final List<Map<String, dynamic>> _cmReceived = _seedCmReceived();
  late final List<Map<String, dynamic>> _cmHistory = _seedCmHistory();
  late final List<Map<String, dynamic>> _dmReady = _seedDmReady();
  late final List<Map<String, dynamic>> _dmVerified = _seedDmVerified();
  late final List<Map<String, dynamic>> _dmHistory = _seedDmHistory();
  late final List<Map<String, dynamic>> _queue = _seedQueue();
  late final List<Map<String, dynamic>> _queueCompleted = _seedQueueCompleted();

  final List<Map<String, dynamic>> partners = _seedPartners();

  Map<String, dynamic>? activeAssignment;

  void setScenarioFromEmail(String email) {
    final value = email.toLowerCase();
    if (value.contains('empty')) {
      scenario = MockScenario.empty;
    } else if (value.contains('error')) {
      scenario = MockScenario.error;
    } else {
      scenario = MockScenario.normal;
    }
  }

  Map<String, dynamic>? deliveryUser(String email) => _deliveryUsers[email.toLowerCase()];

  Map<String, dynamic> registerDeliveryUser({
    required String email,
    required String fullName,
    String? phone,
    String? address,
    String? vehicleType,
    String? vehicleNumber,
  }) {
    final user = _staffUser(
      staffId: 'staff-demo-01',
      fullName: fullName,
      email: email,
      phone: phone ?? '9876543210',
      address: address ?? '12 Lake Road, Kolkata',
      verified: false,
      vehicleType: vehicleType,
      vehicleNumber: vehicleNumber,
    );
    _deliveryUsers[email.toLowerCase()] = user;
    lastDeliveryEmail = email.toLowerCase();
    currentDeliveryUser = user;
    return user;
  }

  Map<String, dynamic> markDeliveryVerified(String email) {
    final user = _deliveryUsers[email.toLowerCase()];
    if (user == null) {
      final created = _staffUser(
        staffId: 'staff-demo-01',
        fullName: 'Demo Partner',
        email: email,
        phone: '9876543210',
        address: '12 Lake Road, Kolkata',
        verified: true,
      );
      _deliveryUsers[email.toLowerCase()] = created;
      currentDeliveryUser = created;
      return created;
    }
    user['is_verified_by_admin'] = true;
    user['isVerifiedByAdmin'] = true;
    user['verification_status'] = 'verified';
    currentDeliveryUser = user;
    return user;
  }

  Map<String, dynamic> staffUserForRole(String role, String email) {
    switch (role) {
      case 'Collection Manager':
        return _staffUser(
          staffId: 'cm-demo-01',
          fullName: 'Rahul Sen',
          email: email,
          phone: '9000000001',
          address: 'Salt Lake, Kolkata',
          verified: true,
        );
      case 'Distribution Manager':
        return _staffUser(
          staffId: 'dm-demo-01',
          fullName: 'Priya Das',
          email: email,
          phone: '9000000002',
          address: 'Park Street, Kolkata',
          verified: true,
        );
      case 'Service Man':
        return _staffUser(
          staffId: 'sm-demo-01',
          fullName: 'Amit Roy',
          email: email,
          phone: '9000000003',
          address: 'Howrah',
          verified: true,
        );
      default:
        return _staffUser(
          staffId: 'staff-demo-01',
          fullName: 'Ananya Sharma',
          email: email,
          phone: '9876543210',
          address: '12 Lake Road, Kolkata',
          verified: true,
          vehicleType: 'bike',
          vehicleNumber: 'WB 06 AB 1234',
        );
    }
  }

  Future<Map<String, dynamic>> homeStats() async {
    await _pauseAndGuard();
    if (scenario == MockScenario.empty) {
      return _ok({'inProgress': 0, 'completed': 0});
    }
    return _ok({
      'inProgress': _accepted.length,
      'completed': _deliveryHistory.length,
    });
  }

  Future<Map<String, dynamic>> deliveryProfile(Map<String, dynamic>? fallback) async {
    await _pauseAndGuard();
    return _ok(
      fallback ?? currentDeliveryUser ?? staffUserForRole('Delivery Partner', 'demo@local.test'),
    );
  }

  Future<Map<String, dynamic>> acceptedOrders() => _list(_accepted);

  Future<Map<String, dynamic>> deliveryHistory() => _list(_deliveryHistory);

  Future<Map<String, dynamic>> shiftStatus() async {
    await _pauseAndGuard();
    if (!shiftActive) return _ok(null);
    return _ok({
      'shiftId': shiftId ?? 'shift-demo',
      'staffId': 'staff-demo-01',
      'startedAt': _isoHoursAgo(1),
      'isActive': true,
    });
  }

  Future<Map<String, dynamic>> startShift() async {
    await _pauseAndGuard();
    shiftActive = true;
    shiftId = 'shift-demo';
    activeAssignment = _assignmentPayload();
    return _ok({
      'shiftId': shiftId,
      'isActive': true,
      'startedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> stopShift() async {
    await _pauseAndGuard();
    shiftActive = false;
    shiftId = null;
    return _ok({'isActive': false});
  }

  Future<Map<String, dynamic>> acceptRequest(String requestId) async {
    await _pauseAndGuard();
    activeAssignment = null;
    _accepted.insert(0, _acceptedTask(
      deliveryId: 'del-accepted-$requestId',
      orderId: 'ord-new-pickup',
      type: 'pickup',
      name: 'Neha Kapoor',
      phone: '9811111111',
      address: '44 Gariahat Road, Kolkata',
      status: 'pickup_assigned',
      items: 4,
    ));
    return _ok({'requestId': requestId, 'accepted': true});
  }

  Future<Map<String, dynamic>> rejectRequest(String requestId) async {
    await _pauseAndGuard();
    activeAssignment = null;
    return _ok({'requestId': requestId, 'rejected': true});
  }

  Future<Map<String, dynamic>> markPickedUp(String deliveryId) async {
    await _pauseAndGuard();
    final task = _findAccepted(deliveryId);
    final order = task?['order'];
    if (order is Map) order['orderStatus'] = 'picked_up';
    return _ok({'deliveryId': deliveryId, 'status': 'picked_up'});
  }

  Future<Map<String, dynamic>> markSubmitted(String deliveryId) async {
    await _pauseAndGuard();
    final task = _takeAccepted(deliveryId);
    if (task != null) _deliveryHistory.insert(0, _historyFromAccepted(task, 'pickup'));
    return _ok({'deliveryId': deliveryId, 'status': 'submitted_to_cm'});
  }

  Future<Map<String, dynamic>> markDelivered(String deliveryId) async {
    await _pauseAndGuard();
    final task = _takeAccepted(deliveryId);
    if (task != null) _deliveryHistory.insert(0, _historyFromAccepted(task, 'delivery'));
    return _ok({'deliveryId': deliveryId, 'status': 'delivered'});
  }

  Future<Map<String, dynamic>> updateLocation() async {
    await _pauseAndGuard();
    return _ok({'updated': true});
  }

  Future<Map<String, dynamic>> perKgItems(String orderId) async {
    await _pauseAndGuard();
    return _ok({
      'orderId': orderId,
      'perKgItems': [
        {'orderItemId': 'item-kg-1', 'itemName': 'Mixed laundry', 'weightKg': null},
        {'orderItemId': 'item-kg-2', 'itemName': 'Bedsheets', 'weightKg': 2.5},
      ],
    });
  }

  Future<Map<String, dynamic>> updateWeights(String orderId) async {
    await _pauseAndGuard();
    for (final list in [_cmIncoming, _cmReceived]) {
      for (final order in list) {
        if (order['orderId'] == orderId) order['perKgWeightsComplete'] = true;
      }
    }
    return _ok({'orderId': orderId, 'updated': true});
  }

  Future<Map<String, dynamic>> orderItems(String orderId) async {
    await _pauseAndGuard();
    return _ok({
      'orderId': orderId,
      'items': [
        {
          'pricingType': 'per_piece',
          'serviceName': 'Wash & Fold',
          'categoryName': 'Regular',
          'selections': [
            {'clothName': 'Shirt', 'quantity': 3},
            {'clothName': 'Trousers', 'quantity': 2},
          ],
        },
        {
          'pricingType': 'per_kg',
          'serviceName': 'Bulk Wash',
          'categoryName': 'Home',
          'quantity': 4,
        },
      ],
    });
  }

  Future<Map<String, dynamic>> cmIncoming() => _list(_cmIncoming);
  Future<Map<String, dynamic>> cmReceived() => _list(_cmReceived);
  Future<Map<String, dynamic>> cmHistory() => _list(_cmHistory);

  Future<Map<String, dynamic>> markReceived(String orderId) async {
    await _pauseAndGuard();
    final order = _take(_cmIncoming, orderId);
    if (order != null) {
      order['orderStatus'] = 'received_by_collection';
      _cmReceived.insert(0, order);
    }
    return _ok({'orderId': orderId});
  }

  Future<Map<String, dynamic>> submitToServices(String orderId) async {
    await _pauseAndGuard();
    final order = _take(_cmReceived, orderId) ?? _take(_cmIncoming, orderId);
    if (order != null) {
      order['orderStatus'] = 'submitted_to_services';
      _cmHistory.insert(0, order);
    }
    return _ok({'orderId': orderId});
  }

  Future<Map<String, dynamic>> generateInvoice(String orderId) async {
    await _pauseAndGuard();
    return _ok({'orderId': orderId, 'invoice': 'INV-1042'});
  }

  Future<Map<String, dynamic>> assignPickup(String orderId, String staffId) async {
    await _pauseAndGuard();
    final staff = partners.firstWhere(
      (p) => p['staffId'] == staffId,
      orElse: () => partners.first,
    );
    for (final order in _cmIncoming) {
      if (order['orderId'] == orderId) {
        order['pickupDelivery'] = {'deliveryStaff': staff};
      }
    }
    return _ok({'orderId': orderId, 'deliveryStaffId': staffId});
  }

  Future<Map<String, dynamic>> dmReady() => _list(_dmReady);
  Future<Map<String, dynamic>> dmVerified() => _list(_dmVerified);
  Future<Map<String, dynamic>> dmHistory() => _list(_dmHistory);

  Future<Map<String, dynamic>> verifyOrder(String orderId) async {
    await _pauseAndGuard();
    final order = _take(_dmReady, orderId);
    if (order != null) {
      order['orderStatus'] = 'verified';
      order['verifiedAt'] = DateTime.now().toUtc().toIso8601String();
      _dmVerified.insert(0, order);
    }
    return _ok({'orderId': orderId});
  }

  Future<Map<String, dynamic>> assignDrop(String orderId, String staffId) async {
    await _pauseAndGuard();
    final staff = partners.firstWhere(
      (p) => p['staffId'] == staffId,
      orElse: () => partners.first,
    );
    for (final order in _dmVerified) {
      if (order['orderId'] == orderId) {
        order['dropDelivery'] = {'deliveryStaff': staff};
      }
    }
    return _ok({'orderId': orderId, 'deliveryStaffId': staffId});
  }

  Future<Map<String, dynamic>> submitToCustomer(String orderId) async {
    await _pauseAndGuard();
    final order = _take(_dmVerified, orderId);
    if (order != null) {
      order['orderStatus'] = 'out_for_delivery';
      order['dispatchedAt'] = DateTime.now().toUtc().toIso8601String();
      order['dispatchedBy'] = {'fullName': 'Priya Das'};
      _dmHistory.insert(0, order);
    }
    return _ok({'orderId': orderId});
  }

  Future<Map<String, dynamic>> queue({required String statusCsv}) async {
    await _pauseAndGuard();
    if (scenario == MockScenario.empty) return _ok(<Map<String, dynamic>>[]);
    final wanted = statusCsv.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
    final rows = _queue.where((row) => wanted.contains((row['status'] ?? '').toString())).toList();
    return _ok(rows);
  }

  Future<Map<String, dynamic>> queueCompleted() => _list(_queueCompleted);

  Future<Map<String, dynamic>> updateQueue(String queueId, String action) async {
    await _pauseAndGuard();
    final index = _queue.indexWhere((row) => row['queueId'] == queueId);
    if (index < 0) return _ok({'queueId': queueId});
    final row = _queue[index];
    if (action == 'completed') {
      _queue.removeAt(index);
      row['status'] = 'completed';
      row['completedOn'] = DateTime.now().toUtc().toIso8601String();
      row['addedOn'] ??= _isoHoursAgo(5);
      _queueCompleted.insert(0, row);
    } else {
      row['status'] = 'in_progress';
      row['startedAt'] = DateTime.now().toUtc().toIso8601String();
    }
    return _ok({'queueId': queueId, 'status': row['status']});
  }

  Future<Map<String, dynamic>> deliveryPartners() async {
    await _pauseAndGuard();
    if (scenario == MockScenario.empty) {
      return _ok({'deliveryStaffs': <Map<String, dynamic>>[]});
    }
    return _ok({'deliveryStaffs': partners});
  }

  Map<String, dynamic> assignmentEvent() {
    final payload = activeAssignment ?? _assignmentPayload();
    return {
      'type': 'assignment_request',
      'title': 'New pickup nearby',
      'body': 'Neha Kapoor · 4 items',
      'payload': payload,
    };
  }

  Future<void> _pauseAndGuard() async {
    await Future<void>.delayed(_pause);
    if (scenario == MockScenario.error) {
      throw Exception('Could not load data. Mock error is on because the login email contains "error".');
    }
  }

  Future<Map<String, dynamic>> _list(List<Map<String, dynamic>> rows) async {
    await _pauseAndGuard();
    if (scenario == MockScenario.empty) return _ok(<Map<String, dynamic>>[]);
    return _ok(rows);
  }

  Map<String, dynamic> _ok(Object? data) => {'success': true, 'data': data};

  Map<String, dynamic>? _take(List<Map<String, dynamic>> rows, String orderId) {
    final index = rows.indexWhere((row) => row['orderId'] == orderId);
    if (index < 0) return null;
    return rows.removeAt(index);
  }

  Map<String, dynamic>? _findAccepted(String deliveryId) {
    for (final task in _accepted) {
      if (task['deliveryId'] == deliveryId) return task;
    }
    return null;
  }

  Map<String, dynamic>? _takeAccepted(String deliveryId) {
    final index = _accepted.indexWhere((task) => task['deliveryId'] == deliveryId);
    if (index < 0) return null;
    return _accepted.removeAt(index);
  }

  static Map<String, dynamic> _staffUser({
    required String staffId,
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required bool verified,
    String? vehicleType,
    String? vehicleNumber,
  }) {
    return {
      'staff_id': staffId,
      'userId': staffId,
      'staffId': staffId,
      'full_name': fullName,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'vehicle_type': vehicleType ?? '',
      'vehicle_number': vehicleNumber ?? '',
      'verification_status': verified ? 'verified' : 'pending',
      'is_verified_by_admin': verified,
      'isVerifiedByAdmin': verified,
      'total_deliveries': 128,
      'average_rating': 4.8,
      'profile_image_url': '',
    };
  }

  static Map<String, dynamic> _customer(String name, String phone) => {
        'fullName': name,
        'phone': phone,
      };

  static Map<String, dynamic> _place(String address, {double lat = 22.5726, double lng = 88.3639}) => {
        'address': address,
        'latitude': lat,
        'longitude': lng,
        'preferredFrom': _isoHoursAgo(-2),
        'preferredTo': _isoHoursAgo(-1),
      };

  static Map<String, dynamic> _order({
    required String orderId,
    required String status,
    required String name,
    required String phone,
    String orderType = 'pickup_and_delivery',
    String pricingModel = 'per_piece',
    bool weightsDone = true,
    Map<String, dynamic>? pickupStaff,
  }) {
    return {
      'orderId': orderId,
      'orderStatus': status,
      'orderType': orderType,
      'pricingModel': pricingModel,
      'perKgWeightsComplete': weightsDone,
      'createdAt': _isoHoursAgo(3),
      'customer': _customer(name, phone),
      if (pickupStaff != null) 'pickupDelivery': {'deliveryStaff': pickupStaff},
    };
  }

  static List<Map<String, dynamic>> _seedAccepted() => [
        _acceptedTask(
          deliveryId: 'del-1001',
          orderId: 'ord-1001-aaaa',
          type: 'pickup',
          name: 'Meera Iyer',
          phone: '9830011122',
          address: '18 Ballygunge Place, Kolkata',
          status: 'pickup_assigned',
          items: 6,
        ),
        _acceptedTask(
          deliveryId: 'del-1002',
          orderId: 'ord-1002-bbbb',
          type: 'drop',
          name: 'Arjun Mehta',
          phone: '9830033344',
          address: '9 Camac Street, Kolkata',
          status: 'out_for_delivery',
          items: 3,
        ),
      ];

  static Map<String, dynamic> _acceptedTask({
    required String deliveryId,
    required String orderId,
    required String type,
    required String name,
    required String phone,
    required String address,
    required String status,
    required int items,
  }) {
    return {
      'deliveryId': deliveryId,
      'orderId': orderId,
      'deliveryType': type,
      'assignedAt': _isoHoursAgo(1),
      'itemCount': items,
      'order': {
        'orderStatus': status,
        'customer': _customer(name, phone),
      },
      'pickup': _place(address, lat: 22.535, lng: 88.365),
      'drop': _place(address, lat: 22.548, lng: 88.352),
    };
  }

  static List<Map<String, dynamic>> _seedDeliveryHistory() => [
        {
          'delivery_id': 'del-0901',
          'order_id': 'ord-0901-cccc',
          'customer_name': 'Sana Qureshi',
          'customer_phone': '9812345678',
          'delivery_type': 'delivery',
          'number_of_order_items': 5,
          'date_of_delivery': _isoHoursAgo(20),
          'assigned_at': _isoHoursAgo(26),
          'delivery_request_status': 'accepted',
          'pickup': _place('2 Alipore Road, Kolkata'),
          'drop': _place('2 Alipore Road, Kolkata'),
        },
        {
          'delivery_id': 'del-0902',
          'order_id': 'ord-0902-dddd',
          'customer_name': 'Vikram Nair',
          'customer_phone': '9800112233',
          'delivery_type': 'pickup',
          'number_of_order_items': 2,
          'date_of_delivery': _isoHoursAgo(30),
          'assigned_at': _isoHoursAgo(32),
          'delivery_request_status': 'rejected',
          'pickup': _place('77 Rashbehari Avenue, Kolkata'),
          'drop': _place('77 Rashbehari Avenue, Kolkata'),
        },
      ];

  static Map<String, dynamic> _historyFromAccepted(Map<String, dynamic> task, String type) {
    final order = task['order'];
    final customer = order is Map ? order['customer'] : null;
    return {
      'delivery_id': task['deliveryId'],
      'order_id': task['orderId'],
      'customer_name': customer is Map ? customer['fullName'] : 'Customer',
      'customer_phone': customer is Map ? customer['phone'] : '',
      'delivery_type': type == 'drop' ? 'delivery' : type,
      'number_of_order_items': task['itemCount'] ?? 1,
      'date_of_delivery': DateTime.now().toUtc().toIso8601String(),
      'assigned_at': task['assignedAt'],
      'delivery_request_status': 'accepted',
      'pickup': task['pickup'],
      'drop': task['drop'],
    };
  }

  static List<Map<String, dynamic>> _seedCmIncoming() => [
        _order(
          orderId: 'ord-cm-placed',
          status: 'placed',
          name: 'Kavya Menon',
          phone: '9900001111',
        ),
        _order(
          orderId: 'ord-cm-kg',
          status: 'placed',
          name: 'Farhan Ali',
          phone: '9900002222',
          pricingModel: 'per_kg',
          weightsDone: false,
        ),
        _order(
          orderId: 'ord-cm-submitted',
          status: 'submitted_to_cm',
          name: 'Ishita Bose',
          phone: '9900003333',
          pickupStaff: {'fullName': 'Ravi Kumar', 'staffId': 'staff-ravi'},
        ),
      ];

  static List<Map<String, dynamic>> _seedCmReceived() => [
        _order(
          orderId: 'ord-cm-received',
          status: 'received_by_collection',
          name: 'Nikhil Jain',
          phone: '9900004444',
          pickupStaff: {'fullName': 'Ravi Kumar', 'staffId': 'staff-ravi'},
        ),
      ];

  static List<Map<String, dynamic>> _seedCmHistory() => [
        _order(
          orderId: 'ord-cm-history',
          status: 'submitted_to_services',
          name: 'Pooja Reddy',
          phone: '9900005555',
          pickupStaff: {'fullName': 'Suresh Pal', 'staffId': 'staff-suresh'},
        ),
      ];

  static List<Map<String, dynamic>> _seedDmReady() => [
        _order(
          orderId: 'ord-dm-ready',
          status: 'services_completed',
          name: 'Aditi Shah',
          phone: '9700001111',
        ),
        _order(
          orderId: 'ord-dm-progress',
          status: 'services_in_progress',
          name: 'Rohit Banerjee',
          phone: '9700002222',
        ),
      ];

  static List<Map<String, dynamic>> _seedDmVerified() => [
        _order(
          orderId: 'ord-dm-assign',
          status: 'verified',
          name: 'Leena Thomas',
          phone: '9700003333',
        ),
        {
          ..._order(
            orderId: 'ord-dm-assigned',
            status: 'verified',
            name: 'Kabir Singh',
            phone: '9700004444',
            orderType: 'pickup_and_delivery',
          ),
          'verifiedAt': _isoHoursAgo(2),
          'dropDelivery': {
            'deliveryStaff': {'fullName': 'Ravi Kumar', 'staffId': 'staff-ravi'},
          },
        },
      ];

  static List<Map<String, dynamic>> _seedDmHistory() => [
        {
          ..._order(
            orderId: 'ord-dm-history',
            status: 'out_for_delivery',
            name: 'Tara Krishnan',
            phone: '9700005555',
          ),
          'dispatchedAt': _isoHoursAgo(8),
          'dispatchedBy': {'fullName': 'Priya Das'},
          'dropDelivery': {
            'deliveryStaff': {'fullName': 'Suresh Pal', 'staffId': 'staff-suresh'},
          },
        },
      ];

  static List<Map<String, dynamic>> _seedQueue() => [
        _queueRow(
          queueId: 'q-1',
          orderId: 'ord-sm-100',
          name: 'Dev Patel',
          item: 'Wash & Fold',
          status: 'pending',
          qty: 4,
        ),
        _queueRow(
          queueId: 'q-2',
          orderId: 'ord-sm-100',
          name: 'Dev Patel',
          item: 'Iron',
          status: 'pending',
          qty: 2,
        ),
        _queueRow(
          queueId: 'q-3',
          orderId: 'ord-sm-200',
          name: 'Aisha Khan',
          item: 'Dry Clean',
          status: 'in_progress',
          qty: 1,
        ),
      ];

  static List<Map<String, dynamic>> _seedQueueCompleted() => [
        _queueRow(
          queueId: 'q-9',
          orderId: 'ord-sm-900',
          name: 'Manish Gupta',
          item: 'Wash & Fold',
          status: 'completed',
          qty: 5,
          completed: true,
        ),
      ];

  static Map<String, dynamic> _queueRow({
    required String queueId,
    required String orderId,
    required String name,
    required String item,
    required String status,
    required int qty,
    bool completed = false,
  }) {
    return {
      'queueId': queueId,
      'orderId': orderId,
      'status': status,
      'itemName': item,
      'quantity': qty,
      'assignedAt': _isoHoursAgo(4),
      'startedAt': status == 'pending' ? null : _isoHoursAgo(2),
      'addedOn': _isoHoursAgo(6),
      'completedOn': completed ? _isoHoursAgo(1) : null,
      'clothItemsCount': qty,
      'order': {'customer': _customer(name, '9600000000')},
      'clothItems': [
        {'clothName': 'Shirt', 'quantity': qty},
      ],
    };
  }

  static List<Map<String, dynamic>> _seedPartners() => [
        {
          'staffId': 'staff-ravi',
          'fullName': 'Ravi Kumar',
          'totalDeliveries': 86,
          'averageRating': 4.7,
          'currentCoordinates': {'latitude': 22.54, 'longitude': 88.36},
          'documents': {'profileImageUrl': ''},
        },
        {
          'staffId': 'staff-suresh',
          'fullName': 'Suresh Pal',
          'totalDeliveries': 54,
          'averageRating': 4.5,
          'currentCoordinates': {'latitude': 22.58, 'longitude': 88.40},
          'documents': {'profileImageUrl': ''},
        },
      ];

  static Map<String, dynamic> _assignmentPayload() => {
        'requestId': 'req-demo-1',
        'orderId': 'ord-new-pickup',
        'deliveryId': 'del-new-1',
        'deliveryType': 'pickup',
        'itemCount': 4,
        'pricingModel': 'per_piece',
        'expiresAt': DateTime.now().toUtc().add(const Duration(minutes: 3)).toIso8601String(),
        'assignedAt': DateTime.now().toUtc().toIso8601String(),
        'pickup': _place('44 Gariahat Road, Kolkata'),
        'drop': _place('44 Gariahat Road, Kolkata'),
      };

  static String _isoHoursAgo(int hours) =>
      DateTime.now().toUtc().subtract(Duration(hours: hours)).toIso8601String();
}

enum MockScenario { normal, empty, error }
