import 'api_service.dart';

class DeliverySlot {
  final String id;
  final String label;
  final String period;
  final String status;

  const DeliverySlot({
    required this.id,
    required this.label,
    required this.period,
    required this.status,
  });
}

class SlotList {
  final int horizonDays;
  final List<DeliverySlot> slots;

  const SlotList({required this.horizonDays, required this.slots});
}

class SlotsService {
  final ApiService _api;

  SlotsService({ApiService? api}) : _api = api ?? ApiService();

  Future<SlotList> list() async {
    final res = await _api.get('/slots');
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final rows = (data['slots'] as List?) ?? const [];
    return SlotList(
      horizonDays: (data['booking_horizon_days'] as num?)?.toInt() ?? 7,
      slots: [
        for (final row in rows)
          if (row is Map<String, dynamic>)
            DeliverySlot(
              id: (row['slot_id'] ?? '') as String,
              label: _label(row),
              period: (row['period'] ?? 'morning') as String,
              status: (row['status'] ?? 'open') as String,
            ),
      ],
    );
  }

  String _label(Map<String, dynamic> row) {
    final start = row['start_time'] as String?;
    final end = row['end_time'] as String?;
    if (start != null && end != null && start.isNotEmpty && end.isNotEmpty) {
      return '$start-$end';
    }
    return (row['label'] ?? '') as String;
  }
}
