import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../inventory/add_product_screen.dart';
import '../inventory/category_management_screen.dart';
import '../orders/create_order_screen.dart';
import '../orders/orders_screen.dart';
import 'notifications_screen.dart';
import '../khata/khata_screen.dart';

import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoadingProfile = true;

  void _handleAuthError() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getProfile();
      setState(() {
        _profile = profile;
        _isLoadingProfile = false;
      });
    } catch (e) {
      setState(() => _isLoadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadProfile();
            setState(() {});
          },
          child: FutureBuilder<Map<String, dynamic>>(
            future: ApiService.getAnalyticsSummary(period: 'today'),
            builder: (context, summarySnapshot) {
              if (summarySnapshot.hasError) {
                if (summarySnapshot.error is UnauthorizedException) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _handleAuthError());
                  return const Center(child: CircularProgressIndicator());
                }
                return Center(child: Text('Error loading stats: ${summarySnapshot.error}'));
              }
              
              final summary = summarySnapshot.data ?? {
                'sales': 0,
                'profit': 0,
                'orders_count': 0,
              };
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 30),
                    
                    // Stats Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(context, 'Today Sales', '₹${summary['sales'].toStringAsFixed(0)}', Icons.payments_rounded, Colors.green),
                        _buildStatCard(context, 'Today Profit', '₹${summary['profit'].toStringAsFixed(0)}', Icons.trending_up_rounded, Colors.blue),
                        _buildStatCard(context, 'Total Orders', '${summary['orders_count']}', Icons.shopping_bag_rounded, Colors.orange),
                        _buildStatCard(context, 'Inventory', 'View Stock', Icons.inventory_2_rounded, Colors.purple),
                        FutureBuilder<Map<String, dynamic>>(
                          future: ApiService.getCreditSummary(),
                          builder: (context, snapshot) {
                            final data = snapshot.data ?? {'customer_count': 0, 'total_amount': 0};
                            return InkWell(
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KhataScreen())),
                              child: _buildStatCard(context, 'Khata (Credit)', '${data['customer_count']} Customers', Icons.book_rounded, Colors.redAccent),
                            );
                          }
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    Text('Quick Actions 🔥', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF1E293B))),
                    const SizedBox(height: 16),
                    _buildQuickActions(context),
                    
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Orders', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF1E293B))),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen())), 
                          child: const Text('View All')
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildRecentOrderList(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome back,', style: TextStyle(color: Color(0xFF64748B))),
            Text(_isLoadingProfile ? 'Loading...' : '${_profile?['full_name'] ?? "Merchant"} 🏪', 
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF1E293B))),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: AppTheme.primaryColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: _buildActionChip(context, 'Add Product', Icons.add_box_rounded, () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddProductScreen()));
              setState(() {});
            }),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: _buildActionChip(context, 'Create Order', Icons.receipt_long_rounded, () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateOrderScreen()));
              setState(() {});
            }),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: _buildActionChip(context, 'New Category', Icons.category_rounded, () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoryManagementScreen()));
              setState(() {});
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ),
              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.accentColor]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.add, color: Colors.white, size: 20),
            Icon(icon, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrderList() {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getUnifiedHistory(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          if (snapshot.error is UnauthorizedException) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _handleAuthError());
            return const Center(child: CircularProgressIndicator());
          }
        }
        final activity = snapshot.data ?? [];
        if (activity.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('No recent activity', style: TextStyle(color: Color(0xFF64748B))),
          ));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activity.length > 5 ? 5 : activity.length,
          itemBuilder: (context, index) {
            final item = activity[index];
            final bool isPayment = item['type'] == 'payment';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPayment ? Colors.green.withValues(alpha: 0.05) : AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isPayment ? Colors.green.withValues(alpha: 0.1) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPayment ? Colors.green : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPayment ? Icons.payment : Icons.receipt_rounded, 
                      color: isPayment ? Colors.white : const Color(0xFF64748B)
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPayment ? 'Payment Recieved' : 'Order #${item['id'].toString().substring(0, 8)}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))
                        ),
                        Text(
                          isPayment 
                            ? 'From ${item['customers']?['name'] ?? 'Customer'}' 
                            : (item['payment_status'] == 'credit' ? 'Bal: ₹${(item['final_amount'] - item['paid_amount']).toStringAsFixed(0)} 📔' : 'Paid ✅'), 
                          style: TextStyle(
                            color: isPayment ? Colors.green : (item['payment_status'] == 'credit' ? Colors.orange : Colors.green), 
                            fontSize: 12,
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isPayment ? "+" : ""}₹${isPayment ? item['amount'] : item['final_amount']}', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: isPayment ? Colors.green : const Color(0xFF1E293B),
                      fontSize: 16
                    )
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
