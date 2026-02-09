import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onProfileUpdated;

  const SettingsPage({super.key, required this.onProfileUpdated});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  String? _profileType;
  String? _profileData;
  String _userAge = "0";
  String _userOrigin = "---";

  final List<String> _availableEmojis = [
    "✈️", "👨‍✈️", "👩‍✈️", "🚀", "🚁", "🌍", "☁️", "🛰️", "🎫", "🛂", "🛩️", "🛫", "🛬", "🗼", "👨‍🚀"
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? "Utilisateur";
      _idController.text = prefs.getString('user_id') ?? "";
      _passController.text = prefs.getString('user_pass') ?? "";

      int ageInt = prefs.getInt('user_age') ?? 0;
      _userAge = ageInt.toString();

      _userOrigin = prefs.getString('user_country') ?? prefs.getString('user_origin') ?? "🏳️ Pays";

      _profileType = prefs.getString('user_profile_type');
      _profileData = prefs.getString('user_profile_data');
    });
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();

    String newName = _nameController.text.trim();
    if (newName.isEmpty) newName = "Utilisateur";

    await prefs.setString('user_name', newName);
    await prefs.setString('user_id', _idController.text);
    await prefs.setString('user_pass', _passController.text);
    await prefs.setString('user_country', _userOrigin);

    if (_profileType != null && _profileData != null) {
      await prefs.setString('user_profile_type', _profileType!);
      await prefs.setString('user_profile_data', _profileData!);
    }

    widget.onProfileUpdated();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Paramètres sauvegardés !"),
          backgroundColor: Colors.blueAccent,
          duration: Duration(seconds: 1),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.cyan),
                title: const Text("Galerie Photo", style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(context); _pickImage(); },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_emotions, color: Colors.pinkAccent),
                title: const Text("Choisir un Emoji", style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(context); _showEmojiPicker(); },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEmojiPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          title: const Text("Choisir un profil", style: TextStyle(color: Colors.white, fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10,
              ),
              itemCount: _availableEmojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() { _profileType = 'emoji'; _profileData = _availableEmojis[index]; });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: Text(_availableEmojis[index], style: const TextStyle(fontSize: 25)),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _changeCountry() {
    showCountryPicker(
      context: context,
      countryListTheme: CountryListThemeData(
        backgroundColor: const Color(0xFF161B22),
        textStyle: const TextStyle(color: Colors.white),
        borderRadius: BorderRadius.circular(20),
      ),
      onSelect: (Country country) {
        setState(() { _userOrigin = "${country.flagEmoji} ${country.name.toUpperCase()}"; });
      },
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() { _profileType = 'file'; _profileData = pickedFile.path; });
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A0E14),
          title: const Text("Supprimer le compte ?", style: TextStyle(color: Colors.redAccent)),
          content: const Text("Cette action est irréversible. Toutes vos données seront perdues."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULER", style: TextStyle(color: Colors.white))),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
                }
              },
              child: const Text("SUPPRIMER", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        title: const Text("PARAMÈTRES", style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showProfileOptions,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Colors.cyan, Colors.pinkAccent]),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[900],
                  backgroundImage: (_profileType == 'file' && _profileData != null && File(_profileData!).existsSync())
                      ? FileImage(File(_profileData!))
                      : null,
                  child: (_profileType == 'emoji' && _profileData != null)
                      ? Text(_profileData!, style: const TextStyle(fontSize: 50))
                      : ((_profileType == null || (_profileType == 'file' && (_profileData == null || !File(_profileData!).existsSync())))
                      ? const Icon(Icons.camera_alt, size: 40, color: Colors.white24)
                      : null),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _changeCountry,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          const Text("ORIGINE", style: TextStyle(color: Colors.white38, fontSize: 10)),
                          const SizedBox(height: 5),
                          Text(_userOrigin, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        const Text("ÂGE", style: TextStyle(color: Colors.white38, fontSize: 10)),
                        const SizedBox(height: 5),
                        Text("$_userAge ans", style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildInputField("Nom d'utilisateur", Icons.person, _nameController, Colors.cyan),
            const SizedBox(height: 20),
            _buildInputField("Identifiant", Icons.alternate_email, _idController, Colors.orangeAccent),
            const SizedBox(height: 20),
            _buildInputField("Mot de passe", Icons.lock_outline, _passController, Colors.purpleAccent, isPassword: true),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _saveAll,
              child: Container(
                width: double.infinity, height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(colors: [Colors.cyan, Colors.blueAccent]),
                  boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: const Center(child: Text("SAUVEGARDER TOUT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white))),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _confirmDeleteAccount,
              child: const Text("SUPPRIMER LE COMPTE", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),

            // --- SECTION VERSION 8.5 COLORÉE ---
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.cyan.withOpacity(0.4), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.cyan, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "VERSION 8.5",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, IconData icon, TextEditingController controller, Color accentColor, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: accentColor, fontSize: 12),
        prefixIcon: Icon(icon, color: accentColor),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: accentColor)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
      ),
    );
  }
}