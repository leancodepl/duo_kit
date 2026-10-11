import 'package:duo_kit/duo_kit.dart';
import 'package:duo_kit/testing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _bodyKey = ValueKey('body');
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
        const EdgeInsets.only(top: 82, bottom: 34),
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
    final placements = await _pumpScaffold(tester, _leftStripData);

    expect(placements.last, FoldNavigationPlacement.left);
    expect(
      tester.getRect(find.byKey(_navigationKey)),
      const Rect.fromLTRB(0, 0, 84, 669),
    );
    expect(
      tester.getRect(find.byKey(_bodyKey)),
      const Rect.fromLTRB(84, 0, 951, 669),
    );
    expect(_getPaddingOf(tester, _bodyKey), const EdgeInsets.only(bottom: 34));
  });

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
}) async {
  final placements = <FoldNavigationPlacement>[];

  tester.view
    ..physicalSize = data.size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: data,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: FoldScaffold(
          detectStrip: detectStrip,
          body: const _StatefulBody(key: _bodyKey),
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
  );

  return placements;
}

/// A window with a strip on the left, as iPhone Duo gives the app on the left
/// of Split View. Not measured.
const _leftStripData = MediaQueryData(
  size: Size(951, 669),
  padding: EdgeInsets.only(left: 84, bottom: 34),
  viewPadding: EdgeInsets.only(left: 84, bottom: 34),
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
