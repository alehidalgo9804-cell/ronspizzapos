import 'package:flutter/material.dart';

import '../../core/session/app_session.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  List<Map<String, dynamic>> _deliveries = <Map<String, dynamic>>[];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    final session = AppSession.instance;
    final driverId = session.driverId;
    if (driverId == null) {
      return;
    }

    setState(() => _loading = true);
    final response = await session.apiClient.get('/deliveries/driver/$driverId');

    if (!mounted) return;
    setState(() {
      _deliveries = (response['data'] is List)
          ? ((response['data'] as List).cast<Map>().map((e) => e.cast<String, dynamic>()).toList())
          : <Map<String, dynamic>>[];
      _loading = false;
    });
  }

  Future<void> _updateStatus(int deliveryId, String status) async {
    final response = await AppSession.instance.apiClient.put('/deliveries/$deliveryId/status', {
      'estado': status,
      'repartidor_id': AppSession.instance.driverId,
    });

    if (response['success'] != true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((response['message'] ?? 'No se pudo actualizar estado').toString())),
      );
    }
    await _loadDeliveries();
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSession.instance;
    return Scaffold(
      appBar: AppBar(
        title: Text('Entregas - ${session.driverName ?? ''}'),
        actions: [
          IconButton(onPressed: _loadDeliveries, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: () async {
              await session.apiClient.post('/auth/logout', {});
              session.clear();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _deliveries.length,
              itemBuilder: (context, index) {
                final d = _deliveries[index];
                final id = d['id'] as int;
                final lat = ((d['direccion_lat'] ?? d['lat_destino'] ?? 0) as num).toDouble();
                final lng = ((d['direccion_lng'] ?? d['lng_destino'] ?? 0) as num).toDouble();
                final address = '${d['calle'] ?? ''}, ${d['colonia'] ?? ''}';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pedido ${d['folio'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Cliente: ${d['cliente_nombre'] ?? 'N/A'}'),
                        Text('Direccion: $address'),
                        Text('Estado: ${d['estado'] ?? ''}'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () => _updateStatus(id, 'recogido'),
                              child: const Text('Recogido'),
                            ),
                            OutlinedButton(
                              onPressed: () => _updateStatus(id, 'en_ruta'),
                              child: const Text('En ruta'),
                            ),
                            FilledButton(
                              onPressed: () => _updateStatus(id, 'entregado'),
                              child: const Text('Entregado'),
                            ),
                            FilledButton.tonal(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                '/route',
                                arguments: {
                                  'delivery_id': id,
                                  'folio': d['folio'] ?? '',
                                  'lat': lat,
                                  'lng': lng,
                                  'address': address,
                                },
                              ),
                              child: const Text('Ruta'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
