import 'dart:ui';
import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../register/register_screen.dart';
import '../../core/services/auth_service.dart';
import '../../core/validation/validation_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final email = TextEditingController();
  final password = TextEditingController();

  final authService = AuthService();

  bool loading = false;
  bool showPassword = false;

  void login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    String result = await authService.loginUser(
      email: email.text,
      password: password.text,
    );

    setState(() => loading = false);

    if (result == "success") {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  InputDecoration input(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color.fromARGB(255, 71, 92, 128)),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

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

          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
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
                        color: Colors.white.withOpacity(0.08),
                        blurRadius: 20,
                      ),
                    ],
                  ),

                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        
                        // 🔵 LOGO CIRCLE + LOGIN
                        Column(
                          children: [
                            Container(
                              width: 130,
                              height: 130,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color.fromARGB(255, 71, 92, 128)
                                      .withOpacity(0.6),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                "HEARA",
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(255, 71, 92, 128),
                                  letterSpacing: 2,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              "LOGIN",
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: const Color.fromARGB(255, 71, 92, 128),
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // 📧 Email
                        TextFormField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: input("Email", Icons.email),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Email is required";
                            }
                            if (!ValidationUtils.isValidEmail(value)) {
                              return "Invalid email format";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 15),

                        // 🔒 Password
                        TextFormField(
                          controller: password,
                          obscureText: !showPassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: input("Password", Icons.lock).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color.fromARGB(255, 71, 92, 128),
                              ),
                              onPressed: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Password required";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 25),

                        // 🔘 Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: loading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 71, 92, 128),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Login",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 🔥 Register
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Don't have an account? Create one",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 71, 92, 128),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
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