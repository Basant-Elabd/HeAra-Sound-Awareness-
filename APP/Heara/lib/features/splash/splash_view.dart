import 'dart:ui';
import 'package:flutter/material.dart';
import '../splash/animated_wave.dart';
import 'package:google_fonts/google_fonts.dart';
import '../splash/loading_dots.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // 🌄 Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/splash.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🪟 Glass Frame (soft blended version)
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: MediaQuery.of(context).size.height * 1.0,
                  width: MediaQuery.of(context).size.width * 1.0,
                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),

                    // ✨ soft gradient instead of solid color
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.80), // البداية أقوى
                        Colors.white.withOpacity(0.03), // النص
                        Colors.white.withOpacity(0.00), // النهاية تختفي
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),

                    // ✨ almost invisible border
                    border: Border.fromBorderSide(BorderSide.none),

                    // ✨ subtle glow for blending effect
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.08),
                        blurRadius: 30,
                        spreadRadius: 1,
                      ),
                    ],
                  ),

                  child: Column(
                    children: [

                      const Spacer(flex: 2),

                      // 🔊 Icon + Waves (contained)
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedWave(delay: 0),
                            AnimatedWave(delay: 0.4),
                            AnimatedWave(delay: 0.8),

                            const Icon(
                              Icons.hearing,
                              size: 70,
                              color: Color.fromARGB(255, 71, 92, 128),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      Text(
                        "HEARA",
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 71, 92, 128),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Hear the world in a smarter way",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 17,
                          color: const Color.fromARGB(255, 71, 92, 128),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "...",
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 16,
                          color: const Color.fromARGB(255, 71, 92, 128),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ✨ loading dots (clean modern)
                      const LoadingDots(),

                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}