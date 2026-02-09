import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<dynamic> _years = [];
  String _selectedFilter = "TOUT";
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadState();
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) => _loadState());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    String? dataVols = prefs.getString('vols_data');
    if (mounted && dataVols != null) {
      setState(() { _years = jsonDecode(dataVols); });
    }
  }

  Color _getThemeColor(String year) {
    if (year == "TOUT") return Colors.white;
    int y = int.tryParse(year) ?? 0;
    switch (y % 5) {
      case 0: return Colors.cyanAccent;
      case 1: return Colors.amberAccent;
      case 2: return Colors.greenAccent;
      case 3: return Colors.purpleAccent;
      case 4: return Colors.orangeAccent;
      default: return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_years.isEmpty) return const Center(child: Text("AUCUNE DONNÉE", style: TextStyle(color: Colors.white)));

    bool isTotal = _selectedFilter == "TOUT";
    Color themeColor = _getThemeColor(_selectedFilter);

    Map<String, int> aircraftStats = {"AIRBUS": 0, "BOEING": 0, "EMBRAER": 0, "AUTRES": 0};
    Map<String, int> allianceStats = {"Star Alliance": 0, "SkyTeam": 0, "Oneworld": 0, "Low Cost": 0, "Autres Majeurs": 0, "Autres": 0};
    Map<String, int> favStats = {};
    Map<int, int> flowData = {};
    Map<String, List<double>> noteGlobale = {};

    for (var y in _years) {
      String currentYear = y['year'].toString();
      if (isTotal || currentYear == _selectedFilter) {
        List flights = y['flights'] ?? [];
        for (var f in flights) {
          // 1. VOL PRINCIPAL ALLER
          _processSegment(f['compA'], f['avionA'], f['favA'], f['allA'], f['dateA'], f['repasA'], f['serviceA'], f['retardA'], aircraftStats, favStats, allianceStats, flowData, noteGlobale);

          // 2. ESCALES ALLER (Comptabilisées individuellement)
          if (f['hasEscA'] == true && f['listEscA'] != null) {
            for (var esc in f['listEscA']) {
              _processSegment(esc['comp'], esc['avion'], false, esc['all'], f['dateA'], esc['repas'], esc['service'], esc['retard'], aircraftStats, favStats, allianceStats, flowData, noteGlobale);
            }
          }

          // 3. VOL PRINCIPAL RETOUR
          if (f['dateR'] != null && f['dateR'] != "") {
            _processSegment(f['compR'], f['avionR'], f['favR'], f['allR'], f['dateR'], f['repasR'], f['serviceR'], f['retardR'], aircraftStats, favStats, allianceStats, flowData, noteGlobale);

            // 4. ESCALES RETOUR (Comptabilisées individuellement)
            if (f['hasEscR'] == true && f['listEscR'] != null) {
              for (var esc in f['listEscR']) {
                _processSegment(esc['comp'], esc['avion'], false, esc['all'], f['dateR'], esc['repas'], esc['service'], esc['retard'], aircraftStats, favStats, allianceStats, flowData, noteGlobale);
              }
            }
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            _buildYearSelector(themeColor, isTotal),
            const SizedBox(height: 25),
            _sectionTitle("FLOTTE & CONSTRUCTEURS (INCL. ESCALES)", isTotal ? Colors.blueAccent : themeColor),
            _buildAircraftStats(aircraftStats, themeColor, isTotal),
            const SizedBox(height: 25),
            _sectionTitle("FAVORIS & COUPS DE COEUR", isTotal ? Colors.pinkAccent : themeColor),
            _buildFavRanking(favStats, themeColor, isTotal),
            const SizedBox(height: 25),
            _sectionTitle("AVIS & NOTES GLOBALES DES COMPAGNIES", isTotal ? Colors.cyanAccent : themeColor),
            _buildNoteRanking(noteGlobale, themeColor, isTotal),
            const SizedBox(height: 25),
            _sectionTitle("ALLIANCES & RÉSEAUX", isTotal ? Colors.orangeAccent : themeColor),
            _buildAllianceStats(allianceStats, themeColor, isTotal),
            const SizedBox(height: 25),
            _sectionTitle("FLUX MENSUEL DES SEGMENTS", isTotal ? Colors.greenAccent : themeColor),
            _buildMonthChart(flowData, themeColor, isTotal),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _processSegment(dynamic comp, dynamic avion, dynamic isFav, dynamic alliance, dynamic dateStr, dynamic repas, dynamic service, dynamic retard, Map<String, int> aircraft, Map<String, int> fav, Map<String, int> all, Map<int, int> flow, Map<String, List<double>> notes) {
    if (comp == null) return;
    String name = comp.toString().toUpperCase().trim();
    if (name.isEmpty || name == "AUCUNE") return;

    // 1. Types d'Avions (Incrémentation pour chaque segment d'escale aussi)
    String model = (avion ?? "").toString().toUpperCase();
    if (model.contains("AIRBUS")) {
      aircraft["AIRBUS"] = (aircraft["AIRBUS"] ?? 0) + 1;
    } else if (model.contains("BOEING")) {
      aircraft["BOEING"] = (aircraft["BOEING"] ?? 0) + 1;
    } else if (model.contains("EMBRAER")) {
      aircraft["EMBRAER"] = (aircraft["EMBRAER"] ?? 0) + 1;
    } else if (model.isNotEmpty) {
      aircraft["AUTRES"] = (aircraft["AUTRES"] ?? 0) + 1;
    }

    // 2. Favoris
    if (isFav == true) fav[name] = (fav[name] ?? 0) + 1;

    // 3. Alliances
    if (alliance != null && alliance.toString().isNotEmpty) {
      all[alliance.toString()] = (all[alliance.toString()] ?? 0) + 1;
    }

    // 4. Flux Mensuel (Chaque escale compte comme un mouvement dans le mois)
    if (dateStr != null && dateStr.toString().isNotEmpty) {
      try {
        DateTime dt = DateTime.parse(dateStr.toString());
        flow[dt.month] = (flow[dt.month] ?? 0) + 1;
      } catch (_) {}
    }

    // 5. Notes Globales (Moyenne calculée sur chaque segment)
    double r = (double.tryParse(repas.toString()) ?? 3.0);
    double s = (double.tryParse(service.toString()) ?? 3.0);
    double rt = (double.tryParse(retard.toString()) ?? 3.0);
    double avg = (r + s + rt) / 3.0;
    notes.putIfAbsent(name, () => []).add(avg);
  }

  // --- UI COMPONENTS ---

  Widget _buildYearSelector(Color color, bool isTotal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
          gradient: isTotal ? const LinearGradient(colors: [Colors.blue, Colors.purple, Colors.red]) : null,
          color: isTotal ? null : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 2)
      ),
      child: DropdownButton<String>(
        value: _selectedFilter,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF1A1F26),
        items: [
          const DropdownMenuItem(value: "TOUT", child: Text("TOTAL GLOBAL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
          ..._years.map((y) => DropdownMenuItem(value: y['year'].toString(), child: Text("SESSION ${y['year']}", style: TextStyle(fontSize: 12, color: _getThemeColor(y['year'].toString()))))),
        ],
        onChanged: (v) => setState(() => _selectedFilter = v!),
      ),
    );
  }

  Widget _buildAircraftStats(Map<String, int> stats, Color color, bool isTotal) {
    int total = stats.values.fold(0, (a, b) => a + b);
    return Column(children: stats.entries.where((e) => e.value > 0).map((e) {
      double p = total > 0 ? e.value / total : 0;
      return _buildLiteralBar(e.key, "${e.value} Segments", p, isTotal ? Colors.blueAccent : color, isTotal);
    }).toList());
  }

  Widget _buildFavRanking(Map<String, int> favs, Color color, bool isTotal) {
    var sorted = favs.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    int total = favs.values.fold(0, (a, b) => a + b);
    return Column(children: sorted.take(5).map((e) {
      double p = total > 0 ? e.value / total : 0;
      return _buildLiteralBar(e.key, "${e.value} ❤", p, isTotal ? Colors.pinkAccent : color, isTotal);
    }).toList());
  }

  Widget _buildNoteRanking(Map<String, List<double>> notes, Color color, bool isTotal) {
    var sorted = notes.entries.toList()..sort((a, b) => (b.value.reduce((a, b) => a + b) / b.value.length).compareTo(a.value.reduce((a, b) => a + b) / a.value.length));
    return Column(children: sorted.take(3).map((e) {
      double avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return _buildLiteralBar(e.key, "${avg.toStringAsFixed(1)}/5", avg / 5.0, isTotal ? Colors.cyanAccent : color, isTotal);
    }).toList());
  }

  Widget _buildAllianceStats(Map<String, int> stats, Color color, bool isTotal) {
    int total = stats.values.fold(0, (a, b) => a + b);
    return Column(children: stats.entries.where((e) => e.value > 0).map((e) {
      double p = total > 0 ? e.value / total : 0;
      return _buildLiteralBar(e.key, "${(p * 100).round()}%", p, isTotal ? Colors.orangeAccent : color, isTotal);
    }).toList());
  }

  Widget _buildLiteralBar(String label, String value, double progress, Color color, bool isTotal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              color: color.withOpacity(isTotal ? 0.8 : 0.6),
              backgroundColor: Colors.white10,
              minHeight: 32,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthChart(Map<int, int> months, Color color, bool isTotal) {
    return Container(
      height: 140, padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(12, (i) {
        int count = months[i + 1] ?? 0;
        Color barColor = isTotal ? Colors.primaries[i % Colors.primaries.length] : color;
        return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text("$count", style: TextStyle(fontSize: 7, color: barColor)),
          const SizedBox(height: 5),
          Container(width: 10, height: (count * 5.0).clamp(2, 70),
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [barColor, barColor.withOpacity(0.3)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(2)
              )
          ),
          const SizedBox(height: 5),
          Text("${i + 1}", style: const TextStyle(fontSize: 7, color: Colors.white38)),
        ]));
      })),
    );
  }

  Widget _sectionTitle(String t, Color c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: Row(children: [
      Container(width: 4, height: 16, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white)),
    ]),
  );
}