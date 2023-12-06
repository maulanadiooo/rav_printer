import 'package:bluetooth_thermal_printer_plus/bluetooth_thermal_printer_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

enum LabelWidth {
  mm40,
  mm58,
  mm80,
}

/// methode connect, disconnect dan writebytes di ambil dari bluetooth thremal printer
/// paddding dalam satuan dots
/// 1mm=11.8dots
/// TEXT x,y, " font ",rotation,x-multiplication,y-multiplication,[alignment,] " content "

class RavPrinter {
  LabelWidth widthLabel;
  int heightLabel;
  int gapLabel;
  int direction;

  String bytes = '';
  List<int> bytesPos = [];
  int maxCharLength = 24;
  CapabilityProfile? profile;

  /// support untuk kertas ukuran lebar 40mm dan 80mm untuk label dan support 58 dan 80mm untuk receipt
  ///
  /// heigh dan gap dalam mm, require untuk label
  RavPrinter({
    this.widthLabel = LabelWidth.mm40,
    this.direction = 0,
    this.heightLabel = 0,
    this.gapLabel = 0,
  });

  Future<String?> connect(String mac) async {
    return BluetoothThermalPrinter.connect(mac);
  }

  // disconnect to any connected device                        --> new feature
  // Future<String?> disconnect() async {
  //   return BluetoothThermalPrinter.disconnect();
  // }

  ///Printes the [bytes] using bluetooth printer.
  Future<bool> doPrintLabel({required List<RavTextStyle> texts}) async {
    init();
    generateByte(texts: texts);
    bytes += '''PRINT 1
''';
    String? result = await BluetoothThermalPrinter.writeBytes(bytes.codeUnits);
    clearBytes();
    if (result == "true") {
      return true;
    }
    return false;
  }

  /// hanya allow mm58 dan 80 papersize
  Future<bool> doPrintReceipt(
      {required List<RavTextStyle> texts, required PaperSize paperSize}) async {
    profile ??= await CapabilityProfile.load();
    if (profile != null) {
      Generator gen = Generator(paperSize, profile!);
      await doFor58mmPos(texts: texts, gen: gen);
      String? result = await BluetoothThermalPrinter.writeBytes(bytesPos);
      clearBytes();
      if (result == "true") {
        return true;
      }
      return false;
    } else {
      throw Exception("Cant load profile");
    }
  }

  void clearBytes() {
    bytes = "";
    bytesPos = [];
  }

  void init() {
    String w;
    String h = heightLabel.toString();
    String g = gapLabel.toString();
    if (widthLabel == LabelWidth.mm80) {
      w = "80";
    } else {
      w = "40";
    }
    bytes += '''INITIALPRINTER
SIZE $w mm, $h mm
DIRECTION $direction
GAP $g mm
SET CUTTER 1
CLS
CODEPAGE 850
COUNTRY 061
''';
  }

  /// PETUNJUK BISA DIBACA DISINI: [https://www.pos-shop.ru/upload/iblock/e6d/e6dcd9090030c75de3ffd3435c1e2024.pdf]
  /// 1 mm = 12 dots, jika bold / italic hanya 8 dots
  void generateByte({required List<RavTextStyle> texts}) {
    /// kalau x nya 1, cukup 24 karakter
    /// kalau x nya 2, cukup 12 karakter
    int paddingleft = 10;
    int paddingtop = 10;
    int lineFeed = 25;
    if (widthLabel == LabelWidth.mm80) {
      _doFor80mm(
        texts: texts,
        lineFeed: lineFeed,
        paddingtop: paddingtop,
        paddingleft: paddingleft,
      );
    } else {
      _doFor40mm(
        texts: texts,
        lineFeed: lineFeed,
        paddingtop: paddingtop,
        paddingleft: paddingleft,
      );
    }
  }

