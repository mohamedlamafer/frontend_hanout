class SaleResponse {
  final String id;
  final int saleDate;
  final List<SaleItemResponse> items;
  final double totalAmount;
  final double totalProfit;
  final String paymentMethod;
  final String customerName;

  SaleResponse({
    required this.id,
    required this.saleDate,
    required this.items,
    required this.totalAmount,
    required this.totalProfit,
    required this.paymentMethod,
    required this.customerName,
  });

  factory SaleResponse.fromJson(Map<String, dynamic> json) {
    return SaleResponse(
      id: json['id'],
      saleDate: json['saleDate'],
      items: (json['items'] as List)
          .map((i) => SaleItemResponse.fromJson(i))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      totalProfit: (json['totalProfit'] as num).toDouble(),
      paymentMethod: json['paymentMethod'],
      customerName: json['customerName'] ?? "Client Passager",
    );
  }
}

class SaleItemResponse {
  final String productName;
  final int quantity;
  final double sellPrice;
  final double totalPrice;

  SaleItemResponse({
    required this.productName,
    required this.quantity,
    required this.sellPrice,
    required this.totalPrice,
  });

  factory SaleItemResponse.fromJson(Map<String, dynamic> json) {
    return SaleItemResponse(
      productName: json['productName'] ?? "Produit",
      quantity: json['quantity'],
      sellPrice: (json['sellPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }
}
