# duo_kit_ios

The iOS side of [duo_kit](../duo_kit): what iPhone Duo reports natively,
published to Flutter.

**In development, not published yet.** The package registers its iOS plugin
and passes its child through. Until the bridge lands, publish the fold to
Flutter with [`foldable`](https://pub.dev/packages/foldable), as the duo_kit
example does.

## Planned

- The edge of the vertical bar, including a strip on the left of Split View.
- Opting out of the vertical bar for a screen.
- The hinge status and angle.
- The reserved regions of the window, while the device is closed and while it
  lies flat.
- Whether the app shares the screen in Split View, and on which side.

## Usage

```dart
runApp(const DuoKitIos(child: MyApp()));
```

Place `DuoKitIos` above the app, so that overlays outside the navigator see
what it publishes. On other platforms it passes its child through.
