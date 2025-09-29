import 'package:geolocator/geolocator.dart';

class LocationModel {
  final double latitude;
  final double longitude;
  final double? accuracy;

  LocationModel({required this.latitude, required this.longitude, this.accuracy});

  factory LocationModel.fromPosition(Position position) {
    return LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}