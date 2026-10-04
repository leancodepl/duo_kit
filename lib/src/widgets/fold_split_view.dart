import 'package:duo_kit/src/geometry/fold_geometry.dart';
import 'package:flutter/widgets.dart';

/// Builds the layout of a [FoldSplitView] while no fold crosses it, from its
/// [first] and [second] panes.
typedef FoldSplitViewBuilder =
    Widget Function(BuildContext context, Widget first, Widget second);

/// Lays [first] and [second] out on either side of a fold that crosses this
/// widget, and in the layout from [unfoldedBuilder] otherwise.
///
/// The fold itself is left empty. Across a vertical fold [first] takes the
/// leading side; across a horizontal fold, the top. Each pane keeps only the
/// padding and the view insets, such as the keyboard, of the edges of this
/// widget it touches.
///
/// The panes keep their state when the fold comes and goes, as long as
/// [unfoldedBuilder] puts each of them in its layout once.
///
/// The fold comes from [FoldGeometry.of] in window coordinates. This widget
/// measures where it sits in the window after each build, resize or scroll of
/// the nearest [Scrollable], so it can be placed anywhere, such as below a top
/// bar or on a page of a [PageView], and catches up one frame later. Any other
/// move is picked up only at its next build.
///
/// Needs bounded constraints; with unbounded ones it uses [unfoldedBuilder].
class FoldSplitView extends StatefulWidget {
  /// Creates a split view.
  const FoldSplitView({
    super.key,
    required this.first,
    required this.second,
    required this.unfoldedBuilder,
  });

  /// The pane on the leading side of a vertical fold or above a horizontal
  /// one.
  final Widget first;

  /// The pane on the other side of the fold.
  final Widget second;

  /// Lays the panes out while no fold crosses this widget.
  ///
  /// Put each pane it gets in the tree at most once: they carry global keys,
  /// which is how they keep their state between the two layouts.
  final FoldSplitViewBuilder unfoldedBuilder;

  @override
  State<FoldSplitView> createState() => _FoldSplitViewState();
}

class _FoldSplitViewState extends State<FoldSplitView> {
  final _firstKey = GlobalKey(debugLabel: 'FoldSplitView.first');
  final _secondKey = GlobalKey(debugLabel: 'FoldSplitView.second');

  /// Where this widget sat in the window when it was last measured.
  var _origin = Offset.zero;

  /// Whether a fold was in the window at the last build.
  var _hasDivision = false;

  /// The position of the nearest [Scrollable], which moves this widget without
  /// rebuilding or resizing it.
  ScrollPosition? _scrollPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final scrollPosition = Scrollable.maybeOf(context)?.position;
    if (scrollPosition != _scrollPosition) {
      _scrollPosition?.removeListener(_scheduleSync);
      _scrollPosition = scrollPosition?..addListener(_scheduleSync);
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_scheduleSync);
    super.dispose();
  }

  /// Measures again after the frame in which a scroll moved this widget, as
  /// long as there is a fold to follow.
  void _scheduleSync() {
    if (_hasDivision) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncOrigin());
    }
  }

  void _syncOrigin() {
    if (!mounted) {
      return;
    }

    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return;
    }

    final origin = box.localToGlobal(Offset.zero);
    if (origin != _origin) {
      setState(() => _origin = origin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final division = FoldGeometry.of(context).division;
    _hasDivision = division != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (division != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _syncOrigin());
        }

        final bounds = Offset.zero & constraints.biggest;
        final localFold = division?.bounds.shift(-_origin);
        final first = KeyedSubtree(key: _firstKey, child: widget.first);
        final second = KeyedSubtree(key: _secondKey, child: widget.second);

        return switch ((division?.axis, localFold)) {
          (final axis?, final fold?)
              when bounds.isFinite && fold.overlaps(bounds) =>
            _buildSplit(
              context,
              bounds: bounds,
              fold: fold.intersect(bounds),
              axis: axis,
              first: first,
              second: second,
            ),
          _ => widget.unfoldedBuilder(context, first, second),
        };
      },
    );
  }

  Widget _buildSplit(
    BuildContext context, {
    required Rect bounds,
    required Rect fold,
    required Axis axis,
    required Widget first,
    required Widget second,
  }) {
    final (leading, trailing) = switch (axis) {
      Axis.vertical => (
        Rect.fromLTRB(bounds.left, bounds.top, fold.left, bounds.bottom),
        Rect.fromLTRB(fold.right, bounds.top, bounds.right, bounds.bottom),
      ),
      Axis.horizontal => (
        Rect.fromLTRB(bounds.left, bounds.top, bounds.right, fold.top),
        Rect.fromLTRB(bounds.left, fold.bottom, bounds.right, bounds.bottom),
      ),
    };

    final isFirstOnRight =
        axis == Axis.vertical &&
        Directionality.of(context) == TextDirection.rtl;
    final (firstRect, secondRect) = isFirstOnRight
        ? (trailing, leading)
        : (leading, trailing);

    return Stack(
      children: [
        _buildPane(context, pane: firstRect, bounds: bounds, child: first),
        _buildPane(context, pane: secondRect, bounds: bounds, child: second),
      ],
    );
  }

  /// Keeps the padding and the view insets, such as the keyboard, only on the
  /// edges of this widget the pane touches.
  Widget _buildPane(
    BuildContext context, {
    required Rect pane,
    required Rect bounds,
    required Widget child,
  }) {
    final removeLeft = pane.left > bounds.left;
    final removeTop = pane.top > bounds.top;
    final removeRight = pane.right < bounds.right;
    final removeBottom = pane.bottom < bounds.bottom;

    return Positioned.fromRect(
      rect: pane,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .removePadding(
              removeLeft: removeLeft,
              removeTop: removeTop,
              removeRight: removeRight,
              removeBottom: removeBottom,
            )
            .removeViewInsets(
              removeLeft: removeLeft,
              removeTop: removeTop,
              removeRight: removeRight,
              removeBottom: removeBottom,
            ),
        child: child,
      ),
    );
  }
}
