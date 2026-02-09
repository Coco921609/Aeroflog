import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_localizations/flutter_localizations.dart';

// Services
import 'ia_service.dart';
import 'navigation_service.dart';

// Écrans
import 'screens/dashboard_page.dart';
import 'screens/settings_page.dart';
import 'screens/login_page.dart';
import 'screens/vols_page.dart';
import 'screens/stats_page.dart';
import 'screens/badges_page.dart';
import 'screens/trophees_page.dart';
import 'screens/favoris_page.dart';
import 'screens/bloc_notes_page.dart';
import 'screens/modeles_avion_page.dart';
import 'screens/ai_chat_page.dart';
import 'screens/turbulence_page.dart' as turb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloque strictement en portrait (Haut et Bas)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  runApp(AeroLogApp(
    startPage: isLoggedIn ? const MainNavigation() : const LoginPage(),
  ));
}

class AeroLogApp extends StatelessWidget {
  final Widget startPage;
  const AeroLogApp({super.key, required this.startPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeroLog',
      debugShowCheckedModeBanner: false,
      // CONFIGURATION LOCALISATION (Correction erreurs précédentes)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1E88E5),
        scaffoldBackgroundColor: const Color(0xFF0A0E14),
        fontFamily: 'Inter', // Si tu as ajouté une police, sinon utilise celle par défaut
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0E14),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      home: startPage,
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  List<int> _history = [0];

  // Données utilisateur
  String _userName = "Voyageur";
  String? _profileType;
  String? _profileData;
  String _userAge = "0";
  String _userOrigin = "🏳️ Pays";

  // Stats calculées
  int _totalVols = 0;
  int _totalBadges = 0;
  int _totalEscales = 0;
  int _moisActifsCount = 0;
  int _avionsDifferents = 0;
  int _villesVisiteesCount = 0;

  List<String> _topWinners = ["---"];
  List<String> _worstWinners = ["---"];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  // Fonction de rechargement globale des données
  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    // 1. Infos Profil
    String? storedName = prefs.getString('user_name');
    String? storedOrigin = prefs.getString('user_country') ?? prefs.getString('user_origin');
    int ageInt = prefs.getInt('user_age') ?? 0;
    String? storedType = prefs.getString('user_profile_type');
    String? storedData = prefs.getString('user_profile_data');

    // 2. Logique d'analyse du JSON des vols
    String? data = prefs.getString('vols_data');
    int vCount = 0;
    int escCount = 0;
    Map<String, int> topFavMap = {};
    Map<String, int> worstMap = {};
    Set<String> uniqueMois = {};
    Set<String> uniqueVilles = {};
    Set<String> uniqueAvions = {};

    bool isValide(dynamic val) => val != null && val.toString().trim().isNotEmpty && val.toString().toLowerCase() != "aucune";

    if (data != null) {
      try {
        List<dynamic> years = jsonDecode(data);
        for (var y in years) {
          if (y["flights"] != null) {
            for (var f in y["flights"]) {
              vCount++;
              // Extraction des villes et avions
              if (isValide(f["depA"])) uniqueVilles.add(f["depA"].toString().toUpperCase());
              if (isValide(f["destA"])) uniqueVilles.add(f["destA"].toString().toUpperCase());
              if (isValide(f["avionA"])) uniqueAvions.add(f["avionA"].toString().toUpperCase());

              // Analyse compagnies
              void addComp(String? name, dynamic note) {
                if (isValide(name)) {
                  String n = name!.toUpperCase();
                  double score = double.tryParse(note.toString()) ?? 0.0;
                  if (score >= 4.0) topFavMap[n] = (topFavMap[n] ?? 0) + 1;
                  if (score > 0 && score <= 2.5) worstMap[n] = (worstMap[n] ?? 0) + 1;
                }
              }
              addComp(f["compA"], f["nA"]);

              if (f["date"] != null) {
                try {
                  DateTime dt = DateTime.parse(f["date"].toString());
                  uniqueMois.add("${dt.month}_${dt.year}");
                } catch(_) {}
              }
            }
          }
        }
      } catch (e) { debugPrint("Erreur Parsing: $e"); }
    }

    if (!mounted) return;
    setState(() {
      _userName = (storedName != null && storedName.isNotEmpty) ? storedName : "Voyageur";
      _profileType = storedType;
      _profileData = storedData;
      _userAge = ageInt.toString();
      _userOrigin = storedOrigin ?? "🏳️ Pays";
      _totalVols = vCount;
      _totalBadges = (vCount / 5).floor().clamp(0, 40);
      _avionsDifferents = uniqueAvions.length;
      _villesVisiteesCount = uniqueVilles.length;
      _topWinners = topFavMap.isNotEmpty ? (topFavMap.entries.toList()..sort((a,b) => b.value.compareTo(a.value))).take(3).map((e) => e.key).toList() : ["---"];
    });
  }

