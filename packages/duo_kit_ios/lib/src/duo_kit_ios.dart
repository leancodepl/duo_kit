import 'package:flutter/widgets.dart';

/// Publishes what iPhone Duo reports natively to the widgets below, for
/// duo_kit to lay them out by.
///
/// Place it above the app, so that overlays outside the navigator see it too.
///
/// In development: for now it passes [child] through, and the fold still has
/// to come from another source, such as the `foldable` package.
class DuoKitIos extends StatelessWidget {
  /// Creates the bridge.
  const DuoKitIos({super.key, required this.child});

  /// The app.
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
