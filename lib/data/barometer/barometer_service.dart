import 'package:flutter/services.dart';

/// Streams raw atmospheric pressure (hPa) from the device's barometer via
/// a platform channel — Android's `TYPE_PRESSURE` sensor, iOS's
/// `CMAltimeter`. Altitude is derived from pressure in Dart, via
/// `GeoUtils.altitudeFromPressure`, so both platforms share one formula
/// and the QNH reference can be adjusted without touching native code.
///
/// Not every device has a barometer (most iPhones do; Android varies by
/// model), so callers should treat an error on this stream as "unsupported
/// on this device" and fall back to GPS altitude only.
class BarometerService {
  static const _eventChannel = EventChannel('pftracker/barometer');

  Stream<double>? _hpaStream;

  Stream<double> pressureHpaStream() {
    _hpaStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => (event as num).toDouble());
    return _hpaStream!;
  }
}
