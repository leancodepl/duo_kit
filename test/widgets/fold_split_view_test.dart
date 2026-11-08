import 'dart:async';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:duo_kit/duo_kit.dart';
import 'package:duo_kit/testing.dart';
import 'package:flutter/cupertino.dart' show CupertinoSheetRoute;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _firstKey = ValueKey('first');
const _secondKey = ValueKey('second');
const _unfoldedKey = ValueKey('unfolded');
const _homeKey = ValueKey('home');

/// Where the fold of the inner display starts and ends, from its top or left
/// edge.
const _foldStart = 455.5;
const _foldEnd = 495.5;
const _innerShortSide = 669.0;
const _innerLongSide = 951.0;
const _splitViewWindowWidth = 469.0;
const _topBarHeight = 100.0;
const _midTransition = Duration(milliseconds: 100);

/// Platforms whose page transitions move the page below.
const _routePlatforms = TargetPlatformVariant({
  TargetPlatform.iOS,
  TargetPlatform.android,
});

/// The window of the app on the left of Split View, half open, with the fold
/// at its right edge. Measured on the iPhone Duo simulator (iOS 27.1).
const _leftAppHalfOpened = MediaQueryData(
  size: Size(_splitViewWindowWidth, _innerShortSide),
  padding: EdgeInsets.only(bottom: 34),
  viewPadding: EdgeInsets.only(bottom: 34),
  displayFeatures: [
    DisplayFeature(
      bounds: Rect.fromLTRB(
        _foldStart,
        0,
        _splitViewWindowWidth,
        _innerShortSide,
      ),
      type: DisplayFeatureType.fold,
      state: DisplayFeatureState.postureHalfOpened,
    ),
  ],
);

const _splitView = FoldSplitView(
  first: SizedBox.expand(key: _firstKey),
  second: SizedBox.expand(key: _secondKey),
  unfoldedBuilder: _buildUnfolded,
);

