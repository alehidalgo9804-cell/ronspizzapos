import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/session/app_session.dart';
import '../../../core/platform/kitchen_printer.dart';
import '../constants/labels.dart';
import '../figma_mock_data.dart';
import '../figma_models.dart';
import '../utils/maps_link_helper.dart';
import '../utils/whatsapp_message_builder.dart';
import '../utils/whatsapp_share_helper.dart';
import '../utils/coordinates_input_parser.dart';
import 'ensalada_builder_view.dart';
import 'hamburger_builder_view.dart';
import 'panes_ajo_builder_view.dart';
import 'pizza_builder_view.dart';
import 'pos_functions_drawer.dart';
import 'pos_sales_report_dialog.dart';
import 'pos_top_header.dart';
import 'spaghetti_builder_view.dart';
import 'wings_builder_view.dart';

class PosWindowView extends StatefulWidget {
  const PosWindowView({
    super.key,
    required this.order,
    required this.onBackToTables,
    required this.onOrderChanged,
    required this.onProceedToPayment,
    required this.onSaveCustomer,
  });

  final AppOrder order;
  final VoidCallback onBackToTables;
  final ValueChanged<AppOrder> onOrderChanged;
  final ValueChanged<AppOrder> onProceedToPayment;
  final Future<Map<String, int>> Function(AppOrder order) onSaveCustomer;

  @override
  State<PosWindowView> createState() => _PosWindowViewState();
}

class _PosWindowViewState extends State<PosWindowView> {
  static const String _toGoType = 'To Go';
  static const String _deliveryType = 'Delivery';
  static const String _dineInType = 'Dine In';

  PosTab _activeTab = PosTab.receipt;
  String? _selectedCategory;
  String? _selectedDrinkGroup;
  late List<OrderItemData> _orderItems;
  late List<GuestData> _guests;
  late int _currentGuest;
  late String _orderType;
  String? _hoveredQuickComplementId;
  final AppSession _session = AppSession.instance;
  late List<String> _deliveryAddresses;
  final Map<String, int> _deliveryAddressIdsByLabel = <String, int>{};
  final Map<String, _DeliveryAddressOption> _deliveryAddressOptionsByLabel =
      <String, _DeliveryAddressOption>{};
  late String? _selectedDeliveryAddress;
  int? _selectedCustomerId;
  int? _selectedCustomerAddressId;
  List<_CustomerSuggestion> _customerSuggestions = const [];
  bool _isSearchingCustomers = false;
  Timer? _customerSearchDebounce;
  final TextEditingController _customerSearchController =
      TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _deliveryNotesController =
      TextEditingController();
  final TextEditingController _deliveryShippingController =
      TextEditingController();

  static const List<_DrinkCategoryEntry> _drinkCatalog = [
    _DrinkCategoryEntry.group(
      name: 'Soda botella',
      items: [
        _DrinkOption(name: 'Coca Cola', price: 40),
        _DrinkOption(name: 'Coca Cola Zero', price: 40),
        _DrinkOption(name: 'Coca Cola Light', price: 40),
        _DrinkOption(name: 'Sidral Mundet', price: 40),
        _DrinkOption(name: 'Sangr\u00eda', price: 40),
        _DrinkOption(name: 'Sprite', price: 40),
        _DrinkOption(name: 'Fresca', price: 40),
      ],
    ),
    _DrinkCategoryEntry.group(
      name: 'Soda vidrio',
      items: [
        _DrinkOption(name: 'Coca Cola', price: 35),
        _DrinkOption(name: 'Fresa', price: 35),
        _DrinkOption(name: 'Sprite', price: 35),
        _DrinkOption(name: 'Sangr\u00eda', price: 35),
        _DrinkOption(name: 'Naranja', price: 35),
        _DrinkOption(name: 'Fresca', price: 35),
      ],
    ),
    _DrinkCategoryEntry.group(
      name: 'Soda bote',
      items: [
        _DrinkOption(name: 'Coca Cola', price: 35),
      ],
    ),
    _DrinkCategoryEntry.group(
      name: 'Frutijugos',
      items: [
        _DrinkOption(name: 'Limonada', price: 40),
        _DrinkOption(name: 'Pepino lim\u00f3n y ch\u00eda', price: 40),
        _DrinkOption(name: 'Limonada cherry', price: 40),
        _DrinkOption(name: 'Jamaica', price: 40),
        _DrinkOption(name: 'Cebada', price: 40),
        _DrinkOption(name: 'Mango', price: 40),
        _DrinkOption(name: 'Horchata', price: 40),
      ],
    ),
    _DrinkCategoryEntry.product(name: 'T\u00e9 jazm\u00edn', price: 40),
    _DrinkCategoryEntry.product(name: 'Brisk', price: 35),
    _DrinkCategoryEntry.product(name: 'Fuze Tea', price: 40),
    _DrinkCategoryEntry.group(
      name: 'Agua',
      items: [
        _DrinkOption(name: 'Mineral', price: 20),
        _DrinkOption(name: 'Natural', price: 20),
      ],
    ),
    _DrinkCategoryEntry.group(
      name: 'Jarra',
      items: [
        _DrinkOption(name: 'Ponche', price: 99),
        _DrinkOption(name: 'T\u00e9', price: 99),
      ],
    ),
    _DrinkCategoryEntry.group(
      name: 'Vaso 32 oz',
      items: [
        _DrinkOption(name: 'Ponche', price: 50),
        _DrinkOption(name: 'T\u00e9', price: 50),
      ],
    ),
    _DrinkCategoryEntry.group(
      name: 'Vaso 16 oz',
      items: [
        _DrinkOption(name: 'Ponche', price: 35),
        _DrinkOption(name: 'T\u00e9', price: 35),
      ],
    ),
  ];

  static const List<String> _menuEstadioPizzaSpecialties = [
    'Peperoni',
    'Suprema',
    'Surtida',
    'Ranchera',
    'Sonorense',
    'Española',
    'Mexicana',
    'Hawaiana',
    'Italiana',
  ];

  static const List<String> _menuEstadioSauces = [
    'Ligera',
    'Mediana',
    'Caliente',
    'Terrible',
    'Mango habanero',
    'Tamarindo',
    'BBQ',
  ];

  bool get _isTableOrder => widget.order.tableNumber != null;
  bool get _isDelivery => _orderType == _deliveryType;
  bool get _isDrinksCategory => _selectedCategory == 'drinks';
  _DeliveryAddressOption? get _selectedDeliveryAddressOption {
    final label = _selectedDeliveryAddress?.trim() ?? '';
    if (label.isEmpty) {
      return null;
    }
    return _deliveryAddressOptionsByLabel[label];
  }

  String _displayOrderType(String value) {
    switch (value) {
      case _toGoType:
        return PosLabels.common.toGo;
      case _deliveryType:
        return PosLabels.common.delivery;
      case _dineInType:
        return PosLabels.common.dineIn;
      default:
        return value;
    }
  }

  String _displayGuestName(String name) {
    if (name.startsWith('Guest ')) {
      return name.replaceFirst('Guest ', 'Cliente ');
    }
    return name;
  }

  OrderPricingSummary get _pricing => calculateOrderPricing(_orderItems);

  double get _deliveryShippingParsed {
    final raw = _deliveryShippingController.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return 0;
    final v = double.tryParse(raw);
    if (v == null || v < 0) return 0;
    return v;
  }

  double get _orderTotal =>
      _pricing.total + (_isDelivery ? _deliveryShippingParsed : 0);

  List<ProductData> get _currentProducts {
    if (_selectedCategory == null) return const [];
    return products
        .where((product) => product.categoryId == _selectedCategory)
        .toList(growable: false);
  }

  List<_DrinkOption> get _currentDrinkOptions {
    if (_selectedDrinkGroup == null) return const [];
    for (final entry in _drinkCatalog) {
      if (entry.isGroup && entry.name == _selectedDrinkGroup) {
        return entry.items;
      }
    }
    return const [];
  }

  List<ProductData> get _quickComplementProducts {
    const orderedNames = [
      'Papas',
      'Aros',
      'Quesitos',
      'Panes de ajo',
      'Ensalada',
    ];
    final byName = {
      for (final product in products.where(
        (product) => product.categoryId == 'complements',
      ))
        product.name: product,
    };
    return orderedNames
        .where((name) => byName.containsKey(name))
        .map((name) => byName[name]!)
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _loadFromOrder(widget.order);
  }

