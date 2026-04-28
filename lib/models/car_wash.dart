import 'package:latlong2/latlong.dart';

enum WashStatus { free, busy, full }

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
  final String openingHours;
  final String phone;
  final double priceBasic;
  final double priceStandard;
  final double pricePremium;

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
    required this.openingHours,
    required this.phone,
    required this.priceBasic,
    required this.priceStandard,
    required this.pricePremium,
  });

  LatLng get latLng => LatLng(lat, lng);
}
