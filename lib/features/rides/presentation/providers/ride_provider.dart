import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../../../core/network/websocket_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/ride_repository.dart';
import '../../domain/models/ride_models.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

// --- Core Providers ---
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.disconnect());
  return service;
});

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  return RideRepository(ref.read(apiClientProvider));
});


// --- State Classes ---
abstract class RideState {}

class RideIdle extends RideState {}

class RideRequesting extends RideState {}

class RidePending extends RideState {
  final RideMission mission;
  RidePending(this.mission);
}

class RideActive extends RideState {
  final String rideId;
  final String? driverId;
  final String status; // 'accepted', 'going_to_pickup', 'arrived', 'processing', 'completed', 'cancelled'
  final double? driverLat;
  final double? driverLng;
  RideActive({
    required this.rideId,
    this.driverId,
    required this.status,
    this.driverLat,
    this.driverLng,
  });
}

class RideIncomingForDriver extends RideState {
  final String rideId;
  final Location pickup;
  final Location dropoff;
  final double price;

  RideIncomingForDriver({
    required this.rideId,
    required this.pickup,
    required this.dropoff,
    required this.price,
  });
}

class RideError extends RideState {
  final String message;
  RideError(this.message);
}


// --- Notifier ---
class RideNotifier extends StateNotifier<RideState> {
  final RideRepository _repository;
  final WebSocketService _wsService;
  final String userId;
  final Ref ref;

  StreamSubscription? _activeRideSubscription;
  StreamSubscription? _driverPendingRidesSubscription;

  RideNotifier(this._repository, this._wsService, this.userId, this.ref) : super(RideIdle()) {
    _initWebSocket();
    // Écouter automatiquement si l'utilisateur change ou s'il y a des courses en cours
    if (userId.isNotEmpty) {
      _listenToUserActiveRide();
    }
  }

  @override
  void dispose() {
    _activeRideSubscription?.cancel();
    _driverPendingRidesSubscription?.cancel();
    super.dispose();
  }

  void _initWebSocket() {
    if (userId.isNotEmpty) {
      _wsService.connect(userId);
      _wsService.events.listen((event) {
        _handleWebSocketEvent(event);
      });
    }
  }

  void _handleWebSocketEvent(Map<String, dynamic> event) {
    final type = event['type'];
    if (type == 'NEW_RIDE_AVAILABLE') {
      state = RideIncomingForDriver(
        rideId: event['ride_id'],
        pickup: Location.fromJson(event['pickup']),
        dropoff: Location.fromJson(event['dropoff']),
        price: (event['price'] as num).toDouble(),
      );
    } else if (type == 'DRIVER_ASSIGNED') {
      state = RideActive(
        rideId: event['ride_id'],
        driverId: event['driver_id'],
        status: event['status'],
      );
    } else if (type == 'RIDE_STATUS_UPDATED') {
      final rideId = event['ride_id'];
      final status = event['status'];
      final driverId = event['driver_id'];

      if (status == 'completed' || status == 'cancelled') {
        state = RideIdle();
      } else {
        double? lat;
        double? lng;
        if (state is RideActive) {
          lat = (state as RideActive).driverLat;
          lng = (state as RideActive).driverLng;
        }
        state = RideActive(
          rideId: rideId,
          driverId: driverId,
          status: status,
          driverLat: lat,
          driverLng: lng,
        );
      }
    } else if (type == 'DRIVER_LOCATION_UPDATED') {
      if (state is RideActive) {
        final activeState = state as RideActive;
        state = RideActive(
          rideId: activeState.rideId,
          driverId: activeState.driverId,
          status: activeState.status,
          driverLat: (event['latitude'] as num).toDouble(),
          driverLng: (event['longitude'] as num).toDouble(),
        );
      }
    } else if (type == 'PAYMENT_FAILED') {
      state = RideError('Le paiement a échoué. Veuillez réessayer.');
    }
  }

  // --- Firestore VTC Flow ---

  void _listenToUserActiveRide() {
    _activeRideSubscription?.cancel();
    // Chercher une course active (pas complétée ni annulée) pour ce client
    _activeRideSubscription = FirebaseFirestore.instance
        .collection('rides')
        .where('clientId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      final activeDocs = snapshot.docs.where((doc) {
        final status = doc.data()['status'] ?? '';
        return status != 'completed' && status != 'cancelled';
      }).toList();

