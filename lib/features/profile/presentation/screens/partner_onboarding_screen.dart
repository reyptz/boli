import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/components/boli_glass_card.dart';
import '../../../../core/components/boli_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PartnerOnboardingScreen extends ConsumerStatefulWidget {
  const PartnerOnboardingScreen({super.key});

  @override
  ConsumerState<PartnerOnboardingScreen> createState() => _PartnerOnboardingScreenState();
}

class _PartnerOnboardingScreenState extends ConsumerState<PartnerOnboardingScreen> {
  String _selectedRole = ''; // 'driver' or 'delivery'
  String _selectedVehicle = ''; // 'moto', 'voiture', 'velo'
  bool _isLoading = false;

  void _submit() async {
    if (_selectedRole.isEmpty || _selectedVehicle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner un rôle et un véhicule.', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.updateProfile(
        role: _selectedRole,
        vehicleType: _selectedVehicle,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Félicitations, vous êtes maintenant partenaire !', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
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
        title: Text('Devenir Partenaire', style: AppTextStyles.h2.copyWith(fontSize: 20, color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 180.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Text(
                'Rejoignez la flotte Boli !',
                style: AppTextStyles.h1.copyWith(fontSize: 28),
              ),
            ),
            const SizedBox(height: 8),
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              child: Text(
                'Choisissez votre activité et votre moyen de transport pour commencer à gagner.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 32),

            // Role Selection
            Text('1. Quelle activité souhaitez-vous faire ?', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSelectCard(
                    title: 'Chauffeur VTC',
                    icon: LucideIcons.car,
                    isSelected: _selectedRole == 'driver',
                    onTap: () => setState(() => _selectedRole = 'driver'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSelectCard(
                    title: 'Livreur (Food/Colis)',
                    icon: LucideIcons.package,
                    isSelected: _selectedRole == 'delivery',
                    onTap: () => setState(() => _selectedRole = 'delivery'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Vehicle Selection
            Text('2. Quel est votre véhicule ?', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildSelectCard(
                  title: 'Moto',
                  icon: LucideIcons.bike,
                  isSelected: _selectedVehicle == 'moto',
                  onTap: () => setState(() => _selectedVehicle = 'moto'),
                ),
                const SizedBox(height: 12),
                _buildSelectCard(
                  title: 'Voiture',
                  icon: Icons.local_taxi,
                  isSelected: _selectedVehicle == 'voiture',
                  onTap: () => setState(() => _selectedVehicle = 'voiture'),
                ),
                const SizedBox(height: 12),
                _buildSelectCard(
                  title: 'Vélo',
                  icon: Icons.pedal_bike,
                  isSelected: _selectedVehicle == 'velo',
                  onTap: () => setState(() => _selectedVehicle = 'velo'),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Submit Button
            BoliButton(
              text: 'Confirmer et Devenir Partenaire',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primaryDark.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
