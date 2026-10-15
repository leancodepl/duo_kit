import 'package:duo_kit/debug.dart';
import 'package:duo_kit/duo_kit.dart';
import 'package:duo_kit_example/closed_fold_occlusions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:foldable/foldable.dart';

void main() => runApp(const ExampleApp());

const _background = Color(0xFFF6F4F1);
const _surface = Color(0xFFFFFFFF);
const _outline = Color(0xFFE6E2DD);
const _foreground = Color(0xFF1B1A1F);
const _muted = Color(0xFF6E6A73);
const _accent = Color(0xFF4F46E5);
const _accentSoft = Color(0xFFE7E5FC);
const _onAccent = Color(0xFFFFFFFF);
const _liveIndicator = Color(0xFFE11D48);
const _barrier = Color(0x661B1A1F);
const _shadow = Color(0x1F1B1A1F);
const _shadowClear = Color(0x001B1A1F);

// Clear versions of the selection colours, so that a selection fades without
// passing through grey.
const _accentSoftClear = Color(0x00E7E5FC);
const _surfaceClear = Color(0x00FFFFFF);

/// Shows through where a split view leaves the fold empty.
const _gap = Color(0xFFE2DDD6);

const _s4 = 4.0;
const _s8 = 8.0;
const _s12 = 12.0;
const _s16 = 16.0;
const _s20 = 20.0;
const _s24 = 24.0;
const _s32 = 32.0;

const _sidePaneWidth = 340.0;
const _twoPaneMinWidth = 600.0;
const _paneMaxWidth = 420.0;
const _dividerWidth = 1.0;
const _accentBarWidth = 4.0;
const _timeColumnWidth = 48.0;
const _progressBarHeight = 6.0;
const _liveDotSize = 8.0;
const _seekSeconds = 10;
const _chipTintAlpha = 0.12;
const _liveProgress = 0.45;
const _animationDuration = Duration(milliseconds: 250);

const _cardRadius = BorderRadius.all(Radius.circular(24));
const _tileRadius = BorderRadius.all(Radius.circular(16));
const _pillRadius = BorderRadius.all(Radius.circular(999));
const _dividerSide = BorderSide(color: _outline);
const _cardShadow = [
  BoxShadow(color: _shadow, blurRadius: 24, offset: Offset(0, 8)),
];

// The shadow fades rather than shrinks, since a shrinking shadow shows through
// a tile that is fading out.
const _cardShadowClear = [
  BoxShadow(color: _shadowClear, blurRadius: 24, offset: Offset(0, 8)),
];

const _displayStyle = TextStyle(
  color: _foreground,
  fontSize: 30,
  fontWeight: FontWeight.w700,
  height: 1.15,
  letterSpacing: -0.6,
);
const _titleStyle = TextStyle(
  color: _foreground,
  fontSize: 22,
  fontWeight: FontWeight.w700,
  height: 1.2,
  letterSpacing: -0.3,
);
const _headingStyle = TextStyle(
  color: _foreground,
  fontSize: 16,
  fontWeight: FontWeight.w600,
  height: 1.3,
);
const _bodyStyle = TextStyle(color: _foreground, fontSize: 16, height: 1.5);
const _captionStyle = TextStyle(
  color: _muted,
  fontSize: 13,
  fontWeight: FontWeight.w500,
  height: 1.3,
);
const _labelStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
const _compactLabelStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

/// Lays plain widgets out with duo_kit. Nothing in it looks like any
/// platform: the navigation, the panes and the dialogs are all made here.
class ExampleApp extends StatelessWidget {
  /// Creates the example.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = WidgetsApp(
      color: _accent,
      debugShowCheckedModeBanner: false,
      textStyle: _bodyStyle,
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
  schedule('Schedule'),
  live('Live');

  const _Tab(this.label);

  final String label;
}

