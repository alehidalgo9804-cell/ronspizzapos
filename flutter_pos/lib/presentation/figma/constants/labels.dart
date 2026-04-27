class PosLabels {
  static const common = _CommonLabels();
  static const order = _OrderLabels();
  static const table = _TableLabels();
  static const buttons = _ButtonLabels();
  static const empty = _EmptyStateLabels();
  static const payment = _PaymentLabels();
  static const ticket = _TicketLabels();
  static const status = _StatusLabels();
  static const categories = _CategoryLabels();
}

class _CommonLabels {
  const _CommonLabels();

  final String restaurantPos = 'POS del restaurante';
  final String backToTables = 'Volver a mesas';
  final String receipt = 'Recibo';
  final String client = 'Cliente';
  final String toGo = 'Recoger';
  final String delivery = 'Domicilio';
  final String dineIn = 'En mesa';
  final String addGuest = 'Agregar cliente';
  final String guest = 'Cliente';
  final String total = 'Total';
  final String pay = 'Pagar';
  final String sendToKitchen = 'Enviar a cocina';
  final String noItemsInOrder = 'Sin productos en la orden';
  final String table = 'Mesa';
  final String ticket = 'Ticket';
  final String adminUser = 'Administrador';
  final String orderNotFound = 'Orden no encontrada';
  final String floorPlan = 'Plano de mesas';
  final String orders = '\u00d3rdenes';
  final String activeOrders = '\u00d3rdenes activas';
  final String orderHistory = 'Historial de \u00f3rdenes';
  final String newOrderToGo = 'Nueva orden';
}

class _OrderLabels {
  const _OrderLabels();

  final String currentOrder = 'Orden actual';
  final String clientInformation = 'Informaci\u00f3n del cliente';
  final String customerName = 'Nombre del cliente';
  final String enterCustomerName = 'Escribe el nombre del cliente';
  final String phoneNumber = 'Tel\u00e9fono';
  final String enterPhoneNumber = 'Escribe el tel\u00e9fono';
  final String addressRequired = 'Direcci\u00f3n (obligatoria)';
  final String selectAddress = 'Selecciona direcci\u00f3n';
  final String addNewAddress = 'Agregar nueva direcci\u00f3n';
  final String deliveryNotes = 'Detalles del domicilio (opcional)';
  final String deliveryNotesHint = 'Port\u00f3n, color de casa, referencias...';
  final String deliveryShippingCost = 'Costo de env\u00edo';
  final String deliveryShippingCostHint = 'Ej. 35';
  final String deliveryShippingNotInRegister =
      'Paga el cliente al repartidor (no entra en caja)';
  final String addAddress = 'Agregar direcci\u00f3n';
  final String addAddressHint = 'Calle, n\u00famero, colonia...';
  final String deliveryDriver = 'Repartidor';
  final String selectDeliveryDriver = 'Selecciona repartidor';
  final String noCustomerReference = 'Sin cliente';
  final String unassignedDriver = 'Sin repartidor';
  final String allOrderTypes = 'Todas';
  final String orderTypePickup = 'Recoger';
  final String orderTypeDelivery = 'Domicilio';
  final String allDrivers = 'Todos los repartidores';
  final String filterByOrderType = 'Tipo de orden';
  final String filterByDriver = 'Filtrar por repartidor';
  final String deliveryDriverRequired = 'Asigna un repartidor para domicilio.';
  final String backToCategories = 'Volver a categor\u00edas';
  final String backToDrinkGroups = 'Volver a grupos de bebidas';
  final String drinkGroup = 'Grupo';
  final String quickComplements = 'Complementos r\u00e1pidos';
  final String addComment = 'Agregar comentario';
  final String itemComment = 'Comentario del producto';
  final String manualExtra = 'Agregar extra manual';
  final String itemName = 'Nombre del \u00edtem';
  final String requiredName = 'El nombre es obligatorio';
  final String invalidPrice = 'Precio inv\u00e1lido';
  final String quantityOptional = 'Cantidad (opcional)';
  final String minQuantity = 'La cantidad debe ser al menos 1';
  final String orderHelpActive =
      '\u00d3rdenes abiertas, en proceso, ocupadas o pendientes de pago';
  final String orderHelpHistory = '\u00d3rdenes pagadas o completadas';
}

