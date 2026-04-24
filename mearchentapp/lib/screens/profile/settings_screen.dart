import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'privacy_policy_screen.dart';
import 'about_app_screen.dart';
import 'help_support_screen.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings ⚙️')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsTile(Icons.lock_outline, 'Change Password', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()))),
          _buildSettingsTile(Icons.privacy_tip_outlined, 'Privacy Policy', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
          _buildSettingsTile(Icons.info_outline, 'About App', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppScreen()))),
          _buildSettingsTile(Icons.help_outline, 'Help & Support', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()))),
          const SizedBox(height: 24),
          const Center(child: Text('Version 1.0.0', style: TextStyle(color: Colors.white24))),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
      ),
    );
  }
}
