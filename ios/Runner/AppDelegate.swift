import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let iconChannelName = "bay_wash/app_icon"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
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
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
