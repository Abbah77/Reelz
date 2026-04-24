import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoplayEnabled = true;
  String _videoQuality = 'Auto';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _autoplayEnabled = prefs.getBool('autoplay') ?? true;
      _videoQuality = prefs.getString('video_quality') ?? 'Auto';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildSwitchTile(
            'Notifications',
            'Receive notifications for new episodes',
            _notificationsEnabled,
            Icons.notifications,
            (value) async {
              setState(() => _notificationsEnabled = value);
              final prefs = await SharedPreferences.getInstance();
              prefs.setBool('notifications', value);
            },
          ),
          
          _buildSwitchTile(
            'Autoplay',
            'Automatically play next episode',
            _autoplayEnabled,
            Icons.autorenew,
            (value) async {
              setState(() => _autoplayEnabled = value);
              final prefs = await SharedPreferences.getInstance();
              prefs.setBool('autoplay', value);
            },
          ),
          
          _buildQualitySelector(),
          
          _buildListTile(
            'Download Quality',
            'Standard Definition',
            Icons.download,
            () {},
          ),
          
          _buildListTile(
            'Clear Cache',
            'Free up storage space',
            Icons.delete_sweep,
            () async {
              await DefaultCacheManager().emptyCache();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared')),
                );
              }
            },
          ),
          
          const Divider(color: Colors.white24),
          
          _buildListTile(
            'About Reelz',
            'Version 1.0.0',
            Icons.info,
            () {},
          ),
          
          _buildListTile(
            'Privacy Policy',
            'Read our privacy policy',
            Icons.privacy_tip,
            () {},
          ),
          
          _buildListTile(
            'Terms of Service',
            'Read our terms',
            Icons.description,
            () {},
          ),
        ],
      ),
    );
  }
  
  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      secondary: Icon(icon, color: Colors.white54),
      value: value,
      activeColor: AppTheme.electricBlue,
      onChanged: onChanged,
    );
  }
  
  Widget _buildQualitySelector() {
    return ListTile(
      leading: const Icon(Icons.high_quality, color: Colors.white54),
      title: const Text('Video Quality', style: TextStyle(color: Colors.white)),
      subtitle: Text(_videoQuality, style: const TextStyle(color: Colors.white54)),
      trailing: DropdownButton<String>(
        value: _videoQuality,
        dropdownColor: AppTheme.surfaceDark,
        style: const TextStyle(color: Colors.white),
        items: ['Auto', '720p', '1080p']
            .map((quality) => DropdownMenuItem(
                  value: quality,
                  child: Text(quality, style: const TextStyle(color: Colors.white)),
                ))
            .toList(),
        onChanged: (value) async {
          setState(() => _videoQuality = value!);
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('video_quality', value);
        },
      ),
    );
  }
  
  Widget _buildListTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white54),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }
}
