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
  // Simular texto plano generado por _buildCustomerReceiptText
  final plainLines = [
    '            Rons Pizza',
    '------------------------------------------',
    'Ticket: 00042',
    'Cajero: ALEX',
    'Hora: 31/05/2026 00:19',
    'Tipo: Dine In',
    'Mesa: 15',
    '------------------------------------------',
    'Nombre                Cant   Precio    Total',
    'PIZZA MEDIANA            1  \$159.00  \$159.00',
    '  - 1/2 HAWAIANA - 1/2 PEPPERONI',
    'REFRESCO 600ML           2   \$25.00   \$50.00',
    '------------------------------------------',
    'TOTAL                               \$209.00',
    'EFECTIVO                            \$209.00',
    'CAMBIO                               \$0.00',
    '------------------------------------------',
    '      Gracias por su compra',
  ];

  final b = EscPosBuilder()..init();

  for (final rawLine in plainLines) {
    final line = rawLine.trimRight();
    final trimmed = line.trim();

    if (trimmed == 'Rons Pizza') {
      b
        ..alignCenter()
        ..boldOn()
        ..doubleHeightOn()
        ..line('Rons Pizza')
        ..doubleHeightOff()
        ..boldOff()
        ..alignLeft();
      continue;
    }

    if (trimmed.toUpperCase().startsWith('GRACIAS')) {
      b
        ..alignCenter()
        ..line(trimmed)
        ..alignLeft();
      continue;
    }

    final upper = trimmed.toUpperCase();
    final isBoldLine = upper.startsWith('TOTAL') ||
        upper.startsWith('EFECTIVO') ||
        upper.startsWith('DOLAR') ||
        upper.startsWith('TARJETA') ||
        upper.startsWith('CAMBIO') ||
        upper.startsWith('RESTANTE') ||
        upper.startsWith('ENVIO') ||
        upper.startsWith('PROMO');
    if (isBoldLine) {
      b.boldOn().line(line).boldOff();
    } else {
      b.line(line);
    }
  }

  b.emptyLine().emptyLine().feed(4).cut();

  final bytes = b.build();
  File('comanda_test_receipt.bin').writeAsBytesSync(bytes);

  // Hex dump
  final hexLines = <String>[];
  for (var i = 0; i < bytes.length; i += 16) {
    final chunk = bytes.sublist(i, (i + 16).clamp(0, bytes.length));
    final hex = chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    final ascii = chunk.map((b) {
      final c = String.fromCharCode(b);
      return (b >= 32 && b < 127) ? c : '.';
    }).join();
    hexLines.add('${i.toString().padLeft(4, '0')}:  ${hex.padRight(48)}  $ascii');
  }
  File('comanda_test_receipt_hex.txt').writeAsStringSync(hexLines.join('\n'));

  // Visual simulation
  final visual = StringBuffer();
  visual.writeln('        RONS PIZZA');
  visual.writeln('------------------------------------------');
  visual.writeln('Ticket: 00042');
  visual.writeln('Cajero: ALEX');
  visual.writeln('Hora: 31/05/2026 00:19');
  visual.writeln('Tipo: Dine In');
  visual.writeln('Mesa: 15');
  visual.writeln('------------------------------------------');
  visual.writeln('Nombre                Cant   Precio    Total');
  visual.writeln('PIZZA MEDIANA            1  \$159.00  \$159.00');
  visual.writeln('  - 1/2 HAWAIANA - 1/2 PEPPERONI');
  visual.writeln('REFRESCO 600ML           2   \$25.00   \$50.00');
  visual.writeln('------------------------------------------');
  visual.writeln('TOTAL                               \$209.00');
  visual.writeln('EFECTIVO                            \$209.00');
  visual.writeln('CAMBIO                               \$0.00');
  visual.writeln('------------------------------------------');
  visual.writeln('      Gracias por su compra');
  visual.writeln('');
  visual.writeln('');
  File('comanda_test_receipt_visual.txt').writeAsStringSync(visual.toString());

  print('Receipt de prueba generado:');
  print('  - comanda_test_receipt.bin        (${bytes.length} bytes ESC/POS)');
  print('  - comanda_test_receipt_hex.txt    (vista hex/ascii)');
  print('  - comanda_test_receipt_visual.txt (simulacion visual)');
}
