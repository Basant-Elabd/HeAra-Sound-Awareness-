import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _service = SettingsService();

  bool loading = true;

  bool notifications = true;
  bool vibration = true;
  bool sleepMode = false;
  bool emergencyAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final data = await _service.getSettings();

    if (!mounted) return;

    setState(() {
      notifications = data["notifications"] ?? true;
      vibration = data["vibration"] ?? true;
      sleepMode = data["sleepMode"] ?? false;
      emergencyAlerts = data["emergencyAlerts"] ?? true;
      loading = false;
    });
  }

  /// بيحدث الشاشة فورًا (لاستجابة بصرية سريعة)
  /// وبيحفظ في Firestore في نفس الوقت
  Future<void> _updateSetting(String key, bool value, VoidCallback applyLocal) async {
    setState(applyLocal);
    await _service.saveSetting(key, value);
  }

  Widget settingTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/splash.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.35)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  const Text(
                    "Settings",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.settings, size: 50, color: Colors.white),
                            SizedBox(height: 10),
                            Text(
                              "HeAra Settings",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Customize your experience",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Expanded(
                    child: ListView(
                      children: [
                        settingTile(
                          icon: Icons.notifications,
                          title: "Notifications",
                          value: notifications,
                          onChanged: (v) => _updateSetting(
                            "notifications",
                            v,
                            () => notifications = v,
                          ),
                        ),
                        settingTile(
                          icon: Icons.vibration,
                          title: "Vibration Alerts",
                          value: vibration,
                          onChanged: (v) => _updateSetting(
                            "vibration",
                            v,
                            () => vibration = v,
                          ),
                        ),
                        settingTile(
                          icon: Icons.bedtime,
                          title: "Sleep Mode",
                          value: sleepMode,
                          onChanged: (v) => _updateSetting(
                            "sleepMode",
                            v,
                            () => sleepMode = v,
                          ),
                        ),
                        settingTile(
                          icon: Icons.warning_amber,
                          title: "Emergency Alerts",
                          value: emergencyAlerts,
                          onChanged: (v) => _updateSetting(
                            "emergencyAlerts",
                            v,
                            () => emergencyAlerts = v,
                          ),
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
}