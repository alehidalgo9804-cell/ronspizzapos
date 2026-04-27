import 'package:flutter/material.dart';

import '../figma_models.dart';

typedef AddHamburgerCallback = void Function(
    HamburgerConfigData config, double price);

class HamburgerBuilderView extends StatefulWidget {
  const HamburgerBuilderView({
    super.key,
    required this.onBack,
    required this.onAddHamburger,
  });

  final VoidCallback onBack;
  final AddHamburgerCallback onAddHamburger;

  @override
  State<HamburgerBuilderView> createState() => _HamburgerBuilderViewState();
}

class _HamburgerBuilderViewState extends State<HamburgerBuilderView> {
  static const double _extraPrice = 1.50;
  static const List<String> _baseIngredients = [
    'Mayonesa',
    'Pepinillos',
    'Cebolla',
    'Tomate',
    'Lechuga',
    'Queso',
  ];
  static const List<String> _vegetables = [
    'Pepinillos',
    'Cebolla',
    'Tomate',
    'Lechuga',
  ];
  static const List<String> _extras = [
    'Extra tocino',
    'Extra queso',
    'Extra jamón',
  ];

  static const Map<String, double> _burgerPrices = {
    'Clásica': 139,
    'Jamón y tocino': 159,
    'Doble carne': 169,
    'Megaburguer': 189,
    'Especial de hamburguesas': 190,
  };

  String _burgerType = 'Clásica';
  HamburgerSideOption _side = HamburgerSideOption.conPapas;

  final Set<String> _removedIngredients = <String>{};
  final Set<String> _extraIngredients = <String>{};
  bool _usedSinVerdura = false;
  HamburgerCutOption _cutOption = HamburgerCutOption.completa;

  final _ComboBurgerState _combo1 = _ComboBurgerState();
  final _ComboBurgerState _combo2 = _ComboBurgerState();

  bool get _isSpecialCombo => _burgerType == 'Especial de hamburguesas';

  double get _sideAdjustment {
    switch (_side) {
      case HamburgerSideOption.conPapas:
        return 0;
      case HamburgerSideOption.sinPapas:
        return -39;
      case HamburgerSideOption.conAros:
        return 20;
    }
  }

  double get _extrasAdjustment {
    if (_isSpecialCombo) {
      return (_combo1.extraIngredients.length +
              _combo2.extraIngredients.length) *
          _extraPrice;
    }
    return _extraIngredients.length * _extraPrice;
  }

  double get _totalPrice {
    final base = _burgerPrices[_burgerType] ?? 0;
    return base + _sideAdjustment + _extrasAdjustment;
  }

  String _sideLabel(HamburgerSideOption value) {
    switch (value) {
      case HamburgerSideOption.conPapas:
        return 'Con papas';
      case HamburgerSideOption.sinPapas:
        return 'Sin papas';
      case HamburgerSideOption.conAros:
        return 'Con aros';
    }
  }

  String _cutLabel(HamburgerCutOption value) {
    switch (value) {
      case HamburgerCutOption.completa:
        return 'Completa';
      case HamburgerCutOption.partidaMitad:
        return 'Partida a la mitad';
    }
  }

  void _selectBurgerType(String type) {
    setState(() {
      _burgerType = type;
      if (_isSpecialCombo) {
        _side = HamburgerSideOption.conPapas;
      }
    });
  }

  void _toggleIngredient(String ingredient) {
    setState(() {
      if (_removedIngredients.contains(ingredient)) {
        _removedIngredients.remove(ingredient);
      } else {
        _removedIngredients.add(ingredient);
      }
      _usedSinVerdura = _vegetables.every(
          (ingredientName) => _removedIngredients.contains(ingredientName));
    });
  }

  void _applySinVerdura() {
    setState(() {
      _usedSinVerdura = true;
      _removedIngredients.addAll(_vegetables);
    });
  }

  void _toggleExtra(String extra) {
    setState(() {
      if (_extraIngredients.contains(extra)) {
        _extraIngredients.remove(extra);
      } else {
        _extraIngredients.add(extra);
      }
    });
  }

