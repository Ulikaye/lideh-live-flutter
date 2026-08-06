import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/responsive.dart';
import '../../providers/musician_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'widgets/musician_card.dart';
import 'widgets/filter_sheet.dart';

class MusicianListScreen extends ConsumerWidget {
  const MusicianListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musiciansAsync = ref.watch(musicianListProvider);
    final filter = ref.watch(musicianFilterProvider);
    final columns = Responsive.gridColumns(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Musicians'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => showMusicianFilterSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          if (filter.location != null || filter.skill != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (filter.location != null)
                    Chip(
                      label: Text('Location: ${filter.location}'),
                      onDeleted: () => ref.read(musicianFilterProvider.notifier).state = filter.copyWith(location: null),
                    ),
                  if (filter.skill != null)
                    Chip(
                      label: Text('Skill: ${filter.skill}'),
                      onDeleted: () => ref.read(musicianFilterProvider.notifier).state = filter.copyWith(skill: null),
                    ),
                ],
              ),
            ),
          Expanded(
            child: musiciansAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => AppErrorWidget(message: 'Failed to load musicians: $e'),
              data: (musicians) {
                if (musicians.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No musicians found',
                    subtitle: 'Try adjusting your filters',
                    icon: Icons.search_off_rounded,
                  );
                }
                return CenteredContent(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: columns == 1 ? 1.5 : 0.85,
                    ),
                    itemCount: musicians.length,
                    itemBuilder: (context, index) => MusicianCard(musician: musicians[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
