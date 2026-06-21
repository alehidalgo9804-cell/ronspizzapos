import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/platform/esc_pos_builder.dart';
import '../../../core/platform/printer_manager.dart';
import '../../../core/platform/printer_models.dart';
import '../../../core/session/app_session.dart';

Future<void> showPosSalesReportDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _PosSalesReportDialog(),
  );
}

class _CashierOption {
  const _CashierOption({required this.id, required this.name});
  final int id;
  final String name;
}

class _SalesPreview {
  const _SalesPreview({
    required this.from,
    required this.to,
    required this.totalSold,
    required this.orderCount,
    required this.avgTicket,
    required this.totalDiscounts,
    required this.netTotal,
    required this.byOrderType,
    required this.byPaymentMethod,
    required this.deliverySales,
    required this.deliveryShipping,
    required this.deliveryDeliveryCount,
    required this.deliveryBonusTotal,
    required this.deliveryDriverShare,
    required this.deliveryPizzeriaShare,
    required this.showProducts,
    required this.generatedAt,
    required this.branchLabel,
    required this.cashierLabel,
    required this.products,
  });

  final DateTime from;
  final DateTime to;
  final double totalSold;
  final int orderCount;
  final double avgTicket;
  final double totalDiscounts;
  final double netTotal;
  final List<Map<String, dynamic>> byOrderType;
  final List<Map<String, dynamic>> byPaymentMethod;
  final double deliverySales;
  final double deliveryShipping;
  final int deliveryDeliveryCount;
  final double deliveryBonusTotal;
  final double deliveryDriverShare;
  final double deliveryPizzeriaShare;
  final bool showProducts;
  final DateTime generatedAt;
  final String branchLabel;
  final String cashierLabel;
  final List<Map<String, dynamic>> products;
}

class _PosSalesReportDialog extends StatefulWidget {
  const _PosSalesReportDialog();

  @override
  State<_PosSalesReportDialog> createState() => _PosSalesReportDialogState();
}

class _PosSalesReportDialogState extends State<_PosSalesReportDialog> {
  final AppSession _session = AppSession.instance;
  late DateTime _fromDateTime;
  late DateTime _toDateTime;
  bool _showProducts = false;
  bool _allCashiers = true;
  int? _selectedCashierId;
  bool _isLoadingCashiers = true;
  bool _isGenerating = false;
  String? _errorMessage;
  List<_CashierOption> _cashiers = const [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDateTime = DateTime(now.year, now.month, now.day, 0, 0);
    _toDateTime = now;
    _loadCashiers();
  }

  Future<void> _loadCashiers() async {
    setState(() {
      _isLoadingCashiers = true;
      _errorMessage = null;
    });
    final options = <_CashierOption>[];
    String? loadError;

    // El selector debe mostrar exactamente los usuarios activos con rol
    // admin o cajero (los mismos que se ven en el apartado Usuarios).
    // /pos-cashiers usa el mismo servicio que /admin-usuarios, pero esta
    // disponible para cualquier usuario autenticado (incluidos cajeros).
    try {
      final usersResponse = await _session.apiClient.get('/pos-cashiers');
      if (usersResponse['success'] == true) {
        final users = (usersResponse['data'] as List?) ?? const [];
        for (final row in users) {
          final map = (row as Map?)?.cast<String, dynamic>();
          if (map == null) continue;
          final isActive = _toInt(map['activo'], fallback: 1) == 1;
          if (!isActive) continue;
          final id = _toInt(map['id']);
          final nombre = '${map['nombre'] ?? ''}'.trim();
          final apellido = '${map['apellido'] ?? ''}'.trim();
          final fullName = '$nombre $apellido'.trim();
          if (id > 0 && fullName.isNotEmpty) {
            options.add(_CashierOption(id: id, name: fullName));
          }
        }
      } else {
        loadError = usersResponse['message']?.toString();
      }
    } catch (e) {
      loadError = 'Error al cargar cajeros: $e';
    }

    // Solo si no hay usuarios configurados, incluir al usuario actual para
    // permitir generar un reporte filtrado por lo menos por el mismo.
    if (options.isEmpty && (_session.userId ?? 0) > 0) {
      final currentName = (_session.userName ?? '').trim();
      if (currentName.isNotEmpty) {
        options.add(_CashierOption(id: _session.userId!, name: currentName));
      }
    }

    if (!mounted) return;
    setState(() {
      final unique = <int, _CashierOption>{};
      for (final option in options) {
        unique[option.id] = option;
      }
      final sorted = unique.values.toList(growable: false)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _cashiers = sorted;
      _selectedCashierId = sorted.isEmpty ? null : sorted.first.id;
      _isLoadingCashiers = false;
      if (sorted.isEmpty && loadError != null) {
        _errorMessage = loadError;
      }
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final current = isFrom ? _fromDateTime : _toDateTime;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    setState(() {
      final merged = DateTime(date.year, date.month, date.day, current.hour, current.minute);
      if (isFrom) {
        _fromDateTime = merged;
      } else {
        _toDateTime = merged;
      }
    });
  }

  Future<void> _pickTime({required bool isFrom}) async {
    final current = isFrom ? _fromDateTime : _toDateTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final merged = DateTime(current.year, current.month, current.day, picked.hour, picked.minute);
      if (isFrom) {
        _fromDateTime = merged;
      } else {
        _toDateTime = merged;
      }
    });
  }

