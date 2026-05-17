import 'package:flutter/material.dart';

import '../../../core/session/app_session.dart';
import '../constants/labels.dart';
import '../figma_models.dart';
import 'pos_functions_drawer.dart';
import 'pos_printer_settings_dialog.dart';
import 'pos_sales_report_dialog.dart';

import 'pos_top_header.dart';

enum _ActiveOrderFilterType { all, pickup, delivery }

class TableLayoutView extends StatelessWidget {
  const TableLayoutView({
    super.key,
    required this.tables,
    required this.orders,
    required this.deliveryDriverOptions,
    required this.onSelectTable,
    required this.onOpenOrder,
    required this.onReprintOrder,
    required this.onAssignDeliveryDriver,
    this.onLogout,
  });

  final List<TableInfo> tables;
  final List<AppOrder> orders;
  final List<String> deliveryDriverOptions;
  final ValueChanged<String> onSelectTable;
  final ValueChanged<String> onOpenOrder;
  final Future<void> Function(AppOrder order) onReprintOrder;
  final Future<void> Function(String orderId, String? driver)
      onAssignDeliveryDriver;
  final VoidCallback? onLogout;

  Color _statusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return const Color(0xFF46515E);
      case TableStatus.occupied:
        return const Color(0xFF2563EB);
      case TableStatus.awaitingPayment:
        return const Color(0xFF16A34A);
    }
  }

  String _statusText(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return PosLabels.status.available;
      case TableStatus.occupied:
        return PosLabels.status.occupied;
      case TableStatus.awaitingPayment:
        return PosLabels.status.awaitingPayment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TableLayoutContent(
      tables: tables,
      orders: orders,
      deliveryDriverOptions: deliveryDriverOptions,
      onSelectTable: onSelectTable,
      onOpenOrder: onOpenOrder,
      onReprintOrder: onReprintOrder,
      onAssignDeliveryDriver: onAssignDeliveryDriver,
      onLogout: onLogout,
      statusColor: _statusColor,
      statusText: _statusText,
    );
  }
}

class _TableLayoutContent extends StatefulWidget {
  const _TableLayoutContent({
    required this.tables,
    required this.orders,
    required this.deliveryDriverOptions,
    required this.onSelectTable,
    required this.onOpenOrder,
    required this.onReprintOrder,
    required this.onAssignDeliveryDriver,
    required this.onLogout,
    required this.statusColor,
    required this.statusText,
  });

  final List<TableInfo> tables;
  final List<AppOrder> orders;
  final List<String> deliveryDriverOptions;
  final ValueChanged<String> onSelectTable;
  final ValueChanged<String> onOpenOrder;
  final Future<void> Function(AppOrder order) onReprintOrder;
  final Future<void> Function(String orderId, String? driver)
      onAssignDeliveryDriver;
  final VoidCallback? onLogout;
  final Color Function(TableStatus) statusColor;
  final String Function(TableStatus) statusText;

  @override
  State<_TableLayoutContent> createState() => _TableLayoutContentState();
}

class _TableLayoutContentState extends State<_TableLayoutContent> {
  final AppSession _session = AppSession.instance;
  FloorPlanSection _section = FloorPlanSection.floorPlan;
  _ActiveOrderFilterType _activeOrderFilterType = _ActiveOrderFilterType.all;
  static const String _allDriversFilter = '__all_drivers__';
  static const String _clearDriverSelection = '__clear_driver__';
  String _selectedDriverFilter = _allDriversFilter;

  List<AppOrder> get _activeOrdersRaw => widget.orders
      .where((order) => order.status.isActive)
      .toList(growable: false)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<String> get _availableDeliveryDrivers {
    final normalizedFromConfig = widget.deliveryDriverOptions
        .map((driver) => driver.trim())
        .where((driver) => driver.isNotEmpty);
    final normalizedFromOrders = _activeOrdersRaw
        .where((order) => order.orderType == 'Delivery')
        .map((order) => order.deliveryDriver?.trim() ?? '')
        .where((driver) => driver.isNotEmpty);

    final drivers = <String>{
      ...normalizedFromConfig,
      ...normalizedFromOrders,
    }.toList(growable: false)
      ..sort();
    return drivers;
  }

  List<AppOrder> get _activeOrders {
    Iterable<AppOrder> current = _activeOrdersRaw;
    switch (_activeOrderFilterType) {
      case _ActiveOrderFilterType.pickup:
        current = current.where((order) => order.orderType == 'To Go');
        break;
      case _ActiveOrderFilterType.delivery:
        current = current.where((order) => order.orderType == 'Delivery');
        if (_selectedDriverFilter != _allDriversFilter) {
          current = current.where(
              (order) => (order.deliveryDriver ?? '') == _selectedDriverFilter);
        }
        break;
      case _ActiveOrderFilterType.all:
        break;
    }

    return current.toList(growable: false);
  }

