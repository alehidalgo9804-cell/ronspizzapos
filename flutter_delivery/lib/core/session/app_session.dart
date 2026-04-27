import '../network/api_client.dart';

class AppSession {
  AppSession._();

  static final AppSession instance = AppSession._();

  final ApiClient apiClient = ApiClient();

  int branchId = 1;
  int? userId;
  int? driverId;
  String? driverName;

  bool get isAuthenticated => apiClient.token != null && apiClient.token!.isNotEmpty;

  void setAuth({
    required String token,
    required int branchId,
    required int userId,
    required int driverId,
    required String driverName,
  }) {
    apiClient.token = token;
    apiClient.branchId = branchId;
    this.branchId = branchId;
    this.userId = userId;
    this.driverId = driverId;
    this.driverName = driverName;
  }

  void clear() {
    apiClient.token = null;
    userId = null;
    driverId = null;
    driverName = null;
  }
}
