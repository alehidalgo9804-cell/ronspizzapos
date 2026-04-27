import 'package:flutter/material.dart';

import '../figma_models.dart';

typedef AddWingsCallback = void Function(WingsConfigData config, double price);

class WingsBuilderView extends StatefulWidget {
  const WingsBuilderView({
    super.key,
    required this.onBack,
    required this.onAddWings,
    this.builderTitle = 'Constructor de Alitas',
    this.summaryTitle = 'Tu orden de alitas',
    this.itemPrefix = 'ALITAS',
    this.addButtonLabel = 'Agregar Alitas a la Orden',
  });

  final VoidCallback onBack;
  final AddWingsCallback onAddWings;
  final String builderTitle;
  final String summaryTitle;
  final String itemPrefix;
  final String addButtonLabel;

  @override
  State<WingsBuilderView> createState() => _WingsBuilderViewState();
}

class _WingsBuilderViewState extends State<WingsBuilderView> {
  static const Map<WingsSizeOption, String> _sizeLabels = {
    WingsSizeOption.mediaOrden: '1/2 orden',
    WingsSizeOption.orden: 'Orden',
    WingsSizeOption.megaOrden: 'Mega orden',
  };

  static const Map<WingsSizeOption, double> _sizePrices = {
    WingsSizeOption.mediaOrden: 149,
    WingsSizeOption.orden: 189,
    WingsSizeOption.megaOrden: 699,
  };

  static const List<String> _sauces = [
    'Salsa ligera',
    'Salsa mediana',
    'Salsa caliente',
    'Salsa terrible',
    'Salsa BBQ',
    'Salsa tamarindo',
    'Salsa mango habanero',
  ];

  static const Map<WingsBoneType, String> _boneLabels = {
    WingsBoneType.unHueso: '1 hueso',
    WingsBoneType.dosHuesos: '2 huesos',
  };

  WingsSizeOption _size = WingsSizeOption.orden;
  WingsSauceMode _sauceMode = WingsSauceMode.unica;
  String _sauce = 'Salsa mediana';
  String _sauceHalf1 = 'Salsa mediana';
  String _sauceHalf2 = 'Salsa mango habanero';
  bool _naturales = false;
  bool _sauceOnSide = false;
  bool _juicy = false;
  bool _doradas = false;
  WingsBoneType? _boneType;
  bool _sinZanahoria = false;
  bool _sinApio = false;

  double get _totalPrice => _sizePrices[_size] ?? 0;

  String _shortSauceName(String value) {
    return value.replaceFirst(RegExp(r'^Salsa\s+', caseSensitive: false), '');
  }

  String _summarySauceLine() {
    if (_naturales) {
      if (_sauceOnSide) {
        return _sauceMode == WingsSauceMode.mitadMitad
            ? 'NATURALES + MITAD ${_shortSauceName(_sauceHalf1).toUpperCase()} / ${_shortSauceName(_sauceHalf2).toUpperCase()} APARTE'
            : 'NATURALES + SALSA ${_shortSauceName(_sauce).toUpperCase()} APARTE';
      }
      return 'NATURALES';
    }

    if (_sauceMode == WingsSauceMode.mitadMitad) {
      final halfLine =
          '1/2 ${_shortSauceName(_sauceHalf1).toUpperCase()} / 1/2 ${_shortSauceName(_sauceHalf2).toUpperCase()}';
      return _sauceOnSide ? '$halfLine APARTE' : halfLine;
    }

    final singleLine = 'SALSA ${_shortSauceName(_sauce).toUpperCase()}';
    return _sauceOnSide ? '$singleLine APARTE' : singleLine;
  }

  WingsConfigData _buildConfig() {
    return WingsConfigData(
      size: _size,
      sauceMode: _sauceMode,
      sauce: _sauceMode == WingsSauceMode.unica ? _sauce : null,
      sauceHalf1: _sauceMode == WingsSauceMode.mitadMitad ? _sauceHalf1 : null,
      sauceHalf2: _sauceMode == WingsSauceMode.mitadMitad ? _sauceHalf2 : null,
      naturales: _naturales,
      sauceOnSide: _sauceOnSide,
      juicy: _juicy,
      doradas: _doradas,
      boneType: _boneType,
      sinApio: _sinApio,
      sinZanahoria: _sinZanahoria,
    );
  }

