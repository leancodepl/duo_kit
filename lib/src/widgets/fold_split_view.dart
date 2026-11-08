import 'package:duo_kit/src/geometry/fold_division.dart';
import 'package:duo_kit/src/geometry/fold_geometry.dart';
import 'package:flutter/widgets.dart';

/// Builds the layout of a [FoldSplitView] while no fold crosses it, from its
/// [first] and [second] panes.
typedef FoldSplitViewBuilder =
    Widget Function(BuildContext context, Widget first, Widget second);

/// Lays [first] and [second] out on either side of a fold that crosses this
/// widget, and in the layout from [unfoldedBuilder] otherwise.
///
/// A fold at an edge of this widget, with room on one side only, counts as no
/// fold.
///
/// The fold itself is left empty. Across a vertical fold [first] takes the
/// leading side; across a horizontal fold, the top. Each pane keeps only the
/// padding and the view insets, such as the keyboard, of the edges of this
/// widget it touches, and only the display features overlapping the pane, so
/// [FoldGeometry.of] finds no fold there and routes of a [Navigator] in the
/// pane open in it.
///
/// The panes keep their state when the fold comes and goes, as long as
/// [unfoldedBuilder] puts each of them in its layout once.
///
/// The fold comes from [FoldGeometry.of] in window coordinates. This widget
/// measures where it sits in the window after each build, resize or scroll of
/// the nearest [Scrollable], so it can be placed anywhere, such as below a top
/// bar or on a page of a [PageView], and catches up one frame later. A page
/// transition moves it with its page, laid out as where the page comes to
/// rest; on a route that rests elsewhere, such as a sheet, it catches up when
/// the transition ends. Any other move is picked up only at its next build.
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

  @override
  Widget build(BuildContext context) {
    final division = FoldGeometry.of(context).division;
    final first = KeyedSubtree(key: _firstKey, child: widget.first);
    final second = KeyedSubtree(key: _secondKey, child: widget.second);

    return _WindowLayoutBuilder(
      // Tracking the origin costs a rebuild for each move, so only while there
      // is a fold.
      tracksOrigin: division != null,
      builder: (context, origin, size) =>
          switch (_findLocalFold(division, origin: origin, size: size)) {
            final fold? => _SplitPanes(
              origin: origin,
              size: size,
              fold: fold.rect,
              axis: fold.axis,
              first: first,
              second: second,
            ),
            null => widget.unfoldedBuilder(context, first, second),
          },
    );
  }

  /// Finds the part of [division] that splits a widget of [size] placed at
  /// [origin] in the window, in the coordinates of that widget.
  ///
  /// Returns null without a fold, for an infinite [size], and for a fold that
  /// misses the widget or lies at one of its edges, with room on one side only.
  static _LocalFold? _findLocalFold(
    FoldDivision? division, {
    required Offset origin,
    required Size size,
  }) {
    if (division == null || !size.isFinite) {
      return null;
    }

    final bounds = Offset.zero & size;
    final fold = division.bounds.shift(-origin);
    final hasRoomOnBothSides = switch (division.axis) {
      Axis.vertical => fold.left > bounds.left && fold.right < bounds.right,
      Axis.horizontal => fold.top > bounds.top && fold.bottom < bounds.bottom,
    };
    if (!fold.overlaps(bounds) || !hasRoomOnBothSides) {
      return null;
    }

    return (rect: fold.intersect(bounds), axis: division.axis);
  }
}

/// A fold in the coordinates of a [FoldSplitView].
typedef _LocalFold = ({Rect rect, Axis axis});

/// A [LayoutBuilder] that also passes where it sits in the window.
///
/// While it [tracksOrigin], it measures where it sits a frame after each build,
/// resize or scroll of the nearest [Scrollable] and each start or end of a
/// transition of its route, and builds again if that moved.
class _WindowLayoutBuilder extends StatefulWidget {
  const _WindowLayoutBuilder({
    required this.tracksOrigin,
    required this.builder,
  });

  final bool tracksOrigin;
  final Widget Function(BuildContext context, Offset origin, Size size) builder;

  @override
  State<_WindowLayoutBuilder> createState() => _WindowLayoutBuilderState();
}

