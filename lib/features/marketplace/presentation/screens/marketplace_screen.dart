import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import '../providers/marketplace_provider.dart';
import '../../../rides/presentation/providers/ride_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../data/models/marketplace_models.dart';
import '../../../rides/domain/models/ride_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/components/boli_glass_card.dart';
import '../../../../core/components/boli_button.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  final double userLat;
  final double userLng;

  const MarketplaceScreen({
    super.key,
    required this.userLat,
    required this.userLng,
  });

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(marketplaceProvider.notifier).fetchNearbyStores(widget.userLat, widget.userLng);
    });
  }

  void _showStoreProducts(Store store) {
    ref.read(marketplaceProvider.notifier).selectStore(store.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BoliGlassCard(
            borderRadius: 30,
            padding: EdgeInsets.zero,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
              child: Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(marketplaceProvider);
                  return Column(
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
                                Text(
                                  store.name,
                                  style: AppTextStyles.h2,
                                ),
                                Text(
                                  'MAGASIN', // Placeholder for store category
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                        child: state.isLoading
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: state.selectedStoreProducts.length,
                                itemBuilder: (context, index) {
                                  final product = state.selectedStoreProducts[index];
                                  return FadeInUp(
                                    delay: Duration(milliseconds: 50 * index),
                                    duration: const Duration(milliseconds: 400),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLight.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.1)),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name, 
                                                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                                ),
                                                if (product.description != null && product.description!.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    product.description!, 
                                                    style: AppTextStyles.caption,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${product.price.toInt()} XOF',
                                                style: AppTextStyles.bodyMedium.copyWith(
                                                  color: AppColors.primary, 
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              IconButton(
                                                icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary, size: 28),
                                                onPressed: () {
                                                  ref.read(marketplaceProvider.notifier).addToCart(product);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('${product.name} ajouté au panier !', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                                                      duration: const Duration(seconds: 1),
                                                      behavior: SnackBarBehavior.floating,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                    ),
                                                  );
                                                },
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BoliGlassCard(
            borderRadius: 30,
            padding: EdgeInsets.zero,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: MediaQuery.of(context).padding.bottom + 20),
              child: Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(marketplaceProvider);
                  return Column(
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
                          Text(
                            'Votre Panier Boli',
                            style: AppTextStyles.h2,
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      Divider(color: AppColors.primaryDark.withValues(alpha: 0.1), height: 20),
                      if (state.cart.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.shoppingCart, size: 48, color: AppColors.textSecondary),
                                const SizedBox(height: 12),
                                Text('Votre panier est vide.', style: AppTextStyles.bodyMedium),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: state.cart.length,
                            itemBuilder: (context, index) {
                              final item = state.cart[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.product.name,
                                            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.product.price.toInt()} XOF',
                                            style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(LucideIcons.minusCircle, color: AppColors.error),
                                          onPressed: () {
                                            ref.read(marketplaceProvider.notifier).removeFromCart(item.product);
                                          },
                                        ),
                                        Text(
                                          '${item.quantity}', 
                                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        IconButton(
                                          icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary),
                                          onPressed: () {
                                            ref.read(marketplaceProvider.notifier).addToCart(item.product);
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
                        Divider(color: AppColors.primaryDark.withValues(alpha: 0.1), height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total du Panier', style: AppTextStyles.bodyLarge),
                            Text(
                              '${state.totalCartPrice.toInt()} XOF',
                              style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        BoliButton(
                          text: 'Valider & Payer',
                          onPressed: () {
                            Navigator.pop(context);
                            _checkout(state.totalCartPrice);
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _checkout(double totalAmount) async {
    final walletState = ref.read(walletProvider);
    if (walletState.balance < totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solde insuffisant dans votre portefeuille. Recharger d\'abord !', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    try {
      ref.read(walletProvider.notifier).deposit(-totalAmount, ''); // Simuler le débit
      
      final orderId = await ref.read(marketplaceProvider.notifier).placeOrder('customer_uid_placeholder');
      
      if (orderId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Commande validée ! Un livreur Boli va être assigné.', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Navigate to the delivery tracking screen with the new order ID
        context.push('/delivery-tracking/$orderId');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de facturation.', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: AppColors.textTertiary.withValues(alpha: 0.2),
        centerTitle: true,
        title: Text(
          'Boli Souq & Resto', 
          style: AppTextStyles.h2.copyWith(fontSize: 20, color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.shoppingCart, color: AppColors.textPrimary),
                onPressed: _showCart,
              ),
              if (state.cart.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${state.cart.length}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white, 
                        fontSize: 9, 
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading && state.stores.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInLeft(
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commerces à proximité',
                          style: AppTextStyles.h1.copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sélectionnez un magasin ou restaurant pour commander.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: state.stores.length,
                      itemBuilder: (context, index) {
                        final store = state.stores[index];
                        Color accentColor = AppColors.primary;

                        return FadeInUp(
                          delay: Duration(milliseconds: 100 * index),
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: BoliGlassCard(
                              padding: EdgeInsets.zero,
                              borderRadius: 20,
                              child: InkWell(
                                onTap: () => _showStoreProducts(store),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: accentColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Icon(LucideIcons.store, color: accentColor, size: 28),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              store.name,
                                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'MAGASIN',
                                              style: AppTextStyles.caption.copyWith(
                                                color: accentColor,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.0,
                                              ),
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
            ),
    );
  }
}
