import CoreMotion
import Flutter
import UIKit

/// Bridges CMAltimeter to Dart as a stream of raw hPa pressure readings,
/// matching the Android side (Sensor.TYPE_PRESSURE) so Dart can share one
/// altitude formula. CMAltimeter reports pressure in kPa; we convert to
/// hPa (×10) at the boundary. Not available on iPads or very old iPhones —
/// `CMAltimeter.isRelativeAltitudeAvailable()` gates that.
@main
@objc class AppDelegate: FlutterAppDelegate {
  private let altimeter = CMAltimeter()
  private var eventSink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterEventChannel(
      name: "pftracker/barometer",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setStreamHandler(BarometerStreamHandler(altimeter: altimeter))

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

class BarometerStreamHandler: NSObject, FlutterStreamHandler {
  private let altimeter: CMAltimeter

  init(altimeter: CMAltimeter) {
    self.altimeter = altimeter
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    guard CMAltimeter.isRelativeAltitudeAvailable() else {
      events(FlutterError(code: "NO_BAROMETER", message: "Device has no barometer", details: nil))
      return nil
    }
    altimeter.startRelativeAltitudeUpdates(to: .main) { data, error in
      guard let data = data, error == nil else { return }
      events(data.pressure.doubleValue * 10.0)
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    altimeter.stopRelativeAltitudeUpdates()
    return nil
  }
}
