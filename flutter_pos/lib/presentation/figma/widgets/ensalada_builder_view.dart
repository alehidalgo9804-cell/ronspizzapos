import 'package:flutter/material.dart';

import '../figma_models.dart';

typedef AddEnsaladaCallback = void Function(
    SaladConfigData config, double price);

class EnsaladaBuilderView extends StatefulWidget {
  const EnsaladaBuilderView({
    super.key,
    required this.onBack,
    required this.onAddEnsalada,
  });

  final VoidCallback onBack;
  final AddEnsaladaCallback onAddEnsalada;

  @override
  State<EnsaladaBuilderView> createState() => _EnsaladaBuilderViewState();
}

class _EnsaladaBuilderViewState extends State<EnsaladaBuilderView> {
  static const double _basePrice = 69;
  static const Map<String, double> _addOnPrices = {
    'Carne': 30,
    'Boneless': 50,
  };
  static const List<String> _ingredients = [
    'Pepino',
    'Lechuga',
    'Tomate',
    'Zanahoria',
    'Repollo morado',
  ];
  static const List<String> _addOns = ['Carne', 'Boneless'];

  final Set<String> _removed = <String>{};
  final Set<String> _selectedAddOns = <String>{};

  double get _totalPrice {
    var total = _basePrice;
    for (final addOn in _selectedAddOns) {
      total += _addOnPrices[addOn] ?? 0;
    }
    return total;
  }

  SaladConfigData _buildConfig() {
    return SaladConfigData(
      removedIngredients: _removed.toList(growable: false),
      addOns: _selectedAddOns.toList(growable: false),
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
                    label: const Text('Volver a Complementos'),
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Constructor de Ensalada',
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
                                'Tu ensalada',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4B5563),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const _SummaryRow(
                                  label: 'Producto:', value: 'ENSALADA'),
                              if (_removed.isNotEmpty)
                                _SummaryRow(
                                  label: 'Sin:',
                                  value: _removed
                                      .map((value) => value.toUpperCase())
                                      .join(' · '),
                                ),
                              if (_selectedAddOns.isNotEmpty)
                                _SummaryRow(
                                  label: 'Con:',
                                  value: _selectedAddOns
                                      .map((value) => value.toUpperCase())
                                      .join(' · '),
                                ),
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
                                    fontSize: 12, color: Colors.white70),
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
                            onPressed: () => widget.onAddEnsalada(
                                _buildConfig(), _totalPrice),
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Ensalada a la Orden'),
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
                      title: 'Ingredientes base',
                      subtitle: 'Toca para quitar ingrediente',
                      columns: 3,
                      children: _ingredients
                          .map(
                            (ingredient) => _ChoiceButton(
                              text: ingredient,
                              active: !_removed.contains(ingredient),
                              activeColor: const Color(0xFF16A34A),
                              onTap: () => setState(() {
                                if (_removed.contains(ingredient)) {
                                  _removed.remove(ingredient);
                                } else {
                                  _removed.add(ingredient);
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
                      title: 'Adiciones',
                      subtitle: 'Opcional',
                      columns: 2,
                      children: _addOns
                          .map(
                            (addOn) => _ChoiceButton(
                              text: addOn,
                              active: _selectedAddOns.contains(addOn),
                              activeColor: const Color(0xFF1D4ED8),
                              onTap: () => setState(() {
                                if (_selectedAddOns.contains(addOn)) {
                                  _selectedAddOns.remove(addOn);
                                } else {
                                  _selectedAddOns.add(addOn);
                                }
                              }),
                            ),
                          )
                          .toList(growable: false),
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
  const _SummaryRow({
    required this.label,
    required this.value,
  });

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
    required this.subtitle,
    required this.columns,
    required this.children,
  });

  final String title;
  final String subtitle;
  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final itemWidth = columns == 2 ? 300.0 : 220.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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
