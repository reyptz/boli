import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/components/boli_glass_card.dart';
import '../../../../core/components/boli_button.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/marketplace_models.dart';
import '../../presentation/providers/marketplace_provider.dart';

class FoodRestaurant {
  final String id;
  final String name;
  final String category;
  final double rating;
  final String deliveryTime;
  final String emoji;
  final List<Product> menu;

  FoodRestaurant({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.deliveryTime,
    required this.emoji,
    required this.menu,
  });
}

class FoodScreen extends ConsumerStatefulWidget {
  const FoodScreen({super.key});

  @override
  ConsumerState<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends ConsumerState<FoodScreen> {
  final List<CartItem> _foodCart = [];
  String _selectedCategory = 'Tout';
  String _searchQuery = '';
  String? _selectedRestaurantId;

  final List<String> _categories = ['Tout', 'Burgers', 'Pizzas', 'Plats Locaux', 'Desserts', 'Boissons'];

  final double _deliveryFee = 1000.0;
  final double _serviceFee = 200.0;

  // Mock Restaurants & Menus
  final List<FoodRestaurant> _restaurants = [
    FoodRestaurant(
      id: 'rest_burger',
      name: 'Burger Palace',
      category: 'Burgers',
      rating: 4.8,
      deliveryTime: '15-25 min',
      emoji: '🍔',
      menu: [
        Product(id: 'food_b1', storeId: 'rest_burger', name: 'Cheeseburger Premium', price: 2500, description: 'Bœuf grillé, cheddar fondu, cornichons, sauce secrète.'),
        Product(id: 'food_b2', storeId: 'rest_burger', name: 'Double Bacon Burger', price: 3500, description: 'Double bœuf, bacon croustillant, cheddar, oignons caramélisés.'),
        Product(id: 'food_b3', storeId: 'rest_burger', name: 'Frites de Patate Douce', price: 1200, description: 'Frites croustillantes assaisonnées.'),
      ],
    ),
    FoodRestaurant(
      id: 'rest_mali',
      name: 'Mama Mali Restaurant',
      category: 'Plats Locaux',
      rating: 4.9,
      deliveryTime: '20-35 min',
      emoji: '🍲',
      menu: [
        Product(id: 'food_l1', storeId: 'rest_mali', name: 'Tiguadégué (Sauce Arachide)', price: 3000, description: 'Poulet tendre mijoté dans une sauce onctueuse à l\'arachide, servi avec du riz.'),
        Product(id: 'food_l2', storeId: 'rest_mali', name: 'Thieboudienne Poisson', price: 3500, description: 'Riz rouge sénégalais traditionnel mijoté avec du poisson et des légumes frais.'),
        Product(id: 'food_l3', storeId: 'rest_mali', name: 'Aloko (Bananes Plantains)', price: 1000, description: 'Rondelles de bananes plantains frites, servies avec sauce pimentée.'),
      ],
    ),
    FoodRestaurant(
      id: 'rest_pizza',
      name: 'Pizzeria Gusto',
      category: 'Pizzas',
      rating: 4.6,
      deliveryTime: '25-40 min',
      emoji: '🍕',
      menu: [
        Product(id: 'food_p1', storeId: 'rest_pizza', name: 'Pizza Margherita', price: 4000, description: 'Sauce tomate maison, mozzarella fraîche, basilic, huile d\'olive.'),
        Product(id: 'food_p2', storeId: 'rest_pizza', name: 'Pizza Regina', price: 5000, description: 'Sauce tomate, mozzarella, jambon de dinde, champignons frais.'),
        Product(id: 'food_p3', storeId: 'rest_pizza', name: 'Calzone Classique', price: 5500, description: 'Pizza repliée farcie à la ricotta, mozzarella et jambon.'),
      ],
    ),
    FoodRestaurant(
      id: 'rest_sucre',
      name: 'Le Jardin Sucré',
      category: 'Desserts',
      rating: 4.7,
      deliveryTime: '10-20 min',
      emoji: '🍰',
      menu: [
        Product(id: 'food_d1', storeId: 'rest_sucre', name: 'Fondant au Chocolat', price: 1500, description: 'Cœur coulant au chocolat noir, boule de glace vanille.'),
        Product(id: 'food_d2', storeId: 'rest_sucre', name: 'Crêpe Banane Chocolat', price: 1800, description: 'Crêpe maison garnie de bananes fraîches et coulis chocolat chaud.'),
        Product(id: 'food_d3', storeId: 'rest_sucre', name: 'Jus de Bissap Maison', price: 800, description: 'Jus de fleurs d\'hibiscus frais parfumé à la menthe.'),
      ],
    ),
  ];

  double get _subtotalPrice => _foodCart.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  double get _totalCheckoutPrice => _subtotalPrice > 0 ? (_subtotalPrice + _deliveryFee + _serviceFee) : 0.0;

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _foodCart.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        _foodCart[existingIndex] = _foodCart[existingIndex].copyWith(
          quantity: _foodCart[existingIndex].quantity + 1,
        );
      } else {
        _foodCart.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  void _removeFromCart(Product product) {
    setState(() {
      final existingIndex = _foodCart.indexWhere((item) => item.product.id == product.id);
      if (existingIndex < 0) return;
      if (_foodCart[existingIndex].quantity > 1) {
        _foodCart[existingIndex] = _foodCart[existingIndex].copyWith(
          quantity: _foodCart[existingIndex].quantity - 1,
        );
      } else {
        _foodCart.removeAt(existingIndex);
      }
    });
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              child: BoliGlassCard(
                borderRadius: 30,
                padding: EdgeInsets.zero,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  padding: EdgeInsets.only(
                    left: 24, 
                    right: 24, 
                    top: 16, 
                    bottom: MediaQuery.of(context).padding.bottom + 16
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Mon Panier Repas', style: AppTextStyles.h2),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _foodCart.isEmpty
                            ? Center(
                                child: Text('Votre panier est vide.', style: AppTextStyles.bodyMedium),
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: _foodCart.length,
                                itemBuilder: (context, index) {
                                  final item = _foodCart[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.product.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                              const SizedBox(height: 4),
                                              Text('${item.product.price.toInt()} XOF x ${item.quantity}', style: AppTextStyles.caption),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(LucideIcons.minusCircle, color: AppColors.primary, size: 22),
                                              onPressed: () {
                                                _removeFromCart(item.product);
                                                setModalState(() {});
                                                setState(() {});
                                              },
                                            ),
                                            Text('${item.quantity}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary, size: 22),
                                              onPressed: () {
                                                _addToCart(item.product);
                                                setModalState(() {});
                                                setState(() {});
                                              },
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (_foodCart.isNotEmpty) ...[
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Sous-total', style: AppTextStyles.bodyMedium),
                              Text('${_subtotalPrice.toInt()} XOF', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Frais de livraison', style: AppTextStyles.bodyMedium),
                              Text('${_deliveryFee.toInt()} XOF', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Frais de service Boli', style: AppTextStyles.bodyMedium),
                              Text('${_serviceFee.toInt()} XOF', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total à payer', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                              Text('${_totalCheckoutPrice.toInt()} XOF', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        BoliButton(
                          text: 'Confirmer et Payer',
                          onPressed: () async {
                            Navigator.pop(context);
                            await _processFoodCheckout();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _processFoodCheckout() async {
    final walletState = ref.read(walletProvider);
    final authState = ref.read(authProvider);

    if (authState is! AuthAuthenticated) return;
    final customerId = authState.user.id;

    if (walletState.balance < _totalCheckoutPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solde insuffisant dans votre portefeuille.', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    try {
      // Débit du portefeuille (Total incluant les frais)
      ref.read(walletProvider.notifier).deposit(-_totalCheckoutPrice, '');

      // Création de l'objet Order de type Food
      final order = Order(
        storeId: _selectedRestaurantId ?? 'Restaurant Boli',
        customerId: customerId,
        items: _foodCart.map((c) => OrderItem(
          productId: c.product.id,
          qty: c.quantity,
          price: c.product.price,
        )).toList(),
        total: _totalCheckoutPrice,
        status: 'pending',
      );

      final orderId = await ref.read(marketplaceRepositoryProvider).placeOrder(order);

      if (orderId != null && mounted) {
        setState(() {
          _foodCart.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Commande repas validée ! Un livreur est en route.', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        context.push('/delivery-tracking/$orderId');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec de la commande.', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showRestaurantProducts(FoodRestaurant rest) {
    setState(() {
      _selectedRestaurantId = rest.name;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              child: BoliGlassCard(
                borderRadius: 30,
                padding: EdgeInsets.zero,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  padding: EdgeInsets.only(
                    left: 24, 
                    right: 24, 
                    top: 16, 
                    bottom: MediaQuery.of(context).padding.bottom + 16
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rest.name, style: AppTextStyles.h2),
                                Text(
                                  'RESTO • ⭐ ${rest.rating} • ⏱️ ${rest.deliveryTime}', 
                                  style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      Divider(color: AppColors.primaryDark.withValues(alpha: 0.1), height: 24),
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: rest.menu.length,
                          itemBuilder: (context, index) {
                            final product = rest.menu[index];
                            final cartItemIndex = _foodCart.indexWhere((item) => item.product.id == product.id);
                            final quantityInCart = cartItemIndex >= 0 ? _foodCart[cartItemIndex].quantity : 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.1)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(product.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                        if (product.description != null) ...[
                                          const SizedBox(height: 4),
                                          Text(product.description!, style: AppTextStyles.caption),
                                        ],
                                        const SizedBox(height: 8),
                                        Text('${product.price.toInt()} XOF', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (quantityInCart == 0)
                                    IconButton(
                                      icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary, size: 28),
                                      onPressed: () {
                                        _addToCart(product);
                                        setModalState(() {});
                                        setState(() {});
                                      },
                                    )
                                  else
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(LucideIcons.minusCircle, color: AppColors.primary, size: 24),
                                          onPressed: () {
                                            _removeFromCart(product);
                                            setModalState(() {});
                                            setState(() {});
                                          },
                                        ),
                                        Text('$quantityInCart', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                        IconButton(
                                          icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary, size: 24),
                                          onPressed: () {
                                            _addToCart(product);
                                            setModalState(() {});
                                            setState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRestaurants = _restaurants.where((r) {
      final matchesCategory = _selectedCategory == 'Tout' || r.category == _selectedCategory;
      final matchesSearch = r.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: AppColors.textTertiary.withValues(alpha: 0.2),
        centerTitle: true,
        title: Text('Boli Resto & Food', style: AppTextStyles.h2.copyWith(fontSize: 20, color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.shoppingBag, color: AppColors.textPrimary),
                onPressed: _showCart,
              ),
              if (_foodCart.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${_foodCart.fold(0, (sum, item) => sum + item.quantity)}',
                      style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner or categories list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInLeft(
                  duration: const Duration(milliseconds: 500),
                  child: Text('Qu\'allez-vous manger ?', style: AppTextStyles.h1.copyWith(fontSize: 24)),
                ),
                const SizedBox(height: 4),
                Text('Sélectionnez un restaurant à Bamako.', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: BoliGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: 16,
              child: Row(
                children: [
                  const Icon(LucideIcons.search, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un restaurant...',
                        hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Horizontal Category List
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.primaryDark.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Restaurants List
          Expanded(
            child: filteredRestaurants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.searchCode, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text('Aucun restaurant ne correspond à votre recherche.', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 100),
                    itemCount: filteredRestaurants.length,
                    itemBuilder: (context, index) {
                      final rest = filteredRestaurants[index];
                      return FadeInUp(
                        delay: Duration(milliseconds: 50 * index),
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: BoliGlassCard(
                            padding: EdgeInsets.zero,
                            borderRadius: 20,
                            child: InkWell(
                              onTap: () => _showRestaurantProducts(rest),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        rest.emoji,
                                        style: const TextStyle(fontSize: 26),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(rest.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(LucideIcons.star, color: Colors.amber, size: 14),
                                              const SizedBox(width: 4),
                                              Text('${rest.rating}', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                                              const SizedBox(width: 12),
                                              const Icon(LucideIcons.clock, color: AppColors.textSecondary, size: 14),
                                              const SizedBox(width: 4),
                                              Text(rest.deliveryTime, style: AppTextStyles.caption),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
