import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';

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
import 'screens/turbulence_page.dart' as turb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'Aeroflog',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E14),
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
  // Liste pour garder l'historique de navigation interne
  final List<int> _navigationHistory = [0];

  String _userName = "Voyageur";
  String? _profileType;
  String? _profileData;
  String _userAge = "0";
  String _userOrigin = "🏳️ Pays";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "Voyageur";
      _profileType = prefs.getString('user_profile_type');
      _profileData = prefs.getString('user_profile_data');
      _userAge = (prefs.getInt('user_age') ?? 0).toString();
      _userOrigin = prefs.getString('user_country') ?? "🏳️ Pays";
    });
  }

  // Fonction pour changer de page et enregistrer l'historique
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _navigationHistory.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardPage(vols: 0, km: 0, badges: 0, totalPossibleBadges: 40, trophees: 0, favs: const [], worsts: const [], onNavigate: _onItemTapped),
      VolsPage(onDataChanged: _loadUserInfo),
      const StatsPage(),
      const BadgesPage(),
      const TropheesPage(villesVisitees: 0, escales: 0, avions: 0, moisActifs: 0),
      const turb.TurbulencePage(),
      const BlocNotePage(),
      const ModelesAvionPage(),
    ];

    // PopScope permet de gérer le bouton "Retour" physique du téléphone
    return PopScope(
      canPop: false, // On bloque la fermeture directe
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_navigationHistory.length > 1) {
          setState(() {
            _navigationHistory.removeLast();
            _selectedIndex = _navigationHistory.last;
          });
        } else {
          // Si on est sur la page d'accueil (index 0), on peut quitter
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("AEROLOG"),
          backgroundColor: const Color(0xFF0A0E14),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.cyan),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(onProfileUpdated: _loadUserInfo))),
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: const Color(0xFF0A0E14),
          child: Column(
            children: [
              _buildDrawerHeader(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero, // Supprime l'espace blanc en haut de la liste
                  children: [
                    _buildSectionTitle("MENU PRINCIPAL"),
                    _drawerTile(Icons.dashboard_rounded, "Tableau de Bord", 0),
                    _drawerTile(Icons.flight_takeoff, "Mes Vols", 1),
                    _drawerTile(Icons.analytics_rounded, "Analyse", 2),
                    _drawerTile(Icons.military_tech, "Mes Badges", 3),
                    _drawerTile(Icons.emoji_events, "Mes Succès", 4),

                    const Divider(color: Colors.white10, height: 10), // Divider plus serré
                    _buildSectionTitle("OUTILS DE VOYAGE"),
                    _drawerTile(Icons.airplanemode_active, "Modèles d'Avions", 7),
                    _drawerTile(Icons.air, "Turbulences", 5),
                    _drawerTile(Icons.edit_note, "Bloc-notes", 6),

                    const Divider(color: Colors.white10, height: 10),
                    ListTile(
                      dense: true, // Réduit la hauteur pour gagner de l'espace
                      leading: const Icon(Icons.favorite, color: Colors.pinkAccent),
                      title: const Text("Compagnies Favorites"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const FavorisPage()));
                      },
                    ),
                  ],
                ),
              ),
              _buildLogoutButton(),
            ],
          ),
        ),
        body: pages[_selectedIndex],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return UserAccountsDrawerHeader(
      margin: EdgeInsets.zero, // Enlève la marge sous le header
      decoration: const BoxDecoration(color: Color(0xFF161B22)),
      accountName: Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold)),
      accountEmail: Text("$_userOrigin • $_userAge ans"),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.grey[900],
        backgroundImage: (_profileType == 'file' && _profileData != null) ? FileImage(File(_profileData!)) : null,
        child: (_profileType == 'emoji') ? Text(_profileData!, style: const TextStyle(fontSize: 35)) : (const Icon(Icons.person)),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, int index) {
    return ListTile(
      dense: true, // Rend les éléments plus compacts pour éviter l'espace vide
      visualDensity: const VisualDensity(vertical: -2), // Resserre encore plus verticalement
      leading: Icon(icon, color: _selectedIndex == index ? Colors.cyan : Colors.white70),
      title: Text(title, style: TextStyle(color: _selectedIndex == index ? Colors.cyan : Colors.white, fontSize: 14)),
      onTap: () {
        _onItemTapped(index);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), // Padding ajusté pour l'esthétique
      child: Text(title, style: const TextStyle(fontSize: 10, color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      color: Colors.black26,
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.redAccent),
        title: const Text("Déconnexion"),
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', false);
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
        },
      ),
    );
  }
}