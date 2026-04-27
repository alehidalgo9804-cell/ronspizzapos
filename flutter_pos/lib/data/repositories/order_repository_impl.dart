import '../../domain/entities/pos_order.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepositoryImpl {
  OrderRepositoryImpl(this.remote);

  final OrderRemoteDataSource remote;

  Future<PosOrder> createQuickPhoneOrder(Map<String, dynamic> payload) async {
    final response = await remote.createQuickPhoneOrder(payload);
    final data = response['data'] as Map<String, dynamic>;

    int toInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double toDouble(dynamic value, {double fallback = 0}) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    return PosOrder(
      id: toInt(data['id']),
      folio: (data['folio'] ?? '') as String,
      total: toDouble(data['total']),
      status: (data['estado'] ?? 'creado') as String,
    );
  }
}
