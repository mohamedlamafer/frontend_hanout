import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'add_product_screen.dart';
import 'product_details_screen.dart';

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

class ProductListScreen extends StatefulWidget {
  final String token;
  final bool showOnlyLowStock;
  const ProductListScreen({
    super.key,
    required this.token,
    this.showOnlyLowStock = false,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadProducts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    final data = await _productService.getProducts(
      widget.token,
      filter: widget.showOnlyLowStock ? "low-stock" : null,
    );

    setState(() {
      if (widget.showOnlyLowStock) {
        _allProducts = data
            .where((p) => p.currentQuantity <= p.minAlertQuantity)
            .toList();
      } else {
        _allProducts = data;
      }
      _filteredProducts = _allProducts;
      _isLoading = false;
    });

    _animationController.forward(from: 0.0);
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((product) {
          final name = product.name.toLowerCase();
          final barcode = product.barcode.toLowerCase();
          final input = query.toLowerCase();
          return name.contains(input) || barcode.contains(input);
        }).toList();
      }
    });
  }

  Widget _buildProductImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              MoroccanColors.cream,
              MoroccanColors.gold.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.shopping_bag_outlined,
          color: MoroccanColors.gold,
          size: 30,
        ),
      );
    }
    try {
      final String cleanBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      return Image.memory(
        base64Decode(cleanBase64),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: MoroccanColors.cream,
            child: const Icon(
              Icons.broken_image,
              color: MoroccanColors.terracotta,
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        color: MoroccanColors.cream,
        child: const Icon(Icons.broken_image, color: MoroccanColors.terracotta),
      );
    }
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

  // ==================== APP BAR MAROCAIN ====================
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
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "بحث عن منتج...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                border: InputBorder.none,
                prefixIcon: const Icon(
                  Icons.search,
                  color: MoroccanColors.gold,
                ),
              ),
              onChanged: _filterProducts,
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: MoroccanColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: MoroccanColors.gold, width: 1.5),
                  ),
                  child: Icon(
                    widget.showOnlyLowStock
                        ? Icons.warning_amber_rounded
                        : Icons.inventory_2_rounded,
                    color: MoroccanColors.gold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.showOnlyLowStock
                        ? "تنبيهات المخزون"
                        : "مخزون الحانوت",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
      actions: [
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.search_rounded,
            color: MoroccanColors.gold,
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _filteredProducts = _allProducts;
              }
            });
          },
        ),
        if (!_isSearching)
          IconButton(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh_rounded, color: MoroccanColors.gold),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ==================== BODY ====================
  Widget _buildBody() {
    if (_filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: MoroccanColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  (index / _filteredProducts.length) * 0.5,
                  1.0,
                  curve: Curves.easeOut,
                ),
              ),
            ),
            child: _buildMoroccanProductCard(_filteredProducts[index], index),
          );
        },
      ),
    );
  }

  // ==================== PRODUCT CARD MAROCAIN ====================
  Widget _buildMoroccanProductCard(Product product, int index) {
    bool isLowStock = product.currentQuantity <= product.minAlertQuantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowStock ? MoroccanColors.orange : MoroccanColors.gold,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLowStock ? MoroccanColors.orange : MoroccanColors.gold)
                .withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProductDetailsScreen(product: product, token: widget.token),
              ),
            );
            if (res == true) _loadProducts();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image avec bordure marocaine
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MoroccanColors.gold, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: MoroccanColors.gold.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildProductImage(product.imageUrl),
                  ),
                ),
                const SizedBox(width: 12),

                // Infos produit
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom du produit
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: MoroccanColors.darkGreen,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Prix avec style marocain
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
                          "${product.priceSell.toStringAsFixed(2)} DH",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Stock
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_rounded,
                            size: 16,
                            color: isLowStock
                                ? MoroccanColors.orange
                                : MoroccanColors.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${product.currentQuantity} ${product.packaging.unitName}",
                            style: TextStyle(
                              fontSize: 13,
                              color: isLowStock
                                  ? MoroccanColors.orange
                                  : MoroccanColors.darkGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Badge catégorie + alerte
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isLowStock)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MoroccanColors.orange.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: MoroccanColors.orange,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: MoroccanColors.orange,
                          size: 20,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: MoroccanColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: MoroccanColors.secondary,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                          fontSize: 10,
                          color: MoroccanColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
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

  // ==================== EMPTY STATE ====================
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
              Icons.inventory_2_outlined,
              size: 60,
              color: MoroccanColors.gold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isSearching ? "لا توجد منتجات" : "المخزون فارغ",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: MoroccanColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSearching
                ? "حاول البحث بكلمة أخرى"
                : "جميع منتجاتك متوفرة بكميات جيدة في المخزون",
            style: TextStyle(
              fontSize: 14,
              color: MoroccanColors.darkGreen.withOpacity(0.7),
            ),
          ),
        ],
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

  // ==================== FAB MAROCAIN ====================
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
          Icons.add_rounded,
          color: MoroccanColors.gold,
          size: 32,
        ),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddProductScreen(token: widget.token),
            ),
          );
          if (result == true) _loadProducts();
        },
      ),
    );
  }
}
