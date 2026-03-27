import 'package:flutter/material.dart';

/// Skeleton loader for itinerary items
class ItineraryListSkeleton extends StatelessWidget {
  final int itemCount;

  const ItineraryListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) => const _ItinerarySkeletonItem(),
    );
  }
}

class _ItinerarySkeletonItem extends StatelessWidget {
  const _ItinerarySkeletonItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 17, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Touchpoint skeleton
          SizedBox(
            width: 30,
            child: Column(
              children: [
                _SkeletonBox(
                  width: 20,
                  height: 20,
                  borderRadius: BorderRadius.circular(10),
                  marginBottom: 4,
                ),
                _SkeletonBox(
                  width: 20,
                  height: 11,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Client info skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(
                  width: double.infinity,
                  height: 14,
                  marginBottom: 6,
                ),
                _SkeletonBox(
                  width: 200,
                  height: 11,
                  marginBottom: 4,
                ),
                _SkeletonBox(
                  width: 150,
                  height: 11,
                ),
              ],
            ),
          ),
          // Status and notes skeleton
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _SkeletonBox(
                  width: 50,
                  height: 18,
                  borderRadius: BorderRadius.circular(4),
                  marginBottom: 6,
                ),
                _SkeletonBox(
                  width: 60,
                  height: 10,
                  marginBottom: 4,
                ),
                _SkeletonBox(
                  width: 40,
                  height: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable skeleton box widget
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final double? marginBottom;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius,
    this.marginBottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: marginBottom != null ? EdgeInsets.only(bottom: marginBottom!) : null,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}
