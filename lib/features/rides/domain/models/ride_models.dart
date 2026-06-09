class Location {
  final double latitude;
  final double longitude;

  Location({required this.latitude, required this.longitude});

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude'] ?? json['lat'] ?? 0.0,
      longitude: json['longitude'] ?? json['lng'] ?? 0.0,
    );
  }
}

class RideMission {
  final String id;
  final String clientId;
  final String? driverId;
  final String status;
  final Location pickup;
  final Location dropoff;
  final double price;

  RideMission({
    required this.id,
    required this.clientId,
    this.driverId,
    required this.status,
    required this.pickup,
    required this.dropoff,
    required this.price,
  });

  factory RideMission.fromJson(Map<String, dynamic> json) {
    return RideMission(
      id: json['id'],
      clientId: json['client_id'],
      driverId: json['driver_id'],
      status: json['status'],
      pickup: Location.fromJson(json['pickup']),
      dropoff: Location.fromJson(json['dropoff']),
      price: (json['price'] as num).toDouble(),
    );
  }
}