void main() {
  testWidgets('shows the unfolded layout while the device lies flat', (
    tester,
  ) async {
    await _pumpPose(tester, FoldTestPose.duoInnerLandscape, _splitView);

    expect(find.byKey(_unfoldedKey), findsOneWidget);
    expect(find.byKey(_firstKey), findsNothing);
  });

  testWidgets('splits at a vertical fold, first pane on the leading side', (
    tester,
  ) async {
    await _pumpPose(tester, FoldTestPose.duoHalfOpenedLandscape, _splitView);

    expect(
      tester.getRect(find.byKey(_firstKey)),
      const Rect.fromLTRB(0, 0, _foldStart, _innerShortSide),
    );
    expect(
      tester.getRect(find.byKey(_secondKey)),
      const Rect.fromLTRB(_foldEnd, 0, _innerLongSide, _innerShortSide),
    );
    expect(_getPaddingOf(tester, _firstKey), const EdgeInsets.only(bottom: 34));
    expect(
      _getPaddingOf(tester, _secondKey),
      const EdgeInsets.only(right: 84, bottom: 34),
    );
  });

  testWidgets('puts the first pane on the right in right-to-left layouts', (
    tester,
  ) async {
    await _pumpPose(
      tester,
      FoldTestPose.duoHalfOpenedLandscape,
      _splitView,
      textDirection: TextDirection.rtl,
    );

    expect(
      tester.getRect(find.byKey(_firstKey)),
      const Rect.fromLTRB(_foldEnd, 0, _innerLongSide, _innerShortSide),
    );
    expect(
      tester.getRect(find.byKey(_secondKey)),
      const Rect.fromLTRB(0, 0, _foldStart, _innerShortSide),
    );
  });

  testWidgets('splits at a horizontal fold, first pane on top', (tester) async {
    await _pumpPose(tester, FoldTestPose.duoHalfOpenedPortrait, _splitView);

    expect(
      tester.getRect(find.byKey(_firstKey)),
      const Rect.fromLTRB(0, 0, _innerShortSide, _foldStart),
    );
    expect(
      tester.getRect(find.byKey(_secondKey)),
      const Rect.fromLTRB(0, _foldEnd, _innerShortSide, _innerLongSide),
    );
    expect(_getPaddingOf(tester, _firstKey), const EdgeInsets.only(top: 82));
    expect(
      _getPaddingOf(tester, _secondKey),
      const EdgeInsets.only(bottom: 34),
    );
  });

  testWidgets('shows the keyboard only to the pane at the bottom', (
    tester,
  ) async {
    const keyboard = EdgeInsets.only(bottom: 300);

    await _pumpData(
      tester,
      FoldTestPose.duoHalfOpenedPortrait.data.copyWith(viewInsets: keyboard),
      _splitView,
    );

    expect(_getViewInsetsOf(tester, _firstKey), EdgeInsets.zero);
    expect(_getViewInsetsOf(tester, _secondKey), keyboard);
  });

  testWidgets('keeps the state of a pane the layout hides offstage', (
    tester,
  ) async {
    const splitView = FoldSplitView(
      first: _StatefulPane(key: _firstKey),
      second: _StatefulPane(key: _secondKey),
      unfoldedBuilder: _buildWithHiddenSecond,
    );

    await _pumpPose(tester, FoldTestPose.duoInnerLandscape, splitView);
    final secondState = tester.state(
      find.byKey(_secondKey, skipOffstage: false),
    );

    await _pumpPose(tester, FoldTestPose.duoHalfOpenedLandscape, splitView);
    await _pumpPose(tester, FoldTestPose.duoInnerLandscape, splitView);

    expect(
      tester.state(find.byKey(_secondKey, skipOffstage: false)),
      same(secondState),
    );
  });

  testWidgets('finds the fold from below a top bar', (tester) async {
    const topBarHeight = 100.0;

    await _pumpPose(
      tester,
      FoldTestPose.duoHalfOpenedPortrait,
      const Column(
        children: [
          SizedBox(height: topBarHeight),
          Expanded(child: _splitView),
        ],
      ),
    );

    expect(
      tester.getRect(find.byKey(_firstKey)),
      const Rect.fromLTRB(0, topBarHeight, _innerShortSide, _foldStart),
    );
    expect(
      tester.getRect(find.byKey(_secondKey)),
      const Rect.fromLTRB(0, _foldEnd, _innerShortSide, _innerLongSide),
    );
  });

  testWidgets('follows the fold when a top bar above it resizes', (
    tester,
  ) async {
    const expandedTopBarHeight = 150.0;
    final topBarHeight = ValueNotifier<double>(100);
    addTearDown(topBarHeight.dispose);

    await _pumpPose(
      tester,
      FoldTestPose.duoHalfOpenedPortrait,
      ValueListenableBuilder(
        valueListenable: topBarHeight,
        builder: (context, height, splitView) => Column(
          children: [
            SizedBox(height: height),
            Expanded(child: splitView ?? const SizedBox()),
          ],
        ),
        child: _splitView,
      ),
    );

    topBarHeight.value = expandedTopBarHeight;
    await tester.pump();
    await tester.pump();

    expect(
      tester.getRect(find.byKey(_firstKey)),
      const Rect.fromLTRB(0, expandedTopBarHeight, _innerShortSide, _foldStart),
    );
  });

  testWidgets('shows the unfolded layout where it does not reach the fold', (
    tester,
  ) async {
    await _pumpPose(
      tester,
      FoldTestPose.duoHalfOpenedLandscape,
      const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 300, child: _splitView),
          Spacer(),
        ],
      ),
    );

    expect(find.byKey(_unfoldedKey), findsOneWidget);
  });

  testWidgets('shows the unfolded layout where its edge lies on the fold', (
    tester,
  ) async {
    await _pumpPose(
      tester,
      FoldTestPose.duoHalfOpenedLandscape,
      const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: (_foldStart + _foldEnd) / 2, child: _splitView),
          Spacer(),
        ],
      ),
    );

    expect(find.byKey(_unfoldedKey), findsOneWidget);
  });

  testWidgets(
    'shows the unfolded layout for a fold on the edge of the window',
    (tester) async {
      await _pumpData(tester, _leftAppHalfOpened, _splitView);

      expect(find.byKey(_unfoldedKey), findsOneWidget);
    },
  );

  testWidgets('shows the unfolded layout with unbounded constraints', (
    tester,
  ) async {
    await _pumpPose(
      tester,
      FoldTestPose.duoHalfOpenedLandscape,
      ListView(
        children: const [
          FoldSplitView(
            first: SizedBox(key: _firstKey),
            second: SizedBox(key: _secondKey),
            unfoldedBuilder: _buildShortUnfolded,
          ),
        ],
      ),
    );

    expect(find.byKey(_unfoldedKey), findsOneWidget);
  });

  testWidgets('follows the fold on a page scrolled into view', (tester) async {
    const secondPageKey = ValueKey('secondPage');

    await _pumpPose(
      tester,
      FoldTestPose.duoHalfOpenedLandscape,
      PageView(
        children: const [
          _splitView,
          FoldSplitView(
            first: SizedBox.expand(key: secondPageKey),
            second: SizedBox.expand(),
            unfoldedBuilder: _buildUnfolded,
          ),
        ],
      ),
    );

    // Holds the page still halfway, then lets it go.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await gesture.moveBy(const Offset(-300, 0));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await gesture.moveBy(const Offset(-300, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(secondPageKey)),
      const Rect.fromLTRB(0, 0, _foldStart, _innerShortSide),
    );
  });

  testWidgets('goes idle on a kept-alive page scrolled out of view', (
    tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);

    await _pumpPose(
      tester,
      FoldTestPose.duoHalfOpenedLandscape,
      PageView(
        controller: controller,
        children: const [
          _KeptAlive(child: _splitView),
          SizedBox.expand(),
        ],
      ),
    );

    controller.jumpToPage(1);
    await tester.pump();
    await tester.pump();

    expect(tester.binding.hasScheduledFrame, isFalse);

    controller.jumpToPage(0);
    await tester.pump();

    expect(
      tester.getRect(find.byKey(_firstKey)),
      const Rect.fromLTRB(0, 0, _foldStart, _innerShortSide),
    );
  });

  testWidgets(
    'splits in place when a route above it closes after the device folded',
    variant: _routePlatforms,
    (tester) async {
      await _pumpApp(tester, FoldTestPose.duoInnerLandscape, _splitView);

      final navigator = Navigator.of(tester.element(find.byKey(_unfoldedKey)));
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(builder: (context) => const SizedBox()),
        ),
      );
      await tester.pumpAndSettle();

      await _pumpApp(tester, FoldTestPose.duoHalfOpenedLandscape, _splitView);
      await tester.pumpAndSettle();

      navigator.pop();
      await tester.pump();
      await tester.pump(_midTransition);

      // The page still moves, with its panes laid out as they will rest.
      expect(
        tester.getSize(find.byKey(_firstKey)),
        const Size(_foldStart, _innerShortSide),
      );

      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byKey(_firstKey)),
        const Rect.fromLTRB(0, 0, _foldStart, _innerShortSide),
      );
    },
  );

  testWidgets(
    'splits in place while its route comes in',
    variant: _routePlatforms,
    (tester) async {
      await _pumpApp(
        tester,
        FoldTestPose.duoHalfOpenedPortrait,
        const SizedBox.expand(key: _homeKey),
      );

      final navigator = Navigator.of(tester.element(find.byKey(_homeKey)));
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (context) => const Column(
              children: [
                SizedBox(height: _topBarHeight),
                Expanded(child: _splitView),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(_midTransition);

      expect(
        tester.getSize(find.byKey(_firstKey)),
        const Size(_innerShortSide, _foldStart - _topBarHeight),
      );
    },
  );

  testWidgets('splits in place on a route that rests lower, as a sheet', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      FoldTestPose.duoHalfOpenedPortrait,
      const SizedBox.expand(key: _homeKey),
    );

    final navigator = Navigator.of(tester.element(find.byKey(_homeKey)));
    unawaited(
      navigator.push(
        CupertinoSheetRoute<void>(builder: (context) => _splitView),
      ),
    );
    await tester.pumpAndSettle();

    final sheetTop = tester.getTopLeft(find.byType(FoldSplitView)).dy;

    expect(sheetTop, greaterThan(0));
    expect(
      tester.getRect(find.byKey(_firstKey)),
      Rect.fromLTRB(0, sheetTop, _innerShortSide, _foldStart),
    );
  });

  testWidgets('keeps the state of the panes when the fold comes and goes', (
    tester,
  ) async {
    const first = _StatefulPane(key: _firstKey);
    const second = _StatefulPane(key: _secondKey);
    const splitView = FoldSplitView(
      first: first,
      second: second,
      unfoldedBuilder: _buildRow,
    );

    await _pumpPose(tester, FoldTestPose.duoInnerLandscape, splitView);
    final firstState = tester.state(find.byKey(_firstKey));
    final secondState = tester.state(find.byKey(_secondKey));

    await _pumpPose(tester, FoldTestPose.duoHalfOpenedLandscape, splitView);

    expect(tester.state(find.byKey(_firstKey)), same(firstState));
    expect(tester.state(find.byKey(_secondKey)), same(secondState));

    await _pumpPose(tester, FoldTestPose.duoInnerLandscape, splitView);

    expect(tester.state(find.byKey(_firstKey)), same(firstState));
    expect(tester.state(find.byKey(_secondKey)), same(secondState));
  });
}

