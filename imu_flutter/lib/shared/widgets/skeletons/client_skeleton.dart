import 'package:flutter/material.dart';

/// Skeleton loader for client list items
class ClientListSkeleton extends StatelessWidget {
  final int itemCount;

  const ClientListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) => const _ClientSkeletonItem(),
    );
  }
}

class _ClientSkeletonItem extends StatelessWidget {
  const _ClientSkeletonItem();

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
          // Avatar skeleton
          _SkeletonBox(
            width: 50,
            height: 50,
            borderRadius: BorderRadius.circular(25),
          ),
          const SizedBox(width: 12),
          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(
                  width: double.infinity,
                  height: 16,
                  marginBottom: 8,
                ),
                _SkeletonBox(
                  width: 150,
                  height: 12,
                  marginBottom: 6,
                ),
                _SkeletonBox(
                  width: 100,
                  height: 12,
                ),
              ],
            ),
          ),
          // Right side skeleton
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _SkeletonBox(
                  width: 60,
                  height: 20,
                  borderRadius: BorderRadius.circular(4),
                  marginBottom: 6,
                ),
                _SkeletonBox(
                  width: 40,
                  height: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for My Day page
class MyDaySkeleton extends StatelessWidget {
  const MyDaySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(17),
      children: [
        // Header skeleton
        _SkeletonBox(
          width: 200,
          height: 24,
          marginBottom: 16,
        ),
        // Stats skeleton
        Row(
          children: [
            Expanded(
              child: _StatCardSkeleton(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCardSkeleton(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // List skeleton
        const _VisitSkeletonItem(),
        const _VisitSkeletonItem(),
        const _VisitSkeletonItem(),
      ],
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SkeletonBox(
            width: 40,
            height: 32,
            marginBottom: 8,
          ),
          _SkeletonBox(
            width: 80,
            height: 12,
          ),
        ],
      ),
    );
  }
}

class _VisitSkeletonItem extends StatelessWidget {
  const _VisitSkeletonItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(20),
            marginBottom: 12,
          ),
          _SkeletonBox(
            width: double.infinity,
            height: 16,
            marginBottom: 8,
          ),
          _SkeletonBox(
            width: 200,
            height: 12,
            marginBottom: 12,
          ),
          Row(
            children: [
              _SkeletonBox(
                width: 60,
                height: 20,
                borderRadius: BorderRadius.circular(4),
                marginBottom: 8,
              ),
              const SizedBox(width: 8),
              _SkeletonBox(
                width: 80,
                height: 12,
              ),
            ],
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
