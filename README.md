<div align="center">

[![Banner][banner-img]][leancode-landing]

</div>

# duo_kit

Flutter layouts for iPhone Duo and other foldables.

On iPhone Duo, `FoldScaffold` moves your navigation into the strip at the side
of the window, and `FoldSplitView` puts a list and its details on either side
of the fold when the device opens like a book. duo_kit only places widgets: the
navigation and the panes are your own, in whatever design your app has.

![The example app on iPhone Duo: as the device opens like a book, the list and its details move to either side of the fold, and back when it lies flat][hero-img]

## Packages

| Package | Version | |
|---|---|---|
| [`duo_kit`](packages/duo_kit) | [![duo_kit pub.dev badge][pub-badge]][pub-badge-link] | Fold geometry, a scaffold, a split view and anchors for dialogs. Pure Flutter. |
| [`duo_kit_ios`](packages/duo_kit_ios) | In development | The iOS side: the fold, the camera, the status cluster, the hinge and the vertical bar of iPhone Duo, published to Flutter. |

Start with the [duo_kit README](packages/duo_kit), which covers the setup for
iPhone Duo and every widget.

## Working on the packages

The repository is a pub workspace, with the Flutter version pinned by FVM:

```sh
fvm flutter pub get
cd packages/duo_kit && fvm flutter test
```

Each package has its own version, changelog and release.

---

## 🛠️ Maintained by LeanCode

<div align="center">

  [<img src="https://leancodepublic.blob.core.windows.net/public/wide.png" alt="LeanCode Logo" height="100" />][leancode-landing]

</div>

These packages are built with 💙 by **[LeanCode][leancode-landing]**.
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

[banner-img]: https://raw.githubusercontent.com/leancodepl/duo_kit/refs/heads/main/packages/duo_kit/doc/imgs/banner.png
[hero-img]: https://raw.githubusercontent.com/leancodepl/duo_kit/refs/heads/main/packages/duo_kit/doc/imgs/hero.gif
[pub-badge]: https://img.shields.io/pub/v/duo_kit
[pub-badge-link]: https://pub.dev/packages/duo_kit
[leancode-landing]: https://leancode.co/?utm_source=github.com&utm_medium=referral&utm_campaign=duo-kit
[patrol-landing]: https://patrol.leancode.co/?utm_source=github.com&utm_medium=referral&utm_campaign=duo-kit
[leancode-estimate]: https://leancode.co/get-estimate?utm_source=github.com&utm_medium=referral&utm_campaign=duo-kit
[leancode-packages]: https://pub.dev/packages?q=publisher%3Aleancode.co&sort=downloads
