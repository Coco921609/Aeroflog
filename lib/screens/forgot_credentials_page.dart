import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForgotCredentialsPage extends StatefulWidget {
  const ForgotCredentialsPage({super.key});

  @override
  State<ForgotCredentialsPage> createState() => _ForgotCredentialsPageState();
}

class _ForgotCredentialsPageState extends State<ForgotCredentialsPage> {
  final TextEditingController _newIdController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  // --- PERSISTANCE : _loadState() CONSERVÉ ---
  Future<void> _loadState() async {
    // Optionnel : On peut pré-remplir si besoin
  }

  // --- PERSISTANCE : _onItemTapped() CONSERVÉ ET MIS À JOUR POUR LES CLÉS ---
  Future<void> _onItemTapped() async {
    if (_newIdController.text.trim().isEmpty || _newPassController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("merci tout rempli avant de valide tout"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // On ecrase les anciens identifiants par les nouveaux (Clés synchronisées avec LoginPage)
    await prefs.setString('user_id', _newIdController.text.trim());
    await prefs.setString('user_pass', _newPassController.text.trim());
    await prefs.setString('saved_id', _newIdController.text.trim());

    if (mounted) {
      // Retour à la page de connexion
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      // Utilisation d'un Stack pour mettre l'avion en arrière-plan
      body: Stack(
        children: [
          // IMAGE D'AVION EN FOND
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1544016768-982d1554f0b9?q=80&w=1887&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // FILTRE SOMBRE POUR LA LISIBILITÉ
          Container(color: Colors.black.withOpacity(0.6)),

          // CONTENU DE LA PAGE
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.airplanemode_active, color: Colors.cyanAccent, size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    "RÉINITIALISATION",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3
                    ),
                  ),
                  const SizedBox(height: 40),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "IDENTIFIANT À NOUVEAU",
                      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _newIdController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      hintText: "Entrez votre nouvel identifiant",
                      hintStyle: const TextStyle(color: Colors.white38),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.cyanAccent),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "MOT DE PASSE À NOUVEAU",
                      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _newPassController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      hintText: "Entrez votre nouveau mot de passe",
                      hintStyle: const TextStyle(color: Colors.white38),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.cyanAccent),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        elevation: 10,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _onItemTapped,
                      child: const Text(
                        "VALIDER ET REVENIR",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "ANNULER",
                      style: TextStyle(color: Colors.white70),
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