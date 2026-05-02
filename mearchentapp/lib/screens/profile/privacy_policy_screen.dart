import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('1. Data Collection', 'We collect basic profile information such as your name, shop name, and email to provide the service. Transactional data is stored securely in our database.'),
            _section('2. Usage of Data', 'Your data is used solely for managing your inventory and billing. We do not sell your data to third parties.'),
            _section('3. Security', 'We use industry-standard encryption to protect your data and authentication sessions.'),
            _section('4. Your Rights', 'You can request to delete your account and all associated data at any time via the profile settings.'),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: Color(0xFF64748B), height: 1.5)),
        ],
      ),
    );
  }
}
