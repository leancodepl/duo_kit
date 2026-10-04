import 'package:flutter/widgets.dart';

/// Which half of a window split by a fold a route opens in, given as the
/// `anchorPoint` of [showGeneralDialog] and the routes built like it, such as
/// `showDialog` and `showModalBottomSheet`.
///
/// Across a vertical fold, as on a device half open like a book, the route
/// opens in the trailing half. Across a horizontal fold, as on a device half
/// open like a laptop, [content] opens in the upper half and [controls] in the
/// lower one. Without a fold the anchor changes nothing.
///
/// The point is a corner of the window, not a spot measured from the fold. A
/// route keeps the point it was opened with and finds its half again on every
/// change of the [MediaQuery], so a route opened while the device lies flat
/// moves to its half once the device folds.
enum FoldAnchor {
  /// Something to read or confirm, such as an alert.
  content,

  /// Something to operate, such as a sheet of actions or media controls.
  controls;

  /// The anchor point for a route opened from [context].
  Offset resolvePoint(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // Routes cap the point to the window, as they do with their own default
    // point in right-to-left text.
    final dx = isRtl ? 0.0 : double.maxFinite;
    final dy = switch (this) {
      content => 0.0,
      controls => double.maxFinite,
    };

    return Offset(dx, dy);
  }
}
