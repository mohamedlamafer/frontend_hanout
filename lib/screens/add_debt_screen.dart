import 'package:flutter/material.dart';
import '../models/debt.dart';
import '../services/debt_service.dart';

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

class AddDebtScreen extends StatefulWidget {
  final String token;
  const AddDebtScreen({super.key, required this.token});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final newDebt = Debt(
        customerName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        totalDebt: double.parse(_amountController.text),
        paidAmount: 0.0,
        remainingAmount: double.parse(_amountController.text),
      );

      bool success = await DebtService().createDebt(widget.token, newDebt);

      setState(() => _isLoading = false);

      if (success && mounted) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar("حدث خطأ، حاول مرة أخرى");
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "تم التسجيل بنجاح!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: MoroccanColors.darkGreen,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "تم إضافة الدين للكناش",
                style: TextStyle(
                  fontSize: 14,
                  color: MoroccanColors.darkGreen.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MoroccanColors.secondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "حسناً",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
              Icons.person_add_rounded,
              color: MoroccanColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "دين جديد",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 24),
                _buildSectionTitle("معلومات العميل"),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  label: "اسم العميل",
                  icon: Icons.person_rounded,
                  color: MoroccanColors.primary,
                  validator: (v) => v!.isEmpty ? "هذا الحقل مطلوب" : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: "رقم الهاتف",
                  icon: Icons.phone_rounded,
                  color: MoroccanColors.blue,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle("المبلغ"),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _amountController,
                  label: "مبلغ الدين (DH)",
                  icon: Icons.attach_money_rounded,
                  color: MoroccanColors.orange,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v!.isEmpty) return "هذا الحقل مطلوب";
                    if (double.tryParse(v) == null) return "أدخل رقماً صحيحاً";
                    if (double.parse(v) <= 0)
                      return "المبلغ يجب أن يكون أكبر من 0";
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MoroccanColors.blue.withOpacity(0.1),
            MoroccanColors.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MoroccanColors.gold, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [MoroccanColors.blue, MoroccanColors.secondary],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MoroccanColors.gold, width: 1.5),
            ),
            child: const Icon(
              Icons.info_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "املأ المعلومات لإضافة دين جديد إلى الكناش",
              style: TextStyle(
                fontSize: 13,
                color: MoroccanColors.darkGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [MoroccanColors.gold, MoroccanColors.orange],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: MoroccanColors.darkGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MoroccanColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: MoroccanColors.darkGreen,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 56,
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
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.save_rounded, color: MoroccanColors.gold, size: 26),
            SizedBox(width: 12),
            Text(
              "تسجيل الدين",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
            "جاري الحفظ...",
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
