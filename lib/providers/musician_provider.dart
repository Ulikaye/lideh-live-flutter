import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/musician.dart';
import 'auth_provider.dart';

class MusicianFilter {
  final String? location;
  final String? skill;
  const MusicianFilter({this.location, this.skill});

  MusicianFilter copyWith({String? location, String? skill}) {
    return MusicianFilter(location: location ?? this.location, skill: skill ?? this.skill);
  }
}

final musicianFilterProvider = StateProvider<MusicianFilter>((ref) => const MusicianFilter());

final musicianListProvider = StreamProvider<List<Musician>>((ref) {
  final filter = ref.watch(musicianFilterProvider);
  return ref.watch(firestoreServiceProvider).watchMusicians(location: filter.location, skill: filter.skill);
});

final featuredMusiciansProvider = StreamProvider<List<Musician>>((ref) {
  return ref.watch(firestoreServiceProvider).watchFeaturedMusicians();
});

final musicianByIdProvider = StreamProvider.family<Musician?, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).watchMusician(uid);
});

final skillsProvider = StreamProvider((ref) {
  return ref.watch(firestoreServiceProvider).watchSkills();
});
