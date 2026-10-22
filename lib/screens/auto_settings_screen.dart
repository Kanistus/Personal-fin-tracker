import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auto_tracking_provider.dart';
import '../services/notification_bridge.dart';

class AutoSettingsScreen extends StatefulWidget {
  const AutoSettingsScreen({super.key});

  @override
  State<AutoSettingsScreen> createState() => _AutoSettingsScreenState();
}

class _AutoSettingsScreenState extends State<AutoSettingsScreen> with WidgetsBindingObserver {
  static const Color _bgColor = Color(0xFF0F1B2D);
  static const Color _cardColor = Color(0xFF1A2940);
  static const Color _accentColor = Color(0xFF3498DB);
  static const Color _incomeColor = Color(0xFF2ECC71);
  static const Color _expenseColor = Color(0xFFE74C3C);
  static const Color _warningColor = Color(0xFFF39C12);
  static const Color _textPrimary = Color(0xFFECF0F1);
  static const Color _textSecondary = Color(0xFF8899AA);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AutoTrackingProvider>(context, listen: false).refreshPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Provider.of<AutoTrackingProvider>(context, listen: false).refreshPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final autoProvider = Provider.of<AutoTrackingProvider>(context);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: const Text(
          'Auto-Tracking Settings',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPermissionBanner(autoProvider),
          const SizedBox(height: 20),
          _buildSectionHeader('General Preferences'),
          const SizedBox(height: 10),
          _buildSwitchTile(
            title: 'Automatic Expense Tracking',
            subtitle: 'Detect payments from notifications and categorize them',
            value: autoProvider.isAutoTrackingEnabled,
            onChanged: (val) => autoProvider.setAutoTrackingEnabled(val),
          ),
          const SizedBox(height: 10),
          _buildSwitchTile(
            title: 'Auto-Log High Confidence Matches',
            subtitle: 'Automatically save clear transactions without manual approval',
            value: autoProvider.autoApproveHighConfidence,
            onChanged: (val) => autoProvider.setAutoApproveHighConfidence(val),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Monitored Payment Applications'),
          const SizedBox(height: 6),
          const Text(
            'Enable or disable transaction tracking for individual apps on your device.',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          _buildAppList(autoProvider),
          const SizedBox(height: 24),
          _buildSectionHeader('Learned Merchant Rules'),
          const SizedBox(height: 6),
          const Text(
            'Categories assigned automatically based on your past corrections.',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          _buildMerchantRulesList(autoProvider),
          const SizedBox(height: 24),
          _buildSectionHeader('Diagnostics & Storage'),
          const SizedBox(height: 10),
          _buildDiagnosticsCard(autoProvider),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner(AutoTrackingProvider provider) {
    final isGranted = provider.isNotificationAccessGranted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGranted
            ? _incomeColor.withValues(alpha: 0.12)
            : _warningColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? _incomeColor.withValues(alpha: 0.4) : _warningColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGranted ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: isGranted ? _incomeColor : _warningColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isGranted ? 'Notification Listener Active' : 'Notification Access Required',
                  style: TextStyle(
                    color: isGranted ? _incomeColor : _warningColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isGranted
                ? 'Finance Vault is monitoring payments locally and privately on this device.'
                : 'Android requires you to grant Notification Access in System Settings so the app can read payment alerts from Google Pay, PhonePe, and banks.',
            style: const TextStyle(color: _textPrimary, fontSize: 13, height: 1.4),
          ),
          if (!isGranted) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _warningColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => NotificationBridge.openNotificationAccessSettings(),
                icon: const Icon(Icons.settings_suggest_rounded, size: 20),
                label: const Text('Open Android Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAppList(AutoTrackingProvider provider) {
    final apps = provider.trackingSettings;

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: apps.map((app) {
          return SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            title: Text(
              app.appName,
              style: const TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              app.packageName,
              style: const TextStyle(color: _textSecondary, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            value: app.enabled,
            activeThumbColor: _accentColor,
            onChanged: (val) => provider.toggleAppTracking(app, val),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMerchantRulesList(AutoTrackingProvider provider) {
    final rules = provider.merchantRules;

    if (rules.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'No custom merchant rules learned yet. When you change the category of an auto-detected expense in the review screen, it will be remembered here.',
          style: TextStyle(color: _textSecondary, fontSize: 13, height: 1.4),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rules.length,
        separatorBuilder: (context, index) => Divider(color: _bgColor, height: 1),
        itemBuilder: (context, i) {
          final rule = rules[i];
          return ListTile(
            title: Text(
              rule.merchantPattern,
              style: const TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rule.category,
                    style: const TextStyle(color: _accentColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: _expenseColor, size: 20),
                  onPressed: () {
                    if (rule.id != null) provider.deleteMerchantRule(rule.id!);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiagnosticsCard(AutoTrackingProvider provider) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final lastTxn = provider.lastDetectedTransaction;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Notifications Processed:', style: TextStyle(color: _textSecondary, fontSize: 13)),
              Text('${provider.allAutoTransactions.length}', style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pending Review:', style: TextStyle(color: _textSecondary, fontSize: 13)),
              Text('${provider.pendingCount}', style: TextStyle(color: provider.pendingCount > 0 ? _warningColor : _incomeColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Last Detection:', style: TextStyle(color: _textSecondary, fontSize: 13)),
              Text(
                lastTxn != null ? dateFormat.format(lastTxn.date) : 'None',
                style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w500, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _expenseColor,
                side: BorderSide(color: _expenseColor.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: _cardColor,
                    title: const Text('Clear All Detections?', style: TextStyle(color: _textPrimary)),
                    content: const Text(
                      'This will delete the history of detected notifications. Manually confirmed transactions will remain safe in your expense records.',
                      style: TextStyle(color: _textSecondary),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear', style: TextStyle(color: _expenseColor)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await provider.clearAll();
                }
              },
              icon: const Icon(Icons.delete_sweep_rounded, size: 20),
              label: const Text('Clear Detection History'),
            ),
          ),
        ],
      ),
    );
  }
}
