import 'package:flutter/material.dart';

import '../figma_models.dart';

typedef AddPizzaCallback = void Function(PizzaConfigData config, double price);

class PizzaBuilderView extends StatefulWidget {
  const PizzaBuilderView({
    super.key,
    required this.onBack,
    required this.onAddPizza,
  });

  final VoidCallback onBack;
  final AddPizzaCallback onAddPizza;

  @override
  State<PizzaBuilderView> createState() => _PizzaBuilderViewState();
}

class _PizzaBuilderViewState extends State<PizzaBuilderView> {
  static const String _defaultSpecialty = 'Pepperoni';
  static const double _promoGarlicBreadPrice = 39;

  static const List<String> _specialties = [
    'Pepperoni',
    'Hawaiana',
    'Suprema',
    'Surtida',
    'Española',
    'Mexicana',
    'Italiana',
    'Ranchera',
    'Sonorense',
    'Vegetariana',
  ];

  static const Map<String, List<String>> _specialtyIngredients = {
    'Pepperoni': ['Pepperoni', 'Queso', 'Salsa de tomate'],
    'Hawaiana': ['Jamón', 'Piña', 'Morrón'],
    'Suprema': ['Pepperoni', 'Salami', 'Champiñón', 'Aceituna', 'Morrón'],
    'Surtida': [
      'Pepperoni',
      'Salami',
      'Jamón',
      'Salchicha',
      'Tocino',
      'Chorizo'
    ],
    'Española': ['Pepperoni', 'Champiñón', 'Jalapeño', 'Carne'],
    'Mexicana': ['Frijol', 'Cebolla', 'Jalapeño', 'Chorizo'],
    'Italiana': ['Pepperoni', 'Salami', 'Champiñón', 'Aceituna', 'Tocino'],
    'Ranchera': ['Jamón', 'Jalapeño', 'Tocino', 'Chorizo'],
    'Sonorense': ['Machaca', 'Tomate', 'Cebolla', 'Jalapeño'],
    'Vegetariana': [
      'Champiñón',
      'Tomate',
      'Cebolla',
      'Morrón',
      'Aceituna',
      'Piña'
    ],
  };

  static const List<String> _allIngredients = [
    'Pepperoni',
    'Salami',
    'Champiñón',
    'Aceituna',
    'Tocino',
    'Morrón',
    'Frijol',
    'Cebolla',
    'Jalapeño',
    'Chorizo',
    'Carne',
    'Jamón',
    'Salchicha',
    'Machaca',
    'Tomate',
    'Piña',
    'Queso',
    'Salsa de tomate',
  ];

  static const List<_PriceOption> _sizes = [
    _PriceOption(name: 'Mini', price: 89),
    _PriceOption(name: 'Chica', price: 119),
    _PriceOption(name: 'Mediana', price: 159),
    _PriceOption(name: 'Grande', price: 199),
    _PriceOption(name: 'Familiar', price: 2499),
    _PriceOption(name: 'Mega', price: 279),
  ];

  static const List<_PriceOption> _crustEdges = [
    _PriceOption(name: 'Regular', price: 0),
    _PriceOption(name: 'Queso crema', price: 0),
    _PriceOption(name: 'Queso mozzarella', price: 0),
    _PriceOption(name: 'Orilla Mitad y Mitad', price: 0),
  ];
  static const List<String> _splitCrustOptions = [
    'Queso crema',
    'Queso mozzarella',
  ];

  static const List<_PriceOption> _breadTypes = [
    _PriceOption(name: 'Regular', price: 0),
    _PriceOption(name: 'Delgado', price: 0),
    _PriceOption(name: 'Grueso', price: 0),
  ];

  static const Map<String, double> _crustPriceBySize = {
    'Mini': 35,
    'Chica': 45,
    'Mediana': 55,
    'Grande': 65,
    'Familiar': 75,
    'Mega': 85,
  };

  static const Map<String, double> _extraIngredientPriceBySize = {
    'Mini': 10,
    'Chica': 10,
    'Mediana': 15,
    'Grande': 15,
    'Familiar': 20,
    'Mega': 20,
  };

