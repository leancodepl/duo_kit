import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:duo_kit/duo_kit.dart';
import 'package:duo_kit/testing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoldGeometry.fromMediaQuery on iOS', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('puts the strip on the right of the cover display', () {
      final geometry = FoldGeometry.fromMediaQuery(FoldTestPose.duoCover.data);

      expect(
        geometry.strip,
        const FoldStrip(
          side: FoldStripSide.right,
          rect: Rect.fromLTWH(382, 0, 84, 678),
          topClearance: FoldGeometry.defaultStripFallbackClearance,
          bottomClearance: 0,
          isClearanceEstimated: true,
        ),
      );
      expect(geometry.division, isNull);
      expect(geometry.occlusions, isEmpty);
      expect(geometry.availableWidth, 382);
    });

    test('clears the status cluster once it is reported', () {
      final geometry = FoldGeometry.fromMediaQuery(
        FoldTestPose.duoCoverWithOcclusions.data,
      );

      expect(geometry.strip?.topClearance, 170);
      expect(geometry.strip?.bottomClearance, 0);
      expect(geometry.strip?.isClearanceEstimated, isFalse);
      expect(geometry.strip?.freeRect, const Rect.fromLTRB(382, 170, 466, 678));
      expect(geometry.occlusions, hasLength(2));
    });

    test('clears an occlusion at the bottom of the strip', () {
      final geometry = FoldGeometry.fromMediaQuery(
        _withCutouts(FoldTestPose.duoInnerLandscape.data, const [
          Rect.fromLTWH(867, 500, 84, 169),
        ]),
      );

      expect(geometry.strip?.topClearance, 0);
      expect(geometry.strip?.bottomClearance, 169);
      expect(geometry.strip?.isClearanceEstimated, isFalse);
    });

    test('keeps the fallback while occlusions lie outside the strip', () {
      final geometry = FoldGeometry.fromMediaQuery(
        _withCutouts(FoldTestPose.duoInnerLandscape.data, const [
          Rect.fromLTWH(400, 20, 37, 37),
        ]),
      );

      expect(geometry.occlusions, hasLength(1));
      expect(
        geometry.strip?.topClearance,
        FoldGeometry.defaultStripFallbackClearance,
      );
      expect(geometry.strip?.isClearanceEstimated, isTrue);
    });

    test('drops an occlusion left over from the previous pose', () {
      final geometry = FoldGeometry.fromMediaQuery(
        _withCutouts(FoldTestPose.duoCover.data, const [
          Rect.fromLTWH(867, 0, 84, 170),
        ]),
      );

      expect(geometry.occlusions, isEmpty);
      expect(geometry.strip?.isClearanceEstimated, isTrue);
    });

    test('puts the strip on the right of the inner display in landscape', () {
      final geometry = FoldGeometry.fromMediaQuery(
        FoldTestPose.duoInnerLandscape.data,
      );

      expect(geometry.strip?.rect, const Rect.fromLTWH(867, 0, 84, 669));
      expect(geometry.strip?.topClearance, 120);
      expect(geometry.strip?.isClearanceEstimated, isFalse);
      expect(geometry.division, isNull);
      expect(geometry.availableWidth, 867);
    });

    test('puts the strip on the left for an inset on the left only', () {
      final geometry = FoldGeometry.fromMediaQuery(_leftStripData);

      expect(geometry.strip?.side, FoldStripSide.left);
      expect(geometry.strip?.rect, const Rect.fromLTWH(0, 0, 84, 669));
      expect(geometry.availableWidth, 867);
    });

    test('finds no strip with insets on both sides', () {
      final geometry = FoldGeometry.fromMediaQuery(
        _leftStripData.copyWith(
          viewPadding: const EdgeInsets.only(left: 84, right: 84, bottom: 34),
        ),
      );

      expect(geometry.strip, isNull);
    });

    test('keeps bars horizontal on the inner display in portrait', () {
      final geometry = FoldGeometry.fromMediaQuery(
        FoldTestPose.duoInnerPortrait.data,
      );

      expect(geometry.strip, isNull);
      expect(geometry.division, isNull);
      expect(geometry.availableWidth, 669);
    });

    test('splits the landscape inner display half open like a book', () {
      final geometry = FoldGeometry.fromMediaQuery(
        FoldTestPose.duoHalfOpenedLandscape.data,
      );

      expect(
        geometry.division,
        const FoldDivision(
          bounds: Rect.fromLTWH(455.5, 0, 40, 669),
          axis: Axis.vertical,
          posture: DisplayFeatureState.postureHalfOpened,
        ),
      );
      expect(geometry.division?.paneAxis, Axis.horizontal);
      expect(geometry.division?.isHalfOpened, isTrue);
      expect(geometry.strip?.rect, const Rect.fromLTWH(867, 0, 84, 669));
    });

    test('splits the portrait inner display half open like a laptop', () {
      final geometry = FoldGeometry.fromMediaQuery(
        FoldTestPose.duoHalfOpenedPortrait.data,
      );

      expect(geometry.division?.axis, Axis.horizontal);
      expect(geometry.division?.paneAxis, Axis.vertical);
      expect(geometry.strip, isNull);
    });

    test('does not split at a fold on the edge of a Split View window', () {
      // The window of the app on the left of Split View, measured half open,
      // and the one on the right, with the fold where the bridge reports it.
      const window = Size(469, 669);
      final left = FoldGeometry.fromMediaQuery(
        _withFeature(
          window,
          const Rect.fromLTRB(455.5, 0, 469, 669),
          DisplayFeatureType.fold,
          DisplayFeatureState.postureHalfOpened,
        ),
      );
      final right = FoldGeometry.fromMediaQuery(
        _withFeature(
          window,
          const Rect.fromLTRB(0, 0, 13.5, 669),
          DisplayFeatureType.fold,
          DisplayFeatureState.postureHalfOpened,
        ),
      );

      expect(left.division, isNull);
      expect(right.division, isNull);
    });

    test('finds no strip on other iPhones and iPads', () {
      const poses = [
        // iPhone in portrait.
        MediaQueryData(
          size: Size(393, 852),
          viewPadding: EdgeInsets.only(top: 59, bottom: 34),
        ),
        // iPhone in landscape.
        MediaQueryData(
          size: Size(852, 393),
          viewPadding: EdgeInsets.only(left: 59, right: 59, bottom: 21),
        ),
        // iPad mini.
        MediaQueryData(
          size: Size(744, 1133),
          viewPadding: EdgeInsets.only(top: 24, bottom: 20),
        ),
      ];

      expect(
        poses.map((pose) => FoldGeometry.fromMediaQuery(pose).strip),
        everyElement(isNull),
      );
    });
  });

  group('FoldGeometry.fromMediaQuery on Android', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    const landscapeWithCutout = MediaQueryData(
      size: Size(915, 412),
      viewPadding: EdgeInsets.only(left: 32),
    );

    test('finds no strip by default', () {
      final geometry = FoldGeometry.fromMediaQuery(landscapeWithCutout);

      expect(geometry.strip, isNull);
      expect(geometry.availableWidth, 883);
    });

    test('finds the strip when asked to', () {
      final geometry = FoldGeometry.fromMediaQuery(
        FoldTestPose.duoCover.data,
        detectStrip: true,
      );

      expect(geometry.strip?.rect, const Rect.fromLTWH(382, 0, 84, 678));
    });

    test('splits at a seamless fold only while half open', () {
      const window = Size(840, 900);
      const fold = Rect.fromLTRB(420, 0, 420, 900);

      final flat = FoldGeometry.fromMediaQuery(
        _withFeature(
          window,
          fold,
          DisplayFeatureType.fold,
          DisplayFeatureState.postureFlat,
        ),
      );
      final halfOpened = FoldGeometry.fromMediaQuery(
        _withFeature(
          window,
          fold,
          DisplayFeatureType.fold,
          DisplayFeatureState.postureHalfOpened,
        ),
      );

      expect(flat.division, isNull);
      expect(halfOpened.division?.axis, Axis.vertical);
    });

    test('splits at a hinge with a gap while flat', () {
      final geometry = FoldGeometry.fromMediaQuery(
        _withFeature(
          const Size(1114, 720),
          const Rect.fromLTWH(540, 0, 34, 720),
          DisplayFeatureType.hinge,
          DisplayFeatureState.postureFlat,
        ),
      );

      expect(geometry.division?.axis, Axis.vertical);
      expect(geometry.division?.isHalfOpened, isFalse);
    });

    test('does not split at a fold that stops short of the edges', () {
      final geometry = FoldGeometry.fromMediaQuery(
        _withFeature(
          const Size(840, 900),
          const Rect.fromLTWH(400, 100, 40, 700),
          DisplayFeatureType.fold,
          DisplayFeatureState.postureHalfOpened,
        ),
      );

      expect(geometry.division, isNull);
    });

    test('does not split at a cutout across the window', () {
      final geometry = FoldGeometry.fromMediaQuery(
        _withFeature(
          const Size(840, 900),
          const Rect.fromLTWH(400, 0, 40, 900),
          DisplayFeatureType.cutout,
          DisplayFeatureState.unknown,
        ),
      );

      expect(geometry.division, isNull);
      expect(geometry.occlusions, [const Rect.fromLTWH(400, 0, 40, 900)]);
    });
  });

  group('FoldGeometry.of', () {
    testWidgets(
      'computes the geometry of the nearest MediaQuery',
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      (tester) async {
        late FoldGeometry geometry;

        await tester.pumpWidget(
          MediaQuery(
            data: FoldTestPose.duoHalfOpenedLandscape.data,
            child: Builder(
              builder: (context) {
                geometry = FoldGeometry.of(context);

                return const SizedBox();
              },
            ),
          ),
        );

        expect(
          geometry,
          FoldGeometry.fromMediaQuery(FoldTestPose.duoHalfOpenedLandscape.data),
        );
      },
    );

    testWidgets('does not rebuild when unrelated metrics change', (
      tester,
    ) async {
      var builds = 0;
      final probe = Builder(
        builder: (context) {
          FoldGeometry.of(context);
          builds++;

          return const SizedBox();
        },
      );
      final data = FoldTestPose.duoInnerLandscape.data;

      await tester.pumpWidget(MediaQuery(data: data, child: probe));
      await tester.pumpWidget(
        MediaQuery(
          data: data.copyWith(textScaler: const TextScaler.linear(2)),
          child: probe,
        ),
      );

      expect(builds, 1);

      await tester.pumpWidget(
        MediaQuery(data: FoldTestPose.duoCover.data, child: probe),
      );

      expect(builds, 2);
    });
  });
}

/// A window with a strip on the left, as iPhone Duo gives the app on the left
/// of Split View. Not measured.
const _leftStripData = MediaQueryData(
  size: Size(951, 669),
  viewPadding: EdgeInsets.only(left: 84, bottom: 34),
);

MediaQueryData _withCutouts(MediaQueryData data, List<Rect> cutouts) =>
    data.copyWith(
      displayFeatures: cutouts
          .map(
            (bounds) => DisplayFeature(
              bounds: bounds,
              type: DisplayFeatureType.cutout,
              state: DisplayFeatureState.unknown,
            ),
          )
          .toList(),
    );

MediaQueryData _withFeature(
  Size size,
  Rect bounds,
  DisplayFeatureType type,
  DisplayFeatureState state,
) => MediaQueryData(
  size: size,
  displayFeatures: [DisplayFeature(bounds: bounds, type: type, state: state)],
);
