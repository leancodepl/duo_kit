# duo_kit example

Lays plain widgets out with duo_kit: navigation that moves into the strip of
iPhone Duo, a list and its details on either side of the fold, and dialogs that
open in one half of a split window.

The parts of [`lib/main.dart`][main] that use duo_kit, trimmed:

```dart
// On iOS, FoldBridge publishes the fold, the camera and the status cluster to
// MediaQuery. In a debug build, FoldDebugTools simulates a fold on any device.
FoldBridge(child: kDebugMode ? FoldDebugTools(child: app) : app)
```

```dart
// The navigation along the bottom edge, or in the strip of iPhone Duo.
FoldScaffold(
  body: SafeArea(bottom: false, child: page),
  navigationBuilder: (context, placement) => _NavigationBar(
    // A row at the bottom, a column in the strip.
    placement: placement,
    selected: _tab,
    onSelected: _selectTab,
  ),
)
```

```dart
// The list and its details on either side of the fold. Without a fold, in a
// row where both fit, and the list alone otherwise, with the details kept
// offstage so that neither pane loses its state at the breakpoint.
FoldSplitView(
  first: list,
  second: _SessionDetails(session: _sessions[_selected]),
  unfoldedBuilder: (context, first, second) => isWide
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: _sidePaneWidth, child: first),
            Expanded(child: second),
          ],
        )
      : Stack(
          fit: StackFit.expand,
          children: [
            first,
            Offstage(child: TickerMode(enabled: false, child: second)),
          ],
        ),
)
```

```dart
// A reminder opens above a horizontal fold; the stream controls open below it,
// with FoldAnchor.controls.
showGeneralDialog<void>(
  context: context,
  anchorPoint: FoldAnchor.content.resolvePoint(context),
  barrierDismissible: true,
  barrierLabel: 'Close',
  pageBuilder: (context, _, _) => const _ReminderDialog(),
)
```

## Running it

```sh
flutter run
```

The iOS project follows the [iPhone Duo setup][setup]; build it with Xcode 27.1
to see the fold. Add any other platform first, for example with
`flutter create --platforms=android .`.

[main]: https://github.com/leancodepl/duo_kit/blob/main/example/lib/main.dart
[setup]: https://github.com/leancodepl/duo_kit#iphone-duo-setup
