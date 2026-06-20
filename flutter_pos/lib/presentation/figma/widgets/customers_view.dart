import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/app_session.dart';
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

  int _currentPage = 1;
  int _totalPages = 1;
  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _loadCustomers(page: 1);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCustomers({required int page, String? query}) async {
    setState(() => _loading = true);
    try {
      final q = query ?? _searchQuery;
      final params = <String, String>{
        'page': page.toString(),
        'page_size': _pageSize.toString(),
        if (q.trim().isNotEmpty) 'busqueda': q.trim(),
      };
      final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final response = await widget.apiClient.get('/admin-clientes?$queryString');
      if (response['success'] == true && response['data'] is Map) {
        final payload = response['data'] as Map<String, dynamic>;
        final rows = payload['data'];
        final list = rows is List
            ? rows.map((e) => CustomerData.fromJson(e as Map<String, dynamic>)).toList()
            : <CustomerData>[];
        final meta = payload['meta'] is Map ? payload['meta'] as Map<String, dynamic> : null;
        setState(() {
          _customers = list;
          _currentPage = meta?['page'] as int? ?? page;
          _totalPages = meta?['pages'] as int? ?? 1;
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
      _loadCustomers(page: 1, query: _searchQuery);
    });
  }

  Future<bool> _requestAdminAuthorization() async {
    if (AppSession.instance.role?.toLowerCase() == 'admin') {
      return true;
    }

    String pinValue = '';
    final authorized = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Autorización de administrador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta acción requiere permisos de administrador. Ingresa el PIN de un administrador para continuar.',
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: 'PIN de administrador',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              onChanged: (value) => pinValue = value.trim(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(PosLabels.buttons.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Autorizar'),
          ),
        ],
      ),
    );

    if (authorized != true || pinValue.isEmpty) return false;

    final response = await widget.apiClient.post('/auth/verify-admin-pin', <String, dynamic>{
      'pin': pinValue,
      'sucursal_id': widget.apiClient.branchId,
      'plataforma': 'pos_flutter',
    });

    if (response['success'] == true) return true;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']?.toString() ?? 'PIN incorrecto'),
        ),
      );
    }
    return false;
  }

  Future<void> _deleteCustomer(int id) async {
    final authorized = await _requestAdminAuthorization();
    if (!authorized) return;
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(PosLabels.buttons.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final response = await widget.apiClient.delete('/admin-clientes/$id');
    if (response['success'] == true) {
      _loadCustomers(page: _currentPage);
    } else {
      final message = response['message']?.toString() ?? 'Error al eliminar';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _saveCustomer({
    int? id,
    required String name,
    String? lastName,
    String? phone,
    String? address,
    String? reference,
    int? addressId,
  }) async {
    if (name.trim().isEmpty) return;
    final body = <String, dynamic>{
      'nombre': name.trim(),
      if (lastName != null && lastName.trim().isNotEmpty) 'apellidos': lastName.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'telefono': phone.trim(),
      if (id == null && address != null && address.trim().isNotEmpty)
        'direccion': {
          'alias': 'Principal',
          'calle': address.trim(),
          if (reference != null && reference.trim().isNotEmpty) 'referencia': reference.trim(),
          'activa': 1,
        },
    };
    debugPrint('[CustomersView] saveCustomer body: $body');
    final response = id == null
        ? await widget.apiClient.post('/admin-clientes', body)
        : await widget.apiClient.put('/admin-clientes/$id', body);
    debugPrint('[CustomersView] saveCustomer response: $response');
    if (response['success'] == true) {
      if (id != null && addressId != null && address != null && address.trim().isNotEmpty) {
        await widget.apiClient.put('/admin-clientes/$id/direcciones/$addressId', {
          'alias': 'Principal',
          'calle': address.trim(),
          if (reference != null && reference.trim().isNotEmpty) 'referencia': reference.trim(),
          'activa': 1,
        });
      }
      _loadCustomers(page: _currentPage);
    } else {
      final message = response['message']?.toString() ?? 'Error al guardar';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<int?> _createCustomer({
    required String name,
    String? lastName,
    String? phone,
    String? address,
    String? reference,
  }) async {
    if (name.trim().isEmpty) return null;
    final body = <String, dynamic>{
      'nombre': name.trim(),
      if (lastName != null && lastName.trim().isNotEmpty) 'apellidos': lastName.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'telefono': phone.trim(),
      if (address != null && address.trim().isNotEmpty)
        'direccion': {
          'alias': 'Principal',
          'calle': address.trim(),
          if (reference != null && reference.trim().isNotEmpty) 'referencia': reference.trim(),
          'activa': 1,
        },
    };
    final response = await widget.apiClient.post('/admin-clientes', body);
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
    int? addressId,
    String? alias,
    String? street,
    String? exteriorNumber,
    String? interiorNumber,
    String? neighborhood,
    String? city,
    String? state,
    String? postalCode,
    String? reference,
    String? deliveryNotes,
  }) async {
    if (street == null || street.trim().isEmpty) return;
    final body = <String, dynamic>{
      'cliente_id': customerId,
      'calle': street.trim(),
      if (alias != null && alias.trim().isNotEmpty) 'alias': alias.trim(),
      if (exteriorNumber != null && exteriorNumber.trim().isNotEmpty)
        'numero_exterior': exteriorNumber.trim(),
      if (interiorNumber != null && interiorNumber.trim().isNotEmpty)
        'numero_interior': interiorNumber.trim(),
      if (neighborhood != null && neighborhood.trim().isNotEmpty) 'colonia': neighborhood.trim(),
      if (city != null && city.trim().isNotEmpty) 'ciudad': city.trim(),
      if (state != null && state.trim().isNotEmpty) 'estado': state.trim(),
      if (postalCode != null && postalCode.trim().isNotEmpty) 'codigo_postal': postalCode.trim(),
      if (reference != null && reference.trim().isNotEmpty) 'referencia': reference.trim(),
      if (deliveryNotes != null && deliveryNotes.trim().isNotEmpty)
        'instrucciones_entrega': deliveryNotes.trim(),
      'activa': 1,
    };
    debugPrint('[CustomersView] saveAddress body: $body');
    final response = addressId == null
        ? await widget.apiClient.post('/admin-clientes/$customerId/direcciones', body)
        : await widget.apiClient.put('/admin-clientes/$customerId/direcciones/$addressId', body);
    debugPrint('[CustomersView] saveAddress response: $response');
    if (response['success'] != true && mounted) {
      final message = response['message']?.toString() ?? 'Error al guardar dirección';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteAddress(int customerId, int addressId) async {
    final authorized = await _requestAdminAuthorization();
    if (!authorized) return;

    final response = await widget.apiClient.delete('/admin-clientes/$customerId/direcciones/$addressId');
    if (response['success'] != true && mounted) {
      final message = response['message']?.toString() ?? 'Error al eliminar dirección';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<List<CustomerAddressData>> _loadAddresses(int customerId) async {
    final response = await widget.apiClient.get('/admin-clientes/$customerId');
    if (response['success'] == true && response['data'] is Map) {
      final data = response['data'] as Map<String, dynamic>;
      final dirs = data['direcciones'];
      if (dirs is List) {
        return dirs.map((e) => CustomerAddressData.fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    return [];
  }

  Future<void> _showCustomerDialog({CustomerData? customer}) async {
    final nameController = TextEditingController(text: customer?.name ?? '');
    final lastNameController = TextEditingController(text: customer?.lastName ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final addressController = TextEditingController();
    final referenceController = TextEditingController();
    List<CustomerAddressData> addresses = [];

    if (customer != null) {
      addresses = await _loadAddresses(customer.id);
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final nav = Navigator.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> reloadAddresses() async {
              if (customer != null) {
                final list = await _loadAddresses(customer.id);
                setDialogState(() => addresses = list);
              }
            }

            return AlertDialog(
              title: Text(customer == null ? 'Nuevo cliente' : 'Editar cliente'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
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
                        label: 'Apellidos',
                        controller: lastNameController,
                        hint: 'Ej. Pérez',
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        label: PosLabels.order.phoneNumber,
                        controller: phoneController,
                        hint: PosLabels.order.enterPhoneNumber,
                        keyboardType: TextInputType.phone,
                      ),
                      if (customer == null) ...[
                        const SizedBox(height: 12),
                        _buildField(
                          label: 'Dirección',
                          controller: addressController,
                          hint: 'Ej. Av. Hidalgo 123, Centro',
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          label: 'Referencias',
                          controller: referenceController,
                          hint: 'Ej. Casa azul, portón negro',
                        ),
                      ] else ...[
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
                            IconButton(
                              icon: const Icon(Icons.add, size: 18, color: Color(0xFF2563EB)),
                              onPressed: () async {
                                await _showAddressDialog(customerId: customer.id);
                                await reloadAddresses();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (addresses.isEmpty)
                          const Text(
                            'Sin direcciones registradas',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          )
                        else
                          ...addresses.map((a) {
                            final street = a.street ?? '';
                            final reference = a.reference ?? '';
                            final showReference = reference.isNotEmpty && !street.toLowerCase().contains(reference.toLowerCase());
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  street,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                                ),
                                subtitle: showReference
                                    ? Text(
                                        reference,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                      )
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit, size: 18, color: Color(0xFF374151)),
                                  onPressed: () async {
                                    await _showAddressDialog(
                                      customerId: customer.id,
                                      address: a,
                                    );
                                    await reloadAddresses();
                                  },
                                ),
                              ),
                            );
                          }),
                      ],
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
                      await _createCustomer(
                        name: nameController.text,
                        lastName: lastNameController.text,
                        phone: phoneController.text,
                        address: addressController.text,
                        reference: referenceController.text,
                      );
                    } else {
                      await _saveCustomer(
                        id: customer.id,
                        name: nameController.text,
                        lastName: lastNameController.text,
                        phone: phoneController.text,
                      );
                    }
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
    lastNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    referenceController.dispose();
  }

  /// Evita mostrar referencia/instrucciones si ya estan contenidas en la
  /// direccion formateada (datos previamente guardados de forma concatenada).
  bool _isTextInAddress(String text, CustomerAddressData address) {
    final fullAddress = [
      if (address.alias != null && address.alias!.isNotEmpty) address.alias,
      address.street,
      address.exteriorNumber,
      address.interiorNumber,
      address.neighborhood,
      address.city,
      address.state,
      address.postalCode,
    ].where((s) => s != null && s.isNotEmpty).join(', ').toLowerCase();
    return fullAddress.contains(text.toLowerCase());
  }

  Future<void> _showCustomerDetailDialog(CustomerData customer) async {
    final nameController = TextEditingController(text: customer.name);
    final lastNameController = TextEditingController(text: customer.lastName ?? '');
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
                constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
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
                        label: 'Apellidos',
                        controller: lastNameController,
                        hint: 'Ej. Pérez',
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          [
                                            if (a.alias != null && a.alias!.isNotEmpty) a.alias,
                                            a.street,
                                            a.exteriorNumber,
                                            a.interiorNumber,
                                            a.neighborhood,
                                            a.city,
                                            a.state,
                                            a.postalCode,
                                          ].where((s) => s != null && s.isNotEmpty).join(', '),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                                        onPressed: () async {
                                          await _deleteAddress(customer.id, a.id);
                                          await fetch();
                                        },
                                      ),
                                    ],
                                  ),
                                  if (a.reference != null &&
                                      a.reference!.isNotEmpty &&
                                      !_isTextInAddress(a.reference!, a))
                                    Text(
                                      'Ref: ${a.reference}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  if (a.deliveryNotes != null &&
                                      a.deliveryNotes!.isNotEmpty &&
                                      !_isTextInAddress(a.deliveryNotes!, a))
                                    Text(
                                      'Instrucciones: ${a.deliveryNotes}',
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
                      lastName: lastNameController.text,
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
    lastNameController.dispose();
    phoneController.dispose();
  }

  Future<void> _showAddressDialog({
    required int customerId,
    CustomerAddressData? address,
  }) async {
    final streetController = TextEditingController(text: address?.street ?? '');
    final referenceController = TextEditingController(text: address?.reference ?? '');

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
                    label: 'Dirección',
                    controller: streetController,
                    hint: 'Ej. Av. Hidalgo 123, Centro',
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    label: 'Referencias',
                    controller: referenceController,
                    hint: 'Ej. Casa azul, portón negro',
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
                  addressId: address?.id,
                  alias: 'Principal',
                  street: streetController.text,
                  reference: referenceController.text,
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
    referenceController.dispose();
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

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _currentPage > 1
                ? () => _loadCustomers(page: _currentPage - 1)
                : null,
            icon: const Icon(Icons.arrow_back_ios, size: 14),
            label: const Text('Anterior'),
          ),
          Text('Página $_currentPage de $_totalPages'),
          TextButton.icon(
            onPressed: _currentPage < _totalPages
                ? () => _loadCustomers(page: _currentPage + 1)
                : null,
            icon: const Icon(Icons.arrow_forward_ios, size: 14),
            label: const Text('Siguiente'),
          ),
        ],
      ),
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
          _buildPagination(),
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
                          c.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (c.phone != null && c.phone!.isNotEmpty)
                              Text(
                                c.phone!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            if (c.email != null && c.email!.isNotEmpty)
                              Text(
                                c.email!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            Text(
                              '${c.totalAddresses} direccion${c.totalAddresses == 1 ? '' : 'es'}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: Color(0xFF374151),
                              ),
                              onPressed: () => _showCustomerDialog(customer: c),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Color(0xFFDC2626),
                              ),
                              onPressed: () => _deleteCustomer(c.id),
                            ),
                          ],
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
