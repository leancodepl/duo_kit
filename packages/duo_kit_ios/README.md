# duo_kit_ios

The iOS side of [duo_kit][duo-kit]: what iPhone Duo reports natively, published
to Flutter.

**In development, not on pub.dev yet.**

duo_kit lays your widgets out around the strip, the fold and the occlusions of
the window, which it reads from `MediaQuery`. On iOS nothing puts the fold or
the occlusions there. This plugin does, and also reports what `MediaQuery` has
no room for.

## What it publishes

- **The fold**, in `MediaQuery.displayFeatures`, as soon as the hinge is partly
  open. duo_kit's `FoldSplitView` and Flutter's dialogs split at it.
- **The camera and the status cluster**, as cutouts, in every pose, the closed
  device included, so that a strip keeps clear of them.
- **The hinge**: `DuoKitIos.hingeOf(context)` gives its status and its angle.
- **The edge of the vertical bar**: `DuoKitIos.verticalBarEdgeOf(context)`
  tells where the system wants the strip, even where it gives the app no room
  for it, as on the left of Split View.

## Usage

```sh
flutter pub add duo_kit duo_kit_ios
```

```dart
runApp(const DuoKitIos(child: MyApp()));
```

Place `DuoKitIos` above your app, so that overlays outside the navigator see
the fold too. On other platforms it passes its child through, and duo_kit keeps
working from what the platform reports.

```dart
final hinge = DuoKitIos.hingeOf(context);
if (hinge?.status == FoldHingeStatus.partiallyOpen) {
  // Half open, like a book or a laptop.
}
```

Prefer the status to the angle: the system decides how often and how precisely
it updates the angle.

## Requirements

- The [iPhone Duo setup][setup] that duo_kit describes: the iOS 27.1 SDK, the
  UIScene life cycle, iOS 15.0 as the deployment target, and no orientation
  lock.
- The bridge is compiled with Swift 6.4 or later, which ships with Xcode 27.1.
  With an older Xcode it is left out, and the plugin publishes nothing.

## How it works

The plugin reads the reserved regions of the Flutter view, the hinge through
`UIHingeInteraction`, and the edge of the vertical bar from the trait
collection. It sends them over an event channel each time one of them changes.

UIKit sends no notification when a reserved region changes. It does lay a view
out again when a region it read during layout changes, so the plugin reads the
regions in the layout of a view that draws nothing, as the
[`foldable`][foldable] package found.

The fold follows the status of the hinge instead of the active flag of its
region, which only turns on about a second after the device comes to rest half
open.

## Limitations

- Tested on the iPhone Duo simulator with iOS 27.1, built with CocoaPods. The
  Swift Package Manager setup follows Flutter's plugin layout but has not been
  tested yet.
- While the device rotates, folds or unfolds, the regions can lead the size of
  the window by a frame or two.

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

[duo-kit]: https://pub.dev/packages/duo_kit
[setup]: https://pub.dev/packages/duo_kit#iphone-duo-setup
[foldable]: https://pub.dev/packages/foldable
[leancode-landing]: https://leancode.co/?utm_source=github.com&utm_medium=referral&utm_campaign=duo-kit
[patrol-landing]: https://patrol.leancode.co/?utm_source=github.com&utm_medium=referral&utm_campaign=duo-kit
[leancode-estimate]: https://leancode.co/get-estimate?utm_source=github.com&utm_medium=referral&utm_campaign=duo-kit
[leancode-packages]: https://pub.dev/packages?q=publisher%3Aleancode.co&sort=downloads
