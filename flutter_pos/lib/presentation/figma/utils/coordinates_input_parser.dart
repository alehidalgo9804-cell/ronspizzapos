class CoordinatesParseResult {
  const CoordinatesParseResult({
    this.latitude,
    this.longitude,
    this.error,
  });

  final double? latitude;
  final double? longitude;
  final String? error;

  bool get hasCoordinates => latitude != null && longitude != null;
}

CoordinatesParseResult parseCoordinatesInput(String raw) {
  final input = raw.trim();
  if (input.isEmpty) {
    return const CoordinatesParseResult();
  }

  final parts = input.split(',');
  if (parts.length != 2) {
    return const CoordinatesParseResult(
      error: 'Formato inválido. Usa: latitud, longitud',
    );
  }

  final latText = parts.first.trim();
  final lngText = parts.last.trim();
  final lat = double.tryParse(latText);
  final lng = double.tryParse(lngText);

  if (lat == null || lng == null) {
    return const CoordinatesParseResult(
      error: 'Las coordenadas deben ser números válidos.',
    );
  }

  if (lat < -90 || lat > 90) {
    return const CoordinatesParseResult(
      error: 'La latitud debe estar entre -90 y 90.',
    );
  }

  if (lng < -180 || lng > 180) {
    return const CoordinatesParseResult(
      error: 'La longitud debe estar entre -180 y 180.',
    );
  }

  return CoordinatesParseResult(latitude: lat, longitude: lng);
}