Widget _buildUnfolded(BuildContext context, Widget first, Widget second) =>
    const SizedBox.expand(key: _unfoldedKey);

Widget _buildShortUnfolded(BuildContext context, Widget first, Widget second) =>
    const SizedBox(key: _unfoldedKey, height: 100);

Widget _buildRow(BuildContext context, Widget first, Widget second) => Row(
  children: [
    Expanded(child: first),
    Expanded(child: second),
  ],
);

/// The recipe from the README for a layout that shows only the first pane.
Widget _buildWithHiddenSecond(
  BuildContext context,
  Widget first,
  Widget second,
) => Stack(
  fit: StackFit.expand,
  children: [
    first,
    Offstage(child: TickerMode(enabled: false, child: second)),
  ],
);

class _StatefulPane extends StatefulWidget {
  const _StatefulPane({super.key});

  @override
  State<_StatefulPane> createState() => _StatefulPaneState();
}

class _StatefulPaneState extends State<_StatefulPane> {
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

/// Keeps [child] alive while its page is scrolled out of view.
class _KeptAlive extends StatefulWidget {
  const _KeptAlive({required this.child});

  final Widget child;

  @override
  State<_KeptAlive> createState() => _KeptAliveState();
}

class _KeptAliveState extends State<_KeptAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return widget.child;
  }
}