class _WindowLayoutBuilderState extends State<_WindowLayoutBuilder> {
  /// Where this widget sat in the window when it was last measured.
  var _origin = Offset.zero;

  /// The position of the nearest [Scrollable], which moves this widget without
  /// rebuilding or resizing it.
  ScrollPosition? _scrollPosition;

  /// The route holding this widget; its transitions move it without a rebuild.
  ModalRoute<Object?>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final scrollPosition = Scrollable.maybeOf(context)?.position;
    if (scrollPosition != _scrollPosition) {
      _scrollPosition?.removeListener(_scheduleOriginUpdate);
      _scrollPosition = scrollPosition?..addListener(_scheduleOriginUpdate);
    }

    final route = ModalRoute.of(context);
    if (route != _route) {
      _updateRouteListeners(_route, add: false);
      _updateRouteListeners(route, add: true);
      _route = route;
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_scheduleOriginUpdate);
    _updateRouteListeners(_route, add: false);
    super.dispose();
  }

  void _updateRouteListeners(ModalRoute<Object?>? route, {required bool add}) {
    for (final animation in [route?.animation, route?.secondaryAnimation]) {
      if (add) {
        animation?.addStatusListener(_onRouteStatusChanged);
      } else {
        animation?.removeStatusListener(_onRouteStatusChanged);
      }
    }
  }

  void _onRouteStatusChanged(AnimationStatus status) => _scheduleOriginUpdate();

  void _scheduleOriginUpdate() {
    if (widget.tracksOrigin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateOrigin());
    }
  }

  void _updateOrigin() {
    if (!mounted) {
      return;
    }

    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return;
    }

    final origin = _measureOrigin(box);
    // Unpainted kept-alive pages measure NaN and would rebuild every frame.
    if (origin.isFinite && origin != _origin) {
      setState(() => _origin = origin);
    }
  }

  /// Where [box] sits, or where it rests while its route moves or is covered.
  Offset _measureOrigin(RenderBox box) {
    final route = _route;
    final isRouteResting =
        (route?.animation?.isCompleted ?? true) &&
        (route?.secondaryAnimation?.isDismissed ?? true);
    final page = route?.subtreeContext?.findRenderObject();
    final overlay = route?.navigator?.overlay?.context.findRenderObject();
    if (isRouteResting || page is! RenderBox || overlay is! RenderBox) {
      return box.localToGlobal(Offset.zero);
    }

    // A transition moves the whole page from where the navigator lays it out.
    return overlay.localToGlobal(Offset.zero) +
        box.localToGlobal(Offset.zero, ancestor: page);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _scheduleOriginUpdate();

      return widget.builder(context, _origin, constraints.biggest);
    },
  );
}

/// Lays [first] and [second] out on either side of [fold] in a [FoldSplitView]
/// of [size] at [origin] in the window, leaving the fold empty.
class _SplitPanes extends StatelessWidget {
  const _SplitPanes({
    required this.origin,
    required this.size,
    required this.fold,
    required this.axis,
    required this.first,
    required this.second,
  });

  final Offset origin;
  final Size size;
  final Rect fold;
  final Axis axis;
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bounds = Offset.zero & size;

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
        _buildPane(mediaQuery, pane: firstRect, bounds: bounds, child: first),
        _buildPane(mediaQuery, pane: secondRect, bounds: bounds, child: second),
      ],
    );
  }

  /// Keeps the padding and the view insets, such as the keyboard, only on the
  /// edges of [bounds] the pane touches, and the display features overlapping
  /// the pane.
  Widget _buildPane(
    MediaQueryData mediaQuery, {
    required Rect pane,
    required Rect bounds,
    required Widget child,
  }) {
    final removeLeft = pane.left > bounds.left;
    final removeTop = pane.top > bounds.top;
    final removeRight = pane.right < bounds.right;
    final removeBottom = pane.bottom < bounds.bottom;

    // As in DisplayFeatureSubScreen, so routes in the pane skip the fold.
    final displayFeatures = mediaQuery.displayFeatures
        .where((feature) => feature.bounds.shift(-origin).overlaps(pane))
        .toList();

    return Positioned.fromRect(
      rect: pane,
      child: MediaQuery(
        data: mediaQuery
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
            )
            .copyWith(displayFeatures: displayFeatures),
        child: child,
      ),
    );
  }
}
