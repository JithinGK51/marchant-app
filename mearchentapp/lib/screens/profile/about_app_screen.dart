import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Merchant App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.storefront_rounded, size: 80, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            const Text('Merchant Inventory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'A complete solution for small to medium merchants to manage inventory, billing, and customer credit (Khata) with ease.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), height: 1.5),
              ),
            ),
            const Spacer(),
            const Text('© 2024 Jithin GK. All rights reserved.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