/// Pumps [child] in a window of [pose], then once more for the split view to
/// pick up where it sits.
Future<void> _pumpPose(
  WidgetTester tester,
  FoldTestPose pose,
  Widget child, {
  TextDirection textDirection = TextDirection.ltr,
}) => _pumpData(tester, pose.data, child, textDirection: textDirection);

/// Pumps [child] in a window described by [data], then once more for the
/// split view to pick up where it sits.
Future<void> _pumpData(
  WidgetTester tester,
  MediaQueryData data,
  Widget child, {
  TextDirection textDirection = TextDirection.ltr,
}) async {
  tester.view
    ..physicalSize = data.size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: data,
      child: Directionality(textDirection: textDirection, child: child),
    ),
  );
  await tester.pump();
}

/// Pumps [home] as the first route of an app in a window of [pose], then once
/// more for the split view to pick up where it sits.
Future<void> _pumpApp(
  WidgetTester tester,
  FoldTestPose pose,
  Widget home,
) async {
  tester.view
    ..physicalSize = pose.data.size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          MediaQuery(data: pose.data, child: child ?? const SizedBox()),
      home: home,
    ),
  );
  await tester.pump();
}

EdgeInsets _getPaddingOf(WidgetTester tester, Key key) =>
    MediaQuery.paddingOf(tester.element(find.byKey(key)));

EdgeInsets _getViewInsetsOf(WidgetTester tester, Key key) =>
    MediaQuery.viewInsetsOf(tester.element(find.byKey(key)));
