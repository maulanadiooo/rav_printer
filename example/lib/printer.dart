// import 'package:bluetooth_print/bluetooth_print.dart';
// import 'package:bluetooth_thermal_printer_plus/bluetooth_thermal_printer_plus.dart';
// import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:rav_printer/rav_printer.dart';

// class MyWidget extends StatefulWidget {
//   const MyWidget({super.key});

//   @override
//   State<MyWidget> createState() => _MyWidgetState();
// }

// class _MyWidgetState extends State<MyWidget> {
//   BluetoothPrint bluetoothPrint = BluetoothPrint.instance;
//   TextEditingController controllerHeight = TextEditingController();

//   bool _connected = false;
//   String tips = 'no device connect';
//   String mac = "";
//   List<dynamic>? bds;
//   LabelWidth? labelWidth;
//   // List<BluetoothDevice> devices = <BluetoothDevice>[];
//   @override
//   void initState() {
//     super.initState();
//     initBluetooth();
//   }

//   Future<void> doPrint({required isPrintLabel}) async {
//     String? isConnected = await BluetoothThermalPrinter.connectionStatus;
//     if (isConnected == "true" && labelWidth != null) {
//       RavPrinter printer = RavPrinter(
//         heightLabel: 25,
//         gapLabel: 2,
//         widthLabel: labelWidth!,
//       );
//       List<RavTextStyle> texts = [];
//       texts.add(RavTextStyle(text: "LEFT", align: RavAlign.left));
//       texts.add(RavTextStyle(text: "CENTER", align: RavAlign.center));
//       texts.add(RavTextStyle(text: "RIGHT", align: RavAlign.right));
//       texts.add(
//           RavTextStyle(text: "QRCODE", align: RavAlign.center, isQrCode: true));
//       texts.add(RavTextStyle(
//           text: "BARCODE", align: RavAlign.center, isBarCode: true));
//       if (isPrintLabel) {
//         await printer.doPrintLabel(
//           texts: texts,
//         );
//       } else {
//         await printer.doPrintReceipt(
//           texts: texts,
//           paperSize:
//               labelWidth == LabelWidth.mm58 ? PaperSize.mm58 : PaperSize.mm80,
//         );
//       }
//     } else {
//       tips = "Label or bluetooth no connect";
//       setState(() {});
//     }
//   }

//   Future<void> initBluetooth() async {
//     // await BluetoothTer
//     bds = await BluetoothThermalPrinter.getBluetooths;
//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.sizeOf(context);
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20),
//         child: Column(
//           children: [
//             const SizedBox(
//               height: 50,
//             ),
//             Text(tips),
//             const Divider(),
//             Container(
//               width: size.width,
//               height: 150,
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 20,
//               ),
//               child: ListView.builder(
//                   itemCount: bds?.length ?? 0,
//                   itemBuilder: ((c, i) {
//                     return ListTile(
//                       title: Text(bds?[i] ?? ""),
//                       subtitle: Text(bds?[i].split("#")[1] ?? ""),
//                       onTap: () async {
//                         setState(() {
//                           // _device = devices[i];
//                           mac = bds?[i].split("#")[1] ?? "";
//                           setState(() {
//                            tips = "mac selected $mac";
//                           });
//                         });
//                       },
//                       trailing: mac != "" && mac == bds?[i].split("#")[1]
//                           ? Icon(
//                               Icons.check,
//                               color: Colors.green,
//                             )
//                           : null,
//                     );
//                   })),
//             ),
//             const Divider(),
//             ElevatedButton(
//               onPressed: _connected
//                   ? null
//                   : () async {
//                       String? isConnected =
//                           await BluetoothThermalPrinter.connectionStatus;
//                       if (isConnected != "true") {
//                         setState(() {
//                           tips = 'connecting...';
//                         });
//                         // await bluetoothPrint.connect(_device!);
//                         String? result =
//                             await BluetoothThermalPrinter.connect(mac);
//                         if (result == "true") {
//                           setState(() {
//                             _connected = true;
//                             tips = "Connected";
//                           });
//                         }
//                       } else {
//                         setState(() {
//                           tips = 'please select device';
//                         });
//                       }
//                     },
//               child: Text("Connect"),
//             ),
//             ElevatedButton(
//               onPressed: _connected
//                   ? () async {
//                       setState(() {
//                         tips = 'disconnecting...';
//                       });
//                       await bluetoothPrint.disconnect();
//                       String? res = await BluetoothThermalPrinter.disconnect();
//                       if (res == "true") {
//                         setState(() {
//                           _connected = false;
//                           tips = "Disconnected";
//                         });
//                       }
//                     }
//                   : null,
//               child: Text("Disconnect"),
//             ),
//             Divider(),
//             ElevatedButton(
//               onPressed: () async {
//                 if (_connected) {
//                   doPrint(isPrintLabel: true);
//                 } else {
//                   setState(() {
//                     tips = "Printer not connect";
//                   });
//                 }
//               },
//               child: Text("Print Label"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 if (_connected) {
//                   doPrint(isPrintLabel: false);
//                 } else {
//                   setState(() {
//                     tips = "Printer not connect";
//                   });
//                 }
//               },
//               child: Text("Print Receipt"),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
