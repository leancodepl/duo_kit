import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:duo_kit/duo_kit.dart';
import 'package:duo_kit/testing.dart';
import 'package:duo_kit_ios/duo_kit_ios.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = EventChannel('duo_kit_ios/state');

final _ios = TargetPlatformVariant.only(TargetPlatform.iOS);

// The raw values of UIHinge.Status that the native side sends.
const _unknown = 0;
const _closed = 1;
const _partiallyOpen = 2;
const _fullyOpen = 3;

/// What the native side sends for the closed cover display, with the regions
/// measured on the iPhone Duo simulator (iOS 27.1).
const _closedCoverMessage = {
  'hinge': {'status': _closed, 'angle': 0.0},
  'verticalBarEdge': 'trailing',
  'regions': [
    {
      'kind': 'occlusion',
      'rect': [399.7, 29.3, 436.7, 66.3],
      'active': true,
    },
    {
      'kind': 'occlusion',
      'rect': [382.0, 0.0, 466.0, 170.0],
      'active': true,
    },
  ],
};

/// What the native side sends for the inner display in landscape, with the
/// regions measured on the iPhone Duo simulator (iOS 27.1).
Map<String, Object?> _buildInnerLandscapeMessage({
  required int hingeStatus,
  required bool isFoldActive,
}) => {
  'hinge': {'status': hingeStatus, 'angle': 1.6},
  'verticalBarEdge': 'trailing',
  'regions': [
    {
      'kind': 'occlusion',
      'rect': [867.0, 0.0, 951.0, 120.0],
      'active': true,
    },
    {
      'kind': 'division',
      'rect': [455.5, 0.0, 495.5, 669.0],
      'active': isFoldActive,
    },
  ],
};

void main() {
  testWidgets('passes its child through on other platforms', (tester) async {
    late FoldHinge? hinge;
    late List<DisplayFeature> features;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: DuoKitIos(
          child: Builder(
            builder: (context) {
              hinge = DuoKitIos.hingeOf(context);
              features = MediaQuery.displayFeaturesOf(context);

              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(hinge, isNull);
    expect(features, isEmpty);
  });

  testWidgets('reports nothing without a DuoKitIos above', (tester) async {
    late FoldHinge? hinge;
    late FoldVerticalBarEdge edge;

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          hinge = DuoKitIos.hingeOf(context);
          edge = DuoKitIos.verticalBarEdgeOf(context);

          return const SizedBox();
        },
      ),
    );

    expect(hinge, isNull);
    expect(edge, FoldVerticalBarEdge.unspecified);
  });

  testWidgets(
    'clears the status cluster of the closed cover display',
    variant: _ios,
    (tester) async {
      final probe = await _pumpBridge(tester, FoldTestPose.duoCover.data);

      await probe.send(_closedCoverMessage);

      expect(
        probe.geometry.strip,
        const FoldStrip(
          side: FoldStripSide.right,
          rect: Rect.fromLTWH(382, 0, 84, 678),
          topClearance: 170,
          bottomClearance: 0,
          isClearanceEstimated: false,
        ),
      );
      expect(
        probe.hinge,
        const FoldHinge(status: FoldHingeStatus.closed, angle: 0),
      );
      expect(probe.edge, FoldVerticalBarEdge.trailing);
    },
  );

  testWidgets(
    'splits at the fold as soon as the hinge is partly open',
    variant: _ios,
    (tester) async {
      final probe = await _pumpBridge(
        tester,
        _withoutFeatures(FoldTestPose.duoInnerLandscape),
      );

      // The division only turns active a moment after the hinge moves.
      await probe.send(
        _buildInnerLandscapeMessage(
          hingeStatus: _partiallyOpen,
          isFoldActive: false,
        ),
      );

      expect(
        probe.geometry.division,
        const FoldDivision(
          bounds: Rect.fromLTRB(455.5, 0, 495.5, 669),
          axis: Axis.vertical,
          posture: DisplayFeatureState.postureHalfOpened,
        ),
      );
    },
  );

  testWidgets(
    'leaves the window whole while the device lies flat',
    variant: _ios,
    (tester) async {
      final probe = await _pumpBridge(
        tester,
        _withoutFeatures(FoldTestPose.duoInnerLandscape),
      );

      // The division can still be active a moment after the device lies flat.
      await probe.send(
        _buildInnerLandscapeMessage(
          hingeStatus: _fullyOpen,
          isFoldActive: true,
        ),
      );

      expect(probe.geometry.division, isNull);
      expect(probe.geometry.strip?.topClearance, 120);
    },
  );

  testWidgets(
    'trusts an active fold while the hinge is unknown',
    variant: _ios,
    (tester) async {
      final probe = await _pumpBridge(
        tester,
        _withoutFeatures(FoldTestPose.duoInnerLandscape),
      );

      await probe.send({
        ..._buildInnerLandscapeMessage(
          hingeStatus: _unknown,
          isFoldActive: true,
        ),
        'hinge': null,
      });

      expect(probe.geometry.division?.axis, Axis.vertical);
      expect(probe.hinge, isNull);
    },
  );

  testWidgets('keeps the display features of the platform', variant: _ios, (
    tester,
  ) async {
    const platformHinge = DisplayFeature(
      bounds: Rect.fromLTWH(540, 0, 34, 720),
      type: DisplayFeatureType.hinge,
      state: DisplayFeatureState.postureFlat,
    );
    final probe = await _pumpBridge(
      tester,
      const MediaQueryData(
        size: Size(1114, 720),
        displayFeatures: [platformHinge],
      ),
    );

    await probe.send(_closedCoverMessage);

    expect(probe.features, const [
      platformHinge,
      DisplayFeature(
        bounds: Rect.fromLTRB(399.7, 29.3, 436.7, 66.3),
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
      DisplayFeature(
        bounds: Rect.fromLTRB(382, 0, 466, 170),
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ]);
  });
}

MediaQueryData _withoutFeatures(FoldTestPose pose) =>
    pose.data.copyWith(displayFeatures: const []);

/// What the widgets below a [DuoKitIos] see.
class _Probe {
  _Probe(this._tester);

  final WidgetTester _tester;
  late MockStreamHandlerEventSink _sink;
  late FoldGeometry geometry;
  late FoldHinge? hinge;
  late FoldVerticalBarEdge edge;
  late List<DisplayFeature> features;

  /// Sends [message] from the native side, then pumps a frame for it to
  /// arrive and one for the widgets to rebuild.
  Future<void> send(Map<String, Object?> message) async {
    _sink.success(message);
    await _tester.pump();
    await _tester.pump();
  }
}

/// Pumps a [DuoKitIos] in a window described by [data], with a mocked native
/// side.
Future<_Probe> _pumpBridge(WidgetTester tester, MediaQueryData data) async {
  final probe = _Probe(tester);
  final messenger = tester.binding.defaultBinaryMessenger
    ..setMockStreamHandler(
      _channel,
      MockStreamHandler.inline(
        onListen: (arguments, events) {
          probe._sink = events;
        },
      ),
    );
  addTearDown(() => messenger.setMockStreamHandler(_channel, null));

  await tester.pumpWidget(
    MediaQuery(
      data: data,
      child: DuoKitIos(
        child: Builder(
          builder: (context) {
            probe
              ..geometry = FoldGeometry.of(context)
              ..hinge = DuoKitIos.hingeOf(context)
              ..edge = DuoKitIos.verticalBarEdgeOf(context)
              ..features = MediaQuery.displayFeaturesOf(context);

            return const SizedBox();
          },
        ),
      ),
    ),
  );
  await tester.pump();

  return probe;
}