  List<AppOrder> get _historyOrders => widget.orders
          .where((order) =>
              order.status == AppOrderStatus.closedWithoutPayment ||
              order.status == AppOrderStatus.paid ||
              order.status == AppOrderStatus.completed)
          .where((order) {
        final referenceDate = (order.completedAt ?? order.createdAt).toLocal();
        final today = DateTime.now();
        return referenceDate.year == today.year &&
            referenceDate.month == today.month &&
            referenceDate.day == today.day;
      }).toList(growable: false)
        ..sort((a, b) => (b.completedAt ?? b.createdAt)
            .compareTo(a.completedAt ?? a.createdAt));

  String _statusLabel(AppOrderStatus status) {
    switch (status) {
      case AppOrderStatus.pending:
        return PosLabels.status.pending;
      case AppOrderStatus.open:
        return PosLabels.status.open;
      case AppOrderStatus.occupied:
        return PosLabels.status.occupied;
      case AppOrderStatus.inProgress:
        return PosLabels.status.inProgress;
      case AppOrderStatus.awaitingPayment:
        return PosLabels.status.awaitingPayment;
      case AppOrderStatus.closedWithoutPayment:
        return PosLabels.status.closedWithoutPayment;
      case AppOrderStatus.paid:
        return PosLabels.status.paid;
      case AppOrderStatus.completed:
        return PosLabels.status.completed;
      case AppOrderStatus.closed:
        return PosLabels.status.closed;
      case AppOrderStatus.cancelled:
        return PosLabels.status.cancelled;
    }
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

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    return '$day/$month/$year ${_formatTime(dateTime)}';
  }

  TableInfo? _tableByNumber(String number) {
    try {
      return widget.tables.firstWhere((table) => table.number == number);
    } catch (_) {
      return null;
    }
  }

  Widget _buildFloorPlanCard(TableInfo table) {
    return InkWell(
      onTap: () => widget.onSelectTable(table.number),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: widget.statusColor(table.status),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(table.number,
                style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 6),
            Text(widget.statusText(table.status),
                style: const TextStyle(fontSize: 13, color: Color(0xFFE5E7EB))),
            if ((table.orderTotal ?? 0) > 0) ...[
              const SizedBox(height: 6),
              Text('\$${table.orderTotal!.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }

  double _orderTotal(AppOrder order) => orderGrandTotal(order);

  Future<void> _openHistoryDetail(AppOrder order) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        bool isPrinting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('${PosLabels.common.ticket} ${order.ticketNumber}'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 640,
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${PosLabels.ticket.type}: ${_displayOrderType(order.orderType)}'),
                    Text(
                      order.tableNumber != null
                          ? '${PosLabels.common.table}: ${order.tableNumber}'
                          : '${PosLabels.table.customer}: ${order.customerName ?? order.customerOrTable}',
                    ),
                    Text(
                        '${PosLabels.table.date}: ${_formatDateTime(order.completedAt ?? order.createdAt)}'),
                    Text(
                        '${PosLabels.table.status}: ${_statusLabel(order.status)}'),
                    if (order.status == AppOrderStatus.closedWithoutPayment &&
                        (order.closeReason?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 4),
                      Text('${PosLabels.table.reason}: ${order.closeReason}'),
                    ],
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            flex: 46,
                            child: Text(PosLabels.table.name,
                                style: TextStyle(fontWeight: FontWeight.w700))),
                        Expanded(
                            flex: 14,
                            child: Text(PosLabels.table.qty,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w700))),
                        Expanded(
                            flex: 20,
                            child: Text(PosLabels.table.price,
                                textAlign: TextAlign.right,
                                style: TextStyle(fontWeight: FontWeight.w700))),
                        Expanded(
                            flex: 20,
                            child: Text(PosLabels.table.total,
                                textAlign: TextAlign.right,
                                style: TextStyle(fontWeight: FontWeight.w700))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Column(
                      children: order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(flex: 46, child: Text(item.name)),
                              Expanded(
                                  flex: 14,
                                  child: Text('${item.quantity}',
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  flex: 20,
                                  child: Text(
                                      '\$${item.price.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right)),
                              Expanded(
                                  flex: 20,
                                  child: Text(
                                      '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                      textAlign: TextAlign.right)),
                            ],
                          ),
                        );
                      }).toList(growable: false),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Text(
                        '${PosLabels.payment.orderTotal}: \$${_orderTotal(order).toStringAsFixed(2)}'),
                    Text(
                        '${PosLabels.payment.cash}: \$${(order.paymentCashAmount ?? 0).toStringAsFixed(2)}'),
                    if ((order.paymentUsdAmount ?? 0) > 0) ...[
                      Text(
                          '${PosLabels.payment.dollar}: \$${(order.paymentUsdAmount ?? 0).toStringAsFixed(2)} USD'),
                      Text(
                          '${PosLabels.payment.exchangeRate}: ${(order.paymentUsdExchangeRate ?? 0).toStringAsFixed(2)}'),
                    ],
                    Text(
                        '${PosLabels.payment.card}: \$${(order.paymentCardAmount ?? 0).toStringAsFixed(2)}'),
                    Text(
                      (order.paymentBalance ?? 0) >= 0
                          ? '${PosLabels.payment.change}: \$${(order.paymentBalance ?? 0).toStringAsFixed(2)}'
                          : '${PosLabels.payment.remainingAmount}: \$${(order.paymentBalance ?? 0).abs().toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(PosLabels.buttons.close),
              ),
              if (order.status == AppOrderStatus.paid ||
                  order.status == AppOrderStatus.completed)
                FilledButton(
                  onPressed: isPrinting
                      ? null
                      : () async {
                          setDialogState(() => isPrinting = true);
                          await widget.onReprintOrder(order);
                          if (mounted) {
                            setDialogState(() => isPrinting = false);
                          }
                        },
                  child: Text(
                    isPrinting
                        ? PosLabels.buttons.printing
                        : PosLabels.buttons.reprintTicket,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 20),
              child: _buildSectionBody(),
            ),
          ),
        ],
      ),
    );
  }