class _TableLabels {
  const _TableLabels();

  final String name = 'Nombre';
  final String qty = 'Cant.';
  final String price = 'Precio';
  final String total = 'Total';
  final String customer = 'Cliente';
  final String date = 'Fecha';
  final String status = 'Estatus';
  final String reason = 'Motivo';
}

class _ButtonLabels {
  const _ButtonLabels();

  final String cancel = 'Cancelar';
  final String save = 'Guardar';
  final String add = 'Agregar';
  final String close = 'Cerrar';
  final String completePayment = 'Completar pago';
  final String closeWithoutPayment = 'Cerrar sin pagar';
  final String confirmClose = 'Confirmar cierre';
  final String reprintTicket = 'Reimprimir ticket';
  final String printing = 'Imprimiendo...';
}

class _EmptyStateLabels {
  const _EmptyStateLabels();

  final String noPendingOrders = 'Sin \u00f3rdenes pendientes';
  final String noCompletedOrders = 'Sin \u00f3rdenes completadas';
}

class _PaymentLabels {
  const _PaymentLabels();

  final String payment = 'Pago';
  final String paymentSummary = 'Resumen de pago';
  final String paymentAtTable = 'Pago - mesa';
  final String orderTotal = 'Total de la orden';
  final String cash = 'Efectivo';
  final String dollar = 'Dólar';
  final String exchangeRate = 'Tipo de cambio';
  final String card = 'Tarjeta';
  final String change = 'Cambio';
  final String remainingAmount = 'Monto pendiente';
  final String printTicket = 'Imprimir ticket';
  final String closeOrderWithoutPayment = 'Cerrar orden sin pago';
  final String currentOrder = 'Orden actual';
  final String reasonOther = 'Otro';
  final String reasonHint = 'Escribe el motivo';
  final List<String> closeReasons = const [
    'Cliente cancel\u00f3',
    'Error de captura',
    'Cliente se fue',
    'Problema en cocina',
    'Orden duplicada',
    'Otro',
  ];
}

class _TicketLabels {
  const _TicketLabels();

  final String customerReceiptSent =
      'Ticket de cliente enviado a impresi\u00f3n.';
  final String customerReceiptFailed = 'Error al imprimir ticket de cliente:';
  final String kitchenTicketSent = 'Comanda enviada a impresi\u00f3n.';
  final String kitchenTicketFailed = 'Error al imprimir comanda:';
  final String reprint = 'REIMPRESI\u00d3N';
  final String type = 'Tipo';
  final String table = 'Mesa';
  final String qtyItemPriceTotal = 'CANT PRODUCTO        PRECIO TOTAL';
  final String orderTotal = 'TOTAL';
  final String orderTotalRegister = 'TOTAL';
  final String cash = 'EFECTIVO';
  final String dollar = 'DÓLAR';
  final String exchangeRate = 'TIPO DE CAMBIO';
  final String card = 'TARJETA';
  final String change = 'CAMBIO';
  final String remaining = 'PENDIENTE';
  final String thankYou = '\u00a1GRACIAS!';
}

class _StatusLabels {
  const _StatusLabels();

  final String available = 'Disponible';
  final String occupied = 'Ocupada';
  final String awaitingPayment = 'Pendiente de pago';
  final String pending = 'Pendiente';
  final String open = 'Abierta';
  final String inProgress = 'En proceso';
  final String closedWithoutPayment = 'Cerrada sin pago';
  final String paid = 'Pagada';
  final String completed = 'Completada';
  final String closed = 'Cerrada';
  final String cancelled = 'Cancelada';
}

class _CategoryLabels {
  const _CategoryLabels();

  final String promotions = 'Promociones';
}
