import 'package:latlong2/latlong.dart';

enum WashStatus { free, busy, full }

// How queue length is determined — cameraAI and crowdSourced
// work without the business signing up.
enum DetectionMethod { cameraAI, crowdSourced, selfReported }

class CarWash {
  final String id;
  final String name;
  final String nameAr;
  final double lat;
  final double lng;
  final WashStatus status;
  final int carsInQueue;
  final int waitTimeMinutes;
  final String address;
  final String addressAr;
  final double rating;
  final List<String> services;
  final DetectionMethod detectionMethod;

  const CarWash({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.lat,
    required this.lng,
    required this.status,
    required this.carsInQueue,
    required this.waitTimeMinutes,
    required this.address,
    required this.addressAr,
    required this.rating,
    required this.services,
    required this.detectionMethod,
  });

  LatLng get latLng => LatLng(lat, lng);
}