  HamburgerConfigData _buildConfig() {
    if (_isSpecialCombo) {
      return HamburgerConfigData(
        burgerType: _burgerType,
        side: _side,
        isSpecialCombo: true,
        burger1: _combo1.toUnitConfig(),
        burger2: _combo2.toUnitConfig(),
      );
    }
    return HamburgerConfigData(
      burgerType: _burgerType,
      side: _side,
      removedIngredients: _removedIngredients.toList(growable: false),
      extraIngredients: _extraIngredients.toList(growable: false),
      usedSinVerduraQuickAction: _usedSinVerdura,
      cutOption: _cutOption,
      isSpecialCombo: false,
    );
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
                  child: Text(
                    'Constructor de Hamburguesas',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
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
                                color: const Color(0xFFBFDBFE), width: 2),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tu Hamburguesa',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4B5563),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _SummaryRow(label: 'Tipo:', value: _burgerType),
                              _SummaryRow(
                                  label: 'Acompañante:',
                                  value: _sideLabel(_side)),
                              if (_isSpecialCombo) ...[
                                _ComboSummarySection(
                                    title: 'Hamburguesa 1', state: _combo1),
                                const SizedBox(height: 8),
                                _ComboSummarySection(
                                    title: 'Hamburguesa 2', state: _combo2),
                              ] else ...[
                                _SummaryRow(
                                    label: 'Corte:',
                                    value: _cutLabel(_cutOption)),
                                const SizedBox(height: 6),
                                if (_usedSinVerdura)
                                  const Text('SIN VERDURA',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF111827),
                                          fontWeight: FontWeight.w700))
                                else if (_removedIngredients.isNotEmpty)
                                  Text(
                                    _removedIngredients
                                        .map((item) =>
                                            'SIN ${item.toUpperCase()}')
                                        .join(' · '),
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF4B5563)),
                                  ),
                                if (_extraIngredients.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      _extraIngredients
                                          .map((item) => item.toUpperCase())
                                          .join(' · '),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF4B5563),
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
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
                              Text(
                                '\$${_totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 38,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => widget.onAddHamburger(
                                _buildConfig(), _totalPrice),
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Hamburguesa a la Orden'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 52),
                            ),
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
                    child: _BurgerTypeSection(
                      burgerType: _burgerType,
                      onSelect: _selectBurgerType,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: _OptionSection(
                      title: 'Acompañante',
                      columns: 3,
                      children: [
                        _ChoiceButton(
                          text: 'Con papas',
                          active: _side == HamburgerSideOption.conPapas,
                          activeColor: const Color(0xFF1D4ED8),
                          onTap: () => setState(
                              () => _side = HamburgerSideOption.conPapas),
                        ),
                        _ChoiceButton(
                          text: 'Sin papas',
                          active: _side == HamburgerSideOption.sinPapas,
                          activeColor: const Color(0xFF1D4ED8),
                          onTap: () => setState(
                              () => _side = HamburgerSideOption.sinPapas),
                        ),
                        _ChoiceButton(
                          text: 'Con aros',
                          active: _side == HamburgerSideOption.conAros,
                          activeColor: const Color(0xFF1D4ED8),
                          onTap: () => setState(
                              () => _side = HamburgerSideOption.conAros),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_isSpecialCombo) ...[
                    _SectionCard(
                      child: _ComboBurgerSection(
                        title: 'Hamburguesa 1',
                        state: _combo1,
                        onChanged: () => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      child: _ComboBurgerSection(
                        title: 'Hamburguesa 2',
                        state: _combo2,
                        onChanged: () => setState(() {}),
                      ),
                    ),
                  ] else ...[
                    _SectionCard(
                      child: _IngredientSection(
                        baseIngredients: _baseIngredients,
                        removedIngredients: _removedIngredients,
                        onToggle: _toggleIngredient,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      child: _OptionSection(
                        title: 'Acciones Rápidas',
                        columns: 1,
                        children: [
                          _ChoiceButton(
                            text: 'Sin verdura',
                            active: _usedSinVerdura,
                            activeColor: const Color(0xFFDC2626),
                            onTap: _applySinVerdura,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      child: _OptionSection(
                        title: 'Extras',
                        columns: 3,
                        children: _extras
                            .map((extra) => _ChoiceButton(
                                  text: extra,
                                  active: _extraIngredients.contains(extra),
                                  activeColor: const Color(0xFFEA580C),
                                  onTap: () => _toggleExtra(extra),
                                ))
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      child: _OptionSection(
                        title: 'Corte',
                        columns: 2,
                        children: [
                          _ChoiceButton(
                            text: 'Completa',
                            active: _cutOption == HamburgerCutOption.completa,
                            activeColor: const Color(0xFF374151),
                            onTap: () => setState(
                                () => _cutOption = HamburgerCutOption.completa),
                          ),
                          _ChoiceButton(
                            text: 'Partida a la mitad',
                            active:
                                _cutOption == HamburgerCutOption.partidaMitad,
                            activeColor: const Color(0xFF374151),
                            onTap: () => setState(() =>
                                _cutOption = HamburgerCutOption.partidaMitad),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComboBurgerState {
  final Set<String> removedIngredients = <String>{};
  final Set<String> extraIngredients = <String>{};
  bool usedSinVerduraQuickAction = false;
  HamburgerCutOption cutOption = HamburgerCutOption.completa;

  void toggleIngredient(String value, List<String> vegetables) {
    if (removedIngredients.contains(value)) {
      removedIngredients.remove(value);
    } else {
      removedIngredients.add(value);
    }
    usedSinVerduraQuickAction = vegetables
        .every((ingredientName) => removedIngredients.contains(ingredientName));
  }

  void applySinVerdura(List<String> vegetables) {
    usedSinVerduraQuickAction = true;
    removedIngredients.addAll(vegetables);
  }

  void toggleExtra(String value) {
    if (extraIngredients.contains(value)) {
      extraIngredients.remove(value);
    } else {
      extraIngredients.add(value);
    }
  }

  HamburgerUnitConfigData toUnitConfig() {
    return HamburgerUnitConfigData(
      removedIngredients: removedIngredients.toList(growable: false),
      extraIngredients: extraIngredients.toList(growable: false),
      usedSinVerduraQuickAction: usedSinVerduraQuickAction,
      cutOption: cutOption,
    );
  }

  bool get hasChanges =>
      usedSinVerduraQuickAction ||
      removedIngredients.isNotEmpty ||
      extraIngredients.isNotEmpty ||
      cutOption == HamburgerCutOption.partidaMitad;
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

class _BurgerTypeSection extends StatelessWidget {
  const _BurgerTypeSection({
    required this.burgerType,
    required this.onSelect,
  });

  final String burgerType;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const types = [
      'Clásica',
      'Jamón y tocino',
      'Doble carne',
      'Megaburguer',
      'Especial de hamburguesas',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de Hamburguesa',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: types
              .map(
                (type) => _ChoiceButton(
                  text: type,
                  active: burgerType == type,
                  activeColor: const Color(0xFF1D4ED8),
                  onTap: () => onSelect(type),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _IngredientSection extends StatelessWidget {
  const _IngredientSection({
    required this.baseIngredients,
    required this.removedIngredients,
    required this.onToggle,
  });

  final List<String> baseIngredients;
  final Set<String> removedIngredients;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ingredientes incluidos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Toca para quitar ingrediente',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: baseIngredients
              .map((ingredient) => _ChoiceButton(
                    text: ingredient,
                    active: !removedIngredients.contains(ingredient),
                    activeColor: const Color(0xFF16A34A),
                    onTap: () => onToggle(ingredient),
                  ))
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _OptionSection extends StatelessWidget {
  const _OptionSection({
    required this.title,
    required this.columns,
    required this.children,
  });

  final String title;
  final int columns;
  final List<Widget> children;

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
            mainAxisExtent: 56,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        ),
      ],
    );
  }
}

class _ComboBurgerSection extends StatelessWidget {
  const _ComboBurgerSection({
    required this.title,
    required this.state,
    required this.onChanged,
  });

  final String title;
  final _ComboBurgerState state;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    const baseIngredients = [
      'Mayonesa',
      'Pepinillos',
      'Cebolla',
      'Tomate',
      'Lechuga',
      'Queso',
    ];
    const vegetables = ['Pepinillos', 'Cebolla', 'Tomate', 'Lechuga'];
    const extras = ['Extra tocino', 'Extra queso', 'Extra jamón'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _IngredientSection(
          baseIngredients: baseIngredients,
          removedIngredients: state.removedIngredients,
          onToggle: (value) {
            state.toggleIngredient(value, vegetables);
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        _OptionSection(
          title: 'Acciones Rápidas',
          columns: 1,
          children: [
            _ChoiceButton(
              text: 'Sin verdura',
              active: state.usedSinVerduraQuickAction,
              activeColor: const Color(0xFFDC2626),
              onTap: () {
                state.applySinVerdura(vegetables);
                onChanged();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        _OptionSection(
          title: 'Extras',
          columns: 3,
          children: extras
              .map((extra) => _ChoiceButton(
                    text: extra,
                    active: state.extraIngredients.contains(extra),
                    activeColor: const Color(0xFFEA580C),
                    onTap: () {
                      state.toggleExtra(extra);
                      onChanged();
                    },
                  ))
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        _OptionSection(
          title: 'Corte',
          columns: 2,
          children: [
            _ChoiceButton(
              text: 'Completa',
              active: state.cutOption == HamburgerCutOption.completa,
              activeColor: const Color(0xFF374151),
              onTap: () {
                state.cutOption = HamburgerCutOption.completa;
                onChanged();
              },
            ),
            _ChoiceButton(
              text: 'Partida a la mitad',
              active: state.cutOption == HamburgerCutOption.partidaMitad,
              activeColor: const Color(0xFF374151),
              onTap: () {
                state.cutOption = HamburgerCutOption.partidaMitad;
                onChanged();
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _ComboSummarySection extends StatelessWidget {
  const _ComboSummarySection({
    required this.title,
    required this.state,
  });

  final String title;
  final _ComboBurgerState state;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];
    if (state.usedSinVerduraQuickAction) {
      lines.add('SIN VERDURA');
    } else {
      lines.addAll(
        state.removedIngredients.map((value) => 'SIN ${value.toUpperCase()}'),
      );
    }
    lines.addAll(state.extraIngredients.map((value) => value.toUpperCase()));
    if (state.cutOption == HamburgerCutOption.partidaMitad) {
      lines.add('PARTIDA A LA MITAD');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          lines.isEmpty ? 'Sin cambios' : lines.join(' · '),
          style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
        ),
      ],
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
