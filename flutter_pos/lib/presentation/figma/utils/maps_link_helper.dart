String? buildGoogleMapsLink({
  double? latitude,
  double? longitude,
  String? address,
}) {
  if (latitude != null && longitude != null) {
    final lat = latitude.toStringAsFixed(6);
    final lng = longitude.toStringAsFixed(6);
    return 'https://www.google.com/maps?q=$lat,$lng';
  }

  final normalizedAddress = (address ?? '').trim();
  if (normalizedAddress.isNotEmpty) {
    final query = Uri.encodeComponent(normalizedAddress);
    return 'https://www.google.com/maps/search/?api=1&query=$query';
  }

  return null;
}
