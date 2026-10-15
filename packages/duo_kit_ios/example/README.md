# duo_kit_ios example

To run the [duo_kit example][example] with duo_kit_ios, wrap its app in
`DuoKitIos` in place of `FoldableProvider` and `ClosedFoldOcclusions`. duo_kit
then lays it out around the fold, the camera and the status cluster that the
plugin publishes:

```dart
@override
Widget build(BuildContext context) {
  final app = WidgetsApp(/* … */);

  // On iOS the fold reaches the display features only through a bridge.
  return DuoKitIos(child: kDebugMode ? FoldDebugTools(child: app) : app);
}
```

Read the hinge and the edge of the vertical bar anywhere below it:

```dart
final hinge = DuoKitIos.hingeOf(context);
final isLikeALaptop = hinge?.status == FoldHingeStatus.partiallyOpen;

final edge = DuoKitIos.verticalBarEdgeOf(context);
```

[example]: https://github.com/leancodepl/duo_kit/tree/main/packages/duo_kit/example
