import '../network/api_client.dart';

class AppSession {
  AppSession._();

  static final AppSession instance = AppSession._();

  final ApiClient apiClient = ApiClient();

  int branchId = 1;
  int? userId;
  String? userName;
  String? role;

  bool get isAuthenticated => apiClient.token != null && apiClient.token!.isNotEmpty;

  void setAuth({
    required String token,
    required int branchId,
    required int userId,
    required String userName,
    required String role,
  }) {
    apiClient.token = token;
    apiClient.branchId = branchId;
    this.branchId = branchId;
    this.userId = userId;
    this.userName = userName;
    this.role = role;
  }

  void clear() {
    apiClient.token = null;
    userId = null;
    userName = null;
    role = null;
  }
}
