import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class KitchenPrinter {
  KitchenPrinter._();

  static const MethodChannel _channel = MethodChannel('rons_pizza/printing');

  static Future<void> printKitchenTicket(String ticketText) async {
    if (kIsWeb || !Platform.isWindows) {
      throw PlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'Kitchen printing is only implemented for Windows desktop.',
      );
    }

    await _channel.invokeMethod<void>('printKitchenTicket', {
      'text': ticketText,
    });
  }

  static Future<void> printCustomerReceipt(String receiptText) async {
    if (kIsWeb || !Platform.isWindows) {
      throw PlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'Receipt printing is only implemented for Windows desktop.',
      );
    }

    await _channel.invokeMethod<void>('printCustomerReceipt', {
      'text': receiptText,
    });
  }

  static Future<void> printKitchenTicketBytes(Uint8List bytes) async {
    if (kIsWeb || !Platform.isWindows) {
      throw PlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'Kitchen printing is only implemented for Windows desktop.',
      );
    }

    await _channel.invokeMethod<void>('printKitchenTicketBytes', {
      'bytes': bytes,
    });
  }

  static Future<void> printCustomerReceiptBytes(Uint8List bytes) async {
    if (kIsWeb || !Platform.isWindows) {
      throw PlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'Receipt printing is only implemented for Windows desktop.',
      );
    }

    await _channel.invokeMethod<void>('printCustomerReceiptBytes', {
      'bytes': bytes,
    });
  }
}
