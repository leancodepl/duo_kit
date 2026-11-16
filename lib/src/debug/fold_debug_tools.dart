import 'package:duo_kit/src/debug/fold_geometry_overlay.dart';
import 'package:duo_kit/src/debug/simulated_fold.dart';
import 'package:flutter/widgets.dart';

/// Development tools for fold layouts: a [SimulatedFold] and a
/// [FoldGeometryOverlay] over [child], with a button at the left edge of the
/// window to control them.
///
/// Tapping the button switches to the next [FoldSimulation]; holding it shows
/// or hides the overlay. Place it where it covers the whole window, below
/// whatever publishes the real fold, so that the simulation replaces it.
class FoldDebugTools extends StatefulWidget {
  /// Creates the tools.
  const FoldDebugTools({
    super.key,
    this.initialSimulation = FoldSimulation.off,
    this.initiallyShowsOverlay = true,
    required this.child,
  });

  /// The pose to simulate at first.
  final FoldSimulation initialSimulation;

  /// Whether the overlay shows at first.
  final bool initiallyShowsOverlay;

  /// The app.
  final Widget child;

  @override
  State<FoldDebugTools> createState() => _FoldDebugToolsState();
}

class _FoldDebugToolsState extends State<FoldDebugTools> {
  late var _simulation = widget.initialSimulation;
  late var _showsOverlay = widget.initiallyShowsOverlay;

  static const _buttonColor = Color(0xCC000000);
  static const _buttonTextStyle = TextStyle(
    color: Color(0xFFFFFFFF),
    fontSize: 12,
  );
  static const _buttonPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 6,
  );
  static const _buttonRadius = BorderRadius.all(Radius.circular(12));
  static const _buttonEdgeInset = 4.0;

  void _selectNextSimulation() => setState(
    () => _simulation = FoldSimulation
        .values[(_simulation.index + 1) % FoldSimulation.values.length],
  );

  void _toggleOverlay() => setState(() => _showsOverlay = !_showsOverlay);

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.centerLeft,
    textDirection: TextDirection.ltr,
    children: [
      Positioned.fill(
        child: SimulatedFold(
          simulation: _simulation,
          child: FoldGeometryOverlay(
            enabled: _showsOverlay,
            child: widget.child,
          ),
        ),
      ),
      Positioned(
        left: _buttonEdgeInset,
        child: GestureDetector(
          onTap: _selectNextSimulation,
          onLongPress: _toggleOverlay,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: _buttonColor,
              borderRadius: _buttonRadius,
            ),
            child: Padding(
              padding: _buttonPadding,
              child: Text(
                'Fold: ${_simulation.name}',
                textDirection: TextDirection.ltr,
                style: _buttonTextStyle,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
