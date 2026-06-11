enum PosView { tables, pos, payment, customers }

enum TableStatus { available, occupied, awaitingPayment }

enum PosTab { receipt, client }

enum PaymentMethod { cash, card, gift }

enum FloorPlanSection { floorPlan, orders, orderHistory }

enum PizzaSelectionMode { specialty, ingredients, halfHalf }

enum PizzaHalfSelectionMode { specialty, ingredients }

enum HamburgerSideOption { conPapas, sinPapas, conAros }

enum HamburgerCutOption { completa, partidaMitad }

enum WingsSizeOption { mediaOrden, orden, megaOrden }

enum WingsBoneType { unHueso, dosHuesos }

enum WingsSauceMode { unica, mitadMitad }

enum AppOrderStatus {
  pending,
  open,
  occupied,
  inProgress,
  awaitingPayment,
  closedWithoutPayment,
  paid,
  completed,
  closed,
  cancelled
}

extension AppOrderStatusX on AppOrderStatus {
  bool get isTerminal =>
      this == AppOrderStatus.paid ||
      this == AppOrderStatus.closedWithoutPayment ||
      this == AppOrderStatus.completed ||
      this == AppOrderStatus.closed ||
      this == AppOrderStatus.cancelled;

  bool get isActive => !isTerminal;
}

class TableInfo {
  const TableInfo({
    required this.id,
    required this.number,
    required this.status,
    this.orderTotal,
  });

  final String id;
  final String number;
  final TableStatus status;
  final double? orderTotal;

  TableInfo copyWith({
    String? id,
    String? number,
    TableStatus? status,
    double? orderTotal,
    bool clearOrderTotal = false,
  }) {
    return TableInfo(
      id: id ?? this.id,
      number: number ?? this.number,
      status: status ?? this.status,
      orderTotal: clearOrderTotal ? null : (orderTotal ?? this.orderTotal),
    );
  }
}

class CategoryData {
  const CategoryData({
    required this.id,
    required this.code,
    required this.name,
    required this.image,
  });

  final String id;
  final String code;
  final String name;
  final String image;
}

class ProductData {
  const ProductData({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.image,
  });

  final String id;
  final String name;
  final double price;
  final String categoryId;
  final String? image;
}

