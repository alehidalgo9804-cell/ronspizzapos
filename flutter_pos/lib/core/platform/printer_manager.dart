import 'dart:convert';
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

  static const String _defaultPdfPrinterId = 'pdf-default';
  static const String _defaultPdfPrinterName = 'PDF - Vista previa';

  final List<PosPrinter> _printers = [
    PosPrinter(
      id: _defaultPdfPrinterId,
      name: _defaultPdfPrinterName,
      driver: PrinterDriver.pdf,
      enabled: true,
    ),
  ];

  PrinterRouting _routing = PrinterRouting(
    customerReceiptPrinterId: _defaultPdfPrinterId,
    kitchenTicketPrinterId: _defaultPdfPrinterId,
    salesReportPrinterId: _defaultPdfPrinterId,
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
    return findPrinter(id) ?? findPrinter(_defaultPdfPrinterId);
  }

  void addPrinter(PosPrinter printer) {
    final existingIndex = _printers.indexWhere((p) => p.id == printer.id);
    if (existingIndex >= 0) {
      _printers[existingIndex] = printer;
    } else {
      _printers.add(printer);
    }
  }

  void updatePrinter(PosPrinter printer) {
    final index = _printers.indexWhere((p) => p.id == printer.id);
    if (index >= 0) {
      if (printer.id == 'pdf-default') {
        _printers[index] = printer.copyWith(enabled: true);
      } else {
        _printers[index] = printer;
      }
    }
  }

  void removePrinter(String id) {
    if (id == _defaultPdfPrinterId) return; // no borrar la default
    _printers.removeWhere((p) => p.id == id);
  }

  void updateRouting(PrinterRouting routing) {
    _routing = routing;
  }

  Future<void> loadConfiguration() async {
    if (kIsWeb) {
      _normalizeState();
      return;
    }
    try {
      final file = await _configFile();
      if (!await file.exists()) {
        _normalizeState();
        return;
      }
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _normalizeState();
        return;
      }

      final printersJson = decoded['printers'];
      final loadedPrinters = <PosPrinter>[];
      if (printersJson is List) {
        for (final item in printersJson) {
          if (item is! Map) continue;
          final id = '${item['id'] ?? ''}'.trim();
          final name = '${item['name'] ?? ''}'.trim();
          final driverRaw = '${item['driver'] ?? ''}'.trim();
          final enabledRaw = item['enabled'];
          final ip = '${item['ip'] ?? ''}'.trim();
          final portRaw = item['port'];
          if (id.isEmpty || name.isEmpty) continue;
          final driver = _driverFromString(driverRaw);
          final enabled = enabledRaw is bool ? enabledRaw : true;
          final paperWidth = _paperWidthFromString('${item['paperWidth'] ?? ''}'.trim());
          final port = portRaw is int ? portRaw : 9100;
          loadedPrinters.add(
            PosPrinter(
              id: id,
              name: name,
              driver: driver,
              enabled: enabled,
              paperWidth: paperWidth,
              ip: ip,
              port: port,
            ),
          );
        }
      }

      if (loadedPrinters.isNotEmpty) {
        _printers
          ..clear()
          ..addAll(loadedPrinters);
      }

      final routingJson = decoded['routing'];
      if (routingJson is Map) {
        _routing = PrinterRouting(
          customerReceiptPrinterId:
              '${routingJson['customerReceiptPrinterId'] ?? ''}'.trim().isEmpty
                  ? null
                  : '${routingJson['customerReceiptPrinterId']}'.trim(),
          kitchenTicketPrinterId:
              '${routingJson['kitchenTicketPrinterId'] ?? ''}'.trim().isEmpty
                  ? null
                  : '${routingJson['kitchenTicketPrinterId']}'.trim(),
          salesReportPrinterId:
              '${routingJson['salesReportPrinterId'] ?? ''}'.trim().isEmpty
                  ? null
                  : '${routingJson['salesReportPrinterId']}'.trim(),
        );
      }
      _normalizeState();
    } catch (_) {
      _normalizeState();
    }
  }

  Future<void> saveConfiguration() async {
    if (kIsWeb) return;
    _normalizeState();
    final file = await _configFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'printers': _printers
            .map((p) => {
                  'id': p.id,
                  'name': p.name,
                  'driver': p.driver.name,
                  'enabled': p.enabled,
                  'paperWidth': p.paperWidth.name,
                  'ip': p.ip,
                  'port': p.port,
                })
            .toList(),
        'routing': {
          'customerReceiptPrinterId': _routing.customerReceiptPrinterId,
          'kitchenTicketPrinterId': _routing.kitchenTicketPrinterId,
          'salesReportPrinterId': _routing.salesReportPrinterId,
        },
      }),
    );
  }

  void _normalizeState() {
    final unique = <String, PosPrinter>{};
    for (final printer in _printers) {
      unique[printer.id] = printer;
    }

    final defaultPrinter = unique[_defaultPdfPrinterId];
    unique[_defaultPdfPrinterId] = PosPrinter(
      id: _defaultPdfPrinterId,
      name: (defaultPrinter?.name.trim().isNotEmpty ?? false)
          ? defaultPrinter!.name
          : _defaultPdfPrinterName,
      driver: PrinterDriver.pdf,
      enabled: true,
    );

    _printers
      ..clear()
      ..addAll(unique.values);
  }

  PrinterDriver _driverFromString(String value) {
    for (final driver in PrinterDriver.values) {
      if (driver.name == value) return driver;
    }
    return PrinterDriver.pdf;
  }

  PrinterPaperWidth _paperWidthFromString(String value) {
    for (final w in PrinterPaperWidth.values) {
      if (w.name == value) return w;
    }
    return PrinterPaperWidth.mm58;
  }

  int charsPerLine(PrinterDestination destination) {
    final printer = resolvePrinter(destination);
    if (printer?.paperWidth == PrinterPaperWidth.mm80) return 48;
    return 42;
  }

  Future<File> _configFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}\\rons_pizza_pos\\printer_config.json');
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
      case PrinterDriver.networkEscPos:
        throw Exception(
          'Las impresoras de red requieren bytes ESC/POS. '
          'Usa printEscPosTicket() en lugar de printTicket().',
        );
    }
  }

  /// Imprime bytes ESC/POS raw en la impresora asignada al [destination].
  /// Soporta impresoras térmicas Windows y de red.
  Future<void> printEscPosTicket({
    required PrinterDestination destination,
    required Uint8List bytes,
  }) async {
    final printer = resolvePrinter(destination);
    if (printer == null) {
      throw Exception('No hay impresora configurada para ${destination.label}');
    }

    switch (printer.driver) {
      case PrinterDriver.pdf:
        throw Exception(
          'ESC/POS no está soportado en modo PDF. '
          'Usa printTicket() para generar vista previa.',
        );
      case PrinterDriver.thermalWindows:
        if (kIsWeb || !Platform.isWindows) {
          throw PlatformException(
            code: 'UNSUPPORTED_PLATFORM',
            message: 'Impresion térmica solo disponible en Windows desktop.',
          );
        }
        if (destination == PrinterDestination.kitchenTicket) {
          await KitchenPrinter.printKitchenTicketBytes(bytes);
        } else {
          await KitchenPrinter.printCustomerReceiptBytes(bytes);
        }
        return;
      case PrinterDriver.networkEscPos:
        await _sendNetworkBytes(printer.ip, printer.port, bytes);
        return;
    }
  }

  /// Envía [bytes] a una impresora de red ESC/POS por TCP.
  Future<void> _sendNetworkBytes(String ip, int port, Uint8List bytes) async {
    if (ip.isEmpty) {
      throw Exception('La impresora de red no tiene IP configurada.');
    }
    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      socket.add(bytes);
      await socket.flush();
      // Pequeña pausa para asegurar que el buffer se transmita antes de cerrar.
      await Future.delayed(const Duration(milliseconds: 200));
    } on SocketException catch (e) {
      throw Exception('No se pudo conectar a la impresora de red $ip:$port. ${e.message}');
    } catch (e) {
      throw Exception('Error enviando ticket a $ip:$port: $e');
    } finally {
      socket?.destroy();
    }
  }

  /// Intenta conectarse a [ip]:[port] para verificar que la impresora responde.
  Future<bool> testNetworkConnection(String ip, int port) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 3));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Escanea la red local buscando impresoras ESC/POS en el puerto 9100.
  /// [subnet] debe ser algo como "192.168.1" y [start]-[end] el rango de host.
  /// Retorna una lista de IPs que respondieron en el puerto 9100.
  Future<List<String>> discoverNetworkPrinters({
    required String subnet,
    int start = 1,
    int end = 254,
    int port = 9100,
    Duration timeout = const Duration(milliseconds: 800),
  }) async {
    final found = <String>[];
    final futures = <Future<void>>[];
    for (int i = start; i <= end; i++) {
      final ip = '$subnet.$i';
      futures.add(
        Future(() async {
          try {
            final socket = await Socket.connect(ip, port, timeout: timeout);
            socket.destroy();
            found.add(ip);
          } catch (_) {
            // ignorar hosts que no respondan
          }
        }),
      );
    }
    await Future.wait(futures);
    return found;
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
