import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';

import '../providers/ride_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/components/boli_glass_card.dart';

class RideHistoryScreen extends ConsumerStatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  ConsumerState<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends ConsumerState<RideHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _history = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final list = await ref.read(rideRepositoryProvider).getRideHistory();
      if (mounted) {
        setState(() {
          _history = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Impossible de charger l'historique des courses.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: AppColors.textTertiary.withValues(alpha: 0.2),
        centerTitle: true,
        title: Text(
          'Mes Courses Boli', 
          style: AppTextStyles.h2.copyWith(fontSize: 20, color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)))
              : _history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.navigationOff, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune course enregistrée.',
                            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        final type = item['type'] ?? 'vtc';
                        final status = item['status'] ?? 'completed';
                        final price = (item['price'] as num?)?.toInt() ?? 0;
                        final dateStr = item['created_at'] != null 
                            ? DateTime.parse(item['created_at']).toLocal().toString().substring(0, 16)
                            : '';

                        IconData icon = LucideIcons.car;
                        Color statusColor = AppColors.success;
                        String label = "Trajet VTC";

                        if (type == 'food') {
                          icon = LucideIcons.pizza;
                          label = "Livraison Repas";
                        } else if (type == 'delivery') {
                          icon = LucideIcons.package;
                          label = "Livraison Colis";
                        }

                        if (status == 'cancelled') {
                          statusColor = AppColors.error;
                        } else if (status != 'completed' && status != 'delivered') {
                          statusColor = AppColors.warning;
                        }

                        return FadeInUp(
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: BoliGlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(icon, color: AppColors.primary, size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            label,
                                            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: AppTextStyles.caption.copyWith(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        dateStr,
                                        style: AppTextStyles.caption,
                                      ),
                                      Text(
                                        '$price XOF',
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ID : ${item['id'].toString().substring(0, 8).toUpperCase()}',
                                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
