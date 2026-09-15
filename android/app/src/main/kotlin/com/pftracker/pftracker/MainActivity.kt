package com.pftracker.pftracker

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

/**
 * Bridges the device's pressure sensor (TYPE_PRESSURE) to Dart as a stream
 * of raw hPa readings. Not every Android device has this sensor; when
 * absent, onListen never emits and the Dart side should treat the stream
 * as unsupported (e.g. via a timeout) and fall back to GPS altitude.
 */
class MainActivity : FlutterActivity() {
    private val barometerChannel = "pftracker/barometer"
    private var sensorManager: SensorManager? = null
    private var pressureSensor: Sensor? = null
    private var sensorListener: SensorEventListener? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sensorManager = getSystemService(SENSOR_SERVICE) as? SensorManager
        pressureSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_PRESSURE)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, barometerChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    val sensor = pressureSensor
                    if (sensor == null) {
                        events.error("NO_BAROMETER", "Device has no pressure sensor", null)
                        return
                    }
                    val listener = object : SensorEventListener {
                        override fun onSensorChanged(event: SensorEvent) {
                            events.success(event.values[0].toDouble())
                        }
                        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
                    }
                    sensorListener = listener
                    sensorManager?.registerListener(
                        listener,
                        sensor,
                        SensorManager.SENSOR_DELAY_NORMAL
                    )
                }

                override fun onCancel(arguments: Any?) {
                    sensorListener?.let { sensorManager?.unregisterListener(it) }
                    sensorListener = null
                }
            })
    }

    override fun onDestroy() {
        sensorListener?.let { sensorManager?.unregisterListener(it) }
        super.onDestroy()
    }
}