  static const Map<String, double> _extraQuesoPriceBySize = {
    'Mini': 30,
    'Chica': 35,
    'Mediana': 40,
    'Grande': 45,
    'Familiar': 50,
    'Mega': 55,
  };

  PizzaSelectionMode _selectionMode = PizzaSelectionMode.specialty;
  late PizzaConfigData _config;
  List<String> _customIngredients = const [];
  List<String> _extraIngredients = const [];
  String _half1Specialty = _defaultSpecialty;
  String _half2Specialty = 'Hawaiana';
  PizzaHalfSelectionMode _half1Mode = PizzaHalfSelectionMode.specialty;
  PizzaHalfSelectionMode _half2Mode = PizzaHalfSelectionMode.specialty;
  List<String> _half1CustomIngredients = const [];
  List<String> _half2CustomIngredients = const [];
  String _splitCrustHalf1 = 'Queso crema';
  String _splitCrustHalf2 = 'Queso mozzarella';
  bool _includePromoGarlicBread = false;

  @override
  void initState() {
    super.initState();
    _config = PizzaConfigData(
      specialty: _defaultSpecialty,
      size: 'Mediana',
      crustEdge: 'Regular',
      breadType: 'Regular',
      dorada: false,
      ingredients: _specialtyIngredients[_defaultSpecialty] ?? const [],
      extraIngredients: const [],
      selectionMode: PizzaSelectionMode.specialty,
      half1: _half1Specialty,
      half2: _half2Specialty,
      half1Mode: _half1Mode,
      half2Mode: _half2Mode,
      half1Specialty: _half1Specialty,
      half2Specialty: _half2Specialty,
      half1Ingredients: const [],
      half2Ingredients: const [],
      crustHalf1: _splitCrustHalf1,
      crustHalf2: _splitCrustHalf2,
      includePromoGarlicBread: false,
    );
  }

  List<String> get _half1Ingredients {
    if (_half1Mode == PizzaHalfSelectionMode.specialty) {
      return _specialtyIngredients[_half1Specialty] ?? const [];
    }
    return _half1CustomIngredients;
  }

  List<String> get _half2Ingredients {
    if (_half2Mode == PizzaHalfSelectionMode.specialty) {
      return _specialtyIngredients[_half2Specialty] ?? const [];
    }
    return _half2CustomIngredients;
  }

  List<String> get _currentIngredients {
    if (_selectionMode == PizzaSelectionMode.specialty) {
      return _specialtyIngredients[_config.specialty] ?? const [];
    }
    if (_selectionMode == PizzaSelectionMode.halfHalf) {
      return [..._half1Ingredients, ..._half2Ingredients];
    }
    return _customIngredients;
  }

  double get _currentCrustPrice => _crustPriceBySize[_config.size] ?? 0;
  double get _currentExtraIngredientPrice =>
      _extraIngredientPriceBySize[_config.size] ?? 0;
  double get _currentExtraQuesoPrice => _extraQuesoPriceBySize[_config.size] ?? 0;

  double _extraIngredientCost(String ingredient) {
    return ingredient == 'Queso'
        ? _currentExtraQuesoPrice
        : _currentExtraIngredientPrice;
  }

  double _calculatePrice() {
    final sizePrice =
        _sizes.firstWhere((size) => size.name == _config.size).price;
    final crustPrice = _config.crustEdge == 'Regular' ? 0 : _currentCrustPrice;
    final breadPrice = _breadTypes
        .firstWhere((bread) => bread.name == _config.breadType)
        .price;
    const doradaPrice = 0.0;
    final extrasPrice =
        _extraIngredients.fold<double>(0, (sum, ingredient) => sum + _extraIngredientCost(ingredient));
    final promoGarlicBreadPrice =
        _includePromoGarlicBread ? _promoGarlicBreadPrice : 0;
    return sizePrice +
        crustPrice +
        breadPrice +
        doradaPrice +
        extrasPrice +
        promoGarlicBreadPrice;
  }