  @override
  void dispose() {
    _customerSearchDebounce?.cancel();
    _customerSearchController.dispose();
    _customerNameController.dispose();
    _phoneController.dispose();
    _deliveryNotesController.dispose();
    _deliveryShippingController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PosWindowView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) {
      _loadFromOrder(widget.order);
    }
  }

  void _loadFromOrder(AppOrder order) {
    _orderItems = List<OrderItemData>.from(order.items);
    _guests = List<GuestData>.from(order.guests);
    _currentGuest = order.currentGuestId;
    if (_guests.isEmpty) {
      _guests = const [GuestData(id: 1, name: 'Cliente 1')];
      _currentGuest = 1;
    }
    if (!_guests.any((guest) => guest.id == _currentGuest)) {
      _currentGuest = _guests.first.id;
    }
    _orderType = _isTableOrder
        ? _dineInType
        : (order.orderType == _deliveryType ? _deliveryType : _toGoType);
    _deliveryAddresses = List<String>.from(order.deliveryAddresses);
    _deliveryAddressIdsByLabel.clear();
    _deliveryAddressOptionsByLabel.clear();
    _selectedDeliveryAddress = order.deliveryAddress;
    _selectedCustomerId = order.customerId;
    _selectedCustomerAddressId = order.customerAddressId;
    _customerSuggestions = const [];
    _customerSearchController.clear();
    if (_selectedDeliveryAddress != null &&
        !_deliveryAddresses.contains(_selectedDeliveryAddress)) {
      _deliveryAddresses = [..._deliveryAddresses, _selectedDeliveryAddress!];
    }
    for (final label in _deliveryAddresses) {
      _deliveryAddressOptionsByLabel.putIfAbsent(
        label,
        () => _DeliveryAddressOption(
          label: label,
          address: label,
          id: _deliveryAddressIdsByLabel[label] ?? 0,
        ),
      );
    }
    if ((_selectedDeliveryAddress?.trim().isNotEmpty ?? false)) {
      final label = _selectedDeliveryAddress!.trim();
      _deliveryAddressOptionsByLabel[label] = _DeliveryAddressOption(
        label: label,
        address: label,
        id: order.customerAddressId ?? 0,
        placeId: order.deliveryAddressPlaceId,
        latitude: order.deliveryAddressLatitude,
        longitude: order.deliveryAddressLongitude,
        reference: order.deliveryAddressReference,
        details: order.deliveryAddressDetails,
      );
    }
    _customerNameController.text = order.customerName ?? '';
    _phoneController.text = order.customerPhone ?? '';
    _deliveryNotesController.text = order.deliveryNotes ?? '';
    final ship = order.deliveryShippingCost;
    _deliveryShippingController.text = ship > 0 ? ship.toStringAsFixed(2) : '';
  }

  AppOrder _composeOrder({AppOrderStatus? statusOverride}) {
    final status = statusOverride ??
        (widget.order.status == AppOrderStatus.awaitingPayment
            ? AppOrderStatus.awaitingPayment
            : (_orderItems.isEmpty
                ? AppOrderStatus.pending
                : AppOrderStatus.open));

    final selectedAddress = _selectedDeliveryAddressOption;
    return widget.order.copyWith(
      status: status,
      orderType: _isTableOrder ? _dineInType : _orderType,
      items: List<OrderItemData>.from(_orderItems),
      guests: List<GuestData>.from(_guests),
      currentGuestId: _currentGuest,
      customerName: _customerNameController.text.trim().isEmpty
          ? null
          : _customerNameController.text.trim(),
      customerPhone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      customerId: _selectedCustomerId,
      customerAddressId: _selectedCustomerAddressId,
      deliveryAddress: _isDelivery ? _selectedDeliveryAddress : null,
      deliveryAddressReference: null,
      deliveryAddressDetails: _isDelivery ? selectedAddress?.details : null,
      deliveryAddressPlaceId: _isDelivery ? selectedAddress?.placeId : null,
      deliveryAddressLatitude: _isDelivery ? selectedAddress?.latitude : null,
      deliveryAddressLongitude: _isDelivery ? selectedAddress?.longitude : null,
      deliveryNotes:
          _isDelivery && _deliveryNotesController.text.trim().isNotEmpty
              ? _deliveryNotesController.text.trim()
              : null,
      deliveryShippingCost: _isDelivery ? _deliveryShippingParsed : 0,
      // Preservar repartidor asignado desde mesas; no forzar null en cada edición.
      deliveryDriver: _isDelivery ? widget.order.deliveryDriver : null,
      deliveryAddresses: List<String>.from(_deliveryAddresses),
      customerOrTable: widget.order.tableNumber != null
          ? 'Mesa ${widget.order.tableNumber}'
          : (_customerNameController.text.trim().isNotEmpty
              ? _customerNameController.text.trim()
              : (_isDelivery
                  ? PosLabels.common.delivery
                  : PosLabels.common.toGo)),
    );
  }

  void _emitOrderChanged({AppOrderStatus? statusOverride}) {
    widget.onOrderChanged(_composeOrder(statusOverride: statusOverride));
  }

  void _addGuest() {
    final newGuestId = _guests.length + 1;
    setState(() {
      _guests = [
        ..._guests,
        GuestData(id: newGuestId, name: 'Cliente $newGuestId')
      ];
      _currentGuest = newGuestId;
    });
    _emitOrderChanged();
  }

  void _addToOrder(ProductData product) {
    final sauceNameUpper = product.name.toUpperCase();
    final orderItemName = product.categoryId == 'sauces'
        ? (sauceNameUpper.startsWith('SALSA ')
            ? sauceNameUpper
            : 'SALSA $sauceNameUpper')
        : product.name;
    final existingIndex = _orderItems.indexWhere(
        (item) => item.id == product.id && item.guestId == _currentGuest);
    setState(() {
      if (existingIndex >= 0) {
        final existing = _orderItems[existingIndex];
        _orderItems[existingIndex] =
            existing.copyWith(quantity: existing.quantity + 1);
      } else {
        _orderItems = [
          ..._orderItems,
          OrderItemData(
            id: product.id,
            name: orderItemName,
            price: product.price,
            categoryId: product.categoryId,
            quantity: 1,
            guestId: _currentGuest,
          ),
        ];
      }
    });
    _emitOrderChanged();
  }

  Future<void> _openManualExtraEntry() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(PosLabels.order.manualExtra),
          content: SizedBox(
            width: 360,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: PosLabels.order.itemName,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return PosLabels.order.requiredName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    validator: (value) {
                      final parsed = double.tryParse((value ?? '').trim());
                      if (parsed == null) {
                        return PosLabels.order.invalidPrice;
                      }
                      if (parsed <= 0) {
                        return 'El precio debe ser mayor a 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: PosLabels.order.quantityOptional,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return null;
                      }
                      final parsed = int.tryParse(value!.trim());
                      if (parsed == null || parsed < 1) {
                        return PosLabels.order.minQuantity;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(PosLabels.buttons.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: Text(PosLabels.buttons.add),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final name = nameController.text.trim();
    final price = double.parse(priceController.text.trim());
    final quantityText = quantityController.text.trim();
    final quantity = quantityText.isEmpty ? 1 : int.parse(quantityText);
    final itemId = 'extra_manual_${DateTime.now().microsecondsSinceEpoch}';

    setState(() {
      _orderItems = [
        ..._orderItems,
        OrderItemData(
          id: itemId,
          name: name,
          price: price,
          categoryId: 'extras',
          quantity: quantity,
          guestId: _currentGuest,
        ),
      ];
    });
    _emitOrderChanged();
  }

  void _addDrinkToOrder({
    required String group,
    required _DrinkOption option,
  }) {
    final groupPrefix =
        group == 'Frutijugos' ? 'FRUTIJUGO' : group.toUpperCase();
    final orderItemName = '$groupPrefix ${option.name.toUpperCase()}';
    final normalizedGroup = group
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final normalizedOption = option.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final productId = 'drink_${normalizedGroup}_$normalizedOption';

    final existingIndex = _orderItems.indexWhere(
      (item) => item.id == productId && item.guestId == _currentGuest,
    );

    setState(() {
      if (existingIndex >= 0) {
        final existing = _orderItems[existingIndex];
        _orderItems[existingIndex] =
            existing.copyWith(quantity: existing.quantity + 1);
      } else {
        _orderItems = [
          ..._orderItems,
          OrderItemData(
            id: productId,
            name: orderItemName,
            price: option.price,
            categoryId: 'drinks',
            quantity: 1,
            guestId: _currentGuest,
          ),
        ];
      }
    });
    _emitOrderChanged();
  }

  void _addDirectDrinkProductToOrder(_DrinkCategoryEntry productEntry) {
    final orderItemName = productEntry.name.toUpperCase();
    final normalizedName = productEntry.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final productId = 'drink_direct_$normalizedName';
    final existingIndex = _orderItems.indexWhere(
      (item) => item.id == productId && item.guestId == _currentGuest,
    );

    setState(() {
      if (existingIndex >= 0) {
        final existing = _orderItems[existingIndex];
        _orderItems[existingIndex] =
            existing.copyWith(quantity: existing.quantity + 1);
      } else {
        _orderItems = [
          ..._orderItems,
          OrderItemData(
            id: productId,
            name: orderItemName,
            price: productEntry.price ?? 0,
            categoryId: 'drinks',
            quantity: 1,
            guestId: _currentGuest,
          ),
        ];
      }
    });
    _emitOrderChanged();
  }

  String _normalizeMenuEstadioToken(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<String?> _selectMenuEstadioOption({
    required String title,
    required List<String> options,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options
                    .map(
                      (option) => ActionChip(
                        label: Text(option),
                        onPressed: () => Navigator.of(dialogContext).pop(option),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(PosLabels.buttons.cancel),
            ),
          ],
        );
      },
    );
  }

  void _addMenuEstadioConfiguredItem({
    required ProductData product,
    required String option,
    required bool isPizza,
  }) {
    final optionSlug = _normalizeMenuEstadioToken(option);
    final itemId = '${product.id}_$optionSlug';
    final displayName =
        isPizza ? '${product.name} ($option)' : '${product.name} - Salsa $option';

    final existingIndex = _orderItems.indexWhere(
      (item) => item.id == itemId && item.guestId == _currentGuest,
    );

    setState(() {
      if (existingIndex >= 0) {
        final existing = _orderItems[existingIndex];
        _orderItems[existingIndex] =
            existing.copyWith(quantity: existing.quantity + 1);
      } else {
        _orderItems = [
          ..._orderItems,
          OrderItemData(
            id: itemId,
            name: displayName,
            price: product.price,
            categoryId: 'menu_estadio',
            quantity: 1,
            guestId: _currentGuest,
          ),
        ];
      }
    });
    _emitOrderChanged();
  }

  Future<void> _handleMenuEstadioTap(ProductData product) async {
    final normalizedName = product.name.trim().toLowerCase();
    final isPizza = normalizedName == 'pizza grande' ||
        normalizedName == 'pizza rebanada' ||
        normalizedName == 'pizza mini';
    final isSauceChoice =
        normalizedName == 'alitas' || normalizedName == 'boneless';

    if (isPizza) {
      final specialty = await _selectMenuEstadioOption(
        title: 'Selecciona especialidad',
        options: _menuEstadioPizzaSpecialties,
      );
      if (specialty == null || specialty.trim().isEmpty) {
        return;
      }
      _addMenuEstadioConfiguredItem(
        product: product,
        option: specialty,
        isPizza: true,
      );
      return;
    }

    if (isSauceChoice) {
      final sauce = await _selectMenuEstadioOption(
        title: 'Selecciona salsa',
        options: _menuEstadioSauces,
      );
      if (sauce == null || sauce.trim().isEmpty) {
        return;
      }
      _addMenuEstadioConfiguredItem(
        product: product,
        option: sauce,
        isPizza: false,
      );
      return;
    }

    _addToOrder(product);
  }

  void _handleQuickComplementTap(ProductData product) {
    if (product.name == 'Ensalada') {
      _openEnsaladaBuilder();
      return;
    }
    if (product.name == 'Panes de ajo') {
      _openPanesAjoBuilder();
      return;
    }
    _addToOrder(product);
  }

  String _quickComplementImage(String name) {
    switch (name) {
      case 'Papas':
        return 'assets/images/complements/papas.jpg';
      case 'Aros':
        return 'assets/images/complements/aros.jpg';
      case 'Quesitos':
        return 'assets/images/complements/quesitos.jpg';
      case 'Panes de ajo':
        return 'assets/images/complements/panes_ajo.jpg';
      case 'Ensalada':
        return 'assets/images/complements/ensalada.jpg';
      default:
        return 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80';
    }
  }

  Widget _buildCardImage(String image) {
    if (image.trim().isEmpty) {
      return Container(color: const Color(0xFFF3F4F6));
    }

    if (image.startsWith('assets/')) {
      return Image.asset(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFE5E7EB),
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported, size: 18),
        ),
      );
    }

    return Image.network(
      image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFE5E7EB),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, size: 18),
      ),
    );
  }

  Future<void> _openPizzaBuilder() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final dialogWidth = (screenSize.width * 0.88).clamp(1320.0, 1700.0);
        final dialogHeight = (screenSize.height * 0.9).clamp(760.0, 980.0);
        return Dialog(
          alignment: Alignment.centerRight,
          insetPadding: const EdgeInsets.fromLTRB(220, 16, 24, 16),
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: PizzaBuilderView(
              onBack: () => Navigator.of(context).pop(),
              onAddPizza: (config, price) {
                final itemId = 'pizza_${DateTime.now().microsecondsSinceEpoch}';
                final specialtyName =
                    config.selectionMode == PizzaSelectionMode.halfHalf
                        ? 'Pizza Mitad y Mitad'
                        : (config.specialty == 'Pizza personalizada'
                            ? 'Pizza Personalizada'
                            : config.specialty);
                final readableName = '$specialtyName (${config.size})';
                setState(() {
                  _orderItems = [
                    ..._orderItems,
                    OrderItemData(
                      id: itemId,
                      name: readableName,
                      price: price,
                      categoryId: 'pizzas',
                      quantity: 1,
                      guestId: _currentGuest,
                      pizzaConfig: PizzaConfigData(
                        specialty: config.specialty,
                        size: config.size,
                        crustEdge: config.crustEdge,
                        breadType: config.breadType,
                        dorada: config.dorada,
                        ingredients: List<String>.from(config.ingredients),
                        extraIngredients:
                            List<String>.from(config.extraIngredients),
                        selectionMode: config.selectionMode,
                        half1: config.half1,
                        half2: config.half2,
                        half1Mode: config.half1Mode,
                        half2Mode: config.half2Mode,
                        half1Specialty: config.half1Specialty,
                        half2Specialty: config.half2Specialty,
                        half1Ingredients:
                            List<String>.from(config.half1Ingredients),
                        half2Ingredients:
                            List<String>.from(config.half2Ingredients),
                        crustHalf1: config.crustHalf1,
                        crustHalf2: config.crustHalf2,
                        includePromoGarlicBread: config.includePromoGarlicBread,
                      ),
                    ),
                  ];
                });
                _emitOrderChanged();
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _openHamburgerBuilder() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final dialogWidth = (screenSize.width * 0.88).clamp(1320.0, 1700.0);
        final dialogHeight = (screenSize.height * 0.9).clamp(760.0, 980.0);
        return Dialog(
          alignment: Alignment.centerRight,
          insetPadding: const EdgeInsets.fromLTRB(220, 16, 24, 16),
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: HamburgerBuilderView(
              onBack: () => Navigator.of(context).pop(),
              onAddHamburger: (config, price) {
                final itemId =
                    'burger_${DateTime.now().microsecondsSinceEpoch}';
                final name = config.isSpecialCombo
                    ? 'ESPECIAL HAMBURGUESAS'
                    : 'HAMBURGUESA ${config.burgerType.toUpperCase()}';
                setState(() {
                  _orderItems = [
                    ..._orderItems,
                    OrderItemData(
                      id: itemId,
                      name: name,
                      price: price,
                      categoryId: 'hamburgers',
                      quantity: 1,
                      guestId: _currentGuest,
                      hamburgerConfig: config,
                    ),
                  ];
                });
                _emitOrderChanged();
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _openWingsBuilder() async {
    await _openWingsLikeBuilder(
      categoryId: 'wings',
      itemPrefix: 'ALITAS',
      builderTitle: 'Constructor de Alitas',
      summaryTitle: 'Tu orden de alitas',
      addButtonLabel: 'Agregar Alitas a la Orden',
    );
  }

  Future<void> _openBonelessBuilder() async {
    await _openWingsLikeBuilder(
      categoryId: 'boneless',
      itemPrefix: 'BONELESS',
      builderTitle: 'Constructor de Boneless',
      summaryTitle: 'Tu orden de boneless',
      addButtonLabel: 'Agregar Boneless a la Orden',
    );
  }

  Future<void> _openWingsLikeBuilder({
    required String categoryId,
    required String itemPrefix,
    required String builderTitle,
    required String summaryTitle,
    required String addButtonLabel,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final dialogWidth = (screenSize.width * 0.88).clamp(1320.0, 1700.0);
        final dialogHeight = (screenSize.height * 0.9).clamp(760.0, 980.0);
        return Dialog(
          alignment: Alignment.centerRight,
          insetPadding: const EdgeInsets.fromLTRB(220, 16, 24, 16),
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: WingsBuilderView(
              builderTitle: builderTitle,
              summaryTitle: summaryTitle,
              itemPrefix: itemPrefix,
              addButtonLabel: addButtonLabel,
              onBack: () => Navigator.of(context).pop(),
              onAddWings: (config, price) {
                final itemId = 'wings_${DateTime.now().microsecondsSinceEpoch}';
                final sizeLabel = _wingsSizeLabel(config.size).toUpperCase();
                setState(() {
                  _orderItems = [
                    ..._orderItems,
                    OrderItemData(
                      id: itemId,
                      name: '$itemPrefix $sizeLabel',
                      price: price,
                      categoryId: categoryId,
                      quantity: 1,
                      guestId: _currentGuest,
                      wingsConfig: config,
                    ),
                  ];
                });
                _emitOrderChanged();
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEnsaladaBuilder() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final dialogWidth = (screenSize.width * 0.88).clamp(1320.0, 1700.0);
        final dialogHeight = (screenSize.height * 0.9).clamp(760.0, 980.0);
        return Dialog(
          alignment: Alignment.centerRight,
          insetPadding: const EdgeInsets.fromLTRB(220, 16, 24, 16),
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: EnsaladaBuilderView(
              onBack: () => Navigator.of(context).pop(),
              onAddEnsalada: (config, price) {
                final itemId = 'salad_${DateTime.now().microsecondsSinceEpoch}';
                setState(() {
                  _orderItems = [
                    ..._orderItems,
                    OrderItemData(
                      id: itemId,
                      name: 'ENSALADA',
                      price: price,
                      categoryId: 'complements',
                      quantity: 1,
                      guestId: _currentGuest,
                      saladConfig: config,
                    ),
                  ];
                });
                _emitOrderChanged();
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPanesAjoBuilder() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final dialogWidth = (screenSize.width * 0.88).clamp(1320.0, 1700.0);
        final dialogHeight = (screenSize.height * 0.9).clamp(760.0, 980.0);
        return Dialog(
          alignment: Alignment.centerRight,
          insetPadding: const EdgeInsets.fromLTRB(220, 16, 24, 16),
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: PanesAjoBuilderView(
              onBack: () => Navigator.of(context).pop(),
              onAddPanesAjo: (config, price) {
                final itemId =
                    'garlic_bread_${DateTime.now().microsecondsSinceEpoch}';
                setState(() {
                  _orderItems = [
                    ..._orderItems,
                    OrderItemData(
                      id: itemId,
                      name: 'PANES DE AJO',
                      price: price,
                      categoryId: 'complements',
                      quantity: 1,
                      guestId: _currentGuest,
                      garlicBreadConfig: config,
                    ),
                  ];
                });
                _emitOrderChanged();
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSpaghettiBuilder() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final dialogWidth = (screenSize.width * 0.88).clamp(1320.0, 1700.0);
        final dialogHeight = (screenSize.height * 0.9).clamp(760.0, 980.0);
        return Dialog(
          alignment: Alignment.centerRight,
          insetPadding: const EdgeInsets.fromLTRB(220, 16, 24, 16),
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: SpaghettiBuilderView(
              onBack: () => Navigator.of(context).pop(),
              onAddSpaghetti: (config, price) {
                final itemId =
                    'spaghetti_${DateTime.now().microsecondsSinceEpoch}';
                setState(() {
                  _orderItems = [
                    ..._orderItems,
                    OrderItemData(
                      id: itemId,
                      name: 'ESPAGUETI ${config.spaghettiType.toUpperCase()}',
                      price: price,
                      categoryId: 'spaghetti',
                      quantity: 1,
                      guestId: _currentGuest,
                      spaghettiConfig: config,
                    ),
                  ];
                });
                _emitOrderChanged();
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  void _updateQuantity(String itemId, int guestId, int change) {
    setState(() {
      _orderItems = _orderItems
          .map((item) => item.id == itemId && item.guestId == guestId
              ? item.copyWith(quantity: (item.quantity + change).clamp(0, 999))
              : item)
          .where((item) => item.quantity > 0)
          .toList(growable: false);
    });
    _emitOrderChanged();
  }

  void _removeItem(String itemId, int guestId) {
    setState(() {
      _orderItems = _orderItems
          .where((item) => !(item.id == itemId && item.guestId == guestId))
          .toList(growable: false);
    });
    _emitOrderChanged();
  }

  Future<void> _editItemComment(OrderItemData item) async {
    final controller = TextEditingController(text: item.comment ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${PosLabels.order.itemComment} - ${item.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: PosLabels.order.addComment,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(PosLabels.buttons.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(PosLabels.buttons.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;

    setState(() {
      _orderItems = _orderItems.map((orderItem) {
        if (orderItem.id == item.id && orderItem.guestId == item.guestId) {
          if (result.isEmpty) {
            return orderItem.copyWith(clearComment: true);
          }
          return orderItem.copyWith(comment: result);
        }
        return orderItem;
      }).toList(growable: false);
    });
    _emitOrderChanged();
  }

  String _burgerSideLabel(HamburgerSideOption side) {
    switch (side) {
      case HamburgerSideOption.conPapas:
        return 'CON PAPAS';
      case HamburgerSideOption.sinPapas:
        return 'SIN PAPAS';
      case HamburgerSideOption.conAros:
        return 'CON AROS';
    }
  }

  bool _isVegetableIngredient(String ingredient) {
    const vegetables = {'Pepinillos', 'Cebolla', 'Tomate', 'Lechuga'};
    return vegetables.contains(ingredient);
  }

  List<String> _burgerUnitLines(HamburgerUnitConfigData unit) {
    final lines = <String>[];
    if (unit.usedSinVerduraQuickAction) {
      lines.add('SIN VERDURA');
      for (final removed in unit.removedIngredients) {
        if (!_isVegetableIngredient(removed)) {
          lines.add('SIN ${removed.toUpperCase()}');
        }
      }
    } else {
      for (final removed in unit.removedIngredients) {
        lines.add('SIN ${removed.toUpperCase()}');
      }
    }
    for (final extra in unit.extraIngredients) {
      lines.add(extra.toUpperCase());
    }
    if (unit.cutOption == HamburgerCutOption.partidaMitad) {
      lines.add('PARTIDA A LA MITAD');
    }
    return lines;
  }

  bool _comboHasChanges(HamburgerConfigData config) {
    final unit1 = config.burger1;
    final unit2 = config.burger2;
    if (unit1 == null || unit2 == null) return false;
    final sideChanged = config.side != HamburgerSideOption.conPapas;
    return sideChanged ||
        _burgerUnitLines(unit1).isNotEmpty ||
        _burgerUnitLines(unit2).isNotEmpty;
  }

  List<String> _burgerDetailLines(HamburgerConfigData config) {
    if (config.isSpecialCombo) {
      if (!_comboHasChanges(config)) return const [];
      final details = <String>[];
      if (config.side != HamburgerSideOption.conPapas) {
        details.add(_burgerSideLabel(config.side));
      }
      final unit1 = config.burger1;
      final unit2 = config.burger2;
      if (unit1 != null) {
        details.add('Hamburguesa 1');
        details.addAll(_burgerUnitLines(unit1));
      }
      if (unit2 != null) {
        details.add('Hamburguesa 2');
        details.addAll(_burgerUnitLines(unit2));
      }
      return details;
    }

    final details = <String>[];
    if (config.usedSinVerduraQuickAction) {
      details.add('SIN VERDURA');
      for (final removed in config.removedIngredients) {
        if (!_isVegetableIngredient(removed)) {
          details.add('SIN ${removed.toUpperCase()}');
        }
      }
    } else {
      for (final removed in config.removedIngredients) {
        details.add('SIN ${removed.toUpperCase()}');
      }
    }
    for (final extra in config.extraIngredients) {
      details.add(extra.toUpperCase());
    }
    if (config.cutOption == HamburgerCutOption.partidaMitad) {
      details.add('PARTIDA A LA MITAD');
    }
    if (config.side != HamburgerSideOption.conPapas) {
      details.add(_burgerSideLabel(config.side));
    }
    return details;
  }

  List<String> _pizzaDetailLinesForTicket(PizzaConfigData config) {
    final lines = <String>[];
    if (config.selectionMode == PizzaSelectionMode.halfHalf) {
      final half1Mode = config.half1Mode ?? PizzaHalfSelectionMode.specialty;
      final half2Mode = config.half2Mode ?? PizzaHalfSelectionMode.specialty;
      final half1Label = half1Mode == PizzaHalfSelectionMode.specialty
          ? (config.half1Specialty ?? config.half1 ?? '-')
          : config.half1Ingredients.join(', ');
      final half2Label = half2Mode == PizzaHalfSelectionMode.specialty
          ? (config.half2Specialty ?? config.half2 ?? '-')
          : config.half2Ingredients.join(', ');
      lines.add(
          'Mitad 1 (${half1Mode == PizzaHalfSelectionMode.specialty ? 'Especialidad' : 'Ingredientes'}): $half1Label');
      lines.add(
          'Mitad 2 (${half2Mode == PizzaHalfSelectionMode.specialty ? 'Especialidad' : 'Ingredientes'}): $half2Label');
    } else if (config.selectionMode == PizzaSelectionMode.ingredients &&
        config.ingredients.isNotEmpty) {
      lines.add('Ingredientes: ${config.ingredients.join(', ')}');
    }
    if (config.extraIngredients.isNotEmpty) {
      lines.add('Extras: ${config.extraIngredients.join(', ')}');
    }
    if (config.includePromoGarlicBread) {
      lines.add('Panes de ajo promo');
    }

    if (config.crustEdge == 'Orilla Mitad y Mitad') {
      lines.add(
          'Orilla: 1/2 ${config.crustHalf1 ?? 'Queso crema'} · 1/2 ${config.crustHalf2 ?? 'Queso mozzarella'}');
    } else if (config.crustEdge != 'Regular') {
      lines.add('Orilla: ${config.crustEdge}');
    }
    if (config.breadType != 'Regular') {
      lines.add('Pan: ${config.breadType}');
    }
    if (config.dorada) {
      lines.add('Dorada');
    }
    return lines;
  }

  String _wingsSizeLabel(WingsSizeOption size) {
    switch (size) {
      case WingsSizeOption.mediaOrden:
        return '1/2 ORDEN';
      case WingsSizeOption.orden:
        return 'ORDEN';
      case WingsSizeOption.megaOrden:
        return 'MEGA ORDEN';
    }
  }

  String _wingsBoneLabel(WingsBoneType boneType) {
    switch (boneType) {
      case WingsBoneType.unHueso:
        return '1 HUESO';
      case WingsBoneType.dosHuesos:
        return '2 HUESOS';
    }
  }

  String _shortSauceName(String value) {
    return value.replaceFirst(RegExp(r'^Salsa\s+', caseSensitive: false), '');
  }

  String? _wingsSauceLine(WingsConfigData config) {
    final hasSingleSauce = config.sauce?.trim().isNotEmpty ?? false;
    final hasHalfSauce1 = config.sauceHalf1?.trim().isNotEmpty ?? false;
    final hasHalfSauce2 = config.sauceHalf2?.trim().isNotEmpty ?? false;

    if (config.sauceMode == WingsSauceMode.mitadMitad &&
        hasHalfSauce1 &&
        hasHalfSauce2) {
      final baseLine =
          'MITAD ${_shortSauceName(config.sauceHalf1!).toUpperCase()} / '
          '${_shortSauceName(config.sauceHalf2!).toUpperCase()}';
      return config.sauceOnSide ? '$baseLine APARTE' : baseLine;
    }

    if (!hasSingleSauce) return null;
    final baseLine = 'SALSA ${_shortSauceName(config.sauce!).toUpperCase()}';
    return config.sauceOnSide ? '$baseLine APARTE' : baseLine;
  }

  List<String> _wingsDetailLines(WingsConfigData config) {
    final lines = <String>[];
    if (config.naturales) {
      lines.add('NATURALES');
      if (config.sauceOnSide) {
        final sauceLine = _wingsSauceLine(config);
        if (sauceLine != null) {
          lines.add(sauceLine);
        }
      }
    } else {
      final sauceLine = _wingsSauceLine(config);
      if (sauceLine != null) {
        lines.add(sauceLine);
      }
    }
    if (config.juicy) {
      lines.add('JUGOSAS');
    }
    if (config.doradas) {
      lines.add('DORADAS');
    }
    if (config.boneType != null) {
      lines.add(_wingsBoneLabel(config.boneType!));
    }
    if (config.sinApio) {
      lines.add('SIN APIO');
    }
    if (config.sinZanahoria) {
      lines.add('SIN ZANAHORIA');
    }
    return lines;
  }

  List<String> _saladDetailLines(SaladConfigData config) {
    final lines = <String>[];
    for (final removed in config.removedIngredients) {
      lines.add('SIN ${removed.toUpperCase()}');
    }
    for (final addOn in config.addOns) {
      lines.add('CON ${addOn.toUpperCase()}');
    }
    return lines;
  }

  List<String> _garlicBreadDetailLines(GarlicBreadConfigData config) {
    final type = config.type.trim();
    if (type.isEmpty || type == 'Normales') {
      return const [];
    }
    if (type == '2 y 2 (crema y mozzarella)') {
      return const ['2 Y 2 (QUESO CREMA / QUESO MOZZARELLA)'];
    }
    return [type.toUpperCase()];
  }

  List<String> _spaghettiDetailLines(SpaghettiConfigData config) {
    final lines = <String>[];
    if (config.accompaniment == 'Papas') {
      lines.add('CON PAPAS');
    } else if (config.garlicBreadType != null &&
        config.garlicBreadType != 'Normales') {
      lines.add(
        'PANES DE AJO RELLENOS DE ${config.garlicBreadType!.toUpperCase()}',
      );
    }
    for (final removedIngredient in config.removedIngredients) {
      lines.add('SIN ${removedIngredient.toUpperCase()}');
    }
    if (config.sinQueso) {
      lines.add('SIN QUESO');
    }
    if (config.sinMantequilla) {
      lines.add('SIN MANTEQUILLA');
    }
    if (config.pocaSalsa) {
      lines.add('POCA SALSA');
    }
    if (config.quesoDorado) {
      lines.add('QUESO DORADO');
    }
    for (final extra in config.extras) {
      lines.add('EXTRA ${extra.toUpperCase()}');
    }
    return lines;
  }

  Future<void> _sendToKitchen() async {
    if (_orderItems.isEmpty) return;
    _emitOrderChanged();
    final ticketText = _buildKitchenTicketText();
    try {
      await KitchenPrinter.printKitchenTicket(ticketText);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(PosLabels.ticket.kitchenTicketSent)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${PosLabels.ticket.kitchenTicketFailed} $error')),
      );
    }
  }

  String _buildKitchenTicketText() {
    const lineWidth = 42;
    const qtyWidth = 4;

    String spaces(int count) => count <= 0 ? '' : ' ' * count;
    String divider() => '-' * lineWidth;
    String normalize(String value) =>
        value.replaceAll(RegExp(r'\s+'), ' ').trim();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    String formatDateTime(DateTime value) {
      final local = value.toLocal();
      return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
          '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
    }

    String center(String text) {
      if (text.length >= lineWidth) return text;
      final left = ((lineWidth - text.length) / 2).floor();
      return '${spaces(left)}$text';
    }

    String rowQty(String text, int qty) {
      final maxNameWidth = lineWidth - qtyWidth - 1;
      final name = normalize(text.toUpperCase());
      final display =
          name.length > maxNameWidth ? name.substring(0, maxNameWidth) : name;
      return '${display.padRight(maxNameWidth)} ${qty.toString().padLeft(qtyWidth)}';
    }

    String resolveArea() {
      for (final item in _orderItems) {
        switch (item.categoryId) {
          case '01':
          case '1':
          case 'Pizzas':
          case 'pizzas':
            return 'HORNO';
          case '03':
          case '04':
          case '3':
          case '4':
          case 'Alitas':
          case 'Boneless':
          case 'alitas':
          case 'boneless':
            return 'FREIDORAS Y PLANCHA';
          default:
            continue;
        }
      }
      return 'GENERAL';
    }

    final buffer = StringBuffer();
    final now = DateTime.now();
    buffer.writeln(center('COMANDA COCINA'));
    buffer.writeln(divider());
    buffer.writeln('Cajero: ${_session.userName ?? 'Sin cajero'}');
    buffer.writeln('Hora: ${formatDateTime(now)}');
    buffer.writeln('Area: ${resolveArea()}');
    buffer.writeln('${PosLabels.common.ticket}: ${widget.order.ticketNumber}');
    buffer.writeln(widget.order.tableNumber != null
        ? '${PosLabels.common.table} ${widget.order.tableNumber}'
        : _displayOrderType(_orderType));
    buffer.writeln(divider());
    buffer.writeln(
        '${'Nombre'.padRight(lineWidth - qtyWidth - 1)} ${'Cant'.padLeft(qtyWidth)}');
    buffer.writeln(divider());
    for (final item in _orderItems) {
      buffer.writeln(rowQty(item.name, item.quantity));
      if (item.hamburgerConfig != null) {
        for (final line in _burgerDetailLines(item.hamburgerConfig!)) {
          buffer.writeln('- ${normalize(line).toUpperCase()}');
        }
      } else if (item.wingsConfig != null) {
        for (final line in _wingsDetailLines(item.wingsConfig!)) {
          buffer.writeln('- ${normalize(line).toUpperCase()}');
        }
      } else if (item.saladConfig != null) {
        for (final line in _saladDetailLines(item.saladConfig!)) {
          buffer.writeln('- ${normalize(line).toUpperCase()}');
        }
      } else if (item.garlicBreadConfig != null) {
        for (final line in _garlicBreadDetailLines(item.garlicBreadConfig!)) {
          buffer.writeln('- ${normalize(line).toUpperCase()}');
        }
      } else if (item.spaghettiConfig != null) {
        for (final line in _spaghettiDetailLines(item.spaghettiConfig!)) {
          buffer.writeln('- ${normalize(line).toUpperCase()}');
        }
      } else if (item.pizzaConfig != null) {
        for (final line in _pizzaDetailLinesForTicket(item.pizzaConfig!)) {
          buffer.writeln('- ${normalize(line).toUpperCase()}');
        }
      }
      final comment = item.comment?.trim() ?? '';
      if (comment.isNotEmpty) {
        buffer.writeln('- ${normalize(comment).toUpperCase()}');
      }
      buffer.writeln(divider());
    }
    return buffer.toString().trimRight();
  }

  void _pay() {
    if (_orderItems.isEmpty) return;
    if (_isDelivery &&
        (_selectedDeliveryAddress == null ||
            _selectedDeliveryAddress!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Las órdenes a domicilio requieren dirección.')),
      );
      return;
    }
    widget.onProceedToPayment(
        _composeOrder(statusOverride: AppOrderStatus.awaitingPayment));
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
                _buildOrderPanel(),
                Expanded(child: _buildProductPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final userName = (_session.userName ?? '').trim();
    final role = (_session.role ?? '').trim();

    Widget tab(String label, PosTab tab) {
      final active = _activeTab == tab;
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: FilledButton(
          onPressed: () => setState(() => _activeTab = tab),
          style: FilledButton.styleFrom(
            elevation: 0,
            backgroundColor: active ? Colors.white : const Color(0xFFF3F4F6),
            foregroundColor:
                active ? const Color(0xFF111827) : const Color(0xFF6B7280),
            side: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          child: Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      );
    }

    return PosTopHeader(
      left: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                _emitOrderChanged();
                widget.onBackToTables();
              },
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text(PosLabels.common.backToTables),
            ),
            const SizedBox(width: 10),
            tab(PosLabels.common.receipt, PosTab.receipt),
            tab(PosLabels.common.client, PosTab.client),
            if (!_isTableOrder) ...[
              const SizedBox(width: 8),
              _OrderTypeSelector(
                orderType: _orderType,
                onChanged: (value) {
                  if (_orderType == value) return;
                  setState(() {
                    _orderType = value;
                  });
                  _emitOrderChanged();
                },
              ),
            ],
          ],
        ),
      ),
      center: Text(
        '${widget.order.tableNumber != null ? '${PosLabels.common.table} ${widget.order.tableNumber}' : _displayOrderType(_orderType)} | ${PosLabels.common.ticket} ${widget.order.ticketNumber}',
      ),
      userName: userName.isEmpty ? PosLabels.common.adminUser : userName,
      statusLabel: role.isEmpty ? null : role,
      showStatusIndicator: _session.isAuthenticated,
      onMenuTap: _openFunctionsMenu,
    );
  }

  void _openFunctionsMenu() {
    showPosFunctionsDrawer(
      context,
      onCreateReport: () {
        if (!mounted) return;
        showPosSalesReportDialog(context);
      },
    );
  }

  Widget _buildOrderPanel() {
    return Container(
      width: 450,
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Column(
        children: [
          SizedBox(
              height: 56,
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(PosLabels.order.currentOrder,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700))))),
          if (_activeTab == PosTab.receipt) ...[
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB)),
                      bottom: BorderSide(color: Color(0xFFE5E7EB)))),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final guest in _guests)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilledButton(
                        onPressed: () => setState(() {
                          _currentGuest = guest.id;
                          _emitOrderChanged();
                        }),
                        style: FilledButton.styleFrom(
                            backgroundColor: _currentGuest == guest.id
                                ? const Color(0xFF2563EB)
                                : Colors.white,
                            foregroundColor: _currentGuest == guest.id
                                ? Colors.white
                                : const Color(0xFF374151),
                            side: const BorderSide(color: Color(0xFFD1D5DB))),
                        child: Text(_displayGuestName(guest.name),
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  OutlinedButton.icon(
                      onPressed: _addGuest,
                      icon: const Icon(Icons.person_add_alt_1, size: 14),
                      label: Text(PosLabels.common.addGuest,
                          style: const TextStyle(fontSize: 12))),
                ],
              ),
            ),
            _buildOrderHeader(),
            Expanded(child: _buildOrderList()),
            _buildOrderFooter(),
          ] else ...[
            Expanded(child: _buildClientForm()),
          ],
        ],
      ),
    );
  }

  Widget _buildClientForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        Text(
          PosLabels.order.clientInformation,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 12),
        _ClientField(
          label: 'Buscar cliente (nombre o teléfono)',
          child: TextField(
            controller: _customerSearchController,
            onChanged: _handleCustomerSearchChanged,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              hintText: 'Escribe nombre o teléfono',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _isSearchingCustomers
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : (_customerSearchController.text.trim().isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: _clearCustomerSearch,
                        )
                      : null),
            ),
          ),
        ),
        if (_customerSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _customerSuggestions.length; i++) ...[
                  ListTile(
                    dense: true,
                    visualDensity:
                        const VisualDensity(horizontal: 0, vertical: -2),
                    title: Text(
                      _customerSuggestions[i].displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _customerSuggestions[i].phone.isNotEmpty
                          ? _customerSuggestions[i].phone
                          : 'Sin teléfono',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.north_west, size: 16),
                    onTap: () =>
                        _selectExistingCustomer(_customerSuggestions[i]),
                  ),
                  if (i < _customerSuggestions.length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _ClientField(
          label: PosLabels.order.customerName,
          child: TextField(
            controller: _customerNameController,
            onChanged: (_) {
              _selectedCustomerId = null;
              _emitOrderChanged();
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              hintText: PosLabels.order.enterCustomerName,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ClientField(
          label: PosLabels.order.phoneNumber,
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            onChanged: (_) {
              _selectedCustomerId = null;
              _emitOrderChanged();
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              hintText: PosLabels.order.enterPhoneNumber,
            ),
          ),
        ),
        if (_isDelivery) ...[
          const SizedBox(height: 12),
          _ClientField(
            label: PosLabels.order.addressRequired,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedDeliveryAddress,
              isExpanded: true,
              items: _deliveryAddresses
                  .map(
                    (address) => DropdownMenuItem<String>(
                      value: address,
                      child: Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                setState(() => _applySelectedDeliveryAddress(value));
                _emitOrderChanged();
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: PosLabels.order.selectAddress,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _showAddAddressDialog,
              icon: const Icon(Icons.add_location_alt_outlined, size: 16),
              label: Text(PosLabels.order.addNewAddress),
            ),
          ),
          const SizedBox(height: 12),
          _ClientField(
            label: PosLabels.order.deliveryNotes,
            child: TextField(
              controller: _deliveryNotesController,
              minLines: 2,
              maxLines: 4,
              onChanged: (_) => _emitOrderChanged(),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: PosLabels.order.deliveryNotesHint,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ClientField(
            label: PosLabels.order.deliveryShippingCost,
            child: TextField(
              controller: _deliveryShippingController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _emitOrderChanged()),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                prefixText: r'$ ',
                hintText: PosLabels.order.deliveryShippingCostHint,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _handleCustomerSearchChanged(String value) {
    _customerSearchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _isSearchingCustomers = false;
        _customerSuggestions = const [];
      });
      return;
    }
    _customerSearchDebounce = Timer(const Duration(milliseconds: 320), () {
      _searchCustomers(query);
    });
  }

  Future<void> _searchCustomers(String query) async {
    final isReady = await _ensureCustomerSearchSession();
    if (!isReady) {
      if (!mounted) return;
      setState(() {
        _customerSuggestions = const [];
        _isSearchingCustomers = false;
      });
      return;
    }
    setState(() {
      _isSearchingCustomers = true;
    });
    final digitsOnly = query.replaceAll(RegExp(r'[^0-9]'), '');
    List<_CustomerSuggestion> suggestions = const [];
    try {
      final response = await _session.apiClient.get(
        '/customers/search?q=${Uri.encodeQueryComponent(query)}&limit=8',
      );
      if (!mounted) return;
      if (response['success'] == true) {
        final data = response['data'];
        final rows = data is List ? data : const [];
        suggestions = rows
            .whereType<Map>()
            .map(
              (row) => _CustomerSuggestion.fromJson(
                row.map((key, value) => MapEntry('$key', value)),
              ),
            )
            .toList(growable: false);
      }
    } catch (_) {
      // Seguimos con fallback por teléfono para no bloquear la búsqueda.
    }

    if (suggestions.isEmpty && digitsOnly.length >= 7) {
      try {
        final byPhoneResponse =
            await _session.apiClient.get('/customers/by-phone/$digitsOnly');
        if (byPhoneResponse['success'] == true &&
            byPhoneResponse['data'] is Map) {
          suggestions = [
            _CustomerSuggestion.fromJson(
              (byPhoneResponse['data'] as Map).cast<String, dynamic>(),
            ),
          ];
        }
      } catch (_) {
        // Si también falla by-phone, dejamos sugerencias vacías.
      }
    }

    if (!mounted) return;
    setState(() {
      _customerSuggestions = suggestions;
      _isSearchingCustomers = false;
    });
  }

  Future<bool> _ensureCustomerSearchSession() async {
    if (_session.isAuthenticated) {
      return true;
    }

    final response =
        await _session.apiClient.post('/auth/login', <String, dynamic>{
      'pin': '1234',
      'sucursal_id': 1,
      'plataforma': 'pos_flutter',
    });
    if (response['success'] != true) {
      return false;
    }

    final data = (response['data'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final token = '${data['token'] ?? ''}'.trim();
    final user =
        (data['user'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final branchIdRaw = user['sucursal_id'];
    final userIdRaw = user['id'];
    final branchId = branchIdRaw is num
        ? branchIdRaw.toInt()
        : int.tryParse('$branchIdRaw') ?? 1;
    final userId =
        userIdRaw is num ? userIdRaw.toInt() : int.tryParse('$userIdRaw') ?? 1;
    final fullName = '${user['nombre'] ?? ''} ${user['apellido'] ?? ''}'.trim();
    final role = '${user['rol'] ?? 'cajero'}'.trim();

    if (token.isEmpty) {
      return false;
    }

    _session.setAuth(
      token: token,
      branchId: branchId,
      userId: userId,
      userName: fullName,
      role: role.isEmpty ? 'cajero' : role,
    );
    return true;
  }

  void _clearCustomerSearch() {
    _customerSearchDebounce?.cancel();
    setState(() {
      _customerSearchController.clear();
      _customerSuggestions = const [];
      _isSearchingCustomers = false;
    });
  }

  String _formatAddressLabel(Map<String, dynamic> raw) {
    final parts = <String>[
      '${raw['calle'] ?? ''}'.trim(),
      '${raw['numero_exterior'] ?? ''}'.trim(),
      '${raw['colonia'] ?? ''}'.trim(),
      '${raw['ciudad'] ?? ''}'.trim(),
    ].where((part) => part.isNotEmpty).toList(growable: false);
    if (parts.isNotEmpty) return parts.join(', ');
    return '${raw['alias'] ?? 'Dirección'}'.trim();
  }

  double? _toNullableDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value');
  }

  _DeliveryAddressOption _addressOptionFromJson(Map<String, dynamic> raw) {
    final label = _formatAddressLabel(raw);
    final idRaw = raw['id'];
    final id = idRaw is num ? idRaw.toInt() : int.tryParse('$idRaw') ?? 0;
    return _DeliveryAddressOption(
      label: label,
      address: '${raw['calle'] ?? ''}'.trim().isNotEmpty
          ? '${raw['calle']}'.trim()
          : label,
      id: id,
      placeId: '${raw['place_id'] ?? ''}'.trim().isEmpty
          ? null
          : '${raw['place_id']}'.trim(),
      latitude: _toNullableDouble(raw['lat']),
      longitude: _toNullableDouble(raw['lng']),
      reference: null,
      details: () {
        final instructions = '${raw['instrucciones_entrega'] ?? ''}'.trim();
        if (instructions.isNotEmpty) {
          return instructions;
        }
        final legacyReference = '${raw['referencia'] ?? ''}'.trim();
        return legacyReference.isNotEmpty ? legacyReference : null;
      }(),
    );
  }

  void _applySelectedDeliveryAddress(String? label) {
    _selectedDeliveryAddress = label;
    if (label == null || label.trim().isEmpty) {
      _selectedCustomerAddressId = null;
      return;
    }

    final option = _deliveryAddressOptionsByLabel[label];
    _selectedCustomerAddressId =
        option != null && option.id > 0 ? option.id : null;
  }

  void _selectExistingCustomer(_CustomerSuggestion customer) {
    final options = customer.addresses
        .map(_addressOptionFromJson)
        .where((option) => option.label.trim().isNotEmpty)
        .toList(growable: false);
    final labels =
        options.map((option) => option.label).toList(growable: false);
    final addressIds = <String, int>{
      for (final option in options)
        if (option.id > 0) option.label: option.id,
    };
    final addressOptions = <String, _DeliveryAddressOption>{
      for (final option in options) option.label: option,
    };

    setState(() {
      _selectedCustomerId = customer.id;
      _customerNameController.text = customer.displayName;
      _phoneController.text = customer.phone;
      _customerSuggestions = const [];
      _customerSearchController.text =
          customer.phone.isNotEmpty ? customer.phone : customer.displayName;
      if (labels.isNotEmpty) {
        _deliveryAddresses = labels;
        _deliveryAddressIdsByLabel
          ..clear()
          ..addAll(addressIds);
        _deliveryAddressOptionsByLabel
          ..clear()
          ..addAll(addressOptions);
        _applySelectedDeliveryAddress(labels.first);
        final selectedOption = _deliveryAddressOptionsByLabel[labels.first];
        if ((selectedOption?.details ?? '').trim().isNotEmpty &&
            _deliveryNotesController.text.trim().isEmpty) {
          _deliveryNotesController.text = selectedOption!.details!.trim();
        }
      }
    });

    _emitOrderChanged();
  }

  Future<void> _showAddAddressDialog() async {
    try {
      await _ensureCustomerSearchSession();
    } catch (_) {
      // En esta fase no bloqueamos el flujo de captura manual de dirección.
    }
    if (!mounted) return;
    final selected = await showDialog<_DeliveryAddressOption>(
      context: context,
      builder: (context) => _AddressCaptureDialog(
        addAddressLabel: PosLabels.order.addAddress,
        addAddressHint: PosLabels.order.addAddressHint,
        detailsLabel: 'Detalles de domicilio',
        detailsHint: 'Entre calles, color de casa, indicaciones...',
        coordinatesLabel: 'Coordenadas (opcional)',
        coordinatesHint: 'Ej: 32.465617, -114.781193',
        coordinatesExample: 'Ejemplo: 32.465617, -114.781193',
        cancelLabel: PosLabels.buttons.cancel,
        addLabel: PosLabels.buttons.add,
      ),
    );
    if (selected == null || selected.label.trim().isEmpty) return;
    var addressOption = selected;

    final customerId = _selectedCustomerId ?? 0;
    if (customerId > 0) {
      try {
        final response = await _session.apiClient.post(
          '/customers/$customerId/addresses',
          <String, dynamic>{
            'alias': 'Dirección',
            'calle': addressOption.address,
            'referencia': null,
            'instrucciones_entrega': addressOption.details,
            'place_id': addressOption.placeId,
            'lat': addressOption.latitude,
            'lng': addressOption.longitude,
            'activa': 1,
          },
        );

        if (response['success'] == true && response['data'] is Map) {
          addressOption = _addressOptionFromJson(
            (response['data'] as Map).cast<String, dynamic>(),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message']?.toString() ??
                    'No se pudo guardar la dirección en base de datos.',
              ),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo guardar la dirección en base de datos.',
              ),
            ),
          );
        }
      }
    }

    setState(() {
      if (!_deliveryAddresses.contains(addressOption.label)) {
        _deliveryAddresses = [..._deliveryAddresses, addressOption.label];
      }
      _deliveryAddressOptionsByLabel[addressOption.label] = addressOption;
      if (addressOption.id > 0) {
        _deliveryAddressIdsByLabel[addressOption.label] = addressOption.id;
      }
      _applySelectedDeliveryAddress(addressOption.label);
      if ((addressOption.details ?? '').trim().isNotEmpty &&
          _deliveryNotesController.text.trim().isEmpty) {
        _deliveryNotesController.text = addressOption.details!.trim();
      }
    });
    _emitOrderChanged();
  }

  String _resolveDeliveryReferenceForMessage(AppOrder order) {
    final optionDetails =
        (_selectedDeliveryAddressOption?.details ?? '').trim();
    if (optionDetails.isNotEmpty) {
      return optionDetails;
    }
    final storedDetails = (order.deliveryAddressDetails ?? '').trim();
    if (storedDetails.isNotEmpty) {
      return storedDetails;
    }
    return (order.deliveryAddressReference ?? '').trim();
  }

  String _resolveDeliveryObservationsForMessage(AppOrder order) {
    final notes = (order.deliveryNotes ?? '').trim();
    final reference = _resolveDeliveryReferenceForMessage(order);
    if (notes.isEmpty || notes == reference) {
      return '';
    }
    return notes;
  }

  List<String> _orderItemDetailLinesForWhatsApp(OrderItemData item) {
    final lines = <String>[];
    if (item.hamburgerConfig != null) {
      lines.addAll(_burgerDetailLines(item.hamburgerConfig!));
    } else if (item.wingsConfig != null) {
      lines.addAll(_wingsDetailLines(item.wingsConfig!));
    } else if (item.saladConfig != null) {
      lines.addAll(_saladDetailLines(item.saladConfig!));
    } else if (item.garlicBreadConfig != null) {
      lines.addAll(_garlicBreadDetailLines(item.garlicBreadConfig!));
    } else if (item.spaghettiConfig != null) {
      lines.addAll(_spaghettiDetailLines(item.spaghettiConfig!));
    } else if (item.pizzaConfig != null) {
      lines.addAll(_pizzaDetailLinesForTicket(item.pizzaConfig!));
    }

    final comment = (item.comment ?? '').trim();
    if (comment.isNotEmpty) {
      lines.add(comment);
    }
    return lines;
  }

  String _buildWhatsAppMessage(AppOrder order) {
    final mapsLink = buildGoogleMapsLink(
      latitude: order.deliveryAddressLatitude,
      longitude: order.deliveryAddressLongitude,
      address: order.deliveryAddress,
    );
    final items = order.items
        .map(
          (item) => WhatsAppOrderLineItem(
            quantity: item.quantity,
            name: item.name,
            modifiers: _orderItemDetailLinesForWhatsApp(item),
          ),
        )
        .toList(growable: false);

    return buildWhatsAppDeliveryMessage(
      WhatsAppDeliveryMessagePayload(
        ticket: order.ticketNumber,
        customer: (order.customerName ?? '').trim(),
        phone: (order.customerPhone ?? '').trim(),
        address: (order.deliveryAddress ?? '').trim(),
        reference: _resolveDeliveryReferenceForMessage(order),
        mapsLink: mapsLink,
        items: items,
        total: orderGrandTotal(order),
        observations: _resolveDeliveryObservationsForMessage(order),
      ),
    );
  }

  Future<void> _copyOrderForWhatsApp() async {
    final order = _composeOrder();
    final message = _buildWhatsAppMessage(order);
    if (message.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo generar el mensaje de WhatsApp.')),
      );
      return;
    }

    final copied = await copyTextToClipboard(message);
    if (!mounted) return;
    if (copied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido copiado para WhatsApp')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo copiar el mensaje de WhatsApp.')),
      );
    }
  }

  Future<void> _openWhatsAppWeb() async {
    final launched = await openWhatsAppWeb();
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible abrir WhatsApp Web.')),
      );
    }
  }

  Widget _buildOrderHeader() {
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          Expanded(
              flex: 40,
              child: Text(PosLabels.table.name,
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700))),
          Expanded(
              flex: 22,
              child: Text(PosLabels.table.qty,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700))),
          Expanded(
              flex: 18,
              child: Text(PosLabels.table.price,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700))),
          Expanded(
              flex: 18,
              child: Text(PosLabels.table.total,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700))),
          Expanded(flex: 8, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    if (_orderItems.isEmpty) {
      return Center(
          child: Text(PosLabels.common.noItemsInOrder,
              style: TextStyle(color: Color(0xFF9CA3AF))));
    }

    return ListView(
      children: [
        for (final guest in _guests) ...[
          if (_orderItems.any((item) => item.guestId == guest.id) &&
              _guests.length > 1)
            Container(
                color: const Color(0xFFEFF6FF),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(_displayGuestName(guest.name),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8)))),
          for (final item in _orderItems
              .where((orderItem) => orderItem.guestId == guest.id))
            _OrderItemRow(
              item: item,
              onTap: () => _editItemComment(item),
              onMinus: () => _updateQuantity(item.id, item.guestId, -1),
              onPlus: () => _updateQuantity(item.id, item.guestId, 1),
              onDelete: () => _removeItem(item.id, item.guestId),
            ),
        ],
      ],
    );
  }

  Widget _buildOrderFooter() {
    final pricing = _pricing;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Column(
        children: [
          if (pricing.promoApplied) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    pricing.promoLabel ?? PosLabels.categories.promotions,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF047857),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${pricing.promoAdjustment >= 0 ? '+' : '-'}\$${pricing.promoAdjustment.abs().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF047857),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          if (_isDelivery) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        PosLabels.order.deliveryShippingCost,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        PosLabels.order.deliveryShippingNotInRegister,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${_deliveryShippingParsed.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Row(children: [
            Text(PosLabels.common.total,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('\$${_orderTotal.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w700))
          ]),
          if (_isDelivery) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _orderItems.isEmpty ? null : _copyOrderForWhatsApp,
                    icon: const Icon(Icons.content_copy_rounded, size: 16),
                    label: const Text('Copiar pedido para WhatsApp'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _orderItems.isEmpty ? null : _openWhatsAppWeb,
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Abrir WhatsApp'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: FilledButton.icon(
                      onPressed: _orderItems.isEmpty ? null : _sendToKitchen,
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: Text(PosLabels.common.sendToKitchen),
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white))),
              const SizedBox(width: 8),
              Expanded(
                  child: FilledButton(
                      onPressed: _orderItems.isEmpty ? null : _pay,
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white),
                      child: Text(PosLabels.common.pay))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductPanel() {
    if (_selectedCategory == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 1050 ? 5 : 4;
                  return GridView.builder(
                    itemCount: categories.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 142,
                    ),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return InkWell(
                        onTap: () {
                          if (category.id == 'pizzas') {
                            _openPizzaBuilder();
                            return;
                          }
                          if (category.id == 'hamburgers') {
                            _openHamburgerBuilder();
                            return;
                          }
                          if (category.id == 'wings') {
                            _openWingsBuilder();
                            return;
                          }
                          if (category.id == 'boneless') {
                            _openBonelessBuilder();
                            return;
                          }
                          if (category.id == 'spaghetti') {
                            _openSpaghettiBuilder();
                            return;
                          }
                          if (category.id == 'extras') {
                            _openManualExtraEntry();
                            return;
                          }
                          setState(() {
                            _selectedCategory = category.id;
                            _selectedDrinkGroup = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Color(0x22000000), blurRadius: 6)
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 88,
                                width: double.infinity,
                                child: _buildCardImage(category.image),
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 6, 8, 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        category.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickComplementsSection(),
          ],
        ),
      );
    }

    final selectedCategoryName = categories
        .firstWhere((category) => category.id == _selectedCategory)
        .name;
    final isDrinkGroupView = _isDrinksCategory && _selectedDrinkGroup != null;
    final headerTitle =
        isDrinkGroupView ? _selectedDrinkGroup! : selectedCategoryName;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            OutlinedButton.icon(
                onPressed: () => setState(() {
                      _selectedCategory = null;
                      _selectedDrinkGroup = null;
                    }),
                icon: const Icon(Icons.chevron_left),
                label: Text(PosLabels.order.backToCategories)),
            if (isDrinkGroupView) ...[
              const SizedBox(width: 10),
              OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedDrinkGroup = null),
                  icon: const Icon(Icons.chevron_left),
                  label: Text(PosLabels.order.backToDrinkGroups)),
            ],
            const SizedBox(width: 10),
            Text(headerTitle,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w700))
          ]),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              itemCount: _isDrinksCategory
                  ? (isDrinkGroupView
                      ? _currentDrinkOptions.length
                      : _drinkCatalog.length)
                  : _currentProducts.length,
              gridDelegate:
                  (!_isDrinksCategory && _selectedCategory == 'sauces')
                      ? const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 290,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 250,
                        )
                      : const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
              itemBuilder: (context, index) {
                if (_isDrinksCategory) {
                  if (!isDrinkGroupView) {
                    final drinkEntry = _drinkCatalog[index];
                    return InkWell(
                      onTap: () {
                        if (drinkEntry.isGroup) {
                          setState(() => _selectedDrinkGroup = drinkEntry.name);
                          return;
                        }
                        _addDirectDrinkProductToOrder(drinkEntry);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Color(0x22000000), blurRadius: 8)
                            ]),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              drinkEntry.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              drinkEntry.isGroup
                                  ? 'Grupo'
                                  : '\$${(drinkEntry.price ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final option = _currentDrinkOptions[index];
                  return InkWell(
                    onTap: () => _addDrinkToOrder(
                      group: _selectedDrinkGroup!,
                      option: option,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Color(0x22000000), blurRadius: 8)
                          ]),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(option.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Text('\$${option.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 23,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  );
                }

                final product = _currentProducts[index];
                return InkWell(
                  onTap: () async {
                    if (product.categoryId == 'pizzas') {
                      _openPizzaBuilder();
                      return;
                    }
                    if (product.categoryId == 'hamburgers') {
                      _openHamburgerBuilder();
                      return;
                    }
                    if (product.categoryId == 'wings') {
                      _openWingsBuilder();
                      return;
                    }
                    if (product.categoryId == 'boneless') {
                      _openBonelessBuilder();
                      return;
                    }
                    if (product.categoryId == 'spaghetti') {
                      _openSpaghettiBuilder();
                      return;
                    }
                    if (product.categoryId == 'extras') {
                      _openManualExtraEntry();
                      return;
                    }
                    if (product.categoryId == 'menu_estadio') {
                      await _handleMenuEstadioTap(product);
                      return;
                    }
                    if (product.categoryId == 'complements' &&
                        product.name == 'Ensalada') {
                      _openEnsaladaBuilder();
                      return;
                    }
                    if (product.categoryId == 'complements' &&
                        product.name == 'Panes de ajo') {
                      _openPanesAjoBuilder();
                      return;
                    }
                    _addToOrder(product);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: Color(0x22000000), blurRadius: 8)
                        ]),
                    clipBehavior: Clip.antiAlias,
                    child: product.image != null
                        ? Column(
                            children: [
                              Builder(
                                builder: (context) {
                                  final isSauceCard =
                                      product.categoryId == 'sauces';
                                  if (isSauceCard) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(8, 8, 8, 6),
                                      child: Container(
                                        width: double.infinity,
                                        height: 132,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: const Color(0xFFE5E7EB)),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: _buildCardImage(product.image!),
                                      ),
                                    );
                                  }
                                  return SizedBox(
                                    height: 96,
                                    width: double.infinity,
                                    child: _buildCardImage(product.image!),
                                  );
                                },
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 6, 10, 8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        product.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '\$${product.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: Color(0xFF2563EB),
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(product.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 8),
                                Text('\$${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 23,
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickComplementsSection() {
    if (_quickComplementProducts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complementos rapidos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final cardWidth = (maxWidth / 5) - 8;
              final effectiveWidth = cardWidth.clamp(130.0, 200.0);
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _quickComplementProducts
                    .map(
                      (product) => MouseRegion(
                        onEnter: (_) => setState(() {
                          _hoveredQuickComplementId = product.id;
                        }),
                        onExit: (_) => setState(() {
                          if (_hoveredQuickComplementId == product.id) {
                            _hoveredQuickComplementId = null;
                          }
                        }),
                        child: InkWell(
                          onTap: () => _handleQuickComplementTap(product),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width: effectiveWidth,
                            height: 108,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0x22000000),
                                  blurRadius:
                                      _hoveredQuickComplementId == product.id
                                          ? 10
                                          : 6,
                                ),
                              ],
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 72,
                                  width: double.infinity,
                                  child: _buildCardImage(
                                      _quickComplementImage(product.name)),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        product.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CustomerSuggestion {
  const _CustomerSuggestion({
    required this.id,
    required this.displayName,
    required this.phone,
    required this.addresses,
  });

  final int id;
  final String displayName;
  final String phone;
  final List<Map<String, dynamic>> addresses;

  factory _CustomerSuggestion.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is num ? idRaw.toInt() : int.tryParse('$idRaw') ?? 0;
    final name = '${json['nombre'] ?? ''}'.trim();
    final lastName = '${json['apellidos'] ?? ''}'.trim();
    final displayName =
        [name, lastName].where((part) => part.isNotEmpty).join(' ').trim();
    final phone = '${json['telefono'] ?? ''}'.trim();
    final addressesRaw = json['addresses'];
    final addresses = addressesRaw is List
        ? addressesRaw
            .whereType<Map>()
            .map(
                (row) => Map<String, dynamic>.from(row.cast<String, dynamic>()))
            .toList(growable: false)
        : const <Map<String, dynamic>>[];
    return _CustomerSuggestion(
      id: id,
      displayName: displayName.isNotEmpty ? displayName : 'Cliente $id',
      phone: phone,
      addresses: addresses,
    );
  }
}

class _DeliveryAddressOption {
  const _DeliveryAddressOption({
    required this.label,
    required this.address,
    required this.id,
    this.placeId,
    this.latitude,
    this.longitude,
    this.reference,
    this.details,
  });

  final String label;
  final String address;
  final int id;
  final String? placeId;
  final double? latitude;
  final double? longitude;
  final String? reference;
  final String? details;
}

class _AddressCaptureDialog extends StatefulWidget {
  const _AddressCaptureDialog({
    required this.addAddressLabel,
    required this.addAddressHint,
    required this.detailsLabel,
    required this.detailsHint,
    required this.coordinatesLabel,
    required this.coordinatesHint,
    required this.coordinatesExample,
    required this.cancelLabel,
    required this.addLabel,
  });

  final String addAddressLabel;
  final String addAddressHint;
  final String detailsLabel;
  final String detailsHint;
  final String coordinatesLabel;
  final String coordinatesHint;
  final String coordinatesExample;
  final String cancelLabel;
  final String addLabel;

  @override
  State<_AddressCaptureDialog> createState() => _AddressCaptureDialogState();
}

class _AddressCaptureDialogState extends State<_AddressCaptureDialog> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _coordinatesController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _addressController.dispose();
    _detailsController.dispose();
    _coordinatesController.dispose();
    super.dispose();
  }

  void _submit() {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      setState(() {
        _errorMessage = 'La dirección es obligatoria.';
      });
      return;
    }

    final parsedCoordinates =
        parseCoordinatesInput(_coordinatesController.text);
    if ((parsedCoordinates.error ?? '').trim().isNotEmpty) {
      setState(() {
        _errorMessage = parsedCoordinates.error;
      });
      return;
    }

    final latitude = parsedCoordinates.latitude;
    final longitude = parsedCoordinates.longitude;

    final details = _detailsController.text.trim();

    Navigator.of(context).pop(
      _DeliveryAddressOption(
        label: address,
        address: address,
        id: 0,
        placeId: null,
        latitude: latitude,
        longitude: longitude,
        reference: null,
        details: details.isEmpty ? null : details,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.addAddressLabel),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  hintText: widget.addAddressHint,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _detailsController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: widget.detailsLabel,
                  hintText: widget.detailsHint,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _coordinatesController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  labelText: widget.coordinatesLabel,
                  hintText: widget.coordinatesHint,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.coordinatesExample,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              if ((_errorMessage ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.addLabel),
        ),
      ],
    );
  }
}

class _OrderTypeSelector extends StatelessWidget {
  const _OrderTypeSelector({
    required this.orderType,
    required this.onChanged,
  });

  final String orderType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option({
      required String value,
      required String label,
    }) {
      final active = orderType == value;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(9),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF2563EB) : Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 240,
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Row(
        children: [
          option(
            value: _PosWindowViewState._toGoType,
            label: PosLabels.common.toGo,
          ),
          const SizedBox(width: 4),
          option(
            value: _PosWindowViewState._deliveryType,
            label: PosLabels.common.delivery,
          ),
        ],
      ),
    );
  }
}

