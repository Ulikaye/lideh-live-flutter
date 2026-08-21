import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/musician_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/skeleton_loaders.dart';
import '../../musicians/widgets/musician_card.dart';

class FeaturedMusicians extends ConsumerWidget {
  const FeaturedMusicians({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musiciansAsync = ref.watch(featuredMusiciansProvider);

    return musiciansAsync.when(
      loading: () => SizedBox(
        height: 260,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) =>
              const SizedBox(width: 280, child: MusicianCardSkeleton()),
        ),
      ),
      error: (e, _) =>
          AppErrorWidget(message: 'Could not load featured musicians'),
      data: (musicians) {
        // ✅ Extra safety: filter out unverified musicians
        final filtered = musicians.where((m) => m.verified).toList();
        if (filtered.isEmpty) {
          return const EmptyStateWidget(
              title: 'No musicians yet', subtitle: 'Check back soon!');
        }
        return SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) => SizedBox(
                width: 280, child: MusicianCard(musician: filtered[index])),
          ),
        );
      },
    );
  }
}
