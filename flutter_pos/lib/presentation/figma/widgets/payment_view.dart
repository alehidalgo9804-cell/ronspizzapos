import 'package:flutter/material.dart';

import '../constants/labels.dart';
import '../constants/payment_settings.dart';
import '../figma_models.dart';

class PaymentView extends StatefulWidget {
  const PaymentView({
    super.key,
    required this.ticketNumber,
    required this.tableNumber,
    required this.orderTotal,
    required this.deliveryShippingCost,
    required this.isDelivery,
    required this.orderItems,
    required this.guests,
    required this.onCancel,
    required this.onComplete,
    required this.onCloseWithoutPayment,
  });

  final String ticketNumber;
  final String tableNumber;
  final double orderTotal;
  final double deliveryShippingCost;
  final bool isDelivery;
  final List<OrderItemData> orderItems;
  final List<GuestData> guests;
  final VoidCallback onCancel;
  final Future<void> Function(PaymentData) onComplete;
  final ValueChanged<String> onCloseWithoutPayment;

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _usdController = TextEditingController();
  final TextEditingController _cardController = TextEditingController();
  bool _printTicket = true;
  bool _isSubmitting = false;

  double get _cashAmount => double.tryParse(_cashController.text.trim()) ?? 0;
  double get _usdAmount => double.tryParse(_usdController.text.trim()) ?? 0;
  double get _usdAmountInMxn => _usdAmount * PaymentSettings.usdExchangeRate;
  double get _cardAmount => double.tryParse(_cardController.text.trim()) ?? 0;
  double get _paidAmount => _cashAmount + _cardAmount + _usdAmountInMxn;
  double get _balance => _paidAmount - widget.orderTotal;

  @override
  void dispose() {
    _cashController.dispose();
    _usdController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (_paidAmount < widget.orderTotal) return;
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onComplete(
        PaymentData(
          cashAmount: _cashAmount,
          usdAmount: _usdAmount,
          usdExchangeRateUsed: PaymentSettings.usdExchangeRate,
          cardAmount: _cardAmount,
          paidAmount: _paidAmount,
          balance: _balance,
          printTicket: _printTicket,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _startCloseWithoutPaymentFlow() async {
    final reasons = PosLabels.payment.closeReasons;
    String selectedReason = reasons.first;
    final otherController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(PosLabels.payment.closeOrderWithoutPayment),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final reason in reasons)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onTap: () =>
                          setDialogState(() => selectedReason = reason),
                      title: Text(reason),
                      leading: Icon(
                        selectedReason == reason
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: selectedReason == reason
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF9CA3AF),
                        size: 20,
                      ),
                    ),
                  if (selectedReason == PosLabels.payment.reasonOther)
                    TextField(
                      controller: otherController,
                      autofocus: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: PosLabels.payment.reasonHint,
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(PosLabels.buttons.cancel),
            ),
            FilledButton(
              onPressed: () {
                String reasonToSave = selectedReason;
                if (selectedReason == PosLabels.payment.reasonOther) {
                  reasonToSave = otherController.text.trim();
                  if (reasonToSave.isEmpty) {
                    return;
                  }
                }
                Navigator.of(context).pop(reasonToSave);
              },
              child: Text(PosLabels.buttons.confirmClose),
            ),
          ],
        ),
      ),
    );

    otherController.dispose();
    if (result == null || result.isEmpty) return;
    widget.onCloseWithoutPayment(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildCurrentOrderPanel()),
                _buildSummaryPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Row(
        children: [
          OutlinedButton.icon(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text(PosLabels.buttons.cancel)),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${PosLabels.common.ticket} ${widget.ticketNumber}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              Text(
                  '${PosLabels.payment.payment} - ${PosLabels.common.table} ${widget.tableNumber}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 92),
        ],
      ),
    );
  }

  Widget _buildSummaryPanel() {
    return Container(
      width: 540,
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(left: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  PosLabels.payment.paymentSummary,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${PosLabels.payment.orderTotal}:',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                      const Spacer(),
                      Text(
                        '\$${widget.orderTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isDelivery && widget.deliveryShippingCost > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${PosLabels.order.deliveryShippingCost}:',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                        const Spacer(),
                        Text(
                          '\$${widget.deliveryShippingCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _PaymentInputRow(
                  label: PosLabels.payment.cash,
                  controller: _cashController,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                _PaymentInputRow(
                  label: PosLabels.payment.dollar,
                  controller: _usdController,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                _PaymentInputRow(
                  label: PosLabels.payment.card,
                  controller: _cardController,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: const Color(0xFFBFDBFE), width: 2),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _balance >= 0
                            ? '${PosLabels.payment.change}:'
                            : '${PosLabels.payment.remainingAmount}:',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\$${_balance.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          color: _balance >= 0
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.print_outlined,
                          color: Color(0xFF6B7280)),
                      const SizedBox(width: 8),
                      Text(
                        PosLabels.payment.printTicket,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _printTicket,
                        onChanged: (value) =>
                            setState(() => _printTicket = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: _isSubmitting || _paidAmount < widget.orderTotal
                        ? null
                        : _complete,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(PosLabels.buttons.completePayment),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton(
                    onPressed: _startCloseWithoutPaymentFlow,
                    child: Text(PosLabels.buttons.closeWithoutPayment),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrderSections() {
    final guests = widget.guests.isNotEmpty
        ? widget.guests
        : const [GuestData(id: 1, name: 'Cliente 1')];
    final showGuestHeaders = guests.length > 1;
    final sections = <Widget>[];

    for (final guest in guests) {
      final guestItems =
          widget.orderItems.where((i) => i.guestId == guest.id).toList();
      if (guestItems.isEmpty) continue;

      if (showGuestHeaders) {
        sections.add(
          Container(
            color: const Color(0xFFEFF6FF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    guest.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      for (final item in guestItems) {
        final lineTotal = item.price * item.quantity;
        sections.add(
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF3F4F6)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 40,
                  child: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 16,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                Expanded(
                  flex: 22,
                  child: Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
                Expanded(
                  flex: 22,
                  child: Text(
                    '\$${lineTotal.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final guestSubtotal = guestItems.fold<double>(
        0.0,
        (sum, item) => sum + item.price * item.quantity,
      );
      sections.add(
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 78,
                child: Text(
                  showGuestHeaders ? 'Total ${guest.name}' : 'Total',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Expanded(
                flex: 22,
                child: Text(
                  '\$${guestSubtotal.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return sections;
  }

  Widget _buildCurrentOrderPanel() {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  PosLabels.order.currentOrder,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 40,
                  child: Text(
                    PosLabels.table.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 16,
                  child: Text(
                    PosLabels.table.qty,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 22,
                  child: Text(
                    PosLabels.table.price,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 22,
                  child: Text(
                    PosLabels.table.total,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: widget.orderItems.isEmpty
                  ? Center(
                      child: Text(
                        PosLabels.common.noItemsInOrder,
                        style: TextStyle(color: Color(0xFF9CA3AF)),
                      ),
                    )
                  : ListView(
                      children: _buildOrderSections(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentInputRow extends StatelessWidget {
  const _PaymentInputRow({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 140,
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: onChanged,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0.00',
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
