import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';

import '../providers/wallet_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/components/boli_glass_card.dart';
import '../../../../core/components/boli_button.dart';
import '../../../../core/components/boli_text_field.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedOperator = 'Wave';

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _recharge(double amount) {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez entrer votre numéro de téléphone.', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    ref.read(walletProvider.notifier).deposit(amount, _phoneController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);

    ref.listen<WalletState>(walletProvider, (previous, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: AppColors.textTertiary.withValues(alpha: 0.2),
        centerTitle: true,
        title: Text(
          'Mon Portefeuille Boli', 
          style: AppTextStyles.h2.copyWith(fontSize: 20, color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 120.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Gradient Virtual Sovereign Credit Card ---
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: BoliGlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 24,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.secondary.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BOLI SOUVERAIN CARD',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary, 
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'SOLDE DISPONIBLE',
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 9,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 28),
                          ],
                        ),
                        state.isLoading 
                            ? const SizedBox(
                                height: 32,
                                width: 32,
                                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                              )
                            : Text(
                                '${state.balance.toInt()} ${state.currency}',
                                style: AppTextStyles.h1.copyWith(
                                  fontSize: 34, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '••••  ••••  ••••  8829',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              'VALIDE',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recharger via Mobile Money',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choisissez votre opérateur et le montant à recharger.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 20),

                    // --- Operator Selection ---
                    Row(
                      children: [
                        _buildOperatorTab('Wave', const Color(0xFF38BDF8), LucideIcons.smartphone),
                        const SizedBox(width: 12),
                        _buildOperatorTab('Orange', const Color(0xFFF97316), LucideIcons.smartphone),
                        const SizedBox(width: 12),
                        _buildOperatorTab('MTN', const Color(0xFFEAB308), LucideIcons.smartphone),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Input Fields ---
                    Text(
                      'Numéro Mobile Money',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    BoliTextField(
                      controller: _phoneController,
                      hintText: 'Ex: 07070707',
                      prefixIcon: LucideIcons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Montant à recharger',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    BoliTextField(
                      controller: _amountController,
                      hintText: 'Montant (XOF)',
                      prefixIcon: LucideIcons.dollarSign,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),

                    // --- Quick Presets ---
                    Text(
                      'Montants prédéfinis',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPresetButton(1000),
                        _buildPresetButton(2000),
                        _buildPresetButton(5000),
                        _buildPresetButton(10000),
                      ],
                    ),

                    const SizedBox(height: 36),

                    BoliButton(
                      text: 'Recharger Maintenant',
                      onPressed: () {
                        final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Veuillez entrer un montant valide.', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          return;
                        }
                        _recharge(amount);
                      },
                      isLoading: state.isLoading,
                    ),

                    const SizedBox(height: 40),
                    Text(
                      'Historique des Transactions',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 16),
                    if (state.transactions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Column(
                            children: [
                              Icon(LucideIcons.listTodo, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text('Aucune transaction enregistrée.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...state.transactions.map((tx) {
                        final isDebit = tx['amount'] < 0;
                        final type = tx['type'] ?? 'deposit';
                        final amount = (tx['amount'] as num).abs().toInt();
                        final dateStr = tx['created_at'] != null 
                            ? DateTime.parse(tx['created_at']).toLocal().toString().substring(0, 16)
                            : '';
                        
                        IconData icon = LucideIcons.arrowUpRight;
                        Color iconColor = AppColors.success;
                        if (isDebit) {
                          icon = LucideIcons.arrowDownLeft;
                          iconColor = AppColors.error;
                        } else if (type == 'earning') {
                          icon = LucideIcons.wallet;
                          iconColor = AppColors.secondary;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: iconColor, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx['description'] ?? 'Transaction',
                                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateStr,
                                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isDebit ? "-" : "+"}$amount XOF',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDebit ? AppColors.error : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorTab(String name, Color color, IconData icon) {
    final isSelected = _selectedOperator == name;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedOperator = name;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : AppColors.primaryDark.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 24),
              const SizedBox(height: 6),
              Text(
                name,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton(double amount) {
    return InkWell(
      onTap: () {
        setState(() {
          _amountController.text = amount.toInt().toString();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.1)),
        ),
        child: Text(
          '+${amount.toInt()}',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold, 
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
