import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hanout_frontend/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/sale_request.dart';
import '../models/sale_response.dart'; // Darouri t-importi l-model jdid
import '../constants.dart';

class SaleService {
  final Dio _dio = Dio();
  final String baseUrl = AppConstants.salesUrl;

  // ==================== 1. ENREGISTRER UNE VENTE ====================
  Future<bool> createSale(String token, SaleRequest sale) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      try {
        final response = await _dio.post(
          baseUrl,
          data: sale.toJson(),
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );
        if (response.statusCode == 201 || response.statusCode == 200)
          return true;
      } catch (e) {
        print("Error API Sale: $e");
      }
    }

    // --- ILA OFFLINE: Khbiha f l-phone ---
    print("Offline: Enregistrement de la vente dans la base locale...");
    await DatabaseHelper.instance.insertOfflineSale({
      'items': jsonEncode(sale.items.map((i) => i.toJson()).toList()),
      'paymentMethod': sale.paymentMethod,
      'customerName': sale.customerName,
      'isSynced': 0,
    });
    return true;
  }

  // ==================== 2. GET SALES HISTORY (Smart Mode) ====================
  Future<List<SaleResponse>> getSalesHistory(String token) async {
    final prefs = await SharedPreferences.getInstance();

    // Check Internet
    // FIX: Khdem b var bach Flutter i-عرف l-naw3 bo7dou
    var connectivityResult = await (Connectivity().checkConnectivity());

    // Check wach kyna internet (ila kanet m-kh-talfa 3la none)
    bool isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      try {
        final response = await _dio.get(
          baseUrl,
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );

        if (response.statusCode == 200) {
          List data = response.data;

          // --- STOKI L-HISTORIQUE F L-CACHE DYAL PHONE ---
          await prefs.setString('cached_sales_history', jsonEncode(data));

          return data.map((s) => SaleResponse.fromJson(s)).toList();
        }
      } catch (e) {
        print("Error fetching online history: $e");
      }
    }

    // --- ILA MAKANTCH INTERNET: Jbed mn l-cache ---
    print("Offline: Chargement de l'historique depuis le cache...");
    String? cachedData = prefs.getString('cached_sales_history');
    if (cachedData != null) {
      List data = jsonDecode(cachedData);
      return data.map((s) => SaleResponse.fromJson(s)).toList();
    }

    return [];
  }
}
