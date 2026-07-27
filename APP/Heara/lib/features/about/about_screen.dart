import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/splash.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 15,
                            sigmaY: 15,
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.12),
                                  Colors.white.withOpacity(0.04),
                                ],
                              ),
                            ),

                            child: Column(
                              children: [
                                // App Icon
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(
                                      0xFF475C80,
                                    ).withOpacity(0.2),
                                  ),
                                  child: const Icon(
                                    Icons.hearing,
                                    size: 55,
                                    color: Color(0xFF475C80),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                Text(
                                  "HeAra",
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF475C80),
                                  ),
                                ),

                                const SizedBox(height: 5),

                                const Text(
                                  "AI Assistant for Hearing Impairment",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 25),

                                const Text(
                                  "HeAra is an AI-powered application designed to support people with hearing impairment by recognizing important environmental sounds and delivering instant alerts.",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    height: 1.6,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 30),

                                // Features
                                _featureTile(
                                  Icons.notifications_active_outlined,
                                  "Real-time Alerts",
                                  "Instant notifications for critical sounds.",
                                ),

                                const SizedBox(height: 12),

                                _featureTile(
                                  Icons.record_voice_over_outlined,
                                  "Speech to Text",
                                  "Convert conversations into readable text.",
                                ),

                                const SizedBox(height: 12),

                                _featureTile(
                                  Icons.graphic_eq,
                                  "Custom Sound Detection",
                                  "Recognize personalized sounds chosen by users.",
                                ),

                                const SizedBox(height: 30),

                                Divider(
                                  color: Colors.white.withOpacity(0.15),
                                ),

                                const SizedBox(height: 15),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF475C80,
                                    ).withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Text(
                                    "Version 1.0.0",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 15),

                                const Text(
                                  "Graduation Project 2026",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _featureTile(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF475C80),
            size: 28,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}