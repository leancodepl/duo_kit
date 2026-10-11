import 'dart:math' as math;
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:duo_kit/src/geometry/fold_division.dart';
import 'package:duo_kit/src/geometry/fold_strip.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Where the system reserves room in the window: a side strip for its
/// controls, a fold that splits the window, and occlusions such as cameras.
///
/// Computed from [MediaQueryData.viewPadding] and
/// [MediaQueryData.displayFeatures] only. Android fills the display features
/// itself; on iOS something has to publish them, such as a bridge from a
/// plugin that reads the reserved regions of the window.
///
/// Holds raw geometry, without margins or sizes of any controls.
@immutable
class FoldGeometry {
  /// Creates geometry from already known parts.
  const FoldGeometry({
    required this.size,
    required this.viewPadding,
    this.strip,
    this.division,
    this.occlusions = const [],
  });

  /// Computes the geometry of the window described by [data].
  ///
  /// See [FoldGeometry.of] for `detectStrip` and `stripFallbackClearance`.
  factory FoldGeometry.fromMediaQuery(
    MediaQueryData data, {
    bool? detectStrip,
    double stripFallbackClearance = defaultStripFallbackClearance,
  }) => FoldGeometry._compute(
    size: data.size,
    viewPadding: data.viewPadding,
    displayFeatures: data.displayFeatures,
    detectStrip: detectStrip,
    stripFallbackClearance: stripFallbackClearance,
  );

  /// Computes the geometry of the window from the nearest [MediaQuery].
  ///
  /// Depends only on the size, view padding and display features of the
  /// [MediaQuery], so [context] does not rebuild when anything else in it
  /// changes.
  ///
  /// A [FoldStrip] is looked for only when [detectStrip] is true, which by
  /// default it is on iOS alone. The strip is recognised by an inset on one
  /// side only, with no inset at the top, and an Android phone in landscape
  /// can report the same insets for its camera cutout.
  ///
  /// [stripFallbackClearance] is used as [FoldStrip.topClearance] until an
  /// occlusion in the strip is reported.
  factory FoldGeometry.of(
    BuildContext context, {
    bool? detectStrip,
    double stripFallbackClearance = defaultStripFallbackClearance,
  }) => FoldGeometry._compute(
    size: MediaQuery.sizeOf(context),
    viewPadding: MediaQuery.viewPaddingOf(context),
    displayFeatures: MediaQuery.displayFeaturesOf(context),
    detectStrip: detectStrip,
    stripFallbackClearance: stripFallbackClearance,
  );

  factory FoldGeometry._compute({
    required Size size,
    required EdgeInsets viewPadding,
    required List<DisplayFeature> displayFeatures,
    required bool? detectStrip,
    required double stripFallbackClearance,
  }) {
    final window = Offset.zero & size;
    final occlusions = displayFeatures
        .where((feature) => feature.type == DisplayFeatureType.cutout)
        .map((feature) => feature.bounds)
        .where((bounds) => _isInside(bounds, window))
        .toList(growable: false);

    final effectiveDetectStrip =
        detectStrip ?? defaultTargetPlatform == TargetPlatform.iOS;
    final stripSide = effectiveDetectStrip
        ? _detectStripSide(viewPadding)
        : null;
    final strip = switch (stripSide) {
      final side? => _computeStrip(
        side: side,
        size: size,
        viewPadding: viewPadding,
        occlusions: occlusions,
        fallbackClearance: stripFallbackClearance,
      ),
      null => null,
    };

    final division = displayFeatures
        .map((feature) => _toDivision(feature, window))
        .nonNulls
        .firstOrNull;

    return FoldGeometry(
      size: size,
      viewPadding: viewPadding,
      strip: strip,
      division: division,
      occlusions: occlusions,
    );
  }

  /// The default [FoldStrip.topClearance] used until the system reports the
  /// occlusions in a strip.
  ///
  /// The status cluster of the iPhone Duo cover display reaches this far down
  /// from the top of the window.
  static const defaultStripFallbackClearance = 170.0;

  /// How far outside the window an occlusion may reach and still count.
  ///
  /// Right after the device folds, unfolds or rotates, a reading taken in the
  /// previous pose can linger for a moment. Its bounds lie outside the window.
  static const _occlusionBoundsTolerance = 1.0;

  /// The size of the window.
  final Size size;

  /// The view padding of the window, which [SafeArea]s further up the tree do
  /// not consume.
  final EdgeInsets viewPadding;

  /// The strip the system keeps for its controls, if the window has one.
  final FoldStrip? strip;

