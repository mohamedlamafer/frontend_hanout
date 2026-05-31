import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/product.dart';
import '../services/product_service.dart';
import 'edit_product_screen.dart';

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

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  final String token;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.token,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
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
    super.dispose();
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _buildMoroccanDialog(context),
    );
  }

  Widget _buildMoroccanDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: MoroccanColors.gold, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MoroccanColors.gold, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header avec gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [MoroccanColors.primary, MoroccanColors.darkGreen],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: MoroccanColors.gold, width: 2),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: MoroccanColors.gold,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "حذف المنتج",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    "هل تريد حقاً حذف",
                    style: TextStyle(
                      fontSize: 15,
                      color: MoroccanColors.darkGreen.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "'${widget.product.name}'",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MoroccanColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "؟",
                    style: TextStyle(
                      fontSize: 15,
                      color: MoroccanColors.darkGreen.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MoroccanColors.cream,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                        "إلغاء",
                        style: TextStyle(
                          color: MoroccanColors.secondary,
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
                        bool success = await ProductService().deleteProduct(
                          widget.token,
                          widget.product.id!,
                        );
                        if (success && context.mounted) {
                          Navigator.pop(context);
                          Navigator.pop(context, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: MoroccanColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "حذف",
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoroccanColors.cream,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildMoroccanAppBar(context),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [_buildImageSection(), _buildDetailsSection()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== APP BAR MAROCAIN ====================
  Widget _buildMoroccanAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: MoroccanColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: MoroccanColors.gold),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          "تفاصيل المنتج",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
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
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: MoroccanColors.gold),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProductScreen(
                product: widget.product,
                token: widget.token,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_forever_rounded,
            color: MoroccanColors.orange,
          ),
          onPressed: () => _confirmDelete(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ==================== IMAGE SECTION ====================
  Widget _buildImageSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 280,
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
          children: [
            // Background pattern
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [MoroccanColors.cream, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Image
            Center(
              child:
                  widget.product.imageUrl != null &&
                      widget.product.imageUrl!.isNotEmpty
                  ? Image.memory(
                      base64Decode(
                        widget.product.imageUrl!.contains(',')
                            ? widget.product.imageUrl!.split(',').last
                            : widget.product.imageUrl!,
                      ),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderIcon();
                      },
                    )
                  : _buildPlaceholderIcon(),
            ),
            // Category badge
            Positioned(
              top: 12,
              right: 12,
              child: Container(
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MoroccanColors.gold, width: 1.5),
                ),
                child: Text(
                  widget.product.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: MoroccanColors.gold.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: MoroccanColors.gold, width: 2),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        size: 80,
        color: MoroccanColors.gold,
      ),
    );
  }

  // ==================== DETAILS SECTION ====================
  Widget _buildDetailsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name & Barcode
          _buildNameCard(),
          const SizedBox(height: 16),

          // Section Title
          _buildSectionTitle("السعر والمخزون"),
          const SizedBox(height: 12),

          // Price Cards
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  "سعر الشراء",
                  "${widget.product.priceInit} DH",
                  Icons.download_rounded,
                  MoroccanColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  "سعر البيع",
                  "${widget.product.priceSell} DH",
                  Icons.upload_rounded,
                  MoroccanColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stock Card
          _buildInfoCard(
            "المخزون المتاح",
            "${widget.product.currentQuantity} ${widget.product.packaging.unitName}",
            Icons.inventory_2_rounded,
            widget.product.currentQuantity <= widget.product.minAlertQuantity
                ? MoroccanColors.orange
                : MoroccanColors.blue,
          ),

          const SizedBox(height: 24),

          // Section Title
          _buildSectionTitle("معلومات إضافية"),
          const SizedBox(height: 12),

          // Additional Info
          _buildDetailRow(
            "العلامة التجارية",
            widget.product.brand,
            Icons.branding_watermark_rounded,
          ),
          _buildDetailRow(
            "المورد",
            widget.product.supplierDefault ?? "غير محدد",
            Icons.business_rounded,
          ),
          _buildDetailRow(
            "الحد الأدنى للتنبيه",
            "${widget.product.minAlertQuantity} ${widget.product.packaging.unitName}",
            Icons.notifications_active_rounded,
          ),
        ],
      ),
    );
  }

  // ==================== NAME CARD ====================
  Widget _buildNameCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MoroccanColors.primary, MoroccanColors.darkGreen],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MoroccanColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: MoroccanColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MoroccanColors.gold, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.qr_code_rounded,
                  color: MoroccanColors.gold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.product.barcode,
                  style: const TextStyle(
                    fontSize: 16,
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

  // ==================== SECTION TITLE ====================
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

  // ==================== INFO CARD ====================
  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MoroccanColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: MoroccanColors.darkGreen.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DETAIL ROW ====================
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MoroccanColors.gold.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MoroccanColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: MoroccanColors.secondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: MoroccanColors.darkGreen.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: MoroccanColors.darkGreen,
                  ),
                ),
              ],
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
