import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import 'boli_glass_card.dart';

class BoliBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BoliBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: BoliGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        borderRadius: 32,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(0, LucideIcons.home, 'Home'),
            _buildNavItem(1, LucideIcons.wallet, 'Wallet'),
            _buildNavItem(2, LucideIcons.shoppingBag, 'Market'),
            _buildNavItem(3, LucideIcons.user, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey<bool>(isSelected),
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: isSelected ? 26 : 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.transparent,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: isSelected ? 1 : 0,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
