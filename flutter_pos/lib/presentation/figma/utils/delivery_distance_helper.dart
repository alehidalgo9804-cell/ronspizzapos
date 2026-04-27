import 'dart:math' as math;

class DeliveryDistanceResult {
  const DeliveryDistanceResult({
    required this.straightDistanceKm,
    required this.estimatedRoadDistanceKm,
    required this.distanceFactor,
  });

  final double straightDistanceKm;
  final double estimatedRoadDistanceKm;
  final double distanceFactor;
}

/// Utilidad base para reparto.
///
/// - `straightDistanceKm`: distancia en línea recta (Haversine)
/// - `estimatedRoadDistanceKm`: aproximación por calles usando un factor
class DeliveryDistanceHelper {
  const DeliveryDistanceHelper._();

  static const double defaultDistanceFactor = 1.33;

  static DeliveryDistanceResult? estimateFromCoordinates({
    required double? branchLatitude,
    required double? branchLongitude,
    required double? customerLatitude,
    required double? customerLongitude,
    double distanceFactor = defaultDistanceFactor,
  }) {
    if (branchLatitude == null ||
        branchLongitude == null ||
        customerLatitude == null ||
        customerLongitude == null) {
      return null;
    }

    final safeFactor = distanceFactor > 0 ? distanceFactor : defaultDistanceFactor;
    final straight = haversineKm(
      branchLatitude,
      branchLongitude,
      customerLatitude,
      customerLongitude,
    );

    return DeliveryDistanceResult(
      straightDistanceKm: straight,
      estimatedRoadDistanceKm: straight * safeFactor,
      distanceFactor: safeFactor,
    );
  }

  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double degrees) => degrees * (math.pi / 180.0);
}
