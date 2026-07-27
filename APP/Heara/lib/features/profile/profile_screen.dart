import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        setState(() {
          userData = doc.data();
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  Widget glassCard(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
          child: child,
        ),
      ),
    );
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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

          Container(
            color: Colors.black.withOpacity(0.35),
          ),

          SafeArea(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : userData == null
                    ? const Center(
                        child: Text(
                          "No user data found",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              "HeAra Profile",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 25),

                            CircleAvatar(
                              radius: 55,
                              backgroundColor:
                                  Colors.white.withOpacity(0.15),
                              child: const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 15),

                            Text(
                              "Welcome, ${userData!['firstName'] ?? 'User'} 👋",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              userData!['email'] ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),

                            const SizedBox(height: 25),

                            Row(
                              children: [
                                Expanded(
                                  child: glassCard(
                                    Column(
                                      children: [
                                        const Icon(
                                          Icons.hearing,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          "Hearing",
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          userData!['hearingStatus'] ?? '',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: glassCard(
                                    const Column(
                                      children: [
                                        Icon(
                                          Icons.notifications_active,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          "Alerts",
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          "Enabled",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            glassCard(
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Personal Information",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  const Divider(
                                    color: Colors.white24,
                                  ),

                                  infoRow(
                                    "First Name",
                                    userData!['firstName'] ?? '',
                                  ),

                                  infoRow(
                                    "Last Name",
                                    userData!['lastName'] ?? '',
                                  ),

                                  infoRow(
                                    "Email",
                                    userData!['email'] ?? '',
                                  ),

                                  infoRow(
                                    "Phone",
                                    userData!['phoneNumber'] ?? '',
                                  ),

                                  infoRow(
                                    "Gender",
                                    userData!['gender'] ?? '',
                                  ),

                                  infoRow(
                                    "Hearing Status",
                                    userData!['hearingStatus'] ?? '',
                                  ),

                                  infoRow(
                                    "Date of Birth",
                                    userData!['dob'] ?? '',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.logout),
                                label: const Text(
                                  "Logout",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(15),
                                  ),
                                ),
                                onPressed: () async {
                                  await FirebaseAuth.instance.signOut();

                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    "/login",
                                    (route) => false,
                                  );
                                },
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