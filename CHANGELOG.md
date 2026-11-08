## 0.2.0

- duo_kit is now a Flutter plugin. On iOS, `FoldBridge` publishes the fold, the camera and the status cluster of iPhone Duo to `MediaQuery.displayFeatures`, the closed device included. Wrap the app in one: `runApp(const FoldBridge(child: MyApp()))`. On other platforms, on devices without a hinge and without the plugin, as in tests, it passes its child through.
- `FoldHinge.maybeOf` gives the status and the angle of the hinge, and `FoldGeometry.verticalBarEdge` the edge where the system wants its vertical bar.
- `FoldScaffold` puts the navigation on the edge of the vertical bar where the window has no strip, as on the left of Split View, `verticalBarWidth` wide. Pass `null` to keep it at the bottom there.
- `FoldScaffold` counts the keyboard once: a `Scaffold` in the body ends above the keyboard and the navigation at the bottom, as above a Material `bottomNavigationBar`, instead of a navigation's height higher.
- `FoldSplitView`:
  - Each pane keeps only the display features that overlap it, so a `Navigator` in a pane opens its dialogs and sheets in the pane instead of with no size. `FoldGeometry.of` in a pane finds no fold.
  - Splits in place after a route above it closes, also when it built while covered, and during a page transition is laid out as where its page comes to rest.
  - Stops rebuilding on every frame on a kept-alive page out of view.
- `FoldBridgeScope` in `package:duo_kit/testing.dart` fakes the hinge and the vertical bar edge in tests, and `FoldTestPose.duoInnerSplitViewLeft` is the window on the left of Split View.

### Migrating from 0.1

- Replace `FoldableProvider` from `foldable`, and occlusions added by hand for the closed device, with one `FoldBridge` above the app.
- The bridge needs Xcode 27.1 (Swift 6.4); with an older Xcode it compiles to nothing. The plugin supports iOS 13.0 and later, like Flutter.
- Read `FoldGeometry.of(context).division` above a `FoldSplitView`, not in its panes.
- From `duo_kit_ios`: `DuoKitIos` is now `FoldBridge`, `DuoKitIos.hingeOf` is `FoldHinge.maybeOf` and `DuoKitIos.verticalBarEdgeOf` is `FoldGeometry.of(context).verticalBarEdge`.

## 0.1.2

- `FoldScaffold` no longer gives a navigation along the bottom edge the top inset, so a `SafeArea` in it adds no space above it.

## 0.1.1

- The README and the example publish the fold on iOS with `foldable`.

## 0.1.0

- Initial release: `FoldGeometry`, `FoldScaffold`, `FoldSplitView` and `FoldAnchor`.
- `FoldScaffold` puts the navigation along the bottom edge or in the strip of the window, on the side `FoldStrip.side` reports.
- Development tools in `package:duo_kit/debug.dart`: `FoldDebugTools`, `SimulatedFold` and `FoldGeometryOverlay`.
- iPhone Duo poses for tests in `package:duo_kit/testing.dart`: `FoldTestPose`.
