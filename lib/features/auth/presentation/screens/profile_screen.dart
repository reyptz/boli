import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../domain/models/auth_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/components/boli_glass_card.dart';
import '../../../../core/components/boli_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late bool _is2faEnabled;
  bool _initialized = false;

  @override
  void dispose() {
    if (_initialized) {
      _usernameController.dispose();
      _phoneController.dispose();
    }
    super.dispose();
  }

  void _initFields(User user) {
    if (!_initialized) {
      _usernameController = TextEditingController(text: user.username);
      _phoneController = TextEditingController(text: user.phone);
      _is2faEnabled = user.is2faEnabled;
      _initialized = true;
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authProvider.notifier).updateProfile(
          username: _usernameController.text.trim(),
          phone: _phoneController.text.trim(),
          is2faEnabled: _is2faEnabled,
        );
        setState(() {
          _isEditing = false;
          _initialized = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil mis à jour !', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''), style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final user = authState.user;
    _initFields(user);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: AppColors.textTertiary.withValues(alpha: 0.2),
        title: Text(
          _isEditing ? 'Modifier le Profil' : 'Mon Profil', 
          style: AppTextStyles.h2.copyWith(fontSize: 20, color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        centerTitle: true,
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(LucideIcons.edit, color: AppColors.primary),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Modifier',
            ),
            IconButton(
              icon: const Icon(LucideIcons.logOut, color: AppColors.error),
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
              tooltip: 'Se déconnecter',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _initialized = false;
                });
              },
              tooltip: 'Annuler',
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 180.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Avatar Header
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: AppColors.surfaceLight,
                          child: const Icon(LucideIcons.user, size: 48, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.username ?? 'Utilisateur Boli',
                        style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? 'Email non renseigné',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Éditer les informations' : 'Mes Informations',
                      style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 16),
                    
                    if (!_isEditing) ...[
                      _buildInfoCard('Identifiant Unique', user.id, LucideIcons.hash),
                      _buildInfoCard('Rôle de l\'utilisateur', user.role.toUpperCase(), LucideIcons.shield),
                      _buildInfoCard('Nom d\'utilisateur', user.username ?? 'Non renseigné', LucideIcons.user),
                      _buildInfoCard('Numéro de téléphone', user.phone ?? 'Non renseigné', LucideIcons.phone),
                      _buildInfoCard('Adresse Email', user.email ?? 'Non renseigné', LucideIcons.mail),
                      _buildInfoCard(
                        'Double Facteur (2FA)', 
                        user.is2faEnabled ? 'Sécurisé (Activé)' : 'Non sécurisé (Désactivé)', 
                        LucideIcons.lock,
                        isHighlight: user.is2faEnabled,
                      ),
                      const SizedBox(height: 24),
                      BoliButton(
                        text: 'Historique de mes courses',
                        isSecondary: true,
                        onPressed: () => context.push('/ride-history'),
                      ),
                      if (user.role == 'client') ...[
                        const SizedBox(height: 16),
                        BoliButton(
                          text: 'Devenir Partenaire (Livreur / Chauffeur)',
                          onPressed: () => context.push('/partner-onboarding'),
                        ),
                      ],
                    ] else ...[
                      // Username field
                      _buildEditField(
                        label: 'Nom d\'utilisateur',
                        controller: _usernameController,
                        icon: LucideIcons.user,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer un nom d\'utilisateur';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Phone field
                      _buildEditField(
                        label: 'Numéro de téléphone',
                        controller: _phoneController,
                        icon: LucideIcons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer votre numéro';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // 2FA toggle card
                      BoliGlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        borderRadius: 16,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (_is2faEnabled ? AppColors.success : AppColors.primary).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                LucideIcons.lock, 
                                color: _is2faEnabled ? AppColors.success : AppColors.primary, 
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Double Facteur (2FA)', 
                                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _is2faEnabled ? 'Sécurisé (Activé)' : 'Non sécurisé (Désactivé)', 
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _is2faEnabled ? AppColors.success : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _is2faEnabled,
                              activeColor: AppColors.success,
                              onChanged: (val) {
                                setState(() {
                                  _is2faEnabled = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      BoliButton(
                        text: 'Enregistrer les modifications',
                        onPressed: _saveProfile,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, {bool isHighlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: BoliGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: 16,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isHighlight ? AppColors.success : AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon, 
                color: isHighlight ? AppColors.success : AppColors.primary, 
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label, 
                    style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value, 
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isHighlight ? AppColors.success : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return BoliGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 16,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }
}
