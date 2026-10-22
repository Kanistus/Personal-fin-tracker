/// Per-app notification tracking preference.
/// Controls which payment apps the notification listener monitors.
class TrackingSetting {
  final int? id;
  final String packageName; // e.g., com.google.android.apps.nbu.paisa.user
  final String appName;     // e.g., Google Pay
  final bool enabled;
  final DateTime addedAt;

  TrackingSetting({
    this.id,
    required this.packageName,
    required this.appName,
    this.enabled = true,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageName': packageName,
      'appName': appName,
      'enabled': enabled ? 1 : 0,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory TrackingSetting.fromMap(Map<String, dynamic> map) {
    return TrackingSetting(
      id: map['id'] as int?,
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      enabled: (map['enabled'] as int) == 1,
      addedAt: DateTime.parse(map['addedAt'] as String),
    );
  }

  TrackingSetting copyWith({bool? enabled}) {
    return TrackingSetting(
      id: id,
      packageName: packageName,
      appName: appName,
      enabled: enabled ?? this.enabled,
      addedAt: addedAt,
    );
  }

  /// Default list of supported payment apps in India.
  static const List<TrackingSetting> defaultApps = [];

  /// Returns default app list for initial setup.
  static List<TrackingSetting> getDefaultApps() {
    return [
      TrackingSetting(
        packageName: 'com.google.android.apps.nbu.paisa.user',
        appName: 'Google Pay',
        enabled: true,
      ),
      TrackingSetting(
        packageName: 'com.phonepe.app',
        appName: 'PhonePe',
        enabled: true,
      ),
      TrackingSetting(
        packageName: 'net.one97.paytm',
        appName: 'Paytm',
        enabled: true,
      ),
      TrackingSetting(
        packageName: 'in.amazon.mShop.android.shopping',
        appName: 'Amazon Pay',
        enabled: true,
      ),
      TrackingSetting(
        packageName: 'com.samsung.android.spay',
        appName: 'Samsung Pay',
        enabled: false,
      ),
      TrackingSetting(
        packageName: 'com.csam.icici.bank.imobile',
        appName: 'ICICI iMobile',
        enabled: false,
      ),
      TrackingSetting(
        packageName: 'com.sbi.SBIFreedomPlus',
        appName: 'SBI YONO',
        enabled: false,
      ),
      TrackingSetting(
        packageName: 'com.axis.mobile',
        appName: 'Axis Mobile',
        enabled: false,
      ),
      TrackingSetting(
        packageName: 'com.hdfc.retail.banking',
        appName: 'HDFC Bank',
        enabled: false,
      ),
      TrackingSetting(
        packageName: 'com.bankofbaroda.mconnect',
        appName: 'Bank of Baroda',
        enabled: false,
      ),
      TrackingSetting(
        packageName: 'com.msf.kbank.mobile',
        appName: 'Kotak 811',
        enabled: false,
      ),
      TrackingSetting(
        packageName: 'com.whatsapp',
        appName: 'WhatsApp Pay',
        enabled: false,
      ),
      TrackingSetting(
        packageName: 'com.cred.android',
        appName: 'CRED',
        enabled: false,
      ),
    ];
  }
}
