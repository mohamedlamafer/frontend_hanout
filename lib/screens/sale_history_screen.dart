import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale_response.dart';
import '../services/sale_service.dart';

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

class SaleHistoryScreen extends StatefulWidget {
  final String token;
  const SaleHistoryScreen({super.key, required this.token});

  @override
  State<SaleHistoryScreen> createState() => _SaleHistoryScreenState();
}

class _SaleHistoryScreenState extends State<SaleHistoryScreen>
    with SingleTickerProviderStateMixin {
  final SaleService _saleService = SaleService();
  List<SaleResponse> _sales = [];
  bool _isLoading = true;

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
    _loadHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final data = await _saleService.getSalesHistory(widget.token);

    setState(() {
      data.sort((a, b) => b.saleDate.compareTo(a.saleDate));
      _sales = data;
      _isLoading = false;
    });

    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoroccanColors.cream,
      appBar: _buildMoroccanAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _sales.isEmpty
          ? _buildEmptyState()
          : _buildHistoryList(),
    );
  }

  PreferredSizeWidget _buildMoroccanAppBar() {
    return AppBar(
      backgroundColor: MoroccanColors.blue,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [MoroccanColors.blue, MoroccanColors.darkGreen],
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
              Icons.history_rounded,
              color: MoroccanColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "سجل المبيعات",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _loadHistory,
          icon: const Icon(Icons.refresh_rounded, color: MoroccanColors.gold),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHistoryList() {
    // Calculate summary
    double totalRevenue = 0;
    double totalProfit = 0;
    for (var sale in _sales) {
      totalRevenue += sale.totalAmount;
      totalProfit += sale.totalProfit;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildSummaryCard(totalRevenue, totalProfit),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadHistory,
              color: MoroccanColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                itemCount: _sales.length,
                itemBuilder: (context, index) {
                  return _buildSaleCard(_sales[index], index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double totalRevenue, double totalProfit) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MoroccanColors.blue, MoroccanColors.darkGreen],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MoroccanColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: MoroccanColors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.sell_rounded,
                  label: "إجمالي المبيعات",
                  value: "${totalRevenue.toStringAsFixed(2)} DH",
                ),
              ),
              Container(
                width: 2,
                height: 50,
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
                  label: "إجمالي الأرباح",
                  value: "${totalProfit.toStringAsFixed(2)} DH",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: MoroccanColors.gold.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: MoroccanColors.gold,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "العدد الكلي: ${_sales.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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
        Icon(icon, color: MoroccanColors.gold, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSaleCard(SaleResponse sale, int index) {
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
      sale.saleDate,
    );
    final String formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);
    final String formattedTime = DateFormat('HH:mm').format(dateTime);
    final bool isCash = sale.paymentMethod == "CASH";

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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCash
                    ? [MoroccanColors.secondary, MoroccanColors.darkGreen]
                    : [MoroccanColors.orange, MoroccanColors.terracotta],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: MoroccanColors.gold, width: 2),
            ),
            child: Icon(
              isCash ? Icons.payments_rounded : Icons.menu_book_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${sale.totalAmount.toStringAsFixed(2)} DH",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: MoroccanColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: MoroccanColors.blue.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$formattedDate à $formattedTime",
                          style: TextStyle(
                            fontSize: 11,
                            color: MoroccanColors.darkGreen.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 12,
                          color: MoroccanColors.blue.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            sale.customerName,
                            style: TextStyle(
                              fontSize: 11,
                              color: MoroccanColors.darkGreen.withOpacity(0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
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
                      "+${sale.totalProfit.toStringAsFixed(1)}",
                      style: const TextStyle(
                        color: MoroccanColors.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MoroccanColors.cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: MoroccanColors.gold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              MoroccanColors.blue,
                              MoroccanColors.darkGreen,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.shopping_cart_rounded,
                          color: MoroccanColors.gold,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "المنتجات:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: MoroccanColors.darkGreen,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...sale.items.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: MoroccanColors.gold.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: MoroccanColors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: MoroccanColors.blue,
                                width: 1,
                              ),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: MoroccanColors.darkGreen,
                                  ),
                                ),
                                Text(
                                  "${item.sellPrice} DH/unité",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: MoroccanColors.darkGreen.withOpacity(
                                      0.6,
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
                              gradient: const LinearGradient(
                                colors: [
                                  MoroccanColors.gold,
                                  MoroccanColors.orange,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${item.totalPrice.toStringAsFixed(2)} DH",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                colors: [MoroccanColors.blue, MoroccanColors.darkGreen],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: MoroccanColors.gold, width: 3),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 60,
              color: MoroccanColors.gold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "لا يوجد سجل",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: MoroccanColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "لا توجد مبيعات مسجلة",
            style: TextStyle(
              fontSize: 14,
              color: MoroccanColors.darkGreen.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [MoroccanColors.blue, MoroccanColors.darkGreen],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: MoroccanColors.gold, width: 3),
            ),
            child: const CircularProgressIndicator(
              color: MoroccanColors.gold,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "جاري التحميل...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MoroccanColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
