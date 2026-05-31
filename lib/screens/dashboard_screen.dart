import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hanout_frontend/screens/revenu_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

// Screens
import 'package:hanout_frontend/screens/add_product_screen.dart';
import 'package:hanout_frontend/screens/debt_list_screen.dart';
import 'package:hanout_frontend/screens/product_list_screen.dart';
import 'package:hanout_frontend/screens/new_sale_screen.dart';
import 'package:hanout_frontend/screens/sale_history_screen.dart';
import 'login_screen.dart';

// Services & Models
import 'package:hanout_frontend/services/debt_service.dart';
import 'package:hanout_frontend/services/product_service.dart';
import 'package:hanout_frontend/services/sale_service.dart';
import 'package:hanout_frontend/services/sync_service.dart';
import '../models/stats_response.dart';
import '../models/sale_response.dart';
import '../services/stats_service.dart';

// ==================== COULEURS MAROCAINES ====================
class MoroccanColors {
  static const primary = Color(0xFFD4392C); // Rouge Marocain
  static const secondary = Color(0xFF006233); // Vert Marocain
  static const gold = Color(0xFFD4AF37); // Or
  static const terracotta = Color(0xFFE07A5F); // Terre cuite
  static const blue = Color(0xFF3D5A80); // Bleu Fès
  static const cream = Color(0xFFF4F1DE); // Crème
  static const darkGreen = Color(0xFF2A4A3A); // Vert foncé
  static const orange = Color(0xFFF77F00); // Orange épices
}

class DashboardScreen extends StatefulWidget {
  final String token;
  const DashboardScreen({super.key, required this.token});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final StatsService _statsService = StatsService();
  final SaleService _saleService = SaleService();

  StatsResponse? _stats;
  List<SaleResponse> _history = [];

  String _selectedPeriod = "TODAY";
  bool _isLoading = true;
  bool _isOffline = false;
  bool _isSyncing = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _fetchStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _fetchStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    var connectivityResult = await (Connectivity().checkConnectivity());
    _isOffline = connectivityResult == ConnectivityResult.none;

    final statsData = await _statsService.getStats(
      widget.token,
      _selectedPeriod,
    );
    final historyData = await _saleService.getSalesHistory(widget.token);

    if (!mounted) return;
    setState(() {
      _stats = statsData;
      _history = historyData;
      _isLoading = false;
    });

