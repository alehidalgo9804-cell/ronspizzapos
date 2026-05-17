import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'kitchen_printer.dart';
import 'printer_models.dart';

/// Gestiona impresoras, routing y emite tickets.
class PrinterManager {
  PrinterManager._();
  static final PrinterManager instance = PrinterManager._();

  final List<PosPrinter> _printers = [
    PosPrinter(id: 'pdf-default', name: 'PDF - Vista previa', driver: PrinterDriver.pdf, enabled: true),
  ];

  PrinterRouting _routing = PrinterRouting(
    customerReceiptPrinterId: 'pdf-default',
    kitchenTicketPrinterId: 'pdf-default',
    salesReportPrinterId: 'pdf-default',
  );

  List<PosPrinter> get printers => List.unmodifiable(_printers);
  PrinterRouting get routing => _routing;

  PosPrinter? findPrinter(String? id) {
    if (id == null || id.isEmpty) return null;
    try {
      return _printers.firstWhere((p) => p.id == id && p.enabled);
    } catch (_) {
      return null;
    }
  }

  PosPrinter? resolvePrinter(PrinterDestination destination) {
    final id = _routing.printerIdFor(destination);
    return findPrinter(id) ?? findPrinter('pdf-default');
  }

  void addPrinter(PosPrinter printer) {
    _printers.add(printer);
  }

  void updatePrinter(PosPrinter printer) {
    final index = _printers.indexWhere((p) => p.id == printer.id);
    if (index >= 0) _printers[index] = printer;
  }

  void removePrinter(String id) {
    if (id == 'pdf-default') return; // no borrar la default
    _printers.removeWhere((p) => p.id == id);
  }

  void updateRouting(PrinterRouting routing) {
    _routing = routing;
  }

  /// Imprime o exporta el [text] según la impresora asignada al [destination].
  /// Retorna la ruta del archivo generado (PDF/TXT) o `null` para impresión térmica.
  Future<String?> printTicket({
    required PrinterDestination destination,
    required String text,
  }) async {
    final printer = resolvePrinter(destination);
    if (printer == null) {
      throw Exception('No hay impresora configurada para ${destination.label}');
    }

    switch (printer.driver) {
      case PrinterDriver.pdf:
        return _saveAsTxt(text: text, destination: destination);
      case PrinterDriver.thermalWindows:
        if (kIsWeb || !Platform.isWindows) {
          throw PlatformException(
            code: 'UNSUPPORTED_PLATFORM',
            message: 'Impresion térmica solo disponible en Windows desktop.',
          );
        }
        if (destination == PrinterDestination.kitchenTicket) {
          await KitchenPrinter.printKitchenTicket(text);
        } else {
          await KitchenPrinter.printCustomerReceipt(text);
        }
        return null;
    }
  }

  Future<String> _saveAsTxt({
    required String text,
    required PrinterDestination destination,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'ticket_${destination.name}_$ts.txt';

    if (kIsWeb) {
      // En web solo devolvemos el texto; la UI puede mostrarlo.
      return text;
    }

    late final Directory dir;
    if (Platform.isWindows) {
      dir = await getApplicationDocumentsDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final file = File('${dir.path}\\rons_pizza_tickets\\$fileName');
    await file.parent.create(recursive: true);
    await file.writeAsString(text, encoding: const SystemEncoding());
    return file.path;
  }
}
