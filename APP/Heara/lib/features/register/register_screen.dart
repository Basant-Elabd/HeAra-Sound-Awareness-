import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/home_screen.dart';
import '../register/user_model.dart';
import '../../core/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final dobController = TextEditingController();

  DateTime? selectedDate;

  String gender = "male";
  String hearingStatus = "Normal";

  final authService = AuthService();

  bool loading = false;
  bool showPassword = false;

  InputDecoration glassInput(String label, IconData icon) {
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

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  void register() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select date of birth")),
      );
      return;
    }

    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => loading = true);

    final user = UserModel(
      firstName: firstName.text,
      lastName: lastName.text,
      phoneNumber: phone.text,
      gender: gender,
      dob: selectedDate!,
      hearingStatus: hearingStatus,
      email: email.text,
    );

    final result = await authService.registerUser(
      user: user,
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

  Widget field(String label, TextEditingController c, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        style: const TextStyle(color: Colors.white),
        decoration: glassInput(label, icon),
        validator: (v) => v == null || v.isEmpty ? "Required field" : null,
      ),
    );
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

          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.02),
                      ],
                    ),
                  ),

                  child: Form(
                    key: _formKey, // ⭐ FIX HERE
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text(
                            "HEARA",
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 71, 92, 128),
                            ),
                          ),

                          const SizedBox(height: 20),

                          field("First Name", firstName, Icons.person),
                          field("Last Name", lastName, Icons.person),
                          field("Phone", phone, Icons.phone),
                          field("Email", email, Icons.email),

                          TextFormField(
                            controller: password,
                            obscureText: !showPassword,
                            style: const TextStyle(color: const Color.fromARGB(255, 71, 92, 128)),
                            decoration: glassInput("Password", Icons.lock)
                                .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: const Color.fromARGB(255, 71, 92, 128),
                                ),
                                onPressed: () => setState(
                                    () => showPassword = !showPassword),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: confirmPassword,
                            obscureText: true,
                            style: const TextStyle(color: const Color.fromARGB(255, 71, 92, 128)),
                            decoration:
                                glassInput("Confirm Password", Icons.lock_outline),
                          ),

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: dobController,
                            readOnly: true,
                            onTap: pickDate,
                            style: const TextStyle(color: const Color.fromARGB(255, 71, 92, 128)),
                            decoration:
                                glassInput("Date of Birth", Icons.calendar_today),
                          ),

                          const SizedBox(height: 12),

                          DropdownButtonFormField(
                            value: gender,
                            dropdownColor: const Color.fromARGB(255, 71, 92, 128),
                            decoration: glassInput("Gender", Icons.person),
                            items: const ["male", "female"]
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => gender = v!),
                          ),

                          const SizedBox(height: 12),

                          DropdownButtonFormField(
                            value: hearingStatus,
                            dropdownColor: const Color.fromARGB(255, 71, 92, 128),
                            decoration:
                                glassInput("Hearing Status", Icons.hearing),
                            items: const ["Normal", "Mild", "Moderate", "Severe"]
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => hearingStatus = v!),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 71, 92, 128),
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color.fromARGB(255, 71, 92, 128)
                                        .withOpacity(0.5),
                              ),
                              onPressed: loading ? null : register,
                              child: loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Create Account",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
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
          ),
        ],
      ),
    );
  }
}