  void _updateConfig({
    String? specialty,
    String? size,
    String? crustEdge,
    String? breadType,
    bool? dorada,
    List<String>? ingredients,
    PizzaSelectionMode? selectionMode,
    String? half1Specialty,
    String? half2Specialty,
    PizzaHalfSelectionMode? half1Mode,
    PizzaHalfSelectionMode? half2Mode,
    List<String>? half1Ingredients,
    List<String>? half2Ingredients,
    String? crustHalf1,
    String? crustHalf2,
    bool? includePromoGarlicBread,
  }) {
    _config = PizzaConfigData(
      specialty: specialty ?? _config.specialty,
      size: size ?? _config.size,
      crustEdge: crustEdge ?? _config.crustEdge,
      breadType: breadType ?? _config.breadType,
      dorada: dorada ?? _config.dorada,
      ingredients: ingredients ?? _config.ingredients,
      extraIngredients: _extraIngredients,
      selectionMode: selectionMode ?? _config.selectionMode,
      half1: half1Specialty ?? _config.half1,
      half2: half2Specialty ?? _config.half2,
      half1Mode: half1Mode ?? _config.half1Mode,
      half2Mode: half2Mode ?? _config.half2Mode,
      half1Specialty: half1Specialty ?? _config.half1Specialty,
      half2Specialty: half2Specialty ?? _config.half2Specialty,
      half1Ingredients: half1Ingredients ?? _config.half1Ingredients,
      half2Ingredients: half2Ingredients ?? _config.half2Ingredients,
      crustHalf1: crustHalf1 ?? _config.crustHalf1,
      crustHalf2: crustHalf2 ?? _config.crustHalf2,
      includePromoGarlicBread:
          includePromoGarlicBread ?? _config.includePromoGarlicBread,
    );
  }

  void _handleSpecialtySelect(String specialty) {
    final ingredients = _specialtyIngredients[specialty] ?? const [];
    setState(() {
      _selectionMode = PizzaSelectionMode.specialty;
      _updateConfig(
        specialty: specialty,
        ingredients: ingredients,
        selectionMode: PizzaSelectionMode.specialty,
      );
    });
  }

  void _handleModeSwitch(PizzaSelectionMode mode) {
    if (mode == _selectionMode) return;
    if (mode == PizzaSelectionMode.ingredients) {
      setState(() {
        _selectionMode = PizzaSelectionMode.ingredients;
        _customIngredients = const [];
        _updateConfig(
          specialty: 'Pizza personalizada',
          ingredients: const [],
          selectionMode: PizzaSelectionMode.ingredients,
        );
      });
      return;
    }

    if (mode == PizzaSelectionMode.halfHalf) {
      setState(() {
        _selectionMode = PizzaSelectionMode.halfHalf;
        _customIngredients = const [];
        _updateConfig(
          specialty: 'Pizza mitad y mitad',
          ingredients: _currentIngredients,
          selectionMode: PizzaSelectionMode.halfHalf,
          half1Specialty: _half1Specialty,
          half2Specialty: _half2Specialty,
          half1Mode: _half1Mode,
          half2Mode: _half2Mode,
          half1Ingredients: _half1Ingredients,
          half2Ingredients: _half2Ingredients,
        );
      });
      return;
    }

    final ingredients = _specialtyIngredients[_defaultSpecialty] ?? const [];
    setState(() {
      _selectionMode = PizzaSelectionMode.specialty;
      _customIngredients = const [];
      _updateConfig(
        specialty: _defaultSpecialty,
        ingredients: ingredients,
        selectionMode: PizzaSelectionMode.specialty,
        half1Specialty: _half1Specialty,
        half2Specialty: _half2Specialty,
        half1Mode: _half1Mode,
        half2Mode: _half2Mode,
        half1Ingredients: _half1Ingredients,
        half2Ingredients: _half2Ingredients,
      );
    });
  }

