import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Dark Mode'),
              subtitle: Text(
                themeService.isDarkMode
                    ? 'Dark theme enabled'
                    : 'Light theme enabled',
              ),
              trailing: Switch(
                value: themeService.isDarkMode,
                onChanged: (_) => themeService.toggleTheme(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('About'),
                  subtitle: const Text('Weather Crops App'),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.code,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.verified,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('License'),
                  subtitle: const Text('FOSS - Free and Open Source Software'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.notifications,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Notifications'),
              subtitle: const Text('Planting recommendations and alerts'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
          // Removed Logout card; logout is now in the App Drawer.
        ],
      ),
    );
  }
}