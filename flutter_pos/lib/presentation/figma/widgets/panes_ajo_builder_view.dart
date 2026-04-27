import 'package:flutter/material.dart';

import '../figma_models.dart';

typedef AddPanesAjoCallback = void Function(
  GarlicBreadConfigData config,
  double price,
);

class PanesAjoBuilderView extends StatefulWidget {
  const PanesAjoBuilderView({
    super.key,
    required this.onBack,
    required this.onAddPanesAjo,
  });

  final VoidCallback onBack;
  final AddPanesAjoCallback onAddPanesAjo;

  @override
  State<PanesAjoBuilderView> createState() => _PanesAjoBuilderViewState();
}

class _PanesAjoBuilderViewState extends State<PanesAjoBuilderView> {
  static const Map<String, double> _typePrices = {
    'Normales': 69,
    'Rellenos de queso crema': 99,
    'Rellenos de queso mozzarella': 99,
    '2 y 2 (crema y mozzarella)': 99,
  };

  String _selectedType = 'Normales';

  double get _totalPrice => _typePrices[_selectedType] ?? 69;

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
                    label: const Text('Volver a Complementos'),
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Panes de Ajo',
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
                                'Tu selección',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4B5563),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const _SummaryRow(
                                  label: 'Producto:', value: 'PANES DE AJO'),
                              _SummaryRow(label: 'Tipo:', value: _selectedType),
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
                            onPressed: () => widget.onAddPanesAjo(
                              GarlicBreadConfigData(type: _selectedType),
                              _totalPrice,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Panes de Ajo a la Orden'),
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
              child: _SectionCard(
                child: _OptionSection(
                  title: 'Tipo de panes de ajo',
                  subtitle: 'Selecciona una opción',
                  columns: 2,
                  children: _typePrices.keys
                      .map(
                        (type) => _ChoiceButton(
                          text: '$type (+\$${_typePrices[type]!.toStringAsFixed(2)})',
                          active: _selectedType == type,
                          activeColor: const Color(0xFF7C3AED),
                          onTap: () => setState(() => _selectedType = type),
                        ),
                      )
                      .toList(growable: false),
                ),
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
    final itemWidth = columns == 2 ? 320.0 : 220.0;
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
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        elevation: active ? 2 : 0,
        minimumSize: const Size(0, 56),
        backgroundColor: active ? activeColor : const Color(0xFFE5E7EB),
        foregroundColor: active ? Colors.white : const Color(0xFF374151),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
