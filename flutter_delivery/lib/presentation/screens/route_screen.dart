import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/session/app_session.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key, required this.args});

  final Map<String, dynamic> args;

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  List<Map<String, dynamic>> _suggested = <Map<String, dynamic>>[];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestedRoute();
  }

  Future<void> _loadSuggestedRoute() async {
    final driverId = AppSession.instance.driverId;
    if (driverId == null) {
      return;
    }

    setState(() => _loading = true);
    final response = await AppSession.instance.apiClient.get('/deliveries/routes/suggest?repartidor_id=$driverId');
    if (!mounted) return;

    setState(() {
      _suggested = (response['data'] is List)
          ? ((response['data'] as List).cast<Map>().map((e) => e.cast<String, dynamic>()).toList())
          : <Map<String, dynamic>>[];
      _loading = false;
    });
  }

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir Google Maps')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialLat = ((widget.args['lat'] ?? 0) as num).toDouble();
    final initialLng = ((widget.args['lng'] ?? 0) as num).toDouble();
    final initialFolio = (widget.args['folio'] ?? '').toString();
    final initialAddress = (widget.args['address'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta Sugerida'),
        actions: [IconButton(onPressed: _loadSuggestedRoute, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Destino seleccionado: $initialFolio', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (initialAddress.isNotEmpty) Text(initialAddress),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: initialLat == 0 && initialLng == 0 ? null : () => _openMaps(initialLat, initialLng),
                      child: const Text('Navegar destino seleccionado'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Orden sugerido de entregas', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  if (_suggested.isEmpty) const Text('Sin sugerencias disponibles por ahora'),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _suggested.length,
                      itemBuilder: (context, index) {
                        final item = _suggested[index];
                        final lat = ((item['lat'] ?? 0) as num).toDouble();
                        final lng = ((item['lng'] ?? 0) as num).toDouble();
                        return ListTile(
                          title: Text('${item['orden_sugerido']}. ${item['folio'] ?? '-'}'),
                          subtitle: Text('${item['calle'] ?? ''}, ${item['colonia'] ?? ''}'),
                          trailing: IconButton(
                            onPressed: lat == 0 && lng == 0 ? null : () => _openMaps(lat, lng),
                            icon: const Icon(Icons.navigation),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
