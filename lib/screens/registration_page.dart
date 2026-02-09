import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  File? _imageFile;
  String _selectedEmoji = "✈️";
  String _selectedCountry = "Choisir pays";
  String _countryEmoji = "🏳️";
  DateTime? _selectedDate;
  int? _calculatedAge;
  String _errorMessage = "";

  final List<String> _aviationEmojis = [
    "✈️", "👨‍✈️", "👩‍✈️", "🚀", "🚁", "🌍", "☁️", "🛰️", "🎫", "🛂", "🛩️", "🛫", "🛬", "🗼", "👨‍🚀"
  ];

  final List<Map<String, String>> _allCountries = [
    {"name": "Afghanistan", "emoji": "🇦🇫"}, {"name": "Afrique du Sud", "emoji": "🇿🇦"}, {"name": "Albanie", "emoji": "🇦🇱"}, {"name": "Algérie", "emoji": "🇩🇿"}, {"name": "Allemagne", "emoji": "🇩🇪"}, {"name": "Andorre", "emoji": "🇦🇩"}, {"name": "Angola", "emoji": "🇦🇴"}, {"name": "Antigua-et-Barbuda", "emoji": "🇦🇬"}, {"name": "Arabie Saoudite", "emoji": "🇸🇦"}, {"name": "Argentine", "emoji": "🇦🇷"}, {"name": "Arménie", "emoji": "🇦🇲"}, {"name": "Australie", "emoji": "🇦🇺"}, {"name": "Autriche", "emoji": "🇦🇹"}, {"name": "Azerbaïdjan", "emoji": "🇦🇿"}, {"name": "Bahamas", "emoji": "🇧🇸"}, {"name": "Bahreïn", "emoji": "🇧🇭"}, {"name": "Bangladesh", "emoji": "🇧🇩"}, {"name": "Barbade", "emoji": "🇧🇧"}, {"name": "Belgique", "emoji": "🇧🇪"}, {"name": "Belize", "emoji": "🇧🇿"}, {"name": "Bénin", "emoji": "🇧🇯"}, {"name": "Bhoutan", "emoji": "🇧🇹"}, {"name": "Biélorussie", "emoji": "🇧🇾"}, {"name": "Birmanie", "emoji": "🇲🇲"}, {"name": "Bolivie", "emoji": "🇧🇴"}, {"name": "Bosnie-Herzégovine", "emoji": "🇧🇦"}, {"name": "Botswana", "emoji": "🇧🇼"}, {"name": "Brésil", "emoji": "🇧🇷"}, {"name": "Brunei", "emoji": "🇧🇳"}, {"name": "Bulgarie", "emoji": "🇧🇬"}, {"name": "Burkina Faso", "emoji": "🇧🇫"}, {"name": "Burundi", "emoji": "🇧🇮"}, {"name": "Cambodge", "emoji": "🇰🇭"}, {"name": "Cameroun", "emoji": "🇨🇲"}, {"name": "Canada", "emoji": "🇨🇦"}, {"name": "Cap-Vert", "emoji": "🇨🇻"}, {"name": "Chili", "emoji": "🇨🇱"}, {"name": "Chine", "emoji": "🇨🇳"}, {"name": "Chypre", "emoji": "🇨🇾"}, {"name": "Colombie", "emoji": "🇨🇴"}, {"name": "Comores", "emoji": "🇰🇲"}, {"name": "Congo", "emoji": "🇨🇬"}, {"name": "Corée du Nord", "emoji": "🇰🇵"}, {"name": "Corée du Sud", "emoji": "🇰🇷"}, {"name": "Costa Rica", "emoji": "🇨🇷"}, {"name": "Côte d'Ivoire", "emoji": "🇨🇮"}, {"name": "Croatie", "emoji": "🇭🇷"}, {"name": "Cuba", "emoji": "🇨🇺"}, {"name": "Danemark", "emoji": "🇩🇰"}, {"name": "Djibouti", "emoji": "🇩🇯"}, {"name": "Dominique", "emoji": "🇩🇲"}, {"name": "Égypte", "emoji": "🇪🇬"}, {"name": "Émirats Arabes Unis", "emoji": "🇦🇪"}, {"name": "Équateur", "emoji": "🇪🇨"}, {"name": "Érythrée", "emoji": "🇪🇷"}, {"name": "Espagne", "emoji": "🇪🇸"}, {"name": "Estonie", "emoji": "🇪🇪"}, {"name": "États-Unis", "emoji": "🇺🇸"}, {"name": "Éthiopie", "emoji": "🇪🇹"}, {"name": "Fidji", "emoji": "🇫🇯"}, {"name": "Finlande", "emoji": "🇫🇮"}, {"name": "France", "emoji": "🇫🇷"}, {"name": "Gabon", "emoji": "🇬🇦"}, {"name": "Gambie", "emoji": "🇬🇲"}, {"name": "Géorgie", "emoji": "🇬🇪"}, {"name": "Ghana", "emoji": "🇬🇭"}, {"name": "Grèce", "emoji": "🇬🇷"}, {"name": "Grenade", "emoji": "🇬🇩"}, {"name": "Guatemala", "emoji": "🇬🇹"}, {"name": "Guinée", "emoji": "🇬🇳"}, {"name": "Guinée équatoriale", "emoji": "🇬🇶"}, {"name": "Guinée-Bissau", "emoji": "🇬🇼"}, {"name": "Guyana", "emoji": "🇬🇾"}, {"name": "Haïti", "emoji": "🇭🇹"}, {"name": "Honduras", "emoji": "🇭🇳"}, {"name": "Hongrie", "emoji": "🇭🇺"}, {"name": "Inde", "emoji": "🇮🇳"}, {"name": "Indonésie", "emoji": "🇮🇩"}, {"name": "Irak", "emoji": "🇮🇶"}, {"name": "Iran", "emoji": "🇮🇷"}, {"name": "Irlande", "emoji": "🇮🇪"}, {"name": "Islande", "emoji": "🇮🇸"}, {"name": "Israël", "emoji": "🇮🇱"}, {"name": "Italie", "emoji": "🇮🇹"}, {"name": "Jamaïque", "emoji": "🇯🇲"}, {"name": "Japon", "emoji": "🇯🇵"}, {"name": "Jordanie", "emoji": "🇯🇴"}, {"name": "Kazakhstan", "emoji": "🇰🇿"}, {"name": "Kenya", "emoji": "🇰🇪"}, {"name": "Kirghizistan", "emoji": "🇰🇬"}, {"name": "Kiribati", "emoji": "🇰🇮"}, {"name": "Koweït", "emoji": "🇰🇼"}, {"name": "Laos", "emoji": "🇱🇦"}, {"name": "Lesotho", "emoji": "🇱🇸"}, {"name": "Lettonie", "emoji": "🇱🇻"}, {"name": "Liban", "emoji": "🇱🇧"}, {"name": "Liberia", "emoji": "🇱🇷"}, {"name": "Libye", "emoji": "🇱🇾"}, {"name": "Liechtenstein", "emoji": "🇱🇮"}, {"name": "Lituanie", "emoji": "🇱🇹"}, {"name": "Luxembourg", "emoji": "🇱🇺"}, {"name": "Macédoine du Nord", "emoji": "🇲🇰"}, {"name": "Madagascar", "emoji": "🇲🇬"}, {"name": "Malaisie", "emoji": "🇲🇾"}, {"name": "Malawi", "emoji": "🇲🇼"}, {"name": "Maldives", "emoji": "🇲🇻"}, {"name": "Mali", "emoji": "🇲🇱"}, {"name": "Malte", "emoji": "🇲🇹"}, {"name": "Maroc", "emoji": "🇲🇦"}, {"name": "Maurice", "emoji": "🇲🇺"}, {"name": "Mauritanie", "emoji": "🇲🇷"}, {"name": "Mexique", "emoji": "🇲🇽"}, {"name": "Moldavie", "emoji": "🇲🇩"}, {"name": "Monaco", "emoji": "🇲🇨"}, {"name": "Mongolie", "emoji": "🇲🇳"}, {"name": "Monténégro", "emoji": "🇲🇪"}, {"name": "Mozambique", "emoji": "🇲🇿"}, {"name": "Namibie", "emoji": "🇳🇦"}, {"name": "Nauru", "emoji": "🇳🇷"}, {"name": "Népal", "emoji": "🇳🇵"}, {"name": "Nicaragua", "emoji": "🇳🇮"}, {"name": "Niger", "emoji": "🇳🇪"}, {"name": "Nigeria", "emoji": "🇳🇬"}, {"name": "Norvège", "emoji": "🇳🇴"}, {"name": "Nouvelle-Zélande", "emoji": "🇳🇿"}, {"name": "Oman", "emoji": "🇴🇲"}, {"name": "Ouganda", "emoji": "🇺🇬"}, {"name": "Ouzbékistan", "emoji": "🇺🇿"}, {"name": "Pakistan", "emoji": "🇵🇰"}, {"name": "Palaos", "emoji": "🇵🇼"}, {"name": "Panama", "emoji": "🇵🇦"}, {"name": "Papouasie-Nouvelle-Guinée", "emoji": "🇵🇬"}, {"name": "Paraguay", "emoji": "🇵🇾"}, {"name": "Pays-Bas", "emoji": "🇳🇱"}, {"name": "Pérou", "emoji": "🇵🇪"}, {"name": "Philippines", "emoji": "🇵🇭"}, {"name": "Pologne", "emoji": "🇵🇱"}, {"name": "Portugal", "emoji": "🇵🇹"}, {"name": "Qatar", "emoji": "🇶🇦"}, {"name": "RDC", "emoji": "🇨🇩"}, {"name": "République centrafricaine", "emoji": "🇨🇫"}, {"name": "République dominicaine", "emoji": "🇩🇴"}, {"name": "République tchèque", "emoji": "🇨🇿"}, {"name": "Roumanie", "emoji": "🇷🇴"}, {"name": "Royaume-Uni", "emoji": "🇬🇧"}, {"name": "Russie", "emoji": "🇷🇺"}, {"name": "Rwanda", "emoji": "🇷🇼"}, {"name": "Sainte-Lucie", "emoji": "🇱🇨"}, {"name": "Saint-Marin", "emoji": "🇸🇲"}, {"name": "Salvador", "emoji": "🇸🇻"}, {"name": "Samoa", "emoji": "🇼🇸"}, {"name": "Sénégal", "emoji": "🇸🇳"}, {"name": "Serbie", "emoji": "🇷🇸"}, {"name": "Seychelles", "emoji": "🇸🇨"}, {"name": "Sierra Leone", "emoji": "🇸🇱"}, {"name": "Singapour", "emoji": "🇸🇬"}, {"name": "Slovaquie", "emoji": "🇸🇰"}, {"name": "Slovénie", "emoji": "🇸🇮"}, {"name": "Somalie", "emoji": "🇸🇴"}, {"name": "Soudan", "emoji": "🇸🇩"}, {"name": "Soudan du Sud", "emoji": "🇸🇸"}, {"name": "Sri Lanka", "emoji": "🇱🇰"}, {"name": "Suède", "emoji": "🇸🇪"}, {"name": "Suisse", "emoji": "🇨🇭"}, {"name": "Suriname", "emoji": "🇸🇷"}, {"name": "Syrie", "emoji": "🇸🇾"}, {"name": "Tadjikistan", "emoji": "🇹🇯"}, {"name": "Tanzanie", "emoji": "🇹🇿"}, {"name": "Tchad", "emoji": "🇹🇩"}, {"name": "Thaïlande", "emoji": "🇹🇭"}, {"name": "Timor oriental", "emoji": "🇹🇱"}, {"name": "Togo", "emoji": "🇹🇬"}, {"name": "Tonga", "emoji": "🇹🇴"}, {"name": "Trinité-et-Tobago", "emoji": "🇹🇹"}, {"name": "Tunisie", "emoji": "🇹🇳"}, {"name": "Turkménistan", "emoji": "🇹🇲"}, {"name": "Turquie", "emoji": "🇹🇷"}, {"name": "Tuvalu", "emoji": "🇹🇻"}, {"name": "Ukraine", "emoji": "🇺🇦"}, {"name": "Uruguay", "emoji": "🇺🇾"}, {"name": "Vanuatu", "emoji": "🇻🇺"}, {"name": "Vatican", "emoji": "🇻🇦"}, {"name": "Venezuela", "emoji": "🇻🇪"}, {"name": "Vietnam", "emoji": "🇻🇳"}, {"name": "Yémen", "emoji": "🇾🇪"}, {"name": "Zambie", "emoji": "🇿🇲"}, {"name": "Zimbabwe", "emoji": "🇿🇼"}
  ];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _selectedEmoji = "";
        _errorMessage = "";
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _calculatedAge = DateTime.now().year - picked.year;
        if (DateTime.now().month < picked.month || (DateTime.now().month == picked.month && DateTime.now().day < picked.day)) {
          _calculatedAge = _calculatedAge! - 1;
        }
        _errorMessage = "";
      });
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E26),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 15),
            const Text("SÉLECTIONNER UN PAYS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _allCountries.length,
                itemBuilder: (context, index) => ListTile(
                  leading: Text(_allCountries[index]['emoji']!, style: const TextStyle(fontSize: 22)),
                  title: Text(_allCountries[index]['name']!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  onTap: () {
                    setState(() {
                      _selectedCountry = _allCountries[index]['name']!;
                      _countryEmoji = _allCountries[index]['emoji']!;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegistration() async {
    if (_userController.text.isEmpty || _idController.text.isEmpty || _passController.text.isEmpty || _selectedDate == null || _selectedCountry == "Choisir pays") {
      setState(() => _errorMessage = "⚠️ Veuillez remplir tous les champs !");
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _userController.text.trim());
    await prefs.setString('user_id', _idController.text.trim());
    await prefs.setString('user_pass', _passController.text.trim());
    await prefs.setString('user_country', "$_countryEmoji $_selectedCountry");
    await prefs.setInt('user_age', _calculatedAge ?? 0);
    await prefs.setString('user_profile_type', _imageFile != null ? 'file' : 'emoji');
    await prefs.setString('user_profile_data', _imageFile != null ? _imageFile!.path : _selectedEmoji);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(title: const Text("CRÉATION COMPTE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blueAccent, width: 2), color: Colors.white.withOpacity(0.05),
                  image: _imageFile != null ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) : null,
                ),
                child: _imageFile == null ? Center(child: Text(_selectedEmoji, style: const TextStyle(fontSize: 40))) : null,
              ),
            ),
            TextButton(onPressed: _pickImage, child: const Text("GALERIE PHOTO", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12))),
            const Text("OU EMOJI AVIATION", style: TextStyle(color: Colors.white54, fontSize: 10)),
            const SizedBox(height: 10),

            SizedBox(
              height: 100,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 5, crossAxisSpacing: 5),
                itemCount: _aviationEmojis.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => setState(() { _selectedEmoji = _aviationEmojis[index]; _imageFile = null; }),
                  child: Container(
                    decoration: BoxDecoration(color: _selectedEmoji == _aviationEmojis[index] && _imageFile == null ? Colors.blueAccent.withOpacity(0.3) : Colors.white10, shape: BoxShape.circle),
                    child: Center(child: Text(_aviationEmojis[index], style: const TextStyle(fontSize: 20))),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),
            if (_errorMessage.isNotEmpty) Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),
            _buildField("Nom d'utilisateur", Icons.person_outline, Colors.blueAccent, controller: _userController),

            GestureDetector(
                onTap: _showCountryPicker,
                child: AbsorbPointer(child: _buildField("$_countryEmoji $_selectedCountry", Icons.public, Colors.purpleAccent))
            ),

            GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(child: _buildField(_selectedDate == null ? "Date de naissance" : "Âge : $_calculatedAge ans", Icons.calendar_today, Colors.cyanAccent))
            ),

            _buildField("Identifiant", Icons.alternate_email, Colors.greenAccent, controller: _idController),
            _buildField("Mot de passe", Icons.lock_outline, Colors.orangeAccent, controller: _passController, isPass: true),

            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: _handleRegistration, child: const Text("VALIDER ET CRÉER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String hint, IconData icon, Color color, {TextEditingController? controller, bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller, obscureText: isPass,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
          prefixIcon: Icon(icon, color: color, size: 20),
          filled: true, fillColor: Colors.white.withOpacity(0.05),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: color.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: color, width: 2)),
        ),
      ),
    );
  }
}