class Debt {
  final String id;
  final String customerName;
  final String? phoneNumber;
  final double totalDebt;
  final double paidAmount;
  final double remainingAmount;
  final bool isPaid;
  final String saleId;
  final int createdAt;

  Debt({
    this.id = "",
    required this.customerName,
    this.phoneNumber,
    required this.totalDebt,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    this.isPaid = false,
    this.saleId = "",
    int? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "customerName": customerName,
      "phoneNumber": phoneNumber,
      "totalDebt": totalDebt,
      "paidAmount": paidAmount,
      "remainingAmount": remainingAmount,
      "isPaid": isPaid,
      "saleId": saleId,
      "createdAt": createdAt,
    };
  }

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] ?? "",
      customerName: json['customerName'] ?? "",
      phoneNumber: json['phoneNumber'],
      totalDebt: (json['totalDebt'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      remainingAmount: (json['remainingAmount'] as num).toDouble(),
      isPaid: json['isPaid'] ?? false,
      saleId: json['saleId'] ?? "",
      createdAt: json['createdAt'],
    );
  }
  // --- Had l-fonction k-t-9ra mn l-phone (SQLite) ---
  factory Debt.fromLocalMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'].toString(),
      customerName: map['customerName'] ?? "",
      phoneNumber: map['phoneNumber'],
      totalDebt: (map['totalDebt'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num).toDouble(),
      remainingAmount: (map['remainingAmount'] as num).toDouble(),
      isPaid: map['isSynced'] == 1, // Temporaire
    );
  }
}
