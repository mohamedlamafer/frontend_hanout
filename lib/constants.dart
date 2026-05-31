// lib/constants.dart

class AppConstants {
  // Bdel had l-IP b dakchi li kiy-tla3 lik f terminal (ipconfig)
  static const String serverIp = "192.168.0.149";

  // L-Base URL dyal l-API kamla
  static const String baseUrl = "http://$serverIp:8080/api/v1";

  static const String authUrl = "$baseUrl/auth";
  static const String productsUrl = "$baseUrl/products";
  static const String statsUrl = "$baseUrl/statistics";
  static const String salesUrl = "$baseUrl/sales";
  static const String debtsUrl = "$baseUrl/debts";
}