  void _openFunctionsMenu() {
    showPosFunctionsDrawer(
      context,
      onCreateReport: () {
        if (!mounted) return;
        showPosSalesReportDialog(context);
      },
      onPrinterSettings: () {
        if (!mounted) return;
        showPrinterSettingsDialog(context);
      },
      onLogout: widget.onLogout,
    );
  }

  Widget _buildHeader() {
    final userName = (_session.userName ?? '').trim();
    final role = (_session.role ?? '').trim();
    return PosTopHeader(
      left: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              PosLabels.common.restaurantPos,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 18),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderTab(
                    label: PosLabels.common.floorPlan,
                    active: _section == FloorPlanSection.floorPlan,
                    onTap: () =>
                        setState(() => _section = FloorPlanSection.floorPlan),
                  ),
                  _HeaderTab(
                    label: PosLabels.common.orders,
                    active: _section == FloorPlanSection.orders,
                    onTap: () =>
                        setState(() => _section = FloorPlanSection.orders),
                  ),
                  _HeaderTab(
                    label: PosLabels.common.orderHistory,
                    active: _section == FloorPlanSection.orderHistory,
                    onTap: () => setState(
                        () => _section = FloorPlanSection.orderHistory),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      center: const SizedBox.shrink(),
      userName: userName.isEmpty ? PosLabels.common.adminUser : userName,
      statusLabel: role.isEmpty ? null : role,
      showStatusIndicator: _session.isAuthenticated,
      onMenuTap: _openFunctionsMenu,
    );
  }

