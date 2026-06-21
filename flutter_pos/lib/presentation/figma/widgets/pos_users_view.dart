import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/app_session.dart';
import '../constants/labels.dart';

class PosUsersView extends StatefulWidget {
  const PosUsersView({
    super.key,
    required this.apiClient,
    required this.onBack,
  });

  final ApiClient apiClient;
  final VoidCallback onBack;

  @override
  State<PosUsersView> createState() => _PosUsersViewState();
}

class _PosUsersViewState extends State<PosUsersView> {
  bool _isLoading = false;
  String? _loadError;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _roles = [];

  int? _selectedBranchId;
  int? _selectedRoleId;
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadFilters().then((_) => _loadUsers());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    setState(() {});
    try {
      final branchesResponse = await widget.apiClient.get('/admin-sucursales');
      final rolesResponse = await widget.apiClient.get('/admin-roles');

      if (branchesResponse['success'] == true && branchesResponse['data'] is List) {
        _branches = (branchesResponse['data'] as List)
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
      }
      if (rolesResponse['success'] == true && rolesResponse['data'] is List) {
        _roles = (rolesResponse['data'] as List)
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
      }
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final params = <String, String>{
        if (_selectedBranchId != null) 'sucursal_id': _selectedBranchId.toString(),
        if (_selectedRoleId != null) 'rol_id': _selectedRoleId.toString(),
        if (_searchQuery.trim().isNotEmpty) 'busqueda': _searchQuery.trim(),
      };
      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final response = await widget.apiClient.get('/admin-usuarios${queryString.isNotEmpty ? '?$queryString' : ''}');

      if (response['success'] == true && response['data'] is List) {
        setState(() {
          _users = (response['data'] as List)
              .map((e) => (e as Map).cast<String, dynamic>())
              .toList();
        });
      } else {
        final message = response['message']?.toString() ?? 'Error al cargar usuarios';
        setState(() => _loadError = message);
        _showError(message);
      }
    } catch (e) {
      final message = 'Error al cargar usuarios: $e';
      setState(() => _loadError = message);
      _showError(message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _loadUsers();
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
        title: const Text('Autorizacion de administrador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta accion requiere permisos de administrador. Ingresa el PIN de un administrador para continuar.',
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

  Future<void> _deleteUser(int id) async {
    final authorized = await _requestAdminAuthorization();
    if (!authorized) return;
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: const Text('¿Estas seguro? Esta accion no se puede deshacer.'),
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

    final response = await widget.apiClient.delete('/admin-usuarios/$id');
    if (response['success'] == true) {
      _loadUsers();
    } else {
      _showError(response['message']?.toString() ?? 'Error al eliminar');
    }
  }

  Future<void> _openUserForm({Map<String, dynamic>? user}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _UserFormDialog(
        apiClient: widget.apiClient,
        branches: _branches,
        roles: _roles,
        user: user,
      ),
    );
    if (result == true) {
      _loadUsers();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _fullName(Map<String, dynamic> user) {
    final name = '${user['nombre'] ?? ''}'.trim();
    final lastName = '${user['apellido'] ?? ''}'.trim();
    return '$name ${lastName.isNotEmpty ? lastName : ''}'.trim();
  }

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
          'Usuarios',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF374151)),
            onPressed: _loadUsers,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
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
                              onPressed: _loadUsers,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                            ),
                          ],
                        ),
                      )
                    : _users.isEmpty
                        ? const Center(child: Text('No hay usuarios registrados'))
                        : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (_, index) => _buildUserCard(_users[index]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openUserForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo usuario'),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int?>(
                  key: ValueKey(_selectedBranchId),
                  initialValue: _selectedBranchId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sucursal',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Todas las sucursales')),
                    ..._branches.map((b) => DropdownMenuItem<int?>(
                          value: _toInt(b['id']),
                          child: Text('${b['nombre'] ?? '-'}'),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedBranchId = value);
                    _loadUsers();
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<int?>(
                  key: ValueKey(_selectedRoleId),
                  initialValue: _selectedRoleId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Todos los roles')),
                    ..._roles.map((r) => DropdownMenuItem<int?>(
                          value: _toInt(r['id']),
                          child: Text('${r['nombre'] ?? '-'}'),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedRoleId = value);
                    _loadUsers();
                  },
                ),
              ),
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar',
                    hintText: 'Usuario, nombre o email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final roleName = '${user['rol_nombre'] ?? ''}'.toLowerCase();
    final badgeColor = roleName == 'admin'
        ? const Color(0xFFDC2626)
        : roleName == 'cocina'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF2563EB);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _fullName(user),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${user['rol_nombre'] ?? '-'}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _infoRow('Usuario', '${user['usuario'] ?? '-'}'),
            _buildBranchesRow(user),
            _infoRow('Estado', (user['activo'] == 1 || user['activo'] == true) ? 'Activo' : 'Inactivo'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _openUserForm(user: user),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Editar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _deleteUser(_toInt(user['id'])),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchesRow(Map<String, dynamic> user) {
    final branches = (user['sucursales'] as List?) ?? [];
    if (branches.isEmpty) {
      return _infoRow('Sucursales', '${user['sucursal_nombre'] ?? '-'}');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sucursales: ',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: branches.map<Widget>((b) {
                final name = '${b['nombre'] ?? '-'}';
                final isPrincipal = b['es_principal'] == 1 || b['es_principal'] == true;
                return Chip(
                  label: Text(
                    isPrincipal ? '$name (principal)' : name,
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: const Color(0xFFE5E7EB),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({
    required this.apiClient,
    required this.branches,
    required this.roles,
    this.user,
  });

  final ApiClient apiClient;
  final List<Map<String, dynamic>> branches;
  final List<Map<String, dynamic>> roles;
  final Map<String, dynamic>? user;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usuarioController;
  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _pinController;

  int? _selectedRoleId;
  final List<int> _selectedBranchIds = [];
  bool _activo = true;
  bool _isSaving = false;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _usuarioController = TextEditingController(text: u != null ? '${u['usuario'] ?? ''}' : '');
    _nombreController = TextEditingController(text: u != null ? '${u['nombre'] ?? ''}' : '');
    _apellidoController = TextEditingController(text: u != null ? '${u['apellido'] ?? ''}' : '');
    _pinController = TextEditingController();

    if (u != null) {
      _selectedRoleId = _toInt(u['rol_id']);
      final branches = (u['sucursales'] as List?) ?? [];
      if (branches.isNotEmpty) {
        _selectedBranchIds.addAll(
          branches.map<int>((b) => _toInt(b['id'])),
        );
      } else {
        final principalId = _toInt(u['sucursal_id']);
        if (principalId > 0) {
          _selectedBranchIds.add(principalId);
        }
      }
      _pinController.text = '${u['pin'] ?? ''}';
      final activo = u['activo'];
      _activo = activo == 1 || activo == true || activo == '1';
    }
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final body = <String, dynamic>{
      'usuario': _usuarioController.text.trim(),
      'nombre': _nombreController.text.trim(),
      'apellido': _apellidoController.text.trim(),
      'rol_id': _selectedRoleId,
      'sucursales': _selectedBranchIds,
      'activo': _activo ? 1 : 0,
      'pin': _pinController.text.trim(),
    };

    try {
      final response = _isEditing
          ? await widget.apiClient.put('/admin-usuarios/${_toInt(widget.user!['id'])}', body)
          : await widget.apiClient.post('/admin-usuarios', body);

      if (response['success'] == true) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final message = response['message']?.toString() ??
            (response['errors'] is Map
                ? (response['errors'] as Map).values.join(', ')
                : 'Error al guardar');
        _showError(message);
      }
    } catch (e) {
      _showError('Error al guardar: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isDesktop ? 80 : 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF374151)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            title: Text(
              _isEditing ? 'Editar usuario' : 'Nuevo usuario',
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildTextField(
                  controller: _usuarioController,
                  label: 'Usuario *',
                  validator: (v) => v == null || v.trim().length < 3
                      ? 'El usuario debe tener al menos 3 caracteres'
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _nombreController,
                        label: 'Nombre *',
                        validator: (v) => v == null || v.trim().isEmpty ? 'El nombre es obligatorio' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _apellidoController,
                        label: 'Apellido',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _pinController,
                  label: 'PIN *',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  obscureText: false,
                  validator: (v) {
                    if (v == null || v.trim().length < 4) {
                      return 'El PIN debe tener al menos 4 digitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  key: ValueKey(_selectedRoleId),
                  initialValue: _selectedRoleId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Rol *',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.roles
                      .map((r) => DropdownMenuItem<int?>(
                            value: _toInt(r['id']),
                            child: Text('${r['nombre'] ?? '-'}'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedRoleId = value),
                  validator: (v) => v == null ? 'Selecciona un rol' : null,
                ),
                const SizedBox(height: 16),
                _buildBranchesSelector(),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Activo'),
                  value: _activo,
                  onChanged: (value) => setState(() => _activo = value),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                  child: Text(PosLabels.buttons.cancel),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranchesSelector() {
    final allSelected = _selectedBranchIds.length == widget.branches.length && widget.branches.isNotEmpty;

    return FormField<List<int>>(
      initialValue: _selectedBranchIds,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecciona al menos una sucursal';
        }
        return null;
      },
      builder: (field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: 'Sucursales *',
            border: const OutlineInputBorder(),
            errorText: field.errorText,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Todas'),
                    selected: allSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedBranchIds
                            ..clear()
                            ..addAll(widget.branches.map<int>((b) => _toInt(b['id'])));
                        } else {
                          _selectedBranchIds.clear();
                        }
                      });
                      field.didChange(_selectedBranchIds);
                    },
                  ),
                  ...widget.branches.map((b) {
                    final id = _toInt(b['id']);
                    final selected = _selectedBranchIds.contains(id);
                    return FilterChip(
                      label: Text('${b['nombre'] ?? '-'}'),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            if (!_selectedBranchIds.contains(id)) {
                              _selectedBranchIds.add(id);
                            }
                          } else {
                            _selectedBranchIds.remove(id);
                          }
                        });
                        field.didChange(_selectedBranchIds);
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'La primera sucursal seleccionada se considera la principal.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
