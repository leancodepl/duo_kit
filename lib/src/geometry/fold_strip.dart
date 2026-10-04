import 'package:flutter/widgets.dart';

/// The side edge of the window a [FoldStrip] runs along.
enum FoldStripSide {
  /// Along the left edge of the window.
  left,

  /// Along the right edge of the window.
  right,
}

/// A strip along a side edge of the window that the system keeps for its own
/// controls, like the one iPhone Duo has beside its status cluster.
///
/// On iPhone Duo the strip stays aligned with the hardware: on the right in
/// both landscape rotations and in right-to-left languages, and on the left
/// only for the app on the left of Split View.
///
/// The strip spans the full height of the window. [topClearance] and
/// [bottomClearance] mark the parts of it covered by occlusions such as the
/// camera and the status cluster.
@immutable
class FoldStrip {
  /// Creates a strip.
  const FoldStrip({
    required this.side,
    required this.rect,
    required this.topClearance,
    required this.bottomClearance,
    required this.isClearanceEstimated,
  });

  /// The edge the strip runs along.
  final FoldStripSide side;

  /// The strip, in window coordinates.
  final Rect rect;

  /// How far occlusions reach down from the top of the strip.
  final double topClearance;

  /// How far occlusions reach up from the bottom of the strip.
  final double bottomClearance;

  /// Whether no occlusion in the strip has been reported yet, so
  /// [topClearance] is a fallback.
  ///
  /// On iPhone Duo every strip holds the camera or the status cluster, so an
  /// empty strip means the system has not reported them for this pose yet.
  final bool isClearanceEstimated;

  /// The width of the strip.
  double get width => rect.width;

  /// The part of the strip that no occlusion covers.
  ///
  /// The bottom view padding (home indicator) is not taken into account; it
  /// stays in [MediaQueryData.viewPadding].
  Rect get freeRect => Rect.fromLTRB(
    rect.left,
    rect.top + topClearance,
    rect.right,
    rect.bottom - bottomClearance,
  );

  @override
  bool operator ==(Object other) =>
      other is FoldStrip &&
      other.side == side &&
      other.rect == rect &&
      other.topClearance == topClearance &&
      other.bottomClearance == bottomClearance &&
      other.isClearanceEstimated == isClearanceEstimated;

  @override
  int get hashCode => Object.hash(
    side,
    rect,
    topClearance,
    bottomClearance,
    isClearanceEstimated,
  );

  @override
  String toString() =>
      'FoldStrip(${side.name}, $rect, top: $topClearance, '
      'bottom: $bottomClearance, estimated: $isClearanceEstimated)';
}
