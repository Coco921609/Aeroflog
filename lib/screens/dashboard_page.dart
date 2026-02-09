import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'favoris_page.dart';
import 'turbulence_page.dart' as turb;
import 'bloc_notes_page.dart';
import 'modeles_avion_page.dart';
import 'ai_chat_page.dart'; // <--- AJOUT IA

class DashboardPage extends StatefulWidget {
  final Function(int) onNavigate;
  final int vols;
  final int km;
  final int badges;
  final int totalPossibleBadges;
  final int trophees;
  final List<String> favs;
  final List<String> worsts;

  const DashboardPage({
    super.key,
    required this.onNavigate,
    required this.vols,
    required this.km,
    required this.badges,
    required this.totalPossibleBadges,
    required this.trophees,
    required this.favs,
    required this.worsts,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _weatherAnimController;
  late AnimationController _writingController;
  Timer? _slowTimer;
  Timer? _yearCycleTimer;
  Timer? _watcherTimer;
  Timer? _weatherCycleTimer;

  String _name = "";
  int _cycleIndex = 0;
  int _yearIndex = 0;
  int _weatherStateIndex = 0;

  Map<String, List<String>> _yearlyFavs = {};
  Map<String, List<String>> _yearlyGoods = {};
  Map<String, List<String>> _yearlyWorsts = {};

  int _totalFavsCount = 0;
  int _totalGoodsCount = 0;
  int _totalWorstsCount = 0;

  List<String> _availableYears = [];

  final List<String> _phrases = [
    "Consultez votre carnet de vol numérique.",
    "Prêt à décoller à nouveau ?",
    "Nouveau vol validé ! Bravo !",
    "Le ciel n'est pas la limite.",
    "Suivez vos exploits en direct."
  ];

  final List<List<Color>> _allPalettes = [
    [const Color(0xFFD4AF37), const Color(0xFF8E6E26)],
    [const Color(0xFFA30685), const Color(0xFF870144)],
    [const Color(0xFF450161), const Color(0xFF870144)],
    [const Color(0xFF450161), const Color(0xFF132A13)],
    [const Color(0xFF6A0D91), const Color(0xFF310E44)],
  ];

  int airbusCount = 0;
  int boeingCount = 0;
  int embraerCount = 0;
  int autreCount = 0;
  int totalSommeModeles = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _weatherAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _writingController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);

    _slowTimer = Timer.periodic(const Duration(seconds: 10), (timer) { if (mounted) setState(() => _cycleIndex++); });
    _yearCycleTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted && _availableYears.isNotEmpty) { setState(() { _yearIndex = (_yearIndex + 1) % _availableYears.length; }); }
    });

    _weatherCycleTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) setState(() => _weatherStateIndex = (_weatherStateIndex + 1) % 6);
    });

    _initNameAndData();
    _watcherTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) => _loadDataSync());
  }

  bool _isValide(dynamic comp) {
    if (comp == null) return false;
    String c = comp.toString().toLowerCase().trim();
    return c != "" && c != "aucune" && c != "none";
  }

  Future<void> _initNameAndData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _name = prefs.getString('user_name') ?? "Voyageur");
    _loadState();
  }

  Future<void> _loadDataSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    String newName = prefs.getString('user_name') ?? "Voyageur";
    if (_name != newName && mounted) { setState(() => _name = newName); }
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('vols_data');
    if (data == null) return;
    List<dynamic> yearsData = jsonDecode(data);

    int a = 0, b = 0, e = 0, o = 0;
    Map<String, List<String>> tempFavs = {};
    Map<String, List<String>> tempGoods = {};
    Map<String, List<String>> tempWorsts = {};

    Set<String> globalFavs = {};
    Set<String> globalGoods = {};
    Set<String> globalWorsts = {};

    for (var y in yearsData) {
      String yearStr = y["year"].toString();
      Map<String, List<double>> yearRatings = {};

      for (var f in y["flights"] ?? []) {
        void processSeg(String comp, String model, dynamic r, dynamic s, dynamic ret, {bool forceFav = false}) {
          if (!_isValide(comp)) return;
          String m = model.toLowerCase();
          if (m.contains("airbus")) a++;
          else if (m.contains("boeing")) b++;
          else if (m.contains("embraer")) e++;
          else o++;

          double moy;
          if (forceFav) {
            moy = 5.0;
          } else {
            moy = ((double.tryParse(r.toString()) ?? 3.0) +
                (double.tryParse(s.toString()) ?? 3.0) +
                (double.tryParse(ret.toString()) ?? 3.0)) / 3;
          }
          yearRatings.putIfAbsent(comp.toUpperCase(), () => []).add(moy);
        }

        processSeg(f['compA'] ?? "", f['avionA'] ?? "", f['nA'] ?? f['repasA'], f['serviceA'], f['retardA'], forceFav: f['favA'] == true);
        if (f['listEscA'] != null && f['listEscA'] is List) {
          for (var esc in f['listEscA']) {
            processSeg(esc['comp'] ?? "", esc['avion'] ?? "", esc['note'] ?? 3.0, 3.0, 3.0, forceFav: esc['fav'] == true);
          }
        }
        processSeg(f['compR'] ?? "", f['avionR'] ?? "", f['nR'] ?? f['repasR'], f['serviceR'], f['retardR'], forceFav: f['favR'] == true);
        if (f['listEscR'] != null && f['listEscR'] is List) {
          for (var esc in f['listEscR']) {
            processSeg(esc['comp'] ?? "", esc['avion'] ?? "", esc['note'] ?? 3.0, 3.0, 3.0, forceFav: esc['fav'] == true);
          }
        }
      }

      List<String> yF = []; List<String> yG = []; List<String> yW = [];
      yearRatings.forEach((comp, notes) {
        double avg = notes.reduce((val1, val2) => val1 + val2) / notes.length;
        if (avg >= 3.5) {
          yF.add(comp);
          globalFavs.add(comp);
        } else if (avg >= 3.0 && avg < 3.5) {
          yG.add(comp);
          globalGoods.add(comp);
        } else if (avg >= 0.5 && avg < 3.0) {
          yW.add(comp);
          globalWorsts.add(comp);
        }
      });
      tempFavs[yearStr] = yF; tempGoods[yearStr] = yG; tempWorsts[yearStr] = yW;
    }

    if (mounted) {
      setState(() {
        airbusCount = a; boeingCount = b; embraerCount = e; autreCount = o;
        totalSommeModeles = a + b + e + o;
        _yearlyFavs = tempFavs; _yearlyGoods = tempGoods; _yearlyWorsts = tempWorsts;
        _totalFavsCount = globalFavs.length;
        _totalGoodsCount = globalGoods.length;
        _totalWorstsCount = globalWorsts.length;
        _availableYears = tempFavs.keys.toList()..sort((a, b) => b.compareTo(a));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int colorIdx = _cycleIndex % _allPalettes.length;
    Color globalColor = _allPalettes[colorIdx][0];
    String currentYear = _availableYears.isNotEmpty ? _availableYears[_yearIndex] : "---";

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(globalColor),
            const SizedBox(height: 20),
            _buildRotatingContainer(
              colorIdx: colorIdx,
              child: Container(width: double.infinity, height: 50, alignment: Alignment.center, child: Text(_phrases[_cycleIndex % _phrases.length], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
            ),
            const SizedBox(height: 40),

            Row(
              children: [
                Expanded(child: _buildEngineCard(1, Icons.flight_takeoff_rounded, "VOLS", "Historique complet incluant escales.", colorIdx)),
                Expanded(child: _buildEngineCard(2, Icons.insights_rounded, "STATS", "Analyse globale flotte et segments.", colorIdx)),
              ],
            ),
            const SizedBox(height: 35),

            Row(
              children: [
                Expanded(child: _buildEngineCard(3, Icons.verified_rounded, "BADGES", "Niveaux de fidélité débloqués.", colorIdx)),
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlocNotePage())),
                  child: Column(children: [
                    SizedBox(height: 60, child: Center(child: _buildNotebookWidget())),
                    const SizedBox(height: 8),
                    const Text("CARNET", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                    const Text("Journal personnel de bord.", textAlign: TextAlign.center, style: TextStyle(fontSize: 7.5, color: Colors.white38, fontWeight: FontWeight.bold))
                  ]),
                )),
                Expanded(child: _buildEngineCard(4, Icons.emoji_events_rounded, "TROPHÉES", "Vitrine de vos exploits rares.", colorIdx)),
              ],
            ),
            const SizedBox(height: 35),

            Row(
              children: [
                Expanded(child: _buildModelesCard(colorIdx)),
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const turb.TurbulencePage())),
                  child: Column(children: [
                    SizedBox(height: 60, child: Center(child: _buildWeatherWidget())),
                    const SizedBox(height: 8),
                    const Text("METEO", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                    const Text("Zones de turbulences et ciel.", textAlign: TextAlign.center, style: TextStyle(fontSize: 7.5, color: Colors.white38, fontWeight: FontWeight.bold))
                  ]),
                )),
                // --- AJOUT BOUTON IA ICI POUR ÉQUILIBRER LA LIGNE ---
                Expanded(child: _buildEngineCard(8, Icons.auto_awesome, "IA CHAT", "Votre assistant intelligent.", colorIdx)),
              ],
            ),

            const SizedBox(height: 45),
            Text("ANALYSE DÉTAILLÉE DE LA FLOTTE (ALLER/RETOUR/ESCALES)", style: TextStyle(letterSpacing: 2.0, fontSize: 10, color: globalColor, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            const Text("Répartition incluant les segments d'escales et vols principaux.", style: TextStyle(fontSize: 8, color: Colors.white24)),
            const SizedBox(height: 15),
            _buildRotatingContainer(
                colorIdx: colorIdx,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSimpleStat("Airbus", airbusCount, Colors.white),
                      _buildSimpleStat("Boeing", boeingCount, Colors.white),
                      _buildSimpleStat("Embraer", embraerCount, Colors.white),
                      _buildSimpleStat("Autres", autreCount, Colors.white38),
                      _buildSimpleStat("Total", totalSommeModeles, globalColor)
                    ]
                )
            ),

            const SizedBox(height: 25),
            Text("BILAN GLOBAL TOUTES ANNÉES", style: TextStyle(letterSpacing: 2.0, fontSize: 10, color: globalColor, fontWeight: FontWeight.w900)),
            const SizedBox(height: 15),
            _buildGlobalTable(globalColor),

            const SizedBox(height: 45),
            Text("CLASSEMENT COMPAGNIES $currentYear", style: TextStyle(letterSpacing: 2.0, fontSize: 10, color: globalColor, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            _buildYearlyCard("COMPAGNIES PRÉFÉRÉES (Score ≥ 3.5)", "Service haut de gamme incluant vos escales.", _yearlyFavs[currentYear] ?? [], Icons.star_rounded, globalColor),
            _buildYearlyCard("BONNES COMPAGNIES (3.0 ≤ Score < 3.5)", "Fiabilité constatée sur l'ensemble des segments.", _yearlyGoods[currentYear] ?? [], Icons.thumb_up_rounded, Colors.blueAccent),
            _buildYearlyCard("PIRES EXPÉRIENCES (Score < 3.0)", "Scores faibles ou problèmes relevés.", _yearlyWorsts[currentYear] ?? [], Icons.warning_rounded, Colors.redAccent),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalTable(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1),
          },
          border: TableBorder.symmetric(inside: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
          children: [
            _buildTableRow("CATÉGORIE", "CRITÈRE", "NB", isHeader: true, color: primaryColor),
            _buildTableRow("PRÉFÉRÉES", "Score ≥ 3.5", _totalFavsCount.toString(), color: primaryColor),
            _buildTableRow("BONNES", "3.0 ≤ S < 3.5", _totalGoodsCount.toString(), color: Colors.blueAccent),
            _buildTableRow("PIRES", "Score < 3.0", _totalWorstsCount.toString(), color: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String col1, String col2, String col3, {bool isHeader = false, required Color color}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: Text(col1, style: TextStyle(color: isHeader ? Colors.white54 : color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Text(col2, style: TextStyle(color: isHeader ? Colors.white54 : Colors.white, fontSize: 11)),
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Text(col3, textAlign: TextAlign.center, style: TextStyle(color: isHeader ? Colors.white54 : color, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildHeader(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text("Bienvenue à bord, $_name !", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color, letterSpacing: -0.5))),
        IconButton(icon: const Icon(Icons.favorite_rounded, size: 28, color: Color(0xFFFF2D55)), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FavorisPage()))),
      ],
    );
  }

  Widget _buildEngineCard(int index, IconData icon, String title, String explanation, int colorIdx) {
    Color dynamicColor = _allPalettes[colorIdx][0];
    return GestureDetector(
        onTap: () {
          if (index == 8) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AIChatPage()));
          } else {
            widget.onNavigate(index);
          }
        },
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(alignment: Alignment.center, children: [
            AnimatedBuilder(animation: _rotationController, builder: (context, child) => Transform.rotate(angle: _rotationController.value * 2 * math.pi, child: Container(width: 55, height: 55, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: dynamicColor.withOpacity(0.2)))))),
            Icon(icon, color: dynamicColor, size: 22)
          ]),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(explanation, textAlign: TextAlign.center, style: const TextStyle(fontSize: 7.5, color: Colors.white38, fontWeight: FontWeight.bold)),
          ),
        ])
    );
  }

  Widget _buildModelesCard(int colorIdx) {
    Color dynamicColor = _allPalettes[colorIdx][0];
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ModelesAvionPage())),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 60, child: Center(child: Stack(alignment: Alignment.center, children: [
            Icon(Icons.airplanemode_active_rounded, color: dynamicColor, size: 28),
            AnimatedBuilder(animation: _rotationController, builder: (context, child) => Transform.rotate(angle: -_rotationController.value * 2 * math.pi, child: Icon(Icons.settings_outlined, color: dynamicColor.withOpacity(0.2), size: 45))),
          ]))),
          const SizedBox(height: 8),
          const Text("MODÈLES", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
          const Text("Détails de votre flotte.", textAlign: TextAlign.center, style: TextStyle(fontSize: 7.5, color: Colors.white38, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNotebookWidget() {
    return AnimatedBuilder(
        animation: _writingController,
        builder: (context, child) {
          return Stack(alignment: Alignment.center, children: [
            Container(width: 38, height: 48, decoration: BoxDecoration(color: const Color(0xFFFFF9C4), borderRadius: BorderRadius.circular(3), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))])),
            Transform.translate(offset: Offset(-8 + (_writingController.value * 16), -5 + (_writingController.value * 10)), child: Transform.rotate(angle: -0.5, child: const Icon(Icons.edit, color: Colors.black54, size: 16))),
          ]);
        }
    );
  }

  Widget _buildWeatherWidget() {
    return AnimatedBuilder(animation: _weatherAnimController, builder: (context, child) {
      double t = _weatherAnimController.value;
      double bounce = math.sin(t * math.pi);
      switch (_weatherStateIndex) {
        case 0: return Icon(Icons.wb_sunny_rounded, color: Colors.orangeAccent, size: 28 + (bounce * 4));
        case 1: return Icon(Icons.cloud_rounded, color: Colors.white70, size: 28);
        case 2: return Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_rounded, color: Colors.grey, size: 24), Transform.translate(offset: Offset(0, bounce * 5), child: const Icon(Icons.water_drop, color: Colors.blueAccent, size: 8))]);
        case 3: return Stack(alignment: Alignment.center, children: [const Icon(Icons.cloud_rounded, color: Color(0xFF455A64), size: 28), if (bounce > 0.5) const Icon(Icons.bolt_rounded, color: Colors.yellowAccent, size: 18)]);
        case 4: return Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_rounded, color: Colors.white, size: 24), Transform.rotate(angle: t * 2, child: const Icon(Icons.ac_unit_rounded, color: Colors.lightBlueAccent, size: 8))]);
        case 5: return Opacity(opacity: 0.5 + (bounce * 0.3), child: const Icon(Icons.foggy, color: Colors.white54, size: 28));
        default: return const Icon(Icons.wb_cloudy_rounded, color: Colors.white);
      }
    });
  }

  Widget _buildYearlyCard(String title, String desc, List<String> items, IconData icon, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(15), border: Border.all(color: accentColor.withOpacity(0.15), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 14, color: accentColor), const SizedBox(width: 8), Text(title, style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 5),
          Text(desc, style: const TextStyle(color: Colors.white24, fontSize: 8)),
          const SizedBox(height: 15),
          items.isEmpty
              ? Text("AUCUNE DONNÉE", style: TextStyle(color: Colors.white.withOpacity(0.05), fontSize: 9, letterSpacing: 1.2))
              : Wrap(spacing: 8, runSpacing: 8, children: items.map((comp) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: accentColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: accentColor.withOpacity(0.2))), child: Text(comp, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))).toList()),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, int value, Color color) {
    return Column(children: [Text(value.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)), Text(label.toUpperCase(), style: const TextStyle(fontSize: 8, color: Colors.white24))]);
  }

  Widget _buildRotatingContainer({required Widget child, required int colorIdx}) {
    return AnimatedBuilder(animation: _rotationController, builder: (context, _) {
      return Container(padding: const EdgeInsets.all(1.2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: SweepGradient(transform: GradientRotation(_rotationController.value * 2 * math.pi), colors: _allPalettes[colorIdx])), child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15), decoration: BoxDecoration(color: const Color(0xFF0A0D12), borderRadius: BorderRadius.circular(13.8)), child: child));
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _weatherAnimController.dispose();
    _writingController.dispose();
    _slowTimer?.cancel();
    _yearCycleTimer?.cancel();
    _watcherTimer?.cancel();
    _weatherCycleTimer?.cancel();
    super.dispose();
  }
}