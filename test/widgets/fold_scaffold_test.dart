import 'dart:math' as math;

import 'package:duo_kit/duo_kit.dart';
import 'package:duo_kit/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _bodyKey = ValueKey('body');
const _contentKey = ValueKey('content');
const _navigationKey = ValueKey('navigation');
const _navigationHeight = 60.0;

final _ios = TargetPlatformVariant.only(TargetPlatform.iOS);

void main() {
  testWidgets(
    'puts the navigation at the bottom without a strip',
    variant: _ios,
    (tester) async {
      final placements = await _pumpScaffold(
        tester,
        FoldTestPose.duoInnerPortrait.data,
      );

      expect(placements.last, FoldNavigationPlacement.bottom);
      expect(
        tester.getRect(find.byKey(_navigationKey)),
        const Rect.fromLTRB(0, 951 - _navigationHeight, 669, 951),
      );
      expect(
        tester.getRect(find.byKey(_bodyKey)),
        const Rect.fromLTRB(0, 0, 669, 951 - _navigationHeight),
      );
      expect(_getPaddingOf(tester, _bodyKey), const EdgeInsets.only(top: 82));
      expect(
        _getPaddingOf(tester, _navigationKey),
        const EdgeInsets.only(bottom: 34),
      );
    },
  );

  testWidgets(
    'puts the navigation in the strip of the cover display',
    variant: _ios,
    (tester) async {
      final placements = await _pumpScaffold(
        tester,
        FoldTestPose.duoCoverWithOcclusions.data,
      );

      expect(placements.last, FoldNavigationPlacement.right);
      expect(
        tester.getRect(find.byKey(_navigationKey)),
        const Rect.fromLTRB(382, 0, 466, 678),
      );
      expect(
        tester.getRect(find.byKey(_bodyKey)),
        const Rect.fromLTRB(0, 0, 382, 678),
      );
      expect(
        _getPaddingOf(tester, _bodyKey),
        const EdgeInsets.only(bottom: 34),
      );
      expect(
        _getPaddingOf(tester, _navigationKey),
        const EdgeInsets.only(top: 170, bottom: 34),
      );
    },
  );

  testWidgets('puts the navigation in a strip on the left', variant: _ios, (
    tester,
  ) async {
    final placements = await _pumpScaffold(
      tester,
      FoldTestPose.duoCoverLandscapeLeft.data,
    );

    expect(placements.last, FoldNavigationPlacement.left);
    expect(
      tester.getRect(find.byKey(_navigationKey)),
      const Rect.fromLTRB(0, 0, 84, 466),
    );
    expect(
      tester.getRect(find.byKey(_bodyKey)),
      const Rect.fromLTRB(84, 0, 678, 466),
    );
    expect(_getPaddingOf(tester, _bodyKey), const EdgeInsets.only(bottom: 34));
    expect(
      _getPaddingOf(tester, _navigationKey),
      const EdgeInsets.only(top: 82, bottom: 34),
    );
  });

  testWidgets(
    'puts the navigation on the edge of the vertical bar where the window '
    'has no strip',
    variant: _ios,
    (tester) async {
      final placements = await _pumpScaffold(
        tester,
        FoldTestPose.duoInnerSplitViewLeft.data,
        verticalBarEdge: FoldVerticalBarEdge.leading,
      );

      expect(placements.last, FoldNavigationPlacement.left);
      expect(
        tester.getRect(find.byKey(_navigationKey)),
        const Rect.fromLTRB(0, 0, 84, 669),
      );
      expect(
        tester.getRect(find.byKey(_bodyKey)),
        const Rect.fromLTRB(84, 0, 469, 669),
      );
      expect(
        _getPaddingOf(tester, _bodyKey),
        const EdgeInsets.only(bottom: 34),
      );
      expect(
        _getPaddingOf(tester, _navigationKey),
        const EdgeInsets.only(bottom: 34),
      );
    },
  );

  testWidgets(
    'puts the navigation of a right-to-left app on the right for a leading '
    'vertical bar',
    variant: _ios,
    (tester) async {
      final placements = await _pumpScaffold(
        tester,
        FoldTestPose.duoInnerSplitViewLeft.data,
        verticalBarEdge: FoldVerticalBarEdge.leading,
        textDirection: TextDirection.rtl,
        verticalBarWidth: 100,
      );

      expect(placements.last, FoldNavigationPlacement.right);
      expect(
        tester.getRect(find.byKey(_navigationKey)),
        const Rect.fromLTRB(369, 0, 469, 669),
      );
    },
  );

  testWidgets(
    'keeps the navigation at the bottom for a vertical bar without a width',
    variant: _ios,
    (tester) async {
      final placements = await _pumpScaffold(
        tester,
        FoldTestPose.duoInnerSplitViewLeft.data,
        verticalBarEdge: FoldVerticalBarEdge.leading,
        verticalBarWidth: null,
      );

      expect(placements.last, FoldNavigationPlacement.bottom);
    },
  );

  testWidgets(
    'keeps the navigation at the bottom for a vertical bar edge in a window '
    'with a top inset',
    variant: _ios,
    (tester) async {
      // While the device closes from portrait, the edge changes first.
      final placements = await _pumpScaffold(
        tester,
        FoldTestPose.duoInnerPortrait.data,
        verticalBarEdge: FoldVerticalBarEdge.leading,
      );

      expect(placements.last, FoldNavigationPlacement.bottom);
    },
  );

  testWidgets(
    'prefers the strip of the system to the vertical bar width',
    variant: _ios,
    (tester) async {
      final placements = await _pumpScaffold(
        tester,
        FoldTestPose.duoCoverWithOcclusions.data,
        verticalBarEdge: FoldVerticalBarEdge.trailing,
        verticalBarWidth: 100,
      );

      expect(placements.last, FoldNavigationPlacement.right);
      expect(
        tester.getRect(find.byKey(_navigationKey)),
        const Rect.fromLTRB(382, 0, 466, 678),
      );
    },
  );

  for (final (keyboardHeight, contentBottom) in [
    (300.0, 951 - 300.0),
    // While the keyboard comes up, the navigation still shows above it.
    (40.0, 951 - _navigationHeight),
  ]) {
    testWidgets(
      'ends a Scaffold in the body above a keyboard of $keyboardHeight and '
      'the navigation at the bottom',
      variant: _ios,
      (tester) async {
        await _pumpScaffold(
          tester,
          _showKeyboard(FoldTestPose.duoInnerPortrait.data, keyboardHeight),
          body: const Scaffold(body: SizedBox.expand(key: _contentKey)),
        );

        expect(tester.getRect(find.byKey(_contentKey)).bottom, contentBottom);
        expect(tester.getRect(find.byKey(_navigationKey)).bottom, 951);
      },
    );
  }

  testWidgets('keeps the body state when the navigation moves', variant: _ios, (
    tester,
  ) async {
    await _pumpScaffold(tester, FoldTestPose.duoCover.data);
    final state = tester.state(find.byType(_StatefulBody));

    await _pumpScaffold(tester, FoldTestPose.duoInnerPortrait.data);

    expect(tester.state(find.byType(_StatefulBody)), same(state));
  });

  testWidgets(
    'keeps the navigation at the bottom when asked not to look for '
    'a strip',
    variant: _ios,
    (tester) async {
      final placements = await _pumpScaffold(
        tester,
        FoldTestPose.duoCover.data,
        detectStrip: false,
        verticalBarEdge: FoldVerticalBarEdge.trailing,
      );

      expect(placements.last, FoldNavigationPlacement.bottom);
    },
  );
}

