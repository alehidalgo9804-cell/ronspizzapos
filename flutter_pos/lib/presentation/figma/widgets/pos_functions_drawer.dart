import 'package:flutter/material.dart';

Future<void> showPosFunctionsDrawer(
  BuildContext context, {
  VoidCallback? onCreateReport,
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
              child: _PosFunctionsPanel(onCreateReport: onCreateReport),
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
  const _PosFunctionsPanel({this.onCreateReport});

  final VoidCallback? onCreateReport;

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
              item(icon: Icons.key, label: 'Cerrar turno de caja'),
              item(icon: Icons.add_circle_outline, label: 'Añadir transacción'),
              item(icon: Icons.timer_outlined, label: 'Cerrar turno'),
              item(icon: Icons.devices_outlined, label: 'Dispositivos'),
              item(icon: Icons.point_of_sale_outlined, label: 'Abrir caja registradora'),
              item(
                icon: Icons.assessment_outlined,
                label: 'Crear reporte',
                onTap: onCreateReport,
              ),
              item(icon: Icons.refresh_outlined, label: 'Borrar caché'),
              item(icon: Icons.logout, label: 'Cerrar sesión'),
            ],
          ),
        ),
      ],
    );
  }
}
