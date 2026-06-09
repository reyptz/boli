import 'package:cloud_firestore/cloud_firestore.dart';

class Store {
  final String id;
  final String name;
  final String? address;
  final String? phone;

  Store({
    required this.id,
    required this.name,
    this.address,
    this.phone,
  });

  factory Store.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Store(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'],
      phone: data['phone'],
    );
  }
}

class Product {
  final String id;
  final String storeId;
  final String name;
  final double price;
  final String? description;
  final List<String> images;

  Product({
    required this.id,
    required this.storeId,
    required this.name,
    required this.price,
    this.description,
    this.images = const [],
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final imagesList = (data['images'] as List<dynamic>?)?.map((e) {
      if (e is Map<String, dynamic> && e['uri'] != null) {
        return e['uri'] as String;
      }
      return '';
    }).where((e) => e.isNotEmpty).toList() ?? [];

    return Product(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'],
      images: imagesList,
    );
  }
}

class OrderItem {
  final String productId;
  final int qty;
  final double price;

  OrderItem({
    required this.productId,
    required this.qty,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'qty': qty,
      'price': price,
    };
  }
}

class Order {
  final String? id;
  final String storeId;
  final String customerId;
  final List<OrderItem> items;
  final double total;
  final String status; // 'pending', 'paid', 'cancelled', 'refunded'
  final Timestamp? createdAt;

  // --- Nouveaux champs pour la livraison ---
  final String? driverId;
  final String deliveryStatus; // 'pending', 'assigned', 'going_to_store', 'picked_up', 'on_the_way', 'delivered'
  final double? driverLat;
  final double? driverLng;
  // Optionnel: adresse de livraison du client (pourrait être un GeoPoint ou juste un string/Location)
  final double? deliveryLat;
  final double? deliveryLng;

  Order({
    this.id,
    required this.storeId,
    required this.customerId,
    required this.items,
    required this.total,
    required this.status,
    this.createdAt,
    this.driverId,
    this.deliveryStatus = 'pending',
    this.driverLat,
    this.driverLng,
    this.deliveryLat,
    this.deliveryLng,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>?)?.map((i) {
      return OrderItem(
        productId: i['productId'] ?? '',
        qty: i['qty'] ?? 1,
        price: (i['price'] ?? 0).toDouble(),
      );
    }).toList() ?? [];

    return Order(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      customerId: data['customerId'] ?? '',
      items: itemsList,
      total: (data['total'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] as Timestamp?,
      driverId: data['driverId'],
      deliveryStatus: data['deliveryStatus'] ?? 'pending',
      driverLat: data['driverLat'] != null ? (data['driverLat'] as num).toDouble() : null,
      driverLng: data['driverLng'] != null ? (data['driverLng'] as num).toDouble() : null,
      deliveryLat: data['deliveryLat'] != null ? (data['deliveryLat'] as num).toDouble() : null,
      deliveryLng: data['deliveryLng'] != null ? (data['deliveryLng'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'customerId': customerId,
      'items': items.map((i) => i.toMap()).toList(),
      'total': total,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'driverId': driverId,
      'deliveryStatus': deliveryStatus,
      'driverLat': driverLat,
      'driverLng': driverLng,
      'deliveryLat': deliveryLat,
      'deliveryLng': deliveryLng,
    };
  }
}