  Future<List<Map<String, dynamic>>> _fetchAllReceipts({
    required DateTime from,
    required DateTime to,
    int? cashierId,
    String? channel,
    bool dateOnly = false,
  }) async {
    final rows = <Map<String, dynamic>>[];
    int page = 1;
    int pages = 1;
    do {
      final query = <String, String>{
        'from': dateOnly ? _apiDateOnly(from) : _apiDateTime(from),
        'to': dateOnly ? _apiDateOnly(to) : _apiDateTime(to),
        'page': '$page',
        'per_page': '100',
        if (cashierId != null) 'mesero_id': '$cashierId',
        if ((channel ?? '').trim().isNotEmpty) 'canal': channel!,
      };
      final path = '/reportes/recibos?${Uri(queryParameters: query).query}';
      final response = await _session.apiClient.get(path);
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'No se pudo consultar recibos');
      }
      final data = (response['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final pageRows = (data['rows'] as List?) ?? const [];
      for (final row in pageRows) {
        final map = (row as Map?)?.cast<String, dynamic>();
        if (map != null) rows.add(map);
      }
      final meta = (data['meta'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      pages = _toInt(meta['pages'], fallback: 1);
      page += 1;
    } while (page <= pages);
    return rows;
  }

  Future<double> _sumDeliveryShippingFromDetails(
    List<Map<String, dynamic>> deliveryRows,
  ) async {
    double shipping = 0;
    for (final row in deliveryRows) {
      final orderId = _toInt(row['id']);
      if (orderId <= 0) continue;
      final response = await _session.apiClient.get('/reportes/recibos/$orderId');
      if (response['success'] != true) continue;
      final data = (response['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final totals = (data['totals'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      shipping += _toDouble(totals['shipping']);
    }
    return shipping;
  }

  Future<_SalesPreview> _generateReport() async {
    final cashierId = _allCashiers ? null : _selectedCashierId;
    var query = _buildQueryParams(
      from: _fromDateTime,
      to: _toDateTime,
      cashierId: cashierId,
      dateOnly: false,
    );
    var salesPath = '/reportes/ventas?${Uri(queryParameters: query).query}';
    var salesResponse = await _session.apiClient.get(salesPath);
    if (salesResponse['success'] != true) {
      throw Exception(salesResponse['message'] ?? 'No se pudo generar reporte de ventas');
    }

    var salesData = (salesResponse['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    var summary = (salesData['summary'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    var channels = (salesData['channels'] as List?) ?? const [];
    var paymentMethods = (salesData['payment_methods'] as List?) ?? const [];
    var branchId = _toInt(salesData['branch_id']);

    var receiptsRows = await _fetchAllReceipts(
      from: _fromDateTime,
      to: _toDateTime,
      cashierId: cashierId,
      dateOnly: false,
    );

    if (_toInt(summary['total_pedidos']) == 0 && receiptsRows.isEmpty) {
      query = _buildQueryParams(
        from: _fromDateTime,
        to: _toDateTime,
        cashierId: cashierId,
        dateOnly: true,
      );
      salesPath = '/reportes/ventas?${Uri(queryParameters: query).query}';
      final fallbackSales = await _session.apiClient.get(salesPath);
      if (fallbackSales['success'] == true) {
        salesData =
            (fallbackSales['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
        summary = (salesData['summary'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
        channels = (salesData['channels'] as List?) ?? const [];
        paymentMethods = (salesData['payment_methods'] as List?) ?? const [];
        branchId = _toInt(salesData['branch_id']);
      }
      receiptsRows = await _fetchAllReceipts(
        from: _fromDateTime,
        to: _toDateTime,
        cashierId: cashierId,
        dateOnly: true,
      );
    }
    final deliveryRows = receiptsRows.where((row) {
      final channel = '${row['tipo_pedido'] ?? ''}'.toLowerCase();
      return channel.contains('delivery') || channel.contains('domicilio');
    }).toList(growable: false);

    double discounts = 0;
    for (final row in receiptsRows) {
      discounts += _toDouble(row['discount_amount']);
    }

    final totalSold = _toDouble(summary['total_ventas']);
    final orderCount = _toInt(summary['total_pedidos']);
    final avgTicket = _toDouble(summary['ticket_promedio']);
    final netTotal = totalSold - discounts;

    final byType = <Map<String, dynamic>>[];
    for (final raw in channels) {
      final map = (raw as Map?)?.cast<String, dynamic>();
      if (map == null) continue;
      final key = '${map['key'] ?? ''}'.toLowerCase();
      final label = key == 'delivery'
          ? 'Domicilio'
          : key == 'pickup'
              ? 'Recoger'
              : 'Mesa / Para comer aqui';
      byType.add(<String, dynamic>{
        'label': label,
        'orders': _toInt(map['orders']),
        'total': _toDouble(map['total_mxn']),
      });
    }

    final byPayment = <Map<String, dynamic>>[];
    for (final raw in paymentMethods) {
      final map = (raw as Map?)?.cast<String, dynamic>();
      if (map == null) continue;
      final key = '${map['key'] ?? ''}'.toLowerCase();
      if (!['efectivo', 'tarjeta', 'usd', 'mixto'].contains(key)) continue;
      final label = key == 'usd'
          ? 'Dolar'
          : key == 'mixto'
              ? 'Mixto'
              : key[0].toUpperCase() + key.substring(1);
      byPayment.add(<String, dynamic>{
        'label': label,
        'orders': _toInt(map['orders']),
        'total': _toDouble(map['total_mxn']),
      });
    }

    final deliverySales = byType
        .where((row) => row['label'] == 'Domicilio')
        .fold<double>(0, (acc, row) => acc + _toDouble(row['total']));
    final deliveryShipping = await _sumDeliveryShippingFromDetails(deliveryRows);
    const bonusPerDelivery = 10.0;
    final deliveryDeliveryCount = deliveryRows.length;
    final deliveryBonusTotal = deliveryDeliveryCount * bonusPerDelivery;
    final deliveryDriverShare = deliveryShipping + deliveryBonusTotal;
    final deliveryPizzeriaShare = deliverySales;

    final products = <Map<String, dynamic>>[];
    if (_showProducts) {
      final productsPath = '/reportes/productos?${Uri(queryParameters: query).query}';
      final productsResponse = await _session.apiClient.get(productsPath);
      if (productsResponse['success'] == true) {
        final productsData =
            (productsResponse['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
        final items = (productsData['items'] as List?) ?? const [];
        for (final row in items) {
          final map = (row as Map?)?.cast<String, dynamic>();
          if (map == null) continue;
          products.add(<String, dynamic>{
            'name': '${map['nombre_snapshot'] ?? map['nombre'] ?? 'Producto'}',
            'qty': _toDouble(map['cantidad_vendida']),
            'total': _toDouble(map['total_vendido']),
          });
          if (products.length >= 20) break;
        }
      }
    }

    String cashierLabel = 'Todos los cajeros';
    if (!_allCashiers) {
      cashierLabel = 'Cajero #${_selectedCashierId ?? 0}';
      for (final cashier in _cashiers) {
        if (cashier.id == _selectedCashierId) {
          cashierLabel = cashier.name;
          break;
        }
      }
    }

    return _SalesPreview(
      from: _fromDateTime,
      to: _toDateTime,
      totalSold: totalSold,
      orderCount: orderCount,
      avgTicket: avgTicket,
      totalDiscounts: discounts,
      netTotal: netTotal,
      byOrderType: byType,
      byPaymentMethod: byPayment,
      deliverySales: deliverySales,
      deliveryShipping: deliveryShipping,
      deliveryDeliveryCount: deliveryDeliveryCount,
      deliveryBonusTotal: deliveryBonusTotal,
      deliveryDriverShare: deliveryDriverShare,
      deliveryPizzeriaShare: deliveryPizzeriaShare,
      showProducts: _showProducts,
      generatedAt: DateTime.now(),
      branchLabel: branchId > 0 ? 'Sucursal #$branchId' : 'Sucursal',
      cashierLabel: cashierLabel,
      products: products,
    );
  }

  Future<void> _handleCreateReport() async {
    // Actualizar el rango final al momento de generar para incluir ventas
    // realizadas mientras el diálogo estuvo abierto.
    final now = DateTime.now();
    if (now.isAfter(_fromDateTime)) {
      _toDateTime = now;
    }

    if (_toDateTime.isBefore(_fromDateTime)) {
      setState(() => _errorMessage = 'La fecha/hora final debe ser mayor o igual a la inicial.');
      return;
    }
    if (!_allCashiers && (_selectedCashierId ?? 0) <= 0) {
      setState(() => _errorMessage = 'Selecciona un cajero especifico o usa Todos los cajeros.');
      return;
    }
    setState(() {
      _errorMessage = null;
      _isGenerating = true;
    });

    try {
      final preview = await _generateReport();
      if (!mounted) return;
      setState(() => _isGenerating = false);
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => _SalesPreviewDialog(preview: preview),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = '$error';
      });
    }
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _formatTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _apiDateTime(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    final s = value.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$mm:$s';
  }

  String _apiDateOnly(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Map<String, String> _buildQueryParams({
    required DateTime from,
    required DateTime to,
    required int? cashierId,
    required bool dateOnly,
  }) {
    return <String, String>{
      'from': dateOnly ? _apiDateOnly(from) : _apiDateTime(from),
      'to': dateOnly ? _apiDateOnly(to) : _apiDateTime(to),
      if (cashierId != null) 'mesero_id': '$cashierId',
    };
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
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
                      'Reporte de ventas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
              child: Column(
                children: [
                  _fieldRow(
                    label: 'Desde',
                    child: Row(
                      children: [
                        Expanded(
                          child: _PickerButton(text: _formatDate(_fromDateTime), onTap: () => _pickDate(isFrom: true)),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 98,
                          child: _PickerButton(text: _formatTime(_fromDateTime), onTap: () => _pickTime(isFrom: true)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _fieldRow(
                    label: 'Hasta',
                    child: Row(
                      children: [
                        Expanded(
                          child: _PickerButton(text: _formatDate(_toDateTime), onTap: () => _pickDate(isFrom: false)),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 98,
                          child: _PickerButton(text: _formatTime(_toDateTime), onTap: () => _pickTime(isFrom: false)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _fieldRow(
                    label: 'Cajero',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _allCashiers
                              ? 'all'
                              : (_selectedCashierId == null ? 'all' : 'cashier_$_selectedCashierId'),
                          items: [
                            const DropdownMenuItem<String>(
                              value: 'all',
                              child: Text('Todos los cajeros'),
                            ),
                            ..._cashiers.map(
                              (cashier) => DropdownMenuItem<String>(
                                value: 'cashier_${cashier.id}',
                                child: Text(cashier.name),
                              ),
                            ),
                          ],
                          onChanged: _isLoadingCashiers
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _allCashiers = value == 'all';
                                    if (!_allCashiers) {
                                      _selectedCashierId = int.tryParse(value.replaceFirst('cashier_', ''));
                                    }
                                  });
                                },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _fieldRow(
                    label: 'Mostrar productos',
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Switch(
                        value: _showProducts,
                        onChanged: (value) => setState(() => _showProducts = value),
                      ),
                    ),
                  ),
                  if (_isLoadingCashiers)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Cargando cajeros...',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                        ),
                      ),
                    ),
                  if (!_isLoadingCashiers && _cashiers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No se encontraron cajeros. Verifica que existan empleados activos en la sucursal.',
                          style: TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
                        ),
                      ),
                    ),
                  if ((_errorMessage ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
                        ),
                      ),
                    ),

                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _handleCreateReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2EAD3A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                    ),
                    child: _isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Crear reporte',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldRow({required String label, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _SalesPreviewDialog extends StatefulWidget {
  const _SalesPreviewDialog({required this.preview});

  final _SalesPreview preview;

  @override
  State<_SalesPreviewDialog> createState() => _SalesPreviewDialogState();
}

class _SalesPreviewDialogState extends State<_SalesPreviewDialog> {
  bool _isPrinting = false;

  String _mxn(double value) => '\$${value.toStringAsFixed(2)} MXN';

  String _two(int v) => v.toString().padLeft(2, '0');

  String _dateTime(DateTime value) {
    return '${_two(value.day)}/${_two(value.month)}/${value.year} ${_two(value.hour)}:${_two(value.minute)}';
  }

  int get _reportLineWidth =>
      PrinterManager.instance.charsPerLine(PrinterDestination.salesReport);

  String _lineKV(String key, String value, {int? width}) {
    final lineWidth = width ?? _reportLineWidth;
    var left = key.trim();
    var right = value.trim();
    final total = left.length + right.length;

    if (total >= lineWidth) {
      // Dejar espacio para un separador entre ambos valores.
      final available = lineWidth - 1;
      final rightWidth = right.length > (available * 0.35).floor()
          ? (available * 0.35).floor()
          : right.length;
      final leftWidth = available - rightWidth;
      if (left.length > leftWidth) {
        left = left.substring(0, leftWidth);
      }
      if (right.length > rightWidth) {
        right = right.substring(0, rightWidth);
      }
      return '$left $right';
    }

    final gap = lineWidth - total;
    return '$left${' ' * gap}$right';
  }

  String _separator({int? width}) => '-' * (width ?? _reportLineWidth);

  String _buildPrintableReportText({int? printWidth}) {
    final p = widget.preview;
    final width = printWidth ?? _reportLineWidth;
    final b = StringBuffer();
    b.writeln('RONS PIZZA');
    b.writeln(p.branchLabel);
    b.writeln('REPORTE DE VENTAS');
    b.writeln('Generado: ${_dateTime(p.generatedAt)}');
    b.writeln('Desde:    ${_dateTime(p.from)}');
    b.writeln('Hasta:    ${_dateTime(p.to)}');
    b.writeln('Cajero:   ${p.cashierLabel}');
    b.writeln(_separator(width: width));
    b.writeln('RESUMEN GENERAL');
    b.writeln(_lineKV('Total vendido', _mxn(p.totalSold), width: width));
    b.writeln(_lineKV('Cantidad ordenes', '${p.orderCount}', width: width));
    b.writeln(_lineKV('Ticket promedio', _mxn(p.avgTicket), width: width));
    b.writeln(_lineKV('Descuentos', _mxn(p.totalDiscounts), width: width));
    b.writeln(_lineKV('Total neto', _mxn(p.netTotal), width: width));
    b.writeln(_separator(width: width));
    b.writeln('TIPO DE PEDIDO');
    for (final row in p.byOrderType) {
      final label = '${row['label']} (${row['orders']})';
      b.writeln(_lineKV(label, _mxn((row['total'] as num).toDouble()), width: width));
    }
    b.writeln(_separator(width: width));
    b.writeln('METODO DE PAGO');
    for (final row in p.byPaymentMethod) {
      final label = '${row['label']} (${row['orders']})';
      b.writeln(_lineKV(label, _mxn((row['total'] as num).toDouble()), width: width));
    }
    b.writeln(_separator(width: width));
    b.writeln('DELIVERY');
    b.writeln(_lineKV('Ventas domicilio (caja)', _mxn(p.deliverySales), width: width));
    b.writeln(_lineKV('Envios (repartidor)', _mxn(p.deliveryShipping), width: width));
    b.writeln(_lineKV(
        'Bono 10 MXN x ${p.deliveryDeliveryCount} entreg.', _mxn(p.deliveryBonusTotal), width: width));
    b.writeln(_lineKV('Total ref. repartidor', _mxn(p.deliveryDriverShare), width: width));
    b.writeln(_lineKV('Ventas caja domicilio', _mxn(p.deliveryPizzeriaShare), width: width));
    if (p.showProducts && p.products.isNotEmpty) {
      b.writeln(_separator(width: width));
      b.writeln('PRODUCTOS');
      for (final product in p.products) {
        final name = '${product['name'] ?? 'Producto'}';
        final qty = (product['qty'] as num?)?.toDouble() ?? 0;
        final total = (product['total'] as num?)?.toDouble() ?? 0;
        b.writeln(_lineKV('${qty.toStringAsFixed(0)} x $name', _mxn(total), width: width));
      }
    }
    b.writeln(_separator(width: width));
    return b.toString().trimRight();
  }

  Uint8List _buildReportEscPos() {
    final text = _buildPrintableReportText(printWidth: _reportLineWidth);
    final lines = text.split('\n');
    final b = EscPosBuilder()
      ..init()
      ..selectFontA()
      ..leftMargin(0)
      ..alignLeft();

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      final trimmed = line.trim();
      final upper = trimmed.toUpperCase();

      if (trimmed == 'RONS PIZZA') {
        b
          ..alignCenter()
          ..boldOn()
          ..doubleHeightOn()
          ..line(trimmed)
          ..doubleHeightOff()
          ..boldOff()
          ..alignLeft();
        continue;
      }

      if (trimmed == widget.preview.branchLabel ||
          trimmed.startsWith('REPORTE DE VENTAS')) {
        b
          ..alignCenter()
          ..boldOn()
          ..line(trimmed)
          ..boldOff()
          ..alignLeft();
        continue;
      }

      final isSectionHeader = upper == 'RESUMEN GENERAL' ||
          upper == 'TIPO DE PEDIDO' ||
          upper == 'METODO DE PAGO' ||
          upper == 'DELIVERY' ||
          upper == 'PRODUCTOS';
      if (isSectionHeader) {
        b.boldOn().line(line).boldOff();
        continue;
      }

      final isBoldTotal = upper.startsWith('TOTAL') ||
          upper.startsWith('VENTAS CAJA DOMICILIO') ||
          upper.startsWith('TOTAL REF. REPARTIDOR');
      if (isBoldTotal) {
        b.boldOn().line(line).boldOff();
        continue;
      }

      b.line(line);
    }

    b.emptyLine().emptyLine().feed(4).cut();
    return b.build();
  }

  Future<void> _printReport() async {
    setState(() => _isPrinting = true);
    try {
      final printer = PrinterManager.instance.resolvePrinter(PrinterDestination.salesReport);
      if (printer == null) {
        throw Exception('No hay impresora configurada para ${PrinterDestination.salesReport.label}');
      }

      if (printer.driver == PrinterDriver.pdf) {
        final filePath = await PrinterManager.instance.printTicket(
          destination: PrinterDestination.salesReport,
          text: _buildPrintableReportText(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reporte guardado: $filePath')),
        );
        return;
      }

      final bytes = _buildReportEscPos();
      await PrinterManager.instance.printEscPosTicket(
        destination: PrinterDestination.salesReport,
        bytes: bytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte enviado a impresion.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo imprimir el reporte: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
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
                  const Expanded(
                    child: Text(
                      'Crear reporte',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isPrinting ? null : _printReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2EAD3A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: _isPrinting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Imprimir'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informe del ${preview.from.day}/${preview.from.month}/${preview.from.year} al ${preview.to.day}/${preview.to.month}/${preview.to.year}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${preview.branchLabel}  |  ${preview.cashierLabel}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 12),
                    if (preview.orderCount == 0)
                      const Text(
                        'No hay ventas para el rango seleccionado.',
                        style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                      )
                    else ...[
                      _kv('Total vendido', _mxn(preview.totalSold)),
                      _kv('Cantidad de ordenes', '${preview.orderCount}'),
                      _kv('Ticket promedio', _mxn(preview.avgTicket)),
                      _kv('Descuentos totales', _mxn(preview.totalDiscounts)),
                      _kv('Total neto', _mxn(preview.netTotal)),
                      const SizedBox(height: 14),
                      const Text('Desglose por tipo de pedido', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      ...preview.byOrderType.map(
                        (row) => _kv('${row['label']} (${row['orders']} ordenes)', _mxn((row['total'] as num).toDouble())),
                      ),
                      const SizedBox(height: 14),
                      const Text('Desglose por metodo de pago', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      ...preview.byPaymentMethod.map(
                        (row) => _kv(
                          '${row['label']} (${row['orders']} ordenes)',
                          _mxn((row['total'] as num).toDouble()),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Delivery', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _kv('Ventas domicilio (caja)', _mxn(preview.deliverySales)),
                      _kv('Envios cobrados (repartidor)', _mxn(preview.deliveryShipping)),
                      _kv(
                        'Bono repartidor (\$10 x ${preview.deliveryDeliveryCount} entregas)',
                        _mxn(preview.deliveryBonusTotal),
                      ),
                      _kv(
                        'Total referencia repartidor (envio + bono)',
                        _mxn(preview.deliveryDriverShare),
                      ),
                      _kv(
                        'Ventas en caja domicilio (sin restar bono)',
                        _mxn(preview.deliveryPizzeriaShare),
                      ),
                      const SizedBox(height: 10),
                      if (preview.showProducts && preview.products.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text('Productos vendidos', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        ...preview.products.map(
                          (product) => _kv(
                            '${((product['qty'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} x ${product['name']}',
                            _mxn(((product['total'] as num?)?.toDouble() ?? 0)),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          const SizedBox(width: 10),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(42),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        foregroundColor: const Color(0xFF111827),
      ),
      child: Text(text),
    );
  }
}
