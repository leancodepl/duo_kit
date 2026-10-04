# duo_kit example

Lays plain widgets out with duo_kit: navigation that moves into the strip of
iPhone Duo, a list and its details on either side of the fold, and dialogs that
open in one half of a split window.

Add the platforms you want to run it on, then run it:

```sh
flutter create --platforms=ios,android .
flutter run
```

On iPhone Duo, build with the iOS 27.1 SDK and raise the deployment target of
the Runner target to iOS 15.0 first, as the [iPhone Duo setup][setup]
describes. In a debug build, the button at the left edge simulates a fold on
any device.

[setup]: https://github.com/leancodepl/duo_kit#iphone-duo-setup
