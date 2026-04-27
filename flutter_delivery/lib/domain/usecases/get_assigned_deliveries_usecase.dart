import '../entities/delivery_task.dart';

abstract class GetAssignedDeliveriesUseCase {
  Future<List<DeliveryTask>> execute(int driverId);
}