<div align="center">

[![Banner][banner-img]][leancode-landing]

</div>

# duo_kit

[![duo_kit pub.dev badge][pub-badge]][pub-badge-link]

Layouts for foldables such as iPhone Duo.

duo_kit works out where the system keeps room in the window – the strip for
its controls, the fold, the camera and the status cluster – and places your
widgets around it. It draws nothing itself and has no opinion on how your app
looks: the navigation, the panes and the dialogs are your own widgets.

![The example app on iPhone Duo: as the device opens like a book, the list and its details move to either side of the fold, and back when it lies flat][hero-img]

## Features

- **`FoldGeometry`** – the strip, the fold and the occlusions of the window,
  computed from `MediaQuery` alone.
- **`FoldScaffold`** – puts your navigation along the bottom edge or, where the
  window has a strip, in the strip, and pads the body to match.
- **`FoldSplitView`** – lays two panes out on either side of a fold, with your
  own layout while there is none, and keeps their state when the fold comes and
  goes.
- **`FoldAnchor`** – the `anchorPoint` that opens a dialog or a sheet in the
  right half of a window split by a fold.
- **Development tools** – simulate a fold on any device and see the geometry
  over your app.
- **Test poses** – the window metrics of every iPhone Duo pose, for widget and
  golden tests.

## Installation

```sh
flutter pub add duo_kit
```

## Where the geometry comes from

duo_kit reads only `MediaQuery.viewPadding` and `MediaQuery.displayFeatures`:

- **Android** – Flutter fills the display features of a foldable by itself.
- **iOS** – nothing fills them yet. Publish the fold and the camera with a
  plugin that reads the reserved regions of the window, such as
  [`foldable`][foldable] with `DisplayFeatureBridgeMode.full`:

  ```dart
  FoldableProvider(
    bridgeMode: DisplayFeatureBridgeMode.full,
    child: app,
  )
  ```

  Place it above your app, so that overlays outside the navigator see the fold
  too. While the device is closed, `foldable` publishes nothing; to keep the
  strip of the cover display clear of the status cluster, add its occlusions
  yourself, as [`ClosedFoldOcclusions`][closed-fold-occlusions] in the example
  does.

  With the fold published, Flutter keeps dialogs, sheets and pickers on one side
  of it while the device is half open, as it does on Android.

## iPhone Duo setup

- **Build with the iOS 27.1 SDK** (Xcode 27.1). With an older SDK, iOS runs the
  app in compatibility mode, with no strip and no reserved regions.
- **Adopt the UIScene life cycle.** With the iOS 27 SDK an app without it
  crashes at launch. Projects created with Flutter 3.41 already have it; in an
  older one, make your `AppDelegate` a `FlutterImplicitEngineDelegate`,
  register plugins in `didInitializeImplicitFlutterEngine`, and add a
  `UIApplicationSceneManifest` with `FlutterSceneDelegate` to `Info.plist`.
- **Target iOS 15.0 or later**, in the Runner target and in your pods. Xcode 27
  rejects lower deployment targets, and the Flutter 3.41 template still sets
  13.0.
- **Do not lock the orientation on a device with a hinge.** iOS then scales the
  app instead of laying it out, and reports no fold. On the simulator this
  sticks to the bundle ID until the simulator reboots.

## Usage

### Navigation

```dart
FoldScaffold(
  body: SafeArea(bottom: false, child: page),
  navigationBuilder: (context, placement) => MyNavigationBar(
    // Lay the items out along placement.axis: a row at the bottom, a column
    // in the strip.
    axis: placement.axis,
  ),
)
```

The navigation gets the `MediaQuery` padding of where it sits – the bottom
inset, or in the strip the room taken by the camera and the status cluster – so
a `SafeArea` inside it keeps it clear. The body stays the same widget in every
pose and keeps its state.

![The navigation in the strip of the cover display, below the status cluster, and along the bottom edge of the inner display in portrait][navigation-img]

In a strip, `placement` is `left` or `right`, the side the strip runs along. On
iPhone Duo it is `right`. Put whatever faces the content, such as a divider or a
selection indicator, on the edge towards the body.

### Two panes

```dart
FoldSplitView(
  first: list,
  second: details,
  unfoldedBuilder: (context, first, second) => Row(
    children: [
      SizedBox(width: 320, child: first),
      Expanded(child: second),
    ],
  ),
)
```

While a fold crosses it, `FoldSplitView` puts `first` on the leading side of a
vertical fold or above a horizontal one, and `second` on the other side. Each
pane keeps only the padding and the view insets, such as the keyboard, of the
edges it touches. Without a fold it uses your layout; put each pane in it once.
Decide when two panes fit with your own breakpoint.

A pane your layout leaves out loses its state. To keep it, hide it instead:

