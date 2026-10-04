import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';
import 'package:foldable/foldable.dart';

/// Publishes the camera and status cluster of a closed iPhone Duo as cutouts
/// in [MediaQueryData.displayFeatures].
///
/// The `foldable` bridge publishes nothing while the device is closed, so
/// without this the strip of the cover display would not know where its
/// status cluster sits. Place it below a [FoldableProvider].
class ClosedFoldOcclusions extends StatefulWidget {
  /// Creates the adapter.
  const ClosedFoldOcclusions({super.key, required this.child});

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  State<ClosedFoldOcclusions> createState() => _ClosedFoldOcclusionsState();
}

class _ClosedFoldOcclusionsState extends State<ClosedFoldOcclusions> {
  (HingeStatus, List<ReservedRegion>, List<DisplayFeature>)? _featuresKey;
  var _features = const <DisplayFeature>[];

  /// MediaQuery tells its dependents about display features by identity, so
  /// the list is only rebuilt when its inputs change.
  List<DisplayFeature> _getFeatures(
    HingeStatus status,
    List<ReservedRegion> regions,
    List<DisplayFeature> ambient,
  ) {
    final key = (status, regions, ambient);
    if (key != _featuresKey) {
      _featuresKey = key;
      _features = switch (status) {
        HingeStatus.closed => List.unmodifiable([
          ...ambient,
          ...regions
              .where(
                (region) =>
                    region.kind == ReservedRegionKind.occlusion &&
                    region.isActive &&
                    !region.bounds.isEmpty,
              )
              .map(
                (region) => DisplayFeature(
                  bounds: region.bounds,
                  type: DisplayFeatureType.cutout,
                  state: DisplayFeatureState.unknown,
                ),
              ),
        ]),
        _ => ambient,
      };
    }

    return _features;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final features = _getFeatures(
      DuoMediaQuery.statusOf(context),
      DuoMediaQuery.regionsOf(context),
      mediaQuery.displayFeatures,
    );

    // Always the same MediaQuery, so that folding keeps the state below.
    return MediaQuery(
      data: mediaQuery.copyWith(displayFeatures: features),
      child: widget.child,
    );
  }
}
