import 'package:flutter/services.dart';

typedef NotificationCallback = void Function(Map<String, dynamic> notification);

class NotificationBridge {
  static const MethodChannel _channel = MethodChannel('com.personalfin/notifications');
  static NotificationCallback? _onNotificationReceived;

  static void initialize({NotificationCallback? onNotification}) {
    _onNotificationReceived = onNotification;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationReceived') {
        final Map<String, dynamic> data = Map<String, dynamic>.from(call.arguments as Map);
        _onNotificationReceived?.call(data);
      }
    });
  }

  static void setNotificationCallback(NotificationCallback? callback) {
    _onNotificationReceived = callback;
  }

  /// Check if the user has granted Notification Listener permission
  static Future<bool> isNotificationAccessGranted() async {
    try {
      final bool granted = await _channel.invokeMethod('isNotificationAccessGranted') ?? false;
      return granted;
    } catch (e) {
      return false;
    }
  }

  /// Open Android Notification Access settings screen
  static Future<bool> openNotificationAccessSettings() async {
    try {
      await _channel.invokeMethod('openNotificationAccessSettings');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch notifications queued while Flutter was inactive
  static Future<List<Map<String, dynamic>>> getQueuedNotifications() async {
    try {
      final List<dynamic>? raw = await _channel.invokeMethod('getQueuedNotifications');
      if (raw == null) return [];
      return raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear the notification queue in native storage
  static Future<void> clearQueuedNotifications() async {
    try {
      await _channel.invokeMethod('clearQueuedNotifications');
    } catch (_) {}
  }
}
