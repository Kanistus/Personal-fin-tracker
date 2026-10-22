package com.personalfin.personal_fin

import android.app.Notification
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

class TransactionNotificationService : NotificationListenerService() {

    companion object {
        const val PREFS_NAME = "fintracker_notification_queue"
        const val KEY_QUEUE = "pending_notifications"

        // Static listener for real-time delivery when Flutter is active
        var notificationListener: ((Map<String, Any>) -> Unit)? = null

        fun getQueuedNotifications(context: Context): List<Map<String, Any>> {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonString = prefs.getString(KEY_QUEUE, "[]") ?: "[]"
            val result = mutableListOf<Map<String, Any>>()

            try {
                val array = JSONArray(jsonString)
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    val map = mutableMapOf<String, Any>()
                    val keys = obj.keys()
                    while (keys.hasNext()) {
                        val key = keys.next()
                        map[key] = obj.get(key)
                    }
                    result.add(map)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }

            return result
        }

        fun clearQueuedNotifications(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putString(KEY_QUEUE, "[]").apply()
        }

        fun queueNotification(context: Context, payload: Map<String, Any>) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonString = prefs.getString(KEY_QUEUE, "[]") ?: "[]"

            try {
                val array = JSONArray(jsonString)
                val obj = JSONObject(payload)
                array.put(obj)

                // Limit queue to most recent 100 items to conserve memory
                val trimmedArray = if (array.length() > 100) {
                    val newArr = JSONArray()
                    for (i in (array.length() - 100) until array.length()) {
                        newArr.put(array.get(i))
                    }
                    newArr
                } else {
                    array
                }

                prefs.edit().putString(KEY_QUEUE, trimmedArray.toString()).apply()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName ?: return

        // Ignore our own app's notifications
        if (packageName == applicationContext.packageName) return

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: ""

        // If all text fields are empty, ignore
        if (title.isBlank() && text.isBlank() && bigText.isBlank()) return

        val payload = mapOf(
            "packageName" to packageName,
            "title" to title,
            "text" to text,
            "bigText" to bigText,
            "subText" to subText,
            "postTime" to sbn.postTime
        )

        // Deliver directly if active Flutter listener exists
        val listener = notificationListener
        if (listener != null) {
            try {
                listener.invoke(payload)
            } catch (e: Exception) {
                e.printStackTrace()
                queueNotification(applicationContext, payload)
            }
        } else {
            // Queue for when Flutter launches
            queueNotification(applicationContext, payload)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }
}