/// Switches between the pages with the navigation of a [FoldScaffold].
class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  var _tab = _Tab.schedule;

  void _selectTab(_Tab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _background,
    child: FoldScaffold(
      body: SafeArea(
        bottom: false,
        child: switch (_tab) {
          _Tab.schedule => const _SchedulePage(),
          _Tab.live => const _LivePage(),
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
      (tab) => _NavigationItem(
        label: tab.label,
        isSelected: tab == selected,
        isCompact: isVertical,
        onTap: () => onSelected(tab),
      ),
    );

    // FoldScaffold hands the bar the padding of where it sits: the bottom
    // inset, or in the strip the room taken by the status cluster.
    return DecoratedBox(
      decoration: BoxDecoration(color: _surface, border: _getBorder()),
      child: SafeArea(
        top: isVertical,
        child: Padding(
          padding: const EdgeInsets.all(_s8),
          child: isVertical
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: _s4,
                  children: items.toList(),
                )
              : Row(
                  spacing: _s8,
                  children: items.map((item) => Expanded(child: item)).toList(),
                ),
        ),
      ),
    );
  }

  /// The divider on the edge that faces the body.
  Border _getBorder() => switch (placement) {
    FoldNavigationPlacement.bottom => const Border(top: _dividerSide),
    FoldNavigationPlacement.left => const Border(right: _dividerSide),
    FoldNavigationPlacement.right => const Border(left: _dividerSide),
  };
}

/// A tab of the navigation, with a pill behind it while it is selected.
class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = isCompact ? _compactLabelStyle : _labelStyle;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: _animationDuration,
        padding: const EdgeInsets.symmetric(vertical: _s12, horizontal: _s4),
        decoration: BoxDecoration(
          color: isSelected ? _accentSoft : _accentSoftClear,
          borderRadius: _pillRadius,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: style.copyWith(color: isSelected ? _accent : _muted),
        ),
      ),
    );
  }
}

typedef _Session = ({
  String time,
  String title,
  String room,
  String speaker,
  Color color,
  String details,
});

/// The session streamed on the live page.
const _Session _liveSession = (
  time: '10:30',
  title: 'Layouts on foldables',
  room: 'Room A',
  speaker: 'Jonas Berg',
  color: Color(0xFF0EA5E9),
  details:
      'Panes on either side of the fold, navigation in the strip and '
      'dialogs that stay in one half. A tour of the layouts that make a '
      'foldable feel at home.',
);

/// The talk after lunch, which the live page reminds of.
const _Session _nextTalk = (
  time: '13:30',
  title: 'Testing on real devices',
  room: 'Room B',
  speaker: 'Priya Raman',
  color: Color(0xFF10B981),
  details:
      'Golden tests for every pose, and the things a simulator cannot tell '
      'you about a hinge.',
);

const List<_Session> _sessions = [
  (
    time: '09:00',
    title: 'Opening keynote',
    room: 'Main hall',
    speaker: 'Maja Nowak',
    color: Color(0xFF4F46E5),
    details:
        'What is new in the conference app, and where it goes next: one '
        'codebase for phones, tablets and devices that fold.',
  ),
  _liveSession,
  (
    time: '12:00',
    title: 'Lunch and demos',
    room: 'Second floor',
    speaker: 'Everyone',
    color: Color(0xFFF59E0B),
    details:
        'Food upstairs, and devices to try out at the demo tables until the '
        'afternoon sessions begin.',
  ),
  _nextTalk,
  (
    time: '15:00',
    title: 'Designing for two screens',
    room: 'Room A',
    speaker: 'Tomás Ortega',
    color: Color(0xFFF43F5E),
    details:
        'When a second pane helps, when it gets in the way, and how to decide '
        'with a breakpoint of your own.',
  ),
  (
    time: '16:30',
    title: 'Closing panel',
    room: 'Main hall',
    speaker: 'Lena Fischer',
    color: Color(0xFF8B5CF6),
    details:
        'Questions from the audience, and what we want to build next year.',
  ),
];

/// The day's sessions, with the selected one next to them where two panes fit.
class _SchedulePage extends StatefulWidget {
  const _SchedulePage();

  @override
  State<_SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<_SchedulePage> {
  var _selected = _sessions.indexOf(_liveSession);

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
      return ColoredBox(
        color: _gap,
        child: FoldSplitView(
          first: list,
          second: _SessionDetails(session: _sessions[_selected]),
          unfoldedBuilder: (context, first, second) => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: _sidePaneWidth, child: first),
              const ColoredBox(
                color: _outline,
                child: SizedBox(width: _dividerWidth),
              ),
              Expanded(child: second),
            ],
          ),
        ),
      );
    },
  );
}

