import 'package:flutter/material.dart';

import '../figma_models.dart';

typedef AddSpaghettiCallback = void Function(
  SpaghettiConfigData config,
  double price,
);

class SpaghettiBuilderView extends StatefulWidget {
  const SpaghettiBuilderView({
    super.key,
    required this.onBack,
    required this.onAddSpaghetti,
  });

  final VoidCallback onBack;
  final AddSpaghettiCallback onAddSpaghetti;

  @override
  State<SpaghettiBuilderView> createState() => _SpaghettiBuilderViewState();
}

class _SpaghettiBuilderViewState extends State<SpaghettiBuilderView> {
  static const List<String> _types = [
    'A la boloñesa',
    'Jamón y champiñón',
    'Supremo',
  ];

  static const Map<String, List<String>> _baseIngredients = {
    'A la boloñesa': ['Salsa', 'Carne'],
    'Jamón y champiñón': ['Salsa', 'Jamón', 'Champiñón'],
    'Supremo': ['Salsa', 'Carne', 'Jamón', 'Champiñón', 'Morrón'],
  };

  static const List<String> _accompaniments = ['Panes de ajo', 'Papas'];
  static const List<String> _garlicBreadTypes = [
    'Normales',
    'Queso crema',
    'Queso mozzarella',
  ];

  static const Map<String, double> _basePrices = {
    'A la boloñesa': 139,
    'Jamón y champiñón': 139,
    'Supremo': 169,
  };

  static const Map<String, double> _accompanimentPrices = {
    'Panes de ajo': 0,
    'Papas': 0,
  };

  static const Map<String, double> _garlicBreadTypePrices = {
    'Normales': 0,
    'Queso crema': 35,
    'Queso mozzarella': 35,
  };

  static const Map<String, double> _extraPrices = {
    'Tocino': 10,
    'Salchicha': 10,
  };

  String _selectedType = 'A la boloñesa';
  String _selectedAccompaniment = 'Panes de ajo';
  String _selectedGarlicBreadType = 'Normales';

  bool _sinQueso = false;
  bool _sinMantequilla = false;
  bool _pocaSalsa = false;
  bool _quesoDorado = false;
  final Set<String> _removedBaseIngredients = <String>{};

  final Set<String> _extras = <String>{};

  bool get _usesGarlicBread => _selectedAccompaniment == 'Panes de ajo';
  List<String> get _currentBaseIngredients =>
      _baseIngredients[_selectedType] ?? const <String>[];
  List<String> get _orderedRemovedIngredients => _currentBaseIngredients
      .where((ingredient) => _removedBaseIngredients.contains(ingredient))
      .toList(growable: false);

  double get _totalPrice {
    var total = _basePrices[_selectedType] ?? 0;
    total += _accompanimentPrices[_selectedAccompaniment] ?? 0;
    if (_usesGarlicBread) {
      total += _garlicBreadTypePrices[_selectedGarlicBreadType] ?? 0;
    }
    for (final extra in _extras) {
      total += _extraPrices[extra] ?? 0;
    }
    return total;
  }

