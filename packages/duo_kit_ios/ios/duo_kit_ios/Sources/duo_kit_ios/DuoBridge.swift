// The iPhone Duo APIs first ship in the iOS 27.1 SDK, with Swift 6.4. With an
// older toolchain the bridge is left out and the plugin sends nothing.
#if compiler(>=6.4)
import UIKit

/// Reads what iPhone Duo reports for a view, and sends it each time it changes.
@available(iOS 27.1, *)
final class DuoBridge {
  private let observer = RegionObserverView()
  private let send: ([String: Any]) -> Void
  private var interaction: UIHingeInteraction?
  private var hinge: UIHinge?
  private var lastState: DuoState?

  init(host: UIView, send: @escaping ([String: Any]) -> Void) {
    self.send = send

    observer.frame = host.bounds
    observer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    observer.onLayout = { [weak self] in self?.update() }
    host.insertSubview(observer, at: 0)

    let interaction = UIHingeInteraction { [weak self] _, update in
      self?.hinge = update.hinge
      self?.update()
    }
    host.addInteraction(interaction)
    self.interaction = interaction
  }

  /// Sends the current state even if it did not change, for a new listener.
  func sendCurrentState() {
    lastState = nil
    update()
  }

  private func update() {
    let state = DuoState(hinge: hinge, view: observer)
    guard state != lastState else { return }

    lastState = state
    send(state.message)
  }
}

/// What the bridge sends, compared to tell whether anything changed.
@available(iOS 27.1, *)
private struct DuoState: Equatable {
  struct Region: Equatable {
    let kind: String
    let frame: CGRect
    let isActive: Bool
  }

  let hingeStatus: Int?
  let hingeAngle: Double?
  let verticalBarEdge: String
  let regions: [Region]

  init(hinge: UIHinge?, view: UIView) {
    hingeStatus = hinge.map { $0.status.rawValue }
    hingeAngle = hinge.map { Double($0.angle) }

    verticalBarEdge =
      switch view.traitCollection.verticalBarEdge {
      case .leading: "leading"
      case .trailing: "trailing"
      default: "unspecified"
      }

    // Inactive regions too: the fold is known while the device lies flat, and
    // its active flag follows the hinge with a delay.
    let kinds: [(UIView.ReservedRegion.Kind, String)] = [
      (.occlusion, "occlusion"), (.division, "division"),
    ]
    regions = kinds.flatMap { kind, name in
      view.reservedRegions(kind: kind, options: .includeInactive).map {
        Region(kind: name, frame: $0.frame, isActive: $0.isActive)
      }
    }
  }

  var message: [String: Any] {
    let hinge: Any =
      if let hingeStatus, let hingeAngle {
        ["status": hingeStatus, "angle": hingeAngle]
      } else {
        NSNull()
      }

    return [
      "hinge": hinge,
      "verticalBarEdge": verticalBarEdge,
      "regions": regions.map { region in
        [
          "kind": region.kind,
          "rect": [
            region.frame.minX, region.frame.minY, region.frame.maxX, region.frame.maxY,
          ].map { Double($0) },
          "active": region.isActive,
        ] as [String: Any]
      },
    ]
  }
}

/// Draws nothing and takes no touches.
///
/// UIKit sends no notification when a reserved region changes. It does run
/// layout again for a view that read the region during its last layout, so
/// this view reads them in `layoutSubviews`, as the foldable package found.
@available(iOS 27.1, *)
private final class RegionObserverView: UIView {
  var onLayout: (() -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)

    isUserInteractionEnabled = false
    isAccessibilityElement = false
    accessibilityElementsHidden = true
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    onLayout?()
  }

  override func safeAreaInsetsDidChange() {
    super.safeAreaInsetsDidChange()
    setNeedsLayout()
  }
}
#endif
