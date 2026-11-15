package com.personalfin.personal_fin

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.personalfin/sms"
    private var methodChannel: MethodChannel? = null
    private val SMS_PERMISSION_REQUEST_CODE = 1001
    private var permissionResultCallback: ((Boolean) -> Unit)? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isSmsPermissionGranted" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.RECEIVE_SMS
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }
                "requestSmsPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.RECEIVE_SMS
                    ) == PackageManager.PERMISSION_GRANTED
                    if (granted) {
                        result.success(true)
                    } else {
                        permissionResultCallback = { isGranted ->
                            result.success(isGranted)
                        }
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.RECEIVE_SMS, Manifest.permission.READ_SMS),
                            SMS_PERMISSION_REQUEST_CODE
                        )
                    }
                }
                "getQueuedSms" -> {
                    val queued = SMSReceiver.getQueuedSms(applicationContext)
                    result.success(queued)
                }
                "clearQueuedSms" -> {
                    SMSReceiver.clearQueuedSms(applicationContext)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Connect real-time SMS listener to MethodChannel
        SMSReceiver.smsListener = { payload ->
            runOnUiThread {
                methodChannel?.invokeMethod("onSmsReceived", payload)
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == SMS_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            permissionResultCallback?.invoke(granted)
            permissionResultCallback = null
        }
    }

    override fun onDestroy() {
        SMSReceiver.smsListener = null
        super.onDestroy()
    }
}
