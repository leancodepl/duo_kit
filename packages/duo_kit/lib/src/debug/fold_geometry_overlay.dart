import 'package:duo_kit/src/geometry/fold_geometry.dart';
import 'package:flutter/widgets.dart';

/// Paints the [FoldGeometry] of the window over [child]: the strip and the
/// part of it free of occlusions in blue, occlusions in orange and the fold in
/// red.
///
/// For development only. Place it where it covers the whole window, since the
/// geometry is in window coordinates. It lets every touch through.
class FoldGeometryOverlay extends StatelessWidget {
  /// Creates an overlay.
  const FoldGeometryOverlay({
    super.key,
    this.enabled = true,
    required this.child,
  });

  /// Whether to paint the geometry.
  final bool enabled;

  /// The widget below the overlay.
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: enabled
        ? _FoldGeometryPainter(FoldGeometry.of(context))
        : null,
    child: child,
  );
}

class _FoldGeometryPainter extends CustomPainter {
  _FoldGeometryPainter(this.geometry);

  final FoldGeometry geometry;

  static const _stripColor = Color(0x332196F3);
  static const _freeStripColor = Color(0xFF2196F3);
  static const _occlusionColor = Color(0x66FF9800);
  static const _divisionColor = Color(0x66F44336);
  static const _outlineWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint();
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _outlineWidth;

    if (geometry.strip case final strip?) {
      canvas
        ..drawRect(strip.rect, fill..color = _stripColor)
        ..drawRect(strip.freeRect, outline..color = _freeStripColor);
    }

    for (final occlusion in geometry.occlusions) {
      canvas.drawRect(occlusion, fill..color = _occlusionColor);
    }

    if (geometry.division case final division?) {
      canvas.drawRect(division.bounds, fill..color = _divisionColor);
    }
  }

  @override
  bool shouldRepaint(_FoldGeometryPainter oldDelegate) =>
      oldDelegate.geometry != geometry;
}
