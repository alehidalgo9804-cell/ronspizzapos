import 'package:flutter/material.dart';

import '../../../core/session/app_session.dart';

Future<void> showPosFunctionsDrawer(
  BuildContext context, {
  VoidCallback? onCreateReport,
  VoidCallback? onPrinterSettings,
  VoidCallback? onLogout,
  VoidCallback? onCustomers,
  VoidCallback? onUsers,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar panel',
    barrierColor: const Color(0x66000000),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, _, __) {
      return SafeArea(
        child: Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            elevation: 18,
            child: SizedBox(
              width: 360,
              height: double.infinity,
              child: _PosFunctionsPanel(
                onCreateReport: onCreateReport,
                onPrinterSettings: onPrinterSettings,
                onLogout: onLogout,
                onCustomers: onCustomers,
                onUsers: onUsers,
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, animation, __, child) {
      final offset = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(animation);
      return SlideTransition(position: offset, child: child);
    },
  );
}

class _PosFunctionsPanel extends StatelessWidget {
  const _PosFunctionsPanel({this.onCreateReport, this.onPrinterSettings, this.onLogout, this.onCustomers, this.onUsers});

  final VoidCallback? onCreateReport;
  final VoidCallback? onPrinterSettings;
  final VoidCallback? onLogout;
  final VoidCallback? onCustomers;
  final VoidCallback? onUsers;

  bool get _isAdmin => AppSession.instance.role?.toLowerCase() == 'admin';

  @override
  Widget build(BuildContext context) {
    Widget item({
      required IconData icon,
      required String label,
      VoidCallback? onTap,
    }) {
      return ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: const Color(0xFF374151)),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          if (onTap != null) onTap();
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Funciones',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                tooltip: 'Cerrar',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (_isAdmin) ...[
                item(
                  icon: Icons.people_outline,
                  label: 'Usuarios',
                  onTap: onUsers,
                ),
              ],
              item(
                icon: Icons.contacts_outlined,
                label: 'Clientes',
                onTap: onCustomers,
              ),
              if (_isAdmin) ...[
                item(
                  icon: Icons.receipt_long_outlined,
                  label: 'Recibos',
                  onTap: () => _showPlaceholder(context, 'Recibos'),
                ),
              ],
              item(
                icon: Icons.assessment_outlined,
                label: 'Reportes',
                onTap: onCreateReport,
              ),
              if (_isAdmin) ...[
                item(
                  icon: Icons.store_outlined,
                  label: 'Sucursales',
                  onTap: () => _showPlaceholder(context, 'Sucursales'),
                ),
              ],
              const Divider(height: 24, indent: 16, endIndent: 16),
              item(
                icon: Icons.print_outlined,
                label: 'Impresora',
                onTap: onPrinterSettings,
              ),
              item(icon: Icons.logout, label: 'Cerrar sesión', onTap: onLogout),
            ],
          ),
        ),
      ],
    );
  }

  void _showPlaceholder(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature estará disponible en una próxima fase.')),
    );
  }
}
