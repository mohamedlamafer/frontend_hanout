class StatsResponse {
  final int salesCount;
  final double totalRevenue; // BigDecimal f Kotlin kiy-welli double f Flutter
  final int lowStockProductsCount;

  StatsResponse({
    required this.salesCount,
    required this.totalRevenue,
    required this.lowStockProductsCount,
  });

  factory StatsResponse.fromJson(Map<String, dynamic> json) {
    return StatsResponse(
      salesCount: json['salesCount'],
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      lowStockProductsCount: json['lowStockProductsCount'],
    );
  }
}
