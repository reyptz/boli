import '../../../../core/network/api_client.dart';
import '../domain/models/ride_models.dart';

class RideRepository {
  final ApiClient apiClient;

  RideRepository(this.apiClient);

  Future<RideMission> requestRide(String clientId, Location pickup, Location dropoff) async {
    final response = await apiClient.dio.post('/rides/request', data: {
      'client_id': clientId,
      'pickup': pickup.toJson(),
      'dropoff': dropoff.toJson(),
    });
    return RideMission.fromJson(response.data['mission']);
  }

  Future<RideMission> acceptRide(String rideId, String driverId) async {
    final response = await apiClient.dio.post('/rides/$rideId/accept', data: {
      'driver_id': driverId,
    });
    return RideMission.fromJson(response.data['mission']);
  }

  Future<RideMission> updateRideStatus(String rideId, String status, {String? driverId}) async {
    final response = await apiClient.dio.post('/rides/$rideId/status', data: {
      'status': status,
      'driver_id': driverId,
    });
    return RideMission.fromJson(response.data['mission']);
  }

  Future<void> syncMission(Map<String, dynamic> data) async {
    await apiClient.dio.post('/rides/sync', data: data);
  }

  Future<List<dynamic>> getRideHistory() async {
    final response = await apiClient.dio.get('/rides/history');
    return response.data as List<dynamic>;
  }
}

