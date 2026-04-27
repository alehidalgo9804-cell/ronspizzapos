class PosOrder {
  PosOrder({
    required this.id,
    required this.folio,
    required this.total,
    required this.status,
  });

  final int id;
  final String folio;
  final double total;
  final String status;
}