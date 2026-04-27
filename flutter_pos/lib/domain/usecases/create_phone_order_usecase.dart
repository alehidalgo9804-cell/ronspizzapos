import '../entities/pos_order.dart';

abstract class CreatePhoneOrderUseCase {
  Future<PosOrder> execute({
    required String phone,
    required List<Map<String, dynamic>> items,
    int? addressId,
  });
}