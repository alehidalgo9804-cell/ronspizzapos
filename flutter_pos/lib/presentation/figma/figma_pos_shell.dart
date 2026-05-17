import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/platform/printer_manager.dart';
import '../../core/platform/printer_models.dart';
import '../../core/session/app_session.dart';
import 'constants/labels.dart';
import 'figma_mock_data.dart';
import 'figma_models.dart';
import 'widgets/payment_view.dart';
import 'widgets/pos_pin_login_view.dart';
import 'widgets/pos_printer_preview_dialog.dart';
import 'widgets/pos_window_view.dart';
import 'widgets/table_layout_view.dart';

class FigmaPosShell extends StatefulWidget {
  const FigmaPosShell({super.key});

  @override
  State<FigmaPosShell> createState() => _FigmaPosShellState();
}

class _FigmaPosShellState extends State<FigmaPosShell> {
  PosView _currentView = PosView.tables;
  String? _activeOrderId;
  int _ticketCounter = 1;
  int _orderCounter = 1040;
  List<AppOrder> _orders = const [];
  final List<TableInfo> _baseTables = List<TableInfo>.from(initialTables);
  final AppSession _session = AppSession.instance;
  final Map<String, int> _remoteOrderIds = <String, int>{};
  final Map<String, int> _paymentMethodIdsByKey = <String, int>{};
  final Map<String, int> _driverIdsByLabel = <String, int>{};
  final List<String> _deliveryDriverOptions = <String>[];
  bool _isSyncingPayment = false;
  bool _isAuthenticating = false;
  String? _authError;
  Timer? _draftSyncTimer;
  bool _isLoadingRemoteOrders = false;
  bool _isLoadingBranches = true;
  List<Map<String, dynamic>> _branches = [];

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final response = await _session.apiClient.get('/branches');
      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          setState(() {
            _branches = data.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).toList();
          });
        }
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) {
        setState(() => _isLoadingBranches = false);
      }
    }
  }

  @override
  void dispose() {
    _draftSyncTimer?.cancel();
    super.dispose();
  }

  AppOrder? get _activeOrder {
    if (_activeOrderId == null) return null;
    for (final order in _orders) {
      if (order.id == _activeOrderId) return order;
    }
    return null;
  }

  List<TableInfo> get _tables {
    return _baseTables.map((table) {
      final relatedOrders = _orders
          .where((order) =>
              order.tableNumber == table.number && order.status.isActive)
          .toList(growable: false);

      if (relatedOrders.isEmpty) {
        return table.copyWith(
            status: TableStatus.available, clearOrderTotal: true);
      }

      final currentOrder = relatedOrders.last;
      final total = orderGrandTotal(currentOrder);

      if (currentOrder.status == AppOrderStatus.awaitingPayment) {
        return table.copyWith(
            status: TableStatus.awaitingPayment, orderTotal: total);
      }

      return table.copyWith(status: TableStatus.occupied, orderTotal: total);
    }).toList(growable: false);
  }

  String _displayOrderType(String value) {
    switch (value) {
      case 'To Go':
        return PosLabels.common.toGo;
      case 'Delivery':
        return PosLabels.common.delivery;
      case 'Dine In':
        return PosLabels.common.dineIn;
      default:
        return value;
    }
  }

  AppOrder _createOrder({required String? tableNumber}) {
    final isToGo = tableNumber == null || tableNumber == 'to-go';
    final ticket = '#${_ticketCounter.toString().padLeft(5, '0')}';
    _ticketCounter += 1;
    _orderCounter += 1;
    final orderNumber = isToGo ? 'A-$_orderCounter' : 'T-$_orderCounter';

    return AppOrder(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      orderNumber: orderNumber,
      ticketNumber: ticket,
      orderType: isToGo ? 'To Go' : 'Dine In',
      customerOrTable: isToGo
          ? PosLabels.common.toGo
          : '${PosLabels.common.table} $tableNumber',
      createdAt: DateTime.now(),
      status: AppOrderStatus.pending,
      guests: [GuestData(id: 1, name: '${PosLabels.common.guest} 1')],
      currentGuestId: 1,
      items: const [],
      cashierName: _session.userName,
      tableNumber: isToGo ? null : tableNumber,
    );
  }

  void _upsertOrder(AppOrder order) {
    final index = _orders.indexWhere((existing) => existing.id == order.id);
    if (index < 0) {
      _orders = [..._orders, order];
    } else {
      final updated = List<AppOrder>.from(_orders);
      updated[index] = order;
      _orders = updated;
    }
  }

  void _openOrCreateOrderFromTable(String tableNumber) {
    final normalizedTable = tableNumber == 'to-go' ? null : tableNumber;
    final existing = _orders.where((order) {
      if (normalizedTable == null) return false;
      return order.tableNumber == normalizedTable && order.status.isActive;
    }).toList(growable: false);

    setState(() {
      if (existing.isNotEmpty) {
        _activeOrderId = existing.last.id;
      } else {
        final created = _createOrder(tableNumber: normalizedTable);
        _upsertOrder(created);
        _activeOrderId = created.id;
      }
      _currentView = PosView.pos;
    });
  }

  void _openOrderById(String orderId) {
    setState(() {
      _activeOrderId = orderId;
      _currentView = PosView.pos;
    });
  }

  void _handleBackToTables() {
    setState(() {
      _currentView = PosView.tables;
      _activeOrderId = null;
    });
  }

  void _handleLogout() {
    _draftSyncTimer?.cancel();
    setState(() {
      _session.clear();
      _authError = null;
      _isAuthenticating = false;
      _isLoadingRemoteOrders = false;
      _isSyncingPayment = false;
      _currentView = PosView.tables;
      _activeOrderId = null;
    });
  }

  void _handleOrderChanged(AppOrder order) {
    setState(() {
      _upsertOrder(order);
    });

    _queueDraftSync(order);
  }

  void _queueDraftSync(AppOrder order) {
    if (!_session.isAuthenticated) return;
    if (order.items.isEmpty) return;
    if (order.status.isTerminal) return;

    _draftSyncTimer?.cancel();
    _draftSyncTimer = Timer(const Duration(milliseconds: 700), () async {
      try {
        await _ensureRemoteOrder(order);
      } catch (_) {
        // No mostramos snackbar aquí para no molestar al usuario en cada tecla/cambio.
      }
    });
  }

  Future<void> _loadOrdersFromBackend() async {
    if (!_session.isAuthenticated || _isLoadingRemoteOrders) return;

    setState(() => _isLoadingRemoteOrders = true);

    try {
      final response =
          await _session.apiClient.get('/orders?limit=250&include_details=1');

      if (response['success'] != true) {
        throw Exception(
            response['message'] ?? 'No se pudieron cargar las órdenes');
      }

      final rows = (response['data'] as List? ?? const []);
      final loadedOrders = <AppOrder>[];
      final remoteIds = <String, int>{};

      int maxTicket = _ticketCounter;
      int maxOrder = _orderCounter;

      for (final row in rows) {
        final map = (row as Map?)?.cast<String, dynamic>();
        if (map == null) continue;

        final order = _mapApiOrder(map);
        loadedOrders.add(order);
        remoteIds[order.id] = _toInt(map['id']);

        final ticketDigits = RegExp(r'(\d+)').firstMatch(order.ticketNumber);
        if (ticketDigits != null) {
          final parsed = int.tryParse(ticketDigits.group(1)!);
          if (parsed != null && parsed >= maxTicket) {
            maxTicket = parsed + 1;
          }
        }

        final orderDigits = RegExp(r'(\d+)').firstMatch(order.orderNumber);
        if (orderDigits != null) {
          final parsed = int.tryParse(orderDigits.group(1)!);
          if (parsed != null && parsed >= maxOrder) {
            maxOrder = parsed + 1;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _orders = loadedOrders;
        _remoteOrderIds
          ..clear()
          ..addAll(remoteIds);
        _ticketCounter = maxTicket;
        _orderCounter = maxOrder;
        _isLoadingRemoteOrders = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingRemoteOrders = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar historial/órdenes: $error')),
      );
    }
  }

  AppOrder _mapApiOrder(Map<String, dynamic> data) {
    final payloadSummary =
        (data['payload_resumen_json'] as Map?)?.cast<String, dynamic>() ??
            _decodeJsonMap(data['payload_resumen_json']);

    final remoteId = _toInt(data['id']);
    final createdAt = _parseDate(data['fecha_pedido']) ??
        _parseDate(data['created_at']) ??
        DateTime.now();
    final completedAt =
        _parseDate(data['fecha_cierre']) ?? _parseDate(data['updated_at']);

    final orderType = _mapApiOrderType('${data['tipo_pedido'] ?? ''}');
    final status = _mapApiStatus(
      estado: '${data['estado'] ?? ''}',
      estadoPago: '${data['estado_pago'] ?? ''}',
    );

    final customerName = '${data['cliente_nombre_completo'] ?? ''}'.trim();
    final customerPhone = '${data['cliente_telefono'] ?? ''}'.trim();
    final driverName = '${data['repartidor_nombre_completo'] ?? ''}'.trim();
    final cashierName = '${data['cajero_nombre_completo'] ?? ''}'.trim();

    final mesaLabel = '${payloadSummary['mesa_label'] ?? ''}'.trim();
    final apiFolio = '${data['folio'] ?? ''}'.trim();
    final fallbackTicket = '#${remoteId.toString().padLeft(5, '0')}';
    final ticketNumber =
        _isSimpleTicketFolio(apiFolio) ? apiFolio : fallbackTicket;
    final orderNumber = ticketNumber;

    final addressText = _buildAddressText(data);
    final items = (data['items'] as List? ?? const [])
        .map((item) => _mapApiOrderItem((item as Map).cast<String, dynamic>()))
        .toList(growable: false);

    return AppOrder(
      id: 'remote-$remoteId',
      orderNumber: orderNumber.isEmpty ? 'ORD-$remoteId' : orderNumber,
      ticketNumber: ticketNumber,
      orderType: orderType,
      customerOrTable: mesaLabel.isNotEmpty
          ? '${PosLabels.common.table} $mesaLabel'
          : (customerName.isNotEmpty
              ? customerName
              : (orderType == 'Delivery'
                  ? PosLabels.common.delivery
                  : orderType == 'To Go'
                      ? PosLabels.common.toGo
                      : PosLabels.common.dineIn)),
      createdAt: createdAt,
      status: status,
      guests: const [GuestData(id: 1, name: 'Invitado 1')],
      currentGuestId: 1,
      items: items,
      customerName: customerName.isEmpty ? null : customerName,
      customerPhone: customerPhone.isEmpty ? null : customerPhone,
      customerId:
          _toInt(data['cliente_id']) > 0 ? _toInt(data['cliente_id']) : null,
      customerAddressId: _toInt(data['direccion_cliente_id']) > 0
          ? _toInt(data['direccion_cliente_id'])
          : null,
      deliveryAddress: addressText.isEmpty ? null : addressText,
      deliveryAddressReference: _stringOrNull(data['direccion_referencia']),
      deliveryAddressDetails:
          _stringOrNull(data['direccion_instrucciones_entrega']),
      deliveryAddressPlaceId: _stringOrNull(data['direccion_place_id']),
      deliveryAddressLatitude: _toNullableDouble(data['direccion_lat']),
      deliveryAddressLongitude: _toNullableDouble(data['direccion_lng']),
      deliveryNotes: _stringOrNull(data['observaciones']),
      deliveryDriver: driverName.isEmpty ? null : driverName,
      cashierName: cashierName.isEmpty ? null : cashierName,
      paymentPaidAmount: _toNullableDouble(data['total_pagado']),
      paymentBalance: _toNullableDouble(data['total_pendiente']),
      closeReason: _stringOrNull(data['cierre_sin_pago_motivo']),
      completedAt: completedAt,
      tableNumber: mesaLabel.isEmpty ? null : mesaLabel,
      deliveryShippingCost: _toDouble(data['envio_total']),
    );
  }

  OrderItemData _mapApiOrderItem(Map<String, dynamic> data) {
    final qty = _toInt(data['cantidad'], fallback: 1);
    final category =
        '${data['categoria_snapshot'] ?? data['categoria_manual'] ?? 'manual'}';

    return OrderItemData(
      id: 'remote-item-${data['id']}',
      name: '${data['nombre_snapshot'] ?? data['nombre_manual'] ?? 'Producto'}',
      price: _toDouble(data['precio_unitario']),
      categoryId: category,
      quantity: qty <= 0 ? 1 : qty,
      guestId: 1,
      comment: _stringOrNull(data['notas']),
    );
  }

  Map<String, dynamic> _decodeJsonMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is! String || value.trim().isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final text = '$value'.trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    final parsed = _toDouble(value, fallback: double.nan);
    return parsed.isNaN ? null : parsed;
  }

  String? _stringOrNull(dynamic value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }

  String _mapApiOrderType(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'delivery' || normalized == 'domicilio') {
      return 'Delivery';
    }
    if (normalized == 'mesa') return 'Dine In';
    return 'To Go';
  }

  AppOrderStatus _mapApiStatus({
    required String estado,
    required String estadoPago,
  }) {
    final orderStatus = estado.trim().toLowerCase();
    final paymentStatus = estadoPago.trim().toLowerCase();

    if (orderStatus == 'closed_without_payment') {
      return AppOrderStatus.closedWithoutPayment;
    }

    if (paymentStatus == 'paid' || orderStatus == 'paid') {
      return AppOrderStatus.paid;
    }

    if (orderStatus == 'completed' ||
        orderStatus == 'closed' ||
        orderStatus == 'cerrado') {
      return AppOrderStatus.completed;
    }

    if (orderStatus == 'cancelled' || orderStatus == 'cancelado') {
      return AppOrderStatus.cancelled;
    }

    if (paymentStatus == 'partial') {
      return AppOrderStatus.awaitingPayment;
    }

    return AppOrderStatus.pending;
  }

  String _buildAddressText(Map<String, dynamic> data) {
    final parts = <String>[
      '${data['direccion_calle'] ?? ''}'.trim(),
      '${data['direccion_numero_exterior'] ?? ''}'.trim(),
      '${data['direccion_numero_interior'] ?? ''}'.trim(),
      '${data['direccion_colonia'] ?? ''}'.trim(),
    ].where((part) => part.isNotEmpty).toList(growable: false);

    return parts.join(', ');
  }

  void _handleProceedToPayment(AppOrder order) {
    setState(() {
      _upsertOrder(order.copyWith(status: AppOrderStatus.awaitingPayment));
      _activeOrderId = order.id;
      _currentView = PosView.payment;
    });
  }

  Future<void> _handlePaymentComplete(PaymentData paymentData) async {
    final active = _activeOrder;
    if (active == null) return;
    if (_isSyncingPayment) return;

    setState(() => _isSyncingPayment = true);
    try {
      await _syncCompletedOrderToBackend(
          order: active, paymentData: paymentData);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('No se pudo guardar la venta en reportes: $error')),
      );
      setState(() => _isSyncingPayment = false);
      return;
    }

    final completedOrder = active.copyWith(
      status: AppOrderStatus.paid,
      paymentCashAmount: paymentData.cashAmount,
      paymentUsdAmount: paymentData.usdAmount,
      paymentUsdExchangeRate: paymentData.usdExchangeRateUsed,
      paymentCardAmount: paymentData.cardAmount,
      paymentPaidAmount: paymentData.paidAmount,
      paymentBalance: paymentData.balance,
      completedAt: DateTime.now(),
    );
    final receiptText =
        _buildCustomerReceiptText(order: completedOrder, isReprint: false);

    setState(() {
      _upsertOrder(completedOrder);
      _currentView = PosView.tables;
      _activeOrderId = null;
      _isSyncingPayment = false;
    });

    if (paymentData.printTicket) {
      await _printCustomerReceipt(receiptText);
    }
  }

  void _handlePaymentCancel() {
    final active = _activeOrder;
    if (active == null) return;
    setState(() {
      _currentView = PosView.pos;
    });
  }

  Future<void> _handleCloseWithoutPayment(String reason) async {
    final active = _activeOrder;
    if (active == null) return;
    try {
      final remoteOrderId = await _ensureRemoteOrder(active);
      await _ensureAuthenticated();
      final updateStatus = await _session.apiClient.put(
        '/orders/$remoteOrderId/status',
        <String, dynamic>{
          'estado': 'closed_without_payment',
          'observaciones': reason,
        },
      );
      if (updateStatus['success'] != true) {
        throw Exception(
            updateStatus['message'] ?? 'Error cerrando orden sin pago');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar cierre sin pago: $error')),
      );
      return;
    }

    setState(() {
      _upsertOrder(
        active.copyWith(
          status: AppOrderStatus.closedWithoutPayment,
          closeReason: reason,
          completedAt: DateTime.now(),
        ),
      );
      _currentView = PosView.tables;
      _activeOrderId = null;
    });
  }

  Future<void> _ensureAuthenticated() async {
    if (_session.isAuthenticated) {
      await _loadPaymentMethods();
      await _loadDeliveryDrivers();
      return;
    }

    throw Exception('Sesion no autenticada. Inicia sesion con PIN de caja.');
  }

  Future<void> _authenticateWithPin(String pin, int branchId) async {
    final response =
        await _session.apiClient.post('/auth/login', <String, dynamic>{
      'pin': pin,
      'sucursal_id': branchId,
      'plataforma': 'pos_flutter',
    });

    if (response['success'] != true) {
      throw Exception(
          response['message'] ?? 'PIN incorrecto o usuario inactivo');
    }

    final data = (response['data'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final token = '${data['token'] ?? ''}';
    final user =
        (data['user'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final responseBranchId = _toInt(user['sucursal_id'], fallback: branchId);
    final userId = _toInt(user['id'], fallback: 1);
    final nombre = '${user['nombre'] ?? ''}'.trim();
    final apellido = '${user['apellido'] ?? ''}'.trim();
    final role = '${user['rol'] ?? ''}'.trim();

    if (token.isEmpty) {
      throw Exception('Respuesta de autenticación inválida');
    }

    _session.setAuth(
      token: token,
      branchId: responseBranchId,
      userId: userId,
      userName: '$nombre $apellido'.trim(),
      role: role.isEmpty ? 'cajero' : role,
    );

    await _loadPaymentMethods();
    await _loadDeliveryDrivers();
    await _loadOrdersFromBackend();
  }

  Future<void> _handleLoginWithPin(String pin, int branchId) async {
    if (_isAuthenticating) return;
    setState(() {
      _authError = null;
      _isAuthenticating = true;
    });
    try {
      await _authenticateWithPin(pin, branchId);
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _authError = '$error';
      });
    }
  }

  Future<void> _loadPaymentMethods() async {
    if (_paymentMethodIdsByKey.isNotEmpty) return;
    final methodsResponse = await _session.apiClient.get('/payments/methods');
    if (methodsResponse['success'] != true) {
      throw Exception(methodsResponse['message'] ??
          'No se pudieron cargar métodos de pago');
    }

    final methods = (methodsResponse['data'] as List? ?? const []);
    for (final row in methods) {
      final map = (row as Map?)?.cast<String, dynamic>();
      if (map == null) continue;
      final key = '${map['clave'] ?? ''}'.trim().toLowerCase();
      if (key.isEmpty) continue;
      _paymentMethodIdsByKey[key] = _toInt(map['id']);
    }
  }

  Future<void> _loadDeliveryDrivers() async {
    if (!_session.isAuthenticated) return;
    final response = await _session.apiClient.get('/drivers?limit=200');
    if (response['success'] != true) return;

    final rows = (response['data'] as List? ?? const []);
    final labels = <String>[];
    final byLabel = <String, int>{};

    for (final row in rows) {
      final map = (row as Map?)?.cast<String, dynamic>();
      if (map == null) continue;
      final isActive = _toInt(map['activo'], fallback: 1) == 1;
      if (!isActive) continue;

      final id = _toInt(map['id']);
      if (id <= 0) continue;

      final firstName = '${map['nombre'] ?? ''}'.trim();
      final lastName = '${map['apellidos'] ?? map['apellido'] ?? ''}'.trim();
      final label = '$firstName $lastName'.trim().isEmpty
          ? 'Repartidor $id'
          : '$firstName $lastName'.trim();

      if (!labels.contains(label)) {
        labels.add(label);
      }
      byLabel[label] = id;
    }

    labels.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (!mounted) return;
    setState(() {
      _deliveryDriverOptions
        ..clear()
        ..addAll(labels);
      _driverIdsByLabel
        ..clear()
        ..addAll(byLabel);
    });
  }

  Future<void> _handleAssignDeliveryDriver(
      String orderId, String? driver) async {
    final normalized = (driver ?? '').trim();
    final nextDriver = normalized.isEmpty ? null : normalized;
    final targetIndex = _orders.indexWhere((order) => order.id == orderId);
    if (targetIndex < 0) return;
    final targetOrder = _orders[targetIndex];
    final previousDriver = targetOrder.deliveryDriver;
    if (previousDriver == nextDriver) return;

    final updatedOrder = targetOrder.copyWith(deliveryDriver: nextDriver);
    setState(() {
      _upsertOrder(updatedOrder);
    });

    try {
      await _ensureAuthenticated();
      final remoteOrderId = await _ensureRemoteOrder(updatedOrder);
      final driverId = _extractDriverId(nextDriver);
      final response = await _session.apiClient.put(
        '/orders/$remoteOrderId/driver',
        <String, dynamic>{
          'repartidor_id': driverId > 0 ? driverId : null,
        },
      );

      if (response['success'] != true) {
        throw Exception(
          response['message'] ?? 'No se pudo asignar repartidor',
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _upsertOrder(targetOrder.copyWith(deliveryDriver: previousDriver));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar repartidor: $error')),
      );
    }
  }

  Future<void> _syncCompletedOrderToBackend({
    required AppOrder order,
    required PaymentData paymentData,
  }) async {
    final remoteOrderId = await _ensureRemoteOrder(order);
    await _registerPayments(
        remoteOrderId: remoteOrderId, paymentData: paymentData);
  }

  Future<int> _ensureRemoteOrder(AppOrder order) async {
    await _ensureAuthenticated();

    if (order.items.isEmpty) {
      throw Exception('La orden no tiene productos');
    }

    final customerRef = await _resolveCustomerForOrder(order);

    final pricing = calculateOrderPricing(order.items);
    final promoDiscount =
        pricing.promoAdjustment < 0 ? pricing.promoAdjustment.abs() : 0.0;

    final payload = <String, dynamic>{
      'tipo_pedido': _mapOrderTypeForApi(order),
      'canal_origen': 'pos_flutter',
      'observaciones':
          order.deliveryNotes ?? 'POS ticket ${order.ticketNumber}',
      'promociones_total': promoDiscount,
      'items': order.items.map(_mapOrderItemToApi).toList(growable: false),
      'ticket_number': order.ticketNumber,
      'customer_or_table': order.customerOrTable,
      if (order.tableNumber != null) 'mesa_label': order.tableNumber,
      if (customerRef.customerId > 0) 'cliente_id': customerRef.customerId,
      if (customerRef.addressId > 0)
        'direccion_cliente_id': customerRef.addressId,
      if (order.orderType == 'Delivery' &&
          _extractDriverId(order.deliveryDriver) > 0)
        'repartidor_id': _extractDriverId(order.deliveryDriver),
      if (order.orderType == 'Delivery')
        'envio_total':
            order.deliveryShippingCost < 0 ? 0 : order.deliveryShippingCost,
    };

    final existingRemoteId = _remoteOrderIds[order.id];
    final response = existingRemoteId == null
        ? await _session.apiClient.post('/orders', payload)
        : await _session.apiClient.put('/orders/$existingRemoteId', payload);

    if (response['success'] != true) {
      throw Exception(
        response['message'] ??
            (existingRemoteId == null
                ? 'No se pudo crear pedido en backend'
                : 'No se pudo actualizar pedido en backend'),
      );
    }

    final data = (response['data'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final remoteOrderId = _toInt(data['id']);
    if (remoteOrderId <= 0) {
      throw Exception('Backend no devolvió ID de pedido');
    }

    _remoteOrderIds[order.id] = remoteOrderId;

    final syncedFolio = '${data['folio'] ?? ''}'.trim();
    final nextTicket = syncedFolio.isNotEmpty
        ? syncedFolio
        : '#${remoteOrderId.toString().padLeft(5, '0')}';
    final orderIndex =
        _orders.indexWhere((existing) => existing.id == order.id);
    if (orderIndex >= 0) {
      final local = _orders[orderIndex];
      if (local.ticketNumber != nextTicket || local.orderNumber != nextTicket) {
        if (mounted) {
          setState(() {
            _upsertOrder(
              local.copyWith(
                ticketNumber: nextTicket,
                orderNumber: nextTicket,
              ),
            );
          });
        } else {
          _upsertOrder(
            local.copyWith(
              ticketNumber: nextTicket,
              orderNumber: nextTicket,
            ),
          );
        }
      }
    }

    return remoteOrderId;
  }

  Future<_CustomerOrderRef> _resolveCustomerForOrder(AppOrder order) async {
    final isDelivery = order.orderType == 'Delivery';
    final hasCustomerData = (order.customerName?.trim().isNotEmpty ?? false) ||
        (order.customerPhone?.trim().isNotEmpty ?? false) ||
        (isDelivery && (order.deliveryAddress?.trim().isNotEmpty ?? false));
    if (!hasCustomerData &&
        (order.customerId ?? 0) <= 0 &&
        (order.customerAddressId ?? 0) <= 0) {
      return const _CustomerOrderRef(customerId: 0, addressId: 0);
    }

    final payload = <String, dynamic>{
      if ((order.customerId ?? 0) > 0) 'customer_id': order.customerId,
      if ((order.customerName ?? '').trim().isNotEmpty)
        'nombre': order.customerName!.trim(),
      if ((order.customerPhone ?? '').trim().isNotEmpty)
        'telefono': order.customerPhone!.trim(),
      if (isDelivery && (order.deliveryAddress ?? '').trim().isNotEmpty)
        'direccion_texto': order.deliveryAddress!.trim(),
      if (isDelivery &&
          (order.deliveryAddressReference ?? '').trim().isNotEmpty)
        'direccion_referencia': order.deliveryAddressReference!.trim(),
      if (isDelivery && (order.deliveryAddressDetails ?? '').trim().isNotEmpty)
        'direccion_instrucciones': order.deliveryAddressDetails!.trim(),
      if (isDelivery && (order.deliveryAddressPlaceId ?? '').trim().isNotEmpty)
        'direccion_place_id': order.deliveryAddressPlaceId!.trim(),
      if (isDelivery && order.deliveryAddressLatitude != null)
        'direccion_lat': order.deliveryAddressLatitude,
      if (isDelivery && order.deliveryAddressLongitude != null)
        'direccion_lng': order.deliveryAddressLongitude,
      if (isDelivery && (order.deliveryNotes ?? '').trim().isNotEmpty)
        'referencia': order.deliveryNotes!.trim(),
      if (isDelivery && (order.customerAddressId ?? 0) > 0)
        'direccion_cliente_id': order.customerAddressId,
    };

    if (payload.isEmpty) {
      return _CustomerOrderRef(
        customerId: order.customerId ?? 0,
        addressId: order.customerAddressId ?? 0,
      );
    }

    final response =
        await _session.apiClient.post('/customers/upsert-pos', payload);
    if (response['success'] != true) {
      throw Exception(
        response['message'] ?? 'No se pudo sincronizar cliente de la orden',
      );
    }

    final data = (response['data'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    return _CustomerOrderRef(
      customerId: _toInt(data['id']),
      addressId: isDelivery
          ? _toInt(
              data['direccion_cliente_id'],
              fallback: order.customerAddressId ?? 0,
            )
          : 0,
    );
  }

  int _extractDriverId(String? driverLabel) {
    final value = (driverLabel ?? '').trim();
    if (value.isEmpty) return 0;
    final mappedId = _driverIdsByLabel[value];
    if (mappedId != null) return mappedId;
    final match = RegExp(r'(\d+)$').firstMatch(value);
    if (match == null) return 0;
    return int.tryParse(match.group(1) ?? '') ?? 0;
  }

  Future<void> _registerPayments({
    required int remoteOrderId,
    required PaymentData paymentData,
  }) async {
    final cashMethod = _paymentMethodIdsByKey['efectivo'] ?? 1;
    final cardMethod = _paymentMethodIdsByKey['tarjeta'] ?? 2;
    final usdMethod = _paymentMethodIdsByKey['usd'] ?? 4;

    Future<void> postPayment(Map<String, dynamic> payload) async {
      final response = await _session.apiClient.post('/payments', payload);
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'No se pudo registrar pago');
      }
    }

    if (paymentData.cashAmount > 0) {
      await postPayment(<String, dynamic>{
        'pedido_id': remoteOrderId,
        'metodo_pago_id': cashMethod,
        'monto': paymentData.cashAmount,
        'moneda': 'MXN',
        'estado': 'aplicado',
      });
    }

    if (paymentData.usdAmount > 0) {
      await postPayment(<String, dynamic>{
        'pedido_id': remoteOrderId,
        'metodo_pago_id': usdMethod,
        'monto': paymentData.usdAmount,
        'moneda': 'USD',
        'tipo_cambio': paymentData.usdExchangeRateUsed,
        'estado': 'aplicado',
      });
    }

    if (paymentData.cardAmount > 0) {
      await postPayment(<String, dynamic>{
        'pedido_id': remoteOrderId,
        'metodo_pago_id': cardMethod,
        'monto': paymentData.cardAmount,
        'moneda': 'MXN',
        'estado': 'aplicado',
      });
    }
  }

  String _mapOrderTypeForApi(AppOrder order) {
    if (order.tableNumber != null) return 'mesa';
    if (order.orderType == 'Delivery') return 'delivery';
    return 'recoger';
  }

  Map<String, dynamic> _mapOrderItemToApi(OrderItemData item) {
    return <String, dynamic>{
      'es_item_manual': 1,
      'nombre_manual': item.name,
      'categoria_manual': item.categoryId,
      'precio_manual_unitario': item.price,
      'nombre_snapshot': item.name,
      'categoria_snapshot': item.categoryId,
      'cantidad': item.quantity,
      'precio_unitario': item.price,
      'notas': item.comment,
      'config_builder_tipo': _builderTypeForItem(item),
      'config_builder_json': _builderConfigToMap(item),
      'display_lines_json': <String>[
        if (item.comment != null && item.comment!.trim().isNotEmpty)
          item.comment!.trim(),
      ],
    };
  }

  String? _builderTypeForItem(OrderItemData item) {
    if (item.pizzaConfig != null) return 'pizza_builder';
    if (item.hamburgerConfig != null) return 'hamburger_builder';
    if (item.wingsConfig != null) return 'wings_builder';
    if (item.spaghettiConfig != null) return 'spaghetti_builder';
    if (item.saladConfig != null) return 'salad_builder';
    if (item.garlicBreadConfig != null) return 'garlic_bread_builder';
    return null;
  }

  Map<String, dynamic>? _builderConfigToMap(OrderItemData item) {
    if (item.pizzaConfig != null) {
      final c = item.pizzaConfig!;
      return <String, dynamic>{
        'specialty': c.specialty,
        'size': c.size,
        'crustEdge': c.crustEdge,
        'breadType': c.breadType,
        'dorada': c.dorada,
        'ingredients': c.ingredients,
        'extraIngredients': c.extraIngredients,
        'selectionMode': c.selectionMode.name,
        'half1': c.half1,
        'half2': c.half2,
        'half1Mode': c.half1Mode?.name,
        'half2Mode': c.half2Mode?.name,
        'half1Specialty': c.half1Specialty,
        'half2Specialty': c.half2Specialty,
        'half1Ingredients': c.half1Ingredients,
        'half2Ingredients': c.half2Ingredients,
        'crustHalf1': c.crustHalf1,
        'crustHalf2': c.crustHalf2,
        'includePromoGarlicBread': c.includePromoGarlicBread,
      };
    }
    if (item.hamburgerConfig != null) {
      final c = item.hamburgerConfig!;
      return <String, dynamic>{
        'burgerType': c.burgerType,
        'side': c.side.name,
        'removedIngredients': c.removedIngredients,
        'extraIngredients': c.extraIngredients,
        'usedSinVerduraQuickAction': c.usedSinVerduraQuickAction,
        'cutOption': c.cutOption.name,
        'isSpecialCombo': c.isSpecialCombo,
      };
    }
    if (item.wingsConfig != null) {
      final c = item.wingsConfig!;
      return <String, dynamic>{
        'size': c.size.name,
        'sauceMode': c.sauceMode.name,
        'sauce': c.sauce,
        'sauceHalf1': c.sauceHalf1,
        'sauceHalf2': c.sauceHalf2,
        'naturales': c.naturales,
        'sauceOnSide': c.sauceOnSide,
        'juicy': c.juicy,
        'doradas': c.doradas,
        'boneType': c.boneType?.name,
        'sinApio': c.sinApio,
        'sinZanahoria': c.sinZanahoria,
      };
    }
    if (item.spaghettiConfig != null) {
      final c = item.spaghettiConfig!;
      return <String, dynamic>{
        'spaghettiType': c.spaghettiType,
        'accompaniment': c.accompaniment,
        'garlicBreadType': c.garlicBreadType,
        'removedIngredients': c.removedIngredients,
        'sinQueso': c.sinQueso,
        'sinMantequilla': c.sinMantequilla,
        'pocaSalsa': c.pocaSalsa,
        'quesoDorado': c.quesoDorado,
        'extras': c.extras,
      };
    }
    if (item.saladConfig != null) {
      final c = item.saladConfig!;
      return <String, dynamic>{
        'removedIngredients': c.removedIngredients,
        'addOns': c.addOns,
      };
    }
    if (item.garlicBreadConfig != null) {
      return <String, dynamic>{'type': item.garlicBreadConfig!.type};
    }
    return null;
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  bool _isSimpleTicketFolio(String value) {
    return RegExp(r'^#\d{5,}$').hasMatch(value.trim());
  }

  Future<void> _printCustomerReceipt(String receiptText) async {
    try {
      final printer = PrinterManager.instance.resolvePrinter(PrinterDestination.customerReceipt);
      if (printer != null && printer.driver == PrinterDriver.pdf) {
        if (!mounted) return;
        await showPrinterPreviewDialog(
          context,
          title: 'Ticket cliente',
          ticketText: receiptText,
        );
        return;
      }
      await PrinterManager.instance.printTicket(
        destination: PrinterDestination.customerReceipt,
        text: receiptText,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(PosLabels.ticket.customerReceiptSent)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${PosLabels.ticket.customerReceiptFailed} $error')),
      );
    }
  }

  Future<void> _handleReprintCompletedOrder(AppOrder order) async {
    final receiptText =
        _buildCustomerReceiptText(order: order, isReprint: true);
    await _printCustomerReceipt(receiptText);
  }

  String _buildCustomerReceiptText({
    required AppOrder order,
    required bool isReprint,
  }) {
    const lineWidth = 42;
    const itemNameWidth = 19;
    const qtyWidth = 4;
    const moneyWidth = 8;

    String spaces(int count) => count <= 0 ? '' : ' ' * count;
    String divider() => '-' * lineWidth;
    String center(String text) {
      if (text.length >= lineWidth) return text;
      final left = ((lineWidth - text.length) / 2).floor();
      return '${spaces(left)}$text';
    }

    String normalize(String value) =>
        value.replaceAll(RegExp(r'\s+'), ' ').trim();

    String twoDigits(int value) => value.toString().padLeft(2, '0');
    String formatDateTime(DateTime value) {
      final local = value.toLocal();
      return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
          '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
    }

    String money(double value) => '\$${value.toStringAsFixed(2)}';

    List<String> wrapText(String text, int width) {
      final source = normalize(text);
      if (source.isEmpty) return const [''];
      final words = source.split(' ');
      final lines = <String>[];
      var current = '';
      for (final rawWord in words) {
        var word = rawWord;
        if (word.length > width) {
          if (current.isNotEmpty) {
            lines.add(current);
            current = '';
          }
          while (word.length > width) {
            lines.add(word.substring(0, width));
            word = word.substring(width);
          }
          if (word.isEmpty) {
            continue;
          }
        }
        final candidate = current.isEmpty ? word : '$current $word';
        if (candidate.length <= width) {
          current = candidate;
        } else {
          if (current.isNotEmpty) {
            lines.add(current);
          }
          current = word;
        }
      }
      if (current.isNotEmpty) {
        lines.add(current);
      }
      return lines;
    }

    String padOrTrim(String value, int width, {bool left = false}) {
      final clean = normalize(value);
      if (clean.length == width) return clean;
      if (clean.length > width) return clean.substring(0, width);
      return left ? clean.padLeft(width) : clean.padRight(width);
    }

    void writeKeyValue(
      StringBuffer out,
      String key,
      String value, {
      bool wrapValue = false,
    }) {
      final cleanValue = normalize(value);
      if (cleanValue.isEmpty) return;
      final prefix = '$key: ';
      if (!wrapValue || prefix.length + cleanValue.length <= lineWidth) {
        out.writeln('$prefix$cleanValue');
        return;
      }
      out.writeln(prefix);
      final lines = wrapText(cleanValue, lineWidth);
      for (final line in lines) {
        out.writeln(line);
      }
    }

    List<String> itemModifierLines(OrderItemData item) {
      final lines = <String>[];

      final pizza = item.pizzaConfig;
      if (pizza != null) {
        if (pizza.selectionMode == PizzaSelectionMode.halfHalf) {
          final half1 = normalize(pizza.half1Specialty ?? pizza.half1 ?? '');
          final half2 = normalize(pizza.half2Specialty ?? pizza.half2 ?? '');
          if (half1.isNotEmpty || half2.isNotEmpty) {
            lines.add('1/2 $half1 - 1/2 $half2'.trim());
          }
        }
        if (pizza.crustEdge == 'Half & Half Crust' &&
            pizza.crustHalf1 != null &&
            pizza.crustHalf2 != null) {
          lines.add('ORILLA 1/2 ${pizza.crustHalf1} - 1/2 ${pizza.crustHalf2}');
        } else if (pizza.crustEdge != 'Regular') {
          lines.add('ORILLA ${pizza.crustEdge}');
        }
        if (pizza.breadType != 'Regular') {
          lines.add('PAN ${pizza.breadType}');
        }
        if (pizza.dorada) {
          lines.add('DORADA');
        }
        for (final extra in pizza.extraIngredients) {
          lines.add('EXTRA $extra');
        }
        if (pizza.includePromoGarlicBread) {
          lines.add('PANES DE AJO PROMO');
        }
      }

      final wings = item.wingsConfig;
      if (wings != null) {
        if (wings.naturales) {
          lines.add('NATURALES');
        } else if (wings.sauceMode == WingsSauceMode.mitadMitad) {
          final half1 = normalize(wings.sauceHalf1 ?? '');
          final half2 = normalize(wings.sauceHalf2 ?? '');
          if (half1.isNotEmpty || half2.isNotEmpty) {
            lines.add('1/2 $half1 - 1/2 $half2');
          }
        } else if ((wings.sauce ?? '').trim().isNotEmpty) {
          lines.add(
              wings.sauceOnSide ? '${wings.sauce} APARTE' : '${wings.sauce}');
        }
        if (wings.boneType == WingsBoneType.unHueso) lines.add('1 HUESO');
        if (wings.boneType == WingsBoneType.dosHuesos) lines.add('2 HUESOS');
      }

      final comment = normalize(item.comment ?? '');
      if (comment.isNotEmpty) {
        lines.add(comment);
      }

      return lines;
    }

    final now = (order.completedAt ?? DateTime.now()).toLocal();
    final buffer = StringBuffer();
    buffer.writeln(center('Rons Pizza'));
    if (isReprint) {
      buffer.writeln(center('*** ${PosLabels.ticket.reprint} ***'));
    }
    buffer.writeln(divider());
    writeKeyValue(buffer, PosLabels.common.ticket,
        order.ticketNumber.replaceAll('#', ''));
    writeKeyValue(buffer, 'Cajero',
        (order.cashierName ?? _session.userName ?? 'Sin cajero'));
    writeKeyValue(buffer, 'Hora', formatDateTime(now));
    writeKeyValue(buffer, 'Tipo', _displayOrderType(order.orderType));
    if (order.tableNumber != null) {
      writeKeyValue(buffer, PosLabels.ticket.table, '${order.tableNumber}');
    }
    if (order.orderType == 'Delivery') {
      buffer.writeln(divider());
      writeKeyValue(
          buffer,
          'Direccion de entrega',
          order.deliveryAddress ??
              order.deliveryAddressDetails ??
              order.deliveryAddressReference ??
              '-',
          wrapValue: true);
      final customerBlock = normalize(
        [
          order.customerPhone ?? '',
          order.customerName ?? order.customerOrTable,
        ].where((part) => normalize(part).isNotEmpty).join(' - '),
      );
      if (customerBlock.isNotEmpty) {
        writeKeyValue(buffer, 'Cliente', customerBlock, wrapValue: true);
      }
    }
    buffer.writeln(divider());
    buffer.writeln(
      '${padOrTrim('Nombre', itemNameWidth)} '
      '${padOrTrim('Cant', qtyWidth, left: true)} '
      '${padOrTrim('Precio', moneyWidth, left: true)} '
      '${padOrTrim('Total', moneyWidth, left: true)}',
    );
    for (final item in order.items) {
      final lineTotal = item.price * item.quantity;
      final nameLines = wrapText(item.name.toUpperCase(), itemNameWidth);
      for (var i = 0; i < nameLines.length; i++) {
        final isFirstLine = i == 0;
        final qty = isFirstLine
            ? padOrTrim(item.quantity.toString(), qtyWidth, left: true)
            : spaces(qtyWidth);
        final unit = isFirstLine
            ? padOrTrim(money(item.price), moneyWidth, left: true)
            : spaces(moneyWidth);
        final total = isFirstLine
            ? padOrTrim(money(lineTotal), moneyWidth, left: true)
            : spaces(moneyWidth);
        buffer.writeln(
          '${padOrTrim(nameLines[i], itemNameWidth)} $qty $unit $total',
        );
      }
      for (final modifier in itemModifierLines(item)) {
        for (final line
            in wrapText('- ${modifier.toUpperCase()}', lineWidth - 2)) {
          buffer.writeln('  $line');
        }
      }
    }
    buffer.writeln(divider());
    final pricing = calculateOrderPricing(order.items);
    final orderTotal = orderGrandTotal(order);
    final cash = order.paymentCashAmount ?? 0;
    final usd = order.paymentUsdAmount ?? 0;
    final usdExchangeRate = order.paymentUsdExchangeRate ?? 0;
    final card = order.paymentCardAmount ?? 0;
    final balance = order.paymentBalance ?? 0;
    if (pricing.promoApplied && pricing.promoLabel != null) {
      final sign = pricing.promoAdjustment >= 0 ? '+' : '-';
      buffer.writeln(
        '${padOrTrim(pricing.promoLabel!, lineWidth - moneyWidth - 1)} '
        '${padOrTrim('$sign${money(pricing.promoAdjustment.abs())}', moneyWidth, left: true)}',
      );
    }
    if (order.orderType == 'Delivery' && order.deliveryShippingCost > 0) {
      buffer.writeln(
        '${padOrTrim(PosLabels.order.deliveryShippingCost, lineWidth - moneyWidth - 1)} '
        '${padOrTrim(money(order.deliveryShippingCost), moneyWidth, left: true)}',
      );
    }
    final totalLabel = PosLabels.ticket.orderTotal;
    buffer.writeln(
      '${padOrTrim(totalLabel, lineWidth - moneyWidth - 1)} '
      '${padOrTrim(money(orderTotal), moneyWidth, left: true)}',
    );
    buffer.writeln(
      '${padOrTrim(PosLabels.ticket.cash, lineWidth - moneyWidth - 1)} '
      '${padOrTrim(money(cash), moneyWidth, left: true)}',
    );
    if (usd > 0) {
      buffer.writeln(
        '${padOrTrim(PosLabels.ticket.dollar, lineWidth - moneyWidth - 1)} '
        '${padOrTrim('${money(usd)} USD', moneyWidth, left: true)}',
      );
      buffer.writeln(
        '${padOrTrim(PosLabels.ticket.exchangeRate, lineWidth - moneyWidth - 1)} '
        '${padOrTrim(usdExchangeRate.toStringAsFixed(2), moneyWidth, left: true)}',
      );
    }
    buffer.writeln(
      '${padOrTrim(PosLabels.ticket.card, lineWidth - moneyWidth - 1)} '
      '${padOrTrim(money(card), moneyWidth, left: true)}',
    );
    if (balance >= 0) {
      buffer.writeln(
        '${padOrTrim(PosLabels.ticket.change, lineWidth - moneyWidth - 1)} '
        '${padOrTrim(money(balance), moneyWidth, left: true)}',
      );
    } else {
      buffer.writeln(
        '${padOrTrim(PosLabels.ticket.remaining, lineWidth - moneyWidth - 1)} '
        '${padOrTrim(money(balance.abs()), moneyWidth, left: true)}',
      );
    }
    buffer.writeln(divider());
    buffer.writeln(center(PosLabels.ticket.thankYou));
    buffer.writeln('');
    return buffer.toString().trimRight();
  }

  @override
  Widget build(BuildContext context) {
    if (!_session.isAuthenticated) {
      return PosPinLoginView(
        isLoading: _isAuthenticating || _isLoadingBranches,
        errorMessage: _authError,
        branches: _branches,
        onSubmitPin: _handleLoginWithPin,
      );
    }

    switch (_currentView) {
      case PosView.tables:
        return TableLayoutView(
          tables: _tables,
          orders: _orders,
          deliveryDriverOptions: _deliveryDriverOptions,
          onSelectTable: _openOrCreateOrderFromTable,
          onOpenOrder: _openOrderById,
          onReprintOrder: _handleReprintCompletedOrder,
          onAssignDeliveryDriver: _handleAssignDeliveryDriver,
          onLogout: _handleLogout,
        );
      case PosView.pos:
        if (_activeOrder == null) {
          return Scaffold(
            body: Center(child: Text(PosLabels.common.orderNotFound)),
          );
        }
        return PosWindowView(
          order: _activeOrder!,
          onBackToTables: _handleBackToTables,
          onOrderChanged: _handleOrderChanged,
          onSaveCustomer: _saveCustomerFromPos,
          onProceedToPayment: _handleProceedToPayment,
          onLogout: _handleLogout,
        );
      case PosView.payment:
        if (_activeOrder == null) {
          return Scaffold(
            body: Center(child: Text(PosLabels.common.orderNotFound)),
          );
        }
        final paymentTotal = orderGrandTotal(_activeOrder!);
        final paymentLabel = _activeOrder!.orderType == 'Delivery'
            ? 'Domicilio'
            : (_activeOrder!.tableNumber != null
                ? 'Mesa ${_activeOrder!.tableNumber}'
                : 'Para llevar');

        return PaymentView(
          ticketNumber: _activeOrder!.ticketNumber,
          tableNumber: paymentLabel,
          orderTotal: paymentTotal,
          orderItems: _activeOrder!.items,
          onCancel: _handlePaymentCancel,
          onComplete: _handlePaymentComplete,
          onCloseWithoutPayment: _handleCloseWithoutPayment,
        );
    }
  }
}

class _CustomerOrderRef {
  const _CustomerOrderRef({
    required this.customerId,
    required this.addressId,
  });

  final int customerId;
  final int addressId;
}

extension on _FigmaPosShellState {
  Future<Map<String, int>> _saveCustomerFromPos(AppOrder order) async {
    final ref = await _resolveCustomerForOrder(order);
    return <String, int>{
      'customerId': ref.customerId,
      'addressId': ref.addressId,
    };
  }
}
