import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registration_page.dart';
import 'forgot_credentials_page.dart';
import '../main.dart';
import 'dart:io';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  String _errorMessage = "";
  String? _profileType;
  String? _profileData;
  bool _hasAccount = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  // --- PERSISTANCE : _loadState() ---
  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      String? storedId = prefs.getString('user_id');
      _hasAccount = storedId != null && storedId.isNotEmpty;
      _userController.text = prefs.getString('saved_id') ?? storedId ?? "";
      _profileType = prefs.getString('user_profile_type');
      _profileData = prefs.getString('user_profile_data');
    });
  }

  // --- PERSISTANCE : _onItemTapped ---
  void _onItemTapped() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationPage()),
    ).then((_) => _loadState());
  }

  Future<void> _handleLogin() async {
    final prefs = await SharedPreferences.getInstance();
    String storedUser = (prefs.getString('user_id') ?? "").trim();
    String storedPass = (prefs.getString('user_pass') ?? "").trim();
    String enteredUser = _userController.text.trim();
    String enteredPass = _passController.text.trim();

    setState(() {
      if (enteredUser.isEmpty || enteredPass.isEmpty) {
        _errorMessage = "Veuillez remplir tous les champs";
      } else if (storedUser.isEmpty) {
        _errorMessage = "Aucun compte trouvé. Créez-en un !";
      } else if (enteredUser != storedUser && enteredPass != storedPass) {
        _errorMessage = "identifiant et mot de passe incorrect";
      } else if (enteredUser != storedUser) {
        _errorMessage = "identifiant incorrect";
      } else if (enteredPass != storedPass) {
        _errorMessage = "mot de passe incorrect";
      } else {
        _errorMessage = "";
        prefs.setBool('is_logged_in', true);
        prefs.setString('saved_id', enteredUser);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const MainNavigation()));
      }
    });

    if (_errorMessage.isNotEmpty) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _errorMessage = "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_profileData != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.yellowAccent, width: 2),
                    image: _profileType == 'file'
                        ? DecorationImage(image: FileImage(File(_profileData!)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _profileType == 'emoji'
                      ? Center(child: Text(_profileData!, style: const TextStyle(fontSize: 40)))
                      : null,
                )
              else
                const Icon(Icons.flight_takeoff, size: 70, color: Colors.yellowAccent),

              const SizedBox(height: 5),
              const Text("AEROLOG", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.cyanAccent)),
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _hasAccount ? Colors.greenAccent.withOpacity(0.3) : Colors.cyanAccent.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(_hasAccount ? "Ravi de vous revoir !" : "Bienvenue sur votre carnet de vol !", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 5),
                    Text(_hasAccount ? "Connectez-vous pour accéder à vos rapports de vol." : "Veuillez créer un compte pour commencer à enregistrer vos voyages.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                  ],
                ),
              ),

              const SizedBox(height: 15),
              SizedBox(height: 30, child: Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14))),
              const SizedBox(height: 5),

              TextField(
                controller: _userController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Identifiant",
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true, fillColor: Colors.white10,
                  prefixIcon: const Icon(Icons.person, color: Colors.greenAccent, size: 20),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.greenAccent, width: 2)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white, width: 2)),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _passController,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Mot de passe",
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true, fillColor: Colors.white10,
                  prefixIcon: const Icon(Icons.lock, color: Colors.orangeAccent, size: 20),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.orangeAccent, width: 2)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white, width: 2)),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotCredentialsPage())),
                  child: const Text("Identifiant ou mot de passe oublié ?", style: TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  onPressed: _handleLogin,
                  child: const Text("SE CONNECTER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: _onItemTapped,
                child: const Text("Nouveau ici ? Créer un compte", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}