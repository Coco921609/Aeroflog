import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class BlocNotePage extends StatefulWidget {
  const BlocNotePage({super.key});

  @override
  State<BlocNotePage> createState() => _BlocNotePageState();
}

class _BlocNotePageState extends State<BlocNotePage> {
  List<dynamic> _years = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('vols_data');
    if (data != null) {
      setState(() {
        List<dynamic> decodedData = jsonDecode(data);
        decodedData.sort((a, b) => a['year'].toString().compareTo(b['year'].toString()));
        _years = decodedData;
      });
    }
  }

  Color _getStatusColor(double note) {
    if (note <= 2.2) return const Color(0xFFFF4D4D);
    if (note <= 3.7) return const Color(0xFFFFB347);
    return const Color(0xFF00F2FE);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070A),
      appBar: AppBar(
        title: const Text("LOGBOOK HISTORIQUE",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white70)),
        backgroundColor: const Color(0xFF05070A),
        elevation: 0,
        centerTitle: true,
      ),
      body: _years.isEmpty
          ? const Center(child: Text("AUCUNE DONNÉE", style: TextStyle(color: Colors.white12)))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _years.length,
        itemBuilder: (context, yIdx) => _buildYearSection(_years[yIdx]),
      ),
    );
  }

  Widget _buildYearSection(Map<String, dynamic> yearData) {
    Map<int, List<dynamic>> flightsByMonth = {};
    for (var f in yearData['flights']) {
      DateTime dt = DateTime.parse(f['dateA']);
      flightsByMonth.putIfAbsent(dt.month, () => []).add(f);
    }
    var sortedMonths = flightsByMonth.keys.toList()..sort((a, b) => a.compareTo(b));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Row(
            children: [
              Text(yearData['year'].toString(),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
              const SizedBox(width: 15),
              Expanded(child: Container(height: 1, color: Colors.white10)),
            ],
          ),
        ),
        ...sortedMonths.map((m) => _buildMonthCard(m, flightsByMonth[m]!)).toList(),
      ],
    );
  }

  Widget _buildMonthCard(int month, List<dynamic> flights) {
    String monthName = DateFormat('MMMM', 'fr_FR').format(DateTime(2024, month)).toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1218),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          iconColor: Colors.blueAccent,
          collapsedIconColor: Colors.white24,
          title: Text(monthName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text("${flights.length} ANALYSES", style: const TextStyle(color: Colors.white38, fontSize: 9)),
          children: flights.map((f) => _buildFlightDetail(f)).toList(),
        ),
      ),
    );
  }

  Widget _buildFlightDetail(Map<String, dynamic> flight) {
    Map<String, Map<String, List<double>>> detailedScores = {};

    // FONCTION DE COLLECTE AVEC FILTRE "AUCUNE"
    void collect(dynamic comp, dynamic r, dynamic s, dynamic t) {
      if (comp == null) return;
      String name = comp.toString().toUpperCase().trim();

      // FILTRE ICI : Si c'est vide ou "AUCUNE", on n'ajoute rien à l'analyse
      if (name.isEmpty || name == "AUCUNE") return;

      double nr = double.tryParse(r.toString()) ?? 0.0;
      double ns = double.tryParse(s.toString()) ?? 0.0;
      double nt = double.tryParse(t.toString()) ?? 0.0;

      detailedScores.putIfAbsent(name, () => {'repas': [], 'service': [], 'retard': []});
      detailedScores[name]!['repas']!.add(nr);
      detailedScores[name]!['service']!.add(ns);
      detailedScores[name]!['retard']!.add(nt);
    }

    collect(flight['compA'], flight['repasA'], flight['serviceA'], flight['retardA']);
    if (flight['hasEscA'] == true && flight['listEscA'] != null) {
      for (var e in flight['listEscA']) { collect(e['comp'], e['repas'], e['service'], e['retard']); }
    }
    if (flight['dateR'] != null) {
      collect(flight['compR'], flight['repasR'], flight['serviceR'], flight['retardR']);
      if (flight['hasEscR'] == true && flight['listEscR'] != null) {
        for (var e in flight['listEscR']) { collect(e['comp'], e['repas'], e['service'], e['retard']); }
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141920),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Affichage des lignes de segments uniquement si ce n'est pas "AUCUNE"
          if (flight['compA']?.toString().toUpperCase() != "AUCUNE")
            _buildSegmentRow("ALLER", flight['compA'], Icons.flight_takeoff, Colors.blueAccent),

          if (flight['hasEscA'] == true && flight['listEscA'] != null)
            ...flight['listEscA'].where((e) => e['comp']?.toString().toUpperCase() != "AUCUNE")
                .map<Widget>((e) => _buildSegmentRow("ESCALE", e['comp'], Icons.sync, Colors.orangeAccent)),

          if (flight['dateR'] != null && flight['compR']?.toString().toUpperCase() != "AUCUNE") ...[
            const Divider(color: Colors.white10, height: 20),
            _buildSegmentRow("RETOUR", flight['compR'], Icons.flight_land, Colors.purpleAccent),
            if (flight['hasEscR'] == true && flight['listEscR'] != null)
              ...flight['listEscR'].where((e) => e['comp']?.toString().toUpperCase() != "AUCUNE")
                  .map<Widget>((e) => _buildSegmentRow("ESCALE", e['comp'], Icons.sync, Colors.orangeAccent)),
          ],

          if (detailedScores.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text("ANALYSE PAR COMPAGNIE",
                style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),

            ...detailedScores.entries.map((entry) {
              double avgRepas = entry.value['repas']!.reduce((a, b) => a + b) / entry.value['repas']!.length;
              double avgService = entry.value['service']!.reduce((a, b) => a + b) / entry.value['service']!.length;
              double avgRetard = entry.value['retard']!.reduce((a, b) => a + b) / entry.value['retard']!.length;
              double totalAvg = (avgRepas + avgService + avgRetard) / 3;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.01),
                  borderRadius: BorderRadius.circular(15),
                  border: Border(left: BorderSide(color: _getStatusColor(totalAvg), width: 3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(totalAvg.toStringAsFixed(2), style: TextStyle(color: _getStatusColor(totalAvg), fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _detailStat("REPAS", avgRepas),
                        _detailStat("SERVICE", avgService),
                        _detailStat("RETARD", avgRetard),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _detailStat(String label, double score) {
    Color c = _getStatusColor(score);
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 6, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(score.toStringAsFixed(1), style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(width: 40, height: 2, color: Colors.white10),
            Container(width: 40 * (score / 5), height: 2, color: c),
          ],
        )
      ],
    );
  }

  Widget _buildSegmentRow(String label, dynamic comp, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color.withOpacity(0.5)),
          const SizedBox(width: 8),
          Text("$label : ", style: TextStyle(color: color.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(comp?.toString().toUpperCase() ?? "INCONNU",
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}