class GuestData {
  const GuestData({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;
}

class OrderItemData {
  const OrderItemData({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.quantity,
    required this.guestId,
    this.comment,
    this.pizzaConfig,
    this.hamburgerConfig,
    this.wingsConfig,
    this.saladConfig,
    this.spaghettiConfig,
    this.garlicBreadConfig,
    this.sentToKitchen = false,
  });

  final String id;
  final String name;
  final double price;
  final String categoryId;
  final int quantity;
  final int guestId;
  final String? comment;
  final PizzaConfigData? pizzaConfig;
  final HamburgerConfigData? hamburgerConfig;
  final WingsConfigData? wingsConfig;
  final SaladConfigData? saladConfig;
  final SpaghettiConfigData? spaghettiConfig;
  final GarlicBreadConfigData? garlicBreadConfig;
  final bool sentToKitchen;

  OrderItemData copyWith({
    String? id,
    String? name,
    double? price,
    String? categoryId,
    int? quantity,
    int? guestId,
    String? comment,
    bool clearComment = false,
    PizzaConfigData? pizzaConfig,
    HamburgerConfigData? hamburgerConfig,
    WingsConfigData? wingsConfig,
    SaladConfigData? saladConfig,
    SpaghettiConfigData? spaghettiConfig,
    GarlicBreadConfigData? garlicBreadConfig,
    bool? sentToKitchen,
  }) {
    return OrderItemData(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      quantity: quantity ?? this.quantity,
      guestId: guestId ?? this.guestId,
      comment: clearComment ? null : (comment ?? this.comment),
      pizzaConfig: pizzaConfig ?? this.pizzaConfig,
      hamburgerConfig: hamburgerConfig ?? this.hamburgerConfig,
      wingsConfig: wingsConfig ?? this.wingsConfig,
      saladConfig: saladConfig ?? this.saladConfig,
      spaghettiConfig: spaghettiConfig ?? this.spaghettiConfig,
      garlicBreadConfig: garlicBreadConfig ?? this.garlicBreadConfig,
      sentToKitchen: sentToKitchen ?? this.sentToKitchen,
    );
  }
}

class PizzaConfigData {
  const PizzaConfigData({
    required this.specialty,
    required this.size,
    required this.crustEdge,
    required this.breadType,
    required this.dorada,
    required this.ingredients,
    required this.extraIngredients,
    required this.selectionMode,
    this.half1,
    this.half2,
    this.half1Mode,
    this.half2Mode,
    this.half1Specialty,
    this.half2Specialty,
    this.half1Ingredients = const [],
    this.half2Ingredients = const [],
    this.crustHalf1,
    this.crustHalf2,
    this.includePromoGarlicBread = false,
    this.promoPizzaMediana = false,
  });

  final String specialty;
  final String size;
  final String crustEdge;
  final String breadType;
  final bool dorada;
  final List<String> ingredients;
  final List<String> extraIngredients;
  final PizzaSelectionMode selectionMode;
  final String? half1;
  final String? half2;
  final PizzaHalfSelectionMode? half1Mode;
  final PizzaHalfSelectionMode? half2Mode;
  final String? half1Specialty;
  final String? half2Specialty;
  final List<String> half1Ingredients;
  final List<String> half2Ingredients;
  final String? crustHalf1;
  final String? crustHalf2;
  final bool includePromoGarlicBread;
  final bool promoPizzaMediana;
}

class HamburgerUnitConfigData {
  const HamburgerUnitConfigData({
    this.removedIngredients = const [],
    this.extraIngredients = const [],
    this.usedSinVerduraQuickAction = false,
    this.cutOption = HamburgerCutOption.completa,
  });

  final List<String> removedIngredients;
  final List<String> extraIngredients;
  final bool usedSinVerduraQuickAction;
  final HamburgerCutOption cutOption;
}

class HamburgerConfigData {
  const HamburgerConfigData({
    required this.burgerType,
    required this.side,
    this.removedIngredients = const [],
    this.extraIngredients = const [],
    this.usedSinVerduraQuickAction = false,
    this.cutOption = HamburgerCutOption.completa,
    this.isSpecialCombo = false,
    this.burger1,
    this.burger2,
  });

  final String burgerType;
  final HamburgerSideOption side;
  final List<String> removedIngredients;
  final List<String> extraIngredients;
  final bool usedSinVerduraQuickAction;
  final HamburgerCutOption cutOption;
  final bool isSpecialCombo;
  final HamburgerUnitConfigData? burger1;
  final HamburgerUnitConfigData? burger2;
}

class WingsConfigData {
  const WingsConfigData({
    required this.size,
    required this.sauceMode,
    required this.sauce,
    required this.sauceHalf1,
    required this.sauceHalf2,
    required this.naturales,
    required this.sauceOnSide,
    required this.juicy,
    required this.doradas,
    required this.boneType,
    required this.sinApio,
    required this.sinZanahoria,
  });

  final WingsSizeOption size;
  final WingsSauceMode sauceMode;
  final String? sauce;
  final String? sauceHalf1;
  final String? sauceHalf2;
  final bool naturales;
  final bool sauceOnSide;
  final bool juicy;
  final bool doradas;
  final WingsBoneType? boneType;
  final bool sinApio;
  final bool sinZanahoria;
}

class SaladConfigData {
  const SaladConfigData({
    required this.removedIngredients,
    required this.addOns,
  });

  final List<String> removedIngredients;
  final List<String> addOns;
}

class SpaghettiConfigData {
  const SpaghettiConfigData({
    required this.spaghettiType,
    this.accompaniment = 'Panes de ajo',
    this.garlicBreadType = 'Normales',
    this.removedIngredients = const [],
    this.sinQueso = false,
    this.sinMantequilla = false,
    this.pocaSalsa = false,
    this.quesoDorado = false,
    this.extras = const [],
  });

  final String spaghettiType;
  final String accompaniment;
  final String? garlicBreadType;
  final List<String> removedIngredients;
  final bool sinQueso;
  final bool sinMantequilla;
  final bool pocaSalsa;
  final bool quesoDorado;
  final List<String> extras;
}

class GarlicBreadConfigData {
  const GarlicBreadConfigData({
    required this.type,
  });

  final String type;
}

class AppOrder {
  const AppOrder({
    required this.id,
    required this.orderNumber,
    required this.ticketNumber,
    required this.orderType,
    required this.customerOrTable,
    required this.createdAt,
    required this.status,
    required this.guests,
    required this.currentGuestId,
    required this.items,
    this.customerName,
    this.customerPhone,
    this.customerId,
    this.customerAddressId,
    this.deliveryAddress,
    this.deliveryAddressReference,
    this.deliveryAddressDetails,
    this.deliveryAddressPlaceId,
    this.deliveryAddressLatitude,
    this.deliveryAddressLongitude,
    this.deliveryNotes,
    this.deliveryDriver,
    this.cashierName,
    this.deliveryAddresses = const [],
    this.paymentCashAmount,
    this.paymentUsdAmount,
    this.paymentUsdExchangeRate,
    this.paymentCardAmount,
    this.paymentPaidAmount,
    this.paymentBalance,
    this.closeReason,
    this.completedAt,
    this.tableNumber,
    this.deliveryShippingCost = 0,
  });

  final String id;
  final String orderNumber;
  final String ticketNumber;
  final String orderType;
  final String customerOrTable;
  final DateTime createdAt;
  final AppOrderStatus status;
  final List<GuestData> guests;
  final int currentGuestId;
  final List<OrderItemData> items;
  final String? customerName;
  final String? customerPhone;
  final int? customerId;
  final int? customerAddressId;
  final String? deliveryAddress;
  final String? deliveryAddressReference;
  final String? deliveryAddressDetails;
  final String? deliveryAddressPlaceId;
  final double? deliveryAddressLatitude;
  final double? deliveryAddressLongitude;
  final String? deliveryNotes;
  final String? deliveryDriver;
  final String? cashierName;
  final List<String> deliveryAddresses;
  final double? paymentCashAmount;
  final double? paymentUsdAmount;
  final double? paymentUsdExchangeRate;
  final double? paymentCardAmount;
  final double? paymentPaidAmount;
  final double? paymentBalance;
  final String? closeReason;
  final DateTime? completedAt;
  final String? tableNumber;

  /// Costo de envío manual (MXN). Solo aplica cuando `orderType == 'Delivery'`.
  final double deliveryShippingCost;

  AppOrder copyWith({
    String? id,
    String? orderNumber,
    String? ticketNumber,
    String? orderType,
    String? customerOrTable,
    DateTime? createdAt,
    AppOrderStatus? status,
    List<GuestData>? guests,
    int? currentGuestId,
    List<OrderItemData>? items,
    String? customerName,
    String? customerPhone,
    int? customerId,
    int? customerAddressId,
    String? deliveryAddress,
    String? deliveryAddressReference,
    String? deliveryAddressDetails,
    String? deliveryAddressPlaceId,
    double? deliveryAddressLatitude,
    double? deliveryAddressLongitude,
    String? deliveryNotes,
    String? deliveryDriver,
    String? cashierName,
    List<String>? deliveryAddresses,
    double? paymentCashAmount,
    double? paymentUsdAmount,
    double? paymentUsdExchangeRate,
    double? paymentCardAmount,
    double? paymentPaidAmount,
    double? paymentBalance,
    String? closeReason,
    DateTime? completedAt,
    String? tableNumber,
    double? deliveryShippingCost,
    bool clearTableNumber = false,
    bool clearCustomerId = false,
    bool clearCustomerAddressId = false,
  }) {
    return AppOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      orderType: orderType ?? this.orderType,
      customerOrTable: customerOrTable ?? this.customerOrTable,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      guests: guests ?? this.guests,
      currentGuestId: currentGuestId ?? this.currentGuestId,
      items: items ?? this.items,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerId: clearCustomerId ? null : (customerId ?? this.customerId),
      customerAddressId: clearCustomerAddressId
          ? null
          : (customerAddressId ?? this.customerAddressId),
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryAddressReference:
          deliveryAddressReference ?? this.deliveryAddressReference,
      deliveryAddressDetails:
          deliveryAddressDetails ?? this.deliveryAddressDetails,
      deliveryAddressPlaceId:
          deliveryAddressPlaceId ?? this.deliveryAddressPlaceId,
      deliveryAddressLatitude:
          deliveryAddressLatitude ?? this.deliveryAddressLatitude,
      deliveryAddressLongitude:
          deliveryAddressLongitude ?? this.deliveryAddressLongitude,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      deliveryDriver: deliveryDriver ?? this.deliveryDriver,
      cashierName: cashierName ?? this.cashierName,
      deliveryAddresses: deliveryAddresses ?? this.deliveryAddresses,
      paymentCashAmount: paymentCashAmount ?? this.paymentCashAmount,
      paymentUsdAmount: paymentUsdAmount ?? this.paymentUsdAmount,
      paymentUsdExchangeRate:
          paymentUsdExchangeRate ?? this.paymentUsdExchangeRate,
      paymentCardAmount: paymentCardAmount ?? this.paymentCardAmount,
      paymentPaidAmount: paymentPaidAmount ?? this.paymentPaidAmount,
      paymentBalance: paymentBalance ?? this.paymentBalance,
      closeReason: closeReason ?? this.closeReason,
      completedAt: completedAt ?? this.completedAt,
      tableNumber: clearTableNumber ? null : (tableNumber ?? this.tableNumber),
      deliveryShippingCost: deliveryShippingCost ?? this.deliveryShippingCost,
    );
  }
}

class PaymentData {
  const PaymentData({
    required this.cashAmount,
    required this.usdAmount,
    required this.usdExchangeRateUsed,
    required this.cardAmount,
    required this.paidAmount,
    required this.balance,
    required this.printTicket,
  });

