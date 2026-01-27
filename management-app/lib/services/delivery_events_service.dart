import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../services/api_service.dart';
import '../utils/auth_storage.dart';

class DeliverySseEvent {
  final String event;
  final Map<String, dynamic> data;

  const DeliverySseEvent({required this.event, required this.data});
}

class DeliveryEventsService {
  // We can't use ApiService directly for SSE because we need ResponseType.stream + Accept header.
  late final Dio _dio;

  DeliveryEventsService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiService.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 0), // keep-alive stream
        headers: {'Accept': 'text/event-stream'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  /// Connects to `/delivery-staff/events` and emits parsed SSE events.
  Stream<DeliverySseEvent> connect() async* {
    final response = await _dio.get<ResponseBody>(
      '/delivery-staff/events',
      options: Options(responseType: ResponseType.stream),
    );

    final body = response.data;
    if (body == null) return;

    final stream = body.stream.map((b) => b as List<int>).transform(utf8.decoder);

    String? currentEvent;
    final dataBuffer = StringBuffer();
    var carry = '';

    await for (final chunk in stream) {
      // SSE can be chunked mid-line; keep a carry buffer.
      final text = carry + chunk;
      final parts = text.split('\n');
      carry = parts.removeLast(); // last may be partial

      for (var line in parts) {
        line = line.trimRight();
        if (line.isEmpty) {
          if (currentEvent != null) {
            final rawData = dataBuffer.toString().trim();
            dataBuffer.clear();

            Map<String, dynamic> parsed = const <String, dynamic>{};
            if (rawData.isNotEmpty) {
              try {
                final decoded = jsonDecode(rawData);
                if (decoded is Map) parsed = decoded.cast<String, dynamic>();
              } catch (_) {
                parsed = <String, dynamic>{'raw': rawData};
              }
            }

            final evt = currentEvent;
            if (evt != null) {
              yield DeliverySseEvent(event: evt, data: parsed);
            }
          }

          currentEvent = null;
          continue;
        }

        if (line.startsWith(':')) {
          // comment ping
          continue;
        }

        if (line.startsWith('event:')) {
          currentEvent = line.substring('event:'.length).trim();
          continue;
        }

        if (line.startsWith('data:')) {
          final part = line.substring('data:'.length).trim();
          if (dataBuffer.isNotEmpty) dataBuffer.write('\n');
          dataBuffer.write(part);
          continue;
        }
      }
    }
  }
}


