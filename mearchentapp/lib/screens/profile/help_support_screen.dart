import 'package:flutter/material.dart';
import '../../core/theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildContactTile(Icons.email_outlined, 'Email Us', 'support@merchantapp.com'),
          _buildContactTile(Icons.phone_outlined, 'Call Support', '+91 9876543210'),
          _buildContactTile(Icons.language_outlined, 'Help Center', 'www.merchantapp.com/help'),
          const SizedBox(height: 32),
          const Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildFaq('How to add products?', 'Go to Inventory and click the + button to add new items.'),
          _buildFaq('How to record Khata payments?', 'Go to the Khata section, select a customer, and click "Record Payment".'),
          _buildFaq('Can I export data?', 'Data export features will be coming in the next update.'),
        ],
      ),
    );
  }

  Widget _buildContactTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      onTap: () {},
    );
  }

  Widget _buildFaq(String q, String a) {
    return ExpansionTile(
      title: Text(q, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(a, style: const TextStyle(color: Color(0xFF64748B))),
        ),
      ],
    );
  }
}