  final double cashAmount;
  final double usdAmount;
  final double usdExchangeRateUsed;
  final double cardAmount;
  final double paidAmount;
  final double balance;
  final bool printTicket;
}

class OrderPricingSummary {
  const OrderPricingSummary({
    required this.subtotal,
    required this.total,
    required this.promoApplied,
    required this.promoLabel,
    required this.promoAdjustment,
  });

  final double subtotal;
  final double total;
  final bool promoApplied;
  final String? promoLabel;
  final double promoAdjustment;
}

OrderPricingSummary calculateOrderPricing(List<OrderItemData> items) {
  final subtotal = items.fold<double>(
    0,
    (sum, item) => sum + (item.price * item.quantity),
  );

  final mediumPizzas = <_PizzaPromoUnit>[];
  for (final item in items) {
    final config = item.pizzaConfig;
    if (config == null) continue;
    if (config.promoPizzaMediana) continue;
    if (!_equalsNormalized(config.size, 'Mediana')) continue;
    for (var i = 0; i < item.quantity; i++) {
      mediumPizzas.add(_PizzaPromoUnit(item: item, config: config));
    }
  }

  final promoResult = _findBestTwoMedianasPromoResult(mediumPizzas);
  if (promoResult.pairCount == 0 || promoResult.totalDiscount <= 0) {
    return OrderPricingSummary(
      subtotal: subtotal,
      total: subtotal,
      promoApplied: false,
      promoLabel: null,
      promoAdjustment: 0,
    );
  }

  final promoAdjustment = -promoResult.totalDiscount;
  final promoLabel = promoResult.pairCount > 1
      ? 'Promo 2 pizzas medianas x${promoResult.pairCount}'
      : 'Promo 2 pizzas medianas';

  return OrderPricingSummary(
    subtotal: subtotal,
    total: subtotal + promoAdjustment,
    promoApplied: true,
    promoLabel: promoLabel,
    promoAdjustment: promoAdjustment,
  );
}

/// Total a cobrar en caja: solo ítems (incl. promos). El envío a domicilio no entra aquí.
double orderGrandTotal(AppOrder order) {
  return calculateOrderPricing(order.items).total;
}

_PromoComputation _findBestTwoMedianasPromoResult(
    List<_PizzaPromoUnit> mediumPizzas) {
  if (mediumPizzas.length < 2) {
    return const _PromoComputation(totalDiscount: 0, pairCount: 0);
  }

  const promoPrice = 229.0;
  final memo = <int, _PromoComputation>{};

  _PromoComputation solve(int usedMask) {
    final cached = memo[usedMask];
    if (cached != null) return cached;

    final n = mediumPizzas.length;
    var firstFree = -1;
    for (var i = 0; i < n; i++) {
      if ((usedMask & (1 << i)) == 0) {
        firstFree = i;
        break;
      }
    }

    if (firstFree == -1) {
      return const _PromoComputation(totalDiscount: 0, pairCount: 0);
    }

    var best = solve(usedMask | (1 << firstFree));

    for (var j = firstFree + 1; j < n; j++) {
      if ((usedMask & (1 << j)) != 0) continue;
      final pair = [mediumPizzas[firstFree], mediumPizzas[j]];
      if (!(_matchesRuleA(pair) || _matchesRuleB(pair))) continue;

      final pairSubtotal = pair.fold<double>(
        0,
        (sum, unit) => sum + unit.item.price,
      );
      final pairDiscount = pairSubtotal - promoPrice;
      if (pairDiscount <= 0) continue;

      final next = solve(usedMask | (1 << firstFree) | (1 << j));
      final candidate = _PromoComputation(
        totalDiscount: next.totalDiscount + pairDiscount,
        pairCount: next.pairCount + 1,
      );

      if (candidate.totalDiscount > best.totalDiscount ||
          (candidate.totalDiscount == best.totalDiscount &&
              candidate.pairCount > best.pairCount)) {
        best = candidate;
      }
    }

    memo[usedMask] = best;
    return best;
  }

  return solve(0);
}

bool _matchesRuleA(List<_PizzaPromoUnit> pair) {
  final isSpecialtyPair = pair.every((unit) {
    return unit.config.selectionMode == PizzaSelectionMode.specialty;
  });
  if (!isSpecialtyPair) return false;
  return pair
      .any((unit) => _equalsNormalized(unit.config.specialty, 'Pepperoni'));
}

bool _matchesRuleB(List<_PizzaPromoUnit> pair) {
  return pair.every((unit) {
    if (unit.config.selectionMode != PizzaSelectionMode.ingredients) {
      return false;
    }
    return unit.config.ingredients.length <= 2;
  });
}

bool _equalsNormalized(String source, String target) {
  return _normalizeText(source) == _normalizeText(target);
}

String _normalizeText(String value) {
  const replacements = {
    'á': 'a',
    'Á': 'a',
    'é': 'e',
    'É': 'e',
    'í': 'i',
    'Í': 'i',
    'ó': 'o',
    'Ó': 'o',
    'ú': 'u',
    'Ú': 'u',
    'ñ': 'n',
    'Ñ': 'n',
  };
  final sb = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    sb.write(replacements[char] ?? char);
  }
  return sb.toString().toLowerCase().trim();
}

