package com.example.platform_channel

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.util.DisplayMetrics
import android.provider.Settings
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val DEVICE_CHANNEL = "com.example.platform_channel/device"
        private const val HARDWARE_CHANNEL = "com.example.platform_channel/hardware_info"
        private const val BLUETOOTH_EVENTS = "com.example.platform_channel/bluetooth_state"
        private const val REQUEST_BLUETOOTH_PERMISSION = 4101
        private const val REQUEST_IMEI_PERMISSION = 4102
    }

    private var eventSink: EventChannel.EventSink? = null
    private var permissionResult: MethodChannel.Result? = null
    private var imeiPermissionResult: MethodChannel.Result? = null
    private var receiverRegistered = false

    private val bluetoothReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == BluetoothAdapter.ACTION_STATE_CHANGED) {
                emitBluetoothState()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDeviceInfo" -> result.success(getDeviceInfo())
                    "getBluetoothState" -> result.success(bluetoothState())
                    "requestBluetoothPermission" -> requestBluetoothPermission(result)
                    "requestImeiPermission" -> requestImeiPermission(result)
                    "openBluetoothSettings" -> {
                        startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HARDWARE_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getHardwareInfo") {
                    result.success(getHardwareInfo())
                } else {
                    result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, BLUETOOTH_EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                    registerBluetoothReceiver()
                    emitBluetoothState()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    unregisterBluetoothReceiver()
                }
            })
    }

    private fun requestBluetoothPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || hasBluetoothPermission()) {
            result.success(true)
            return
        }
        if (permissionResult != null) {
            result.error("permission_in_progress", "Bluetooth izni isteği zaten açık.", null)
            return
        }
        permissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.BLUETOOTH_CONNECT),
            REQUEST_BLUETOOTH_PERMISSION,
        )
    }

    @Deprecated("Used for the Android runtime permission callback")
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_BLUETOOTH_PERMISSION) {
            val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
            permissionResult?.success(granted)
            permissionResult = null
            emitBluetoothState()
        } else if (requestCode == REQUEST_IMEI_PERMISSION) {
            val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
            imeiPermissionResult?.success(granted)
            imeiPermissionResult = null
        }
    }

    private fun requestImeiPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.P ||
            checkSelfPermission(Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        if (imeiPermissionResult != null) {
            result.error("permission_in_progress", "Telefon bilgisi izni isteği zaten açık.", null)
            return
        }
        imeiPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.READ_PHONE_STATE),
            REQUEST_IMEI_PERMISSION,
        )
    }

    private fun hasBluetoothPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED

    private fun registerBluetoothReceiver() {
        if (receiverRegistered) return
        val filter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(bluetoothReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(bluetoothReceiver, filter)
        }
        receiverRegistered = true
    }

    private fun unregisterBluetoothReceiver() {
        if (!receiverRegistered) return
        unregisterReceiver(bluetoothReceiver)
        receiverRegistered = false
    }

    private fun emitBluetoothState() {
        val state = bluetoothState()
        runOnUiThread { eventSink?.success(mapOf("state" to state)) }
    }

    private fun bluetoothState(): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !hasBluetoothPermission()) {
            return "permission_required"
        }
        val manager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            ?: return "unavailable"
        val adapter = manager.adapter ?: return "unavailable"
        return when (adapter.state) {
            BluetoothAdapter.STATE_ON -> "on"
            BluetoothAdapter.STATE_OFF -> "off"
            BluetoothAdapter.STATE_TURNING_ON -> "turning_on"
            BluetoothAdapter.STATE_TURNING_OFF -> "turning_off"
            else -> "unavailable"
        }
    }

    private fun getDeviceInfo(): Map<String, Any?> {
        val androidId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
        val (imei, imeiMessage) = readImei()
        val imeiPermissionRequired = packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY) &&
            Build.VERSION.SDK_INT in Build.VERSION_CODES.M..Build.VERSION_CODES.P &&
            checkSelfPermission(Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED
        return mapOf(
            "androidId" to androidId,
            "imei" to imei,
            "imeiMessage" to imeiMessage,
            "imeiPermissionRequired" to imeiPermissionRequired,
        )
    }

    private fun getHardwareInfo(): Map<String, Any> {
        val memory = ActivityManager.MemoryInfo()
        (getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager)
            .getMemoryInfo(memory)
        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        windowManager.defaultDisplay.getRealMetrics(metrics)

        val features = linkedMapOf(
            "Bluetooth" to PackageManager.FEATURE_BLUETOOTH,
            "Bluetooth LE" to PackageManager.FEATURE_BLUETOOTH_LE,
            "NFC" to PackageManager.FEATURE_NFC,
            "Kamera" to PackageManager.FEATURE_CAMERA_ANY,
            "GPS" to PackageManager.FEATURE_LOCATION_GPS,
            "Telefon" to PackageManager.FEATURE_TELEPHONY,
            "USB host" to PackageManager.FEATURE_USB_HOST,
            "İvmeölçer" to PackageManager.FEATURE_SENSOR_ACCELEROMETER,
            "Jiroskop" to PackageManager.FEATURE_SENSOR_GYROSCOPE,
            "Parmak izi" to PackageManager.FEATURE_FINGERPRINT,
        ).mapValues { (_, featureName) -> packageManager.hasSystemFeature(featureName) }

        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "brand" to Build.BRAND,
            "model" to Build.MODEL,
            "device" to Build.DEVICE,
            "product" to Build.PRODUCT,
            "androidVersion" to Build.VERSION.RELEASE,
            "apiLevel" to Build.VERSION.SDK_INT,
            "securityPatch" to (Build.VERSION.SECURITY_PATCH ?: "Bilinmiyor"),
            "supportedAbis" to Build.SUPPORTED_ABIS.toList(),
            "processorCores" to Runtime.getRuntime().availableProcessors(),
            "totalRamBytes" to memory.totalMem,
            "availableRamBytes" to memory.availMem,
            "screenWidthPx" to metrics.widthPixels,
            "screenHeightPx" to metrics.heightPixels,
            "densityDpi" to metrics.densityDpi,
            "density" to metrics.density.toDouble(),
            "features" to features,
        )
    }

    @Suppress("DEPRECATION")
    private fun readImei(): Pair<String?, String> {
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)) {
            return null to "Bu cihazda telefon/radyo modülü bulunmuyor."
        }
        if (Build.VERSION.SDK_INT in Build.VERSION_CODES.M..Build.VERSION_CODES.P &&
            checkSelfPermission(Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED
        ) {
            return null to "Android 9 ve öncesinde telefon bilgisi izni gerekir."
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return null to "Bu Android sürümünde IMEI API'si desteklenmiyor."
        }
        return try {
            val telephony = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            val value = telephony.imei
            if (value.isNullOrBlank()) null to "Cihaz IMEI bilgisi döndürmedi."
            else value to "IMEI erişilebilir."
        } catch (_: SecurityException) {
            null to "Android, IMEI erişimini uygulamalar için kısıtlıyor."
        } catch (_: RuntimeException) {
            null to "Bu cihaz IMEI bilgisi sağlamıyor."
        }
    }

    override fun onDestroy() {
        unregisterBluetoothReceiver()
        super.onDestroy()
    }
}
