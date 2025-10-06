import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaflens/core/config/app_config.dart';
import 'package:leaflens/core/services/storage_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _privacyMode = AppConfig.privacyMode;
  bool _enableTelemetry = AppConfig.enableTelemetry;
  bool _enableNotifications = true;
  String _region = AppConfig.regionCode;
  String _language = 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Privacy Section
          _SettingsSection(
            title: 'Privacy & Security',
            children: [
              _SettingsTile(
                title: 'Privacy Mode',
                subtitle: 'Control how your data is handled',
                trailing: DropdownButton<String>(
                  value: _privacyMode,
                  onChanged: (value) {
                    setState(() {
                      _privacyMode = value!;
                    });
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'offline',
                      child: Text('Offline Only'),
                    ),
                    DropdownMenuItem(
                      value: 'pseudonymous',
                      child: Text('Pseudonymous'),
                    ),
                    DropdownMenuItem(
                      value: 'cloud',
                      child: Text('Cloud Assisted'),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                title: const Text('Enable Telemetry'),
                subtitle: const Text('Help improve the app with anonymous usage data'),
                value: _enableTelemetry,
                onChanged: (value) {
                  setState(() {
                    _enableTelemetry = value;
                  });
                },
              ),
              ListTile(
                title: const Text('Clear All Data'),
                subtitle: const Text('Delete all stored data and history'),
                trailing: const Icon(Icons.delete_forever),
                onTap: _showClearDataDialog,
              ),
            ],
          ),
          
          // Notifications Section
          _SettingsSection(
            title: 'Notifications',
            children: [
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive alerts and updates'),
                value: _enableNotifications,
                onChanged: (value) {
                  setState(() {
                    _enableNotifications = value;
                  });
                },
              ),
            ],
          ),
          
          // Regional Settings
          _SettingsSection(
            title: 'Regional Settings',
            children: [
              _SettingsTile(
                title: 'Region',
                subtitle: 'Select your region for localized content',
                trailing: DropdownButton<String>(
                  value: _region,
                  onChanged: (value) {
                    setState(() {
                      _region = value!;
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: 'US', child: Text('United States')),
                    DropdownMenuItem(value: 'EU', child: Text('Europe')),
                    DropdownMenuItem(value: 'TR', child: Text('Turkey')),
                    DropdownMenuItem(value: 'CA', child: Text('Canada')),
                    DropdownMenuItem(value: 'AU', child: Text('Australia')),
                  ],
                ),
              ),
              _SettingsTile(
                title: 'Language',
                subtitle: 'Choose your preferred language',
                trailing: DropdownButton<String>(
                  value: _language,
                  onChanged: (value) {
                    setState(() {
                      _language = value!;
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'es', child: Text('Spanish')),
                    DropdownMenuItem(value: 'fr', child: Text('French')),
                    DropdownMenuItem(value: 'de', child: Text('German')),
                    DropdownMenuItem(value: 'tr', child: Text('Turkish')),
                  ],
                ),
              ),
            ],
          ),
          
          // App Information
          _SettingsSection(
            title: 'App Information',
            children: [
              ListTile(
                title: const Text('Version'),
                subtitle: Text(AppConfig.appVersion),
                trailing: const Icon(Icons.info_outline),
              ),
              ListTile(
                title: const Text('About LeafLens'),
                subtitle: const Text('Learn more about the app'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _showAboutDialog,
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                subtitle: const Text('Read our privacy policy'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Open privacy policy
                },
              ),
              ListTile(
                title: const Text('Terms of Service'),
                subtitle: const Text('Read our terms of service'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Open terms of service
                },
              ),
            ],
          ),
          
          // Support Section
          _SettingsSection(
            title: 'Support',
            children: [
              ListTile(
                title: const Text('Help & FAQ'),
                subtitle: const Text('Get help and find answers'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Open help
                },
              ),
              ListTile(
                title: const Text('Contact Support'),
                subtitle: const Text('Get in touch with our team'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Open contact
                },
              ),
              ListTile(
                title: const Text('Report Bug'),
                subtitle: const Text('Help us improve the app'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Open bug report
                },
              ),
            ],
          ),
          
          // Cache Management
          _SettingsSection(
            title: 'Storage',
            children: [
              ListTile(
                title: const Text('Cache Size'),
                subtitle: Text('${StorageService.getCacheSize()} items stored'),
                trailing: const Icon(Icons.storage),
              ),
              ListTile(
                title: const Text('Clear Cache'),
                subtitle: const Text('Free up storage space'),
                trailing: const Icon(Icons.cleaning_services),
                onTap: _showClearCacheDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all your diagnosis history, settings, and cached data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              StorageService.clearCache();
              setState(() {});
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear temporary files and cached data to free up storage space.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              StorageService.clearOldCache();
              setState(() {});
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'LeafLens',
      applicationVersion: AppConfig.appVersion,
      applicationIcon: const Icon(
        Icons.eco,
        size: 48,
        color: Colors.green,
      ),
      children: [
        const Text(
          'LeafLens is an AI-powered plant health companion that helps you diagnose '
          'diseases, nutrient deficiencies, and pests from a single leaf photo.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text('• On-device AI analysis for privacy'),
        const Text('• Comprehensive plant health diagnosis'),
        const Text('• Regional outbreak mapping'),
        const Text('• Expert treatment recommendations'),
        const Text('• Offline functionality'),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }
}