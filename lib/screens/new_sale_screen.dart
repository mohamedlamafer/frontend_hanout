import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hanout_frontend/services/database_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../models/sale_request.dart';
import '../models/debt.dart';
import '../services/product_service.dart';
import '../services/sale_service.dart';
import '../services/debt_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
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

class NewSaleScreen extends StatefulWidget {
  final String token;
  const NewSaleScreen({super.key, required this.token});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen>
    with SingleTickerProviderStateMixin {
  final _saleService = SaleService();
  final _productService = ProductService();
  final _debtService = DebtService();

  List<Product> _availableProducts = [];
  List<Debt> _existingDebts = [];
  List<SaleItem> _cartItems = [];
  List<String> _cartProductNames = [];

  Product? _selectedProduct;
  Debt? _selectedDebtCustomer;

  String _paymentMethod = "CASH";
  final _quantityController = TextEditingController(text: "1");
  final _priceController = TextEditingController();
  final _newCustomerNameController = TextEditingController();
  final _newCustomerPhoneController = TextEditingController();

  bool _isLoading = false;

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
    _loadInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _newCustomerNameController.dispose();
    _newCustomerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productService.getProducts(widget.token);
      final debts = await _debtService.getDebts(widget.token);

      final Map<String, Debt> uniqueDebtsMap = {};
      for (var d in debts) {
        uniqueDebtsMap[d.customerName.trim().toLowerCase()] = d;
      }

      setState(() {
        _availableProducts = products;
        _existingDebts = uniqueDebtsMap.values.toList();
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scanProductBarcode() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          border: Border(top: BorderSide(color: MoroccanColors.gold, width: 3)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 60,
              height: 5,
              decoration: BoxDecoration(
                color: MoroccanColors.gold.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          MoroccanColors.primary,
                          MoroccanColors.darkGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: MoroccanColors.gold, width: 2),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "مسح المنتج",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: MoroccanColors.darkGreen,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: MoroccanColors.gold, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: MobileScanner(
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final String code = barcodes.first.rawValue ?? "";
                          try {
                            final Product foundProduct = _availableProducts
                                .firstWhere((p) => p.barcode == code);
                            setState(() {
                              _selectedProduct = foundProduct;
                              _priceController.text = foundProduct.priceSell
                                  .toString();
                              _quantityController.text = "1";
                            });
                            Navigator.pop(context);
                            _showSuccessSnackBar(
                              "المنتج: ${foundProduct.name}",
                            );
                          } catch (e) {
                            Navigator.pop(context);
                            _showErrorSnackBar("المنتج غير موجود!");
                          }
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _addToCart() {
    if (_selectedProduct == null || _priceController.text.isEmpty) {
      _showErrorSnackBar("اختر منتج وسعره");
      return;
    }

    final int qty = int.parse(_quantityController.text);
    final double price = double.parse(_priceController.text);

    setState(() {
      _cartItems.add(
        SaleItem(
          productId: _selectedProduct!.id!,
          quantity: qty,
          sellPrice: price,
        ),
      );
      _cartProductNames.add(_selectedProduct!.name);
      _selectedProduct = null;
      _priceController.clear();
      _quantityController.text = "1";
    });

    _showSuccessSnackBar("تمت الإضافة للسلة");
  }

  void _submitSale() async {
    if (_cartItems.isEmpty) {
      _showErrorSnackBar("السلة فارغة!");
      return;
    }

    setState(() => _isLoading = true);

    var connectivityResult = await (Connectivity().checkConnectivity());
    bool isOnline = connectivityResult != ConnectivityResult.none;

    double totalAmount = 0;
    for (var item in _cartItems) {
      totalAmount += (item.quantity * item.sellPrice);
    }

    final saleRequest = SaleRequest(
      items: _cartItems,
      paymentMethod: _paymentMethod,
      customerName: _paymentMethod == "CASH"
          ? "Client Passager"
          : (_selectedDebtCustomer?.customerName ??
                _newCustomerNameController.text),
    );

    for (var item in _cartItems) {
      await DatabaseHelper.instance.decrementLocalStock(
        item.productId,
        item.quantity,
      );
    }

    bool saleSuccess = await _saleService.createSale(widget.token, saleRequest);

    if (_paymentMethod == "CREDIT") {
      final debtRequest = Debt(
        customerName:
            _selectedDebtCustomer?.customerName ??
            _newCustomerNameController.text,
        phoneNumber:
            _selectedDebtCustomer?.phoneNumber ??
            _newCustomerPhoneController.text,
        totalDebt: totalAmount,
        remainingAmount: totalAmount,
        paidAmount: 0.0,
      );

      if (isOnline) {
        await _debtService.createDebt(widget.token, debtRequest);
      } else {
        await DatabaseHelper.instance.saveSingleDebtOffline(
          debtRequest,
          isSynced: 0,
        );
      }
    }

    setState(() => _isLoading = false);

    if (saleSuccess) {
      if (_paymentMethod == "CREDIT") {
        _showShareDialog(totalAmount);
      } else {
        _showSuccessSnackBar("تمت العملية بنجاح!");
        Navigator.pop(context, true);
      }
    }
  }

  void _showShareDialog(double totalAmount) {
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
                "بيع ناجح!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: MoroccanColors.darkGreen,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "هل تريد إرسال الفاتورة عبر واتساب؟",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(this.context, true);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(
                          color: MoroccanColors.secondary,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "لا، شكراً",
                        style: TextStyle(
                          color: MoroccanColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        final String phone =
                            _selectedDebtCustomer?.phoneNumber ??
                            _newCustomerPhoneController.text;
                        final String name =
                            _selectedDebtCustomer?.customerName ??
                            _newCustomerNameController.text;

                        if (phone.isNotEmpty) {
                          _shareToWhatsAppDirectly(
                            customerName: name,
                            phone: phone,
                            totalAmount: totalAmount,
                          );
                        } else {
                          _shareReceiptText(
                            customerName: name,
                            totalAmount: totalAmount,
                          );
                        }
                        Navigator.pop(this.context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.message, color: Colors.white),
                      label: const Text(
                        "إرسال",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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

  void _shareToWhatsAppDirectly({
    required String customerName,
    required String phone,
    required double totalAmount,
  }) async {
    String date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    String ticket = "🧾 *** فاتورة الحانوت *** 🧾\n";
    ticket += "━━━━━━━━━━━━━━━━━━━━━━\n";
    ticket += "العميل: $customerName\n";
    ticket += "التاريخ: $date\n";
    ticket += "━━━━━━━━━━━━━━━━━━━━━━\n";

    for (int i = 0; i < _cartItems.length; i++) {
      ticket += "• ${_cartProductNames[i]}\n";
      ticket +=
          "  ${_cartItems[i].quantity} x ${_cartItems[i].sellPrice} DH = ${_cartItems[i].quantity * _cartItems[i].sellPrice} DH\n";
    }

    ticket += "━━━━━━━━━━━━━━━━━━━━━━\n";
    ticket += "المجموع: $totalAmount DH\n";
    ticket += "الحالة: دين (كناش)\n";
    ticket += "━━━━━━━━━━━━━━━━━━━━━━\n";
    ticket += "🙏 شكراً لزيارتكم!";

    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '212${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('212')) {
      cleanPhone = '212$cleanPhone';
    }

    final Uri url = Uri.parse(
      "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(ticket)}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Share.share(ticket);
    }
  }

  void _shareReceiptText({
    required String customerName,
    required double totalAmount,
  }) {
    final String date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    String ticket = "🧾 *** فاتورة بيع (دين) *** 🧾\n";
    ticket += "━━━━━━━━━━━━━━━━━━━━━━━━\n";
    ticket += "المحل: الحانوت برو\n";
    ticket += "العميل: $customerName\n";
    ticket += "التاريخ: $date\n";
    ticket += "━━━━━━━━━━━━━━━━━━━━━━━━\n";

    for (int i = 0; i < _cartItems.length; i++) {
      ticket += "• ${_cartProductNames[i]}\n";
      ticket +=
          "  ${_cartItems[i].quantity} x ${_cartItems[i].sellPrice} DH = ${_cartItems[i].quantity * _cartItems[i].sellPrice} DH\n";
    }

    ticket += "━━━━━━━━━━━━━━━━━━━━━━━━\n";
    ticket += "المجموع: $totalAmount DH\n";
    ticket += "الحالة: ديْن\n";
    ticket += "━━━━━━━━━━━━━━━━━━━━━━━━\n";
    ticket += "🙏 شكراً لثقتكم!";

    Share.share(ticket);
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
              Icons.point_of_sale_rounded,
              color: MoroccanColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "بيع جديد",
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("إضافة منتجات"),
            const SizedBox(height: 12),
            _buildProductSelection(),
            const SizedBox(height: 16),
            _buildQuantityPriceRow(),
            const SizedBox(height: 24),
            if (_cartItems.isNotEmpty) ...[
              _buildSectionTitle("السلة (${_cartItems.length})"),
              const SizedBox(height: 12),
              _buildCart(),
              const SizedBox(height: 24),
            ],
            _buildSectionTitle("طريقة الدفع"),
            const SizedBox(height: 12),
            _buildPaymentMethods(),
            if (_paymentMethod == "CREDIT") ...[
              const SizedBox(height: 16),
              _buildCreditSection(),
            ],
            const SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
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

  Widget _buildProductSelection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MoroccanColors.gold, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<Product>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "اختر المنتج",
                labelStyle: TextStyle(color: MoroccanColors.primary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              value: _selectedProduct,
              items: _availableProducts
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text("${p.name} (${p.currentQuantity})"),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() {
                _selectedProduct = val;
                _priceController.text = val!.priceSell.toString();
              }),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [MoroccanColors.primary, MoroccanColors.darkGreen],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MoroccanColors.gold, width: 2),
            ),
            child: IconButton(
              onPressed: _scanProductBarcode,
              icon: const Icon(
                Icons.qr_code_scanner_rounded,
                color: MoroccanColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityPriceRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: _quantityController,
            label: "الكمية",
            icon: Icons.numbers_rounded,
            color: MoroccanColors.blue,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTextField(
            controller: _priceController,
            label: "السعر (DH)",
            icon: Icons.monetization_on_rounded,
            color: MoroccanColors.secondary,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [MoroccanColors.secondary, MoroccanColors.darkGreen],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MoroccanColors.gold, width: 2),
          ),
          child: IconButton(
            onPressed: _addToCart,
            icon: const Icon(
              Icons.add_shopping_cart_rounded,
              color: MoroccanColors.gold,
            ),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MoroccanColors.gold, width: 2),
      ),
      child: TextField(
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
          prefixIcon: Icon(icon, color: color),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCart() {
    double total = 0;
    for (var item in _cartItems) {
      total += item.quantity * item.sellPrice;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MoroccanColors.gold, width: 2),
      ),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cartItems.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MoroccanColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: MoroccanColors.secondary,
                    ),
                  ),
                ),
                title: Text(
                  _cartProductNames[index],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${_cartItems[index].quantity} x ${_cartItems[index].sellPrice} DH",
                  style: const TextStyle(color: MoroccanColors.darkGreen),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_rounded,
                    color: MoroccanColors.primary,
                  ),
                  onPressed: () => setState(() {
                    _cartItems.removeAt(index);
                    _cartProductNames.removeAt(index);
                  }),
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [MoroccanColors.gold, MoroccanColors.orange],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "المجموع:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "${total.toStringAsFixed(2)} DH",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MoroccanColors.gold, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPaymentOption("نقداً", "CASH", Icons.money_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildPaymentOption(
              "دين",
              "CREDIT",
              Icons.credit_card_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String label, String value, IconData icon) {
    bool isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [MoroccanColors.secondary, MoroccanColors.darkGreen],
                )
              : null,
          color: isSelected ? null : MoroccanColors.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? MoroccanColors.gold
                : MoroccanColors.gold.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : MoroccanColors.darkGreen,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : MoroccanColors.darkGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditSection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MoroccanColors.gold, width: 2),
          ),
          child: DropdownButtonFormField<Debt>(
            decoration: const InputDecoration(
              labelText: "عميل موجود",
              labelStyle: TextStyle(color: MoroccanColors.primary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            value: _selectedDebtCustomer,
            items: _existingDebts
                .map(
                  (d) =>
                      DropdownMenuItem(value: d, child: Text(d.customerName)),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedDebtCustomer = val),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text("أو", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        _buildTextField(
          controller: _newCustomerNameController,
          label: "اسم جديد",
          icon: Icons.person_rounded,
          color: MoroccanColors.primary,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _newCustomerPhoneController,
          label: "الهاتف",
          icon: Icons.phone_rounded,
          color: MoroccanColors.blue,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    double total = 0;
    for (var item in _cartItems) {
      total += item.quantity * item.sellPrice;
    }

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
        onPressed: _submitSale,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: MoroccanColors.gold,
              size: 26,
            ),
            const SizedBox(width: 12),
            Text(
              "تأكيد البيع (${_cartItems.length}) | ${total.toStringAsFixed(2)} DH",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
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
            "جاري المعالجة...",
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
