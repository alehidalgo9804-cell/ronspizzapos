import 'dart:typed_data';

/// Builder para generar comandos ESC/POS en bytes raw.
/// Compatible con impresoras térmicas genéricas ESC/POS.
class EscPosBuilder {
  final BytesBuilder _buffer = BytesBuilder();

  static const int _esc = 0x1B;
  static const int _gs = 0x1D;

  void _writeByte(int byte) => _buffer.addByte(byte & 0xFF);
  void _writeBytes(List<int> bytes) => _buffer.add(bytes);

  /// Inicializa la impresora (ESC @)
  EscPosBuilder init() {
    _writeBytes([_esc, 0x40]);
    return this;
  }

  /// Alinea a la izquierda (ESC a 0)
  EscPosBuilder alignLeft() {
    _writeBytes([_esc, 0x61, 0x00]);
    return this;
  }

  /// Alinea al centro (ESC a 1)
  EscPosBuilder alignCenter() {
    _writeBytes([_esc, 0x61, 0x01]);
    return this;
  }

  /// Alinea a la derecha (ESC a 2)
  EscPosBuilder alignRight() {
    _writeBytes([_esc, 0x61, 0x02]);
    return this;
  }

  /// Define margen izquierdo en puntos (GS L nL nH).
  /// 1 punto suele equivaler aprox. a 1/203".
  EscPosBuilder leftMargin(int dots) {
    final safeDots = dots < 0 ? 0 : (dots > 65535 ? 65535 : dots);
    final nL = safeDots & 0xFF;
    final nH = (safeDots >> 8) & 0xFF;
    _writeBytes([_gs, 0x4C, nL, nH]);
    return this;
  }

  /// Activa negrita (ESC E 1)
  EscPosBuilder boldOn() {
    _writeBytes([_esc, 0x45, 0x01]);
    return this;
  }

  /// Desactiva negrita (ESC E 0)
  EscPosBuilder boldOff() {
    _writeBytes([_esc, 0x45, 0x00]);
    return this;
  }

  /// Activa doble altura (ESC ! 0x10)
  EscPosBuilder doubleHeightOn() {
    _writeBytes([_esc, 0x21, 0x10]);
    return this;
  }

  /// Desactiva doble altura (ESC ! 0x00)
  EscPosBuilder doubleHeightOff() {
    _writeBytes([_esc, 0x21, 0x00]);
    return this;
  }

  /// Activa doble anchura (ESC ! 0x20)
  EscPosBuilder doubleWidthOn() {
    _writeBytes([_esc, 0x21, 0x20]);
    return this;
  }

  /// Desactiva doble anchura (ESC ! 0x00)
  EscPosBuilder doubleWidthOff() {
    _writeBytes([_esc, 0x21, 0x00]);
    return this;
  }

  /// Selecciona codepage (ESC t n). Por defecto CP437 (n=0).
  EscPosBuilder codepage([int page = 0]) {
    _writeBytes([_esc, 0x74, page & 0xFF]);
    return this;
  }

  /// Selecciona fuente A (ESC M 0).
  EscPosBuilder selectFontA() {
    _writeBytes([_esc, 0x4D, 0x00]);
    return this;
  }

  /// Selecciona fuente B (ESC M 1).
  EscPosBuilder selectFontB() {
    _writeBytes([_esc, 0x4D, 0x01]);
    return this;
  }

  /// Avanza [lines] líneas (ESC d n)
  EscPosBuilder feed(int lines) {
    if (lines > 0) _writeBytes([_esc, 0x64, lines & 0xFF]);
    return this;
  }

  /// Corte parcial (GS V 1)
  EscPosBuilder cut() {
    _writeBytes([_gs, 0x56, 0x01]);
    return this;
  }

  /// Escribe texto sin salto de línea. Se sanitizan acentos.
  EscPosBuilder text(String value) {
    final sanitized = removeAccents(value);
    _buffer.add(_toLatin1Bytes(sanitized));
    return this;
  }

  /// Escribe texto + salto de línea (LF)
  EscPosBuilder line(String value) {
    text(value);
    _writeByte(0x0A);
    return this;
  }

  /// Salto de línea vacío
  EscPosBuilder emptyLine() {
    _writeByte(0x0A);
    return this;
  }

  /// Línea separadora repetida [width] veces.
  EscPosBuilder separator(String char, int width) {
    final repeated = char * width;
    return line(repeated);
  }

  /// Construye el payload final.
  Uint8List build() => _buffer.toBytes();

  /// Reemplaza acentos y caracteres problemáticos por equivalentes ASCII
  /// seguros para impresoras térmicas genéricas.
  static String removeAccents(String input) {
    const from = 'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖØòóôõöøÙÚÛÜùúûü'
        'ÝýÿÑñÇç'
        'ÁÉÍÓÚáéíóúÜü¡¿№ºª';
    const to = 'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOOooooooUUUUuuuu'
        'YyyNnCc'
        'AEIOUaeiouUu!?No.oa';
    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      final idx = from.indexOf(ch);
      buffer.write(idx >= 0 ? to[idx] : ch);
    }
    return buffer.toString();
  }

  static List<int> _toLatin1Bytes(String input) {
    // Como ya removemos acentos, el texto debería caber en Latin1.
    // Cualquier rune fuera de rango se reemplaza por '?'.
    return input.runes.map((r) => r <= 255 ? r : 0x3F).toList();
  }
}
