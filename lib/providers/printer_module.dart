import 'dart:typed_data';
import 'services.dart';

class PrinterModule {
  Future<int> logicPowerOn() async {
    // Code Retour
    // 0 Success
    // -2043 No Card inserted
    return await Services.platform.invokeMethod('LogicPowerOn');
  }

  Future<String> logicCardDispatcher(
      {bool writing = false, String contenu = ""}) async {
    // Code Retour
    // UART_CMD_FAILED
    // RSP_FAILED
    // CARD_CHECK_FAILED
    // ERROR
    // -NUMBER

    Map<String, dynamic> args = <String, dynamic>{};
    args.addAll({"writing": writing, "contenu": contenu});
    return await Services.platform.invokeMethod('LogicCardDispatcher', args);
  }

  /// init printer with some default config
  Future printInit() async {
    await Services.platform.invokeMethod('printInit');
    //await platform.invokeMethod('printSetGray', val(2));
    //await platform.invokeMethod('printSetDefaultFont');
  }

  Future<int> printCheckStatus() async {
    return await Services.platform.invokeMethod('PrintCheckStatus');
  }

  /// text and QR_code alignment
  Future printSetAlignLeft() async {
    await Services.platform.invokeMethod('printSetAlign', val('alignment', 0));
  }

  /// text and QR_code alignment
  Future printSetAlignCenter() async {
    await Services.platform.invokeMethod('printSetAlign', val('alignment', 1));
  }

  /// text and QR_code alignment
  Future printSetAlignRight() async {
    await Services.platform.invokeMethod('printSetAlign', val('alignment', 2));
  }

  /// from 1 to 5. Default is 2
  Future printSetDensity(int density) async {
    await Services.platform.invokeMethod('printSetGray', val('level', density));
  }

  // O == off,  1 = on
  Future<int> sysSetPower(int mode) async {
    return await Services.platform
        .invokeMethod('sysSetPower', val('mode', mode));
  }

  /// set font size and zoom.
  /// Default font size is 24.
  /// Default zoom is 0. Bold can be 33
  Future printSetFontSize(int size, int zoom) async {
    await Services.platform
        .invokeMethod('printSetFontSize', fontSize(size, zoom));
  }

  /// set font size to 24
  Future printSetDefaultFont() async {
    await Services.platform.invokeMethod('printSetDefaultFont');
  }

  /// print text
  Future printText(String txt) async {
    await Services.platform.invokeMethod('printString', text(txt));
  }

  /// print end line
  Future printEndLine() async {
    await Services.platform.invokeMethod('printEndLine');
  }

  /// print QR Code
  Future printQrCode(String text, int width, int height) async {
    //await platform.invokeMethod('printSetAlign', val(1));
    await Services.platform
        .invokeMethod('printBarcode', qrCode(text, width, height));
  }

  /// print barcode
  Future printBarcode(String text, int width, int height) async {
    // await platform.invokeMethod('printSetAlign', val(1));
    await Services.platform
        .invokeMethod('printBarcode', barcode(text, width, height));
  }

  /// start printing
  Future<int> printStart() async {
    return await Services.platform.invokeMethod('printStart');
  }

  /// print bitmap
  Future printbitmap(Uint8List bytes, int width, int height) async {
    Map<String, dynamic> map = bitmap(bytes);
    map['width'] = width;
    map['height'] = height;
    return await Services.platform.invokeMethod('printBitmap', map);
  }

  /// send int value
  Map<String, dynamic> val(String key, int value) {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent(key, () => value);
    return args;
  }

  Map<String, dynamic> fontSize(int size, int zoom) {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent("size", () => size);
    args.putIfAbsent("zoom", () => zoom);
    return args;
  }

  /// send text value
  Map<String, dynamic> text(String text) {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent("text", () => text);
    return args;
  }

  /// send qr code text
  Map<String, dynamic> qrCode(String text, int width, int height) {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent("text", () => text);
    args.putIfAbsent("width", () => width);
    args.putIfAbsent("height", () => height);
    args.putIfAbsent("type", () => "QR_CODE");
    return args;
  }

  /// send barcode
  Map<String, dynamic> barcode(String text, int width, int height) {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent("text", () => text);
    args.putIfAbsent("width", () => width);
    args.putIfAbsent("height", () => height);
    args.putIfAbsent("type", () => "EAN_13");
    return args;
  }

  Map<String, dynamic> bitmap(Uint8List param) {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent("p1", () => param);
    return args;
  }
}