```dart
unfoldedBuilder: (context, first, second) => Stack(
  fit: StackFit.expand,
  children: [
    first,
    Offstage(child: TickerMode(enabled: false, child: second)),
  ],
),
```

### Dialogs and sheets

```dart
showDialog(
  context: context,
  anchorPoint: FoldAnchor.content.resolvePoint(context),
  builder: (context) => const MyDialog(),
);
```

`FoldAnchor.content` opens above a horizontal fold, `FoldAnchor.controls` below
it; across a vertical fold both open on the trailing side. Overlays that are not
routes can do the same with `DisplayFeatureSubScreen`.

<img src="https://raw.githubusercontent.com/leancodepl/duo_kit/refs/heads/main/doc/imgs/dialogs.gif" width="360" alt="iPhone Duo half open like a laptop: a reminder opens above the fold as content, and stream controls below it as controls">

### Geometry

```dart
final geometry = FoldGeometry.of(context);

geometry.strip; // The strip at the side, with the clearances of its occlusions.
geometry.division; // The fold that splits the window, if any.
geometry.occlusions; // Cameras and the status cluster.
geometry.availableWidth; // The width without the side insets.
```

![The geometry of four iPhone Duo poses, painted over the example app][geometry-img]

The cover display and the inner display lying flat, then half open like a book
and like a laptop, as `FoldGeometryOverlay` paints them: the strip in blue, the
camera and the status cluster in orange, and the fold in red.

### Development tools

```dart
import 'package:duo_kit/debug.dart';

kDebugMode ? FoldDebugTools(child: app) : app
```

A button at the left edge switches between poses – a strip, a fold like a book,
a fold like a laptop – on any device, and holding it shows or hides the geometry
over your app. Place it below whatever publishes the real fold.

### Tests

```dart
import 'package:duo_kit/testing.dart';

MediaQuery(data: FoldTestPose.duoHalfOpenedLandscape.data, child: screen)
```


## Limitations

- A strip is looked for on iOS only, since an Android phone in landscape can
  report the same insets for its camera cutout. Pass `detectStrip` to change
  that.
- Apple's [guidelines for iPhone Duo][hig-duo] put the strip on the left for
  the app on the left of Split View, but iOS 27.1 reports no strip to a Flutter
  app there, so its navigation stays at the bottom.
- `FoldSplitView` measures where it sits after it builds, resizes or scrolls,
  and catches up one frame later.
- With `foldable`, the fold reaches the display features about a second after
  the device comes to rest half open, since the reserved regions follow the
  hinge with a delay.
- Tested on the iPhone Duo simulator. Android foldables follow from the same
  display features, but have not been tested on a device.

---

## 🛠️ Maintained by LeanCode

<div align="center">

  [<img src="https://leancodepublic.blob.core.windows.net/public/wide.png" alt="LeanCode Logo" height="100" />][leancode-landing]

</div>

This package is built with 💙 by **[LeanCode][leancode-landing]**.
We are **top-tier experts** focused on Flutter Enterprise solutions.

### Why LeanCode?

- **Creators of [Patrol][patrol-landing]** – the next-gen testing framework for Flutter.
- **Full-Cycle Product Development** – We take your product from scratch to long-term maintenance.

<div align="center">
  <br />

  **Need help with your Flutter project?**

  [**👉 Hire our team**][leancode-estimate]
  &nbsp;&nbsp;•&nbsp;&nbsp;
  [Check our other packages][leancode-packages]

</div>

[pub-badge]: https://img.shields.io/pub/v/duo_kit
[pub-badge-link]: https://pub.dev/packages/duo_kit
[banner-img]: https://raw.githubusercontent.com/leancodepl/duo_kit/refs/heads/main/doc/imgs/banner.png
[hero-img]: https://raw.githubusercontent.com/leancodepl/duo_kit/refs/heads/main/doc/imgs/hero.gif
[navigation-img]: https://raw.githubusercontent.com/leancodepl/duo_kit/refs/heads/main/doc/imgs/navigation.png
[geometry-img]: https://raw.githubusercontent.com/leancodepl/duo_kit/refs/heads/main/doc/imgs/geometry.png
[foldable]: https://pub.dev/packages/foldable
[hig-duo]: https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo
[closed-fold-occlusions]: https://github.com/leancodepl/duo_kit/blob/main/example/lib/closed_fold_occlusions.dart
[leancode-landing]: https://leancode.co/?utm_source=github.com&utm_medium=referral&utm_campaign=duo-kit
[leancode-estimate]: https://leancode.co/get-estimate?utm_source=github.com&utm_medium=referral&utm_campaign=duo-kit
[leancode-packages]: https://pub.dev/packages?q=publisher%3Aleancode.co&sort=downloads
[patrol-landing]: https://patrol.leancode.co/?utm_source=github.com&utm_medium=referral&utm_campaign=duo-kit