  void _doFor40mm(
      {required List<RavTextStyle> texts,
      required int lineFeed,
      required int paddingtop,
      required int paddingleft}) {
    for (RavTextStyle style in texts) {
      int feed = lineFeed;
      int maxLength = maxCharLength;
      if (style.lineEnter != null) {
        for (int i = 0; i < style.lineEnter!; i++) {
          bytes += '''TEXT 0, $paddingtop, "1", 0, 1, 1, ""\n''';
          paddingtop += feed;
        }
      } else {
        if (style.isQrCode) {
          // if (style.align == 1) {
          //   bytes += '''QRCODE 75,$paddingtop,H,4,A,0,"${style.text}"\n''';
          // } else {
          //   bytes +=
          //       '''QRCODE $paddingleft,$paddingtop,H,4,A,0,"${style.text}"\n''';
          // }
          bytes +=
              '''QRCODE $paddingleft,$paddingtop,H,5,A,0,"${style.text}"\n''';
        } else if (style.isBarCode) {
          int heighBarCode = 100;
          if (style.align == RavAlign.center) {
            int dotsPerChar = 6;
            int space = maxLength - style.text.length; // 6
            int spaceKiri = (space / 2).ceil();
            int dotToSkip = (spaceKiri * (dotsPerChar * 2)) + paddingleft;
            bytes +=
                '''BARCODE $dotToSkip, $paddingtop, "128",$heighBarCode,1,0,1,1, "${style.text}""\n''';
          } else {
            bytes +=
                '''BARCODE $paddingleft, $paddingtop, "128",$heighBarCode,1,0,1,1, "${style.text}""\n''';
          }

          paddingtop += heighBarCode + 50;
        } else if (style.printLine) {
          // bytes += '''BAR 0,$paddingtop,400,4\n''';
          bytes += '''BLINE 4 mm\n''';
          paddingtop += 20;
        } else {
          if (style.fontZoom > 1) {
            feed = 50;
            maxLength = maxCharLength ~/ 2; // toInt()
          }
          if (style.align == RavAlign.left) {
            paddingtop = _leftText(
              maxLength: maxLength,
              spaceLeft: 0,
              fontZoom: style.fontZoom,
              text: style.text,
              paddingLeft: paddingleft,
              paddingTop: paddingtop,
              feed: feed,
            );
          } else if (style.align == RavAlign.center) {
            paddingtop = _textCenter(
              maxLength: maxLength,
              fontZoom: style.fontZoom,
              text: style.text,
              paddingLeft: paddingleft,
              paddingTop: paddingtop,
              feed: feed,
              widthLabel: widthLabel,
            );
          } else {
            paddingtop = _rightText(
              maxLength: maxLength,
              spaceLeft: 0,
              fontZoom: style.fontZoom,
              text: style.text,
              paddingLeft: paddingleft,
              paddingTop: paddingtop,
              feed: feed,
            );
          }
          paddingtop += feed;
        }
      }
    }
  }

  void _doFor80mm(
      {required List<RavTextStyle> texts,
      required int lineFeed,
      required int paddingtop,
      required int paddingleft}) {
    maxCharLength = 48;
    for (RavTextStyle style in texts) {
      int feed = lineFeed;
      int maxLength = maxCharLength;
      if (style.lineEnter != null) {
        for (int i = 0; i < style.lineEnter!; i++) {
          bytes += '''TEXT 0, $paddingtop, "1", 0, 1, 1, ""\n''';
          paddingtop += feed;
        }
      } else {
        if (style.isQrCode) {
          // if (style.align == 1) {
          //   bytes += '''QRCODE 180,$paddingtop,H,10,A,0,"${style.text}"\n''';
          // } else {
          //   bytes +=
          //       '''QRCODE $paddingleft,$paddingtop,H,10,A,0,"${style.text}"\n''';
          // }
          bytes += '''QRCODE 0,$paddingtop,H,5,A,0,"${style.text}"\n''';
          paddingtop += 225;
        } else if (style.isBarCode) {
          int heighBarCode = 100;
          if (style.align == RavAlign.center) {
            int dotsPerChar = 6;
            int space = maxCharLength - style.text.length; // 6
            int spaceKiri = (space / 2).ceil();
            int dotToSkip = (spaceKiri * (dotsPerChar * 2));
            bytes +=
                '''BARCODE $dotToSkip, $paddingtop, "128",$heighBarCode,1,0,1,1, "${style.text}""\n''';
          } else if (style.align == RavAlign.right) {
            int dotsPerChar = 6;
            int spaceKiri = maxCharLength - style.text.length;
            int dotToSkip = (spaceKiri * (dotsPerChar * 2));
            bytes +=
                '''BARCODE $dotToSkip, $paddingtop, "128",$heighBarCode,1,0,1,1, "${style.text}""\n''';
          } else {
            bytes +=
                '''BARCODE 0, $paddingtop, "128",$heighBarCode,1,0,1,1, "${style.text}""\n''';
          }

          paddingtop += heighBarCode + 50;
        } else if (style.printLine) {
          bytes += '''BAR 0,$paddingtop,800,4\n''';
          paddingtop += 20;
        } else {
          if (style.fontZoom > 1) {
            feed = 50;
            maxLength = maxCharLength ~/ 2; // toInt()
          }
          if (style.align == RavAlign.left) {
            paddingtop = _leftText(
              maxLength: maxLength,
              spaceLeft: 0,
              fontZoom: style.fontZoom,
              text: style.text,
              paddingLeft: 0,
              paddingTop: paddingtop,
              feed: feed,
            );
          } else if (style.align == RavAlign.center) {
            paddingtop = _textCenter(
              maxLength: maxLength,
              fontZoom: style.fontZoom,
              text: style.text,
              paddingLeft: 0,
              paddingTop: paddingtop,
              feed: feed,
              widthLabel: widthLabel,
            );
          } else {
            paddingtop = _rightText(
              maxLength: maxLength,
              spaceLeft: 0,
              fontZoom: style.fontZoom,
              text: style.text,
              paddingLeft: 0,
              paddingTop: paddingtop,
              feed: feed,
            );
          }
          paddingtop += feed;
        }
      }
    }
  }

