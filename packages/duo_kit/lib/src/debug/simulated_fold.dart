import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';

/// The pose a [SimulatedFold] makes the window report, after iPhone Duo.
enum FoldSimulation {
  /// The window as the device reports it.
  off,

  /// A strip on the right with the status cluster at its top, as on the
  /// cover display or on the inner display lying flat in landscape.
  strip,

  /// The strip, and a fold from top to bottom with the device half open like
  /// a book.
  book,

  /// A fold from edge to edge across the middle with the device half open like
  /// a laptop.
  laptop,
}

/// Makes the window below report the pose from [simulation], on whatever
/// device it runs, so that fold layouts can be tried without folding one.
///
/// Only [MediaQueryData.viewPadding], [MediaQueryData.padding] and
/// [MediaQueryData.displayFeatures] change, computed from the real size of the
/// window: the fold lies in its middle and the strip along its right edge. The
/// simulated fold replaces any real fold or hinge; real cutouts stay.
///
/// The strip comes with no top inset, so content can slide under the status
/// bar of a device that has one. It is recognised as a strip only where
/// strips are looked for, which by default is iOS.
class SimulatedFold extends StatefulWidget {
  /// Creates a simulated fold.
  const SimulatedFold({
    super.key,
    required this.simulation,
    required this.child,
  });

  /// The pose to report.
  final FoldSimulation simulation;

  /// The widget below this widget in the tree.
  final Widget child;

  /// The width of the strip, as on iPhone Duo.
  static const stripWidth = 84.0;

  /// How far the status cluster reaches down the strip, as on the inner
  /// display of iPhone Duo in landscape.
  static const statusClusterHeight = 120.0;

  /// The thickness of the fold, as on iPhone Duo.
  static const foldThickness = 40.0;

  @override
  State<SimulatedFold> createState() => _SimulatedFoldState();
}

class _SimulatedFoldState extends State<SimulatedFold> {
  (FoldSimulation, Size, List<DisplayFeature>)? _featuresKey;
  var _features = const <DisplayFeature>[];

  /// MediaQuery tells its dependents about display features by identity, so
  /// the list is only rebuilt when the pose, the window or the real features
  /// change.
  List<DisplayFeature> _getFeatures(Size size, List<DisplayFeature> real) {
    final key = (widget.simulation, size, real);
    if (key != _featuresKey) {
      _featuresKey = key;
      _features = List.unmodifiable([
        ...real.where((feature) => feature.type == DisplayFeatureType.cutout),
        ..._buildFeatures(widget.simulation, size),
      ]);
    }

    return _features;
  }

  static Iterable<DisplayFeature> _buildFeatures(
    FoldSimulation simulation,
    Size size,
  ) sync* {
    final hasStrip =
        simulation == FoldSimulation.strip || simulation == FoldSimulation.book;
    if (hasStrip) {
      yield DisplayFeature(
        bounds: Rect.fromLTWH(
          size.width - SimulatedFold.stripWidth,
          0,
          SimulatedFold.stripWidth,
          SimulatedFold.statusClusterHeight,
        ),
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      );
    }

    final fold = switch (simulation) {
      FoldSimulation.book => Rect.fromLTWH(
        (size.width - SimulatedFold.foldThickness) / 2,
        0,
        SimulatedFold.foldThickness,
        size.height,
      ),
      FoldSimulation.laptop => Rect.fromLTWH(
        0,
        (size.height - SimulatedFold.foldThickness) / 2,
        size.width,
        SimulatedFold.foldThickness,
      ),
      FoldSimulation.off || FoldSimulation.strip => null,
    };
    if (fold != null) {
      yield DisplayFeature(
        bounds: fold,
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureHalfOpened,
      );
    }
  }

  static EdgeInsets _getPadding(FoldSimulation simulation, EdgeInsets real) =>
      switch (simulation) {
        FoldSimulation.strip || FoldSimulation.book => EdgeInsets.only(
          right: SimulatedFold.stripWidth,
          bottom: real.bottom,
        ),
        FoldSimulation.off || FoldSimulation.laptop => real,
      };

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    if (widget.simulation == FoldSimulation.off) {
      return MediaQuery(data: mediaQuery, child: widget.child);
    }

    return MediaQuery(
      data: mediaQuery.copyWith(
        padding: _getPadding(widget.simulation, mediaQuery.padding),
        viewPadding: _getPadding(widget.simulation, mediaQuery.viewPadding),
        displayFeatures: _getFeatures(
          mediaQuery.size,
          mediaQuery.displayFeatures,
        ),
      ),
      child: widget.child,
    );
  }
}
