import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingLocation {
  final String id;
  final String name;
  final String address;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final int availableSpots;
  final double pricePerHour;
  final String description;
  final double distanceKm;
  final String operatingHours;
  final String parkingType;

  ParkingLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.availableSpots,
    required this.pricePerHour,
    this.description = '',
    this.distanceKm = 2.5,
    this.operatingHours = '9AM - 12AM',
    this.parkingType = 'Underground Parking',
  });

  factory ParkingLocation.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ParkingLocation(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      availableSpots: data['availableSpots'] ?? 0,
      pricePerHour: (data['pricePerHour'] ?? 0.0).toDouble(),
      description: data['description'] ?? 'No description available for this location.',
      distanceKm: (data['distanceKm'] ?? 2.5).toDouble(),
      operatingHours: data['operatingHours'] ?? '9AM - 12AM',
      parkingType: data['parkingType'] ?? 'Underground Parking',
    );
  }
}
