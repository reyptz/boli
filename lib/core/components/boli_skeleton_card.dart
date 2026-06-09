import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

class BoliSkeletonCard extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;

  const BoliSkeletonCard({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight.withValues(alpha: 0.2),
      highlightColor: AppColors.surfaceLight.withValues(alpha: 0.5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