class _ClientField extends StatelessWidget {
  const _ClientField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.item,
    required this.onTap,
    required this.onMinus,
    required this.onPlus,
    required this.onDelete,
  });

  final OrderItemData item;
  final VoidCallback onTap;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onDelete;

  bool get _isCustomPizza {
    final config = item.pizzaConfig;
    if (config == null) return false;
    return config.selectionMode == PizzaSelectionMode.ingredients ||
        config.specialty == 'Pizza personalizada';
  }

  bool get _isHalfHalfPizza {
    final config = item.pizzaConfig;
    if (config == null) return false;
    return config.selectionMode == PizzaSelectionMode.halfHalf;
  }

  String _burgerSideLabel(HamburgerSideOption side) {
    switch (side) {
      case HamburgerSideOption.conPapas:
        return 'CON PAPAS';
      case HamburgerSideOption.sinPapas:
        return 'SIN PAPAS';
      case HamburgerSideOption.conAros:
        return 'CON AROS';
    }
  }

  bool _isVegetableIngredient(String ingredient) {
    const vegetables = {'Pepinillos', 'Cebolla', 'Tomate', 'Lechuga'};
    return vegetables.contains(ingredient);
  }

  List<String> _burgerUnitLines(HamburgerUnitConfigData unit) {
    final lines = <String>[];
    if (unit.usedSinVerduraQuickAction) {
      lines.add('SIN VERDURA');
      for (final removed in unit.removedIngredients) {
        if (!_isVegetableIngredient(removed)) {
          lines.add('SIN ${removed.toUpperCase()}');
        }
      }
    } else {
      for (final removed in unit.removedIngredients) {
        lines.add('SIN ${removed.toUpperCase()}');
      }
    }
    for (final extra in unit.extraIngredients) {
      lines.add(extra.toUpperCase());
    }
    if (unit.cutOption == HamburgerCutOption.partidaMitad) {
      lines.add('PARTIDA A LA MITAD');
    }
    return lines;
  }

  List<String> _hamburgerDetailLines(HamburgerConfigData config) {
    if (config.isSpecialCombo) {
      final unit1 = config.burger1;
      final unit2 = config.burger2;
      final lines1 = unit1 == null ? const <String>[] : _burgerUnitLines(unit1);
      final lines2 = unit2 == null ? const <String>[] : _burgerUnitLines(unit2);
      final sideChanged = config.side != HamburgerSideOption.conPapas;
      if (!sideChanged && lines1.isEmpty && lines2.isEmpty) {
        return const [];
      }
      final lines = <String>[];
      if (sideChanged) {
        lines.add(_burgerSideLabel(config.side));
      }
      if (unit1 != null) {
        lines.add('Hamburguesa 1');
        lines.addAll(lines1);
      }
      if (unit2 != null) {
        lines.add('Hamburguesa 2');
        lines.addAll(lines2);
      }
      return lines;
    }

    final lines = <String>[];
    if (config.usedSinVerduraQuickAction) {
      lines.add('SIN VERDURA');
      for (final removed in config.removedIngredients) {
        if (!_isVegetableIngredient(removed)) {
          lines.add('SIN ${removed.toUpperCase()}');
        }
      }
    } else {
      for (final removed in config.removedIngredients) {
        lines.add('SIN ${removed.toUpperCase()}');
      }
    }
    for (final extra in config.extraIngredients) {
      lines.add(extra.toUpperCase());
    }
    if (config.cutOption == HamburgerCutOption.partidaMitad) {
      lines.add('PARTIDA A LA MITAD');
    }
    if (config.side != HamburgerSideOption.conPapas) {
      lines.add(_burgerSideLabel(config.side));
    }
    return lines;
  }

  List<String> _pizzaDetailLines(PizzaConfigData config) {
    final lines = <String>[];
    if (_isHalfHalfPizza) {
      final half1Mode = config.half1Mode ?? PizzaHalfSelectionMode.specialty;
      final half2Mode = config.half2Mode ?? PizzaHalfSelectionMode.specialty;
      final half1Label = half1Mode == PizzaHalfSelectionMode.specialty
          ? (config.half1Specialty ?? config.half1 ?? '-')
          : config.half1Ingredients.join(', ');
      final half2Label = half2Mode == PizzaHalfSelectionMode.specialty
          ? (config.half2Specialty ?? config.half2 ?? '-')
          : config.half2Ingredients.join(', ');
      if (half1Label.trim().isNotEmpty) {
        lines.add(
            'Mitad 1 (${half1Mode == PizzaHalfSelectionMode.specialty ? 'Especialidad' : 'Ingredientes'}): $half1Label');
      }
      if (half2Label.trim().isNotEmpty) {
        lines.add(
            'Mitad 2 (${half2Mode == PizzaHalfSelectionMode.specialty ? 'Especialidad' : 'Ingredientes'}): $half2Label');
      }
    }
    if (_isCustomPizza && config.ingredients.isNotEmpty) {
      lines.add('Ingredientes: ${config.ingredients.join(', ')}');
    }
    if (config.extraIngredients.isNotEmpty) {
      lines.add('Extras: ${config.extraIngredients.join(', ')}');
    }
    if (config.includePromoGarlicBread) {
      lines.add('Panes de ajo promo');
    }

    if (config.crustEdge == 'Orilla Mitad y Mitad') {
      lines.add(
          'Orilla: 1/2 ${config.crustHalf1 ?? 'Queso crema'} · 1/2 ${config.crustHalf2 ?? 'Queso mozzarella'}');
    } else if (config.crustEdge != 'Regular') {
      lines.add('Orilla: ${config.crustEdge}');
    }
    if (config.breadType != 'Regular') {
      lines.add('Pan: ${config.breadType}');
    }
    if (config.dorada) {
      lines.add('Dorada');
    }
    return lines;
  }

  String _wingsBoneLabel(WingsBoneType boneType) {
    switch (boneType) {
      case WingsBoneType.unHueso:
        return '1 HUESO';
      case WingsBoneType.dosHuesos:
        return '2 HUESOS';
    }
  }

  String _shortSauceName(String value) {
    return value.replaceFirst(RegExp(r'^Salsa\s+', caseSensitive: false), '');
  }

  String? _wingsSauceLine(WingsConfigData config) {
    final hasSingleSauce = config.sauce?.trim().isNotEmpty ?? false;
    final hasHalfSauce1 = config.sauceHalf1?.trim().isNotEmpty ?? false;
    final hasHalfSauce2 = config.sauceHalf2?.trim().isNotEmpty ?? false;

    if (config.sauceMode == WingsSauceMode.mitadMitad &&
        hasHalfSauce1 &&
        hasHalfSauce2) {
      final baseLine =
          'MITAD ${_shortSauceName(config.sauceHalf1!).toUpperCase()} / '
          '${_shortSauceName(config.sauceHalf2!).toUpperCase()}';
      return config.sauceOnSide ? '$baseLine APARTE' : baseLine;
    }

    if (!hasSingleSauce) return null;
    final baseLine = 'SALSA ${_shortSauceName(config.sauce!).toUpperCase()}';
    return config.sauceOnSide ? '$baseLine APARTE' : baseLine;
  }

  List<String> _wingsDetailLines(WingsConfigData config) {
    final lines = <String>[];
    if (config.naturales) {
      lines.add('NATURALES');
      if (config.sauceOnSide) {
        final sauceLine = _wingsSauceLine(config);
        if (sauceLine != null) {
          lines.add(sauceLine);
        }
      }
    } else {
      final sauceLine = _wingsSauceLine(config);
      if (sauceLine != null) {
        lines.add(sauceLine);
      }
    }
    if (config.juicy) {
      lines.add('JUGOSAS');
    }
    if (config.doradas) {
      lines.add('DORADAS');
    }
    if (config.boneType != null) {
      lines.add(_wingsBoneLabel(config.boneType!));
    }
    if (config.sinApio) {
      lines.add('SIN APIO');
    }
    if (config.sinZanahoria) {
      lines.add('SIN ZANAHORIA');
    }
    return lines;
  }

  List<String> _saladDetailLines(SaladConfigData config) {
    final lines = <String>[];
    for (final removed in config.removedIngredients) {
      lines.add('SIN ${removed.toUpperCase()}');
    }
    for (final addOn in config.addOns) {
      lines.add('CON ${addOn.toUpperCase()}');
    }
    return lines;
  }

  List<String> _garlicBreadDetailLines(GarlicBreadConfigData config) {
    final type = config.type.trim();
    if (type.isEmpty || type == 'Normales') {
      return const [];
    }
    if (type == '2 y 2 (crema y mozzarella)') {
      return const ['2 Y 2 (QUESO CREMA / QUESO MOZZARELLA)'];
    }
    return [type.toUpperCase()];
  }

  List<String> _spaghettiDetailLines(SpaghettiConfigData config) {
    final lines = <String>[];
    if (config.accompaniment == 'Papas') {
      lines.add('CON PAPAS');
    } else if (config.garlicBreadType != null &&
        config.garlicBreadType != 'Normales') {
      lines.add(
        'PANES DE AJO RELLENOS DE ${config.garlicBreadType!.toUpperCase()}',
      );
    }
    for (final removedIngredient in config.removedIngredients) {
      lines.add('SIN ${removedIngredient.toUpperCase()}');
    }
    if (config.sinQueso) {
      lines.add('SIN QUESO');
    }
    if (config.sinMantequilla) {
      lines.add('SIN MANTEQUILLA');
    }
    if (config.pocaSalsa) {
      lines.add('POCA SALSA');
    }
    if (config.quesoDorado) {
      lines.add('QUESO DORADO');
    }
    for (final extra in config.extras) {
      lines.add('EXTRA ${extra.toUpperCase()}');
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final hasComment = (item.comment?.trim().isNotEmpty ?? false);
    final pizzaConfig = item.pizzaConfig;
    final hamburgerConfig = item.hamburgerConfig;
    final wingsConfig = item.wingsConfig;
    final saladConfig = item.saladConfig;
    final spaghettiConfig = item.spaghettiConfig;
    final garlicBreadConfig = item.garlicBreadConfig;
    final subtitleLines = <String>[
      if (hasComment) item.comment!.trim(),
      if (hamburgerConfig != null) ..._hamburgerDetailLines(hamburgerConfig),
      if (wingsConfig != null) ..._wingsDetailLines(wingsConfig),
      if (saladConfig != null) ..._saladDetailLines(saladConfig),
      if (garlicBreadConfig != null)
        ..._garlicBreadDetailLines(garlicBreadConfig),
      if (spaghettiConfig != null) ..._spaghettiDetailLines(spaghettiConfig),
      if (pizzaConfig != null) ..._pizzaDetailLines(pizzaConfig),
      if (!hasComment &&
          pizzaConfig == null &&
          hamburgerConfig == null &&
          wingsConfig == null &&
          saladConfig == null &&
          garlicBreadConfig == null &&
          spaghettiConfig == null)
        'Agregar comentario',
    ];
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.name,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (hasComment)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.comment,
                              size: 14, color: Color(0xFFF97316)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  for (var i = 0; i < subtitleLines.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text(
                        subtitleLines[i],
                        style: TextStyle(
                          fontSize: 11,
                          color: i == 0 && hasComment
                              ? const Color(0xFF6B7280)
                              : (subtitleLines[i] == 'Agregar comentario'
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280)),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 22,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _QtyButton(icon: Icons.remove, onTap: onMinus),
                const SizedBox(width: 5),
                SizedBox(
                    width: 18,
                    child: Text('${item.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12))),
                const SizedBox(width: 5),
                _QtyButton(icon: Icons.add, onTap: onPlus),
              ]),
            ),
            Expanded(
                flex: 18,
                child: Text('\$${item.price.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF4B5563)))),
            Expanded(
                flex: 18,
                child: Text(
                    '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w700))),
            Expanded(
                flex: 8,
                child: IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFFDC2626), size: 17),
                    splashRadius: 18)),
          ],
        ),
      ),
    );
  }
}

class _DrinkCategoryEntry {
  const _DrinkCategoryEntry.group({
    required this.name,
    required this.items,
  })  : isGroup = true,
        price = null;

  const _DrinkCategoryEntry.product({
    required this.name,
    required this.price,
  })  : isGroup = false,
        items = const [];

  final String name;
  final bool isGroup;
  final List<_DrinkOption> items;
  final double? price;
}

class _DrinkOption {
  const _DrinkOption({
    required this.name,
    required this.price,
  });

  final String name;
  final double price;
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: const BorderSide(color: Color(0xFFD1D5DB)),
            backgroundColor: const Color(0xFFF9FAFB)),
        child: Icon(icon, size: 12, color: const Color(0xFF4B5563)),
      ),
    );
  }
}
