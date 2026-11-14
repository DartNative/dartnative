import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "shopbench/native", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "homeReady":
        NSLog("SHOPBENCH home_ready")
        result(nil)
      case "apiUrl":
        result(ProcessInfo.processInfo.environment["SHOP_API_URL"])
      default:
        result(nil)
      }
    }
  }
}
