class Product {
  final String? id;
  final String barcode;
  final String name;
  final String brand;
  final String category;
  final String? imageUrl;
  final double priceInit; // Prix d'Achat
  final double priceSell; // PRIX DE VENTE (Zidnaha hna)
  final String? supplierDefault;
  final int currentQuantity;
  final int minAlertQuantity;
  final Packaging packaging;

  Product({
    this.id,
    required this.barcode,
    required this.name,
    required this.brand,
    required this.category,
    this.imageUrl,
    required this.priceInit,
    required this.priceSell, // Zidnaha hna
    this.supplierDefault,
    required this.currentQuantity,
    required this.minAlertQuantity,
    required this.packaging,
  });

  // --- 1. Mapping mn API (Backend) ---
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      barcode: json['barcode'] ?? "",
      name: json['name'] ?? "",
      brand: json['brand'] ?? "",
      category: json['category'] ?? "",
      imageUrl: json['imageUrl'],
      priceInit: (json['priceInit'] as num).toDouble(),
      priceSell: (json['priceSell'] as num? ?? 0.0).toDouble(), // Zidnaha hna
      supplierDefault: json['supplierDefault'],
      currentQuantity: (json['currentQuantity'] as num).toInt(),
      minAlertQuantity: (json['minAlertQuantity'] as num).toInt(),
      packaging: Packaging.fromJson(json['packaging'] ?? {}),
    );
  }

  // --- 2. Mapping l API (Backend) ---
  Map<String, dynamic> toJson() {
    return {
      "barcode": barcode,
      "name": name,
      "brand": brand,
      "category": category,
      "imageUrl": imageUrl,
      "priceInit": priceInit,
      "priceSell": priceSell, // Zidnaha hna
      "supplierDefault": supplierDefault,
      "currentQuantity": currentQuantity,
      "minAlertQuantity": minAlertQuantity,
      "packaging": packaging.toJson(),
    };
  }

  // --- 3. Mapping mn Local Database (SQLite) ---
  factory Product.fromLocalMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      barcode: map['barcode'] ?? "",
      name: map['name'] ?? "",
      brand: map['brand'] ?? "",
      category: map['category'] ?? "",
      imageUrl: map['imageUrl'],
      priceInit: (map['priceInit'] as num? ?? 0.0).toDouble(),
      priceSell: (map['priceSell'] as num? ?? 0.0).toDouble(), // Zidnaha hna
      supplierDefault: map['supplierDefault'],
      currentQuantity: (map['currentQuantity'] as num? ?? 0).toInt(),
      minAlertQuantity: (map['minAlertQuantity'] as num? ?? 0).toInt(),
      packaging: Packaging(
        bundleSize: 1,
        isBundleCommon: false,
        unitName: "pièce",
      ),
    );
  }

  // --- 4. Mapping l Local Database (SQLite) ---
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'category': category,
      'imageUrl': imageUrl,
      'priceInit': priceInit,
      'priceSell': priceSell, // Zidnaha hna
      'supplierDefault': supplierDefault,
      'currentQuantity': currentQuantity,
      'minAlertQuantity': minAlertQuantity,
    };
  }
}

class Packaging {
  final int bundleSize;
  final bool isBundleCommon;
  final String unitName;

  Packaging({
    required this.bundleSize,
    required this.isBundleCommon,
    required this.unitName,
  });

  factory Packaging.fromJson(Map<String, dynamic> json) {
    return Packaging(
      // Hna k-n-9raw mn l-Backend (CamelCase)
      bundleSize: json['bundleSize'] ?? 1,
      isBundleCommon: json['isBundleCommon'] ?? false,
      unitName: json['unitName'] ?? "pièce",
    );
  }

  // HADI HIYA L-MOHIMMA: Khass s-miyat ikounou kima kiy-tsennahom l-Backend
  Map<String, dynamic> toJson() => {
    "bundleSize": bundleSize,
    "isBundleCommon": isBundleCommon,
    "unitName": unitName, // <--- KHASS T-KOUN unitName (MACHI unit_name)
  };
}