  /// The fold or hinge that splits the window, if any.
  final FoldDivision? division;

  /// Areas of the window the hardware covers, such as cameras and the status
  /// cluster, in window coordinates.
  final List<Rect> occlusions;

  /// The width of the window without the side view padding.
  ///
  /// Decide between one and two panes by this, so the strip does not count as
  /// room for content.
  double get availableWidth => size.width - viewPadding.horizontal;

  static bool _isInside(Rect bounds, Rect window) {
    final area = window.inflate(_occlusionBoundsTolerance);

    return area.contains(bounds.topLeft) && area.contains(bounds.bottomRight);
  }

  /// iPhone Duo reports its strip as an inset on one side with none at the
  /// top. Other iPhones have a top inset in portrait and equal side insets in
  /// landscape, and iPads have no side inset.
  static FoldStripSide? _detectStripSide(EdgeInsets viewPadding) =>
      switch (viewPadding) {
        EdgeInsets(top: != 0.0) => null,
        EdgeInsets(left: 0.0, right: > 0.0) => FoldStripSide.right,
        EdgeInsets(left: > 0.0, right: 0.0) => FoldStripSide.left,
        _ => null,
      };

  static FoldStrip _computeStrip({
    required FoldStripSide side,
    required Size size,
    required EdgeInsets viewPadding,
    required List<Rect> occlusions,
    required double fallbackClearance,
  }) {
    final rect = switch (side) {
      FoldStripSide.left => Rect.fromLTWH(0, 0, viewPadding.left, size.height),
      FoldStripSide.right => Rect.fromLTWH(
        size.width - viewPadding.right,
        0,
        viewPadding.right,
        size.height,
      ),
    };
    final inStrip = occlusions.where((occlusion) => occlusion.overlaps(rect));
    final middle = size.height / 2;

    final topClearance = inStrip
        .where((occlusion) => occlusion.center.dy < middle)
        .map((occlusion) => occlusion.bottom)
        .fold<double>(0, math.max);
    final bottomClearance = inStrip
        .where((occlusion) => occlusion.center.dy >= middle)
        .map((occlusion) => size.height - occlusion.top)
        .fold<double>(0, math.max);
    final isClearanceEstimated = inStrip.isEmpty;

    return FoldStrip(
      side: side,
      rect: rect,
      topClearance: isClearanceEstimated ? fallbackClearance : topClearance,
      bottomClearance: bottomClearance,
      isClearanceEstimated: isClearanceEstimated,
    );
  }

  /// Uses the rule Flutter's [DisplayFeatureSubScreen] splits dialogs by: the
  /// fold takes up room or the device is half open, and the fold crosses the
  /// whole window with room on both of its sides.
  ///
  /// In Split View on iPhone Duo the fold can lie at an edge of the window,
  /// with room on one side only, and then splits nothing.
  static FoldDivision? _toDivision(DisplayFeature feature, Rect window) {
    final bounds = feature.bounds;
    final isFold =
        feature.type == DisplayFeatureType.fold ||
        feature.type == DisplayFeatureType.hinge;
    final isObstructing =
        bounds.shortestSide > 0 ||
        feature.state == DisplayFeatureState.postureHalfOpened;
    if (!isFold || !isObstructing) {
      return null;
    }

    final splitsSideBySide =
        bounds.top <= window.top &&
        bounds.bottom >= window.bottom &&
        bounds.left > window.left &&
        bounds.right < window.right;
    final splitsAboveAndBelow =
        bounds.left <= window.left &&
        bounds.right >= window.right &&
        bounds.top > window.top &&
        bounds.bottom < window.bottom;

    final axis = switch ((splitsSideBySide, splitsAboveAndBelow)) {
      (true, _) => Axis.vertical,
      (_, true) => Axis.horizontal,
      _ => null,
    };

    return switch (axis) {
      final axis? => FoldDivision(
        bounds: bounds,
        axis: axis,
        posture: feature.state,
      ),
      null => null,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is FoldGeometry &&
      other.size == size &&
      other.viewPadding == viewPadding &&
      other.strip == strip &&
      other.division == division &&
      listEquals(other.occlusions, occlusions);

  @override
  int get hashCode => Object.hash(
    size,
    viewPadding,
    strip,
    division,
    Object.hashAll(occlusions),
  );

  @override
  String toString() =>
      'FoldGeometry($size, viewPadding: $viewPadding, strip: $strip, '
      'division: $division, occlusions: $occlusions)';
}
