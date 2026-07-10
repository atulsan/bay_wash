import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../utils/distance.dart';

enum RouteEtaSource { openRouteService, fallback, unavailable }

class RouteEta {
  final int driveMinutes;
  final int totalMinutes;
  final double routeDistanceKm;
  final double? averageSpeedKph;
  final List<LatLng> routeGeometry;
  final RouteEtaSource source;
  final DateTime updatedAt;

  const RouteEta({
    required this.driveMinutes,
    required this.totalMinutes,
    required this.routeDistanceKm,
    required this.averageSpeedKph,
    required this.routeGeometry,
    required this.source,
    required this.updatedAt,
  });

  bool get isOpenRouteService => source == RouteEtaSource.openRouteService;
}

class RouteEtaService {
  static const _primaryApiKey = String.fromEnvironment(
    'OPENROUTESERVICE_API_KEY',
  );
  static const _alternateApiKey = String.fromEnvironment('ORS_API_KEY');
  static const _maxResponseBytes = 256 * 1024;

  final http.Client _client;

  RouteEtaService({http.Client? client}) : _client = client ?? http.Client();

  bool get hasApiKey => apiKey.isNotEmpty;

  String get apiKey {
    final key = _primaryApiKey.isNotEmpty ? _primaryApiKey : _alternateApiKey;
    return key.trim();
  }

  Future<RouteEta> estimate({
    required LatLng origin,
    required LatLng destination,
    required int queueWaitMinutes,
  }) async {
    if (!hasApiKey) {
      return _fallbackEta(
        origin: origin,
        destination: destination,
        queueWaitMinutes: queueWaitMinutes,
        source: RouteEtaSource.fallback,
      );
    }

    try {
      final route = await _fetchRoute(origin, destination);
      if (route == null || route.durationSeconds <= 0) {
        return _fallbackEta(
          origin: origin,
          destination: destination,
          queueWaitMinutes: queueWaitMinutes,
          source: RouteEtaSource.unavailable,
        );
      }

      final driveMinutes = max(1, (route.durationSeconds / 60).round());
      final routeKm = max(0.1, route.distanceMeters / 1000);
      final speed = routeKm / max(route.durationSeconds / 3600, 0.01);

      return RouteEta(
        driveMinutes: driveMinutes,
        totalMinutes: driveMinutes + queueWaitMinutes,
        routeDistanceKm: routeKm,
        averageSpeedKph: speed,
        routeGeometry: route.geometry,
        source: RouteEtaSource.openRouteService,
        updatedAt: DateTime.now(),
      );
    } catch (_) {
      return _fallbackEta(
        origin: origin,
        destination: destination,
        queueWaitMinutes: queueWaitMinutes,
        source: RouteEtaSource.unavailable,
      );
    }
  }

  Future<_OpenRoute?> _fetchRoute(LatLng origin, LatLng destination) async {
    final uri = Uri.https(
      'api.openrouteservice.org',
      '/v2/directions/driving-car/geojson',
    );

    final response = await _client
        .post(
          uri,
          headers: {
            'Authorization': apiKey,
            'Accept': 'application/json, application/geo+json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'coordinates': [
              [origin.longitude, origin.latitude],
              [destination.longitude, destination.latitude],
            ],
            'instructions': false,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    if (response.bodyBytes.length > _maxResponseBytes) {
      return null;
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) return null;
    final features = decoded['features'];
    if (features is! List || features.isEmpty) return null;
    final first = features.first;
    if (first is! Map<String, dynamic>) return null;

    final properties = first['properties'];
    final geometry = first['geometry'];
    if (properties is! Map<String, dynamic> ||
        geometry is! Map<String, dynamic>) {
      return null;
    }

    final summary = properties['summary'];
    if (summary is! Map<String, dynamic>) return null;

    final distanceMeters = _readNumber(summary['distance']);
    final durationSeconds = _readNumber(summary['duration']);
    if (distanceMeters == null || durationSeconds == null) return null;

    final coordinates = geometry['coordinates'];
    final points = _decodeLineString(coordinates);

    return _OpenRoute(
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      geometry: points.isEmpty ? [origin, destination] : points,
    );
  }

  RouteEta _fallbackEta({
    required LatLng origin,
    required LatLng destination,
    required int queueWaitMinutes,
    required RouteEtaSource source,
  }) {
    final routeKm = _estimatedRoadDistanceKm(origin, destination);
    const fallbackCitySpeedKph = 48.0;
    final driveMinutes = max(1, (routeKm / fallbackCitySpeedKph * 60).round());

    return RouteEta(
      driveMinutes: driveMinutes,
      totalMinutes: driveMinutes + queueWaitMinutes,
      routeDistanceKm: routeKm,
      averageSpeedKph: fallbackCitySpeedKph,
      routeGeometry: [origin, _routeMidpoint(origin, destination), destination],
      source: source,
      updatedAt: DateTime.now(),
    );
  }

  List<LatLng> _decodeLineString(Object? coordinates) {
    if (coordinates is! List) return const [];
    final points = <LatLng>[];
    for (final pair in coordinates) {
      if (pair is! List || pair.length < 2) continue;
      final lng = _readNumber(pair[0]);
      final lat = _readNumber(pair[1]);
      if (lat == null || lng == null) continue;
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  double _estimatedRoadDistanceKm(LatLng origin, LatLng destination) {
    final straightKm = haversineKm(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );
    return max(0.8, straightKm * 1.32);
  }

  LatLng _routeMidpoint(LatLng from, LatLng to) {
    return LatLng(
      (from.latitude + to.latitude) / 2 + 0.015,
      (from.longitude + to.longitude) / 2,
    );
  }

  double? _readNumber(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class _OpenRoute {
  final double distanceMeters;
  final double durationSeconds;
  final List<LatLng> geometry;

  const _OpenRoute({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.geometry,
  });
}