      if (activeDocs.isNotEmpty) {
        final doc = activeDocs.first;
        final data = doc.data();
        final status = data['status'] ?? 'pending';
        final driverId = data['driverId'];

        if (status == 'pending') {
          state = RidePending(RideMission(
            id: doc.id,
            clientId: userId,
            pickup: Location.fromJson(data['pickup']),
            dropoff: Location.fromJson(data['dropoff']),
            status: 'pending',
            price: (data['price'] as num?)?.toDouble() ?? 2500.0,
          ));
        } else {
          state = RideActive(
            rideId: doc.id,
            driverId: driverId,
            status: status,
            driverLat: (data['driverLat'] as num?)?.toDouble(),
            driverLng: (data['driverLng'] as num?)?.toDouble(),
          );
        }
      } else {
        if (state is! RideIncomingForDriver && state is! RideRequesting) {
          state = RideIdle();
        }
      }
    });
  }

  void startListeningForDriverRides() {
    _driverPendingRidesSubscription?.cancel();
    _driverPendingRidesSubscription = FirebaseFirestore.instance
        .collection('rides')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty && state is RideIdle) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        state = RideIncomingForDriver(
          rideId: doc.id,
          pickup: Location.fromJson(data['pickup']),
          dropoff: Location.fromJson(data['dropoff']),
          price: (data['price'] as num?)?.toDouble() ?? 2500.0,
        );
      } else if (snapshot.docs.isEmpty && state is RideIncomingForDriver) {
        state = RideIdle();
      }
    });
  }

  void stopListeningForDriverRides() {
    _driverPendingRidesSubscription?.cancel();
  }

  void sendLocationUpdate(double lat, double lng) {
    _wsService.sendGpsUpdate(lat, lng);
  }

  Future<void> requestRide(Location pickup, Location dropoff) async {
    state = RideRequesting();
    try {
      final docRef = await FirebaseFirestore.instance.collection('rides').add({
        'clientId': userId,
        'driverId': null,
        'pickup': pickup.toJson(),
        'dropoff': dropoff.toJson(),
        'status': 'pending',
        'price': 2500.0,
        'createdAt': FieldValue.serverTimestamp(),
        'driverLat': null,
        'driverLng': null,
      });

      final rideId = docRef.id;
      final mission = RideMission(
        id: rideId,
        clientId: userId,
        pickup: pickup,
        dropoff: dropoff,
        status: 'pending',
        price: 2500.0,
      );

      state = RidePending(mission);
      _listenToActiveRide(rideId);

      // Synchronisation PostgreSQL
      await _repository.syncMission({
        'ride_id': rideId,
        'client_id': userId,
        'driver_id': null,
        'merchant_id': null,
        'type': 'vtc',
        'status': 'pending',
        'price': 2500.0,
        'pickup_lat': pickup.latitude,
        'pickup_lng': pickup.longitude,
        'dropoff_lat': dropoff.latitude,
        'dropoff_lng': dropoff.longitude,
      });
    } catch (e) {
      state = RideError('Erreur lors de la demande de course.');
    }
  }

  void _listenToActiveRide(String rideId) {
    _activeRideSubscription?.cancel();
    _activeRideSubscription = FirebaseFirestore.instance
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final status = data['status'] ?? 'pending';
      final driverId = data['driverId'];

      if (status == 'completed' || status == 'cancelled') {
        state = RideIdle();
        _activeRideSubscription?.cancel();
      } else if (driverId != null) {
        state = RideActive(
          rideId: rideId,
          driverId: driverId,
          status: status,
          driverLat: (data['driverLat'] as num?)?.toDouble(),
          driverLng: (data['driverLng'] as num?)?.toDouble(),
        );
      }
    });
  }

  Future<void> acceptRide(String rideId) async {
    try {
      await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
        'driverId': userId,
        'status': 'going_to_pickup',
      });
      _listenToActiveRide(rideId);

      final doc = await FirebaseFirestore.instance.collection('rides').doc(rideId).get();
      final data = doc.data();
      if (data != null) {
        await _repository.syncMission({
          'ride_id': rideId,
          'client_id': data['clientId'] ?? '',
          'driver_id': userId,
          'merchant_id': null,
          'type': 'vtc',
          'status': 'going_to_pickup',
          'price': 2500.0,
          'pickup_lat': (data['pickup'] as Map?)?['latitude'] ?? 0.0,
          'pickup_lng': (data['pickup'] as Map?)?['longitude'] ?? 0.0,
          'dropoff_lat': (data['dropoff'] as Map?)?['latitude'] ?? 0.0,
          'dropoff_lng': (data['dropoff'] as Map?)?['longitude'] ?? 0.0,
        });
      }
    } catch (e) {
      state = RideError('Erreur lors de l\'acceptation de la course.');
    }
  }

  Future<void> updateStatus(String rideId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
        'status': status,
      });
      if (status == 'completed' || status == 'cancelled') {
        state = RideIdle();
      }

      final doc = await FirebaseFirestore.instance.collection('rides').doc(rideId).get();
      final data = doc.data();
      if (data != null) {
        await _repository.syncMission({
          'ride_id': rideId,
          'client_id': data['clientId'] ?? '',
          'driver_id': data['driverId'],
          'merchant_id': null,
          'type': 'vtc',
          'status': status,
          'price': 2500.0,
          'pickup_lat': (data['pickup'] as Map?)?['latitude'] ?? 0.0,
          'pickup_lng': (data['pickup'] as Map?)?['longitude'] ?? 0.0,
          'dropoff_lat': (data['dropoff'] as Map?)?['latitude'] ?? 0.0,
          'dropoff_lng': (data['dropoff'] as Map?)?['longitude'] ?? 0.0,
        });
      }

      if (status == 'completed' || status == 'cancelled') {
        ref.read(walletProvider.notifier).fetchBalance();
        ref.read(walletProvider.notifier).fetchTransactions();
      }
    } catch (e) {
      state = RideError('Erreur lors de la mise à jour du statut.');
    }
  }

  Future<void> updateDriverLocation(String rideId, double lat, double lng) async {
    try {
      await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
        'driverLat': lat,
        'driverLng': lng,
      });
    } catch (e) {
      print('Error updating VTC driver location: $e');
    }
  }

  void reset() {
    state = RideIdle();
  }
}

final rideProvider = StateNotifierProvider<RideNotifier, RideState>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState is AuthAuthenticated ? authState.user.id : '';
  
  return RideNotifier(
    ref.read(rideRepositoryProvider),
    ref.read(webSocketServiceProvider),
    userId,
    ref,
  );
});
