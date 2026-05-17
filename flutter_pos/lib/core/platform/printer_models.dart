/// Tipo de driver de impresora soportado.
enum PrinterDriver {
  /// PDF para guardar/visualizar el ticket.
  pdf,

  /// Impresora térmica Windows (ESC/POS) vía MethodChannel.
  thermalWindows,
}

/// Extensión para nombres legibles del driver.
extension PrinterDriverLabel on PrinterDriver {
  String get label {
    switch (this) {
      case PrinterDriver.pdf:
        return 'PDF (Guardar / Vista previa)';
      case PrinterDriver.thermalWindows:
        return 'Térmica Windows (ESC/POS)';
    }
  }
}

/// Destino / rol de la impresora dentro del POS.
enum PrinterDestination {
  /// Ticket para el cliente (recibo de pago).
  customerReceipt,

  /// Ticket de cocina / comanda.
  kitchenTicket,

  /// Reporte de ventas.
  salesReport,
}

/// Extensión para nombres legibles del destino.
extension PrinterDestinationLabel on PrinterDestination {
  String get label {
    switch (this) {
      case PrinterDestination.customerReceipt:
        return 'Ticket cliente';
      case PrinterDestination.kitchenTicket:
        return 'Ticket cocina';
      case PrinterDestination.salesReport:
        return 'Reporte de ventas';
    }
  }
}

/// Representa una impresora configurada en el POS.
class PosPrinter {
  final String id;
  String name;
  PrinterDriver driver;
  bool enabled;

  PosPrinter({
    required this.id,
    required this.name,
    this.driver = PrinterDriver.pdf,
    this.enabled = true,
  });

  PosPrinter copyWith({
    String? name,
    PrinterDriver? driver,
    bool? enabled,
  }) {
    return PosPrinter(
      id: id,
      name: name ?? this.name,
      driver: driver ?? this.driver,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// Asignación de qué impresora atiende cada destino.
class PrinterRouting {
  String? customerReceiptPrinterId;
  String? kitchenTicketPrinterId;
  String? salesReportPrinterId;

  PrinterRouting({
    this.customerReceiptPrinterId,
    this.kitchenTicketPrinterId,
    this.salesReportPrinterId,
  });

  String? printerIdFor(PrinterDestination destination) {
    switch (destination) {
      case PrinterDestination.customerReceipt:
        return customerReceiptPrinterId;
      case PrinterDestination.kitchenTicket:
        return kitchenTicketPrinterId;
      case PrinterDestination.salesReport:
        return salesReportPrinterId;
    }
  }

  PrinterRouting copyWith({
    String? customerReceiptPrinterId,
    String? kitchenTicketPrinterId,
    String? salesReportPrinterId,
  }) {
    return PrinterRouting(
      customerReceiptPrinterId: customerReceiptPrinterId ?? this.customerReceiptPrinterId,
      kitchenTicketPrinterId: kitchenTicketPrinterId ?? this.kitchenTicketPrinterId,
      salesReportPrinterId: salesReportPrinterId ?? this.salesReportPrinterId,
    );
  }
}