  SpaghettiConfigData _buildConfig() {
    return SpaghettiConfigData(
      spaghettiType: _selectedType,
      accompaniment: _selectedAccompaniment,
      garlicBreadType: _usesGarlicBread ? _selectedGarlicBreadType : null,
      removedIngredients: _orderedRemovedIngredients,
      sinQueso: _sinQueso,
      sinMantequilla: _sinMantequilla,
      pocaSalsa: _pocaSalsa,
      quesoDorado: _quesoDorado,
      extras: _extras.toList(growable: false),
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
                BoxShadow(color: Color(0x22000000), blurRadius: 8),
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
                    'Constructor de Espagueti',
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
                              color: const Color(0xFFBFDBFE),
                              width: 2,
                            ),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tu espagueti',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4B5563),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _SummaryRow(label: 'Tipo:', value: _selectedType),
                              _SummaryRow(
                                label: 'Base:',
                                value: _currentBaseIngredients.join(' · '),
                              ),
                              _SummaryRow(
                                label: 'Acompañante:',
                                value: _selectedAccompaniment,
                              ),
                              if (_usesGarlicBread)
                                _SummaryRow(
                                  label: 'Pan de ajo:',
                                  value: '3 x $_selectedGarlicBreadType',
                                ),
                              if (_sinQueso) const _FlagLine('SIN QUESO'),
                              if (_sinMantequilla)
                                const _FlagLine('SIN MANTEQUILLA'),
                              if (_pocaSalsa) const _FlagLine('POCA SALSA'),
                              if (_quesoDorado) const _FlagLine('QUESO DORADO'),
                              for (final ingredient
                                  in _orderedRemovedIngredients)
                                _FlagLine('SIN ${ingredient.toUpperCase()}'),
                              for (final extra in _extras)
                                _FlagLine('EXTRA ${extra.toUpperCase()}'),
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
                              const Text(
                                'Precio Total',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${_totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 38,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => widget.onAddSpaghetti(
                              _buildConfig(),
                              _totalPrice,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Espagueti a la Orden'),
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
                    child: _OptionSection(
                      title: 'Tipo de espagueti',
                      columns: 3,
                      children: _types
                          .map(
                            (type) => _ChoiceButton(
                              text: type,
                              active: _selectedType == type,
                              activeColor: const Color(0xFF1D4ED8),
                              onTap: () => setState(() {
                                _selectedType = type;
                                _removedBaseIngredients.removeWhere(
                                  (ingredient) =>
                                      !_currentBaseIngredients.contains(
                                    ingredient,
                                  ),
                                );
                              }),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: _OptionSection(
                      title: 'Ingredientes',
                      columns: 3,
                      children: _currentBaseIngredients
                          .map(
                            (ingredient) => _ChoiceButton(
                              text: ingredient,
                              active:
                                  !_removedBaseIngredients.contains(ingredient),
                              activeColor: const Color(0xFF16A34A),
                              onTap: () => setState(() {
                                if (_removedBaseIngredients
                                    .contains(ingredient)) {
                                  _removedBaseIngredients.remove(ingredient);
                                } else {
                                  _removedBaseIngredients.add(ingredient);
                                }
                              }),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: _OptionSection(
                      title: 'Acompañamiento',
                      columns: 2,
                      children: _accompaniments
                          .map(
                            (item) => _ChoiceButton(
                              text: item,
                              active: _selectedAccompaniment == item,
                              activeColor: const Color(0xFF2563EB),
                              onTap: () => setState(() {
                                _selectedAccompaniment = item;
                              }),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  if (_usesGarlicBread) ...[
                    const SizedBox(height: 14),
                    _SectionCard(
                      child: _OptionSection(
                        title: 'Tipo de pan de ajo (3 piezas)',
                        columns: 3,
                        children: _garlicBreadTypes
                            .map(
                              (type) => _ChoiceButton(
                                text: type,
                                active: _selectedGarlicBreadType == type,
                                activeColor: const Color(0xFF7C3AED),
                                onTap: () => setState(
                                  () => _selectedGarlicBreadType = type,
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: _OptionSection(
                      title: 'Modificadores',
                      columns: 2,
                      children: [
                        _ChoiceButton(
                          text: 'Sin queso',
                          active: _sinQueso,
                          activeColor: const Color(0xFF334155),
                          onTap: () => setState(() => _sinQueso = !_sinQueso),
                        ),
                        _ChoiceButton(
                          text: 'Sin mantequilla',
                          active: _sinMantequilla,
                          activeColor: const Color(0xFF334155),
                          onTap: () => setState(
                              () => _sinMantequilla = !_sinMantequilla),
                        ),
                        _ChoiceButton(
                          text: 'Poca salsa',
                          active: _pocaSalsa,
                          activeColor: const Color(0xFF334155),
                          onTap: () => setState(() => _pocaSalsa = !_pocaSalsa),
                        ),
                        _ChoiceButton(
                          text: 'Queso dorado',
                          active: _quesoDorado,
                          activeColor: const Color(0xFF334155),
                          onTap: () =>
                              setState(() => _quesoDorado = !_quesoDorado),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: _OptionSection(
                      title: 'Extras',
                      columns: 2,
                      children: [
                        _ChoiceButton(
                          text: 'Extra tocino',
                          active: _extras.contains('Tocino'),
                          activeColor: const Color(0xFFEA580C),
                          onTap: () => setState(() {
                            if (_extras.contains('Tocino')) {
                              _extras.remove('Tocino');
                            } else {
                              _extras.add('Tocino');
                            }
                          }),
                        ),
                        _ChoiceButton(
                          text: 'Extra salchicha',
                          active: _extras.contains('Salchicha'),
                          activeColor: const Color(0xFFEA580C),
                          onTap: () => setState(() {
                            if (_extras.contains('Salchicha')) {
                              _extras.remove('Salchicha');
                            } else {
                              _extras.add('Salchicha');
                            }
                          }),
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagLine extends StatelessWidget {
  const _FlagLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF111827),
          fontWeight: FontWeight.w700,
        ),
      ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6)],
      ),
      padding: const EdgeInsets.all(14),
      child: child,
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
    final itemWidth = switch (columns) {
      2 => 300.0,
      3 => 220.0,
      _ => 180.0,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final effectiveWidth = itemWidth > constraints.maxWidth
                ? constraints.maxWidth
                : itemWidth;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: children
                  .map(
                    (child) => SizedBox(
                      width: effectiveWidth,
                      child: child,
                    ),
                  )
                  .toList(growable: false),
            );
          },
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
    final foreground = active ? Colors.white : const Color(0xFF111827);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Ink(
          height: 38,
          decoration: BoxDecoration(
            color: active ? activeColor : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? activeColor : const Color(0xFFD1D5DB),
            ),
            boxShadow: active
                ? const [BoxShadow(color: Color(0x22000000), blurRadius: 6)]
                : null,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
