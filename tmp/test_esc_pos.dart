import 'dart:io';
import 'dart:typed_data';

class EscPosBuilder {
  final BytesBuilder _buffer = BytesBuilder();

  static const int _esc = 0x1B;
  static const int _gs = 0x1D;

  void _writeByte(int byte) => _buffer.addByte(byte & 0xFF);
  void _writeBytes(List<int> bytes) => _buffer.add(bytes);

  EscPosBuilder init() {
    _writeBytes([_esc, 0x40]);
    return this;
  }

  EscPosBuilder alignLeft() {
    _writeBytes([_esc, 0x61, 0x00]);
    return this;
  }

  EscPosBuilder alignCenter() {
    _writeBytes([_esc, 0x61, 0x01]);
    return this;
  }

  EscPosBuilder alignRight() {
    _writeBytes([_esc, 0x61, 0x02]);
    return this;
  }

  EscPosBuilder boldOn() {
    _writeBytes([_esc, 0x45, 0x01]);
    return this;
  }

  EscPosBuilder boldOff() {
    _writeBytes([_esc, 0x45, 0x00]);
    return this;
  }

  EscPosBuilder doubleHeightOn() {
    _writeBytes([_esc, 0x21, 0x10]);
    return this;
  }

  EscPosBuilder doubleHeightOff() {
    _writeBytes([_esc, 0x21, 0x00]);
    return this;
  }

  EscPosBuilder doubleWidthOn() {
    _writeBytes([_esc, 0x21, 0x20]);
    return this;
  }

  EscPosBuilder doubleWidthOff() {
    _writeBytes([_esc, 0x21, 0x00]);
    return this;
  }

  EscPosBuilder codepage([int page = 0]) {
    _writeBytes([_esc, 0x74, page & 0xFF]);
    return this;
  }

  EscPosBuilder feed(int lines) {
    if (lines > 0) _writeBytes([_esc, 0x64, lines & 0xFF]);
    return this;
  }

  EscPosBuilder cut() {
    _writeBytes([_gs, 0x56, 0x01]);
    return this;
  }

  EscPosBuilder text(String value) {
    final sanitized = removeAccents(value);
    _buffer.add(_toLatin1Bytes(sanitized));
    return this;
  }

  EscPosBuilder line(String value) {
    text(value);
    _writeByte(0x0A);
    return this;
  }

  EscPosBuilder emptyLine() {
    _writeByte(0x0A);
    return this;
  }

  EscPosBuilder separator(String char, int width) {
    final repeated = char * width;
    return line(repeated);
  }

  Uint8List build() => _buffer.toBytes();

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
    return input.runes.map((r) => r <= 255 ? r : 0x3F).toList();
  }
}

void main() {
  const lineWidth = 42;
  const qtyWidth = 4;

  String rowQty(String text, int qty) {
    final maxNameWidth = lineWidth - qtyWidth - 1;
    final name = text.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final display = name.length > maxNameWidth ? name.substring(0, maxNameWidth) : name;
    return '${display.padRight(maxNameWidth)} ${qty.toString().padLeft(qtyWidth)}';
  }

  String headerRow() {
    const label = 'PRODUCTO';
    const qtyLabel = 'CANT.';
    final spaces = lineWidth - label.length - qtyLabel.length;
    return '$label${' ' * spaces}$qtyLabel';
  }

  final b = EscPosBuilder()
    ..init()
    ..alignCenter()
    ..boldOn()
    ..doubleHeightOn()
    ..line('COMANDA COCINA')
    ..doubleHeightOff()
    ..boldOff()
    ..emptyLine()
    ..alignLeft();

  b..boldOn()..text('Mesa: ')..boldOff()..line('15');
  b..boldOn()..text('Recibo No.: ')..boldOff()..line('19315');
  b..boldOn()..text('Area: ')..boldOff()..line('FREIDORAS Y PLANCHA');
  b..boldOn()..text('Mesero: ')..boldOff()..line('ALEX');
  b..boldOn()..text('Enviado: ')..boldOff()..line('31 mayo 2026 00:19');

  b.separator('-', lineWidth);
  b..boldOn()..line(headerRow())..boldOff();
  b.separator('-', lineWidth);

  b.line(rowQty('Ensalada', 1));

  b.separator('-', lineWidth);
  b..boldOn()..line('Comentarios:')..boldOff();
  b.line('Sin cebolla, aderezo aparte');

  b..emptyLine()..emptyLine()..feed(3)..cut();

  final bytes = b.build();

  // Guardar binario
  File('comanda_test.bin').writeAsBytesSync(bytes);

  // Guardar representación hex+ASCII para inspección
  final hexLines = <String>[];
  final asciiLines = <String>[];
  for (var i = 0; i < bytes.length; i += 16) {
    final chunk = bytes.sublist(i, (i + 16).clamp(0, bytes.length));
    final hex = chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    final ascii = chunk.map((b) {
      final c = String.fromCharCode(b);
      return (b >= 32 && b < 127) ? c : '.';
    }).join();
    hexLines.add('${i.toString().padLeft(4, '0')}:  ${hex.padRight(48)}  $ascii');
  }

  File('comanda_test_hex.txt').writeAsStringSync(hexLines.join('\n'));

  // También generar una simulación de texto plano para visualizar
  final textSim = StringBuffer();
  textSim.writeln('        COMANDA COCINA');
  textSim.writeln();
  textSim.writeln('Mesa: 15');
  textSim.writeln('Recibo No.: 19315');
  textSim.writeln('Area: FREIDORAS Y PLANCHA');
  textSim.writeln('Mesero: ALEX');
  textSim.writeln('Enviado: 31 mayo 2026 00:19');
  textSim.writeln('------------------------------------------');
  textSim.writeln('PRODUCTO                           CANT.');
  textSim.writeln('------------------------------------------');
  textSim.writeln('ENSALADA                             1');
  textSim.writeln('------------------------------------------');
  textSim.writeln('Comentarios:');
  textSim.writeln('Sin cebolla, aderezo aparte');

  File('comanda_test_visual.txt').writeAsStringSync(textSim.toString());

  print('Comanda generada:');
  print('  - tmp/comanda_test.bin        (${bytes.length} bytes ESC/POS)');
  print('  - tmp/comanda_test_hex.txt    (vista hex/ascii)');
  print('  - tmp/comanda_test_visual.txt (simulacion visual)');
}