/// Pumps a [FoldScaffold] in a window described by [data] and returns the
/// placements its navigation was built for.
Future<List<FoldNavigationPlacement>> _pumpScaffold(
  WidgetTester tester,
  MediaQueryData data, {
  bool? detectStrip,
  FoldVerticalBarEdge verticalBarEdge = FoldVerticalBarEdge.unspecified,
  TextDirection textDirection = TextDirection.ltr,
  double? verticalBarWidth = FoldScaffold.defaultVerticalBarWidth,
  Widget body = const _StatefulBody(key: _bodyKey),
}) async {
  final placements = <FoldNavigationPlacement>[];

  tester.view
    ..physicalSize = data.size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    FoldBridgeScope(
      verticalBarEdge: verticalBarEdge,
      child: MediaQuery(
        data: data,
        child: Directionality(
          textDirection: textDirection,
          child: FoldScaffold(
            detectStrip: detectStrip,
            verticalBarWidth: verticalBarWidth,
            body: body,
            navigationBuilder: (context, placement) {
              placements.add(placement);

              return SizedBox(
                key: _navigationKey,
                height: switch (placement.axis) {
                  Axis.horizontal => _navigationHeight,
                  Axis.vertical => null,
                },
              );
            },
          ),
        ),
      ),
    ),
  );

  return placements;
}

/// [data] with a keyboard of [height] up, which takes over the bottom inset as
/// on iOS.
MediaQueryData _showKeyboard(MediaQueryData data, double height) =>
    data.copyWith(
      viewInsets: EdgeInsets.only(bottom: height),
      padding: data.padding.copyWith(
        bottom: math.max(0, data.viewPadding.bottom - height),
      ),
    );

EdgeInsets _getPaddingOf(WidgetTester tester, Key key) =>
    MediaQuery.paddingOf(tester.element(find.byKey(key)));

class _StatefulBody extends StatefulWidget {
  const _StatefulBody({super.key});

  @override
  State<_StatefulBody> createState() => _StatefulBodyState();
}

class _StatefulBodyState extends State<_StatefulBody> {
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
