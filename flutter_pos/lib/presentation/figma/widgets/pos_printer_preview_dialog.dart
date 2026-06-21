import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<void> showPrinterPreviewDialog(
  BuildContext context, {
  required String title,
  required String ticketText,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _PrinterPreviewDialog(title: title, ticketText: ticketText),
  );
}

class _PrinterPreviewDialog extends StatefulWidget {
  const _PrinterPreviewDialog({required this.title, required this.ticketText});

  final String title;
  final String ticketText;

  @override
  State<_PrinterPreviewDialog> createState() => _PrinterPreviewDialogState();
}

class _PrinterPreviewDialogState extends State<_PrinterPreviewDialog> {
  bool _isSaving = false;
  String? _savedPath;

  Future<void> _saveToFile() async {
    setState(() => _isSaving = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}\\rons_pizza_tickets');
      await folder.create(recursive: true);
      final file = File(
        '${folder.path}\\ticket_${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      await file.writeAsString(widget.ticketText, encoding: const SystemEncoding());
      if (mounted) {
        setState(() {
          _savedPath = file.path;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guardado en: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                    label: const Text('Volver'),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      widget.ticketText,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _saveToFile,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save, size: 18),
                      label: const Text('Guardar como archivo'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.ticketText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ticket copiado al portapapeles')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copiar texto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_savedPath != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                child: Text(
                  'Guardado: $_savedPath',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
