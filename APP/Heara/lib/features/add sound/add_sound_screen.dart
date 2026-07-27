import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/home_service.dart';

class AddSoundScreen extends StatefulWidget {
  const AddSoundScreen({super.key});

  @override
  State<AddSoundScreen> createState() => _AddSoundScreenState();
}

class _AddSoundScreenState extends State<AddSoundScreen> {
  final TextEditingController soundName = TextEditingController();
  final TextEditingController soundDesc = TextEditingController();

  final AudioRecorder _recorder = AudioRecorder();
  final HomeService _homeService = HomeService();

  bool loading = false;
  bool isRecording = false;

  List<String> recordings = [];

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

  /// =========================
  /// RECORD SAMPLE (3 TIMES)
  /// =========================
  Future<void> recordSample() async {
    try {
      if (recordings.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Already recorded 3 samples")),
        );
        return;
      }

      if (!isRecording) {
        bool permission = await _recorder.hasPermission();

        if (!permission) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Microphone permission denied")),
          );
          return;
        }

        final dir = await getTemporaryDirectory();

        final path =
            '${dir.path}/${soundName.text}_${DateTime.now().millisecondsSinceEpoch}.wav';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: path,
        );

        setState(() {
          isRecording = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Recording ${recordings.length + 1}/3 started")),
        );
      } else {
        final path = await _recorder.stop();

        if (path != null) {
          recordings.add(path);
        }

        setState(() {
          isRecording = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Saved ${recordings.length}/3")),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  /// =========================
  /// SAVE SOUND → CALL API 3 TIMES
  /// =========================
  /// =========================
  /// SAVE SOUND → CALL API 3 TIMES
  /// =========================
  Future<void> saveSound() async {
      if (soundName.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter sound name")),
        );
        return;
      }

      if (recordings.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Record 3 samples first")),
        );
        return;
      }

      setState(() => loading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          throw Exception("User not logged in");
        }

        int successCount = 0;

        for (String file in recordings) {
          final result = await _homeService.registerCustomSound(
            filePath: file,
            userId: user.uid,
            label: soundName.text.trim(),
          );

          // بنعتبر النداء ناجح لو رجع response مش null ومفيهوش مفتاح error صريح
          final bool looksSuccessful = result != null &&
              result['error'] == null &&
              (result['success'] != false);

          if (looksSuccessful) {
            successCount++;
          } else {
            print('🟥 [AddSoundScreen] sample failed to register: $result');
          }
        }

        if (!mounted) return;

        if (successCount == recordings.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sound added successfully 🎉")),
          );
          soundName.clear();
          soundDesc.clear();
          recordings.clear();
        } else if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "تم حفظ $successCount من ${recordings.length} عينات بس، جربي تاني",
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("فشل حفظ الصوت، تأكدي إن السيرفر شغال وجربي تاني"),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }

      if (mounted) {
        setState(() => loading = false);
      }
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
                  width: MediaQuery.of(context).size.width * 0.88,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // HEADER
                      Column(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color.fromARGB(255, 71, 92, 128)
                                    .withOpacity(0.6),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Color.fromARGB(255, 71, 92, 128),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "ADD SOUND",
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 71, 92, 128),
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Text(
                        "${recordings.length}/3 Samples",
                        style: const TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        controller: soundName,
                        style: const TextStyle(color: Colors.white),
                        decoration: input("Sound Name", Icons.music_note),
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        controller: soundDesc,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: input("Description", Icons.description),
                      ),

                      const SizedBox(height: 20),

                      // RECORD BUTTON
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: recordSample,
                              icon: Icon(isRecording ? Icons.stop : Icons.mic),
                              label: Text(isRecording ? "Stop" : "Record"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 71, 92, 128),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // SAVE
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loading ? null : saveSound,
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
                                  "Save Sound",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
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
        ],
      ),
    );
  }
}