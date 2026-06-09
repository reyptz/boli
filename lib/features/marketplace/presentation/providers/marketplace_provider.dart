import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/marketplace_repository.dart';
import '../../data/models/marketplace_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository();
});

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }
}

class MarketplaceState {
  final List<Store> stores;
  final List<Product> selectedStoreProducts;
  final List<CartItem> cart;
  final String? selectedStoreId;
  final bool isLoading;
  final String? error;

  MarketplaceState({
    this.stores = const [],
    this.selectedStoreProducts = const [],
    this.cart = const [],
    this.selectedStoreId,
    this.isLoading = false,
    this.error,
  });

  double get totalCartPrice => cart.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));

  MarketplaceState copyWith({
    List<Store>? stores,
    List<Product>? selectedStoreProducts,
    List<CartItem>? cart,
    String? selectedStoreId,
    bool? isLoading,
    String? error,
  }) {
    return MarketplaceState(
      stores: stores ?? this.stores,
      selectedStoreProducts: selectedStoreProducts ?? this.selectedStoreProducts,
      cart: cart ?? this.cart,
      selectedStoreId: selectedStoreId ?? this.selectedStoreId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MarketplaceNotifier extends StateNotifier<MarketplaceState> {
  final MarketplaceRepository _repository;

  MarketplaceNotifier(this._repository) : super(MarketplaceState());

  Future<void> fetchNearbyStores(double lat, double lng) async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repository.getNearbyStores(lat, lng);
      state = state.copyWith(stores: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Échec de chargement des magasins.');
    }
  }

  Future<void> selectStore(String storeId) async {
    state = state.copyWith(isLoading: true, selectedStoreId: storeId, selectedStoreProducts: []);
    try {
      final products = await _repository.getStoreProducts(storeId);
      state = state.copyWith(selectedStoreProducts: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Échec de chargement des articles.');
    }
  }

  void addToCart(Product product) {
    final existingIndex = state.cart.indexWhere((item) => item.product.id == product.id);
    List<CartItem> newCart;
    if (existingIndex >= 0) {
      newCart = List.from(state.cart);
      newCart[existingIndex] = newCart[existingIndex].copyWith(
        quantity: newCart[existingIndex].quantity + 1,
      );
    } else {
      newCart = [...state.cart, CartItem(product: product, quantity: 1)];
    }
    state = state.copyWith(cart: newCart);
  }

  void removeFromCart(Product product) {
    final existingIndex = state.cart.indexWhere((item) => item.product.id == product.id);
    if (existingIndex < 0) return;
    
    final newCart = List<CartItem>.from(state.cart);
    if (newCart[existingIndex].quantity > 1) {
      newCart[existingIndex] = newCart[existingIndex].copyWith(
        quantity: newCart[existingIndex].quantity - 1,
      );
    } else {
      newCart.removeAt(existingIndex);
    }
    state = state.copyWith(cart: newCart);
  }

  void clearCart() {
    state = state.copyWith(cart: const []);
  }

  Future<String?> placeOrder(String customerId) async {
    if (state.cart.isEmpty || state.selectedStoreId == null) return null;
    
    final order = Order(
      storeId: state.selectedStoreId!,
      customerId: customerId,
      items: state.cart.map((c) => OrderItem(
        productId: c.product.id,
        qty: c.quantity,
        price: c.product.price,
      )).toList(),
      total: state.totalCartPrice,
      status: 'pending',
    );

    try {
      final orderId = await _repository.placeOrder(order);
      clearCart();
      return orderId;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la commande.');
      return null;
    }
  }
}

final marketplaceProvider = StateNotifierProvider<MarketplaceNotifier, MarketplaceState>((ref) {
  return MarketplaceNotifier(ref.read(marketplaceRepositoryProvider));
});
