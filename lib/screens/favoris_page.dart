import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavorisPage extends StatefulWidget {
  const FavorisPage({super.key});

  @override
  State<FavorisPage> createState() => _FavorisPageState();
}

class _FavorisPageState extends State<FavorisPage> {
  Map<String, List<Map<String, dynamic>>> _groupedFavs = {};
  List<String> _sortedYears = [];

  final List<Color> _noteColors = [
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.greenAccent,
    Colors.pinkAccent,
    Colors.cyanAccent,
  ];

  @override
  void initState() {
    super.initState();
    _loadFavoris();
  }

  // Fonction pour vérifier si une compagnie est valide
  bool _isValid(dynamic comp) {
    if (comp == null) return false;
    String s = comp.toString().toUpperCase().trim();
    return s.isNotEmpty && s != "AUCUNE";
  }

  Future<void> _loadFavoris() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('vols_data');
    Map<String, List<Map<String, dynamic>>> tempGrouped = {};

    if (data != null) {
      try {
        List<dynamic> years = jsonDecode(data);
        for (var y in years) {
          String yearStr = y["year"].toString();
          List<Map<String, dynamic>> yearFavs = [];

          if (y["flights"] != null) {
            for (var f in y["flights"]) {

              // --- VÉRIFICATION ALLER ---
              // On compte si (le vol direct a une compagnie OU une escale a une compagnie) ET que le coeur est coché
              bool hasValidCompA = _isValid(f["compA"]);
              bool hasValidEscA = (f["listEscA"] != null && f["listEscA"].any((e) => _isValid(e["comp"])));

              if (f["favA"] == true && (hasValidCompA || hasValidEscA)) {
                yearFavs.add({
                  "comp": hasValidCompA ? f["compA"] : "ESCALE",
                  "route": "${f["depA"]} ➔ ${f["arrA"]}",
                  "type": "ALLER"
                });
              }

              // --- VÉRIFICATION RETOUR ---
              bool hasValidCompR = _isValid(f["compR"]);
              bool hasValidEscR = (f["listEscR"] != null && f["listEscR"].any((e) => _isValid(e["comp"])));

              if (f["favR"] == true && (hasValidCompR || hasValidEscR)) {
                yearFavs.add({
                  "comp": hasValidCompR ? f["compR"] : "ESCALE",
                  "route": "${f["depR"]} ➔ ${f["arrR"]}",
                  "type": "RETOUR"
                });
              }
            }
          }

          if (yearFavs.isNotEmpty) {
            tempGrouped[yearStr] = yearFavs;
          }
        }
      } catch (e) {
        debugPrint("Erreur: $e");
      }
    }

    List<String> sortedYears = tempGrouped.keys.toList()..sort((a, b) => a.compareTo(b));

    setState(() {
      _groupedFavs = tempGrouped;
      _sortedYears = sortedYears;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        title: const Text("ARCHIVES COUP DE CŒUR",
            style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 14)),
        backgroundColor: const Color(0xFF0A0E14),
        centerTitle: true,
        elevation: 0,
      ),
      body: _sortedYears.isEmpty
          ? const Center(child: Text("AUCUN VOL VALIDE EN FAVORIS",
          style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)))
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _sortedYears.length,
        itemBuilder: (context, index) {
          String year = _sortedYears[index];
          List<Map<String, dynamic>> favs = _groupedFavs[year]!;
          Color accentColor = _noteColors[index % _noteColors.length];
          return _buildYearBlock(year, favs, accentColor);
        },
      ),
    );
  }

  Widget _buildYearBlock(String year, List<Map<String, dynamic>> favs, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(topRight: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("SESSION $year",
                    style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                Icon(Icons.bookmark_rounded, color: color, size: 16),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: favs.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: color, size: 14),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f["comp"].toString().toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text("${f["type"]} : ${f["route"]}",
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}