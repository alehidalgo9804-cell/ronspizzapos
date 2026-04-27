import '../../core/network/api_client.dart';

class OrderRemoteDataSource {
  OrderRemoteDataSource(this.apiClient);

  final ApiClient apiClient;

  Future<Map<String, dynamic>> createQuickPhoneOrder(Map<String, dynamic> payload) {
    return apiClient.post('/orders/quick-phone', payload);
  }
}