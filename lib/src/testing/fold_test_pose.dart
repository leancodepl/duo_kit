import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';

const _coverWidth = 466.0;
const _coverHeight = 678.0;
const _innerLongSide = 951.0;
const _innerShortSide = 669.0;

const _stripWidth = 84.0;
const _homeIndicatorHeight = 34.0;
const _innerPortraitTopInset = 82.0;
const _coverStatusClusterHeight = 170.0;
const _innerLandscapeStatusClusterHeight = 120.0;
const _innerPortraitStatusClusterWidth = 134.0;
const _foldThickness = 40.0;

/// Where the fold starts, measured from the top or left edge of the inner
/// display.
const _foldOffset = 455.5;

const _coverSize = Size(_coverWidth, _coverHeight);
const _innerLandscapeSize = Size(_innerLongSide, _innerShortSide);
const _innerPortraitSize = Size(_innerShortSide, _innerLongSide);

const _rightStripPadding = EdgeInsets.only(
  right: _stripWidth,
  bottom: _homeIndicatorHeight,
);
const _innerPortraitPadding = EdgeInsets.only(
  top: _innerPortraitTopInset,
  bottom: _homeIndicatorHeight,
);

const _coverCamera = DisplayFeature(
  bounds: Rect.fromLTRB(399.7, 29.3, 436.7, 66.3),
  type: DisplayFeatureType.cutout,
  state: DisplayFeatureState.unknown,
);
const _coverStatusCluster = DisplayFeature(
  bounds: Rect.fromLTRB(
    _coverWidth - _stripWidth,
    0,
    _coverWidth,
    _coverStatusClusterHeight,
  ),
  type: DisplayFeatureType.cutout,
  state: DisplayFeatureState.unknown,
);
const _innerLandscapeStatusCluster = DisplayFeature(
  bounds: Rect.fromLTRB(
    _innerLongSide - _stripWidth,
    0,
    _innerLongSide,
    _innerLandscapeStatusClusterHeight,
  ),
  type: DisplayFeatureType.cutout,
  state: DisplayFeatureState.unknown,
);
const _innerPortraitStatusCluster = DisplayFeature(
  bounds: Rect.fromLTRB(
    _innerShortSide - _innerPortraitStatusClusterWidth,
    0,
    _innerShortSide,
    _innerPortraitTopInset,
  ),
  type: DisplayFeatureType.cutout,
  state: DisplayFeatureState.unknown,
);
const _landscapeFold = DisplayFeature(
  bounds: Rect.fromLTWH(_foldOffset, 0, _foldThickness, _innerShortSide),
  type: DisplayFeatureType.fold,
  state: DisplayFeatureState.postureHalfOpened,
);
const _portraitFold = DisplayFeature(
  bounds: Rect.fromLTWH(0, _foldOffset, _innerShortSide, _foldThickness),
  type: DisplayFeatureType.fold,
  state: DisplayFeatureState.postureHalfOpened,
);

/// Window metrics of iPhone Duo poses, for widget and golden tests.
///
/// Measured on the iPhone Duo simulator (iOS 27.1). The fold and the
/// occlusions appear in [MediaQueryData.displayFeatures] as a bridge
/// publishing the reserved regions of the window puts them there: occlusions
/// as cutouts, and the fold only while the device is half open.
///
/// The inner display has one landscape pose: in both landscape rotations the
/// system keeps the strip and the status cluster on the right.
enum FoldTestPose {
  /// The cover display of the closed device, with no display features.
  ///
  /// The bridge publishes nothing while the device is closed.
  duoCover(
    MediaQueryData(
      size: _coverSize,
      padding: _rightStripPadding,
      viewPadding: _rightStripPadding,
    ),
  ),

  /// The cover display with its camera and status cluster published as
  /// cutouts.
  duoCoverWithOcclusions(
    MediaQueryData(
      size: _coverSize,
      padding: _rightStripPadding,
      viewPadding: _rightStripPadding,
      displayFeatures: [_coverCamera, _coverStatusCluster],
    ),
  ),

  /// The inner display in landscape, lying flat, with the strip on the right.
  duoInnerLandscape(
    MediaQueryData(
      size: _innerLandscapeSize,
      padding: _rightStripPadding,
      viewPadding: _rightStripPadding,
      displayFeatures: [_innerLandscapeStatusCluster],
    ),
  ),

  /// The inner display in portrait, lying flat, with the status cluster in
  /// the top right corner.
  duoInnerPortrait(
    MediaQueryData(
      size: _innerPortraitSize,
      padding: _innerPortraitPadding,
      viewPadding: _innerPortraitPadding,
      displayFeatures: [_innerPortraitStatusCluster],
    ),
  ),

  /// The inner display in landscape, half open like a book.
  duoHalfOpenedLandscape(
    MediaQueryData(
      size: _innerLandscapeSize,
      padding: _rightStripPadding,
      viewPadding: _rightStripPadding,
      displayFeatures: [_innerLandscapeStatusCluster, _landscapeFold],
    ),
  ),

  /// The inner display in portrait, half open like a laptop.
  duoHalfOpenedPortrait(
    MediaQueryData(
      size: _innerPortraitSize,
      padding: _innerPortraitPadding,
      viewPadding: _innerPortraitPadding,
      displayFeatures: [_innerPortraitStatusCluster, _portraitFold],
    ),
  );

  const FoldTestPose(this.data);

  /// The window metrics of this pose.
  final MediaQueryData data;
}
