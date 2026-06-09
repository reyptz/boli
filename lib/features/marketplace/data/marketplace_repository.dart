import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'models/marketplace_models.dart';

class MarketplaceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Store>> getNearbyStores(double lat, double lng) async {
    // Note: For a real app, use GeoFlutterFire or a backend function for geo-queries.
    // Here we fetch all active stores from the 'stores' collection as a fallback/mock.
    try {
      final snapshot = await _firestore.collection('stores').get();
      return snapshot.docs.map((doc) => Store.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching stores: $e');
      // Return empty list on failure for now
      return [];
    }
  }

  Future<List<Product>> getStoreProducts(String storeId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('storeId', isEqualTo: storeId)
          .where('enabled', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<String> placeOrder(Order order) async {
    try {
      final docRef = await _firestore.collection('orders').add(order.toMap());
      return docRef.id;
    } catch (e) {
      print('Error placing order: $e');
      throw Exception('Failed to place order');
    }
  }
}
