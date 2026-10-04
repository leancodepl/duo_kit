import 'package:duo_kit/debug.dart';
import 'package:duo_kit/duo_kit.dart';
import 'package:duo_kit_example/closed_fold_occlusions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:foldable/foldable.dart';

void main() => runApp(const ExampleApp());

const _background = Color(0xFFFFFFFF);
const _foreground = Color(0xFF1D1B20);
const _surface = Color(0xFFF1EFF4);
const _accent = Color(0xFF3D5AFE);

const _spacing = 16.0;
const _sidePaneWidth = 320.0;
const _twoPaneMinWidth = 600.0;

/// Lays plain widgets out with duo_kit. Nothing in it looks like any
/// platform: the navigation, the panes and the dialogs are all made here.
class ExampleApp extends StatelessWidget {
  /// Creates the example.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = WidgetsApp(
      color: _accent,
      textStyle: const TextStyle(color: _foreground, fontSize: 16),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: const _Home(),
    );

    // On iOS the fold reaches the display features only through a bridge.
    return FoldableProvider(
      bridgeMode: DisplayFeatureBridgeMode.full,
      child: ClosedFoldOcclusions(
        child: kDebugMode ? FoldDebugTools(child: app) : app,
      ),
    );
  }
}

enum _Tab {
  sessions('Sessions'),
  about('About');

  const _Tab(this.label);

  final String label;
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  var _tab = _Tab.sessions;

  void _selectTab(_Tab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _background,
    child: FoldScaffold(
      body: SafeArea(
        bottom: false,
        child: switch (_tab) {
          _Tab.sessions => const _SessionsPage(),
          _Tab.about => const _AboutPage(),
        },
      ),
      navigationBuilder: (context, placement) => _NavigationBar(
        placement: placement,
        selected: _tab,
        onSelected: _selectTab,
      ),
    ),
  );
}

/// A row of tabs at the bottom, or a column of them in the strip that iPhone
/// Duo keeps at the side of the window.
class _NavigationBar extends StatelessWidget {
  const _NavigationBar({
    required this.placement,
    required this.selected,
    required this.onSelected,
  });

  final FoldNavigationPlacement placement;
  final _Tab selected;
  final ValueChanged<_Tab> onSelected;

  @override
  Widget build(BuildContext context) {
    final isVertical = placement.axis == Axis.vertical;
    final items = _Tab.values.map(
      (tab) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(tab),
        child: Padding(
          padding: const EdgeInsets.all(_spacing),
          child: Text(
            tab.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tab == selected ? _accent : _foreground,
              fontSize: isVertical ? 12 : 16,
            ),
          ),
        ),
      ),
    );

    // FoldScaffold hands the bar the padding of where it sits: the bottom
    // inset, or in the strip the room taken by the status cluster.
    return ColoredBox(
      color: _surface,
      child: SafeArea(
        top: isVertical,
        child: isVertical
            ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items.toList(),
              )
            : Row(
                children: items.map((item) => Expanded(child: item)).toList(),
              ),
      ),
    );
  }
}

const _sessions = [
  (
    title: 'Keynote',
    details: 'What is new, and what is next for the conference app.',
  ),
  (
    title: 'Layouts on foldables',
    details: 'Panes on either side of the fold, and controls in the strip.',
  ),
  (title: 'Lunch', details: 'Second floor, from noon.'),
];

class _SessionsPage extends StatefulWidget {
  const _SessionsPage();

  @override
  State<_SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<_SessionsPage> {
  var _selected = 0;

  void _select(int index) => setState(() => _selected = index);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final isWide = constraints.maxWidth >= _twoPaneMinWidth;
      final list = _SessionList(
        selected: isWide ? _selected : null,
        onSelected: _select,
      );
      if (!isWide) {
        return list;
      }

      // Splits at the fold of a half open device, and keeps the state of the
      // panes when the fold comes and goes.
      return FoldSplitView(
        first: list,
        second: _SessionDetails(index: _selected),
        unfoldedBuilder: (context, first, second) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: _sidePaneWidth, child: first),
            const ColoredBox(color: _surface, child: SizedBox(width: 1)),
            Expanded(child: second),
          ],
        ),
      );
    },
  );
}

class _SessionList extends StatelessWidget {
  const _SessionList({required this.selected, required this.onSelected});

  /// The session shown next to the list, if any.
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: _sessions.length,
    itemBuilder: (context, index) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(index),
      child: ColoredBox(
        color: index == selected ? _surface : _background,
        child: Padding(
          padding: const EdgeInsets.all(_spacing),
          child: Text(_sessions[index].title),
        ),
      ),
    ),
  );
}

class _SessionDetails extends StatelessWidget {
  const _SessionDetails({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(_spacing),
      child: Text(_sessions[index].details),
    ),
  );
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  void _showMessage(BuildContext context, FoldAnchor anchor) {
    showGeneralDialog<void>(
      context: context,
      // Picks the half of a split window the dialog opens in.
      anchorPoint: anchor.resolvePoint(context),
      barrierDismissible: true,
      barrierLabel: 'Close',
      pageBuilder: (context, _, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(_spacing),
          child: ColoredBox(
            color: _background,
            child: Padding(
              padding: const EdgeInsets.all(_spacing * 2),
              child: Text('Opened as ${anchor.name}.'),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final anchor in FoldAnchor.values)
          GestureDetector(
            onTap: () => _showMessage(context, anchor),
            child: Padding(
              padding: const EdgeInsets.all(_spacing),
              child: Text(
                'Open a dialog for ${anchor.name}',
                style: const TextStyle(color: _accent),
              ),
            ),
          ),
      ],
    ),
  );
}
