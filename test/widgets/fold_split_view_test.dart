import 'package:duo_kit/duo_kit.dart';
import 'package:duo_kit/testing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _firstKey = ValueKey('first');
const _secondKey = ValueKey('second');
const _unfoldedKey = ValueKey('unfolded');

/// Where the fold of the inner display starts and ends, from its top or left
/// edge.
const _foldStart = 455.5;
const _foldEnd = 495.5;
const _innerShortSide = 669.0;
const _innerLongSide = 951.0;

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

EdgeInsets _getPaddingOf(WidgetTester tester, Key key) =>
    MediaQuery.paddingOf(tester.element(find.byKey(key)));

EdgeInsets _getViewInsetsOf(WidgetTester tester, Key key) =>
    MediaQuery.viewInsetsOf(tester.element(find.byKey(key)));