  void _selectHalf1Specialty(String specialty) {
    setState(() {
      _half1Specialty = specialty;
      _updateConfig(
        specialty: 'Pizza mitad y mitad',
        ingredients: _currentIngredients,
        selectionMode: PizzaSelectionMode.halfHalf,
        half1Specialty: _half1Specialty,
        half2Specialty: _half2Specialty,
        half1Mode: _half1Mode,
        half2Mode: _half2Mode,
        half1Ingredients: _half1Ingredients,
        half2Ingredients: _half2Ingredients,
      );
    });
  }

  void _selectHalf2Specialty(String specialty) {
    setState(() {
      _half2Specialty = specialty;
      _updateConfig(
        specialty: 'Pizza mitad y mitad',
        ingredients: _currentIngredients,
        selectionMode: PizzaSelectionMode.halfHalf,
        half1Specialty: _half1Specialty,
        half2Specialty: _half2Specialty,
        half1Mode: _half1Mode,
        half2Mode: _half2Mode,
        half1Ingredients: _half1Ingredients,
        half2Ingredients: _half2Ingredients,
      );
    });
  }

  void _setHalfMode(int halfIndex, PizzaHalfSelectionMode mode) {
    setState(() {
      if (halfIndex == 1) {
        _half1Mode = mode;
      } else {
        _half2Mode = mode;
      }
      _updateConfig(
        specialty: 'Pizza mitad y mitad',
        ingredients: _currentIngredients,
        selectionMode: PizzaSelectionMode.halfHalf,
        half1Specialty: _half1Specialty,
        half2Specialty: _half2Specialty,
        half1Mode: _half1Mode,
        half2Mode: _half2Mode,
        half1Ingredients: _half1Ingredients,
        half2Ingredients: _half2Ingredients,
      );
    });
  }

  void _toggleHalfIngredient(int halfIndex, String ingredient) {
    setState(() {
      if (halfIndex == 1) {
        if (_half1CustomIngredients.contains(ingredient)) {
          _half1CustomIngredients =
              _half1CustomIngredients.where((i) => i != ingredient).toList();
        } else {
          _half1CustomIngredients = [..._half1CustomIngredients, ingredient];
        }
      } else {
        if (_half2CustomIngredients.contains(ingredient)) {
          _half2CustomIngredients =
              _half2CustomIngredients.where((i) => i != ingredient).toList();
        } else {
          _half2CustomIngredients = [..._half2CustomIngredients, ingredient];
        }
      }
      _updateConfig(
        specialty: 'Pizza mitad y mitad',
        ingredients: _currentIngredients,
        selectionMode: PizzaSelectionMode.halfHalf,
        half1Specialty: _half1Specialty,
        half2Specialty: _half2Specialty,
        half1Mode: _half1Mode,
        half2Mode: _half2Mode,
        half1Ingredients: _half1Ingredients,
        half2Ingredients: _half2Ingredients,
      );
    });
  }

  void _toggleIngredient(String ingredient) {
    setState(() {
      if (_customIngredients.contains(ingredient)) {
        _customIngredients =
            _customIngredients.where((value) => value != ingredient).toList();
      } else {
        _customIngredients = [..._customIngredients, ingredient];
      }
      _updateConfig(
        specialty: 'Pizza personalizada',
        ingredients: _customIngredients,
        selectionMode: PizzaSelectionMode.ingredients,
      );
    });
  }

  void _toggleExtraIngredient(String ingredient) {
    setState(() {
      if (_extraIngredients.contains(ingredient)) {
        _extraIngredients =
            _extraIngredients.where((value) => value != ingredient).toList();
      } else {
        _extraIngredients = [..._extraIngredients, ingredient];
      }
      _updateConfig();
    });
  }

  void _selectSplitCrustHalf(int half, String value) {
    setState(() {
      if (half == 1) {
        _splitCrustHalf1 = value;
      } else {
        _splitCrustHalf2 = value;
      }
      _updateConfig(
        crustEdge: 'Orilla Mitad y Mitad',
        crustHalf1: _splitCrustHalf1,
        crustHalf2: _splitCrustHalf2,
      );
    });
  }

