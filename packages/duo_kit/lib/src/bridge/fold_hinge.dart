import 'package:flutter/foundation.dart';

/// How far a hinge is open, as the system reports it.
enum FoldHingeStatus {
  /// The system does not know yet.
  unknown,

  /// The device is closed.
  closed,

  /// The device is partly open, like a book or a laptop.
  partiallyOpen,

  /// The device is open as far as it goes.
  fullyOpen,
}

/// The state of the hinge of a foldable device.
@immutable
class FoldHinge {
  /// Creates a hinge state.
  const FoldHinge({required this.status, required this.angle});

  /// How far the hinge is open.
  ///
  /// Prefer it to [angle] for layout decisions.
  final FoldHingeStatus status;

  /// The angle of the hinge, in radians.
  ///
  /// The system decides how often and how precisely it updates the angle, so
  /// do not depend on a particular rate or precision.
  final double angle;

  @override
  bool operator ==(Object other) =>
      other is FoldHinge && other.status == status && other.angle == angle;

  @override
  int get hashCode => Object.hash(status, angle);

  @override
  String toString() => 'FoldHinge(${status.name}, $angle)';
}
