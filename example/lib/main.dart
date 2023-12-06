import 'package:flutter/material.dart';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_thermal_printer_plus/bluetooth_thermal_printer_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:rav_printer/rav_printer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyWidget(),
    );
  }
}

class ListWidth {
  LabelWidth lw;
  String screen;

  ListWidth({
    required this.lw,
    required this.screen,
  });
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;
  TextEditingController controllerHeight = TextEditingController(text: "100");
  TextEditingController controllerGap = TextEditingController(text: "3");

  List<ListWidth> lw = [
    ListWidth(lw: LabelWidth.mm40, screen: "40mm"),
    ListWidth(lw: LabelWidth.mm58, screen: "58mm"),
    ListWidth(lw: LabelWidth.mm80, screen: "80mm"),
  ];

  bool _connected = false;
  String tips = 'no device connect';
  String mac = "";
  List<dynamic>? bds;
  LabelWidth? labelWidth;
  // List<BluetoothDevice> devices = <BluetoothDevice>[];
  @override
  void initState() {
    super.initState();
    initBluetooth();
  }

  Future<void> doPrint({required isPrintLabel}) async {
    String? isConnected = await BluetoothThermalPrinter.connectionStatus;
    if (isConnected == "true" && labelWidth != null) {
      int labelHeight = int.tryParse(controllerHeight.text) ?? 100;
      int labelGap = int.tryParse(controllerGap.text) ?? 3;
      RavPrinter printer = RavPrinter(
        heightLabel: labelHeight,
        gapLabel: labelGap,
        widthLabel: labelWidth!,
      );
      List<RavTextStyle> texts = [];
      texts.add(RavTextStyle(text: "LEFT", align: RavAlign.left));
      texts.add(RavTextStyle(text: "CENTER", align: RavAlign.center));
      texts.add(RavTextStyle(text: "RIGHT", align: RavAlign.right));
      texts.add(
          RavTextStyle(text: "QRCODE", align: RavAlign.center, isQrCode: true));
      texts.add(RavTextStyle(text: "", align: RavAlign.right, lineEnter: 2));
      texts.add(RavTextStyle(
          text: "BARCODE", align: RavAlign.center, isBarCode: true));
      if (isPrintLabel) {
        await printer.doPrintLabel(
          texts: texts,
        );
      } else {
        await printer.doPrintReceipt(
          texts: texts,
          paperSize:
              labelWidth == LabelWidth.mm58 ? PaperSize.mm58 : PaperSize.mm80,
        );
      }
    } else {
      tips = "Label or bluetooth no connect";
      setState(() {});
    }
  }

  Future<void> initBluetooth() async {
    // await BluetoothTer
    bds = await BluetoothThermalPrinter.getBluetooths;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        minimum: EdgeInsets.zero,
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            Text("Information: $tips"),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const Divider(),
                      Container(
                        width: size.width,
                        height: 250,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: ListView.builder(
                            itemCount: bds?.length ?? 0,
                            itemBuilder: ((c, i) {
                              return ListTile(
                                title: Text(bds?[i] ?? ""),
                                subtitle: Text(bds?[i].split("#")[1] ?? ""),
                                onTap: () async {
                                  setState(() {
                                    // _device = devices[i];
                                    mac = bds?[i].split("#")[1] ?? "";
                                    setState(() {
                                      tips = "mac selected $mac";
                                    });
                                  });
                                },
                                trailing:
                                    mac != "" && mac == bds?[i].split("#")[1]
                                        ? Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          )
                                        : null,
                              );
                            })),
                      ),
                      const Divider(),
                      Text("Select Width"),
                      Container(
                        width: size.width,
                        height: 200,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: ListView.builder(
                            itemCount: lw.length,
                            itemBuilder: (c, i) {
                              return ListTile(
                                title: Text(lw[i].screen),
                                onTap: () async {
                                  setState(() {
                                    setState(() {
                                      labelWidth = lw[i].lw;
                                    });
                                  });
                                },
                                trailing:
                                    labelWidth != null && labelWidth == lw[i].lw
                                        ? Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          )
                                        : null,
                              );
                            }),
                      ),
                      const Divider(),
                      Text("Label Height (mm)"),
                      SizedBox(
                        height: 10,
                      ),
                      TextField(
                        controller: controllerHeight,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text("Label Gap (mm)"),
                      TextField(
                        controller: controllerGap,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      const Divider(),
                      ElevatedButton(
                        onPressed: _connected
                            ? null
                            : () async {
                                String? isConnected =
                                    await BluetoothThermalPrinter
                                        .connectionStatus;
                                if (isConnected != "true") {
                                  setState(() {
                                    tips = 'connecting...';
                                  });
                                  // await bluetoothPrint.connect(_device!);
                                  String? result =
                                      await BluetoothThermalPrinter.connect(mac);
                                  if (result == "true") {
                                    setState(() {
                                      _connected = true;
                                      tips = "Connected";
                                    });
                                  }
                                } else {
                                  setState(() {
                                    tips = 'please select device';
                                  });
                                }
                              },
                        child: Text("Connect"),
                      ),
                      ElevatedButton(
                        onPressed: _connected
                            ? () async {
                                setState(() {
                                  tips = 'disconnecting...';
                                });
                                await bluetoothPrint.disconnect();
                                String? res =
                                    await BluetoothThermalPrinter.disconnect();
                                if (res == "true") {
                                  setState(() {
                                    _connected = false;
                                    tips = "Disconnected";
                                  });
                                }
                              }
                            : null,
                        child: Text("Disconnect"),
                      ),
                      Divider(),
                      ElevatedButton(
                        onPressed: () async {
                          if (_connected) {
                            doPrint(isPrintLabel: true);
                          } else {
                            setState(() {
                              tips = "Printer not connect";
                            });
                          }
                        },
                        child: Text("Print Label"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_connected) {
                            doPrint(isPrintLabel: false);
                          } else {
                            setState(() {
                              tips = "Printer not connect";
                            });
                          }
                        },
                        child: Text("Print Receipt"),
                      ),
                      SizedBox(height: 100,)
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
