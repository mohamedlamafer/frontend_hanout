import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_helper.dart';
import 'product_service.dart';
import 'sale_service.dart';
import 'debt_service.dart';
import '../models/product.dart';
import '../models/sale_request.dart';
import '../models/debt.dart';

class SyncService {
  static bool _isSyncing = false; // Bach n-7bssou l-double click

  Future<void> syncData(String token) async {
    if (_isSyncing) return; // Ila khedam sync, ma-t-dir walou
    _isSyncing = true;

    try {
      final db = await DatabaseHelper.instance.database;

      // ==================== 1. SYNC SALES ====================
      // Hna s-sir: mli n-sifto sale b CREDIT, n-t-m-nnaw backend i-creyi debt bo7dou
      final List<Map<String, dynamic>> offlineSales = await db.query(
        'sales_offline',
      );
      for (var saleData in offlineSales) {
        List itemsJson = jsonDecode(saleData['items']);
        final saleRequest = SaleRequest(
          items: itemsJson
              .map(
                (i) => SaleItem(
                  productId: i['productId'],
                  quantity: i['quantity'],
                  sellPrice: i['sellPrice'],
                ),
              )
              .toList(),
          paymentMethod: saleData['paymentMethod'],
          customerName: saleData['customerName'],
        );

        bool success = await SaleService().createSale(token, saleRequest);
        if (success) {
          // Mli d-douz s-sale, n-ms7ouha f l-phone dghya
          await db.delete(
            'sales_offline',
            where: 'id = ?',
            whereArgs: [saleData['id']],
          );
        }
      }

      // ==================== 2. SYNC MANUAL DEBTS ====================
      // Hna ghadi n-sifto ghi d-dyoun li t-zadou b ydik (machi mn sale)
      // ==================== C. SYNC DEBTS (Version Safe) ====================
      // Hna ghadi n-jbdou ghi d-dyoun li isSynced dyalhom hwa 0
      // ==================== C. SYNC DEBTS ====================
      final List<Map<String, dynamic>> offlineDebts = await db.query(
        'debts_offline',
        where: 'isSynced = 0',
      );

      print("DEBUG SYNC: L9it ${offlineDebts.length} dettes l-sync");

      for (var debtData in offlineDebts) {
        final debtRequest = Debt(
          customerName: debtData['customerName'],
          phoneNumber: debtData['phoneNumber'],
          totalDebt: debtData['totalDebt'],
          remainingAmount: debtData['remainingAmount'],
          paidAmount: debtData['paidAmount'],
        );

        print(
          "DEBUG SYNC: Jari irsal dette dyal ${debtRequest.customerName}...",
        );

        bool success = await DebtService().createDebt(token, debtRequest);

        if (success) {
          print("DEBUG SYNC: Dette t-poushat l-Firebase!");
          await db.delete(
            'debts_offline',
            where: 'id = ?',
            whereArgs: [debtData['id']],
          );
        } else {
          print("DEBUG SYNC: Erreur backend mli k-n-sifto d-dette");
        }
      }
    } finally {
      _isSyncing = false; // Salina sync
    }
  }
}
