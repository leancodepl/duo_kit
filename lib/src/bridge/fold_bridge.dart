import 'dart:async';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:duo_kit/src/bridge/fold_bridge_scope.dart';
import 'package:duo_kit/src/bridge/fold_hinge.dart';
import 'package:duo_kit/src/bridge/fold_vertical_bar_edge.dart';
import 'package:duo_kit/src/geometry/fold_geometry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Publishes what iPhone Duo reports natively to the widgets below.
///
/// Adds the fold and the occlusions of the window, such as the camera and the
/// status cluster, to [MediaQueryData.displayFeatures], where duo_kit and
/// Flutter's dialogs find them. The fold is added while the device is partly
/// open; the occlusions also while it is closed.
///
/// See also [FoldHinge.maybeOf] and [FoldGeometry.verticalBarEdge].
///
/// Place it above the app, so that overlays outside the navigator see it too.
/// Use only one: every [FoldBridge] listens on the same native channel.
/// On other platforms, on devices without a hinge, and without the plugin (as
/// in tests), it passes [child] through.
class FoldBridge extends StatefulWidget {
  /// Creates the bridge.
  const FoldBridge({super.key, required this.child});

  /// The app.
  final Widget child;

  @override
  State<FoldBridge> createState() => _FoldBridgeState();
}

class _FoldBridgeState extends State<FoldBridge> {
  /// Read by hand: [EventChannel] reports a missing plugin as an error.
  static const _channel = OptionalMethodChannel('duo_kit/state');

  var _isListening = false;
  var _state = _NativeState.none;

  (List<DisplayFeature>, _NativeState)? _featuresKey;
  var _features = const <DisplayFeature>[];

  @override
  void initState() {
    super.initState();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      _isListening = true;
      _channel.binaryMessenger.setMessageHandler(_channel.name, _onEnvelope);
      unawaited(_invoke('listen'));
    }
  }

  @override
  void dispose() {
    if (_isListening) {
      _channel.binaryMessenger.setMessageHandler(_channel.name, null);
      unawaited(_invoke('cancel'));
    }

    super.dispose();
  }

  Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } catch (err, st) {
      _reportError(err, st);
    }
  }

  Future<ByteData?> _onEnvelope(ByteData? envelope) async {
    // A null envelope ends the stream, which the plugin never does.
    if (envelope != null) {
      try {
        _onMessage(_channel.codec.decodeEnvelope(envelope));
      } on PlatformException catch (e, st) {
        _reportError(e, st);
      }
    }

    return null;
  }

  void _reportError(Object error, StackTrace stack) => FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: 'duo_kit',
      context: ErrorDescription('while reading the native state'),
    ),
  );

  void _onMessage(Object? message) {
    if (message is! Map<Object?, Object?>) {
      return;
    }

    final state = _NativeState.fromMessage(message);
    if (state != _state) {
      setState(() => _state = state);
    }
  }

  /// MediaQuery tells its dependents about display features by identity, so
  /// the list is only rebuilt when its inputs change.
  List<DisplayFeature> _getFeatures(List<DisplayFeature> ambient) {
    final key = (ambient, _state);
    if (key != _featuresKey) {
      _featuresKey = key;
      _features = List.unmodifiable([...ambient, ..._state.toFeatures()]);
    }

    return _features;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // Always the same MediaQuery, so that the state below survives the first
    // message.
    return FoldBridgeScope(
      hinge: _state.hinge,
      verticalBarEdge: _state.verticalBarEdge,
      child: MediaQuery(
        data: mediaQuery.copyWith(
          displayFeatures: _getFeatures(mediaQuery.displayFeatures),
        ),
        child: widget.child,
      ),
    );
  }
}

/// What the native side reported last.
@immutable
class _NativeState {
  const _NativeState({
    this.hinge,
    this.verticalBarEdge = FoldVerticalBarEdge.unspecified,
    this.occlusions = const [],
    this.fold,
    this.isFoldActive = false,
  });

