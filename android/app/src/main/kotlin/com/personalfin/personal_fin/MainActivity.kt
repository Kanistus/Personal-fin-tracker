package com.personalfin.personal_fin

import android.content.Intent
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.personalfin/notifications"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationAccessGranted" -> {
                    val isGranted = isNotificationAccessGranted()
                    result.success(isGranted)
                }
                "openNotificationAccessSettings" -> {
                    openNotificationAccessSettings()
                    result.success(true)
                }
                "getQueuedNotifications" -> {
                    val queued = TransactionNotificationService.getQueuedNotifications(applicationContext)
                    result.success(queued)
                }
                "clearQueuedNotifications" -> {
                    TransactionNotificationService.clearQueuedNotifications(applicationContext)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Connect real-time notification listener to MethodChannel
        TransactionNotificationService.notificationListener = { payload ->
            runOnUiThread {
                methodChannel?.invokeMethod("onNotificationReceived", payload)
            }
        }
    }

    private fun isNotificationAccessGranted(): Boolean {
        val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(applicationContext)
        return enabledPackages.contains(applicationContext.packageName)
    }

    private fun openNotificationAccessSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    override fun onDestroy() {
        TransactionNotificationService.notificationListener = null
        super.onDestroy()
    }
}
