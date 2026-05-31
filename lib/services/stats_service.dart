import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/stats_response.dart';
import '../constants.dart';

class StatsService {
  final Dio _dio = Dio();
  final String baseUrl = AppConstants.statsUrl;

  Future<StatsResponse?> getStats(String token, String period) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Check Internet
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      try {
        final response = await _dio.get(
          baseUrl,
          queryParameters: {"period": period},
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );

        if (response.statusCode == 200) {
          // --- STOKI L-STATS F L-PHONE (CACHE) ---
          await prefs.setString(
            'cached_stats_$period',
            jsonEncode(response.data),
          );
          return StatsResponse.fromJson(response.data);
        }
      } catch (e) {
        print("Error fetching online stats: $e");
      }
    }

    // 2. OFFLINE WLA ERROR: Jbed mn l-cache dyal SharedPreferences
    print("Offline: Loading stats from cache...");
    String? cachedData = prefs.getString('cached_stats_$period');
    if (cachedData != null) {
      return StatsResponse.fromJson(jsonDecode(cachedData));
    }

    return null; // Ila ma-kanach internet o ma-3ndnach cache
  }
}
