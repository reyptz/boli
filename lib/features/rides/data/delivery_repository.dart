import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../marketplace/data/models/marketplace_models.dart';

class DeliveryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Client Side ---
  
  /// Listen to a specific order for real-time delivery updates
  Stream<Order?> streamOrder(String orderId) {
    return _firestore.collection('orders').doc(orderId).snapshots().map((doc) {
      if (doc.exists) {
        return Order.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Listen to active orders in progress for a customer
  Stream<List<Order>> streamActiveOrdersForCustomer(String customerId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final all = snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
          return all.where((order) => order.deliveryStatus != 'delivered').toList();
        });
  }

  // --- Driver Side ---

  /// Listen to available deliveries that need a driver
  Stream<List<Order>> streamAvailableDeliveries() {
    return _firestore
        .collection('orders')
        // Usually we want 'paid' but for testing we can listen to 'pending' as well
        // .where('status', isEqualTo: 'paid') 
        .where('deliveryStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

  /// Accept a delivery
  Future<void> acceptDelivery(String orderId, String driverId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'driverId': driverId,
      'deliveryStatus': 'assigned',
    });
  }

  /// Update the status of the delivery
  Future<void> updateDeliveryStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'deliveryStatus': status,
    });
  }

  /// Update driver's location
  Future<void> updateDriverLocation(String orderId, double lat, double lng) async {
    await _firestore.collection('orders').doc(orderId).update({
      'driverLat': lat,
      'driverLng': lng,
    });
  }
}