    _animationController.forward(from: 0.0);
  }

  List<BarChartGroupData> _generateChartData(List<SaleResponse> history) {
    List<double> dailyTotals = List.filled(7, 0.0);
    DateTime now = DateTime.now();

    for (var sale in history) {
      DateTime saleDate = DateTime.fromMillisecondsSinceEpoch(sale.saleDate);
      int difference = now.difference(saleDate).inDays;
      if (difference >= 0 && difference < 7) {
        dailyTotals[6 - difference] += sale.totalAmount;
      }
    }

    return List.generate(7, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: dailyTotals[i] == 0 ? 0.1 : dailyTotals[i],
            gradient: const LinearGradient(
              colors: [MoroccanColors.gold, MoroccanColors.orange],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ],
      );
    });
  }

  double _getMaxY(List<SaleResponse> history) {
    List<double> dailyTotals = List.filled(7, 0.0);
    DateTime now = DateTime.now();

    for (var sale in history) {
      DateTime saleDate = DateTime.fromMillisecondsSinceEpoch(sale.saleDate);
      int difference = now.difference(saleDate).inDays;
      if (difference >= 0 && difference < 7) {
        dailyTotals[6 - difference] += sale.totalAmount;
      }
    }

    double max = dailyTotals.isEmpty
        ? 100
        : dailyTotals.reduce((a, b) => a > b ? a : b);
    return max == 0 ? 100 : (max * 1.3).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoroccanColors.cream,
      drawer: _buildDrawer(),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _fetchStats,
              color: MoroccanColors.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildPeriodSelector(),
                          const SizedBox(height: 20),
                          if (_stats != null) _buildQuickStats(),
                          const SizedBox(height: 20),
                          if (_stats != null) _buildStatsGrid(),
                          const SizedBox(height: 20),
                          _buildWeeklyChart(_history),
                          const SizedBox(height: 20),
                          _buildQuickActions(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _buildMoroccanFAB(),
    );
  }

  // ==================== SLIVER APP BAR MAROCAIN ====================
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: MoroccanColors.primary,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: MoroccanColors.gold),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: Row(
          children: [
            const Text(
              "لوحة القيادة",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Arial',
              ),
            ),
            if (_isOffline) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: MoroccanColors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MoroccanColors.gold, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.wifi_off, size: 9, color: MoroccanColors.gold),
                    SizedBox(width: 3),
                    Text(
                      "Offline",
                      style: TextStyle(fontSize: 8, color: MoroccanColors.gold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [MoroccanColors.primary, MoroccanColors.darkGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _MoroccanPatternPainter()),
            ),
            Positioned(
              top: 70,
              left: 20,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "مرحبا",
                        style: TextStyle(
                          fontSize: 16,
                          color: MoroccanColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(DateTime.now()),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _fetchStats,
          icon: const Icon(Icons.refresh_rounded, color: MoroccanColors.gold),
        ),
        _buildSyncButton(),
        const SizedBox(width: 8),
      ],
    );
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd MMMM yyyy', 'ar_MA').format(date);
    } catch (e) {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  // ==================== QUICK STATS MAROCAIN ====================
  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MoroccanColors.primary, MoroccanColors.darkGreen],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MoroccanColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: MoroccanColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _MoroccanBorderPainter()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStatItem(
                Icons.trending_up_rounded,
                "الإيرادات",
                "${_stats!.totalRevenue.toStringAsFixed(0)} DH",
              ),
              Container(
                height: 50,
                width: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      MoroccanColors.gold.withOpacity(0.3),
                      MoroccanColors.gold,
                      MoroccanColors.gold.withOpacity(0.3),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              _buildQuickStatItem(
                Icons.shopping_bag_rounded,
                "المبيعات",
                "${_stats!.salesCount}",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MoroccanColors.gold.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: MoroccanColors.gold, width: 2),
          ),
          child: Icon(icon, color: MoroccanColors.gold, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ==================== PERIOD SELECTOR MAROCAIN ====================
  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: MoroccanColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: MoroccanColors.gold.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPeriodChip("اليوم", "TODAY"),
          const SizedBox(width: 8),
          _buildPeriodChip("30 يوم", "LAST_30_DAYS"),
          const SizedBox(width: 8),
          _buildPeriodChip("6 أشهر", "LAST_6_MONTHS"),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    bool isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedPeriod != value) {
            setState(() => _selectedPeriod = value);
            _fetchStats();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [MoroccanColors.primary, MoroccanColors.darkGreen],
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: MoroccanColors.gold, width: 1.5)
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : MoroccanColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== STATS GRID MAROCAIN ====================
  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.35,
        children: [
          _buildMoroccanCard(
            "مخزون ضعيف",
            "${_stats!.lowStockProductsCount}",
            Icons.warning_amber_rounded,
            MoroccanColors.orange,
            MoroccanColors.terracotta,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductListScreen(
                  token: widget.token,
                  showOnlyLowStock: true,
                ),
              ),
            ),
          ),
          _buildMoroccanCard(
            "المخزون الكلي",
            "عرض",
            Icons.inventory_2_rounded,
            MoroccanColors.secondary,
            MoroccanColors.darkGreen,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductListScreen(token: widget.token),
              ),
            ),
          ),
          _buildMoroccanCard(
            "بيع جديد",
            "بيع",
            Icons.point_of_sale_rounded,
            MoroccanColors.blue,
            const Color(0xFF2C3E50),
            onTap: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewSaleScreen(token: widget.token),
                ),
              );
              if (res == true) _fetchStats();
            },
          ),
          _buildMoroccanCard(
            "دفتر الديون",
            "كناش",
            Icons.menu_book_rounded,
            MoroccanColors.gold,
            const Color(0xFFB8860B),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DebtListScreen(token: widget.token),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoroccanCard(
    String title,
    String value,
    IconData icon,
    Color color1,
    Color color2, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color1, color2],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: MoroccanColors.gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: color1.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: CustomPaint(
                  size: const Size(60, 60),
                  painter: _CornerPatternPainter(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: MoroccanColors.gold.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== WEEKLY CHART MAROCAIN ====================
  Widget _buildWeeklyChart(List<SaleResponse> history) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MoroccanColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: MoroccanColors.gold.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [MoroccanColors.primary, MoroccanColors.darkGreen],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: MoroccanColors.gold, width: 1.5),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "الأداء",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: MoroccanColors.primary,
                      ),
                    ),
                    Text(
                      "آخر 7 أيام",
                      style: TextStyle(
                        fontSize: 11,
                        color: MoroccanColors.darkGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: MoroccanColors.primary,
                    tooltipRoundedRadius: 10,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(0)} DH',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: MoroccanColors.gold.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        DateTime date = DateTime.now().subtract(
                          Duration(days: 6 - value.toInt()),
                        );
                        String formattedDate = DateFormat('dd/MM').format(date);
                        bool isToday = value.toInt() == 6;

                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 10,
                              color: isToday
                                  ? MoroccanColors.primary
                                  : MoroccanColors.darkGreen,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: _generateChartData(history),
                maxY: _getMaxY(history),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== QUICK ACTIONS MAROCAIN ====================
  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MoroccanColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: MoroccanColors.gold.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "إجراءات سريعة",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MoroccanColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  "السجل",
                  Icons.history_rounded,
                  MoroccanColors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SaleHistoryScreen(token: widget.token),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  "الإيرادات",
                  Icons.monetization_on_rounded,
                  MoroccanColors.secondary,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RevenuDetailsScreen(
                        token: widget.token,
                        history: _history,
                        period: _selectedPeriod,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MoroccanColors.gold, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SYNC BUTTON ====================
  Widget _buildSyncButton() {
    return _isSyncing
        ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: MoroccanColors.gold,
                strokeWidth: 2.5,
              ),
            ),
          )
        : IconButton(
            icon: const Icon(
              Icons.cloud_sync_rounded,
              size: 26,
              color: MoroccanColors.gold,
            ),
            tooltip: "مزامنة",
            onPressed: () async {
              var connectivityResult = await (Connectivity()
                  .checkConnectivity());
              if (connectivityResult == ConnectivityResult.none) {
                _showSnackBar(
                  "لا يوجد اتصال بالإنترنت!",
                  MoroccanColors.orange,
                );
                return;
              }
              setState(() => _isSyncing = true);
              try {
                await SyncService().syncData(widget.token);
                await ProductService().getProducts(widget.token);
                await DebtService().getDebts(widget.token);
                await _fetchStats();
                _showSnackBar("تمت المزامنة!", MoroccanColors.secondary);
              } catch (e) {
                _showSnackBar("خطأ", MoroccanColors.primary);
              } finally {
                if (mounted) setState(() => _isSyncing = false);
              }
            },
          );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: MoroccanColors.gold, width: 1.5),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ==================== DRAWER MAROCAIN ====================
  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [MoroccanColors.primary, MoroccanColors.darkGreen],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: MoroccanColors.gold,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        size: 45,
                        color: MoroccanColors.gold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "مول الحانوت",
                      style: TextStyle(
                        color: MoroccanColors.gold,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "جلسة نشطة",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: MoroccanColors.cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    _buildDrawerItem(
                      Icons.dashboard_rounded,
                      "لوحة القيادة",
                      MoroccanColors.primary,
                      () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      Icons.inventory_2_rounded,
                      "إدارة المخزون",
                      MoroccanColors.secondary,
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductListScreen(token: widget.token),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.menu_book_rounded,
                      "دفتر الديون",
                      MoroccanColors.gold,
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DebtListScreen(token: widget.token),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.history_rounded,
                      "السجل",
                      MoroccanColors.blue,
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SaleHistoryScreen(token: widget.token),
                          ),
                        );
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Divider(
                        color: MoroccanColors.gold,
                        thickness: 1.5,
                      ),
                    ),
                    _buildDrawerItem(
                      Icons.logout_rounded,
                      "تسجيل الخروج",
                      MoroccanColors.orange,
                      _logout,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        textAlign: TextAlign.right,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  // ==================== MOROCCAN FAB ====================
  Widget _buildMoroccanFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MoroccanColors.primary, MoroccanColors.darkGreen],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MoroccanColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: MoroccanColors.primary.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(
          Icons.add_rounded,
          color: MoroccanColors.gold,
          size: 26,
        ),
        label: const Text(
          "إضافة منتج",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddProductScreen(token: widget.token),
            ),
          );
          if (res == true) _fetchStats();
        },
      ),
    );
  }

  // ==================== LOADING STATE ====================
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [MoroccanColors.primary, MoroccanColors.darkGreen],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: MoroccanColors.gold, width: 3),
            ),
            child: const CircularProgressIndicator(
              color: MoroccanColors.gold,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "جاري التحميل...",
            style: TextStyle(
              color: MoroccanColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== MOROCCAN PATTERN PAINTER ====================
class _MoroccanPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 30.0;

    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        _drawStar(canvas, Offset(i, j), 8, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    const points = 8;
    final path = Path();

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi) / points;
      final r = i.isEven ? radius : radius / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==================== MOROCCAN BORDER PAINTER ====================
class _MoroccanBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MoroccanColors.gold.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 15.0;

    // Top border pattern
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + spacing / 2, spacing / 2),
        paint,
      );
      canvas.drawLine(
        Offset(i + spacing / 2, spacing / 2),
        Offset(i + spacing, 0),
        paint,
      );
    }

    // Bottom border pattern
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + spacing / 2, size.height - spacing / 2),
        paint,
      );
      canvas.drawLine(
        Offset(i + spacing / 2, size.height - spacing / 2),
        Offset(i + spacing, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==================== CORNER PATTERN PAINTER ====================
class _CornerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MoroccanColors.gold.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.7, size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
