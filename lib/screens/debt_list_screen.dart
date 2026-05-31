import 'package:flutter/material.dart';
import '../models/debt.dart';
import '../services/debt_service.dart';
import 'add_debt_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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

class DebtListScreen extends StatefulWidget {
  final String token;
  const DebtListScreen({super.key, required this.token});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen>
    with SingleTickerProviderStateMixin {
  final DebtService _debtService = DebtService();
  List<Debt> _debts = [];
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
    _loadDebts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDebts() async {
    setState(() => _isLoading = true);
    try {
      final data = await _debtService.getDebts(widget.token);

      Map<String, Debt> groupedDebts = {};
      for (var d in data) {
        if (groupedDebts.containsKey(d.customerName)) {
          var existing = groupedDebts[d.customerName]!;
          groupedDebts[d.customerName] = Debt(
            id: existing.id,
            customerName: existing.customerName,
            phoneNumber: existing.phoneNumber ?? d.phoneNumber,
            totalDebt: existing.totalDebt + d.totalDebt,
            remainingAmount: existing.remainingAmount + d.remainingAmount,
            paidAmount: existing.paidAmount + d.paidAmount,
            isPaid: (existing.remainingAmount + d.remainingAmount) <= 0,
          );
        } else {
          groupedDebts[d.customerName] = d;
        }
      }

      if (mounted) {
        setState(() {
          _debts = groupedDebts.values.toList();
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sendWhatsAppReminder(Debt debt) async {
    final String phone = debt.phoneNumber ?? "";
    if (phone.isEmpty) {
      _showErrorSnackBar("رقم الهاتف غير متوفر");
      return;
    }

    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '212${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('212')) {
      cleanPhone = '212$cleanPhone';
    }

    final String message =
        "السلام عليكم ${debt.customerName}، 🧾\n\n"
        "تذكير بالدين المتبقي: *${debt.remainingAmount.toStringAsFixed(2)} DH*\n\n"
        "الرجاء التسديد في أقرب وقت ممكن.\n"
        "شكراً لتفهمكم! 🙏";

    final Uri url = Uri.parse(
      "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}",
    );

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showErrorSnackBar("تعذر فتح واتساب");
    }
  }

  void _showPayDialog(Debt debt) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: MoroccanColors.gold, width: 2),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      MoroccanColors.secondary,
                      MoroccanColors.darkGreen,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: MoroccanColors.gold, width: 2),
                ),
                child: const Icon(
                  Icons.attach_money_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                debt.customerName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: MoroccanColors.darkGreen,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: MoroccanColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MoroccanColors.primary, width: 1.5),
                ),
                child: Text(
                  "الباقي: ${debt.remainingAmount.toStringAsFixed(2)} DH",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: MoroccanColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MoroccanColors.gold, width: 2),
                ),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MoroccanColors.darkGreen,
                  ),
                  decoration: const InputDecoration(
                    labelText: "المبلغ المدفوع (DH)",
                    labelStyle: TextStyle(color: MoroccanColors.secondary),
                    prefixIcon: Icon(
                      Icons.payments_rounded,
                      color: MoroccanColors.gold,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: MoroccanColors.primary,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "إلغاء",
                        style: TextStyle(
                          color: MoroccanColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (controller.text.isEmpty) return;
                        double amount = double.parse(controller.text);
                        bool success = await _debtService.payDebt(
                          widget.token,
                          debt.id,
                          amount,
                        );
                        Navigator.pop(context);
                        if (success) {
                          _showSuccessSnackBar("تم التسجيل بنجاح!");
                          _loadDebts();
                        } else {
                          _showErrorSnackBar("خطأ في التسجيل");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MoroccanColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "تأكيد",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: MoroccanColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: MoroccanColors.gold, width: 1.5),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: MoroccanColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: MoroccanColors.gold, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoroccanColors.cream,
      appBar: _buildMoroccanAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildBody(),
      floatingActionButton: _buildMoroccanFAB(),
    );
  }

  PreferredSizeWidget _buildMoroccanAppBar() {
    return AppBar(
      backgroundColor: MoroccanColors.primary,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [MoroccanColors.primary, MoroccanColors.darkGreen],
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
              Icons.menu_book_rounded,
              color: MoroccanColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "كناش الديون",
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
          onPressed: _loadDebts,
          icon: const Icon(Icons.refresh_rounded, color: MoroccanColors.gold),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    if (_debts.isEmpty) {
      return _buildEmptyState();
    }

    // Calculate total debt
    double totalDebt = 0;
    for (var debt in _debts) {
      if (!debt.isPaid) {
        totalDebt += debt.remainingAmount;
      }
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildSummaryCard(totalDebt),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDebts,
              color: MoroccanColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                itemCount: _debts.length,
                itemBuilder: (context, index) {
                  return _buildDebtCard(_debts[index], index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double totalDebt) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MoroccanColors.primary, MoroccanColors.darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: MoroccanColors.gold, width: 2),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: MoroccanColors.gold,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "إجمالي الديون المتبقية",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${totalDebt.toStringAsFixed(2)} DH",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
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

  Widget _buildDebtCard(Debt debt, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: debt.isPaid ? MoroccanColors.secondary : MoroccanColors.gold,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (debt.isPaid ? MoroccanColors.secondary : MoroccanColors.orange)
                    .withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: debt.isPaid ? null : () => _showPayDialog(debt),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: debt.isPaid
                          ? [MoroccanColors.secondary, MoroccanColors.darkGreen]
                          : [MoroccanColors.primary, MoroccanColors.orange],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: MoroccanColors.gold, width: 2),
                  ),
                  child: Icon(
                    debt.isPaid
                        ? Icons.check_circle_rounded
                        : Icons.person_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: MoroccanColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 14,
                            color: MoroccanColors.blue.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            debt.phoneNumber ?? 'غير متوفر',
                            style: TextStyle(
                              fontSize: 13,
                              color: MoroccanColors.darkGreen.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: debt.isPaid
                              ? MoroccanColors.secondary.withOpacity(0.1)
                              : MoroccanColors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: debt.isPaid
                                ? MoroccanColors.secondary
                                : MoroccanColors.orange,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          debt.isPaid ? "مسدد" : "قيد السداد",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: debt.isPaid
                                ? MoroccanColors.secondary
                                : MoroccanColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!debt.isPaid &&
                        debt.phoneNumber != null &&
                        debt.phoneNumber!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.message,
                            color: Colors.green,
                            size: 24,
                          ),
                          onPressed: () => _sendWhatsAppReminder(debt),
                        ),
                      ),
                    Text(
                      "${debt.remainingAmount.toStringAsFixed(2)} DH",
                      style: TextStyle(
                        color: debt.isPaid
                            ? MoroccanColors.secondary
                            : MoroccanColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                colors: [MoroccanColors.primary, MoroccanColors.darkGreen],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: MoroccanColors.gold, width: 3),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 60,
              color: MoroccanColors.gold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "لا توجد ديون",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: MoroccanColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "الكناش فارغ حالياً",
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

  Widget _buildMoroccanFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MoroccanColors.primary, MoroccanColors.darkGreen],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MoroccanColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: MoroccanColors.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.person_add_rounded,
          color: MoroccanColors.gold,
          size: 32,
        ),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddDebtScreen(token: widget.token),
            ),
          );
          if (result == true) _loadDebts();
        },
      ),
    );
  }
}
