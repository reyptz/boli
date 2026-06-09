import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/components/boli_glass_card.dart';
import '../providers/delivery_provider.dart';

class DeliveryTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const DeliveryTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends ConsumerState<DeliveryTrackingScreen> {
  final MapController _mapController = MapController();
  final LatLng _storeLocation = const LatLng(12.6450, -8.0050); // MOCK Store location
  final LatLng _userLocation = const LatLng(12.6392, -8.0029); // MOCK Client location
  
  LatLng? _lastDriverLocation;

  String _getFrenchStatus(String status) {
    switch (status) {
      case 'pending': return 'Recherche d\'un livreur...';
      case 'assigned': return 'Livreur assigné';
      case 'going_to_store': return 'En route vers le magasin';
      case 'picked_up': return 'Colis récupéré';
      case 'on_the_way': return 'En route vers vous';
      case 'delivered': return 'Livré avec succès';
      default: return 'En cours...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderStream = ref.watch(deliveryTrackingStreamProvider(widget.orderId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: AppColors.surfaceLight,
            child: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: orderStream.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Erreur: $err', style: AppTextStyles.bodyMedium)),
        data: (order) {
          if (order == null) {
            return Center(child: Text('Commande introuvable.', style: AppTextStyles.bodyMedium));
          }

          LatLng? driverLoc;
          if (order.driverLat != null && order.driverLng != null) {
            driverLoc = LatLng(order.driverLat!, order.driverLng!);
            if (_lastDriverLocation == null || _lastDriverLocation!.latitude != driverLoc.latitude || _lastDriverLocation!.longitude != driverLoc.longitude) {
              _lastDriverLocation = driverLoc;
              // On centre la carte sur le chauffeur s'il bouge
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _mapController.move(driverLoc!, 15.5);
              });
            }
          }

          final statusText = _getFrenchStatus(order.deliveryStatus);

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _userLocation,
                  initialZoom: 14.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.boli.app',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_storeLocation, _userLocation],
                        color: AppColors.primary.withValues(alpha: 0.5),
                        strokeWidth: 4.0,
                        pattern: const StrokePattern.dotted(),
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _userLocation,
                        width: 40,
                        height: 40,
                        child: const Icon(LucideIcons.home, color: AppColors.success, size: 30),
                      ),
                      Marker(
                        point: _storeLocation,
                        width: 40,
                        height: 40,
                        child: const Icon(LucideIcons.store, color: AppColors.secondary, size: 30),
                      ),
                      if (driverLoc != null)
                        Marker(
                          point: driverLoc,
                          width: 50,
                          height: 50,
                          child: Bounce(
                            infinite: true,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 3),
                              ),
                              child: const Icon(LucideIcons.bike, color: Colors.black, size: 24),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              // Bottom Sheet with Driver Info
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      boxShadow: [
                        BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -5)),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusText,
                                  style: AppTextStyles.h2.copyWith(color: AppColors.primary, fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Commande #${widget.orderId.substring(0, 8)}',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                            if (order.deliveryStatus != 'delivered' && order.deliveryStatus != 'pending')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'En direct',
                                  style: AppTextStyles.h3.copyWith(fontSize: 14),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (order.driverId != null)
                          BoliGlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.surfaceLight,
                                  child: Icon(LucideIcons.user, color: AppColors.primary),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Livreur Pro', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                      Text('ID: ${order.driverId!.substring(0, 8)}', style: AppTextStyles.caption),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.phone, color: AppColors.success),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

