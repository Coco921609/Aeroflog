import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class TropheesPage extends StatefulWidget {
  final int villesVisitees;
  final int escales;
  final int avions;
  final int moisActifs;

  const TropheesPage({
    super.key,
    required this.villesVisitees,
    required this.escales,
    required this.avions,
    required this.moisActifs,
  });

  @override
  State<TropheesPage> createState() => _TropheesPageState();
}

class _TropheesPageState extends State<TropheesPage> {
  // --- VARIABLES DE CALCUL ---
  int _totalVols = 0;
  int _airbus = 0; int _boeing = 0; int _embraer = 0; int _autresConst = 0;
  int _matin = 0; int _midi = 0; int _aprem = 0; int _soir = 0; int _nuit = 0;
  int _star = 0; int _sky = 0; int _one = 0; int _low = 0; int _majeur = 0;
  int _favs = 0; int _turb = 0; int _notesCount = 0;
  int _topCompagnies = 0;
  int _totalAnnees = 0;

  // --- SYSTÈME DE COULEURS DYNAMIQUE ---
  final List<List<Color>> _allPalettes = [
    [const Color(0xFFD4AF37), const Color(0xFF8E6E26)], // Or
    [const Color(0xFFA30685), const Color(0xFF870144)], // Rose/Prune
    [const Color(0xFF450161), const Color(0xFF870144)], // Violet
    [const Color(0xFF450161), const Color(0xFF132A13)], // Sombre/Vert
    [const Color(0xFF6A0D91), const Color(0xFF310E44)], // Deep Purple
  ];
  int _paletteIndex = 0;
  Timer? _colorTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Changement de couleur toutes les 10 secondes
    _colorTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _paletteIndex = (_paletteIndex + 1) % _allPalettes.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _colorTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('vols_data');
    if (data == null) return;

