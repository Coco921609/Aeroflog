import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:convert';
import 'dart:math' as math;

class TurbulencePage extends StatefulWidget {
  const TurbulencePage({super.key});

  @override
  State<TurbulencePage> createState() => _TurbulencePageState();
}

class _TurbulencePageState extends State<TurbulencePage> with TickerProviderStateMixin {
  Map<String, Map<String, List<dynamic>>> _organizedData = {};
  Map<String, int> _globalTotalStats = {"🟢 CALME": 0, "🟡 MODÉRÉ": 0, "🔴 SÉVÈRE": 0};
  bool _isLoading = true;
  late AnimationController _animationController;
  late AnimationController _flightController;

  final List<Color> _yearColors = [
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.tealAccent,
    Colors.pinkAccent,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this)..repeat();
    _flightController = AnimationController(duration: const Duration(seconds: 10), vsync: this)..repeat();
    _loadAndOrganize();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _flightController.dispose();
    super.dispose();
  }

  bool _isValid(dynamic comp) {
    if (comp == null) return false;
    String s = comp.toString().toUpperCase().trim();
    return s.isNotEmpty && s != "AUCUNE";
  }

  Future<void> _loadAndOrganize() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('vols_data');

    if (data == null || data.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      List<dynamic> rawList = jsonDecode(data);
      Map<String, Map<String, List<dynamic>>> tempStructure = {};
      int gCalme = 0, gModere = 0, gSevere = 0;

      for (var yearEntry in rawList) {
        String year = (yearEntry['year'] ?? "Inconnu").toString();
        List<dynamic> flights = yearEntry['flights'] ?? [];

        for (var f in flights) {
          bool hasValidSegment = _isValid(f['compA']) || _isValid(f['compR']) ||
              (f['listEscA'] != null && f['listEscA'].any((e) => _isValid(e['comp']))) ||
              (f['listEscR'] != null && f['listEscR'].any((e) => _isValid(e['comp'])));

          if (!hasValidSegment) continue;

          DateTime date = DateTime.parse(f['dateA'] ?? f['date'] ?? DateTime.now().toString());
          String monthName = _getMonthName(date.month);

          if (!tempStructure.containsKey(year)) tempStructure[year] = {};
          if (!tempStructure[year]!.containsKey(monthName)) tempStructure[year]![monthName] = [];
          tempStructure[year]![monthName]!.add(f);

          var stats = _calculateStats([f]);
          gCalme += stats["🟢 CALME"]!;
          gModere += stats["🟡 MODÉRÉ"]!;
          gSevere += stats["🔴 SÉVÈRE"]!;
        }
      }

      if (mounted) {
        setState(() {
          _organizedData = tempStructure;
          _globalTotalStats = {"🟢 CALME": gCalme, "🟡 MODÉRÉ": gModere, "🔴 SÉVÈRE": gSevere};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getMonthName(int month) => ["Janvier","Février","Mars","Avril","Mai","Juin","Juillet","Août","Septembre","Octobre","Novembre","Décembre"][month - 1];

  Map<String, int> _calculateStats(List<dynamic> flights) {
    int c = 0, m = 0, s = 0;
    void count(dynamic status, dynamic comp) {
      if (!_isValid(comp)) return;
      String res = status?.toString().toLowerCase() ?? "";
      if (res.contains("pire") || res.contains("severe")) s++;
      else if (res.contains("moyen") || res.contains("modere")) m++;
      else c++;
    }
    for (var f in flights) {
      count(f['turbAller'], f['compA']);
      if (f['listEscA'] != null) {
        for (var e in f['listEscA']) count(e['turb'], e['comp']);
      }
      count(f['turbRetour'], f['compR']);
      if (f['listEscR'] != null) {
        for (var e in f['listEscR']) count(e['turb'], e['comp']);
      }
    }
    return {"🟢 CALME": c, "🟡 MODÉRÉ": m, "🔴 SÉVÈRE": s};
  }

  String _getEmoji(dynamic status) {
    String s = status?.toString().toLowerCase() ?? "";
    if (s.contains("moyen") || s.contains("modere")) return "🟡 MODÉRÉ";
    if (s.contains("pire") || s.contains("severe")) return "🔴 SÉVÈRE";
    return "🟢 CALME";
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('turbulence-page-visibility-key'),
      onVisibilityChanged: (info) { if (info.visibleFraction > 0.1) _loadAndOrganize(); },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E14),
        appBar: AppBar(
          title: const Text("PHYSIQUE ET MODÈLES DE VOL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildAnimatedPlaneSafety(),
            const SizedBox(height: 20),

            _sectionLabel("RÉSUMÉ GLOBAL DE TOUS LES VOLS", Colors.white),
            _buildGlobalDashboard(),
            const SizedBox(height: 30),

            _sectionLabel("COMPRENDRE L'AIR : CHAUD VS FROID", Colors.orangeAccent),
            _buildAirComparisonTable(),
            const SizedBox(height: 30),

            _sectionLabel("LES TURBULENCES SONT-ELLES DANGEREUSES ?", Colors.greenAccent),
            _buildDangerVerdict(),
            const SizedBox(height: 30),

            _sectionLabel("VITESSE ET STABILITÉ (275 KM/H)", Colors.redAccent),
            _buildSpeedAltitudeSection(),
            const SizedBox(height: 30),

            _sectionLabel("PHASES DE VOL ET STABILITÉ", Colors.blueAccent),
            _buildFlightPhasesTable(),
            const SizedBox(height: 30),

            _sectionLabel("SPÉCIFICATIONS AIRBUS", Colors.blueAccent),
            _buildAirbusSpecs(),
            const SizedBox(height: 30),

            _sectionLabel("SPÉCIFICATIONS BOEING", Colors.orangeAccent),
            _buildBoeingSpecs(),
            const SizedBox(height: 30),

            _sectionLabel("SPÉCIFICATIONS EMBRAER", Colors.tealAccent),
            _buildEmbraerSpecs(),
            const SizedBox(height: 30),

            _sectionLabel("DÉTAILS MÉTÉO PAR PHASE DE VOL", Colors.white),
            _buildWeatherMatrix(),
            const SizedBox(height: 30),

            _sectionLabel("MÉTÉO ET RESSENTI EN VOL", Colors.purpleAccent),
            _buildWeatherImpactTable(),
            const SizedBox(height: 30),

            _sectionLabel("LÉGENDE ET SÉCURITÉ", Colors.orangeAccent),
            _buildLegend(),
            const SizedBox(height: 40),

            _sectionLabel("HISTORIQUE DÉTAILLÉ", Colors.blueAccent),
            ..._organizedData.entries.toList().asMap().entries.map((entry) {
              return _buildYearSection(entry.value.key, entry.value.value, entry.key);
            }).toList(),
          ],
        ),
      ),
    );
  }

  // --- SECTIONS APPAREILS DÉTAILLÉES PAR MODÈLE ---

  Widget _buildAirbusSpecs() {
    return Column(children: [
      _specItem("A220-100 / A220-300", "C : Incroyable | M : Souple | P : Ailes actives", "Technologie de pointe : ses ailes absorbent les impacts comme des amortisseurs, réduisant l'effet de chute.", Colors.blueAccent),
      _specItem("A318 / A319", "C : Fluide | M : Secousses | P : Très réactif", "Leur petite taille les rend vifs, mais les commandes électriques corrigent instantanément les trajectoires.", Colors.blueAccent),
      _specItem("A320 / A321 (CEO & NEO)", "C : Parfait | M : Stable | P : Équilibré", "La référence en stabilité. Les oscillations sont maîtrisées pour une traversée de zone agitée prévisible.", Colors.blueAccent),
      _specItem("A330 / A340", "C : Royal | M : Lent | P : Balancement lourd", "La masse imposante de ces appareils lisse les courants d'air. Les mouvements sont amples mais très lents.", Colors.blueAccent),
      _specItem("A350 / A380", "C : Immobile | M : Souple | P : Anti-rafales", "Capteurs intelligents qui ajustent les ailes en millisecondes. L'A380 est le plus stable au monde en turbulence.", Colors.blueAccent),
    ]);
  }

  Widget _buildBoeingSpecs() {
    return Column(children: [
      _specItem("737-700 / 800 / 900", "C : Direct | M : Vibrations | P : Sec", "Conception rigide. On ressent physiquement l'air frapper la carlingue. Très solide mais moins filtré.", Colors.orangeAccent),
      _specItem("737 MAX 8 / MAX 9", "C : Amorti | M : Stable | P : Plus doux", "Nouveaux moteurs et électronique moderne offrant une stabilité nettement supérieure aux anciennes générations.", Colors.orangeAccent),
      _specItem("747 / 757 / 767", "C : Stable | M : Lourd | P : Solide", "Des appareils massifs. Leur inertie les rend insensibles aux petites et moyennes turbulences.", Colors.orangeAccent),
      _specItem("777 / 787 DREAMLINER", "C : High-tech | M : Filtré | P : Flexibilité", "Le 787 utilise la courbure extrême de ses ailes en carbone pour absorber l'énergie des chocs verticaux.", Colors.orangeAccent),
    ]);
  }

  Widget _buildEmbraerSpecs() {
    return Column(children: [
      _specItem("ERJ 145 / E170 / E175", "C : Agile | M : Mobile | P : Très vif", "Sensibles aux micro-courants d'air en raison de leur légèreté, mais réagissent sainement et rapidement.", Colors.tealAccent),
      _specItem("E190 / E195", "C : Stable | M : Rail | P : Équilibré", "Excellent comportement en croisière. Il offre un ressenti de 'gros avion' malgré sa taille de jet régional.", Colors.tealAccent),
      _specItem("E190-E2 / E195-E2", "C : Doux | M : Filtré | P : Ultra-fluide", "Concurrent direct de l'A220. Ses nouvelles ailes allongées pénêtrent l'air avec beaucoup moins de résistance.", Colors.tealAccent),
    ]);
  }

  Widget _specItem(String title, String subtitle, String desc, Color accentColor) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: accentColor.withOpacity(0.05),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: accentColor.withOpacity(0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
      const SizedBox(height: 6),
      Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 9, height: 1.4)),
    ]),
  );

  // --- AUTRES COMPOSANTS ---

  Widget _buildWeatherMatrix() {
    return _buildCustomTable([
      _tableRow("DÉCOLLAGE", "Sensible au cisaillement du vent (windshear). La poussée réacteurs compense l'instabilité.", Colors.greenAccent),
      _tableRow("MONTÉE", "Traversée des couches thermiques. Zone de frottement entre l'air chaud sol et l'air froid altitude.", Colors.blueAccent),
      _tableRow("CROISIÈRE", "Stable à 95%. Les turbulences en ciel clair (CAT) sont dues aux Jet Streams invisibles au radar.", Colors.white),
      _tableRow("DESCENTE", "Compression de l'air. L'avion retrouve une densité d'air plus forte, créant une portance plus ferme.", Colors.orangeAccent),
      _tableRow("APPROCHE", "Sensible au relief et aux bâtiments au sol qui créent des micro-vortex d'air.", Colors.redAccent),
    ]);
  }

  Widget _buildLegend() {
    return _buildCustomTable([
      _tableRow("🟢 CALME", "L'air est parfaitement lisse. Aucune contrainte sur la structure.", Colors.greenAccent),
      _tableRow("🟡 MODÉRÉ", "L'avion bouge mais conserve son altitude. Le service à bord peut être interrompu.", Colors.orangeAccent),
      _tableRow("🔴 SÉVÈRE", "Changements d'altitude brusques. Les pilotes appliquent la vitesse de pénétration (275 km/h).", Colors.redAccent),
      _tableRow("💡 INFO", "Un avion ne peut pas tomber. Il 'flotte' sur l'air comme un bateau sur l'eau.", Colors.blueAccent),
    ]);
  }

  Widget _buildAnimatedPlaneSafety() {
    return AnimatedBuilder(
      animation: _flightController,
      builder: (context, child) {
        double t = _flightController.value;
        double x = (t * 2) - 1;
        double y = 0; double angle = 0; String phase = ""; String desc = "";
        if (t < 0.3) {
          phase = "DÉCOLLAGE"; y = 0.5 - (t * 1.5); angle = -0.3;
          desc = "L'avion accélère et monte. L'air sous les ailes crée la portance nécessaire.";
        } else if (t < 0.7) {
          phase = "CROISIÈRE"; y = -0.2; angle = 0;
          desc = "L'avion est stable à haute altitude. Le vol est rectiligne et fluide.";
        } else {
          phase = "ATTERRISSAGE"; y = -0.2 + ((t - 0.7) * 2); angle = 0.2;
          desc = "L'avion descend doucement vers la piste en réduisant sa vitesse.";
        }
        return Container(
          height: 180,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
          child: Column(children: [
            Expanded(child: Stack(children: [
              Center(child: Divider(color: Colors.white.withOpacity(0.05), thickness: 1)),
              Align(alignment: Alignment(x, y), child: Transform.rotate(angle: angle, child: const Icon(Icons.airplanemode_active, color: Colors.blueAccent, size: 30))),
              Positioned(top: 10, left: 15, child: Text(phase, style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold))),
            ])),
            Padding(padding: const EdgeInsets.all(12.0), child: Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 9))),
          ]),
        );
      },
    );
  }

  Widget _buildAirComparisonTable() => _buildCustomTable([
    _tableRow("AIR CHAUD", "Léger, monte vers le haut. Crée des courants ascendants.", Colors.orangeAccent),
    _tableRow("AIR FROID", "Dense et lourd, il descend. L'avion y est plus stable.", Colors.blueAccent),
  ]);

  Widget _buildFlightPhasesTable() => _buildCustomTable([
    _tableRow("DÉCOLLAGE", "Puissance maximale. Turbulences rares mais ressenties.", Colors.greenAccent),
    _tableRow("CROISIÈRE", "Air fluide. Présence de Jet Streams ou convection.", Colors.blueAccent),
    _tableRow("ATTERRISSAGE", "Passage des couches d'air. Secousses légères possibles.", Colors.redAccent),
  ]);

  Widget _buildWeatherImpactTable() {
    return _buildCustomTable([
      _tableRow("SOLEIL", "Peut créer des turbulences thermiques (air chaud qui monte). Ciel clair mais petits rebonds possibles.", Colors.yellowAccent),
      _tableRow("NEIGE", "Aucun impact sur la turbulence en vol.", Colors.white),
      _tableRow("BROUILLARD", "Zéro turbulence. L'air est parfaitement calme.", Colors.grey),
      _tableRow("ORAGE", "Zone à éviter. Les pilotes utilisent le radar météo.", Colors.deepPurpleAccent),
      _tableRow("PLUIE", "Généralement très calme. La pluie 'lisse' l'air.", Colors.lightBlueAccent),
      _tableRow("TEMPÊTE", "Vents forts au sol. En altitude, peut créer du vent arrière.", Colors.redAccent),
    ]);
  }

  Widget _buildCustomTable(List<Widget> rows) => Container(
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
    child: Column(children: rows),
  );

  Widget _tableRow(String label, String desc, Color col) => Padding(
    padding: const EdgeInsets.all(12.0),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 90, child: Text(label, style: TextStyle(color: col, fontWeight: FontWeight.w900, fontSize: 9))),
      Expanded(child: Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 9, height: 1.4))),
    ]),
  );

  Widget _sectionLabel(String text, Color col) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(text, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    Divider(color: col.withOpacity(0.2), thickness: 0.5),
    const SizedBox(height: 10),
  ]);

  Widget _buildGlobalDashboard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: _globalTotalStats.entries.map((e) {
      Color c = e.key.contains("CALME") ? Colors.greenAccent : (e.key.contains("MODÉRÉ") ? Colors.orangeAccent : Colors.redAccent);
      return Column(children: [
        Text(e.value.toString(), style: TextStyle(color: c, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(e.key.split(" ")[1], style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
      ]);
    }).toList()),
  );

  Widget _buildDangerVerdict() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.greenAccent.withOpacity(0.2))),
    child: const Text("NON, ELLES NE SONT PAS DANGEREUSES. Les turbulences sont un phénomène de confort. Un avion ne peut pas être retourné ou cassé par une turbulence. Restez simplement attaché.", style: TextStyle(color: Colors.white, fontSize: 10, height: 1.5, fontWeight: FontWeight.w500)),
  );

  Widget _buildSpeedAltitudeSection() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.redAccent.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("PROCÉDURE DE STABILISATION : 275 KM/H", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
      const SizedBox(height: 8),
      const Text("En zone 'Pire', la vitesse est réduite à 275 km/h. Les pilotes changent d'altitude pour chercher un air plus stable.", style: TextStyle(color: Colors.white70, fontSize: 10, height: 1.5)),
    ]),
  );

  Widget _buildYearSection(String year, Map<String, List<dynamic>> months, int index) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(year, style: TextStyle(color: _yearColors[index % _yearColors.length], fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      ...months.entries.map((m) => _buildMonthSection(m.key, m.value)).toList(),
      const SizedBox(height: 20),
    ]);
  }

  Widget _buildMonthSection(String month, List<dynamic> flights) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text(month, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600))),
      ...flights.map((f) => _buildFlightCard(f)).toList(),
    ]);
  }

  Widget _buildFlightCard(dynamic f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        _segmentRow("ALLER", f['compA'], f['avionA'], f['turbAller']),
        if (f['listEscA'] != null) ...f['listEscA'].where((e) => _isValid(e['comp'])).map((e) =>
            _segmentRow("ESC. ALLER", e['comp'], e['avion'], e['turb'])).toList(),
        if (_isValid(f['compR'])) const Divider(height: 20, color: Colors.white10),
        if (_isValid(f['compR'])) _segmentRow("RETOUR", f['compR'], f['avionR'], f['turbRetour']),
        if (f['listEscR'] != null) ...f['listEscR'].where((e) => _isValid(e['comp'])).map((e) =>
            _segmentRow("ESC. RETOUR", e['comp'], e['avion'], e['turb'])).toList(),
      ]),
    );
  }

  Widget _segmentRow(String type, dynamic comp, dynamic avion, dynamic turb) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(children: [
        SizedBox(width: 70, child: Text(type, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold))),
        Expanded(child: Text("${comp ?? ''} | ${avion ?? ''}".toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
        Text(_getEmoji(turb), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}