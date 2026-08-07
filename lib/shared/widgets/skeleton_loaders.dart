import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

/// Shimmering placeholder shapes shown while real content loads.
/// Sized and laid out to roughly match the card they're standing in
/// for, so the transition from skeleton -> real content doesn't jump
/// around, and the loading state actually looks intentional instead
/// of a lone spinner floating in empty space.
class ShimmerWrap extends StatelessWidget {
  final Widget child;
  const ShimmerWrap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.background,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

class _Bone extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const _Bone({this.width, this.height = 12, this.radius = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(radius)),
    );
  }
}

/// Matches the shape of [MusicianCard].
class MusicianCardSkeleton extends StatelessWidget {
  const MusicianCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _Bone(width: 52, height: 52, radius: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _Bone(width: 100, height: 14),
                        SizedBox(height: 6),
                        _Bone(width: 70, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _Bone(width: 90, height: 10),
              const SizedBox(height: 12),
              Row(children: const [_Bone(width: 50, height: 22, radius: 12), SizedBox(width: 6), _Bone(width: 50, height: 22, radius: 12)]),
              const Spacer(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [_Bone(width: 60, height: 14), _Bone(width: 80, height: 14)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid of [MusicianCardSkeleton] — drop-in replacement for a loading spinner.
class MusicianGridSkeleton extends StatelessWidget {
  final int columns;
  final int count;
  const MusicianGridSkeleton({super.key, this.columns = 1, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: columns == 1 ? 1.5 : 0.85,
      ),
      itemCount: count,
      itemBuilder: (context, i) => const MusicianCardSkeleton(),
    );
  }
}

/// Matches the shape of an event list row.
class EventRowSkeleton extends StatelessWidget {
  const EventRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Bone(width: 160, height: 14),
                    SizedBox(height: 8),
                    _Bone(width: 100, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventListSkeleton extends StatelessWidget {
  final int count;
  const EventListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => const EventRowSkeleton(),
    );
  }
}

/// Matches the shape of a blog post card (image + text block).
class BlogCardSkeleton extends StatelessWidget {
  const BlogCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 16 / 9, child: Container(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _Bone(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  _Bone(width: 140, height: 10),
                  SizedBox(height: 10),
                  _Bone(width: 80, height: 9),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlogGridSkeleton extends StatelessWidget {
  final int columns;
  final int count;
  const BlogGridSkeleton({super.key, this.columns = 1, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.3),
      itemCount: count,
      itemBuilder: (context, i) => const BlogCardSkeleton(),
    );
  }
}