  int _leftText(
      {required int maxLength,
      required int spaceLeft,
      required int fontZoom,
      required String text,
      required int paddingLeft,
      required int paddingTop,
      required int feed}) {
    int maxChar = maxLength - spaceLeft;
    int charZoom;
    if (fontZoom <= 1) {
      charZoom = 1;
    } else {
      charZoom = 2;
    }

    String space = "";
    for (int i = 0; i < spaceLeft; i++) {
      space += " ";
    }
    if (text.length < maxChar) {
      bytes +=
          '''TEXT $paddingLeft, $paddingTop, "1", 0, $charZoom, $charZoom, "$text"\n''';
      return paddingTop;
    } else {
      List<String> splitSpace = text.split(" ");
      List<String> resultLines = [];
      String currentLine = "";

      for (String teks in splitSpace) {
        if (currentLine.isEmpty) {
          currentLine = teks;
        } else {
          String tempLine = '$currentLine $teks';
          if (tempLine.length <= maxChar) {
            currentLine = tempLine;
          } else {
            resultLines.add(currentLine);
            currentLine = teks;
          }
        }
      }

      if (currentLine.isNotEmpty) {
        resultLines.add(currentLine);
      }

      for (int i = 0; i < resultLines.length; i++) {
        bytes +=
            '''TEXT $paddingLeft, $paddingTop, "1", 0, $charZoom, $charZoom, "$space${resultLines[i]}"\n''';
        paddingTop += feed;
      }
      return paddingTop;
    }
  }

  int _rightText(
      {required int maxLength,
      required int spaceLeft,
      required int fontZoom,
      required String text,
      required int paddingLeft,
      required int paddingTop,
      required int feed}) {
    int maxChar = maxLength - spaceLeft;
    int charZoom;
    if (fontZoom <= 1) {
      charZoom = 1;
    } else {
      charZoom = 2;
    }

    String space = "";
    for (int i = 0; i < spaceLeft; i++) {
      space += " ";
    }
    if (text.length < maxChar) {
      int dotsPerChar = 6;
      if (fontZoom > 1) {
        dotsPerChar = 12;
      }
      int spaceKiri = maxChar - text.length;
      int dotToSkip = (spaceKiri * (dotsPerChar * 2));
      bytes +=
          '''TEXT $dotToSkip, $paddingTop, "1", 0, $charZoom, $charZoom, "$text"\n''';
      return paddingTop;
    } else {
      List<String> splitSpace = text.split(" ");
      List<String> resultLines = [];
      String currentLine = "";

      for (String teks in splitSpace) {
        if (currentLine.isEmpty) {
          currentLine = teks;
        } else {
          String tempLine = '$currentLine $teks';
          if (tempLine.length <= maxChar) {
            currentLine = tempLine;
          } else {
            resultLines.add(currentLine);
            currentLine = teks;
          }
        }
      }

      if (currentLine.isNotEmpty) {
        resultLines.add(currentLine);
      }

      for (int i = 0; i < resultLines.length; i++) {
        int dotsPerChar = 6;
        int spaceKiri = maxChar - resultLines[i].length;
        int dotToSkip = (spaceKiri * (dotsPerChar * 2));
        bytes +=
            '''TEXT $dotToSkip, $paddingTop, "1", 0, $charZoom, $charZoom, "$space${resultLines[i]}"\n''';
        paddingTop += feed;
      }
      return paddingTop;
    }
  }

