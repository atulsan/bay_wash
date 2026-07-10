import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private let iconChannelName = "bay_wash/app_icon"
  private var privacyOverlay: UIView?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    registerIconChannel()
  }

  override func sceneWillResignActive(_ scene: UIScene) {
    super.sceneWillResignActive(scene)
    showPrivacyOverlay()
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    hidePrivacyOverlay()
  }

  private func registerIconChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    let channel = FlutterMethodChannel(
      name: iconChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "setIcon" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard UIApplication.shared.supportsAlternateIcons else {
        result(false)
        return
      }
      let args = call.arguments as? [String: Any]
      let icon = args?["icon"] as? String
      guard icon == nil || icon == "light" || icon == "dark" else {
        result(FlutterError(
          code: "INVALID_ICON",
          message: "Unsupported app icon variant.",
          details: nil
        ))
        return
      }
      let iconName = icon == "dark" ? "AppIconDark" : nil
      UIApplication.shared.setAlternateIconName(iconName) { error in
        if let error = error {
          result(FlutterError(
            code: "ICON_SWITCH_FAILED",
            message: error.localizedDescription,
            details: nil
          ))
        } else {
          result(true)
        }
      }
    }
  }

  private func showPrivacyOverlay() {
    guard privacyOverlay == nil, let window = window else {
      return
    }
    let overlay = UIView(frame: window.bounds)
    overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    overlay.backgroundColor = UIColor(red: 0.02, green: 0.12, blue: 0.15, alpha: 1.0)

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = "Bay Wash"
    label.textColor = .white
    label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
    overlay.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
    ])

    window.addSubview(overlay)
    privacyOverlay = overlay
  }

  private func hidePrivacyOverlay() {
    privacyOverlay?.removeFromSuperview()
    privacyOverlay = nil
  }
}
