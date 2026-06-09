import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../marketplace/data/models/marketplace_models.dart';
import '../../data/delivery_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../../../features/rides/presentation/providers/ride_provider.dart';
import '../../../../features/wallet/presentation/providers/wallet_provider.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository();
});

/// Stream un Order spécifique pour le suivi client
final deliveryTrackingStreamProvider = StreamProvider.family<Order?, String>((ref, orderId) {
  final repository = ref.watch(deliveryRepositoryProvider);
  return repository.streamOrder(orderId);
});

/// Stream les livraisons en attente pour les chauffeurs
final availableDeliveriesStreamProvider = StreamProvider<List<Order>>((ref) {
  final repository = ref.watch(deliveryRepositoryProvider);
  return repository.streamAvailableDeliveries();
});

/// Stream les commandes actives en cours pour le client
final activeCustomerOrdersStreamProvider = StreamProvider<List<Order>>((ref) {
  final repository = ref.watch(deliveryRepositoryProvider);
  final authState = ref.watch(authProvider);
  final customerId = authState is AuthAuthenticated ? authState.user.id : '';
  if (customerId.isEmpty) return Stream.value([]);
  return repository.streamActiveOrdersForCustomer(customerId);
});

/// Pour gérer l'état des actions du livreur
class DeliveryDriverState {
  final bool isLoading;
  final String? error;
  final String? activeOrderId; // L'ID de la commande que le livreur est en train de livrer

  DeliveryDriverState({this.isLoading = false, this.error, this.activeOrderId});

  DeliveryDriverState copyWith({bool? isLoading, String? error, String? activeOrderId, bool clearError = false}) {
    return DeliveryDriverState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeOrderId: activeOrderId ?? this.activeOrderId,
    );
  }
}

class DeliveryDriverNotifier extends StateNotifier<DeliveryDriverState> {
  final DeliveryRepository _repository;
  final String _driverId;
  final Ref ref;

  DeliveryDriverNotifier(this._repository, this._driverId, this.ref) : super(DeliveryDriverState());

  Future<void> acceptDelivery(String orderId) async {
    if (_driverId.isEmpty) return;
    
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.acceptDelivery(orderId, _driverId);
      state = state.copyWith(isLoading: false, activeOrderId: orderId);

      // Fetch details from Firestore to sync
      final doc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      final data = doc.data();
      if (data != null) {
        await ref.read(rideRepositoryProvider).syncMission({
          'ride_id': orderId,
          'client_id': data['customerId'] ?? '',
          'driver_id': _driverId,
          'merchant_id': data['storeId'],
          'type': 'food',
          'status': 'assigned',
          'price': (data['total'] as num?)?.toDouble() ?? 0.0,
        });
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateStatus(String orderId, String status) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.updateDeliveryStatus(orderId, status);

      // Sync with PostgreSQL
      final doc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      final data = doc.data();
      if (data != null) {
        await ref.read(rideRepositoryProvider).syncMission({
          'ride_id': orderId,
          'client_id': data['customerId'] ?? '',
          'driver_id': data['driverId'],
          'merchant_id': data['storeId'],
          'type': 'food',
          'status': status,
          'price': (data['total'] as num?)?.toDouble() ?? 0.0,
        });
      }

      if (status == 'delivered') {
        state = state.copyWith(isLoading: false, activeOrderId: null); // Terminé
        ref.read(walletProvider.notifier).fetchBalance();
        ref.read(walletProvider.notifier).fetchTransactions();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateLocation(String orderId, double lat, double lng) async {
    try {
      await _repository.updateDriverLocation(orderId, lat, lng);
    } catch (e) {
      // Éviter de bloquer si juste une erreur de GPS
      print('Erreur lors de la mise à jour GPS: $e');
    }
  }

  void reset() {
    state = DeliveryDriverState();
  }
}

final deliveryDriverProvider = StateNotifierProvider<DeliveryDriverNotifier, DeliveryDriverState>((ref) {
  final repository = ref.watch(deliveryRepositoryProvider);
  final authState = ref.watch(authProvider);
  final driverId = authState is AuthAuthenticated ? authState.user.id : '';
  
  return DeliveryDriverNotifier(repository, driverId, ref);
});