/// The day's sessions under a heading.
class _SessionList extends StatelessWidget {
  const _SessionList({required this.selected, required this.onSelected});

  /// The session shown next to the list, if any.
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _background,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(_s16, _s24, _s16, _s16),
      itemCount: _sessions.length + 1,
      // A wider gap below the header than between the sessions.
      separatorBuilder: (context, index) =>
          SizedBox(height: index == 0 ? _s20 : _s4),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _ScheduleHeader();
        }

        final sessionIndex = index - 1;

        return _SessionTile(
          session: _sessions[sessionIndex],
          isSelected: sessionIndex == selected,
          onTap: () => onSelected(sessionIndex),
        );
      },
    ),
  );
}

/// The title of the schedule and its date.
class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: _s12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: _s4,
      children: [
        Text('Thursday, 12 November', style: _captionStyle),
        Text('Schedule', style: _displayStyle),
      ],
    ),
  );
}

/// A session in the list: its time, a bar in its colour, its title and room.
class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.isSelected,
    required this.onTap,
  });

  final _Session session;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: AnimatedContainer(
      duration: _animationDuration,
      padding: const EdgeInsets.all(_s12),
      decoration: BoxDecoration(
        color: isSelected ? _surface : _surfaceClear,
        borderRadius: _tileRadius,
        boxShadow: isSelected ? _cardShadow : _cardShadowClear,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: _s12,
          children: [
            SizedBox(
              width: _timeColumnWidth,
              child: Text(session.time, style: _captionStyle),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: session.color,
                borderRadius: _pillRadius,
              ),
              child: const SizedBox(width: _accentBarWidth),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: _s4,
                children: [
                  Text(session.title, style: _headingStyle),
                  Text(
                    '${session.room} · ${session.speaker}',
                    style: _captionStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Everything about the selected session.
class _SessionDetails extends StatelessWidget {
  const _SessionDetails({required this.session});

  final _Session session;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _surface,
    child: SafeArea(
      child: AnimatedSwitcher(
        duration: _animationDuration,
        child: ListView(
          key: ValueKey(session.title),
          padding: const EdgeInsets.all(_s32),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _Chip(
                label: '${session.time} · ${session.room}',
                color: session.color,
              ),
            ),
            const SizedBox(height: _s16),
            Text(session.title, style: _displayStyle),
            const SizedBox(height: _s8),
            Text('with ${session.speaker}', style: _captionStyle),
            const SizedBox(height: _s24),
            Text(session.details, style: _bodyStyle),
          ],
        ),
      ),
    ),
  );
}

/// A short label on a pill tinted with [color].
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: _chipTintAlpha),
      borderRadius: _pillRadius,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: _s12, vertical: _s4),
      child: Text(
        label,
        style: _captionStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

/// The session streamed right now, and actions that open dialogs in one half
/// of a split window.
class _LivePage extends StatelessWidget {
  const _LivePage();

  void _showDialog(
    BuildContext context, {
    required FoldAnchor anchor,
    required Widget child,
  }) => showGeneralDialog<void>(
    context: context,
    // Picks the half of a split window the dialog opens in.
    anchorPoint: anchor.resolvePoint(context),
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: _barrier,
    transitionDuration: _animationDuration,
    pageBuilder: (context, _, _) => child,
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _gap,
    child: FoldSplitView(
      first: const _LivePane(child: _NowPlayingCard()),
      second: _LivePane(
        child: _LiveActions(
          onRemind: () => _showDialog(
            context,
            anchor: FoldAnchor.content,
            child: const _ReminderDialog(),
          ),
          onOpenControls: () => _showDialog(
            context,
            anchor: FoldAnchor.controls,
            child: const _StreamControlsDialog(),
          ),
        ),
      ),
      unfoldedBuilder: (context, first, second) => ColoredBox(
        color: _background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [first, second],
          ),
        ),
      ),
    ),
  );
}

