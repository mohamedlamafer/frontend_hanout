import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/product.dart';
import '../services/product_service.dart';

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

class AddProductScreen extends StatefulWidget {
  final String token;
  const AddProductScreen({super.key, required this.token});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();

  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceAchatController = TextEditingController();
  final _priceVenteController = TextEditingController();
  final _quantityController = TextEditingController();

  File? _imageFile;
  String? _base64Image;
  bool _isLoading = false;
  bool _isFetchingInfo = false;

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
    _nameController.dispose();
    _barcodeController.dispose();
    _priceAchatController.dispose();
    _priceVenteController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // ==================== SCAN BARCODE ====================
  void _scanBarcode() async {
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
                    "مسح الباركود",
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
                      onDetect: (capture) async {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final String code = barcodes.first.rawValue ?? "";
                          setState(() => _barcodeController.text = code);
                          Navigator.pop(context);

                          _showLoadingSnackBar(
                            "جاري البحث عن معلومات المنتج...",
                          );

                          setState(() => _isFetchingInfo = true);
                          final Product? globalInfo = await _productService
                              .searchGlobalBarcode(widget.token, code);
                          setState(() => _isFetchingInfo = false);

                          if (globalInfo != null) {
                            setState(() {
                              _nameController.text = globalInfo.name;
                              _priceVenteController.text = globalInfo.priceSell
                                  .toString();
                              if (globalInfo.imageUrl != null &&
                                  globalInfo.imageUrl!.isNotEmpty) {
                                _base64Image = globalInfo.imageUrl;
                                _imageFile = null;
                              }
                            });
                            _showSuccessSnackBar(
                              "تم العثور على المعلومات والصورة!",
                            );
                          } else {
                            _showInfoSnackBar("لم يتم العثور على معلومات");
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

  // ==================== PICK IMAGE ====================
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          border: Border(top: BorderSide(color: MoroccanColors.gold, width: 3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 20),
            const Text(
              "اختر مصدر الصورة",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: MoroccanColors.darkGreen,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: "الكاميرا",
                  color: MoroccanColors.primary,
                  onTap: () async {
                    Navigator.pop(context);
                    await _selectImage(ImageSource.camera);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: "المعرض",
                  color: MoroccanColors.secondary,
                  onTap: () async {
                    Navigator.pop(context);
                    await _selectImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MoroccanColors.gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      final List<int> bytes = await file.readAsBytes();

      setState(() {
        _imageFile = file;
        _base64Image = base64Encode(bytes);
      });
    }
  }

  // ==================== SUBMIT ====================
  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final newProduct = Product(
        barcode: _barcodeController.text.trim(),
        name: _nameController.text.trim(),
        brand: "Générique",
        category: "Alimentation",
        imageUrl: _base64Image,
        supplierDefault: "Grossiste",
        priceInit: double.tryParse(_priceAchatController.text) ?? 0.0,
        priceSell: double.tryParse(_priceVenteController.text) ?? 0.0,
        currentQuantity: int.tryParse(_quantityController.text) ?? 0,
        minAlertQuantity: 5,
        packaging: Packaging(
          bundleSize: 1,
          isBundleCommon: false,
          unitName: "pièce",
        ),
      );

      bool success = await ProductService().addProduct(
        widget.token,
        newProduct,
      );
      setState(() => _isLoading = false);

      if (success && mounted) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar("حدث خطأ تقني");
      }
    }
  }

  // ==================== DIALOGS & SNACKBARS ====================
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
                "تمت الإضافة بنجاح!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: MoroccanColors.darkGreen,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "تم إضافة المنتج إلى المخزون",
                style: TextStyle(fontSize: 14, color: Colors.grey),
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

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: MoroccanColors.gold,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: MoroccanColors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: MoroccanColors.gold, width: 1.5),
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

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: MoroccanColors.orange,
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

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoroccanColors.cream,
      appBar: _buildMoroccanAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildImagePicker(),
                  const SizedBox(height: 24),
                  _buildForm(),
                  const SizedBox(height: 30),
                  _buildSubmitButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ==================== APP BAR ====================
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
              Icons.add_box_rounded,
              color: MoroccanColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "منتج جديد",
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

  // ==================== IMAGE PICKER ====================
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MoroccanColors.gold, width: 3),
          boxShadow: [
            BoxShadow(
              color: MoroccanColors.gold.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_imageFile == null &&
                  (_base64Image == null || _base64Image!.isEmpty))
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        MoroccanColors.cream,
                        MoroccanColors.gold.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: MoroccanColors.gold.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: MoroccanColors.gold,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 50,
                          color: MoroccanColors.gold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "انقر لإضافة صورة",
                        style: TextStyle(
                          fontSize: 14,
                          color: MoroccanColors.darkGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_imageFile != null)
                Image.file(_imageFile!, fit: BoxFit.cover)
              else
                Image.memory(
                  base64Decode(
                    _base64Image!.contains(',')
                        ? _base64Image!.split(',').last
                        : _base64Image!,
                  ),
                  fit: BoxFit.cover,
                ),
              if (_imageFile != null ||
                  (_base64Image != null && _base64Image!.isNotEmpty))
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          MoroccanColors.primary,
                          MoroccanColors.darkGreen,
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: MoroccanColors.gold, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== FORM ====================
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _barcodeController,
                  label: "الباركود",
                  icon: Icons.qr_code_rounded,
                  color: MoroccanColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [MoroccanColors.primary, MoroccanColors.darkGreen],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MoroccanColors.gold, width: 2),
                ),
                child: IconButton(
                  onPressed: _isFetchingInfo ? null : _scanBarcode,
                  icon: _isFetchingInfo
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: MoroccanColors.gold,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: MoroccanColors.gold,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            label: "اسم المنتج",
            icon: Icons.shopping_bag_rounded,
            color: MoroccanColors.primary,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _priceAchatController,
            label: "سعر الشراء (DH)",
            icon: Icons.download_rounded,
            color: MoroccanColors.orange,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _priceVenteController,
            label: "سعر البيع (DH)",
            icon: Icons.upload_rounded,
            color: MoroccanColors.secondary,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _quantityController,
            label: "المخزون الأولي",
            icon: Icons.inventory_2_rounded,
            color: MoroccanColors.blue,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
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
        validator: (v) => v!.isEmpty ? "هذا الحقل مطلوب" : null,
      ),
    );
  }

  // ==================== SUBMIT BUTTON ====================
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
              "حفظ المنتج",
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

  // ==================== LOADING STATE ====================
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
