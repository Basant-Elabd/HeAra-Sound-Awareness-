import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_model.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingModel page;

  const OnboardingPage({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          page.icon,
          size: 120,
          color: const Color.fromARGB(255, 71, 92, 128),
        ),

        const SizedBox(height: 40),

        Text(
          page.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 71, 92, 128),
          ),
        ),

        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            page.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18,
              color: const Color.fromARGB(255, 71, 92, 128),
            ),
          ),
        ),
      ],
    );
  }
}