/// A part of the live page on its own background, so that the fold between
/// two parts shows.
class _LivePane extends StatelessWidget {
  const _LivePane({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _background,
    child: _NarrowCenter(child: child),
  );
}

/// Centres [child] and keeps it narrow.
class _NarrowCenter extends StatelessWidget {
  const _NarrowCenter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _paneMaxWidth),
      child: Padding(padding: const EdgeInsets.all(_s24), child: child),
    ),
  );
}

/// The session streamed right now.
class _NowPlayingCard extends StatelessWidget {
  const _NowPlayingCard();

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: _s12,
      children: [
        Row(
          spacing: _s8,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: _liveIndicator,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: _liveDotSize),
            ),
            Text('Live now · ${_liveSession.room}', style: _captionStyle),
          ],
        ),
        Text(_liveSession.title, style: _titleStyle),
        Text(_liveSession.speaker, style: _captionStyle),
        const _ProgressBar(value: _liveProgress),
      ],
    ),
  );
}

/// The actions of the live page: one opens a reminder, the other the
/// controls of the stream.
class _LiveActions extends StatelessWidget {
  const _LiveActions({required this.onRemind, required this.onOpenControls});

  final VoidCallback onRemind;
  final VoidCallback onOpenControls;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: _s12,
    children: [
      _Button(label: 'Remind me of the next talk', onTap: onRemind),
      _Button(
        label: 'Open stream controls',
        isPrimary: false,
        onTap: onOpenControls,
      ),
    ],
  );
}

/// Something to read and confirm, so it opens as [FoldAnchor.content].
class _ReminderDialog extends StatelessWidget {
  const _ReminderDialog();

  @override
  Widget build(BuildContext context) => _NarrowCenter(
    child: _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: _s16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: _s12,
            children: [
              const Text('Reminder set', style: _titleStyle),
              Text(
                '${_nextTalk.title} starts at ${_nextTalk.time} in '
                '${_nextTalk.room}. You will hear from us ten minutes before.',
                style: _bodyStyle,
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _Button(
              label: 'Done',
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Something to operate, so it opens as [FoldAnchor.controls].
class _StreamControlsDialog extends StatefulWidget {
  const _StreamControlsDialog();

  @override
  State<_StreamControlsDialog> createState() => _StreamControlsDialogState();
}

class _StreamControlsDialogState extends State<_StreamControlsDialog> {
  static const _streamLength = 100.0;

  var _position = _liveProgress * _streamLength;
  var _isPlaying = true;

  void _seekBy(int seconds) =>
      setState(() => _position = (_position + seconds).clamp(0, _streamLength));

  void _togglePlaying() => setState(() => _isPlaying = !_isPlaying);

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: SafeArea(
      child: _NarrowCenter(
        child: _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: _s16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: _s4,
                children: [
                  Text(_liveSession.title, style: _headingStyle),
                  Text('${_liveSession.room} · live', style: _captionStyle),
                ],
              ),
              _ProgressBar(value: _position / _streamLength),
              Row(
                spacing: _s8,
                children: [
                  Expanded(
                    child: _Button(
                      label: '−$_seekSeconds s',
                      isPrimary: false,
                      onTap: () => _seekBy(-_seekSeconds),
                    ),
                  ),
                  Expanded(
                    child: _Button(
                      label: _isPlaying ? 'Pause' : 'Play',
                      onTap: _togglePlaying,
                    ),
                  ),
                  Expanded(
                    child: _Button(
                      label: '+$_seekSeconds s',
                      isPrimary: false,
                      onTap: () => _seekBy(_seekSeconds),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A raised white surface with rounded corners.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: _surface,
      borderRadius: _cardRadius,
      boxShadow: _cardShadow,
    ),
    child: Padding(padding: const EdgeInsets.all(_s24), child: child),
  );
}

/// A pill-shaped button, filled with the accent colour when [isPrimary].
class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onTap,
    this.isPrimary = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: isPrimary ? _accent : _accentSoft,
        borderRadius: _pillRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _s24, vertical: _s12),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: _labelStyle.copyWith(color: isPrimary ? _onAccent : _accent),
        ),
      ),
    ),
  );
}

/// A thin track filled up to [value], between 0 and 1.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: _pillRadius,
    child: SizedBox(
      height: _progressBarHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: _outline),
          FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: value,
            child: const ColoredBox(color: _accent),
          ),
        ],
      ),
    ),
  );
}
