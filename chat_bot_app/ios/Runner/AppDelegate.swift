import UIKit
import Flutter
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GeneratedPluginRegistrant.register(with: self)

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let controller = window?.rootViewController as? FlutterViewController {
      let audioChannel = FlutterMethodChannel(name: "com.example.audio/routing",
                                              binaryMessenger: controller.binaryMessenger)

      audioChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "setSpeaker" {
          guard let args = call.arguments as? [String: Any],
                let enable = args["enable"] as? Bool else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing 'enable'", details: nil))
            return
          }
          self?.setSpeakerMode(enable: enable)
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return result
  }

  private func setSpeakerMode(enable: Bool) {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
      try session.setActive(true)
      if enable {
        try session.overrideOutputAudioPort(.speaker)
      } else {
        try session.overrideOutputAudioPort(.none)
      }
    } catch {
      print("⚠️ Failed to set audio session: \(error)")
    }
  }
}
