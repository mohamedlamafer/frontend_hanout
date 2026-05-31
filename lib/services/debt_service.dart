import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/debt.dart';
import '../constants.dart';
import 'database_helper.dart';

class DebtService {
  final Dio _dio = Dio();
  final String baseUrl = AppConstants.debtsUrl;

  Future<List<Debt>> getDebts(String token) async {
    try {
      // 1. Check Connectivity
      var connectivityResult = await (Connectivity().checkConnectivity());
      bool isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline) {
        final response = await _dio.get(
          baseUrl,
          options: Options(
            headers: {"Authorization": "Bearer $token"},
            sendTimeout: const Duration(seconds: 2), // Timeout dghya
          ),
        );

        if (response.statusCode == 200) {
          List data = response.data;
          List<Debt> debts = data.map((d) => Debt.fromJson(d)).toList();

          // --- DARBA DYAL CACHE: Khbi f l-phone ---
          await DatabaseHelper.instance.saveDebts(debts);
          return debts;
        }
      }
    } catch (e) {
      print("Offline Mode (Debts): $e");
    }

    // --- 2. ILA OFFLINE WLA ERROR: Jbed mn SQLite ---
    return await DatabaseHelper.instance.getLocalDebts();
  }

  Future<bool> createDebt(String token, Debt debt) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      try {
        final response = await _dio.post(
          baseUrl,
          data: debt.toJson(),
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );
        return response.statusCode == 201 || response.statusCode == 200;
      } catch (e) {
        print("Error creating debt online: $e");
      }
    }

    // --- OFFLINE: Khbiha f l-phone ---
    print("Offline: Enregistrement de la dette localement...");
    await DatabaseHelper.instance.insertOfflineDebt({
      'customerName': debt.customerName,
      'phoneNumber': debt.phoneNumber,
      'totalDebt': debt.totalDebt,
      'paidAmount': debt.paidAmount,
      'remainingAmount': debt.remainingAmount,
      'isSynced': 0,
    });
    return true;
  }

  // Zid l-fonction payDebt hna kima siybnaha 9bel...
  Future<bool> payDebt(String token, String debtId, double amount) async {
    try {
      final response = await _dio.put(
        "$baseUrl/$debtId/pay",
        queryParameters: {"amount": amount},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