  int _textCenter(
      {required int maxLength,
      required int fontZoom,
      required String text,
      required int paddingLeft,
      required int paddingTop,
      required int feed,
      required LabelWidth widthLabel}) {
    int maxChar = maxLength;

    if (text.length < maxChar) {
      // hitung spacenya
      int space = maxChar - text.length; // 6
      int spaceKiri = (space / 2).ceil(); // 3
      // int spaceKanan = (space / 2).floor(); // 3
      String finalText = text;
      // hitung berdasarkan dots, 1 karkter itu 1mm = 8dots, jika fontzoom 2 maka 1 karakter 2mm = 24dots
      int dotsPerChar = 6;
      if (fontZoom > 1) {
        dotsPerChar = 12;
      }
      // int spaceWidthSisa = 470; // ini karena 40 * 12 dan dikurang pading left default 10
      // if (widthLabel == LabelWidth.mm80) {
      //   // TODO: spacenya berapa
      // }
      int dotToSkip = (spaceKiri * (dotsPerChar * 2)) + paddingLeft;
      // for (int i = 0; i < spaceKiri; i++) {
      //   finalText += " ";
      // }
      // finalText += text;
      // for (int i = 0; i < spaceKanan; i++) {
      //   finalText += " ";
      // }
      bytes +=
          '''TEXT $dotToSkip, $paddingTop, "1", 0, $fontZoom, $fontZoom, "$finalText"\n''';
      return paddingTop;
    } else {
      // cari hasil baginya dulu berapa
      int r = (text.length / maxChar).floor();

      // cari modulusnya, atau sisa karakternya
      int m = text.length % maxChar;

      // bikin setiap baris khusu ini gak ada spacenya
      for (int i = 0; i < r; i++) {
        int akhirKarakter = maxChar * (i + 1);
        int awalKarakter = maxChar * i;
        String singleLineText = text.substring(awalKarakter, akhirKarakter);
        bytes +=
            '''TEXT $paddingLeft, $paddingTop, "1", 0, $fontZoom, $fontZoom, "$singleLineText"\n''';
        paddingTop += feed;
      }
      // nah ambil sisa karakternya, ini baru yang di center kan
      if (m > 0) {
        String textSisa = text.substring(text.length - m);
        int space = maxChar - textSisa.length;
        int spaceKiri = (space / 2).ceil();
        int spaceKanan = (space / 2).floor();
        String finalText = "";
        for (int i = 0; i < spaceKiri; i++) {
          finalText += " ";
        }
        finalText += textSisa;
        for (int i = 0; i < spaceKanan; i++) {
          finalText += " ";
        }
        bytes +=
            '''TEXT $paddingLeft, $paddingTop, "1", 0, $fontZoom, $fontZoom, "$finalText"\n''';
        paddingTop += feed;
      }

      return paddingTop;
    }
  }

  Future<void> doFor58mmPos({
    required List<RavTextStyle> texts,
    required Generator gen,
  }) async {
    for (RavTextStyle style in texts) {
      if (style.isQrCode) {
        bytesPos += gen.qrcode(style.text,
            align: style.align == RavAlign.left
                ? PosAlign.left
                : style.align == RavAlign.right
                    ? PosAlign.right
                    : PosAlign.center,
            cor: QRCorrection.H);
      } else if (style.isBarCode) {
        String result = "{B"; // TYPE BARCODE A,B,C
        result += style.text;
        List<dynamic> barcodeData = result.split('');
        bytesPos += gen.barcode(Barcode.code128(barcodeData));
      } else {
        PosStyles stylePos = PosStyles(
          align: style.align == RavAlign.left
              ? PosAlign.left
              : style.align == RavAlign.right
                  ? PosAlign.right
                  : PosAlign.center,
          height: style.fontZoom == 1 ? PosTextSize.size1 : PosTextSize.size2,
          width: style.fontZoom == 1 ? PosTextSize.size1 : PosTextSize.size2,
        );
        bytesPos += gen.text(
          style.text,
          styles: stylePos,
          linesAfter: 0,
        );
      }
    }
    bytesPos += gen.cut();
    bytesPos += gen.reset();
  }

  // List<int> _generateCode128(String textToEncode) {
  //   final List<int> result = [];

  //   // Start Code
  //   result.add(0x7B); // '{'

  //   // Type C
  //   result.add(textToEncode.codeUnitAt(0) - 32);

  //   // Data
  //   for (int i = 1; i < textToEncode.length; i++) {
  //     result.add(textToEncode.codeUnitAt(i));
  //   }

  //   // Checksum
  //   int checksum = result[1];
  //   for (int i = 2; i < result.length; i++) {
  //     checksum += i * result[i];
  //   }
  //   result.add(checksum % 103);

  //   // Stop Code
  //   result.add(0x7D); // '}'

  //   return result;
  // }
}

class RavTextStyle {
  int fontZoom;
  String text;
  RavAlign align;
  bool isQrCode;
  bool isBarCode;
  bool printLine;
  int? lineEnter;

  /// Jika fontzoom lebih besar daripada 1, maka itu ukuran text 2x lebih besar, default 1
  ///
  /// align, 0=left, 1=center, NOTE: [2=hanya untuk print receipt align right]
  /// printLine = false, true jika ingin membuat garus putus2, dan text dikosongkan saja
  RavTextStyle({
    this.fontZoom = 1,
    this.align = RavAlign.left,
    this.isQrCode = false,
    this.isBarCode = false,
    this.printLine = false,
    this.lineEnter,
    required this.text,
  });
}

enum RavAlign {
  left,
  center,
  right,
}
