import '../../domain/entities/delivery_task.dart';
import '../datasources/delivery_remote_datasource.dart';

class DeliveryRepositoryImpl {
  DeliveryRepositoryImpl(this.remote);

  final DeliveryRemoteDataSource remote;

  Future<List<DeliveryTask>> assigned(int driverId) async {
    final response = await remote.getDriverDeliveries(driverId);
    final list = (response['data'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e as Map<String, dynamic>)
        .map(
          (e) => DeliveryTask(
            id: (e['id'] ?? 0) as int,
            orderFolio: (e['folio'] ?? '') as String,
            status: (e['estado'] ?? '') as String,
            lat: ((e['lat_destino'] ?? 0) as num).toDouble(),
            lng: ((e['lng_destino'] ?? 0) as num).toDouble(),
          ),
        )
        .toList();

    return list;
  }
}