import 'dart:math' as math;

import 'package:duo_kit/src/geometry/fold_geometry.dart';
import 'package:duo_kit/src/geometry/fold_strip.dart';
import 'package:flutter/widgets.dart';

/// Where a [FoldScaffold] puts its navigation.
enum FoldNavigationPlacement {
  /// Along the bottom edge of the window.
  bottom,

  /// In the strip the system keeps along the left edge.
  ///
  /// iPhone Duo keeps its strip on the right; see [FoldStrip].
  left,

  /// In the strip the system keeps along the right edge.
  right;

  /// The direction to lay the navigation items out in.
  Axis get axis => switch (this) {
    bottom => Axis.horizontal,
    left || right => Axis.vertical,
  };
}

/// Builds the navigation of a [FoldScaffold] for [placement].
typedef FoldNavigationBuilder =
    Widget Function(BuildContext context, FoldNavigationPlacement placement);

/// Lays [body] out with the navigation from [navigationBuilder] either along
/// the bottom edge or, where the window has a [FoldStrip], in that strip.
///
/// Draws nothing itself. The navigation gets the [MediaQuery] padding of the
/// area it sits in: the bottom inset at the bottom, and in the strip the
/// clearances of the camera and status cluster plus the bottom inset. The
/// body loses the padding of the edge the navigation takes.
///
/// Its left and right edges must meet the edges of the window, which is where
/// a strip lies.
class FoldScaffold extends StatelessWidget {
  /// Creates a scaffold.
  const FoldScaffold({
    super.key,
    required this.body,
    required this.navigationBuilder,
    this.detectStrip,
  });

  /// The content next to the navigation.
  final Widget body;

  /// Builds the navigation for where it goes.
  final FoldNavigationBuilder navigationBuilder;

  /// See [FoldGeometry.of].
  final bool? detectStrip;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final strip = FoldGeometry.of(context, detectStrip: detectStrip).strip;

    final placement = switch (strip?.side) {
      FoldStripSide.left => FoldNavigationPlacement.left,
      FoldStripSide.right => FoldNavigationPlacement.right,
      null => FoldNavigationPlacement.bottom,
    };
    final bodyData = mediaQuery.removePadding(
      removeLeft: placement == FoldNavigationPlacement.left,
      removeRight: placement == FoldNavigationPlacement.right,
      removeBottom: placement == FoldNavigationPlacement.bottom,
    );
    final navigationData = switch (strip) {
      final strip? => _getStripData(mediaQuery, strip),
      null => mediaQuery,
    };

    // The same children in every pose, so the body keeps its state when the
    // navigation moves.
    return CustomMultiChildLayout(
      delegate: _FoldScaffoldLayout(placement: placement, strip: strip),
      children: [
        LayoutId(
          id: _FoldScaffoldSlot.body,
          child: MediaQuery(data: bodyData, child: body),
        ),
        LayoutId(
          id: _FoldScaffoldSlot.navigation,
          child: MediaQuery(
            data: navigationData,
            child: navigationBuilder(context, placement),
          ),
        ),
      ],
    );
  }

  MediaQueryData _getStripData(MediaQueryData mediaQuery, FoldStrip strip) {
    final padding = EdgeInsets.only(
      top: strip.topClearance,
      bottom: math.max(strip.bottomClearance, mediaQuery.viewPadding.bottom),
    );

    return mediaQuery.copyWith(padding: padding, viewPadding: padding);
  }
}

enum _FoldScaffoldSlot { body, navigation }

class _FoldScaffoldLayout extends MultiChildLayoutDelegate {
  _FoldScaffoldLayout({required this.placement, required this.strip});

  final FoldNavigationPlacement placement;
  final FoldStrip? strip;

  @override
  void performLayout(Size size) {
    final stripWidth = strip?.width ?? 0;

    switch (placement) {
      case FoldNavigationPlacement.bottom:
        final navigation = layoutChild(
          _FoldScaffoldSlot.navigation,
          BoxConstraints(
            minWidth: size.width,
            maxWidth: size.width,
            maxHeight: size.height,
          ),
        );
        final bodyHeight = size.height - navigation.height;

        layoutChild(
          _FoldScaffoldSlot.body,
          BoxConstraints.tight(Size(size.width, bodyHeight)),
        );
        positionChild(_FoldScaffoldSlot.body, Offset.zero);
        positionChild(_FoldScaffoldSlot.navigation, Offset(0, bodyHeight));
      case FoldNavigationPlacement.left || FoldNavigationPlacement.right:
        final isLeft = placement == FoldNavigationPlacement.left;
        final bodySize = Size(size.width - stripWidth, size.height);

        layoutChild(
          _FoldScaffoldSlot.navigation,
          BoxConstraints.tight(Size(stripWidth, size.height)),
        );
        layoutChild(_FoldScaffoldSlot.body, BoxConstraints.tight(bodySize));
        positionChild(
          _FoldScaffoldSlot.navigation,
          Offset(isLeft ? 0 : bodySize.width, 0),
        );
        positionChild(
          _FoldScaffoldSlot.body,
          Offset(isLeft ? stripWidth : 0, 0),
        );
    }
  }

  @override
  bool shouldRelayout(_FoldScaffoldLayout oldDelegate) =>
      oldDelegate.placement != placement || oldDelegate.strip != strip;
}
