import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics 📊')),
      body: Column(
        children: [
          _buildPeriodFilter(),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: ApiService.getAnalyticsSummary(period: _selectedPeriod),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final data = snapshot.data ?? {};
                final totalSales = (data['sales'] as num?)?.toDouble() ?? 0.0;
                final totalProfit = (data['profit'] as num?)?.toDouble() ?? 0.0;
                final totalOrders = data['orders_count'] ?? 0;
                final List<dynamic> trend = data['trend'] ?? [];
                final List<dynamic> catDist = data['category_distribution'] ?? [];
                final List<dynamic> topProducts = data['top_products'] ?? [];
                final khata = data['khata_stats'] ?? {'outstanding': 0, 'collected': 0};

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryGrid(totalSales, totalProfit, totalOrders),
                      const SizedBox(height: 24),
                      
                      // Khata Summary Card
                      _buildKhataSummaryCard(khata),
                      const SizedBox(height: 24),

                      _buildChartCard(
                        context,
                        _getChartTitle(_selectedPeriod),
                        SizedBox(
                          height: 200,
                          child: trend.isEmpty 
                            ? const Center(child: Text('No trend data available'))
                            : LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: trend.asMap().entries.map((e) {
                                    return FlSpot(e.key.toDouble(), (e.value['sales'] as num).toDouble());
                                  }).toList(),
                                  isCurved: true,
                                  color: AppTheme.primaryColor,
                                  barWidth: 4,
                                  dotData: FlDotData(show: _selectedPeriod != 'month'),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 22,
                                    interval: _selectedPeriod == 'month' ? 5 : 1,
                                    getTitlesWidget: (value, meta) {
                                      int idx = value.toInt();
                                      if (idx >= 0 && idx < trend.length) {
                                        return Text(trend[idx]['label'], style: const TextStyle(fontSize: 8, color: Colors.black54));
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Top Products Section
                      _buildTopProductsSection(topProducts),
                      const SizedBox(height: 24),

                      _buildChartCard(
                        context,
                        'Sales by Category',
                        SizedBox(
                          height: 200,
                          child: catDist.isEmpty || (catDist.length == 1 && catDist[0]['name'] == 'No Data')
                            ? const Center(child: Text('No category data'))
                            : PieChart(
                            PieChartData(
                              sections: catDist.asMap().entries.map((e) {
                                final List<Color> colors = [Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.red, Colors.amber];
                                return PieChartSectionData(
                                  value: (e.value['value'] as num).toDouble(),
                                  color: colors[e.key % colors.length],
                                  title: e.value['name'],
                                  radius: 50,
                                  titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text('Quick Insights 💡', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF1E293B))),
                      const SizedBox(height: 16),
                      _buildInsightItem('Active Debtors', '${khata['active_debtors'] ?? 0} customers', Icons.people_outline_rounded, Colors.orange),
                      _buildInsightItem('Top Debtor', khata['top_debtor'] ?? 'None', Icons.person_search_rounded, Colors.redAccent),
                      _buildInsightItem('Avg. Order Value', '₹${totalOrders > 0 ? (totalSales / totalOrders).toStringAsFixed(2) : 0.00}', Icons.analytics_rounded, Colors.amber),
                      _buildInsightItem('Conversion Status', 'Good', Icons.check_circle_rounded, Colors.green),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getChartTitle(String period) {
    switch (period) {
      case 'today': return 'Hourly Sales Trend';
      case 'week': return 'Daily Sales Trend (Week)';
      case 'month': return 'Daily Sales Trend (Month)';
      default: return 'Monthly Sales Trend (All-Time)';
    }
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _filterButton('All-Time', 'all'),
          _filterButton('Today', 'today'),
          _filterButton('Week', 'week'),
          _filterButton('Month', 'month'),
        ],
      ),
    );
  }

  Widget _filterButton(String label, String value) {
    bool isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(double sales, double profit, int orders) {
    return Row(
      children: [
        _buildMiniStat('Sales', '₹${sales.toStringAsFixed(0)}', Colors.green),
        const SizedBox(width: 12),
        _buildMiniStat('Profit', '₹${profit.toStringAsFixed(2)}', Colors.blue),
        const SizedBox(width: 12),
        _buildMiniStat('Orders', '$orders', Colors.orange),
      ],
    );
  }

  Widget _buildKhataSummaryCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade700]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.book_rounded, color: Colors.white70, size: 16),
              SizedBox(width: 8),
              Text('Khata Overview', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text('${(stats['health_score'] ?? 0).toString()}% Recovery Rate', 
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ((stats['health_score'] ?? 0) as num).toDouble() / 100,
              backgroundColor: Colors.white24,
              color: Colors.lightGreenAccent,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildKhataStatItem('Remaining Khata\nBalance', '₹${(stats['outstanding'] as num).toStringAsFixed(0)}', Colors.orangeAccent),
              Container(width: 1, height: 45, color: Colors.white24),
              _buildKhataStatItem('Total Khata\nPaid', '₹${((stats['payed_katha'] ?? 0) as num).toStringAsFixed(0)}', Colors.lightGreenAccent),
            ],
          ),
          const SizedBox(height: 12),
          Text('Total Credit Granted: ₹${((stats['total_khata'] ?? 0) as num).toStringAsFixed(0)}', 
            style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildKhataStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTopProductsSection(List<dynamic> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Selling Products 🚀', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 16),
        ...products.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.star, color: Colors.orange, size: 16),
              ),
              const SizedBox(width: 12),
              Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${p['count']} sold', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            FittedBox(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 20),
          chart,
        ],
      ),
    );
  }

  Widget _buildInsightItem(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: Color(0xFF64748B))),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
