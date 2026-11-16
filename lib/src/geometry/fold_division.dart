import 'dart:ui' show DisplayFeatureState;

import 'package:flutter/widgets.dart';

/// A fold or hinge that splits the window in two.
@immutable
class FoldDivision {
  /// Creates a division.
  const FoldDivision({
    required this.bounds,
    required this.axis,
    required this.posture,
  });

  /// The area of the fold, in window coordinates.
  ///
  /// Has zero thickness for a fold without a physical gap, such as the one of
  /// a half open Android foldable.
  final Rect bounds;

  /// The direction the fold runs in.
  ///
  /// [Axis.vertical] for a fold from the top to the bottom edge of the window,
  /// with the halves side by side like the pages of a book.
  final Axis axis;

  /// The posture the system reports for the fold.
  final DisplayFeatureState posture;

  /// The direction the halves are laid out in, across the fold.
  Axis get paneAxis => flipAxis(axis);

  /// Whether the device is half open, like a book or a laptop.
  bool get isHalfOpened => posture == DisplayFeatureState.postureHalfOpened;

  @override
  bool operator ==(Object other) =>
      other is FoldDivision &&
      other.bounds == bounds &&
      other.axis == axis &&
      other.posture == posture;

  @override
  int get hashCode => Object.hash(bounds, axis, posture);

  @override
  String toString() => 'FoldDivision(${axis.name}, $bounds, ${posture.name})';
}
