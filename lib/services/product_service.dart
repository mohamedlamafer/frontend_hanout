import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/product.dart';
import '../constants.dart';
import 'database_helper.dart';

class ProductService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 2), // 2 s-taniya max dyal l-cnx
      receiveTimeout: const Duration(seconds: 2),
    ),
  );
  final String baseUrl = AppConstants.productsUrl;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<bool> updateProduct(String token, String id, Product product) async {
    try {
      final response = await _dio.put(
        "$baseUrl/$id",
        data: product.toJson(),
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Erreur update product: $e");
      return false;
    }
  }

  // --- Fonction bach t-m-s7 produit ---
  Future<bool> deleteProduct(String token, String id) async {
    try {
      final response = await _dio.delete(
        "$baseUrl/$id",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      // Backend dyalkom kiy-rjje3 204 No Content ghaliban
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print("Erreur delete product: $e");
      return false;
    }
  }

  // ==================== 1. GET PRODUCTS (Smart Mode) ====================
  Future<List<Product>> getProducts(String token, {String? filter}) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      bool isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline) {
        final response = await _dio.get(
          baseUrl,
          // --- ZID HAD L-QUERY PARAMETERS ---
          queryParameters: filter != null ? {"filter": filter} : null,
          options: Options(
            headers: {"Authorization": "Bearer $token"},
            sendTimeout: const Duration(seconds: 2),
          ),
        );

        if (response.statusCode == 200) {
          List data = response.data;
          List<Product> products = data
              .map((p) => Product.fromJson(p))
              .toList();

          // N-khbiw l-cache ghi ila m-jbdna kolchi (bla filter) bach may-t-rawench SQLite
          if (filter == null) await _dbHelper.saveProducts(products);

          return products;
        }
      }
    } catch (e) {
      print("Erreur fetching products: $e");
    }

    // ILA OFFLINE: Jbed kolchi o n-f-eltriw b idina wast l-Screen
    return await _dbHelper.getLocalProducts();
  }

  Future<Product?> searchGlobalBarcode(String token, String barcode) async {
    try {
      final response = await _dio.get(
        "${AppConstants.productsUrl}/search-global", // T-akkad mn l-path
        queryParameters: {"barcode": barcode},
        options: Options(
          headers: {
            "Authorization":
                "Bearer $token", // <--- T-akkad mn l-format "Bearer "
          },
        ),
      );
      if (response.statusCode == 200) {
        return Product.fromJson(response.data);
      }
    } catch (e) {
      print("Global search debug: $e");
    }
    return null;
  }

  // ==================== 2. ADD PRODUCT (Smart Mode) ====================
  Future<bool> addProduct(String token, Product product) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      try {
        final response = await _dio.post(
          baseUrl,
          data: product.toJson(),
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          print("Online Success: Produit envoyé au Firebase !");
          return true;
        }
      } catch (e) {
        if (e is DioException) {
          // HNA GHADI T-CHOUL L-ERROR DYAL BACKEND S7I7
          print("ERREUR API S7I7A: ${e.response?.data}");
          print("STATUS CODE: ${e.response?.statusCode}");
        }
        return false; // Rje3 false bach may-goullikch "Succès" o hwa t-bloka
      }
    }

    // OFFLINE FALLBACK
    await _dbHelper.saveSingleProduct(product, isSynced: 0);
    return true;
  }
}