  /// Reads a message of the native side, which looks like:
  ///
  /// ```text
  /// {
  ///   'hinge': {'status': 2, 'angle': 1.57} or null,
  ///   'verticalBarEdge': 'unspecified', 'leading' or 'trailing',
  ///   'regions': [
  ///     {'kind': 'occlusion' or 'division', 'rect': [l, t, r, b], 'active': true},
  ///   ],
  /// }
  /// ```
  factory _NativeState.fromMessage(Map<Object?, Object?> message) {
    final regions = switch (message['regions']) {
      final List<Object?> list => list.whereType<Map<Object?, Object?>>(),
      _ => const <Map<Object?, Object?>>[],
    };
    final occlusions = regions
        .where((region) => region['kind'] == 'occlusion')
        .where((region) => region['active'] == true)
        .map(_readRect)
        .nonNulls
        .where((rect) => !rect.isEmpty)
        .toList(growable: false);
    final division = regions
        .where((region) => region['kind'] == 'division')
        .map(
          (region) =>
              (rect: _readRect(region), isActive: region['active'] == true),
        )
        .where((division) => division.rect?.isEmpty == false)
        .firstOrNull;

    return _NativeState(
      hinge: _readHinge(message['hinge']),
      verticalBarEdge: switch (message['verticalBarEdge']) {
        'leading' => FoldVerticalBarEdge.leading,
        'trailing' => FoldVerticalBarEdge.trailing,
        _ => FoldVerticalBarEdge.unspecified,
      },
      occlusions: occlusions,
      fold: division?.rect,
      isFoldActive: division?.isActive ?? false,
    );
  }

  static const none = _NativeState();

  final FoldHinge? hinge;
  final FoldVerticalBarEdge verticalBarEdge;

  /// Active occlusions, in the coordinates of the window.
  final List<Rect> occlusions;

  /// Where the fold is, whether or not it is active.
  final Rect? fold;

  /// Whether the system reports the fold as active.
  ///
  /// The flag follows the hinge with a delay, so the hinge status decides
  /// when it is known.
  final bool isFoldActive;

  /// Whether the device is partly open, so that the fold splits the window.
  bool get isHalfOpened => switch (hinge?.status) {
    FoldHingeStatus.partiallyOpen => true,
    FoldHingeStatus.closed || FoldHingeStatus.fullyOpen => false,
    FoldHingeStatus.unknown || null => isFoldActive,
  };

  List<DisplayFeature> toFeatures() => [
    ...occlusions.map(
      (occlusion) => DisplayFeature(
        bounds: occlusion,
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ),
    if (fold case final fold? when isHalfOpened)
      DisplayFeature(
        bounds: fold,
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureHalfOpened,
      ),
  ];

  static FoldHinge? _readHinge(Object? hinge) => switch (hinge) {
    {'status': final int status, 'angle': final num angle} => FoldHinge(
      // The raw values of UIHinge.Status.
      status: switch (status) {
        1 => FoldHingeStatus.closed,
        2 => FoldHingeStatus.partiallyOpen,
        3 => FoldHingeStatus.fullyOpen,
        _ => FoldHingeStatus.unknown,
      },
      angle: angle.toDouble(),
    ),
    _ => null,
  };

  static Rect? _readRect(Map<Object?, Object?> region) =>
      switch (region['rect']) {
        [final num left, final num top, final num right, final num bottom] =>
          Rect.fromLTRB(
            left.toDouble(),
            top.toDouble(),
            right.toDouble(),
            bottom.toDouble(),
          ),
        _ => null,
      };

  @override
  bool operator ==(Object other) =>
      other is _NativeState &&
      other.hinge == hinge &&
      other.verticalBarEdge == verticalBarEdge &&
      listEquals(other.occlusions, occlusions) &&
      other.fold == fold &&
      other.isFoldActive == isFoldActive;

  @override
  int get hashCode => Object.hash(
    hinge,
    verticalBarEdge,
    Object.hashAll(occlusions),
    fold,
    isFoldActive,
  );
}