  String _itemName() =>
      '${widget.itemPrefix} ${_sizeLabels[_size]!.toUpperCase()}';

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
                    label: const Text('Volver a Categorias'),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.builderTitle,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w700),
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
                              Text(
                                widget.summaryTitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4B5563),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _SummaryRow(
                                  label: 'Producto:', value: _itemName()),
                              _SummaryRow(
                                label: 'Tamano:',
                                value: _sizeLabels[_size]!,
                              ),
                              _SummaryRow(
                                  label: 'Salsa:', value: _summarySauceLine()),
                              if (_boneType != null)
                                _SummaryRow(
                                  label: 'Pieza:',
                                  value: _boneLabels[_boneType]!,
                                ),
                              if (_juicy) const _FlagLine('JUGOSAS'),
                              if (_doradas) const _FlagLine('DORADAS'),
                              if (_sinApio) const _FlagLine('SIN APIO'),
                              if (_sinZanahoria)
                                const _FlagLine('SIN ZANAHORIA'),
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
                            onPressed: () =>
                                widget.onAddWings(_buildConfig(), _totalPrice),
                            icon: const Icon(Icons.add),
                            label: Text(widget.addButtonLabel),
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
                      title: 'Tamano',
                      columns: 3,
                      children: WingsSizeOption.values
                          .map(
                            (size) => _ChoiceButton(
                              text: _sizeLabels[size]!,
                              active: _size == size,
                              activeColor: const Color(0xFF1D4ED8),
                              onTap: () => setState(() => _size = size),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Salsas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: 190,
                              child: _ChoiceButton(
                                text: 'Salsa normal',
                                active: _sauceMode == WingsSauceMode.unica,
                                activeColor: const Color(0xFFEA580C),
                                onTap: () => setState(
                                    () => _sauceMode = WingsSauceMode.unica),
                              ),
                            ),
                            SizedBox(
                              width: 190,
                              child: _ChoiceButton(
                                text: '1/2 y 1/2',
                                active: _sauceMode == WingsSauceMode.mitadMitad,
                                activeColor: const Color(0xFFEA580C),
                                onTap: () => setState(() =>
                                    _sauceMode = WingsSauceMode.mitadMitad),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_sauceMode == WingsSauceMode.unica)
                          _OptionSection(
                            title: 'Selecciona salsa',
                            columns: 3,
                            topSpacing: 0,
                            children: _sauces
                                .map(
                                  (sauce) => _ChoiceButton(
                                    text: sauce,
                                    active: _sauce == sauce,
                                    activeColor: const Color(0xFFEA580C),
                                    onTap: () => setState(() => _sauce = sauce),
                                  ),
                                )
                                .toList(growable: false),
                          )
                        else
                          Column(
                            children: [
                              _OptionSection(
                                title: 'Salsa 1',
                                columns: 3,
                                topSpacing: 0,
                                children: _sauces
                                    .map(
                                      (sauce) => _ChoiceButton(
                                        text: sauce,
                                        active: _sauceHalf1 == sauce,
                                        activeColor: const Color(0xFFEA580C),
                                        onTap: () =>
                                            setState(() => _sauceHalf1 = sauce),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                              const SizedBox(height: 10),
                              _OptionSection(
                                title: 'Salsa 2',
                                columns: 3,
                                topSpacing: 0,
                                children: _sauces
                                    .map(
                                      (sauce) => _ChoiceButton(
                                        text: sauce,
                                        active: _sauceHalf2 == sauce,
                                        activeColor: const Color(0xFFEA580C),
                                        onTap: () =>
                                            setState(() => _sauceHalf2 = sauce),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: _OptionSection(
                      title: 'Preparacion',
                      columns: 2,
                      children: [
                        _ChoiceButton(
                          text: 'Naturales',
                          active: _naturales,
                          activeColor: const Color(0xFF059669),
                          onTap: () => setState(() => _naturales = !_naturales),
                        ),
                        _ChoiceButton(
                          text: 'Salsa aparte',
                          active: _sauceOnSide,
                          activeColor: const Color(0xFF059669),
                          onTap: () =>
                              setState(() => _sauceOnSide = !_sauceOnSide),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: _OptionSection(
                      title: 'Coccion',
                      columns: 2,
                      children: [
                        _ChoiceButton(
                          text: 'Jugosas',
                          active: _juicy,
                          activeColor: const Color(0xFF7C3AED),
                          onTap: () => setState(() => _juicy = !_juicy),
                        ),
                        _ChoiceButton(
                          text: 'Doradas',
                          active: _doradas,
                          activeColor: const Color(0xFF7C3AED),
                          onTap: () => setState(() => _doradas = !_doradas),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: _OptionSection(
                      title: 'Tipo de pieza',
                      columns: 2,
                      children: [
                        _ChoiceButton(
                          text: '1 hueso',
                          active: _boneType == WingsBoneType.unHueso,
                          activeColor: const Color(0xFF0EA5E9),
                          onTap: () => setState(() {
                            _boneType = _boneType == WingsBoneType.unHueso
                                ? null
                                : WingsBoneType.unHueso;
                          }),
                        ),
                        _ChoiceButton(
                          text: '2 huesos',
                          active: _boneType == WingsBoneType.dosHuesos,
                          activeColor: const Color(0xFF0EA5E9),
                          onTap: () => setState(() {
                            _boneType = _boneType == WingsBoneType.dosHuesos
                                ? null
                                : WingsBoneType.dosHuesos;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: _OptionSection(
                      title: 'Vegetales incluidos',
                      columns: 2,
                      children: [
                        _ChoiceButton(
                          text: _sinZanahoria ? 'Sin zanahoria' : 'Zanahoria',
                          active: !_sinZanahoria,
                          activeColor: const Color(0xFF16A34A),
                          onTap: () =>
                              setState(() => _sinZanahoria = !_sinZanahoria),
                        ),
                        _ChoiceButton(
                          text: _sinApio ? 'Sin apio' : 'Apio',
                          active: !_sinApio,
                          activeColor: const Color(0xFF16A34A),
                          onTap: () => setState(() => _sinApio = !_sinApio),
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
    required this.columns,
    required this.children,
    this.topSpacing = 10,
  });

  final String title;
  final int columns;
  final List<Widget> children;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    final targetItemWidth = columns == 2 ? 300.0 : 220.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: topSpacing),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = targetItemWidth > constraints.maxWidth
                ? constraints.maxWidth
                : targetItemWidth;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: children
                  .map(
                    (child) => SizedBox(
                      width: itemWidth,
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
