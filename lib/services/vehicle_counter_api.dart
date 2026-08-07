import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ZonePoint {
  final double x;
  final double y;

  const ZonePoint(this.x, this.y);

  factory ZonePoint.fromJson(List<dynamic> json) {
    return ZonePoint(
      (json[0] as num).toDouble().clamp(0.0, 1.0).toDouble(),
      (json[1] as num).toDouble().clamp(0.0, 1.0).toDouble(),
    );
  }

  List<double> toJson() => [x, y];
}

class VehicleCounterZone {
  final String id;
  final String label;
  final List<ZonePoint> points;

  const VehicleCounterZone({
    required this.id,
    required this.label,
    required this.points,
  });

  factory VehicleCounterZone.fromJson(Map<String, dynamic> json) {
    return VehicleCounterZone(
      id: json['id'] as String,
      label: json['label'] as String? ?? json['id'] as String,
      points: (json['points'] as List<dynamic>)
          .map((point) => ZonePoint.fromJson(point as List<dynamic>))
          .toList(growable: false),
    );
  }

  VehicleCounterZone copyWith({String? label, List<ZonePoint>? points}) {
    return VehicleCounterZone(
      id: id,
      label: label ?? this.label,
      points: points ?? this.points,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'points': points.map((point) => point.toJson()).toList(),
      };
}

class VehicleCounterZoneConfig {
  final String stationId;
  final String cameraId;
  final List<VehicleCounterZone> zones;

  const VehicleCounterZoneConfig({
    required this.stationId,
    required this.cameraId,
    required this.zones,
  });

  factory VehicleCounterZoneConfig.fromJson(Map<String, dynamic> json) {
    return VehicleCounterZoneConfig(
      stationId: json['stationId'] as String,
      cameraId: json['cameraId'] as String,
      zones: (json['zones'] as List<dynamic>)
          .map((zone) =>
              VehicleCounterZone.fromJson(zone as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  VehicleCounterZoneConfig copyWith({List<VehicleCounterZone>? zones}) {
    return VehicleCounterZoneConfig(
      stationId: stationId,
      cameraId: cameraId,
      zones: zones ?? this.zones,
    );
  }

  Map<String, dynamic> toJson() => {
        'stationId': stationId,
        'cameraId': cameraId,
        'zones': zones.map((zone) => zone.toJson()).toList(),
      };
}

class VehicleCounterZoneCount {
  final String id;
  final String label;
  final int count;

  const VehicleCounterZoneCount({
    required this.id,
    required this.label,
    required this.count,
  });

  factory VehicleCounterZoneCount.fromJson(Map<String, dynamic> json) {
    return VehicleCounterZoneCount(
      id: json['id'] as String,
      label: json['label'] as String? ?? json['id'] as String,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class VehicleCounterCounts {
  final bool ready;
  final String? error;
  final int queueCount;
  final int inWashCount;
  final int detections;
  final int frameWidth;
  final int frameHeight;
  final double fpsMeasured;
  final List<VehicleCounterZoneCount> zones;
  final DateTime? updatedAt;

  const VehicleCounterCounts({
    required this.ready,
    required this.error,
    required this.queueCount,
    required this.inWashCount,
    required this.detections,
    required this.frameWidth,
    required this.frameHeight,
    required this.fpsMeasured,
    required this.zones,
    required this.updatedAt,
  });

  factory VehicleCounterCounts.fromJson(Map<String, dynamic> json) {
    return VehicleCounterCounts(
      ready: json['ready'] as bool? ?? false,
      error: json['error'] as String?,
      queueCount: (json['queueCount'] as num?)?.toInt() ?? 0,
      inWashCount: (json['inWashCount'] as num?)?.toInt() ?? 0,
      detections: (json['detections'] as num?)?.toInt() ?? 0,
      frameWidth: (json['frameWidth'] as num?)?.toInt() ?? 0,
      frameHeight: (json['frameHeight'] as num?)?.toInt() ?? 0,
      fpsMeasured: (json['fpsMeasured'] as num?)?.toDouble() ?? 0,
      zones: (json['zones'] as List<dynamic>? ?? const [])
          .map((zone) =>
              VehicleCounterZoneCount.fromJson(zone as Map<String, dynamic>))
          .toList(growable: false),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}

class VehicleCounterApi {
  final String baseUrl;
  final http.Client _client;

  VehicleCounterApi(String baseUrl, {http.Client? client})
      : baseUrl = _normalizeBaseUrl(baseUrl),
        _client = client ?? http.Client();

  static String get defaultBaseUrl {
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8090'
        : 'http://localhost:8090';
  }

  Uri snapshotUri({required int frame, bool raw = false}) {
    final endpoint = raw ? '/raw-snapshot.jpg' : '/snapshot.jpg';
    return Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: {'frame': '$frame'},
    );
  }

  Future<VehicleCounterCounts> getCounts() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/counts'))
        .timeout(const Duration(seconds: 3));
    _ensureSuccess(response);
    return VehicleCounterCounts.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<VehicleCounterZoneConfig> getZones() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/zones'))
        .timeout(const Duration(seconds: 4));
    _ensureSuccess(response);
    return VehicleCounterZoneConfig.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<VehicleCounterZoneConfig> updateZones(
    VehicleCounterZoneConfig config,
  ) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl/zones'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(config.toJson()),
        )
        .timeout(const Duration(seconds: 5));
    _ensureSuccess(response);
    return VehicleCounterZoneConfig.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void close() => _client.close();

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    var detail = 'Vehicle counter returned HTTP ${response.statusCode}.';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      detail = body['detail'] as String? ?? detail;
    } catch (_) {
      // Keep the status-based message for non-JSON responses.
    }
    throw VehicleCounterApiException(detail);
  }
}

class VehicleCounterApiException implements Exception {
  final String message;

  const VehicleCounterApiException(this.message);

  @override
  String toString() => message;
}