  void _addPizza() {
    final finalConfig = PizzaConfigData(
      specialty: _config.specialty,
      size: _config.size,
      crustEdge: _config.crustEdge,
      breadType: _config.breadType,
      dorada: _config.dorada,
      ingredients: _currentIngredients,
      extraIngredients: _extraIngredients,
      selectionMode: _selectionMode,
      half1: _selectionMode == PizzaSelectionMode.halfHalf
          ? _half1Specialty
          : null,
      half2: _selectionMode == PizzaSelectionMode.halfHalf
          ? _half2Specialty
          : null,
      half1Mode:
          _selectionMode == PizzaSelectionMode.halfHalf ? _half1Mode : null,
      half2Mode:
          _selectionMode == PizzaSelectionMode.halfHalf ? _half2Mode : null,
      half1Specialty: _selectionMode == PizzaSelectionMode.halfHalf
          ? _half1Specialty
          : null,
      half2Specialty: _selectionMode == PizzaSelectionMode.halfHalf
          ? _half2Specialty
          : null,
      half1Ingredients: _selectionMode == PizzaSelectionMode.halfHalf
          ? _half1Ingredients
          : const [],
      half2Ingredients: _selectionMode == PizzaSelectionMode.halfHalf
          ? _half2Ingredients
          : const [],
      crustHalf1:
          _config.crustEdge == 'Orilla Mitad y Mitad' ? _splitCrustHalf1 : null,
      crustHalf2:
          _config.crustEdge == 'Orilla Mitad y Mitad' ? _splitCrustHalf2 : null,
      includePromoGarlicBread: _includePromoGarlicBread,
    );
    widget.onAddPizza(finalConfig, _calculatePrice());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Row(
        children: [
          Container(
            width: 400,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x22000000), blurRadius: 8)
              ],
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Volver a Categorías'),
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Constructor de Pizza',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFFED7AA), width: 2),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFF7ED), Color(0xFFFEF2F2)],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tu Pizza',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF4B5563),
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 10),
                              if (_selectionMode ==
                                  PizzaSelectionMode.halfHalf) ...[
                                _SummaryRow(
                                  label: 'Mitad 1:',
                                  value: _half1Mode ==
                                          PizzaHalfSelectionMode.specialty
                                      ? 'Especialidad - $_half1Specialty'
                                      : 'Ingredientes (${_half1Ingredients.length})',
                                ),
                                _SummaryRow(
                                  label: 'Mitad 2:',
                                  value: _half2Mode ==
                                          PizzaHalfSelectionMode.specialty
                                      ? 'Especialidad - $_half2Specialty'
                                      : 'Ingredientes (${_half2Ingredients.length})',
                                ),
                              ] else
                                _SummaryRow(
                                    label: 'Especialidad:',
                                    value: _config.specialty),
                              _SummaryRow(
                                  label: 'Tamaño:', value: _config.size),
                              if (_config.crustEdge ==
                                  'Orilla Mitad y Mitad') ...[
                                const _SummaryRow(
                                    label: 'Orilla:', value: 'Mitad y Mitad'),
                                _SummaryRow(
                                    label: 'Orilla Mitad 1:',
                                    value: _splitCrustHalf1),
                                _SummaryRow(
                                    label: 'Orilla Mitad 2:',
                                    value: _splitCrustHalf2),
                              ] else
                                _SummaryRow(
                                    label: 'Orilla:', value: _config.crustEdge),
                              _SummaryRow(
                                  label: 'Tipo de Pan:',
                                  value: _config.breadType),
                              _SummaryRow(
                                  label: 'Dorada:',
                                  value: _config.dorada ? 'Sí' : 'No'),
                              _SummaryRow(
                                label: 'Complemento:',
                                value: _includePromoGarlicBread
                                    ? 'Panes de ajo promo'
                                    : 'Ninguno',
                              ),
                              const SizedBox(height: 10),
                              const Divider(),
                              const SizedBox(height: 6),
                              const Text('Ingredientes:',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF4B5563),
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              if (_currentIngredients.isEmpty)
                                const Text('Ningún ingrediente seleccionado',
                                    style: TextStyle(
                                        fontSize: 12, color: Color(0xFF6B7280)))
                              else if (_selectionMode ==
                                  PizzaSelectionMode.halfHalf)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mitad 1 (${_half1Mode == PizzaHalfSelectionMode.specialty ? _half1Specialty : 'Ingredientes'}):',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    _IngredientWrap(values: _half1Ingredients),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Mitad 2 (${_half2Mode == PizzaHalfSelectionMode.specialty ? _half2Specialty : 'Ingredientes'}):',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    _IngredientWrap(values: _half2Ingredients),
                                  ],
                                )
                              else
                                _IngredientWrap(values: _currentIngredients),
                              const SizedBox(height: 10),
                              const Text('Ingredientes Extra:',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF4B5563),
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              if (_extraIngredients.isEmpty)
                                const Text('Ningún extra seleccionado',
                                    style: TextStyle(
                                        fontSize: 12, color: Color(0xFF6B7280)))
                              else
                                _IngredientWrap(values: _extraIngredients),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              const Text('Precio Total',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white70)),
                              const SizedBox(height: 4),
                              Text('\$${_calculatePrice().toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 38,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _addPizza,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Pizza a la Orden'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 52),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Complemento de pizza',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4B5563),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ChoiceButton(
                                      text: 'Ninguno',
                                      active: !_includePromoGarlicBread,
                                      activeColor: const Color(0xFF475569),
                                      onTap: () => setState(() {
                                        _includePromoGarlicBread = false;
                                        _updateConfig(
                                          includePromoGarlicBread: false,
                                        );
                                      }),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _ChoiceButton(
                                      text:
                                          'Panes de ajo promo (+\$${_promoGarlicBreadPrice.toStringAsFixed(2)})',
                                      active: _includePromoGarlicBread,
                                      activeColor: const Color(0xFF16A34A),
                                      onTap: () => setState(() {
                                        _includePromoGarlicBread = true;
                                        _updateConfig(
                                          includePromoGarlicBread: true,
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
              child: Column(
                children: [
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _ModeButton(
                                label: 'Especialidad',
                                active: _selectionMode ==
                                    PizzaSelectionMode.specialty,
                                onTap: () => _handleModeSwitch(
                                    PizzaSelectionMode.specialty),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ModeButton(
                                label: 'Ingredientes',
                                active: _selectionMode ==
                                    PizzaSelectionMode.ingredients,
                                onTap: () => _handleModeSwitch(
                                    PizzaSelectionMode.ingredients),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ModeButton(
                                label: 'Mitad y Mitad',
                                active: _selectionMode ==
                                    PizzaSelectionMode.halfHalf,
                                onTap: () => _handleModeSwitch(
                                    PizzaSelectionMode.halfHalf),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                            _selectionMode == PizzaSelectionMode.specialty
                                ? 'Selecciona una Especialidad'
                                : (_selectionMode ==
                                        PizzaSelectionMode.ingredients
                                    ? 'Selecciona Ingredientes'
                                    : 'Configura Mitad y Mitad'),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        if (_selectionMode == PizzaSelectionMode.specialty)
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _specialties
                                .map((specialty) => _ChoiceButton(
                                      text: specialty,
                                      active: _config.specialty == specialty,
                                      activeColor: const Color(0xFFEA580C),
                                      onTap: () =>
                                          _handleSpecialtySelect(specialty),
                                    ))
                                .toList(growable: false),
                          )
                        else if (_selectionMode == PizzaSelectionMode.halfHalf)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mitad 1',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF374151))),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ModeButton(
                                      label: 'Especialidad',
                                      active: _half1Mode ==
                                          PizzaHalfSelectionMode.specialty,
                                      onTap: () => _setHalfMode(
                                          1, PizzaHalfSelectionMode.specialty),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _ModeButton(
                                      label: 'Ingredientes',
                                      active: _half1Mode ==
                                          PizzaHalfSelectionMode.ingredients,
                                      onTap: () => _setHalfMode(1,
                                          PizzaHalfSelectionMode.ingredients),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: (_half1Mode ==
                                        PizzaHalfSelectionMode.specialty
                                    ? _specialties
                                        .map((specialty) => _ChoiceButton(
                                              text: specialty,
                                              active:
                                                  _half1Specialty == specialty,
                                              activeColor:
                                                  const Color(0xFFEA580C),
                                              onTap: () =>
                                                  _selectHalf1Specialty(
                                                      specialty),
                                            ))
                                        .toList(growable: false)
                                    : _allIngredients
                                        .map((ingredient) => _ChoiceButton(
                                              text: ingredient,
                                              active: _half1CustomIngredients
                                                  .contains(ingredient),
                                              activeColor:
                                                  const Color(0xFFEA580C),
                                              onTap: () =>
                                                  _toggleHalfIngredient(
                                                      1, ingredient),
                                            ))
                                        .toList(growable: false)),
                              ),
                              const SizedBox(height: 14),
                              const Text('Mitad 2',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF374151))),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ModeButton(
                                      label: 'Especialidad',
                                      active: _half2Mode ==
                                          PizzaHalfSelectionMode.specialty,
                                      onTap: () => _setHalfMode(
                                          2, PizzaHalfSelectionMode.specialty),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _ModeButton(
                                      label: 'Ingredientes',
                                      active: _half2Mode ==
                                          PizzaHalfSelectionMode.ingredients,
                                      onTap: () => _setHalfMode(2,
                                          PizzaHalfSelectionMode.ingredients),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: (_half2Mode ==
                                        PizzaHalfSelectionMode.specialty
                                    ? _specialties
                                        .map((specialty) => _ChoiceButton(
                                              text: specialty,
                                              active:
                                                  _half2Specialty == specialty,
                                              activeColor:
                                                  const Color(0xFF2563EB),
                                              onTap: () =>
                                                  _selectHalf2Specialty(
                                                      specialty),
                                            ))
                                        .toList(growable: false)
                                    : _allIngredients
                                        .map((ingredient) => _ChoiceButton(
                                              text: ingredient,
                                              active: _half2CustomIngredients
                                                  .contains(ingredient),
                                              activeColor:
                                                  const Color(0xFF2563EB),
                                              onTap: () =>
                                                  _toggleHalfIngredient(
                                                      2, ingredient),
                                            ))
                                        .toList(growable: false)),
                              ),
                            ],
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _allIngredients
                                .map((ingredient) => _ChoiceButton(
                                      text: ingredient,
                                      active: _customIngredients
                                          .contains(ingredient),
                                      activeColor: const Color(0xFFEA580C),
                                      onTap: () =>
                                          _toggleIngredient(ingredient),
                                    ))
                                .toList(growable: false),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: _OptionSection(
                      title: 'Tamaño',
                      columns: 6,
                      mainAxisExtent: 74,
                      children: _sizes
                          .map((size) => _PriceButton(
                                label: size.name,
                                price: size.price,
                                active: _config.size == size.name,
                                color: const Color(0xFF2563EB),
                                onTap: () => setState(
                                    () => _updateConfig(size: size.name)),
                              ))
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: _OptionSection(
                      title: 'Orilla',
                      columns: 3,
                      mainAxisExtent: 74,
                      children: _crustEdges
                          .map((crust) => _PriceButton(
                                label: crust.name,
                                price: crust.name == 'Regular'
                                    ? 0
                                    : _currentCrustPrice,
                                active: _config.crustEdge == crust.name,
                                color: const Color(0xFF7C3AED),
                                onTap: () => setState(
                                  () => _updateConfig(
                                    crustEdge: crust.name,
                                    crustHalf1:
                                        crust.name == 'Orilla Mitad y Mitad'
                                            ? _splitCrustHalf1
                                            : null,
                                    crustHalf2:
                                        crust.name == 'Orilla Mitad y Mitad'
                                            ? _splitCrustHalf2
                                            : null,
                                  ),
                                ),
                              ))
                          .toList(growable: false),
                    ),
                  ),
                  if (_config.crustEdge == 'Orilla Mitad y Mitad') ...[
                    const SizedBox(height: 14),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Orilla Mitad y Mitad',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          const Text('Orilla Mitad 1',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4B5563))),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _splitCrustOptions
                                .map((option) => _ChoiceButton(
                                      text: option,
                                      active: _splitCrustHalf1 == option,
                                      activeColor: const Color(0xFF7C3AED),
                                      onTap: () =>
                                          _selectSplitCrustHalf(1, option),
                                    ))
                                .toList(growable: false),
                          ),
                          const SizedBox(height: 12),
                          const Text('Orilla Mitad 2',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4B5563))),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _splitCrustOptions
                                .map((option) => _ChoiceButton(
                                      text: option,
                                      active: _splitCrustHalf2 == option,
                                      activeColor: const Color(0xFF7C3AED),
                                      onTap: () =>
                                          _selectSplitCrustHalf(2, option),
                                    ))
                                .toList(growable: false),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: _OptionSection(
                      title: 'Tipo de Pan',
                      columns: 3,
                      mainAxisExtent: 60,
                      children: _breadTypes
                          .map((bread) => _PriceButton(
                                label: bread.name,
                                price: bread.price,
                                active: _config.breadType == bread.name,
                                color: const Color(0xFFD97706),
                                onTap: () => setState(
                                    () => _updateConfig(breadType: bread.name)),
                              ))
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: _OptionSection(
                      title: 'Cocción',
                      columns: 2,
                      mainAxisExtent: 60,
                      children: [
                        _ChoiceButton(
                          text: 'Normal',
                          active: !_config.dorada,
                          activeColor: const Color(0xFF374151),
                          onTap: () =>
                              setState(() => _updateConfig(dorada: false)),
                        ),
                        _ChoiceButton(
                          text: 'Dorada',
                          active: _config.dorada,
                          activeColor: const Color(0xFFD97706),
                          onTap: () =>
                              setState(() => _updateConfig(dorada: true)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ingredientes Extra',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          'Extra: \$${_currentExtraIngredientPrice.toStringAsFixed(2)} · Queso extra: \$${_currentExtraQuesoPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _allIngredients
                              .map((ingredient) => _ChoiceButton(
                                    text: ingredient,
                                    active:
                                        _extraIngredients.contains(ingredient),
                                    activeColor: const Color(0xFFDC2626),
                                    onTap: () =>
                                        _toggleExtraIngredient(ingredient),
                                  ))
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceOption {
  const _PriceOption({required this.name, required this.price});

  final String name;
  final double price;
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: Color(0xFF6B7280)))),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: Color(0xFF111827), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _IngredientWrap extends StatelessWidget {
  const _IngredientWrap({required this.values});

  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: values
          .map((ingredient) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(ingredient,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF374151))),
              ))
          .toList(growable: false),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8)],
      ),
      child: child,
    );
  }
}

class _OptionSection extends StatelessWidget {
  const _OptionSection({
    required this.title,
    required this.columns,
    required this.children,
    this.mainAxisExtent = 62,
  });

  final String title;
  final int columns;
  final List<Widget> children;
  final double mainAxisExtent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: mainAxisExtent,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        elevation: active ? 3 : 0,
        backgroundColor:
            active ? const Color(0xFFEA580C) : const Color(0xFFF3F4F6),
        foregroundColor: active ? Colors.white : const Color(0xFF374151),
        minimumSize: const Size(0, 44),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.text,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String text;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        elevation: active ? 3 : 0,
        backgroundColor: active ? activeColor : const Color(0xFFF3F4F6),
        foregroundColor: active ? Colors.white : const Color(0xFF374151),
        minimumSize: const Size(120, 44),
      ),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}

class _PriceButton extends StatelessWidget {
  const _PriceButton({
    required this.label,
    required this.price,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final String label;
  final double price;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        elevation: active ? 3 : 0,
        backgroundColor: active ? color : const Color(0xFFF3F4F6),
        foregroundColor: active ? Colors.white : const Color(0xFF374151),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        minimumSize: const Size(0, 48),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, textAlign: TextAlign.center),
          if (price > 0)
            Text('+ \$${price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
