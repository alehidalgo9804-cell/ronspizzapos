import '../../core/network/api_client.dart';

class DeliveryRemoteDataSource {
  DeliveryRemoteDataSource(this.apiClient);

  final ApiClient apiClient;

  Future<Map<String, dynamic>> getDriverDeliveries(int driverId) {
    return apiClient.get('/deliveries/driver/$driverId');
  }
}