class _PizzaPromoUnit {
  const _PizzaPromoUnit({
    required this.item,
    required this.config,
  });

  final OrderItemData item;
  final PizzaConfigData config;
}

class _PromoComputation {
  const _PromoComputation({
    required this.totalDiscount,
    required this.pairCount,
  });

  final double totalDiscount;
  final int pairCount;
}

class CustomerData {
  const CustomerData({
    required this.id,
    required this.name,
    this.phone,
    this.phoneAlt,
    this.email,
    this.notes,
    this.active = true,
  });

  factory CustomerData.fromJson(Map<String, dynamic> json) {
    return CustomerData(
      id: json['id'] as int? ?? 0,
      name: json['nombre'] as String? ?? '',
      phone: json['telefono'] as String?,
      phoneAlt: json['telefono_alterno'] as String?,
      email: json['email'] as String?,
      notes: json['notas'] as String?,
      active: (json['activo'] as int? ?? 1) == 1,
    );
  }

  final int id;
  final String name;
  final String? phone;
  final String? phoneAlt;
  final String? email;
  final String? notes;
  final bool active;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nombre': name,
      if (phone != null && phone!.isNotEmpty) 'telefono': phone,
      if (phoneAlt != null && phoneAlt!.isNotEmpty) 'telefono_alterno': phoneAlt,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (notes != null && notes!.isNotEmpty) 'notas': notes,
    };
  }
}

