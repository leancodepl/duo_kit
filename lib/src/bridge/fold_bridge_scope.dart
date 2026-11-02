import 'package:duo_kit/src/bridge/fold_bridge.dart';
import 'package:duo_kit/src/bridge/fold_hinge.dart';
import 'package:duo_kit/src/bridge/fold_vertical_bar_edge.dart';
import 'package:duo_kit/src/geometry/fold_geometry.dart';
import 'package:flutter/widgets.dart';

/// The parts of a [FoldBridgeScope] a widget can depend on.
enum FoldBridgeAspect {
  /// [FoldBridgeScope.hinge].
  hinge,

  /// [FoldBridgeScope.verticalBarEdge].
  verticalBarEdge,
}

/// The state of a [FoldBridge], for [FoldHinge.maybeOf] and [FoldGeometry.of].
class FoldBridgeScope extends InheritedModel<FoldBridgeAspect> {
  /// Creates the scope.
  const FoldBridgeScope({
    super.key,
    required this.hinge,
    required this.verticalBarEdge,
    required super.child,
  });

  /// See [FoldHinge.maybeOf].
  static FoldHinge? maybeHingeOf(BuildContext context) =>
      InheritedModel.inheritFrom<FoldBridgeScope>(
        context,
        aspect: FoldBridgeAspect.hinge,
      )?.hinge;

  /// See [FoldGeometry.verticalBarEdge].
  static FoldVerticalBarEdge verticalBarEdgeOf(BuildContext context) =>
      InheritedModel.inheritFrom<FoldBridgeScope>(
        context,
        aspect: FoldBridgeAspect.verticalBarEdge,
      )?.verticalBarEdge ??
      FoldVerticalBarEdge.unspecified;

  /// See [FoldHinge.maybeOf].
  final FoldHinge? hinge;

  /// See [FoldGeometry.verticalBarEdge].
  final FoldVerticalBarEdge verticalBarEdge;

  @override
  bool updateShouldNotify(FoldBridgeScope oldWidget) =>
      hinge != oldWidget.hinge || verticalBarEdge != oldWidget.verticalBarEdge;

  @override
  bool updateShouldNotifyDependent(
    FoldBridgeScope oldWidget,
    Set<FoldBridgeAspect> dependencies,
  ) =>
      (dependencies.contains(FoldBridgeAspect.hinge) &&
          hinge != oldWidget.hinge) ||
      (dependencies.contains(FoldBridgeAspect.verticalBarEdge) &&
          verticalBarEdge != oldWidget.verticalBarEdge);
}
