import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/musician_provider.dart';

Future<void> showMusicianFilterSheet(BuildContext context, WidgetRef ref) {
  final current = ref.read(musicianFilterProvider);
  final locationController = TextEditingController(text: current.location ?? '');
  String? selectedSkill = current.skill;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      final skillsAsync = ref.watch(skillsProvider);
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter Musicians', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'City / Region', prefixIcon: Icon(Icons.location_on_outlined)),
                ),
                const SizedBox(height: 16),
                Text('Skill', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                skillsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (skills) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills.map((skill) {
                      final selected = selectedSkill == skill.name;
                      return ChoiceChip(
                        label: Text(skill.name),
                        selected: selected,
                        onSelected: (v) => setState(() => selectedSkill = v ? skill.name : null),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(musicianFilterProvider.notifier).state = const MusicianFilter();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(musicianFilterProvider.notifier).state = MusicianFilter(
                            location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                            skill: selectedSkill,
                          );
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
