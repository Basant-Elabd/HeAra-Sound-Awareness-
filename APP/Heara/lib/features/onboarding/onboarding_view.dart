import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'onboarding_model.dart';
import 'onboarding_page.dart';

import '../login/login_screen.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _controller = PageController();

  int currentPage = 0;

  final List<OnboardingModel> pages = [
    OnboardingModel(
      icon: Icons.hearing,
      title: "Stay Aware of Every Sound",
      description:
          "HeAra detects important sounds around you and keeps you informed in real time.",
    ),
    OnboardingModel(
      icon: Icons.notifications_active_rounded,
      title: "Never Miss an Emergency",
      description:
          "Receive instant alerts for alarms, sirens, doorbells, and other critical sounds.",
    ),
    OnboardingModel(
      icon: Icons.add_circle_outline_rounded,
      title: "Personalize Your Sounds",
      description:
          "Add custom sounds so the app can detect and notify you about what matters most.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌄 Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/splash.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  /// Skip Button
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: Text(
                        "Skip",
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 71, 92, 128),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Glass Card
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter:
                            ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.08),
                                Colors.white.withOpacity(0.03),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.10),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.05),
                                blurRadius: 25,
                                spreadRadius: 3,
                              ),
                            ],
                          ),

                          child: PageView.builder(
                            controller: _controller,
                            itemCount: pages.length,
                            onPageChanged: (index) {
                              setState(() {
                                currentPage = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return OnboardingPage(
                                page: pages[index],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Dots Indicator
                  SmoothPageIndicator(
                    controller: _controller,
                    count: pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor:
                          const Color.fromARGB(255, 71, 92, 128),
                      dotColor:
                          const Color.fromARGB(255, 189, 203, 227),
                      dotHeight: 10,
                      dotWidth: 10,
                      expansionFactor: 3,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Next / Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (currentPage == pages.length - 1) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 71, 92, 128),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        currentPage == pages.length - 1
                            ? "Get Started"
                            : "Next",
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

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