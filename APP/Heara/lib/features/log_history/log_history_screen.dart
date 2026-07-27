import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogHistoryScreen extends StatelessWidget {
  const LogHistoryScreen({super.key});

  /// =========================
  /// FETCH LOGS FROM FIRESTORE
  /// =========================
  Stream<List<Map<String, dynamic>>> getLogs() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection("logs")
        .doc(user.uid)
        .collection("items")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          "sound": data["sound"] ?? "Unknown",
          "time": data["time"] ?? "",
          "date": data["date"] ?? "",
          "icon": Icons.notifications,
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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

          Container(
            color: Colors.black.withOpacity(0.35),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  const Text(
                    "Log History",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// =========================
                  /// HEADER STATS
                  /// =========================
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: getLogs(),
                    builder: (context, snapshot) {
                      final logs = snapshot.data ?? [];

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white.withOpacity(0.08),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.history,
                                  color: Colors.white,
                                  size: 35,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "${logs.length}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "Detected Sounds",
                                  style: TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  /// =========================
                  /// LIST
                  /// =========================
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: getLogs(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        }

                        final logs = snapshot.data ?? [];

                        if (logs.isEmpty) {
                          return const Center(
                            child: Text(
                              "No logs yet",
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.white.withOpacity(0.08),
                                      border: Border.all(
                                        color:
                                            Colors.white.withOpacity(0.15),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const CircleAvatar(
                                          radius: 28,
                                          backgroundColor: Colors.white24,
                                          child: Icon(
                                            Icons.hearing,
                                            color: Colors.white,
                                          ),
                                        ),

                                        const SizedBox(width: 15),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                log["sound"],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "${log["date"]} • ${log["time"]}",
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.white54,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
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