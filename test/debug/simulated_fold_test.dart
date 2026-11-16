import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:duo_kit/debug.dart';
import 'package:duo_kit/duo_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// An iPhone in landscape, which has no fold and no strip.
const _window = MediaQueryData(
  size: Size(800, 600),
  padding: EdgeInsets.only(top: 24, bottom: 34),
  viewPadding: EdgeInsets.only(top: 24, bottom: 34),
);

final _ios = TargetPlatformVariant.only(TargetPlatform.iOS);

void main() {
  testWidgets(
    'makes the window half open like a book, with a strip',
    variant: _ios,
    (tester) async {
      final context = await _pumpSimulation(tester, FoldSimulation.book);
      final geometry = FoldGeometry.of(context);

      expect(geometry.strip?.rect, const Rect.fromLTWH(716, 0, 84, 600));
      expect(geometry.strip?.topClearance, SimulatedFold.statusClusterHeight);
      expect(geometry.strip?.isClearanceEstimated, isFalse);
      expect(geometry.division?.axis, Axis.vertical);
      expect(geometry.division?.bounds, const Rect.fromLTWH(380, 0, 40, 600));
      expect(geometry.division?.isHalfOpened, isTrue);
    },
  );

  testWidgets('makes the window half open like a laptop', variant: _ios, (
    tester,
  ) async {
    final context = await _pumpSimulation(tester, FoldSimulation.laptop);
    final geometry = FoldGeometry.of(context);

    expect(geometry.strip, isNull);
    expect(geometry.division?.axis, Axis.horizontal);
    expect(geometry.division?.bounds, const Rect.fromLTWH(0, 280, 800, 40));
  });

  testWidgets('keeps the bottom inset and drops the top one for a strip', (
    tester,
  ) async {
    final context = await _pumpSimulation(tester, FoldSimulation.strip);

    expect(
      MediaQuery.viewPaddingOf(context),
      const EdgeInsets.only(right: 84, bottom: 34),
    );
    expect(
      MediaQuery.paddingOf(context),
      const EdgeInsets.only(right: 84, bottom: 34),
    );
  });

  testWidgets('leaves the window as it is while off', (tester) async {
    final context = await _pumpSimulation(tester, FoldSimulation.off);

    expect(MediaQuery.of(context), _window);
  });

  testWidgets('replaces a real fold and keeps real cutouts', (tester) async {
    const camera = DisplayFeature(
      bounds: Rect.fromLTWH(380, 0, 40, 24),
      type: DisplayFeatureType.cutout,
      state: DisplayFeatureState.unknown,
    );
    const realFold = DisplayFeature(
      bounds: Rect.fromLTWH(0, 280, 800, 40),
      type: DisplayFeatureType.fold,
      state: DisplayFeatureState.postureHalfOpened,
    );

    final context = await _pumpSimulation(
      tester,
      FoldSimulation.book,
      window: _window.copyWith(displayFeatures: [camera, realFold]),
    );
    final features = MediaQuery.displayFeaturesOf(context);

    expect(features, contains(camera));
    expect(features, isNot(contains(realFold)));
    expect(
      features.where((feature) => feature.type == DisplayFeatureType.fold),
      hasLength(1),
    );
  });

  testWidgets('keeps the same display features while the pose holds', (
    tester,
  ) async {
    final context = await _pumpSimulation(tester, FoldSimulation.book);
    final features = MediaQuery.displayFeaturesOf(context);

    await _pumpSimulation(
      tester,
      FoldSimulation.book,
      window: _window.copyWith(textScaler: const TextScaler.linear(2)),
    );

    expect(MediaQuery.displayFeaturesOf(context), same(features));
  });
}

Future<BuildContext> _pumpSimulation(
  WidgetTester tester,
  FoldSimulation simulation, {
  MediaQueryData window = _window,
}) async {
  tester.view
    ..physicalSize = window.size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  const probeKey = ValueKey('probe');

  await tester.pumpWidget(
    MediaQuery(
      data: window,
      child: SimulatedFold(
        simulation: simulation,
        child: const SizedBox.expand(key: probeKey),
      ),
    ),
  );

  return tester.element(find.byKey(probeKey));
}
