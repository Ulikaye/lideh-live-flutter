import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/booking.dart';
import '../../../models/review.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/star_rating.dart';

Future<void> showReviewModal(BuildContext context, WidgetRef ref, Booking booking) {
  int rating = 5;
  final commentController = TextEditingController();
  bool saving = false;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rate this musician', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Center(child: StarRatingInput(rating: rating, onChanged: (r) => setState(() => rating = r))),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Leave a comment (optional)', alignLabelWithHint: true),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setState(() => saving = true);
                          final review = Review(
                            id: booking.id,
                            bookingId: booking.id,
                            musicianId: booking.musicianId,
                            organizerId: booking.organizerId,
                            rating: rating,
                            comment: commentController.text.trim().isEmpty ? null : commentController.text.trim(),
                          );
                          await ref.read(firestoreServiceProvider).submitReview(review);
                          if (context.mounted) Navigator.pop(context);
                        },
                  child: saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Review'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