  Widget _buildSectionBody() {
    if (_section == FloorPlanSection.orders) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(PosLabels.common.activeOrders,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
          const SizedBox(height: 4),
          Text(
            PosLabels.order.orderHelpActive,
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${PosLabels.order.filterByOrderType}:',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(PosLabels.order.allOrderTypes),
                    selected:
                        _activeOrderFilterType == _ActiveOrderFilterType.all,
                    onSelected: (_) {
                      setState(() {
                        _activeOrderFilterType = _ActiveOrderFilterType.all;
                        _selectedDriverFilter = _allDriversFilter;
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(PosLabels.order.orderTypePickup),
                    selected:
                        _activeOrderFilterType == _ActiveOrderFilterType.pickup,
                    onSelected: (_) {
                      setState(() {
                        _activeOrderFilterType = _ActiveOrderFilterType.pickup;
                        _selectedDriverFilter = _allDriversFilter;
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(PosLabels.order.orderTypeDelivery),
                    selected: _activeOrderFilterType ==
                        _ActiveOrderFilterType.delivery,
                    onSelected: (_) {
                      setState(() {
                        _activeOrderFilterType =
                            _ActiveOrderFilterType.delivery;
                        _selectedDriverFilter = _allDriversFilter;
                      });
                    },
                  ),
                ],
              ),
              if (_activeOrderFilterType == _ActiveOrderFilterType.delivery)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${PosLabels.order.filterByDriver}:',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 250,
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: (_selectedDriverFilter == _allDriversFilter ||
                                  _availableDeliveryDrivers
                                      .contains(_selectedDriverFilter))
                              ? _selectedDriverFilter
                              : _allDriversFilter,
                          isExpanded: true,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedDriverFilter = value);
                          },
                          items: [
                            DropdownMenuItem<String>(
                              value: _allDriversFilter,
                              child: Text(PosLabels.order.allDrivers),
                            ),
                            ..._availableDeliveryDrivers.map(
                              (driver) => DropdownMenuItem<String>(
                                value: driver,
                                child: Text(driver),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _activeOrders.isEmpty
                ? Center(
                    child: Text(
                      PosLabels.empty.noPendingOrders,
                      style: const TextStyle(
                          fontSize: 16, color: Color(0xFF6B7280)),
                    ),
                  )
                : ListView.separated(
                    itemCount: _activeOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = _activeOrders[index];
                      final referenceText = order.tableNumber != null
                          ? '${PosLabels.common.table} ${order.tableNumber}'
                          : ((order.customerName?.trim().isNotEmpty ?? false)
                              ? order.customerName!.trim()
                              : PosLabels.order.noCustomerReference);
                      final driverText =
                          (order.deliveryDriver?.trim().isNotEmpty ?? false)
                              ? order.deliveryDriver!.trim()
                              : PosLabels.order.unassignedDriver;
                      return InkWell(
                        onTap: () => widget.onOpenOrder(order.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x12000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 1))
                            ],
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 140,
                                child: Text(order.orderNumber,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                              ),
                              SizedBox(
                                width: 170,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _OrderTypeBadge(
                                    label: _displayOrderType(order.orderType),
                                    isDelivery: order.orderType == 'Delivery',
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(referenceText,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF111827))),
                              ),
                              SizedBox(
                                width: 220,
                                child: order.orderType == 'Delivery'
                                    ? _DriverAssignmentSelector(
                                        deliveryDriverLabel:
                                            PosLabels.order.deliveryDriver,
                                        currentDriverLabel: driverText,
                                        clearDriverLabel:
                                            PosLabels.order.unassignedDriver,
                                        drivers: _availableDeliveryDrivers,
                                        onChanged: (selected) async {
                                          final newDriver =
                                              selected == _clearDriverSelection
                                                  ? null
                                                  : selected.trim();
                                          await widget.onAssignDeliveryDriver(
                                            order.id,
                                            (newDriver?.isEmpty ?? true)
                                                ? null
                                                : newDriver,
                                          );
                                        },
                                      )
                                    : const Text(
                                        '-',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(_formatTime(order.createdAt),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280))),
                              ),
                              Container(
                                width: 110,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFFFCD34D)),
                                ),
                                child: Text(
                                  _statusLabel(order.status),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF92400E),
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    if (_section == FloorPlanSection.orderHistory) {
      if (_historyOrders.isEmpty) {
        return Center(
          child: Text(PosLabels.empty.noCompletedOrders,
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 150,
                  child: Text('Ticket',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700)),
                ),
                SizedBox(
                  width: 120,
                  child: Text('Tipo',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  child: Text('Cliente / mesa',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700)),
                ),
                SizedBox(
                  width: 160,
                  child: Text('Cajero',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700)),
                ),
                SizedBox(
                  width: 90,
                  child: Text('Hora',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700)),
                ),
                SizedBox(
                  width: 110,
                  child: Text('Total',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700)),
                ),
                SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: Text('Estatus',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _historyOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final order = _historyOrders[index];
                final total = _orderTotal(order);
                final referenceDate = order.completedAt ?? order.createdAt;
                final reference = order.tableNumber != null
                    ? '${PosLabels.common.table} ${order.tableNumber}'
                    : (order.customerName ?? order.customerOrTable);
                final cashier = (order.cashierName ?? '').trim().isEmpty
                    ? 'Sin cajero'
                    : order.cashierName!.trim();
                return InkWell(
                  onTap: () => _openHistoryDetail(order),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 6,
                            offset: Offset(0, 1))
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 150,
                          child: Text(
                              '${PosLabels.common.ticket} ${order.ticketNumber}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(_displayOrderType(order.orderType),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF374151),
                                  fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(reference,
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF111827))),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: Text(cashier,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF111827),
                                  fontWeight: FontWeight.w500)),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(_formatTime(referenceDate),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF6B7280))),
                        ),
                        SizedBox(
                          width: 110,
                          child: Text('\$${total.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF111827),
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 140,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: order.status ==
                                    AppOrderStatus.closedWithoutPayment
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: order.status ==
                                        AppOrderStatus.closedWithoutPayment
                                    ? const Color(0xFFFCA5A5)
                                    : const Color(0xFF86EFAC)),
                          ),
                          child: Text(
                            _statusLabel(order.status),
                            style: TextStyle(
                                fontSize: 12,
                                color: order.status ==
                                        AppOrderStatus.closedWithoutPayment
                                    ? const Color(0xFF991B1B)
                                    : const Color(0xFF166534),
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 42,
          child: ElevatedButton.icon(
            onPressed: () => widget.onSelectTable('to-go'),
            icon: const Icon(Icons.add, size: 18),
            label: Text(PosLabels.common.newOrderToGo,
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _LegendDot(
                color: const Color(0xFF46515E),
                label: PosLabels.status.available),
            const SizedBox(width: 24),
            _LegendDot(
                color: const Color(0xFF2563EB),
                label: PosLabels.status.occupied),
          ],
        ),
        const SizedBox(height: 18),
        Text(PosLabels.common.floorPlan,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827))),
        const SizedBox(height: 14),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 14.0;
              const normalWidth = 186.0;
              const normalHeight = 146.0;
              final topTables = ['5', '6', '7', '8', '9']
                  .map(_tableByNumber)
                  .whereType<TableInfo>()
                  .toList(growable: false);
              final bottomTables = ['3 y 4', '1 y 2']
                  .map(_tableByNumber)
                  .whereType<TableInfo>()
                  .toList(growable: false);

              final maxWidth = constraints.maxWidth;
              final minRequiredTopWidth =
                  (normalWidth * 5) + (spacing * 4); // 5 cards + gaps
              final scale = (maxWidth / minRequiredTopWidth).clamp(0.55, 1.0);
              final itemWidth = normalWidth * scale;
              final itemHeight = normalHeight * scale;
              final doubleCardWidth = (itemWidth * 2) + spacing;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: topTables
                          .map(
                            (table) => Padding(
                              padding: EdgeInsets.only(
                                  right: table == topTables.last ? 0 : spacing),
                              child: SizedBox(
                                width: itemWidth,
                                height: itemHeight,
                                child: _buildFloorPlanCard(table),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    SizedBox(height: spacing),
                    Row(
                      children: bottomTables
                      .map(
                        (table) => Padding(
                          padding: EdgeInsets.only(
                            right: table == bottomTables.last ? 0 : spacing,
                            ),
                            child: SizedBox(
                              width: doubleCardWidth,
                              height: itemHeight,
                              child: _buildFloorPlanCard(table),
                              ),
                              ),
                              )
                              .toList(growable: false),
                              ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OrderTypeBadge extends StatelessWidget {
  const _OrderTypeBadge({
    required this.label,
    required this.isDelivery,
  });

  final String label;
  final bool isDelivery;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDelivery ? const Color(0xFFEEF2FF) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDelivery ? const Color(0xFFC7D2FE) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isDelivery ? const Color(0xFF3730A3) : const Color(0xFF166534),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DriverAssignmentSelector extends StatelessWidget {
  const _DriverAssignmentSelector({
    required this.deliveryDriverLabel,
    required this.currentDriverLabel,
    required this.clearDriverLabel,
    required this.drivers,
    required this.onChanged,
  });

  final String deliveryDriverLabel;
  final String currentDriverLabel;
  final String clearDriverLabel;
  final List<String> drivers;
  final Future<void> Function(String selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      onSelected: (selected) async => onChanged(selected),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: _TableLayoutContentState._clearDriverSelection,
          child: Text(clearDriverLabel),
        ),
        ...drivers.map(
          (driver) => PopupMenuItem<String>(
            value: driver,
            child: Text(driver),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(
              '$deliveryDriverLabel: ',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1D4ED8),
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: Text(
                currentDriverLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1D4ED8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.expand_more,
              size: 16,
              color: Color(0xFF1D4ED8),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderTab extends StatelessWidget {
  const _HeaderTab({
    required this.label,
    this.active = false,
    this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active ? Border.all(color: const Color(0xFFD1D5DB)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
              color: active ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
              fontSize: 13),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
      ],
    );
  }
}
