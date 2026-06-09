import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';

import '../providers/ride_provider.dart';
import '../providers/delivery_provider.dart';
import '../../domain/models/ride_models.dart';
import '../../../marketplace/data/models/marketplace_models.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/components/boli_glass_card.dart';
import '../../../../core/components/boli_button.dart';
import '../../../../core/components/boli_skeleton_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();
  ll.LatLng? _currentPosition;
  bool _isDriverMode = false;
  bool _isInitialModeSet = false;
  StreamSubscription<Position>? _positionSubscription;
  List<ll.LatLng> _mockTaxis = [];
  Timer? _mockTaxiTimer;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _startLocationTracking();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        final role = authState.user.role;
        final isPro = role == 'driver' || role == 'delivery';
        setState(() {
          _isDriverMode = isPro;
          _isInitialModeSet = true;
          if (role == 'driver') {
            ref.read(rideProvider.notifier).startListeningForDriverRides();
          } else {
            ref.read(rideProvider.notifier).stopListeningForDriverRides();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mockTaxiTimer?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = ll.LatLng(position.latitude, position.longitude);
      _mapController.move(_currentPosition!, 15.0);
      _initMockTaxis(_currentPosition!);
    });

    ref.read(rideProvider.notifier).sendLocationUpdate(position.latitude, position.longitude);
  }

  void _initMockTaxis(ll.LatLng center) {
    _mockTaxis = [
      ll.LatLng(center.latitude + 0.003, center.longitude + 0.002),
      ll.LatLng(center.latitude - 0.002, center.longitude + 0.004),
      ll.LatLng(center.latitude + 0.0015, center.longitude - 0.003),
    ];
    
    _mockTaxiTimer?.cancel();
    _mockTaxiTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        _mockTaxis = _mockTaxis.map((pos) {
          final latOffset = (timer.tick % 2 == 0 ? 0.00012 : -0.00012) * (timer.tick % 3 == 0 ? 1.1 : 0.7);
          final lngOffset = (timer.tick % 2 == 0 ? -0.00015 : 0.00011) * (timer.tick % 4 == 0 ? 0.8 : 1.2);
          return ll.LatLng(pos.latitude + latOffset, pos.longitude + lngOffset);
        }).toList();
      });
    });
  }

  void _startLocationTracking() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = ll.LatLng(position.latitude, position.longitude);
      });
      ref.read(rideProvider.notifier).sendLocationUpdate(position.latitude, position.longitude);
      
      final deliveryState = ref.read(deliveryDriverProvider);
      if (deliveryState.activeOrderId != null && _isDriverMode) {
        ref.read(deliveryDriverProvider.notifier).updateLocation(
          deliveryState.activeOrderId!, 
          position.latitude, 
          position.longitude
        );
      }

      final rideState = ref.read(rideProvider);
      if (rideState is RideActive && _isDriverMode) {
        ref.read(rideProvider.notifier).updateDriverLocation(
          rideState.rideId,
          position.latitude,
          position.longitude
        );
      }
    });
  }

  void _requestMockRide() {
    if (_currentPosition == null) return;
    
    final dropoff = Location(
      latitude: _currentPosition!.latitude + 0.015, 
      longitude: _currentPosition!.longitude + 0.015
    );
    
    final pickup = Location(
      latitude: _currentPosition!.latitude, 
      longitude: _currentPosition!.longitude
    );

    ref.read(rideProvider.notifier).requestRide(pickup, dropoff);
  }

  void _showDriverModal(RideIncomingForDriver stateData) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Material(
              color: Colors.transparent,
              child: BoliGlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.navigation,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nouvelle Course !',
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Une course de ${stateData.price.toInt()} FCFA est disponible à proximité.\nSouhaitez-vous l\'accepter ?',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: BoliButton(
                            text: 'Ignorer',
                            isSecondary: true,
                            onPressed: () {
                              Navigator.pop(context);
                              ref.read(rideProvider.notifier).reset();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BoliButton(
                            text: 'Accepter',
                            onPressed: () {
                              Navigator.pop(context);
                              ref.read(rideProvider.notifier).acceptRide(stateData.rideId);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNotifications() {
    ref.read(notificationProvider.notifier).markAllAsRead();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BoliGlassCard(
            borderRadius: 30,
            padding: EdgeInsets.zero,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: EdgeInsets.only(
                left: 24, 
                right: 24, 
                top: 16, 
                bottom: MediaQuery.of(context).padding.bottom + 16
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final notifState = ref.watch(notificationProvider);
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
                          Text('Mes Notifications', style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark)),
                          if (notifState.notifications.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                ref.read(notificationProvider.notifier).clearAll();
                              },
                              child: Text('Tout effacer', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                            ),
                        ],
                      ),
                      Divider(color: AppColors.primaryDark.withValues(alpha: 0.1), height: 24),
                      Expanded(
                        child: notifState.notifications.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(LucideIcons.bellOff, size: 48, color: AppColors.textSecondary),
                                    const SizedBox(height: 12),
                                    Text('Aucune notification pour le moment.', style: AppTextStyles.bodyMedium),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: notifState.notifications.length,
                                itemBuilder: (context, index) {
                                  final notif = notifState.notifications[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.05)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(LucideIcons.bell, color: AppColors.primary, size: 18),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(notif.title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                              const SizedBox(height: 4),
                                              Text(notif.message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, fontSize: 13)),
                                              const SizedBox(height: 6),
                                              Text(
                                                '${notif.timestamp.hour.toString().padLeft(2, '0')}:${notif.timestamp.minute.toString().padLeft(2, '0')}',
                                                style: AppTextStyles.caption.copyWith(fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideProvider);
    final deliveryDriverState = ref.watch(deliveryDriverProvider);
    final availableDeliveries = ref.watch(availableDeliveriesStreamProvider);
    final authState = ref.watch(authProvider);
    final isPro = authState is AuthAuthenticated &&
        (authState.user.role == 'driver' || authState.user.role == 'delivery');

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        if (!_isInitialModeSet) {
          final role = next.user.role;
          final isProUser = role == 'driver' || role == 'delivery';
          setState(() {
            _isDriverMode = isProUser;
            _isInitialModeSet = true;
            if (role == 'driver') {
              ref.read(rideProvider.notifier).startListeningForDriverRides();
            } else {
              ref.read(rideProvider.notifier).stopListeningForDriverRides();
            }
          });
        }
      } else if (next is AuthUnauthenticated) {
        setState(() {
          _isDriverMode = false;
          _isInitialModeSet = false;
          ref.read(rideProvider.notifier).stopListeningForDriverRides();
        });
      }
    });

    ref.listen<NotificationState>(notificationProvider, (previous, next) {
      if (next.latestNotification != null && next.latestNotification != previous?.latestNotification) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(next.latestNotification!.title, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(next.latestNotification!.message, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    ref.listen<RideState>(rideProvider, (previous, next) {
      final role = authState is AuthAuthenticated ? authState.user.role : '';
      if (next is RideIncomingForDriver && _isDriverMode && role == 'driver') {
        _showDriverModal(next);
      } else if (next is RideError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)), 
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // --- OpenStreetMap Map Rendering ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition ?? const ll.LatLng(12.6392, -8.0029), // Bamako coords
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.boli.app',
                tileBuilder: (context, tileWidget, tile) {
                  return tileWidget;
                },
              ),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    // Position courante
                    Marker(
                      point: _currentPosition!,
                      width: 60,
                      height: 60,
                      child: Center(
                        child: PulseMarker(
                          color: AppColors.primary,
                          icon: LucideIcons.mapPin,
                        ),
                      ),
                    ),
                    // Si course active et chauffeur géolocalisé
                    if (!_isDriverMode && rideState is RideActive && rideState.driverLat != null)
                      Marker(
                        point: ll.LatLng(rideState.driverLat!, rideState.driverLng!),
                        width: 60,
                        height: 60,
                        child: Center(
                          child: PulseMarker(
                            color: AppColors.secondary,
                            icon: LucideIcons.car,
                          ),
                        ),
                      ),
                    // Taxis à proximité
                    if (!_isDriverMode)
                      ..._mockTaxis.map((pos) => Marker(
                        point: pos,
                        width: 45,
                        height: 45,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(LucideIcons.car, color: Colors.white, size: 16),
                        ),
                      )),
                  ],
                ),
            ],
          ),

          // --- Premium Floating Glass Header ---
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              child: FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: BoliGlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  borderRadius: 16,
                  child: Row(
                    children: [
                      // Profile Link
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: const Icon(LucideIcons.user, size: 18, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Boli Sovereign',
                          style: AppTextStyles.h3.copyWith(
                            fontSize: 16, 
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      // Client / Driver Mode Toggle
                      if (isPro) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isDriverMode 
                                ? AppColors.secondary.withValues(alpha: 0.2) 
                                : AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isDriverMode ? LucideIcons.navigation : LucideIcons.user, 
                                size: 14, 
                                color: _isDriverMode ? AppColors.secondary : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isDriverMode ? 'Pro' : 'Client', 
                                style: AppTextStyles.caption.copyWith(
                                  color: _isDriverMode ? AppColors.secondary : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                height: 24,
                                width: 32,
                                child: Switch(
                                  value: _isDriverMode,
                                  activeColor: AppColors.secondary,
                                  activeTrackColor: AppColors.secondary.withValues(alpha: 0.4),
                                  inactiveThumbColor: AppColors.primary,
                                  inactiveTrackColor: AppColors.primary.withValues(alpha: 0.4),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onChanged: (val) {
                                    HapticFeedback.lightImpact();
                                    final role = authState.user.role;
                                    setState(() {
                                      _isDriverMode = val;
                                      ref.read(rideProvider.notifier).reset();
                                      if (val && role == 'driver') {
                                        ref.read(rideProvider.notifier).startListeningForDriverRides();
                                      } else {
                                        ref.read(rideProvider.notifier).stopListeningForDriverRides();
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Bell Notification Icon
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.bell, color: AppColors.textPrimary, size: 22),
                            onPressed: _showNotifications,
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primaryDark.withValues(alpha: 0.1),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, child) {
                              final notifs = ref.watch(notificationProvider).notifications;
                              final unreadCount = notifs.where((n) => !n.isRead).length;
                              if (unreadCount == 0) return const SizedBox.shrink();
                              return Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Wallet screen navigation button
                      IconButton(
                        icon: const Icon(LucideIcons.wallet, color: AppColors.textPrimary, size: 22),
                        onPressed: () => context.push('/wallet'),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryDark.withValues(alpha: 0.1),
                          padding: const EdgeInsets.all(8),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- Bottom UI Panel ---
          Positioned(
            bottom: 120, // Increased to avoid BoliBottomNavBar
            left: 16,
            right: 16,
            child: _isDriverMode 
                ? _buildDriverPanel(rideState, deliveryDriverState, availableDeliveries)
                : _buildClientPanel(rideState),
          ),
        ],
      ),
    );
  }
  Widget _buildServiceCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFrenchDeliveryStatus(String status) {
    switch (status) {
      case 'pending': return 'Recherche d\'un livreur...';
      case 'assigned': return 'Livreur assigné';
      case 'going_to_store': return 'En route vers le magasin';
      case 'picked_up': return 'Colis récupéré';
      case 'on_the_way': return 'En route vers vous';
      default: return 'En cours...';
    }
  }

  Widget _buildClientPanel(RideState state) {
    if (state is RideIdle || state is RideIncomingForDriver || state is RideError) {
      return FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: BoliGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ref.watch(activeCustomerOrdersStreamProvider).when(
                data: (orders) {
                  if (orders.isEmpty) return const SizedBox.shrink();
                  final latestOrder = orders.first;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.truck, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Livraison en cours', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                              Text('Statut : ${_getFrenchDeliveryStatus(latestOrder.deliveryStatus)}', style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.push('/delivery-tracking/${latestOrder.id}');
                          },
                          child: Text('Suivre', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              Text(
                "Où allons-nous aujourd'hui ?",
                style: AppTextStyles.h2.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Commandez un trajet VTC ou explorez la livraison locale.",
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildServiceCard(
                    title: 'Food',
                    icon: LucideIcons.pizza,
                    color: const Color(0xFFFF3B30), // Red
                    onTap: () {
                      context.push('/food');
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildServiceCard(
                    title: 'VTC',
                    icon: LucideIcons.car,
                    color: const Color(0xFF34C759), // Green
                    onTap: _currentPosition == null ? () {} : _requestMockRide,
                  ),
                  const SizedBox(width: 12),
                  _buildServiceCard(
                    title: 'Market',
                    icon: LucideIcons.shoppingBag,
                    color: const Color(0xFF007AFF), // Blue
                    onTap: () {
                      context.push('/marketplace', extra: {
                        'latitude': _currentPosition?.latitude ?? 12.6392,
                        'longitude': _currentPosition?.longitude ?? -8.0029,
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (state is RideRequesting) {
      return FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: BoliGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Demande en cours...',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 8),
              Text(
                'Initialisation de la transaction...',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (state is RidePending) {
      return FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: BoliGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              SizedBox(
                height: 72,
                width: 72,
                child: Center(
                  child: PulseMarker(
                    color: AppColors.primary,
                    icon: LucideIcons.search,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Recherche d'un chauffeur...",
                style: AppTextStyles.h2.copyWith(fontSize: 20, color: AppColors.primaryDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Nous contactons les chauffeurs disponibles à proximité de votre position. Veuillez patienter.",
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              BoliButton(
                text: 'Annuler la recherche',
                isSecondary: true,
                onPressed: () {
                  ref.read(rideProvider.notifier).updateStatus(state.mission.id, 'cancelled');
                },
              ),
            ],
          ),
        ),
      );
    }

    if (state is RideActive) {
      String statusMsg = "Course acceptée. Paiement en cours...";
      IconData statusIcon = LucideIcons.wallet;
      Color statusColor = AppColors.warning;

      if (state.status == 'going_to_pickup') {
        statusMsg = "Chauffeur assigné ! Il se dirige vers vous.";
        statusIcon = LucideIcons.navigation;
        statusColor = AppColors.primary;
      } else if (state.status == 'arrived') {
        statusMsg = "Votre chauffeur est arrivé au point de départ !";
        statusIcon = LucideIcons.bellRing;
        statusColor = AppColors.secondary;
      } else if (state.status == 'processing') {
        statusMsg = "Course commencée. Bon trajet avec Boli !";
        statusIcon = LucideIcons.compass;
        statusColor = AppColors.success;
      }

      return FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: BoliGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusMsg,
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (state.driverId != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Chauffeur ID: ${state.driverId!.substring(0, 8).toUpperCase()}',
                            style: AppTextStyles.caption,
                          ),
                        ]
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              BoliButton(
                text: 'Annuler ma course',
                isSecondary: true,
                onPressed: () {
                  ref.read(rideProvider.notifier).updateStatus(state.rideId, 'cancelled');
                },
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDriverPanel(RideState state, DeliveryDriverState deliveryState, AsyncValue<List<Order>> availableDeliveries) {
    // Si une livraison est active
    if (deliveryState.activeOrderId != null) {
      return _buildActiveDeliveryPanel(deliveryState.activeOrderId!);
    }

    final authState = ref.read(authProvider);
    final role = authState is AuthAuthenticated ? authState.user.role : '';
    final isVtcDriver = role == 'driver';
    final isDeliverer = role == 'delivery';

    if (isDeliverer) {
      // Les livreurs voient uniquement le statut de livraison active et les livraisons disponibles
      return FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: BoliGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Spin(
                duration: const Duration(seconds: 4),
                infinite: true,
                child: const Icon(LucideIcons.radar, color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'En ligne — Réception active (Livreur)',
                style: AppTextStyles.h3.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre position est partagée en temps réel pour recevoir les livraisons les plus proches.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              availableDeliveries.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Aucune livraison disponible pour le moment.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return Column(
                    children: orders.map((order) => _buildIncomingDeliveryCard(order)).toList(),
                  );
                },
                loading: () => Column(
                  children: List.generate(2, (index) => const Padding(
                    padding: EdgeInsets.only(top: 12.0),
                    child: BoliSkeletonCard(height: 70),
                  )),
                ),
                error: (err, _) => Text('Erreur: $err', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
              ),
            ],
          ),
        ),
      );
    }

    // Si c'est un chauffeur VTC
    if (isVtcDriver && state is RideIncomingForDriver) {
      return FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: BoliGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.car, color: AppColors.secondary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nouvelle course VTC !',
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tarif estimé : ${state.price.toInt()} XOF',
                          style: AppTextStyles.caption.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: BoliButton(
                      text: 'Refuser',
                      isSecondary: true,
                      onPressed: () {
                        ref.read(rideProvider.notifier).reset();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BoliButton(
                      text: 'Accepter',
                      onPressed: () {
                        ref.read(rideProvider.notifier).acceptRide(state.rideId);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (state is RideIdle) {
      return FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: BoliGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Spin(
                duration: const Duration(seconds: 4),
                infinite: true,
                child: const Icon(LucideIcons.radar, color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'En ligne — Réception active',
                style: AppTextStyles.h3.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre position est partagée en temps réel pour recevoir les trajets les plus proches.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Affichage des livraisons disponibles
              availableDeliveries.when(
                data: (orders) {
                  if (orders.isEmpty) return const SizedBox();
                  return Column(
                    children: orders.map((order) => _buildIncomingDeliveryCard(order)).toList(),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),
      );
    }

    if (state is RideRequesting) {
      return FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: BoliGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(
                  color: AppColors.secondary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Validation Mobile Money...',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 8),
              Text(
                'Veuillez patienter pendant la validation de la transaction.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (state is RideActive) {
      String buttonText = "Je suis arrivé";
      String statusText = "En route vers le client";
      String nextStatus = "arrived";
      Color statusColor = AppColors.warning;

      if (state.status == 'arrived') {
        buttonText = "Démarrer la course";
        statusText = "Arrivé au point de chargement";
        nextStatus = "processing";
        statusColor = AppColors.secondary;
      } else if (state.status == 'processing') {
        buttonText = "Terminer la course";
        statusText = "Voyage en cours...";
        nextStatus = "completed";
        statusColor = AppColors.success;
      }

      return FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: BoliGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.navigation, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID Course: ${state.rideId.substring(0, 8).toUpperCase()}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: BoliButton(
                      text: 'Annuler',
                      isSecondary: true,
                      onPressed: () {
                        ref.read(rideProvider.notifier).updateStatus(state.rideId, 'cancelled');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BoliButton(
                      text: buttonText,
                      onPressed: () {
                        ref.read(rideProvider.notifier).updateStatus(state.rideId, nextStatus);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildIncomingDeliveryCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(LucideIcons.package, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nouvelle Livraison', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                Text('${order.items.length} article(s)', style: AppTextStyles.caption),
              ],
            ),
          ),
          BoliButton(
            text: 'Accepter',
            onPressed: () {
              ref.read(deliveryDriverProvider.notifier).acceptDelivery(order.id!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveryPanel(String orderId) {
    final orderStream = ref.watch(deliveryTrackingStreamProvider(orderId));

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: orderStream.when(
        data: (order) {
          if (order == null) return const SizedBox.shrink();
          
          String btnText = 'Arrivé au magasin';
          String nextStatus = 'going_to_store';
          
          if (order.deliveryStatus == 'assigned') {
            btnText = 'Arrivé au magasin';
            nextStatus = 'going_to_store';
          } else if (order.deliveryStatus == 'going_to_store') {
            btnText = 'Colis récupéré';
            nextStatus = 'picked_up';
          } else if (order.deliveryStatus == 'picked_up') {
            btnText = 'En route vers le client';
            nextStatus = 'on_the_way';
          } else if (order.deliveryStatus == 'on_the_way') {
            btnText = 'Livraison terminée';
            nextStatus = 'delivered';
          }

          return BoliGlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.packageCheck, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Livraison en cours',
                            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Statut actuel: ${order.deliveryStatus}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                BoliButton(
                  text: btnText,
                  onPressed: () {
                    ref.read(deliveryDriverProvider.notifier).updateStatus(orderId, nextStatus);
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const BoliGlassCard(child: Center(child: CircularProgressIndicator())),
        error: (e, _) => BoliGlassCard(child: Text('Erreur: $e')),
      ),
    );
  }
}

class PulseMarker extends StatefulWidget {
  final Color color;
  final IconData icon;

  const PulseMarker({
    super.key,
    required this.color,
    required this.icon,
  });

  @override
  State<PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<PulseMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 50 * _animation.value,
                height: 50 * _animation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.4 * (1.0 - _animation.value)),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.color, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 16,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
