import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DataService {
  static const String keyVols = 'vols_data';

  static Future<Map<String, dynamic>> getTrophyStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    String? data = prefs.getString(keyVols);

    int totalVols = 0, favsTotal = 0, escCount = 0;
    int sa = 0, st = 0, ow = 0, lc = 0, maj = 0;
    int airbus = 0, boeing = 0, embraer = 0;

    Set<String> uniqueAvions = {};
    Set<String> uniqueMois = {};
    Set<String> uniqueVilles = {};
    Map<String, int> destCountMap = {};

    final majeursList = ["AIR FRANCE", "LUFTHANSA", "EMIRATES", "QATAR AIRWAYS", "BRITISH AIRWAYS", "DELTA", "UNITED", "KLM", "SWISS", "SINGAPORE AIRLINES"];

    if (data != null) {
      try {
        List<dynamic> years = jsonDecode(data);
        for (var y in years) {
          List flights = y["flights"] ?? [];
          for (var f in flights) {
            totalVols++;

            // Logique de traitement des segments (Aller/Retour)
            _processCity(f["depA"], uniqueVilles, destCountMap);
            _processCity(f["destA"], uniqueVilles, destCountMap);
            _processCity(f["depR"], uniqueVilles, destCountMap);
            _processCity(f["destR"], uniqueVilles, destCountMap);

            if (_isValide(f["escA"])) escCount++;
            if (_isValide(f["escR"])) escCount++;

            String comp = (f["compA"] ?? "").toString().toUpperCase().trim();
            if (majeursList.contains(comp)) maj++;
            if (f["allA"] == "Star Alliance") sa++;
            if (f["allA"] == "SkyTeam") st++;
            if (f["allA"] == "Oneworld") ow++;
            if (f["allA"] == "Low Cost") lc++;
            if (f["favA"] == true) favsTotal++;

            _processAvion(f["avionA"], uniqueAvions, (type) {
              if (type == "A") airbus++; else if (type == "B") boeing++; else if (type == "E") embraer++;
            });
            _processAvion(f["avionR"], uniqueAvions, (type) {}); // On compte l'avion unique, pas le constructeur 2 fois par vol

            if (f["date"] != null) {
              try {
                DateTime dt = DateTime.parse(f["date"].toString());
                uniqueMois.add("${dt.month}_${dt.year}");
              } catch (_) {}
            }
          }
        }
      } catch (e) { print("Erreur Décodage: $e"); }
    }

    // --- LOGIQUE DES 40 BADGES (SYSTÈME DE POINTS) ---
    int b = 0;
    if (totalVols >= 1) b++; if (totalVols >= 10) b++; if (totalVols >= 50) b++; if (totalVols >= 100) b++;
    if (uniqueMois.length >= 6) b++; if (uniqueMois.length >= 12) b++; if (uniqueMois.length >= 24) b++;
    if (airbus >= 10) b++; if (airbus >= 30) b++; if (boeing >= 10) b++; if (boeing >= 30) b++;
    if (embraer >= 5) b++; if (uniqueAvions.length >= 10) b++; if (uniqueAvions.length >= 20) b++;
    if (sa >= 10) b++; if (sa >= 25) b++; if (st >= 10) b++; if (st >= 25) b++;
    if (ow >= 10) b++; if (ow >= 25) b++; if (maj >= 20) b++; if (maj >= 50) b++;
    if (lc >= 20) b++; if (lc >= 50) b++; if (uniqueVilles.length >= 10) b++; if (uniqueVilles.length >= 30) b++;
    if (uniqueVilles.length >= 60) b++; if (escCount >= 10) b++; if (escCount >= 30) b++;
    if (destCountMap.values.where((v) => v >= 5).length >= 5) b++;
    if (favsTotal >= 10) b++; if (favsTotal >= 30) b++; if (favsTotal >= 60) b++;

    return {
      "vols": totalVols,
      "escales": escCount,
      "avions": uniqueAvions.length,
      "villes": uniqueVilles.length,
      "badges": b,
      "favs": favsTotal,
      "airbus": airbus, "boeing": boeing, "embraer": embraer,
      "alliances": {"sa": sa, "st": st, "ow": ow, "lc": lc}
    };
  }

  static bool _isValide(dynamic val) => val != null && val.toString().isNotEmpty && val != "Aucune";

  static void _processCity(dynamic city, Set<String> set, Map<String, int> map) {
    if (_isValide(city)) {
      String n = city.toString().toUpperCase().trim();
      set.add(n);
      map[n] = (map[n] ?? 0) + 1;
    }
  }

  static void _processAvion(dynamic av, Set<String> set, Function(String) onType) {
    if (_isValide(av)) {
      String n = av.toString().toUpperCase().trim();
      set.add(n);
      if (n.contains("AIRBUS")) onType("A");
      else if (n.contains("BOEING")) onType("B");
      else if (n.contains("EMBRAER")) onType("E");
    }
  }
}