class WhatsAppOrderLineItem {
  const WhatsAppOrderLineItem({
    required this.quantity,
    required this.name,
    this.modifiers = const [],
  });

  final int quantity;
  final String name;
  final List<String> modifiers;
}

class WhatsAppDeliveryMessagePayload {
  const WhatsAppDeliveryMessagePayload({
    required this.ticket,
    required this.customer,
    required this.phone,
    required this.address,
    required this.items,
    required this.subtotal,
    required this.total,
    this.shippingCost = 0,
    this.reference,
    this.mapsLink,
    this.observations,
  });

  final String ticket;
  final String customer;
  final String phone;
  final String address;
  final String? reference;
  final String? mapsLink;
  final List<WhatsAppOrderLineItem> items;
  final double subtotal;
  final double total;
  final double shippingCost;
  final String? observations;
}

String buildWhatsAppDeliveryMessage(WhatsAppDeliveryMessagePayload payload) {
  final lines = <String>[];

  void addLine(String value) {
    final normalized = value.trim();
    if (normalized.isNotEmpty) {
      lines.add(normalized);
    }
  }

  void addSection(String title, String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) return;
    addLine(title);
    addLine(normalized);
    addLine('');
  }

  addLine('NUEVO PEDIDO A DOMICILIO');
  addLine('');

  addLine('Ticket: #${payload.ticket.trim().isEmpty ? '-' : payload.ticket.trim()}');
  addLine('Cliente: ${payload.customer.trim().isEmpty ? 'Sin nombre' : payload.customer.trim()}');
  if (payload.phone.trim().isNotEmpty) {
    addLine('Teléfono: ${payload.phone.trim()}');
  }
  addLine('');

  addSection('Dirección:', payload.address);
  addSection('Referencia:', payload.reference);
  addSection('Ubicación en Google Maps:', payload.mapsLink);

  addLine('Pedido:');
  if (payload.items.isEmpty) {
    addLine('- Sin productos');
  } else {
    for (final item in payload.items) {
      final itemName = item.name.trim().isEmpty ? 'Producto' : item.name.trim();
      addLine('- ${item.quantity} $itemName');
      for (final modifier in item.modifiers) {
        final normalizedModifier = modifier.trim();
        if (normalizedModifier.isEmpty) continue;
        addLine('  * $normalizedModifier');
      }
    }
  }
  addLine('');

  addLine('Subtotal: \$${payload.subtotal.toStringAsFixed(2)}');
  if (payload.shippingCost > 0) {
    addLine('Envío: \$${payload.shippingCost.toStringAsFixed(2)}');
  }
  addLine('Total: \$${payload.total.toStringAsFixed(2)}');
  addLine('');

  addSection('Observaciones:', payload.observations);

  final sanitized = lines
      .join('\n')
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  return sanitized;
}
