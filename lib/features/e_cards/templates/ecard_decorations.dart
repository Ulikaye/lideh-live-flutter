import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared decorative painters used to give each occasion's e-card a
/// distinct, colorful personality — florals for weddings, a radiant
/// cross for worship services, a modern geometric accent for
/// conferences — without touching any card's data or layout logic.
/// These are purely visual and are consumed via the optional
/// `background` slot on [EcardCardShell].

/// One stylized flower bloom made of flat, hand-cut-paper style
/// petals radiating from a small center. Several of these, in
/// different sizes/colors/rotations, are composed into a corner
/// cluster by [WeddingFloralFrame].
class FloralBloomPainter extends CustomPainter {
  final List<Color> petalColors;
  final Color centerColor;
  final int petalCount;
  final double petalLength;
  final double petalWidth;
  final double rotation;

  FloralBloomPainter({
    required this.petalColors,
    this.centerColor = const Color(0xFF6B4A2B),
    this.petalCount = 6,
    this.petalLength = 0.88,
    this.petalWidth = 0.36,
    this.rotation = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final petalLen = radius * petalLength;
    final petalW = radius * petalWidth;

    for (int i = 0; i < petalCount; i++) {
      final angle = rotation + (2 * math.pi / petalCount) * i;
      final color = petalColors[i % petalColors.length];
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(petalW, -petalLen * 0.55, 0, -petalLen)
        ..quadraticBezierTo(-petalW, -petalLen * 0.55, 0, 0)
        ..close();
      canvas.drawPath(path, Paint()..color = color);

      final vein = Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(0, -3), Offset(0, -petalLen + 5), vein);
      canvas.restore();
    }

    canvas.drawCircle(center, radius * 0.17, Paint()..color = centerColor);
    final dot = Paint()..color = centerColor.withValues(alpha: 0.55);
    for (int i = 0; i < 5; i++) {
      final a = rotation + i * (2 * math.pi / 5);
      canvas.drawCircle(
        center + Offset(math.cos(a), math.sin(a)) * radius * 0.085,
        radius * 0.032,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FloralBloomPainter oldDelegate) => false;
}

/// A single leaf, curved left ([curve] = 1) or right ([curve] = -1).
class LeafPainter extends CustomPainter {
  final Color color;
  final double curve;
  LeafPainter({required this.color, this.curve = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, size.height)
      ..quadraticBezierTo(
        size.width * (0.5 + 0.55 * curve),
        size.height * 0.42,
        size.width * 0.5,
        0,
      )
      ..quadraticBezierTo(
        size.width * (0.5 - 0.55 * curve),
        size.height * 0.42,
        size.width * 0.5,
        size.height,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);

    final vein = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.92),
      Offset(size.width * 0.5, size.height * 0.12),
      vein,
    );
  }

  @override
  bool shouldRepaint(covariant LeafPainter oldDelegate) => false;
}

/// Colorful floral corner clusters for the wedding card — mirrored so
/// all four corners of the card read like a hand-painted invitation
/// border, in the spirit of a modern stationery design.
class WeddingFloralFrame extends StatelessWidget {
  final List<Color> palette;
  const WeddingFloralFrame({super.key, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: -18, left: -18, child: _corner(false, false, 0)),
        Positioned(top: -18, right: -18, child: _corner(true, false, 1)),
        Positioned(bottom: -18, left: -18, child: _corner(false, true, 2)),
        Positioned(bottom: -18, right: -18, child: _corner(true, true, 3)),
      ],
    );
  }

  Widget _corner(bool flipX, bool flipY, int seed) {
    final c1 = palette[seed % palette.length];
    final c2 = palette[(seed + 1) % palette.length];
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scale(flipX ? -1.0 : 1.0, flipY ? -1.0 : 1.0),
      child: SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 14,
              top: 6,
              child: Transform.rotate(
                angle: -0.35,
                child: SizedBox(
                  width: 20,
                  height: 46,
                  child: CustomPaint(
                    painter: LeafPainter(
                        color: const Color(0xFF3F6E5B).withValues(alpha: 0.55)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: SizedBox(
                width: 62,
                height: 62,
                child: CustomPaint(
                  painter: FloralBloomPainter(
                    petalColors: [c1],
                    rotation: seed * 0.5,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 42,
              top: 34,
              child: SizedBox(
                width: 38,
                height: 38,
                child: CustomPaint(
                  painter: FloralBloomPainter(
                    petalColors: [c2],
                    petalCount: 5,
                    rotation: 0.9 + seed,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A soft radiant cross for worship cards — a filled cross motif with
/// fine rays fanning out behind it, like early morning light.
class RadiantCrossPainter extends CustomPainter {
  final Color crossColor;
  final Color rayColor;
  RadiantCrossPainter({required this.crossColor, required this.rayColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rayPaint = Paint()
      ..color = rayColor
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 16; i++) {
      final a = (2 * math.pi / 16) * i;
      final inner = size.shortestSide * 0.30;
      final outer = size.shortestSide * 0.5;
      canvas.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * inner,
        center + Offset(math.cos(a), math.sin(a)) * outer,
        rayPaint,
      );
    }

    final crossPaint = Paint()..color = crossColor;
    final w = size.width * 0.16;
    final vH = size.height * 0.62;
    final hW = size.width * 0.40;
    final hH = size.height * 0.16;
    final vRect = Rect.fromCenter(
        center: center.translate(0, -size.height * 0.02), width: w, height: vH);
    final hRect = Rect.fromCenter(
        center: center.translate(0, -size.height * 0.10),
        width: hW,
        height: hH);
    canvas.drawRRect(
        RRect.fromRectAndRadius(vRect, Radius.circular(w * 0.35)), crossPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(hRect, Radius.circular(hH * 0.35)), crossPaint);
  }

  @override
  bool shouldRepaint(covariant RadiantCrossPainter oldDelegate) => false;
}

/// Soft laurel-leaf sprig, used in the lower corners of a worship
/// card for a quiet, ceremonial finish.
class LaurelSprig extends StatelessWidget {
  final Color color;
  final bool flip;
  const LaurelSprig({super.key, required this.color, this.flip = false});

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(flip ? -1.0 : 1.0, 1.0),
      child: SizedBox(
        width: 60,
        height: 70,
        child: Stack(
          children: List.generate(4, (i) {
            return Positioned(
              left: i * 10.0,
              top: 40 - i * 9.0,
              child: Transform.rotate(
                angle: -0.5 + i * 0.18,
                child: SizedBox(
                  width: 16,
                  height: 30,
                  child: CustomPaint(
                    painter: LeafPainter(color: color.withValues(alpha: 0.65)),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Modern geometric corner accent for the conference card — two
/// overlapping angled panels in the brand navy and gold, plus a
/// faint dot grid, like a premium event badge.
class ConferenceAccentPainter extends CustomPainter {
  final Color primary;
  final Color accent;
  ConferenceAccentPainter({required this.primary, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.62)
      ..lineTo(size.width * 0.38, 0)
      ..close();
    canvas.drawPath(p1, Paint()..color = primary.withValues(alpha: 0.10));

    final p2 = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.30)
      ..lineTo(size.width * 0.70, 0)
      ..close();
    canvas.drawPath(p2, Paint()..color = accent.withValues(alpha: 0.55));

    final dotPaint = Paint()..color = primary.withValues(alpha: 0.18);
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4 - row; col++) {
        canvas.drawCircle(
          Offset(size.width - 10 - col * 10.0, size.height - 10 - row * 10.0),
          1.6,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ConferenceAccentPainter oldDelegate) => false;
}
