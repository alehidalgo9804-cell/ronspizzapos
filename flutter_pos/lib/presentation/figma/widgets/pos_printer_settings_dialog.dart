import 'package:flutter/material.dart';

import '../../../core/platform/printer_manager.dart';
import '../../../core/platform/printer_models.dart';
import 'pos_printer_preview_dialog.dart';

extension _PrinterDestinationIcon on PrinterDestination {
  IconData get icon {
    switch (this) {
      case PrinterDestination.customerReceipt:
        return Icons.receipt_long;
      case PrinterDestination.kitchenTicket:
        return Icons.restaurant;
      case PrinterDestination.salesReport:
        return Icons.assessment_outlined;
    }
  }
}

Future<void> showPrinterSettingsDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _PrinterSettingsDialog(),
  );
}

class _PrinterSettingsDialog extends StatefulWidget {
  const _PrinterSettingsDialog();

  @override
  State<_PrinterSettingsDialog> createState() => _PrinterSettingsDialogState();
}

class _PrinterSettingsDialogState extends State<_PrinterSettingsDialog> {
  final PrinterManager _manager = PrinterManager.instance;
  bool _isSavingConfiguration = false;

  void _addPrinter() {
    final id = 'printer_${DateTime.now().millisecondsSinceEpoch}';
    _manager.addPrinter(
      PosPrinter(id: id, name: 'Nueva impresora', driver: PrinterDriver.thermalWindows),
    );
    setState(() {});
  }

  void _removePrinter(String id) {
    _manager.removePrinter(id);
    setState(() {});
  }

  void _updatePrinter(PosPrinter printer) {
    _manager.updatePrinter(printer);
    setState(() {});
  }

  void _updateRouting(PrinterDestination dest, String? printerId) {
    final current = _manager.routing;
    switch (dest) {
      case PrinterDestination.customerReceipt:
        _manager.updateRouting(current.copyWith(customerReceiptPrinterId: printerId));
        break;
      case PrinterDestination.kitchenTicket:
        _manager.updateRouting(current.copyWith(kitchenTicketPrinterId: printerId));
        break;
      case PrinterDestination.salesReport:
        _manager.updateRouting(current.copyWith(salesReportPrinterId: printerId));
        break;
    }
    setState(() {});
  }

  Future<void> _saveConfiguration() async {
    if (_isSavingConfiguration) return;
    setState(() => _isSavingConfiguration = true);
    try {
      await _manager.saveConfiguration();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración de impresoras guardada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingConfiguration = false);
      }
    }
  }

  Future<void> _testPrint(PrinterDestination dest) async {
    final sample = _sampleTicketFor(dest);
    final printer = _manager.resolvePrinter(dest);
    if (printer == null) return;

    if (printer.driver == PrinterDriver.pdf) {
      if (!mounted) return;
      await showPrinterPreviewDialog(
        context,
        title: 'Vista previa: ${dest.label}',
        ticketText: sample,
      );
    } else {
      try {
        await _manager.printTicket(destination: dest, text: sample);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ticket de prueba enviado a ${printer.name}')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _sampleTicketFor(PrinterDestination dest) {
    final now = DateTime.now();
    final b = StringBuffer();
    b.writeln('RONS PIZZA');
    b.writeln('TICKET DE PRUEBA');
    b.writeln('Destino: ${dest.label}');
    b.writeln('Fecha: ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
    b.writeln('------------------------------------------');
    b.writeln('1 x Pizza Pepperoni        \$159.00');
    b.writeln('1 x Refresco 600ml          \$25.00');
    b.writeln('------------------------------------------');
    b.writeln('TOTAL                       \$184.00');
    b.writeln('------------------------------------------');
    b.writeln('');
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final printers = _manager.printers;
    final routing = _manager.routing;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                    label: const Text('Funciones'),
                  ),
                  const Expanded(
                    child: Text(
                      'Configuracion de impresoras',
                      textAlign: TextAlign.center,
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
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Impresoras registradas',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ...printers.map((p) => _printerCard(p)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _addPrinter,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Agregar impresora'),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Asignacion de destinos',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _destinationRow(
                      destination: PrinterDestination.customerReceipt,
                      selectedId: routing.customerReceiptPrinterId,
                    ),
                    const SizedBox(height: 12),
                    _destinationRow(
                      destination: PrinterDestination.kitchenTicket,
                      selectedId: routing.kitchenTicketPrinterId,
                    ),
                    const SizedBox(height: 12),
                    _destinationRow(
                      destination: PrinterDestination.salesReport,
                      selectedId: routing.salesReportPrinterId,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Prueba de impresion',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Envia un ticket de prueba a la impresora asignada para verificar que funciona.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _testButton(PrinterDestination.customerReceipt),
                        _testButton(PrinterDestination.kitchenTicket),
                        _testButton(PrinterDestination.salesReport),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSavingConfiguration
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSavingConfiguration ? null : _saveConfiguration,
                      icon: _isSavingConfiguration
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(
                        _isSavingConfiguration
                            ? 'Guardando...'
                            : 'Guardar configuración',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _printerCard(PosPrinter printer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: printer.name)
                      ..selection = TextSelection.collapsed(offset: printer.name.length),
                    onChanged: (v) => _updatePrinter(printer.copyWith(name: v)),
                  ),
                ),
                if (printer.id != 'pdf-default') ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _removePrinter(printer.id),
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                    tooltip: 'Eliminar',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<PrinterDriver>(
                isExpanded: true,
                value: printer.driver,
                items: PrinterDriver.values
                    .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _updatePrinter(printer.copyWith(driver: v));
                },
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<PrinterPaperWidth>(
                isExpanded: true,
                value: printer.paperWidth,
                items: PrinterPaperWidth.values
                    .map((w) => DropdownMenuItem(value: w, child: Text(w.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _updatePrinter(printer.copyWith(paperWidth: v));
                },
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: printer.enabled,
                  onChanged: printer.id == 'pdf-default'
                      ? null
                      : (v) => _updatePrinter(printer.copyWith(enabled: v ?? true)),
                ),
                const Text('Activa'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: printer.driver == PrinterDriver.pdf
                        ? const Color(0xFFDBEAFE)
                        : const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    printer.driver == PrinterDriver.pdf ? 'PDF' : 'Térmica',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: printer.driver == PrinterDriver.pdf
                          ? const Color(0xFF1E40AF)
                          : const Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _destinationRow({
    required PrinterDestination destination,
    required String? selectedId,
  }) {
    final printers = {
      for (final p in _manager.printers.where((p) => p.enabled)) p.id: p,
    }.values.toList();
    final selectedValue = printers.any((p) => p.id == selectedId) ? selectedId : null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(destination.icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    isDense: true,
                    value: selectedValue,
                    hint: const Text('Seleccionar impresora'),
                    items: printers
                        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                        .toList(),
                    onChanged: (id) => _updateRouting(destination, id),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _testButton(PrinterDestination dest) {
    return OutlinedButton.icon(
      onPressed: () => _testPrint(dest),
      icon: Icon(dest.icon, size: 16),
      label: Text('Probar ${dest.label}'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}