class CustomerAddressData {
  const CustomerAddressData({
    required this.id,
    required this.customerId,
    this.alias,
    this.street,
    this.exteriorNumber,
    this.interiorNumber,
    this.neighborhood,
    this.city,
    this.state,
    this.postalCode,
    this.reference,
    this.deliveryNotes,
    this.latitude,
    this.longitude,
    this.placeId,
    this.active = true,
  });

  factory CustomerAddressData.fromJson(Map<String, dynamic> json) {
    return CustomerAddressData(
      id: json['id'] as int? ?? 0,
      customerId: json['cliente_id'] as int? ?? 0,
      alias: json['alias'] as String?,
      street: json['calle'] as String?,
      exteriorNumber: json['numero_exterior'] as String?,
      interiorNumber: json['numero_interior'] as String?,
      neighborhood: json['colonia'] as String?,
      city: json['ciudad'] as String?,
      state: json['estado'] as String?,
      postalCode: json['codigo_postal'] as String?,
      reference: json['referencia'] as String?,
      deliveryNotes: json['instrucciones_entrega'] as String?,
      latitude: (json['lat'] as num?)?.toDouble(),
      longitude: (json['lng'] as num?)?.toDouble(),
      placeId: json['place_id'] as String?,
      active: (json['activa'] as int? ?? 1) == 1,
    );
  }