  void _onItemTapped(int index) async {
    // Navigation vers les pages "Outils" (hors BottomBar)
    if (index > 4) {
      Navigator.pop(context); // Ferme le Drawer
      Widget target;
      switch (index) {
        case 5: target = const turb.TurbulencePage(); break;
        case 6: target = const BlocNotePage(); break;
        case 7: target = const ModelesAvionPage(); break;
        case 8: target = const AIChatPage(); break;
        default: return;
      }
      await Navigator.push(context, MaterialPageRoute(builder: (context) => target));
      _loadState(); // Rafraîchit au retour
      return;
    }

    if (_selectedIndex != index) _history.add(index);
    setState(() => _selectedIndex = index);
    _loadState();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardPage(vols: _totalVols, km: 0, badges: _totalBadges, totalPossibleBadges: 40, trophees: _totalBadges, favs: _topWinners, worsts: _worstWinners, onNavigate: _onItemTapped),
      VolsPage(onDataChanged: _loadState),
      const StatsPage(),
      const BadgesPage(),
      TropheesPage(villesVisitees: _villesVisiteesCount, escales: _totalEscales, avions: _avionsDifferents, moisActifs: _moisActifsCount),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_history.length > 1) {
          setState(() {
            _history.removeLast();
            _selectedIndex = _history.last;
          });
        } else if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("AEROLOG"),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.cyan),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(onProfileUpdated: _loadState))).then((_) => _loadState()),
            ),
          ],
        ),
        drawer: _buildDrawer(),
        body: pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF161B22),
          selectedItemColor: Colors.cyan,
          unselectedItemColor: Colors.white24,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Stats'),
            BottomNavigationBarItem(icon: Icon(Icons.flight_takeoff), label: 'Vols'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Analyse'),            BottomNavigationBarItem(icon: Icon(Icons.military_tech), label: 'Badges'),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Succès'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              children: [
                _buildSectionTitle("OUTILS IA & ANALYSE"),
                _drawerTile(Icons.auto_awesome, "Assistant IA", 8, color: Colors.purpleAccent),
                _drawerTile(Icons.airplanemode_active, "Modèles Avion", 7),
                _drawerTile(Icons.air, "Turbulences", 5),
                _drawerTile(Icons.edit_note, "Bloc-notes", 6),
                const Divider(color: Colors.white10),
                _buildSectionTitle("AUTRE"),
                ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.pinkAccent),
                  title: const Text("Compagnies Favorites"),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FavorisPage())),
                ),
              ],
            ),
          ),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(color: Color(0xFF161B22)),
      accountName: Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold)),
      accountEmail: Text("$_userOrigin • $_userAge ans", style: const TextStyle(color: Colors.cyan)),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.grey[900],
        backgroundImage: (_profileType == 'file' && _profileData != null) ? FileImage(File(_profileData!)) : null,
        child: (_profileType == 'emoji') ? Text(_profileData!, style: const TextStyle(fontSize: 35)) : (_profileType == null ? const Icon(Icons.person) : null),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, int index, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white70),
      title: Text(title),
      onTap: () => _onItemTapped(index),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white24, letterSpacing: 1.2)),
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.redAccent),
      title: const Text("Déconnexion"),
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', false);
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      },
    );
  }
}