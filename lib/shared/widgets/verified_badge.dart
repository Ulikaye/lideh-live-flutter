import 'package:flutter/material.dart';

/// The blue checkmark trust signal — shown next to a musician's name
/// wherever it appears (card, profile, admin list) once an admin has
/// verified their account. This is the actual visible payoff of the
/// verification gate: an organizer browsing the directory sees proof
/// a real person reviewed and approved this account, not just an
/// unverified claim.
class VerifiedBadge extends StatelessWidget {
  final double size;
  const VerifiedBadge({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Verified by LiDeH Live',
      child: Icon(Icons.verified_rounded, color: const Color(0xFF3897F0), size: size),
    );
  }
}
