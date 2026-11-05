import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:duo_kit/duo_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = EventChannel('duo_kit/state');
const _unfoldedKey = ValueKey('unfolded');
const _dialogKey = ValueKey('dialog');

/// Windows of phones and tablets that do not fold, close to what they report.
const _windows = {
  'an iPhone in portrait': (
    TargetPlatform.iOS,
    MediaQueryData(
      size: Size(402, 874),
      padding: EdgeInsets.only(top: 62, bottom: 34),
      viewPadding: EdgeInsets.only(top: 62, bottom: 34),
    ),
  ),
  'an iPhone in landscape': (
    TargetPlatform.iOS,
    MediaQueryData(
      size: Size(874, 402),
      padding: EdgeInsets.only(left: 62, right: 62, bottom: 21),
      viewPadding: EdgeInsets.only(left: 62, right: 62, bottom: 21),
    ),
  ),
  'an iPhone without a notch in landscape': (
    TargetPlatform.iOS,
    MediaQueryData(size: Size(667, 375)),
  ),
  'an iPad in landscape': (
    TargetPlatform.iOS,
    MediaQueryData(
      size: Size(1180, 820),
      padding: EdgeInsets.only(top: 24, bottom: 20),
      viewPadding: EdgeInsets.only(top: 24, bottom: 20),
    ),
  ),
  'an Android phone with a cutout in portrait': (
    TargetPlatform.android,
    MediaQueryData(
      size: Size(412, 915),
      padding: EdgeInsets.only(top: 48, bottom: 24),
      viewPadding: EdgeInsets.only(top: 48, bottom: 24),
      displayFeatures: [
        DisplayFeature(
          bounds: Rect.fromLTWH(186, 0, 40, 48),
          type: DisplayFeatureType.cutout,
          state: DisplayFeatureState.unknown,
        ),
      ],
    ),
  ),
  'an Android phone with a cutout in immersive landscape': (
    TargetPlatform.android,
    MediaQueryData(
      size: Size(915, 412),
      padding: EdgeInsets.only(left: 48),
      viewPadding: EdgeInsets.only(left: 48),
      displayFeatures: [
        DisplayFeature(
          bounds: Rect.fromLTWH(0, 186, 48, 40),
          type: DisplayFeatureType.cutout,
          state: DisplayFeatureState.unknown,
        ),
      ],
    ),
  ),
};

void main() {
  for (final MapEntry(key: name, value: (platform, data)) in _windows.entries) {
    final variant = TargetPlatformVariant.only(platform);

    testWidgets('changes nothing on $name', variant: variant, (tester) async {
      late MediaQueryData bridged;
      late FoldGeometry geometry;
      late FoldNavigationPlacement placement;

      await _pumpWindow(
        tester,
        data,
        Builder(
          builder: (context) {
            bridged = MediaQuery.of(context);
            geometry = FoldGeometry.of(context);

            return FoldScaffold(
              body: FoldSplitView(
                first: const SizedBox.expand(),
                second: const SizedBox.expand(),
                unfoldedBuilder: (context, first, second) => Row(
                  key: _unfoldedKey,
                  children: [
                    Expanded(child: first),
                    Expanded(child: second),
                  ],
                ),
              ),
              navigationBuilder: (context, navigationPlacement) {
                placement = navigationPlacement;

                return const SizedBox();
              },
            );
          },
        ),
      );
      await tester.pump();

      expect(bridged, data);
      expect(geometry.strip, isNull);
      expect(geometry.division, isNull);
      expect(geometry.verticalBarEdge, FoldVerticalBarEdge.unspecified);
      expect(placement, FoldNavigationPlacement.bottom);
      expect(find.byKey(_unfoldedKey), findsOneWidget);
    });

    testWidgets(
      'opens dialogs on $name where they open without an anchor',
      variant: variant,
      (tester) async {
        // Dialog routes put their page in a DisplayFeatureSubScreen with the
        // anchor point, which is where an anchor could move a dialog.
        Future<Rect> getDialogRect(Offset? anchorPoint) async {
          await _pumpWindow(
            tester,
            data,
            DisplayFeatureSubScreen(
              anchorPoint: anchorPoint,
              child: const SizedBox.expand(key: _dialogKey),
            ),
          );

          return tester.getRect(find.byKey(_dialogKey));
        }

        final withoutAnchor = await getDialogRect(null);
        final context = tester.element(find.byKey(_dialogKey));
        final contentPoint = FoldAnchor.content.resolvePoint(context);
        final controlsPoint = FoldAnchor.controls.resolvePoint(context);

        expect(await getDialogRect(contentPoint), withoutAnchor);
        expect(await getDialogRect(controlsPoint), withoutAnchor);
      },
    );
  }
}

/// Pumps [child] below a [FoldBridge] in a window described by [data], with a
/// native side that reports nothing, as on a device without a hinge.
Future<void> _pumpWindow(
  WidgetTester tester,
  MediaQueryData data,
  Widget child,
) {
  tester.view
    ..physicalSize = data.size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final messenger = tester.binding.defaultBinaryMessenger
    ..setMockStreamHandler(
      _channel,
      MockStreamHandler.inline(onListen: (arguments, events) {}),
    );
  addTearDown(() => messenger.setMockStreamHandler(_channel, null));

  return tester.pumpWidget(
    MediaQuery(
      data: data,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: FoldBridge(child: child),
      ),
    ),
  );
}
