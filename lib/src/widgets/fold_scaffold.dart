import 'dart:math' as math;

import 'package:duo_kit/src/bridge/fold_vertical_bar_edge.dart';
import 'package:duo_kit/src/geometry/fold_geometry.dart';
import 'package:duo_kit/src/geometry/fold_strip.dart';
import 'package:flutter/widgets.dart';

/// Where a [FoldScaffold] puts its navigation.
enum FoldNavigationPlacement {
  /// Along the bottom edge of the window.
  bottom,

  /// In a strip along the left edge, as on the cover display of iPhone Duo in
  /// landscape with the camera on the left.
  left,

  /// In a strip along the right edge.
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
/// Where the system wants its vertical bar on an edge with no room for it, as
/// on the left of Split View, the navigation takes [verticalBarWidth] there.
///
/// Draws nothing itself. The navigation gets the [MediaQuery] padding of the
/// area it sits in: the bottom inset at the bottom, and in the strip the
/// clearances of the camera and status cluster plus the bottom inset. The
/// body loses the padding of the edge the navigation takes. While the keyboard
/// covers the navigation at the bottom, the body reaches behind it, so a
/// `Scaffold` in the body ends above the keyboard and the navigation.
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
    this.verticalBarWidth = defaultVerticalBarWidth,
  });

  /// The width of the strip the system keeps on iPhone Duo.
  static const defaultVerticalBarWidth = 84.0;

  /// The content next to the navigation.
  final Widget body;

  /// Builds the navigation for where it goes.
  final FoldNavigationBuilder navigationBuilder;

  /// See [FoldGeometry.of]. Does not turn off [verticalBarWidth].
  final bool? detectStrip;

  /// The width of the navigation on the edge of [FoldGeometry.verticalBarEdge]
  /// where the window has no strip, or null to keep it at the bottom there.
  final double? verticalBarWidth;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final geometry = FoldGeometry.of(context, detectStrip: detectStrip);
    final strip =
        geometry.strip ??
        _getVerticalBarStrip(geometry, Directionality.of(context));

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
      null => mediaQuery.removePadding(removeTop: true),
    };

    // The same children in every pose, so the body keeps its state when the
    // navigation moves.
    return CustomMultiChildLayout(
      delegate: _FoldScaffoldLayout(
        placement: placement,
        strip: strip,
        keyboardHeight: mediaQuery.viewInsets.bottom,
      ),
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

  /// A strip for the vertical bar where the window has no room for it.
  FoldStrip? _getVerticalBarStrip(
    FoldGeometry geometry,
    TextDirection direction,
  ) {
    final side = switch ((geometry.verticalBarEdge, direction)) {
      (FoldVerticalBarEdge.unspecified, _) => null,
      (FoldVerticalBarEdge.leading, TextDirection.ltr) ||
      (FoldVerticalBarEdge.trailing, TextDirection.rtl) => FoldStripSide.left,
      (FoldVerticalBarEdge.leading, TextDirection.rtl) ||
      (FoldVerticalBarEdge.trailing, TextDirection.ltr) => FoldStripSide.right,
    };

    // While the device folds or rotates, the edge can change a moment before
    // the window does. No window with a vertical bar has a top inset.
    final EdgeInsets(:left, :right, :top) = geometry.viewPadding;
    final hasRoom = switch (side) {
      FoldStripSide.left => left > 0,
      FoldStripSide.right => right > 0,
      null => true,
    };
    final width = verticalBarWidth;
    if (side == null || width == null || hasRoom || top > 0) {
      return null;
    }

    final size = geometry.size;

    return FoldStrip(
      side: side,
      rect: switch (side) {
        FoldStripSide.left => Rect.fromLTWH(0, 0, width, size.height),
        FoldStripSide.right => Rect.fromLTWH(
          size.width - width,
          0,
          width,
          size.height,
        ),
      },
      topClearance: 0,
      bottomClearance: 0,
      isClearanceEstimated: false,
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
  _FoldScaffoldLayout({
    required this.placement,
    required this.strip,
    required this.keyboardHeight,
  });

  final FoldNavigationPlacement placement;
  final FoldStrip? strip;
  final double keyboardHeight;

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
        // The body takes back the part of the navigation the keyboard covers.
        final bodyHeight =
            size.height - math.max(0.0, navigation.height - keyboardHeight);

        layoutChild(
          _FoldScaffoldSlot.body,
          BoxConstraints.tight(Size(size.width, bodyHeight)),
        );
        positionChild(_FoldScaffoldSlot.body, Offset.zero);
        positionChild(
          _FoldScaffoldSlot.navigation,
          Offset(0, size.height - navigation.height),
        );
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
      oldDelegate.placement != placement ||
      oldDelegate.strip != strip ||
      oldDelegate.keyboardHeight != keyboardHeight;
}
