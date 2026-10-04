import 'package:duo_kit/debug.dart';
import 'package:duo_kit/duo_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _appKey = ValueKey('app');

const _window = MediaQueryData(size: Size(800, 600));

void main() {
  testWidgets('switches to the next pose on a tap and keeps the app state', (
    tester,
  ) async {
    await _pumpTools(tester);
    final appState = tester.state(find.byKey(_appKey));

    await tester.tap(find.text('Fold: off'));
    await tester.pump();

    expect(find.text('Fold: strip'), findsOneWidget);

    await tester.tap(find.text('Fold: strip'));
    await tester.pump();

    expect(find.text('Fold: book'), findsOneWidget);
    expect(
      FoldGeometry.of(tester.element(find.byKey(_appKey))).division,
      isNotNull,
    );
    expect(tester.state(find.byKey(_appKey)), same(appState));
  });

  testWidgets('starts over after the last pose', (tester) async {
    await _pumpTools(tester, initialSimulation: FoldSimulation.laptop);

    await tester.tap(find.text('Fold: laptop'));
    await tester.pump();

    expect(find.text('Fold: off'), findsOneWidget);
  });

  testWidgets('lets touches through the overlay', (tester) async {
    var taps = 0;

    await _pumpTools(
      tester,
      initialSimulation: FoldSimulation.book,
      app: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => taps++,
        child: const SizedBox.expand(),
      ),
    );
    await tester.tapAt(const Offset(400, 100));

    expect(taps, 1);
  });
}

Future<void> _pumpTools(
  WidgetTester tester, {
  FoldSimulation initialSimulation = FoldSimulation.off,
  Widget app = const _StatefulApp(key: _appKey),
}) async {
  tester.view
    ..physicalSize = _window.size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: _window,
      child: FoldDebugTools(initialSimulation: initialSimulation, child: app),
    ),
  );
}

class _StatefulApp extends StatefulWidget {
  const _StatefulApp({super.key});

  @override
  State<_StatefulApp> createState() => _StatefulAppState();
}

class _StatefulAppState extends State<_StatefulApp> {
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
