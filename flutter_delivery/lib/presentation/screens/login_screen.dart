import 'package:flutter/material.dart';

import '../../core/session/app_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinController = TextEditingController(text: '2222');
  final _branchController = TextEditingController(text: '1');
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final branchId = int.tryParse(_branchController.text.trim()) ?? 0;
    final pin = _pinController.text.trim();
    if (branchId <= 0 || pin.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Captura sucursal y PIN.';
      });
      return;
    }

    final session = AppSession.instance;
    final authResp = await session.apiClient.post('/auth/login', {
      'pin': pin,
      'sucursal_id': branchId,
      'plataforma': 'delivery',
    });

    if (authResp['success'] != true) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = (authResp['message'] ?? 'No se pudo iniciar sesion').toString();
      });
      return;
    }

    final data = (authResp['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
    final token = (data['token'] ?? '').toString();
    final user = (data['user'] as Map<String, dynamic>? ?? <String, dynamic>{});
    session.apiClient.token = token;
    session.apiClient.branchId = branchId;

    final driverResp = await session.apiClient.get('/drivers/me');
    if (!mounted) return;

    if (driverResp['success'] != true || driverResp['data'] is! Map<String, dynamic>) {
      setState(() {
        _loading = false;
        _error = (driverResp['message'] ?? 'No hay repartidor asociado al usuario').toString();
      });
      return;
    }

    final driver = driverResp['data'] as Map<String, dynamic>;
    session.setAuth(
      token: token,
      branchId: branchId,
      userId: (user['id'] ?? 0) as int,
      driverId: (driver['id'] ?? 0) as int,
      driverName: '${driver['nombre'] ?? ''} ${driver['apellidos'] ?? ''}'.trim(),
    );

    setState(() => _loading = false);
    Navigator.pushReplacementNamed(context, '/deliveries');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 360,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Rons Delivery', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _branchController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Sucursal ID'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pinController,
                    decoration: const InputDecoration(labelText: 'PIN repartidor'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Entrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
