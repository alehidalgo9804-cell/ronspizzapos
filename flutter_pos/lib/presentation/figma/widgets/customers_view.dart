import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../constants/labels.dart';
import '../figma_models.dart';

class CustomersView extends StatefulWidget {
  const CustomersView({
    super.key,
    required this.apiClient,
    required this.onBack,
  });

  final ApiClient apiClient;
  final VoidCallback onBack;

  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  List<CustomerData> _customers = [];
  bool _loading = false;
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _loading = true);
    try {
      final response = await widget.apiClient.get('/customers?limit=500');
      if (response['success'] == true && response['data'] is List) {
        final list = (response['data'] as List)
            .map((e) => CustomerData.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _customers = list;
        });
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _searchCustomers(String query) async {
    setState(() => _loading = true);
    try {
      final q = Uri.encodeComponent(query.trim());
      final response =
          await widget.apiClient.get('/customers/search?q=$q&limit=50');
      if (response['success'] == true && response['data'] is List) {
        final list = (response['data'] as List)
            .map((e) => CustomerData.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _customers = list;
        });
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (_searchQuery.trim().isEmpty) {
        _loadCustomers();
      } else {
        _searchCustomers(_searchQuery);
      }
    });
  }

  Future<void> _saveCustomer({
    int? id,
    required String name,
    required String phone,
  }) async {
    if (name.trim().isEmpty) return;
    final body = <String, dynamic>{
      'nombre': name.trim(),
      'telefono': phone.trim(),
    };
    final response = id == null
        ? await widget.apiClient.post('/customers', body)
        : await widget.apiClient.put('/customers/$id', body);
    if (response['success'] == true) {
      _loadCustomers();
      if (mounted) Navigator.of(context).pop();
    } else {
      final message = response['message']?.toString() ?? 'Error al guardar';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  Future<void> _showCustomerDialog({CustomerData? customer}) async {
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final isEditing = customer != null;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar cliente' : 'Nuevo cliente'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(
                  label: PosLabels.order.customerName,
                  controller: nameController,
                  hint: PosLabels.order.enterCustomerName,
                ),
                const SizedBox(height: 12),
                _buildField(
                  label: PosLabels.order.phoneNumber,
                  controller: phoneController,
                  hint: PosLabels.order.enterPhoneNumber,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(PosLabels.buttons.cancel),
            ),
            TextButton(
              onPressed: () {
                _saveCustomer(
                  id: customer?.id,
                  name: nameController.text,
                  phone: phoneController.text,
                );
              },
              child: Text(PosLabels.buttons.save),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
            hintText: hint,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Clientes',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                hintText: 'Buscar por nombre o teléfono',
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          if (_loading && _customers.isEmpty)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_customers.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Sin clientes registrados',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                itemCount: _customers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final c = _customers[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(
                        c.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      subtitle: c.phone != null && c.phone!.isNotEmpty
                          ? Text(
                              c.phone!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            )
                          : null,
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Color(0xFF374151),
                        ),
                        onPressed: () => _showCustomerDialog(customer: c),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerDialog(),
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.person_add, size: 18),
        label: const Text('Agregar cliente'),
      ),
    );
  }
}
