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
        setState(() => _customers = list);
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
        setState(() => _customers = list);
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
    } else {
      final message = response['message']?.toString() ?? 'Error al guardar';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  Future<int?> _createCustomer({
    required String name,
    required String phone,
  }) async {
    if (name.trim().isEmpty) return null;
    final response = await widget.apiClient.post('/customers', <String, dynamic>{
      'nombre': name.trim(),
      'telefono': phone.trim(),
    });
    if (response['success'] == true && response['data'] is Map) {
      return (response['data'] as Map)['id'] as int?;
    }
    final message = response['message']?.toString() ?? 'Error al crear cliente';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    return null;
  }

  Future<void> _saveAddress({
    required int customerId,
    String? street,
    String? neighborhood,
    String? exteriorNumber,
    String? reference,
    String? alias,
  }) async {
    if (street == null || street.trim().isEmpty) return;
    final body = <String, dynamic>{
      'cliente_id': customerId,
      'calle': street.trim(),
      if (neighborhood != null && neighborhood.trim().isNotEmpty)
        'colonia': neighborhood.trim(),
      if (exteriorNumber != null && exteriorNumber.trim().isNotEmpty)
        'numero_exterior': exteriorNumber.trim(),
      if (reference != null && reference.trim().isNotEmpty)
        'referencia': reference.trim(),
      'alias': (alias != null && alias.trim().isNotEmpty)
          ? alias.trim()
          : 'Principal',
      'activa': 1,
    };
    final response =
        await widget.apiClient.post('/customers/$customerId/addresses', body);
    if (response['success'] != true && mounted) {
      final message = response['message']?.toString() ?? 'Error al guardar dirección';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<List<CustomerAddressData>> _loadAddresses(int customerId) async {
    final response = await widget.apiClient.get('/customers/$customerId/addresses');
    if (response['success'] == true && response['data'] is List) {
      return (response['data'] as List)
          .map((e) => CustomerAddressData.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> _showCustomerDialog({CustomerData? customer}) async {
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final streetController = TextEditingController();
    final neighborhoodController = TextEditingController();
    final extNumberController = TextEditingController();
    final referenceController = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final nav = Navigator.of(context);
        return AlertDialog(
          title: Text(customer == null ? 'Nuevo cliente' : 'Editar cliente'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Dirección principal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    label: 'Calle y número',
                    controller: streetController,
                    hint: 'Ej. Av. Hidalgo 123',
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    label: 'Colonia',
                    controller: neighborhoodController,
                    hint: 'Ej. Centro',
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    label: 'Número exterior',
                    controller: extNumberController,
                    hint: 'Ej. 123',
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    label: 'Referencia / Detalles',
                    controller: referenceController,
                    hint: 'Portón azul, 2do piso...',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(PosLabels.buttons.cancel),
            ),
            TextButton(
              onPressed: () async {
                if (customer == null) {
                  final newId = await _createCustomer(
                    name: nameController.text,
                    phone: phoneController.text,
                  );
                  if (newId != null && streetController.text.trim().isNotEmpty) {
                    await _saveAddress(
                      customerId: newId,
                      street: streetController.text,
                      neighborhood: neighborhoodController.text,
                      exteriorNumber: extNumberController.text,
                      reference: referenceController.text,
                      alias: 'Principal',
                    );
                  }
                } else {
                  await _saveCustomer(
                    id: customer.id,
                    name: nameController.text,
                    phone: phoneController.text,
                  );
                  if (streetController.text.trim().isNotEmpty) {
                    await _saveAddress(
                      customerId: customer.id,
                      street: streetController.text,
                      neighborhood: neighborhoodController.text,
                      exteriorNumber: extNumberController.text,
                      reference: referenceController.text,
                      alias: 'Principal',
                    );
                  }
                }
                if (mounted) nav.pop();
              },
              child: Text(PosLabels.buttons.save),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    streetController.dispose();
    neighborhoodController.dispose();
    extNumberController.dispose();
    referenceController.dispose();
  }

  Future<void> _showCustomerDetailDialog(CustomerData customer) async {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone ?? '');
    List<CustomerAddressData> addresses = [];
    bool loadingAddresses = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final nav = Navigator.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> fetch() async {
              final list = await _loadAddresses(customer.id);
              setDialogState(() {
                addresses = list;
                loadingAddresses = false;
              });
            }

            if (loadingAddresses && addresses.isEmpty) {
              fetch();
            }

            return AlertDialog(
              title: const Text('Detalle del cliente'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Direcciones',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await _showAddressDialog(customerId: customer.id);
                              await fetch();
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Agregar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (loadingAddresses)
                        const Center(child: CircularProgressIndicator())
                      else if (addresses.isEmpty)
                        const Text(
                          'Sin direcciones registradas',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        )
                      else
                        ...addresses.map((a) {
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (a.alias != null && a.alias!.isNotEmpty)
                                    Text(
                                      a.alias!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  Text(
                                    [
                                      a.street,
                                      a.exteriorNumber,
                                      a.neighborhood,
                                    ].where((s) => s != null && s.isNotEmpty).join(', '),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  if (a.reference != null && a.reference!.isNotEmpty)
                                    Text(
                                      a.reference!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(PosLabels.buttons.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    await _saveCustomer(
                      id: customer.id,
                      name: nameController.text,
                      phone: phoneController.text,
                    );
                if (mounted) nav.pop();
                  },
                  child: Text(PosLabels.buttons.save),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
  }

  Future<void> _showAddressDialog({
    required int customerId,
    CustomerAddressData? address,
  }) async {
    final streetController = TextEditingController(text: address?.street ?? '');
    final neighborhoodController =
        TextEditingController(text: address?.neighborhood ?? '');
    final extNumberController =
        TextEditingController(text: address?.exteriorNumber ?? '');
    final referenceController =
        TextEditingController(text: address?.reference ?? '');
    final aliasController = TextEditingController(text: address?.alias ?? '');

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final nav = Navigator.of(context);
        return AlertDialog(
          title: Text(address == null ? 'Nueva dirección' : 'Editar dirección'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildField(
                    label: 'Alias',
                    controller: aliasController,
                    hint: 'Ej. Casa, Trabajo',
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    label: 'Calle y número',
                    controller: streetController,
                    hint: 'Ej. Av. Hidalgo 123',
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    label: 'Colonia',
                    controller: neighborhoodController,
                    hint: 'Ej. Centro',
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    label: 'Número exterior',
                    controller: extNumberController,
                    hint: 'Ej. 123',
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    label: 'Referencia / Detalles',
                    controller: referenceController,
                    hint: 'Portón azul, 2do piso...',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(PosLabels.buttons.cancel),
            ),
            TextButton(
              onPressed: () async {
                await _saveAddress(
                  customerId: customerId,
                  street: streetController.text,
                  neighborhood: neighborhoodController.text,
                  exteriorNumber: extNumberController.text,
                  reference: referenceController.text,
                  alias: aliasController.text,
                );
                if (mounted) nav.pop();
              },
              child: Text(PosLabels.buttons.save),
            ),
          ],
        );
      },
    );

    streetController.dispose();
    neighborhoodController.dispose();
    extNumberController.dispose();
    referenceController.dispose();
    aliasController.dispose();
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
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _showCustomerDetailDialog(c),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
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
