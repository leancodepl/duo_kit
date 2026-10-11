<div align="center">

[![Banner][banner-img]][leancode-landing]

</div>

# duo_kit

Layouts for foldables such as iPhone Duo, for Flutter. duo_kit works out where
the system keeps room in the window – the strip for its controls, the fold, the
camera and the status cluster – and places your widgets around it, drawing
nothing of its own.

![The example app on iPhone Duo: as the device opens like a book, the list and its details move to either side of the fold, and back when it lies flat][hero-img]

## Packages

| Package | Version | |
|---|---|---|
| [`duo_kit`](packages/duo_kit) | [![duo_kit pub.dev badge][pub-badge]][pub-badge-link] | Fold geometry, a scaffold, a split view and anchors for dialogs. Pure Dart. |
| [`duo_kit_ios`](packages/duo_kit_ios) | In development | The iOS side: the vertical bar, the hinge and the reserved regions of iPhone Duo, published to Flutter. |

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

Built by **[LeanCode][leancode-landing]**, creators of
[Patrol][patrol-landing].

[banner-img]: https://raw.githubusercontent.com/leancodepl/duo_kit/refs/heads/main/packages/duo_kit/doc/imgs/banner.png
[hero-img]: https://raw.githubusercontent.com/leancodepl/duo_kit/refs/heads/main/packages/duo_kit/doc/imgs/hero.gif
[pub-badge]: https://img.shields.io/pub/v/duo_kit
[pub-badge-link]: https://pub.dev/packages/duo_kit
[leancode-landing]: https://leancode.co/?utm_source=github.com&utm_medium=referral&utm_campaign=duo-kit
[patrol-landing]: https://patrol.leancode.co/?utm_source=github.com&utm_medium=referral&utm_campaign=duo-kit
