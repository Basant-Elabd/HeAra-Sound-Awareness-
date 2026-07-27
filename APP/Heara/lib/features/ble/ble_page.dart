import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:async';

class BLEPage extends StatefulWidget {
  const BLEPage({super.key});

  @override
  State<BLEPage> createState() => _BLEPageState();
}

class _BLEPageState extends State<BLEPage> {
  BluetoothDevice? device;
  BluetoothCharacteristic? characteristic;

  String status = "Not Connected";
  bool isConnected = false;

  final String deviceName = "Heara";

  final String serviceUUID =
      "12345678-1234-1234-1234-123456789abc";

  final String charUUID =
      "abcd1234-1234-1234-1234-abcdef123456";

  Stream<List<ScanResult>>? scanStream;
  StreamSubscription? bleSubscription;

  bool scanning = false;

  // ================= SCAN =================

  void scanDevices() async {
    if (scanning) return;

    setState(() {
      status = "Scanning...";
      scanning = true;
    });

    await FlutterBluePlus.stopScan();

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
    );

    scanStream = FlutterBluePlus.scanResults;

    bleSubscription?.cancel();

    bleSubscription = scanStream!.listen((results) async {
      for (var r in results) {
        final name = r.device.platformName;

        if (name == deviceName) {
          device = r.device;

          await FlutterBluePlus.stopScan();

          scanning = false;

          await connectToDevice();

          return;
        }
      }
    });
  }

  // ================= CONNECT =================

  Future<void> connectToDevice() async {
    if (device == null) return;

    setState(() {
      status = "Connecting...";
    });

    try {
      await device!.connect(
        timeout: const Duration(seconds: 10),
      );

      var services = await device!.discoverServices();

      for (var service in services) {
        if (service.uuid.toString() == serviceUUID) {
          for (var c in service.characteristics) {
            if (c.uuid.toString() == charUUID) {
              characteristic = c;

              await characteristic!.setNotifyValue(true);

              setState(() {
                isConnected = true;
                status = "Connected to HeAra 🔗";
              });

              listenToESP32();

              return;
            }
          }
        }
      }

      setState(() {
        status = "Service Not Found ❌";
      });
    } catch (e) {
      setState(() {
        status = "Connection Failed ❌";
      });
    }
  }

  // ================= LISTEN =================

  void listenToESP32() {
    characteristic!.value.listen((value) {
      String data = String.fromCharCodes(value).trim();

      if (data == "FALL") {
        setState(() {
          status = "🔥 FALL DETECTED!";
        });
      }
    });
  }

  // ================= SEND COMMAND =================

  Future<void> sendCommand(String cmd) async {
    if (characteristic == null || !isConnected) return;

    await characteristic!.write(
      cmd.codeUnits,
      withoutResponse: true,
    );

    setState(() {
      status = "Sent: $cmd";
    });
  }

  // ================= DISPOSE =================

  @override
  void dispose() {
    bleSubscription?.cancel();
    device?.disconnect();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  // ================= GLASS BOX =================

  Widget glassBox({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  "assets/images/splash.jpg",
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Container(
            color: Colors.black.withOpacity(0.45),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  Text(
                    "HEARA BLE",
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),

                  const SizedBox(height: 25),

                  CircleAvatar(
                    radius: 55,
                    backgroundColor:
                        Colors.white.withOpacity(0.08),
                    child: Icon(
                      isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth,
                      color: Colors.white,
                      size: 55,
                    ),
                  ),

                  const SizedBox(height: 20),

                  glassBox(
                    child: Column(
                      children: [
                        const Text(
                          "Connection Status",
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          status,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text(
                        "Connect to ESP32",
                      ),
                      onPressed: scanDevices,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(
                                255, 71, 92, 128),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Test Commands",
                      style: GoogleFonts.cormorantGaramond(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  glassBox(
                    child: Column(
                      children: [
                        commandBtn(
                          "TEST",
                          Icons.send,
                          () => sendCommand("TEST"),
                        ),

                        const SizedBox(height: 10),

                        commandBtn(
                          "FIRE",
                          Icons.local_fire_department,
                          () => sendCommand("FIRE"),
                          color: Colors.red,
                        ),

                        const SizedBox(height: 10),

                        commandBtn(
                          "BABY",
                          Icons.child_care,
                          () => sendCommand("BABY"),
                          color: Colors.orange,
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

  Widget commandBtn(
    String text,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(text),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              color ??
              const Color.fromARGB(
                  255, 71, 92, 128),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}