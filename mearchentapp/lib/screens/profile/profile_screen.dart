import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.getProfile();
      setState(() {
        _profile = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile 👤'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=${_profile?['id'] ?? 'merchant'}'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_profile?['full_name'] ?? 'Merchant User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => EditProfileScreen(currentProfile: _profile!))
                          );
                          if (result == true) _loadProfile();
                        }, 
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue)
                      ),
                    ],
                  ),
                  Text(_profile?['email'] ?? '', style: const TextStyle(color: Colors.white60)),
                  _buildProfileItem(Icons.calendar_today_rounded, 'Joined', _formatDate(_profile?['created_at'])),
                  const SizedBox(height: 32),
                  _buildProfileItem(Icons.store_rounded, 'Shop Name', _profile?['shop_name'] ?? 'My Shop 🏪'),
                  _buildProfileItem(Icons.location_on_rounded, 'Address', _profile?['shop_address'] ?? 'Not set 📍'),
                  const SizedBox(height: 32),
                  ListTile(
                    onTap: () async {
                      await authProvider.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    tileColor: Colors.redAccent.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ],
              ),
            ),
    );
  }



  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white60, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return 'unknown';
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return timestamp;
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