    try {
      List<dynamic> years = jsonDecode(data);
      _totalAnnees = years.length;
      Map<String, List<double>> notesMap = {};

      int v = 0, air = 0, boe = 0, emb = 0, aut = 0;
      int ma = 0, mi = 0, ap = 0, so = 0, nu = 0;
      int sA = 0, sT = 0, oW = 0, lC = 0, mJ = 0;
      int fv = 0, tb = 0, nt = 0;

      for (var y in years) {
        List flights = y["flights"] ?? [];
        for (var f in flights) {
          List<String> segs = f['dateR'] != null && f['dateR'] != "" ? ['A', 'R'] : ['A'];
          for (var s in segs) {
            v++;
            String mom = f['moment$s'] ?? "";
            if (mom == "Matin") ma++; else if (mom == "Midi") mi++; else if (mom == "Après-midi") ap++; else if (mom == "Soirée") so++; else if (mom == "Minuit") nu++;

            String av = (f['avion$s'] ?? "").toString().toUpperCase();
            if (av.contains("AIRBUS")) air++; else if (av.contains("BOEING")) boe++; else if (av.contains("EMBRAER")) emb++; else aut++;

            String al = f['all$s'] ?? "";
            if (al == "Star Alliance") sA++; else if (al == "SkyTeam") sT++; else if (al == "Oneworld") oW++; else if (al == "Low Cost") lC++; else mJ++;

            if (f['fav$s'] == true) fv++;
            String t = (f['turb$s'] ?? "").toString().toLowerCase();
            if (t.contains("moyen") || t.contains("pire")) tb++;

            if (f['repas$s'] != null) {
              nt++;
              double m = ((f['repas$s']??3).toDouble() + (f['service$s']??3).toDouble() + (f['retard$s']??3).toDouble()) / 3;
              notesMap.putIfAbsent(f['comp$s']??'?', () => []).add(m);
            }
          }
        }
      }

      int topC = 0;
      notesMap.forEach((k, list) {
        if ((list.reduce((a, b) => a + b) / list.length) >= 4.0) topC++;
      });

      setState(() {
        _totalVols = v; _airbus = air; _boeing = boe; _embraer = emb; _autresConst = aut;
        _matin = ma; _midi = mi; _aprem = ap; _soir = so; _nuit = nu;
        _star = sA; _sky = sT; _one = oW; _low = lC; _majeur = mJ;
        _favs = fv; _turb = tb; _notesCount = nt; _topCompagnies = topC;
      });
    } catch (e) { debugPrint(e.toString()); }
  }

  // --- CALCUL PRÉCIS DES 60 BADGES ---
  int _countTotalBadges() {
    int c = 0;
    // 1. Horaires (10)
    if (_matin >= 5) c++; if (_matin >= 15) c++;
    if (_midi >= 5) c++; if (_midi >= 15) c++;
    if (_aprem >= 5) c++; if (_aprem >= 15) c++;
    if (_soir >= 5) c++; if (_soir >= 15) c++;
    if (_nuit >= 5) c++; if (_nuit >= 15) c++;
    // 2. Expérience (10)
    if (_totalVols >= 1) c++; if (_totalVols >= 25) c++; if (_totalVols >= 50) c++; if (_totalVols >= 100) c++;
    if (widget.escales >= 5) c++; if (widget.escales >= 15) c++; if (widget.escales >= 30) c++;
    if (widget.villesVisitees >= 10) c++; if (widget.villesVisitees >= 25) c++; if (widget.villesVisitees >= 50) c++;
    // 3. Flotte (10)
    if (_airbus >= 5) c++; if (_airbus >= 20) c++;
    if (_boeing >= 5) c++; if (_boeing >= 20) c++;
    if (_embraer >= 5) c++; if (_embraer >= 15) c++;
    if (_autresConst >= 5) c++;
    if (widget.avions >= 3) c++; if (widget.avions >= 7) c++; if (widget.avions >= 12) c++;
    // 4. Alliances (10)
    if (_star >= 5) c++; if (_star >= 15) c++;
    if (_sky >= 5) c++; if (_sky >= 15) c++;
    if (_one >= 5) c++; if (_one >= 15) c++;
    if (_low >= 5) c++; if (_low >= 20) c++;
    if (_majeur >= 5) c++;
    if (_star > 0 && _sky > 0 && _one > 0) c++; // Diplomate
    // 5. Qualité (10)
    if (_topCompagnies >= 1) c++; if (_topCompagnies >= 3) c++; if (_topCompagnies >= 5) c++; if (_topCompagnies >= 10) c++; if (_topCompagnies >= 15) c++;
    if (_notesCount >= 20) c++; if (_notesCount >= 40) c++; // Gourmet & Ponctuel
    if (_totalVols >= 10) c++; if (_totalVols >= 25) c++; if (_totalVols >= 50) c++; // Testeur/Expert/Juge
    // 6. Carnet (10)
    if (_favs >= 1) c++; if (_favs >= 10) c++; if (_favs >= 25) c++; if (_favs >= 50) c++;
    if (_turb >= 5) c++; if (_turb >= 15) c++; if (_turb >= 30) c++;
    if (_totalAnnees >= 2) c++; if (_totalAnnees >= 5) c++; if (_totalAnnees >= 10) c++;

    return c.clamp(0, 60);
  }

  String _getGradeLabel(int b) {
    if (b < 5) return "DÉBUTANT";
    if (b < 10) return "RECRUE";
    if (b < 15) return "NAVIGANT";
    if (b < 25) return "AVIATEUR";
    if (b < 35) return "OFFICIER";
    if (b < 45) return "COMMANDANT";
    if (b < 55) return "AMBASSADEUR";
    return "EMPEREUR DES AIRS";
  }

  void _showGradesInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        title: Text("PALIERS DE RANG", style: TextStyle(color: _allPalettes[_paletteIndex][0], fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _gradeLine(5, "RECRUE"),
            _gradeLine(10, "NAVIGANT"),
            _gradeLine(15, "AVIATEUR"),
            _gradeLine(25, "OFFICIER"),
            _gradeLine(35, "COMMANDANT"),
            _gradeLine(45, "AMBASSADEUR"),
            _gradeLine(55, "EMPEREUR"),
          ],
        ),
      ),
    );
  }

  Widget _gradeLine(int req, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$req Badges", style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text(label, style: TextStyle(color: _allPalettes[_paletteIndex][0], fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int badges = _countTotalBadges();
    Color mainColor = _allPalettes[_paletteIndex][0];

    return Scaffold(
      backgroundColor: const Color(0xFF06090E),
      appBar: AppBar(
        title: Text("SALON DES TROPHEES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: mainColor, letterSpacing: 2)),
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        actions: [IconButton(icon: Icon(Icons.info_outline, color: mainColor), onPressed: _showGradesInfo)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(badges, mainColor),
            const SizedBox(height: 25),
            _buildSection("1. RYTHME CIRCADIEN", Icons.timer, Colors.orangeAccent, [
              _badge("Aube I", "5 Matin", _matin, 5), _badge("Aube II", "15 Matin", _matin, 15),
              _badge("Zénith I", "5 Midi", _midi, 5), _badge("Zénith II", "15 Midi", _midi, 15),
              _badge("Sieste I", "5 Apr-M", _aprem, 5), _badge("Sieste II", "15 Apr-M", _aprem, 15),
              _badge("Crépus. I", "5 Soir", _soir, 5), _badge("Crépus. II", "15 Soir", _soir, 15),
              _badge("Minuit I", "5 Nuit", _nuit, 5), _badge("Night Owl", "15 Nuit", _nuit, 15),
            ], mainColor),
            _buildSection("2. EXPERIENCE & ESCALES", Icons.flight_takeoff, Colors.greenAccent, [
              _badge("Décollage", "1er Vol", _totalVols, 1), _badge("Grand Voy.", "25 Vols", _totalVols, 25),
              _badge("Vétéran", "50 Vols", _totalVols, 50), _badge("Légende", "100 Vols", _totalVols, 100),
              _badge("Transit I", "5 Escal.", widget.escales, 5), _badge("Transit II", "15 Escal.", widget.escales, 15),
              _badge("Hub Master", "30 Escal.", widget.escales, 30), _badge("Globe-Tr.", "10 Villes", widget.villesVisitees, 10),
              _badge("Explo.", "25 Villes", widget.villesVisitees, 25), _badge("Conquérant", "50 Villes", widget.villesVisitees, 50),
            ], mainColor),
            _buildSection("3. FLOTTE & CONSTRUCTEURS", Icons.precision_manufacturing, Colors.blueAccent, [
              _badge("Airbus I", "5 Vols", _airbus, 5), _badge("Airbus II", "20 Vols", _airbus, 20),
              _badge("Boeing I", "5 Vols", _boeing, 5), _badge("Boeing II", "20 Vols", _boeing, 20),
              _badge("Embraer I", "5 Vols", _embraer, 5), _badge("Embraer II", "15 Vols", _embraer, 15),
              _badge("Régional", "5 Autres", _autresConst, 5), _badge("Curieux", "3 Modèles", widget.avions, 3),
              _badge("Collect.", "7 Modèles", widget.avions, 7), _badge("Ingénieur", "12 Modèles", widget.avions, 12),
            ], mainColor),
            _buildSection("4. ALLIANCES & RÉSEAUX", Icons.public, Colors.purpleAccent, [
              _badge("Star I", "5 Vols", _star, 5), _badge("Star II", "15 Vols", _star, 15),
              _badge("Sky I", "5 Vols", _sky, 5), _badge("Sky II", "15 Vols", _sky, 15),
              _badge("One I", "5 Vols", _one, 5), _badge("One II", "15 Vols", _one, 15),
              _badge("Eco I", "5 LowC.", _low, 5), _badge("Eco II", "20 LowC.", _low, 20),
              _badge("Majeur", "5 Vols", _majeur, 5), _badge("Diplomate", "3 Alliances", (_star>0?1:0)+(_sky>0?1:0)+(_one>0?1:0), 3),
            ], mainColor),
            _buildSection("5. QUALITÉ & AVIS", Icons.star, Colors.pinkAccent, [
              _badge("1ère Imp.", "1 Comp >4", _topCompagnies, 1), _badge("Satisfait", "3 Comp >4", _topCompagnies, 3),
              _badge("Fidèle", "5 Comp >4", _topCompagnies, 5), _badge("Elite", "10 Comp >4", _topCompagnies, 10),
              _badge("Ambass.", "15 Comp >4", _topCompagnies, 15), _badge("Gourmet", "20 Repas", _notesCount, 20),
              _badge("Ponctuel", "40 Repas", _notesCount, 40), _badge("Testeur", "10 Vols", _totalVols, 10),
              _badge("Expert", "25 Vols", _totalVols, 25), _badge("Juge", "50 Vols", _totalVols, 50),
            ], mainColor),
            _buildSection("6. CARNET & TURBULENCES", Icons.auto_stories, Colors.cyanAccent, [
              _badge("Favori", "1er Fav", _favs, 1), _badge("Passionné", "10 Favs", _favs, 10),
              _badge("Fanatique", "25 Favs", _favs, 25), _badge("Accro", "50 Favs", _favs, 50),
              _badge("Secousse", "5 Turb.", _turb, 5), _badge("Survivant", "15 Turb.", _turb, 15),
              _badge("Invuln.", "30 Turb.", _turb, 30), _badge("Sénior", "2 Ans", _totalAnnees, 2),
              _badge("Doyen", "5 Ans", _totalAnnees, 5), _badge("Légende V.", "10 Ans", _totalAnnees, 10),
            ], mainColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int badges, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF12161D), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Row(children: [
          Icon(Icons.workspace_premium, color: color, size: 40),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_getGradeLabel(badges), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text("$badges / 60 BADGES", style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ]),
        ]),
        const SizedBox(height: 15),
        LinearProgressIndicator(value: (badges / 60).toDouble(), minHeight: 6, backgroundColor: Colors.white10, color: color),
      ]),
    );
  }

  Widget _buildSection(String t, IconData i, Color c, List<Widget> items, Color mainColor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [Icon(i, color: c, size: 16), const SizedBox(width: 8), Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))])),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.1, children: items),
      const SizedBox(height: 20),
    ]);
  }

  Widget _badge(String n, String d, int cur, int tar) {
    bool ok = cur >= tar && tar > 0;
    Color color = ok ? _allPalettes[_paletteIndex][0] : Colors.white10;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: ok ? color.withOpacity(0.05) : const Color(0xFF12161D), borderRadius: BorderRadius.circular(10), border: Border.all(color: ok ? color : Colors.white.withOpacity(0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(n.toUpperCase(), style: TextStyle(color: ok ? Colors.white : Colors.white38, fontSize: 8, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis)),
          Icon(ok ? Icons.verified : Icons.lock_outline, color: ok ? color : Colors.white10, size: 10),
        ]),
        Text(d, style: const TextStyle(color: Colors.white24, fontSize: 7)),
        const Spacer(),
        LinearProgressIndicator(value: (tar > 0 ? cur / tar : 0).clamp(0.0, 1.0).toDouble(), minHeight: 2, backgroundColor: Colors.white10, color: color),
      ]),
    );
  }
}