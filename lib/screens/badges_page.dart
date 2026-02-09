import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> with SingleTickerProviderStateMixin {
  Set<String> _flownAirlines = {};
  late AnimationController _rotationController;

  final List<List<Color>> _allPalettes = [
    [const Color(0xFFD4AF37), const Color(0xFF8E6E26)],
    [const Color(0xFFA30685), const Color(0xFF870144)],
    [const Color(0xFF450161), const Color(0xFF870144)],
    [const Color(0xFF450161), const Color(0xFF132A13)],
    [const Color(0xFF6A0D91), const Color(0xFF310E44)],
  ];

  int _paletteIndex = 0;
  Timer? _colorTimer;

  // --- LISTES MISES À JOUR (COMPTES STRICTS) ---
  final Map<String, List<String>> _categories = {
    "STAR ALLIANCE": [
      "AEGEAN", "AIR CANADA", "AIR CHINA", "AIR INDIA", "AIR NEW ZEALAND",
      "ANA", "ASIANA AIRLINES", "AUSTRIAN", "AVIANCA", "BRUSSELS AIRLINES",
      "COPA AIRLINES", "CROATIA AIRLINES", "EGYPTAIR", "ETHIOPIAN AIRLINES",
      "EVA AIR", "LOT POLISH AIRLINES", "LUFTHANSA", "SHENZHEN AIRLINES",
      "SINGAPORE AIRLINES", "SOUTH AFRICAN AIRWAYS", "SWISS", "TAP AIR PORTUGAL",
      "THAI", "TURKISH AIRLINES", "UNITED", "ITA AIRWAYS", "JUNEYAO AIR"
    ], // TOTAL: 27
    "SKYTEAM": [
      "AEROLINEAS ARGENTINAS", "AEROMEXICO", "AIR EUROPA", "AIR FRANCE",
      "CHINA AIRLINES", "CHINA EASTERN", "DELTA", "GARUDA INDONESIA",
      "KENYA AIRWAYS", "KLM", "KOREAN AIR", "MEA", "SAS", "SAUDIA",
      "TAROM", "VIETNAM AIRLINES", "VIRGIN ATLANTIC", "XIAMEN AIR", "AEROFLOT"
    ], // TOTAL: 19
    "ONEWORLD": [
      "ALASKA AIRLINES", "AMERICAN AIRLINES", "BRITISH AIRWAYS", "CATHAY PACIFIC",
      "FIJI AIRWAYS", "FINNAIR", "IBERIA", "JAPAN AIRLINES", "MALAYSIA AIRLINES",
      "OMAN AIR", "QANTAS", "QATAR AIRWAYS", "ROYAL AIR MAROC", "ROYAL JORDANIAN",
      "SRILANKAN AIRLINES"
    ], // TOTAL: 15
    "LOW-COST": [
      "RYANAIR", "EASYJET", "WIZZAIR", "VOLOTEA", "VUELING", "TRANSAVIA",
      "SOUTHWEST", "JET2", "NORWEGIAN", "EUROWINGS", "PEGASUS", "FLYDUBAI",
      "AIRASIA", "INDIGO", "SCOOT", "SPICEJET", "PEACH", "SPRING AIRLINES",
      "FRENCH BEE", "LEVEL", "FLYNAS", "AIR BALTIC", "SMARTWINGS", "SPIRIT AIRLINES",
      "FRONTIER", "ALLEGIANT", "GOL", "AZUL", "JETSTAR", "TUI FLY", "PLAY",
      "NORSE", "ZIPAIR", "VIVA AEROBUS", "VIVA AIR", "VOLARIS", "WESTJET", "JETBLUE"
    ], // TOTAL: 37 (WestJet inclus ici)
    "AUTRES MAJEURS": [
      "EMIRATES", "ETIHAD", "EL AL", "ICELANDAIR", "GULF AIR", "AIR ASTANA",
      "AIR MAURITIUS", "AIR SEYCHELLES", "BANGKOK AIRWAYS", "HAWAIIAN AIRLINES",
      "LATAM", "PHILIPPINE AIRLINES", "VIETJET AIR", "VIRGIN AUSTRALIA",
      "STARLUX", "AIR TRANSAT"
    ], // TOTAL: 16 (WestJet retiré d'ici)
  };

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _loadState();
    _colorTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) setState(() => _paletteIndex = (_paletteIndex + 1) % _allPalettes.length);
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _colorTimer?.cancel();
    super.dispose();
  }

  void _checkAirline(dynamic name, Set<String> activated) {
    if (name == null) return;
    String cleanName = name.toString().toUpperCase().trim();
    if (cleanName.isEmpty || cleanName == "AUCUNE") return;

    for (var list in _categories.values) {
      if (list.contains(cleanName)) {
        activated.add(cleanName);
        break;
      }
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('vols_data');
    Set<String> activatedAirlines = {};

    if (data != null) {
      try {
        List<dynamic> years = jsonDecode(data);
        for (var y in years) {
          if (y["flights"] != null) {
            for (var f in y["flights"]) {
              _checkAirline(f["compA"], activatedAirlines);
              _checkAirline(f["compR"], activatedAirlines);
              if (f["listEscA"] != null) {
                for (var e in f["listEscA"]) _checkAirline(e["comp"], activatedAirlines);
              }
              if (f["listEscR"] != null) {
                for (var e in f["listEscR"]) _checkAirline(e["comp"], activatedAirlines);
              }
            }
          }
        }
      } catch (e) { debugPrint("Erreur: $e"); }
    }
    if (mounted) setState(() => _flownAirlines = activatedAirlines);
  }

  @override
  Widget build(BuildContext context) {
    int totalGlobal = 0;
    _categories.forEach((_, list) => totalGlobal += list.length);
    int allume = _flownAirlines.length;
    double ratio = totalGlobal > 0 ? allume / totalGlobal : 0;
    List<Color> currentColors = _allPalettes[_paletteIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/');
            }
          },
        ),
        title: const Text("TABLEAU DES BADGES",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 30),
                width: 170, height: 170,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RotationTransition(
                      turns: _rotationController,
                      child: AnimatedContainer(
                        duration: const Duration(seconds: 2),
                        width: 155, height: 155,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [currentColors[0].withOpacity(0.1), currentColors[1], currentColors[0].withOpacity(0.1)],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    RotationTransition(
                      turns: _rotationController,
                      child: CustomPaint(size: const Size(145, 145), painter: IndicatorSquarePainter()),
                    ),
                    Container(
                      width: 130, height: 130,
                      decoration: const BoxDecoration(color: Color(0xFF0A0E14), shape: BoxShape.circle),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("$allume / $totalGlobal", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                            const Text("COMPAGNIES", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 145, height: 145,
                      child: CircularProgressIndicator(value: ratio, strokeWidth: 4, backgroundColor: Colors.white.withOpacity(0.05), color: Colors.white.withOpacity(0.3)),
                    ),
                  ],
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                String cat = _categories.keys.elementAt(index);
                return _buildCategory(cat, _categories[cat]!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory(String title, List<String> items) {
    int count = items.where((name) => _flownAirlines.contains(name.toUpperCase().trim())).length;
    int total = items.length;
    double progress = total > 0 ? count / total : 0;
    Color catColor = title.contains("STAR") ? Colors.amber : title.contains("SKYTEAM") ? Colors.blue : title.contains("ONEWORLD") ? Colors.indigoAccent : title.contains("LOW-COST") ? Colors.orange : Colors.cyanAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: catColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: catColor, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2)),
              Text("$count / $total", style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white10, color: catColor, minHeight: 6),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.1),
            itemCount: items.length,
            itemBuilder: (context, idx) {
              String name = items[idx];
              bool active = _flownAirlines.contains(name.toUpperCase().trim());
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? catColor.withOpacity(0.2) : Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: active ? catColor : Colors.white.withOpacity(0.05), width: active ? 2 : 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(name, textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, color: active ? Colors.white : Colors.white24, fontWeight: active ? FontWeight.w900 : FontWeight.normal)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class IndicatorSquarePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Paint paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromCenter(center: Offset(radius, 0), width: 6, height: 6), paint);
  }
  @override bool shouldRepaint(CustomPainter oldDelegate) => false;
}