  final int id;
  final int customerId;
  final String? alias;
  final String? street;
  final String? exteriorNumber;
  final String? interiorNumber;
  final String? neighborhood;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? reference;
  final String? deliveryNotes;
  final double? latitude;
  final double? longitude;
  final String? placeId;
  final bool active;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cliente_id': customerId,
      if (alias != null && alias!.isNotEmpty) 'alias': alias,
      if (street != null && street!.isNotEmpty) 'calle': street,
      if (exteriorNumber != null && exteriorNumber!.isNotEmpty) 'numero_exterior': exteriorNumber,
      if (interiorNumber != null && interiorNumber!.isNotEmpty) 'numero_interior': interiorNumber,
      if (neighborhood != null && neighborhood!.isNotEmpty) 'colonia': neighborhood,
      if (city != null && city!.isNotEmpty) 'ciudad': city,
      if (state != null && state!.isNotEmpty) 'estado': state,
      if (postalCode != null && postalCode!.isNotEmpty) 'codigo_postal': postalCode,
      if (reference != null && reference!.isNotEmpty) 'referencia': reference,
      if (deliveryNotes != null && deliveryNotes!.isNotEmpty) 'instrucciones_entrega': deliveryNotes,
      if (latitude != null) 'lat': latitude,
      if (longitude != null) 'lng': longitude,
      if (placeId != null && placeId!.isNotEmpty) 'place_id': placeId,
      'activa': active ? 1 : 0,
    };
  }
}
