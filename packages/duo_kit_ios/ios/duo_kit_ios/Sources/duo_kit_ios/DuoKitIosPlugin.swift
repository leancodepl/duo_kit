import Flutter
import UIKit

/// Bridges what iPhone Duo reports natively to duo_kit.
///
/// Sends the hinge, the edge of the vertical bar and the reserved regions of
/// the Flutter view over an event channel, each time one of them changes.
public final class DuoKitIosPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private static let channelName = "duo_kit_ios/state"
  private static let viewRetryDelay = 0.25

  private weak var registrar: FlutterPluginRegistrar?
  private var eventSink: FlutterEventSink?

  /// The bridge, once the Flutter view exists. Typed loosely so that the
  /// plugin still builds with SDKs older than iOS 27.1.
  private var bridge: AnyObject?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = DuoKitIosPlugin()
    instance.registrar = registrar

    let channel = FlutterEventChannel(name: channelName, binaryMessenger: registrar.messenger())
    channel.setStreamHandler(instance)
    registrar.publish(instance)
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    startBridge()

    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil

    return nil
  }

  /// Starts the bridge on the Flutter view, retrying until the view exists,
  /// or sends the current state again to a new listener.
  private func startBridge() {
    #if compiler(>=6.4)
    guard #available(iOS 27.1, *), eventSink != nil else { return }

    if let bridge = bridge as? DuoBridge {
      bridge.sendCurrentState()
      return
    }

    guard let view = registrar?.viewController?.view else {
      DispatchQueue.main.asyncAfter(deadline: .now() + Self.viewRetryDelay) { [weak self] in
        self?.startBridge()
      }
      return
    }

    bridge = DuoBridge(host: view) { [weak self] message in
      self?.eventSink?(message)
    }
    #endif
  }
}
