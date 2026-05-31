import 'package:flutter/material.dart';
import '../models/sale_response.dart';
import 'package:intl/intl.dart';

// ==================== COULEURS MAROCAINES ====================
class MoroccanColors {
  static const primary = Color(0xFFD4392C);
  static const secondary = Color(0xFF006233);
  static const gold = Color(0xFFD4AF37);
  static const terracotta = Color(0xFFE07A5F);
  static const blue = Color(0xFF3D5A80);
  static const cream = Color(0xFFF4F1DE);
  static const darkGreen = Color(0xFF2A4A3A);
  static const orange = Color(0xFFF77F00);
}

class RevenuDetailsScreen extends StatefulWidget {
  final String token;
  final List<SaleResponse> history;
  final String period;

  const RevenuDetailsScreen({
    super.key,
    required this.token,
    required this.history,
    required this.period,
  });

  @override
  State<RevenuDetailsScreen> createState() => _RevenuDetailsScreenState();
}

class _RevenuDetailsScreenState extends State<RevenuDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Filter logic
    final filteredSales = widget.history.where((sale) {
      final saleDate = DateTime.fromMillisecondsSinceEpoch(sale.saleDate);

      if (widget.period == "TODAY") {
        return saleDate.day == now.day &&
            saleDate.month == now.month &&
            saleDate.year == now.year;
      } else if (widget.period == "LAST_30_DAYS") {
        return saleDate.isAfter(now.subtract(const Duration(days: 30)));
      } else if (widget.period == "LAST_6_MONTHS") {
        return saleDate.isAfter(now.subtract(const Duration(days: 180)));
      }
      return true;
    }).toList();

    filteredSales.sort((a, b) => b.saleDate.compareTo(a.saleDate));

    // Calculate totals
    double totalRevenue = 0;
    double totalProfit = 0;
    for (var sale in filteredSales) {
      totalRevenue += sale.totalAmount;
      totalProfit += sale.totalProfit;
    }

    // Dynamic title
    String title = "الإيرادات";
    if (widget.period == "TODAY") title = "إيرادات اليوم";
    if (widget.period == "LAST_30_DAYS") title = "إيرادات 30 يوم";
    if (widget.period == "LAST_6_MONTHS") title = "إيرادات 6 أشهر";

    return Scaffold(
      backgroundColor: MoroccanColors.cream,
      appBar: _buildMoroccanAppBar(title),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeaderSummary(
              totalRevenue,
              totalProfit,
              filteredSales.length,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredSales.isEmpty
                  ? _buildEmptyState()
                  : _buildSalesList(filteredSales),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMoroccanAppBar(String title) {
    return AppBar(
      backgroundColor: MoroccanColors.secondary,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [MoroccanColors.secondary, MoroccanColors.darkGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: MoroccanColors.gold),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MoroccanColors.gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: MoroccanColors.gold, width: 1.5),
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: MoroccanColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSummary(
    double totalRevenue,
    double totalProfit,
    int salesCount,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MoroccanColors.secondary, MoroccanColors.darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MoroccanColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: MoroccanColors.secondary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.attach_money_rounded,
                  label: "رقم الأعمال",
                  value: "${totalRevenue.toStringAsFixed(2)} DH",
                ),
              ),
              Container(
                width: 2,
                height: 60,
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
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.trending_up_rounded,
                  label: "الربح الصافي",
                  value: "${totalProfit.toStringAsFixed(2)} DH",
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: MoroccanColors.gold.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_rounded,
                  color: MoroccanColors.gold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "عدد المبيعات: $salesCount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: MoroccanColors.gold, width: 2),
          ),
          child: Icon(icon, color: MoroccanColors.gold, size: 26),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSalesList(List<SaleResponse> sales) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: sales.length,
      itemBuilder: (context, index) {
        return _buildSaleCard(sales[index], index);
      },
    );
  }

  Widget _buildSaleCard(SaleResponse sale, int index) {
    final date = DateTime.fromMillisecondsSinceEpoch(sale.saleDate);
    final formattedDate = DateFormat('dd/MM à HH:mm').format(date);
    final isToday =
        date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MoroccanColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: MoroccanColors.gold.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [MoroccanColors.cream, Colors.white],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            MoroccanColors.blue,
                            MoroccanColors.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: MoroccanColors.gold,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.receipt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: MoroccanColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: MoroccanColors.blue.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 11,
                                color: MoroccanColors.darkGreen.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: MoroccanColors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: MoroccanColors.orange,
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  "اليوم",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: MoroccanColors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        MoroccanColors.secondary,
                        MoroccanColors.darkGreen,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: MoroccanColors.gold, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "الربح",
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      Text(
                        "+${sale.totalProfit.toStringAsFixed(1)} DH",
                        style: const TextStyle(
                          color: MoroccanColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...sale.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: MoroccanColors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "×${item.quantity}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: MoroccanColors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: MoroccanColors.darkGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: MoroccanColors.gold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: MoroccanColors.gold.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            "${item.totalPrice.toStringAsFixed(2)} DH",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: MoroccanColors.darkGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        MoroccanColors.gold.withOpacity(0.1),
                        MoroccanColors.orange.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MoroccanColors.gold, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "المجموع الكلي:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: MoroccanColors.darkGreen,
                        ),
                      ),
                      Text(
                        "${sale.totalAmount.toStringAsFixed(2)} DH",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MoroccanColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [MoroccanColors.secondary, MoroccanColors.darkGreen],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: MoroccanColors.gold, width: 3),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 60,
              color: MoroccanColors.gold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "لا توجد مبيعات",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: MoroccanColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "لا توجد مبيعات في هذه الفترة",
            style: TextStyle(
              fontSize: 14,
              color: MoroccanColors.darkGreen.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
