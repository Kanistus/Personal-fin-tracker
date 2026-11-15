package com.personalfin.personal_fin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import org.json.JSONArray
import org.json.JSONObject

class SMSReceiver : BroadcastReceiver() {

    companion object {
        const val PREFS_NAME = "fintracker_sms_queue"
        const val KEY_QUEUE = "pending_sms"

        // Static listener for real-time delivery when Flutter is active
        var smsListener: ((Map<String, Any>) -> Unit)? = null

        fun getQueuedSms(context: Context): List<Map<String, Any>> {
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

        fun clearQueuedSms(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putString(KEY_QUEUE, "[]").apply()
        }

        fun queueSms(context: Context, payload: Map<String, Any>) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonString = prefs.getString(KEY_QUEUE, "[]") ?: "[]"

            try {
                val array = JSONArray(jsonString)
                val obj = JSONObject(payload)
                array.put(obj)

                // Limit queue to most recent 50 messages to conserve memory
                val trimmedArray = if (array.length() > 50) {
                    val newArr = JSONArray()
                    for (i in (array.length() - 50) until array.length()) {
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

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
            if (messages.isEmpty()) return

            val sender = messages[0].displayOriginatingAddress ?: ""
            val fullBody = buildString {
                for (msg in messages) {
                    append(msg.displayMessageBody ?: "")
                }
            }
            val timestamp = messages[0].timestampMillis

            // Check if it looks like a financial / transaction message
            val lower = fullBody.lowercase()
            val isTransaction = lower.contains("debited") ||
                    lower.contains("credited") ||
                    lower.contains("spent") ||
                    lower.contains("paid") ||
                    lower.contains("inr") ||
                    lower.contains("rs.") ||
                    lower.contains("rs ") ||
                    lower.contains("₹") ||
                    lower.contains("txn") ||
                    lower.contains("upi") ||
                    lower.contains("vpa") ||
                    lower.contains("a/c") ||
                    lower.contains("acct") ||
                    lower.contains("transfer")

            if (!isTransaction) return

            val payload = mapOf(
                "sender" to sender,
                "body" to fullBody,
                "timestamp" to timestamp
            )

            val listener = smsListener
            if (listener != null) {
                try {
                    listener.invoke(payload)
                } catch (e: Exception) {
                    e.printStackTrace()
                    queueSms(context, payload)
                }
            } else {
                queueSms(context, payload)
            }
        }
    }
}
