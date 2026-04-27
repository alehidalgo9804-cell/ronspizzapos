class DeliveryTask {
  DeliveryTask({
    required this.id,
    required this.orderFolio,
    required this.status,
    required this.lat,
    required this.lng,
  });

  final int id;
  final String orderFolio;
  final String status;
  final double lat;
  final double lng;
}