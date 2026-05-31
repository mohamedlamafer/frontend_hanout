class SaleRequest {
  final List<SaleItem> items;
  final String paymentMethod; // "CASH" wla "CREDIT"
  final String customerName;

  SaleRequest({
    required this.items,
    this.paymentMethod = "CASH",
    this.customerName = "Client",
  });

  Map<String, dynamic> toJson() => {
    "items": items.map((i) => i.toJson()).toList(),
    "paymentMethod": paymentMethod,
    "customerName": customerName,
  };
}

class SaleItem {
  final String productId;
  final int quantity;
  final double sellPrice;

  SaleItem({
    required this.productId,
    required this.quantity,
    required this.sellPrice,
  });

  Map<String, dynamic> toJson() => {
    "productId": productId,
    "quantity": quantity,
    "sellPrice": sellPrice,
  };
}
