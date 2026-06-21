import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../constants/labels.dart';

class PosBranchesView extends StatefulWidget {
  const PosBranchesView({
    super.key,
    required this.apiClient,
    required this.onBack,
  });

  final ApiClient apiClient;
  final VoidCallback onBack;

  @override
  State<PosBranchesView> createState() => _PosBranchesViewState();
}

class _PosBranchesViewState extends State<PosBranchesView> {
  bool _isLoading = false;
  String? _loadError;
  List<Map<String, dynamic>> _branches = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final dateStr = _formatDate(_selectedDate);
      final response = await widget.apiClient.get('/reportes/sucursales-resumen?date=$dateStr');

      if (response['success'] == true && response['data'] is List) {
        setState(() {
          _branches = (response['data'] as List)
              .map((e) => (e as Map).cast<String, dynamic>())
              .toList();
        });
      } else {
        final message = response['message']?.toString() ?? 'Error al cargar sucursales';
        setState(() => _loadError = message);
        _showError(message);
      }
    } catch (e) {
      final message = 'Error al cargar sucursales: $e';
      setState(() => _loadError = message);
      _showError(message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    _loadBranches();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.year}-${_two(value.month)}-${_two(value.day)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  String _mxn(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Sucursales',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFFDC2626)),
            label: Text(
              _formatDate(_selectedDate),
              style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF374151)),
            onPressed: _loadBranches,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF374151)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _loadBranches,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                )
              : _branches.isEmpty
                  ? const Center(child: Text('No hay sucursales activas'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _branches.length,
                      itemBuilder: (_, index) => _buildBranchCard(_branches[index]),
                    ),
    );
  }

  Widget _buildBranchCard(Map<String, dynamic> branch) {
    final name = '${branch['nombre'] ?? 'Sucursal'}';
    final key = '${branch['clave'] ?? ''}'.trim();
    final orders = (branch['total_pedidos'] as num?)?.toInt() ?? 0;
    final sales = (branch['total_ventas'] as num?)?.toDouble() ?? 0.0;
    final tickets = (branch['total_tickets'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (key.isNotEmpty)
                        Text(
                          key,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _metricBox(
                    label: 'Ventas',
                    value: '$orders',
                    subValue: _mxn(sales),
                    icon: Icons.point_of_sale,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricBox(
                    label: 'Tickets impresos',
                    value: '$tickets',
                    subValue: tickets == 1 ? 'ticket' : 'tickets',
                    icon: Icons.receipt_long,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBox({
    required String label,
    required String value,
    required String subValue,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  subValue,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
