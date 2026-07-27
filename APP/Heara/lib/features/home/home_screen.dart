import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_controller.dart';
import '../profile/profile_screen.dart';
import '../about/about_screen.dart';
import '../settings/settings_screen.dart';
import '../add sound/add_sound_screen.dart';
import '../log_history/log_history_screen.dart';

// 🔵 BLE IMPORT
import '../ble/ble_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeController controller;

  // Design palette (matches the rest of the HeAra design system)
  static const Color sapphire = Color(0xFF3C507D);
  static const Color royalBlue = Color(0xFF112250);
  static const Color swanWing = Color(0xFFF5F0E9);
  static const Color cloudedSteel = Color(0xFF778CA4);
  static const Color paleSnow = Color(0xFFD5DBE2);

  @override
  void initState() {
    super.initState();
    controller = HomeController();
    controller.init().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget glassCard({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: child,
        ),
      ),
    );
  }

  void navigateTo(Widget screen) {
    Navigator.pop(context); // close drawer first
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void logout() {
    Navigator.pop(context);
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
    Color textColor = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label, style: TextStyle(color: textColor)),
      onTap: onTap,
    );
  }

  Widget _signWordCard(SignWord sign) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: sign.imagePath != null
                  ? Image.asset(sign.imagePath!, fit: BoxFit.cover)
                  : Container(
                      color: Colors.white.withOpacity(0.15),
                      child: const Icon(
                        Icons.front_hand_outlined,
                        size: 40,
                        color: Colors.white70,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            sign.word,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 71, 92, 128),
                Color(0xFF0F172A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.hearing, size: 35, color: royalBlue),
                ),

                const SizedBox(height: 10),

                const Text(
                  "HEARA",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 20),
                Divider(color: Colors.white.withOpacity(0.15), height: 1),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _drawerItem(
                        icon: Icons.person,
                        label: "Profile",
                        onTap: () => navigateTo(const ProfileScreen()),
                      ),
                      _drawerItem(
                        icon: Icons.settings,
                        label: "Settings",
                        onTap: () => navigateTo(const SettingsScreen()),
                      ),
                      _drawerItem(
                        icon: Icons.add_circle_outline,
                        label: "Add Sound",
                        onTap: () => navigateTo(const AddSoundScreen()),
                      ),
                      _drawerItem(
                        icon: Icons.history,
                        label: "Log History",
                        onTap: () => navigateTo(const LogHistoryScreen()),
                      ),
                      _drawerItem(
                        icon: Icons.info,
                        label: "About",
                        onTap: () => navigateTo(const AboutScreen()),
                      ),
                    ],
                  ),
                ),

                Divider(color: Colors.white.withOpacity(0.15), height: 1),
                _drawerItem(
                  icon: Icons.logout,
                  label: "Logout",
                  iconColor: Colors.redAccent,
                  textColor: Colors.redAccent,
                  onTap: logout,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),

      body: Stack(
        children: [
          /// BACKGROUND
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/splash.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// TOP BAR — menu + app name
                  Row(
                    children: [
                      Builder(
                        builder: (context) => Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.menu, color: sapphire),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "HeAra",
                        style: TextStyle(
                          fontFamily: "PlayfairDisplay",
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: royalBlue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  /// WELCOME MESSAGE
                  ValueListenableBuilder(
                    valueListenable: controller.userFirstName,
                    builder: (_, name, __) {
                      final greeting =
                          name.isNotEmpty ? "Welcome, $name 👋" : "Welcome 👋";
                      return Text(
                        greeting,
                        style: const TextStyle(
                          fontFamily: "CormorantGaramond",
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: royalBlue,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  /// STATUS
                  ValueListenableBuilder(
                    valueListenable: controller.statusMessage,
                    builder: (_, value, __) {
                      return glassCard(
                        child: Row(
                          children: [
                            const Icon(Icons.graphic_eq, color: Colors.white70),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                value,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  /// DETECTED LABEL
                  ValueListenableBuilder(
                    valueListenable: controller.detectedLabel,
                    builder: (_, value, __) {
                      return glassCard(
                        child: Column(
                          children: [
                            const Text("Detected Sound",
                                style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 8),
                            Text(value,
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  /// CONFIDENCE
                  ValueListenableBuilder(
                    valueListenable: controller.confidence,
                    builder: (_, value, __) {
                      return glassCard(
                        child: Row(
                          children: [
                            const Icon(Icons.insights, color: Colors.white70),
                            const SizedBox(width: 10),
                            Text(
                              "Confidence: ${(value * 100).toStringAsFixed(1)}%",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 26),

                  /// START / STOP LISTENING
                  ValueListenableBuilder(
                    valueListenable: controller.isListening,
                    builder: (_, isListening, __) {
                      return SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isListening ? Colors.redAccent : sapphire,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () async {
                            if (isListening) {
                              await controller.stopListening();
                            } else {
                              await controller.startListening();
                            }
                          },
                          child: Text(
                            isListening ? "Stop Listening" : "Start Listening",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  /// BLE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: royalBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BLEPage()),
                        );
                      },
                      child: const Text(
                        "Connect ESP32",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// ALERT
                  ValueListenableBuilder(
                    valueListenable: controller.alertTriggered,
                    builder: (_, value, __) {
                      return value
                          ? glassCard(
                              child: const Text(
                                "🚨 ALERT TRIGGERED!",
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          : const SizedBox();
                    },
                  ),

                  const SizedBox(height: 30),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
