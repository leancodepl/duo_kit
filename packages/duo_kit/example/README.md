# duo_kit example

Lays plain widgets out with duo_kit: navigation that moves into the strip of
iPhone Duo, a list and its details on either side of the fold, and dialogs that
open in one half of a split window.

The parts of [`lib/main.dart`][main] that use duo_kit, trimmed:

```dart
// On iOS, duo_kit_ios publishes the fold, the camera and the status cluster to
// MediaQuery. In a debug build, FoldDebugTools simulates a fold on any device.
DuoKitIos(child: kDebugMode ? FoldDebugTools(child: app) : app)
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
// The list and its details on either side of the fold, in a row otherwise.
FoldSplitView(
  first: list,
  second: _SessionDetails(session: _sessions[_selected]),
  unfoldedBuilder: (context, first, second) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(width: _sidePaneWidth, child: first),
      Expanded(child: second),
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

Add the platforms you want to run it on, then run it:

```sh
flutter create --platforms=ios,android .
flutter run
```

On iPhone Duo, build with the iOS 27.1 SDK and raise the deployment target to
iOS 15.0, in the Runner target and in your pods, as the
[iPhone Duo setup][setup] describes.

[main]: https://github.com/leancodepl/duo_kit/blob/main/packages/duo_kit/example/lib/main.dart
[setup]: https://github.com/leancodepl/duo_kit/tree/main/packages/duo_kit#iphone-duo-setup
