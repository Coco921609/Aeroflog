import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class VolsPage extends StatefulWidget {
  final VoidCallback onDataChanged;
  const VolsPage({super.key, required this.onDataChanged});

  @override
  State<VolsPage> createState() => _VolsPageState();
}

// --- LOGIQUE COULEURS MOIS ---
Color _getMonthColor(int month) {
  switch (month) {
    case 1: return const Color(0xFF4A90E2);
    case 2: return const Color(0xFFEC407A);
    case 3: return const Color(0xFF66BB6A);
    case 4: return const Color(0xFFFFEE58);
    case 5: return const Color(0xFFFFA726);
    case 6: return const Color(0xFFFF7043);
    case 7: return const Color(0xFFEF5350);
    case 8: return const Color(0xFF26C6DA);
    case 9: return const Color(0xFF7E57C2);
    case 10: return const Color(0xFF8D6E63);
    case 11: return const Color(0xFF78909C);
    case 12: return const Color(0xFF263238);
    default: return Colors.blueAccent;
  }
}

String _getMonthName(int month) {
  const m = ["JANVIER", "FÉVRIER", "MARS", "AVRIL", "MAI", "JUIN", "JUILLET", "AOÛT", "SEPTEMBRE", "OCTOBRE", "NOVEMBRE", "DÉCEMBRE"];
  return m[month - 1];
}

class _VolsPageState extends State<VolsPage> {
  List<dynamic> _years = [];
  int? _activeYearIndex;

  final Map<String, List<String>> _alliancesData = {
    "AUTRE": ["AUCUNE"],
    "STAR ALLIANCE": ["AEGEAN", "AIR CANADA", "AIR CHINA", "AIR INDIA", "AIR NEW ZEALAND", "ANA", "ASIANA AIRLINES", "AUSTRIAN", "AVIANCA", "BRUSSELS AIRLINES", "COPA AIRLINES", "CROATIA AIRLINES", "EGYPTAIR", "ETHIOPIAN AIRLINES", "EVA AIR", "LOT POLISH AIRLINES", "LUFTHANSA", "SHENZHEN AIRLINES", "SINGAPORE AIRLINES", "SOUTH AFRICAN AIRWAYS", "SWISS", "TAP AIR PORTUGAL", "THAI", "TURKISH AIRLINES", "UNITED", "ITA AIRWAYS", "JUNEYAO AIR"],
    "SKYTEAM": ["AEROLINEAS ARGENTINAS", "AEROMEXICO", "AIR EUROPA", "AIR FRANCE", "CHINA AIRLINES", "CHINA EASTERN", "DELTA", "GARUDA INDONESIA", "KENYA AIRWAYS", "KLM", "KOREAN AIR", "MEA", "SAS", "SAUDIA", "TAROM", "VIETNAM AIRLINES", "VIRGIN ATLANTIC", "XIAMEN AIR", "AEROFLOT"],
    "ONEWORLD": ["ALASKA AIRLINES", "AMERICAN AIRLINES", "BRITISH AIRWAYS", "CATHAY PACIFIC", "FIJI AIRWAYS", "FINNAIR", "IBERIA", "JAPAN AIRLINES", "MALAYSIA AIRLINES", "OMAN AIR", "QANTAS", "QATAR AIRWAYS", "ROYAL AIR MAROC", "ROYAL JORDANIAN", "SRILANKAN AIRLINES"],
    "LOW-COST": ["RYANAIR", "EASYJET", "WIZZAIR", "VOLOTEA", "VUELING", "TRANSAVIA", "SOUTHWEST", "JET2", "NORWEGIAN", "EUROWINGS", "PEGASUS", "FLYDUBAI", "AIRASIA", "INDIGO", "SCOOT", "SPICEJET", "PEACH", "SPRING AIRLINES", "FRENCH BEE", "LEVEL", "FLYNAS", "AIR BALTIC", "SMARTWINGS", "SPIRIT AIRLINES", "FRONTIER", "ALLEGIANT", "GOL", "AZUL", "JETSTAR", "TUI FLY", "PLAY", "NORSE", "ZIPAIR", "VIVA AEROBUS", "VIVA AIR", "VOLARIS", "WESTJET"],
    "AUTRES MAJEURS": ["EMIRATES", "ETIHAD", "EL AL", "ICELANDAIR", "GULF AIR", "AIR ASTANA", "AIR MAURITIUS", "AIR SEYCHELLES", "BANGKOK AIRWAYS", "HAWAIIAN AIRLINES", "LATAM", "PHILIPPINE AIRLINES", "VIETJET AIR", "VIRGIN AUSTRALIA"],
  };

  Map<String, String> get _companyToAlliance {
    Map<String, String> map = {};
    _alliancesData.forEach((alliance, companies) {
      for (var comp in companies) { map[comp] = alliance; }
    });
    return map;
  }

  @override
  void initState() { super.initState(); _loadState(); }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('vols_data');
    if (data != null) {
      List<dynamic> loadedYears = jsonDecode(data);
      loadedYears.sort((a, b) => (a['year'] ?? "").toString().compareTo((b['year'] ?? "").toString()));
      setState(() => _years = loadedYears);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    _years.sort((a, b) => (a['year'] ?? "").toString().compareTo((b['year'] ?? "").toString()));
    await prefs.setString('vols_data', jsonEncode(_years));
    widget.onDataChanged();
  }

  Color _getTimeColor(String moment) {
    switch (moment) {
      case "Très tôt": return Colors.orangeAccent;
      case "Matin": return Colors.yellowAccent;
      case "Midi": return Colors.cyanAccent;
      case "Après-midi": return Colors.blueAccent;
      case "Soirée": return Colors.indigoAccent;
      case "Minuit": return Colors.deepPurpleAccent;
      default: return Colors.white24;
    }
  }

  // --- WIDGETS UI ---
  void _showInfoLegend() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1F26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("GUIDE DES HORAIRES", style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _legendItem("Très tôt", "04:00 - 07:00", _getTimeColor("Très tôt")),
        _legendItem("Matin", "07:00 - 11:00", _getTimeColor("Matin")),
        _legendItem("Midi", "11:00 - 14:00", _getTimeColor("Midi")),
        _legendItem("Après-midi", "14:00 - 18:00", _getTimeColor("Après-midi")),
        _legendItem("Soirée", "18:00 - 22:00", _getTimeColor("Soirée")),
        _legendItem("Minuit", "22:00 - 04:00", _getTimeColor("Minuit")),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("FERMER"))],
    ));
  }

  Widget _legendItem(String title, String hours, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ]),
        Text(hours, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ]),
    );
  }

  void _showNotationLegend() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1F26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("SYSTÈME DE NOTATION", style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _notationGroup("REPAS", ["Dégueulasse", "Bof", "Correct", "Bon", "Excellent"]),
        const Divider(color: Colors.white10),
        _notationGroup("RETARD", ["Gros Retard", "Petit Retard", "Léger", "À l'heure", "En avance"]),
        const Divider(color: Colors.white10),
        _notationGroup("SERVICE", ["Désagréable", "Froid", "Normal", "Souriant", "Exceptionnel"]),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("COMPRIS"))],
    ));
  }

// --- GESTION ESCALES AVEC FAVORIS ---
  void _openEscalPage(BuildContext context, List<dynamic> currentList, Function(List<dynamic>) onSave) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0E14),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(children: [
          const Text("GÉRER LES ESCALES", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          Expanded(child: ListView.builder(
            itemCount: currentList.length,
            itemBuilder: (context, i) {
              bool isFav = currentList[i]['favEsc'] ?? false;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(15),
                    border: isFav ? Border.all(color: Colors.redAccent.withOpacity(0.5)) : null
                ),
                child: ListTile(
                  leading: Icon(isFav ? Icons.favorite : Icons.repeat, color: isFav ? Colors.redAccent : Colors.white38),
                  title: Text("${currentList[i]['ville'] ?? ""} ➔ ${currentList[i]['villeF'] ?? ""}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text("${currentList[i]['comp'] ?? ""} - ${currentList[i]['moment'] ?? ""}", style: const TextStyle(color: Colors.white38)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _addEscalDialog(ctx, (newEsc) => setS(() => currentList[i] = newEsc), initialEsc: currentList[i])),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => setS(() => currentList.removeAt(i))),
                  ]),
                ),
              );
            },
          )),
          ElevatedButton(onPressed: () => _addEscalDialog(ctx, (esc) => setS(() => currentList.add(esc))), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 50)), child: const Text("AJOUTER UNE ESCALE")),
          const SizedBox(height: 10),
          TextButton(onPressed: () { onSave(currentList); Navigator.pop(ctx); }, child: const Text("ENREGISTRER TOUTES LES ESCALES", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
        ]),
      )),
    );
  }

  void _addEscalDialog(BuildContext context, Function(Map<String, dynamic>) onAdd, {Map<String, dynamic>? initialEsc}) {
    var cV = TextEditingController(text: initialEsc?['ville'] ?? "");
    var cVF = TextEditingController(text: initialEsc?['villeF'] ?? "");
    String comp = initialEsc?['comp'] ?? "AUCUNE";
    String all = initialEsc?['alliance'] ?? "AUTRE";
    String avion = initialEsc?['avion'] ?? "Airbus";
    String mom = initialEsc?['moment'] ?? "Matin";
    String turb = initialEsc?['turbulence'] ?? "Normal";
    bool favEsc = initialEsc?['favEsc'] ?? false; // Nouveau champ Favori
    double r = (initialEsc?['repas'] ?? 3).toDouble();
    double ret = (initialEsc?['retard'] ?? 3).toDouble();
    double s = (initialEsc?['service'] ?? 3).toDouble();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      backgroundColor: const Color(0xFF1A1F26),
      insetPadding: const EdgeInsets.all(10),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("DÉTAILS DE L'ESCALE", style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
          IconButton(
            icon: Icon(favEsc ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent),
            onPressed: () => setS(() => favEsc = !favEsc),
          )
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _companyDropdown(comp, (c, a) => setS(() { comp = c; all = a; })),
          _selectionListVertical("AVION", ["Airbus", "Boeing", "Embraer", "Autre", "Aucun"], avion, (v) => setS(() => avion = v), (v) => _getConstructorColor(v)),
          _selectionListVertical("HORAIRE", ["Très tôt", "Matin", "Midi", "Après-midi", "Soirée", "Minuit"], mom, (v) => setS(() => mom = v), (v) => _getTimeColor(v)),
          _input(cV, "De (Ville)"), _input(cVF, "À (Ville)"),
          _noteTriple("Repas", r, (v) => setS(() => r = v)), _noteTriple("Retard", ret, (v) => setS(() => ret = v)), _noteTriple("Service", s, (v) => setS(() => s = v)),
          _selectionListVertical("TURBULENCE", ["Normal", "Moyen", "Pire"], turb, (v) => setS(() => turb = v), (v) => _getTurbulenceColor(v)),
        ])),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER")),
        ElevatedButton(onPressed: () {
          onAdd({
            "ville": cV.text, "villeF": cVF.text, "comp": comp, "alliance": all,
            "avion": avion, "moment": mom, "turbulence": turb,
            "repas": r.toInt(), "retard": ret.toInt(), "service": s.toInt(),
            "favEsc": favEsc // On enregistre l'état favori
          });
          Navigator.pop(ctx);
        }, child: const Text("VALIDER")),
      ],
    )));
  }

  // --- DIALOGUE SESSION AVEC DETECTION ROUGE ---
  void _showYearDialog({int? editIndex}) {
    var c = TextEditingController(text: editIndex != null ? (_years[editIndex]['year'] ?? "").toString() : "");
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => StatefulBuilder(builder: (context, setStateDialog) {
      final String val = c.text;
      final bool isFourDigits = RegExp(r"^\d{4}$").hasMatch(val);
      int yearInput = int.tryParse(val) ?? 0;

      // Verification Année 1980-2099 + Doublon
      final bool isReasonableYear = yearInput >= 1980 && yearInput <= 2099;
      final bool exists = _years.any((y) => y['year'].toString() == val && _years.indexOf(y) != editIndex);

      bool isError = (val.length == 4 && !isReasonableYear) || (isFourDigits && exists);
      String label = exists ? "DEJA CREE!" : "ECRIS UNE ANNEE";

      return AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        title: Text(editIndex == null ? "NOUVELLE SESSION" : "MODIFIER SESSION", style: const TextStyle(color: Colors.blueAccent, fontSize: 14)),
        content: TextField(
          controller: c, autofocus: true, keyboardType: TextInputType.number, maxLength: 4,
          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center, onChanged: (v) => setStateDialog(() {}),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: isError ? Colors.red : Colors.white38, fontSize: 12),
            counterText: "",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER")),
          if (isFourDigits && isReasonableYear && !exists) ElevatedButton(onPressed: () {
            setState(() { if (editIndex == null) _years.add({"year": c.text, "flights": []}); else _years[editIndex]['year'] = c.text; });
            _save(); Navigator.pop(ctx);
          }, child: const Text("OK")),
        ],
      );
    }));
  }

  void _showFlightForm({int? editIndex}) {
    var f = editIndex != null ? _years[_activeYearIndex!]["flights"][editIndex] : null;
    int sessionYear = int.parse((_years[_activeYearIndex!]["year"] ?? "2024").toString());

    String compA = f?['compA'] ?? "AUCUNE"; String allA = f?['allA'] ?? "AUTRE";
    var cDA = TextEditingController(text: f?['depA'] ?? ""); var cAA = TextEditingController(text: f?['arrA'] ?? "");
    String avionA = f?['avionA'] ?? "Airbus"; String momA = f?['momentA'] ?? "Matin";
    String turbA = f?['turbAller'] ?? "Normal"; bool favA = f?['favA'] ?? false;
    double rA = (f?['repasA'] ?? 3).toDouble(); double retA = (f?['retardA'] ?? 3).toDouble(); double sA = (f?['serviceA'] ?? 3).toDouble();
    bool hasEscA = f?['hasEscA'] ?? false; List<dynamic> listEscA = f?['listEscA'] != null ? List.from(f['listEscA']) : [];

    String compR = f?['compR'] ?? "AUCUNE"; String allR = f?['allR'] ?? "AUTRE";
    var cDR = TextEditingController(text: f?['depR'] ?? ""); var cAR = TextEditingController(text: f?['arrR'] ?? "");
    String avionR = f?['avionR'] ?? "Airbus"; String momR = f?['momentR'] ?? "Matin";
    String turbR = f?['turbRetour'] ?? "Normal"; bool favR = f?['favR'] ?? false;
    double rR = (f?['repasR'] ?? 3).toDouble(); double retR = (f?['retardR'] ?? 3).toDouble(); double sR = (f?['serviceR'] ?? 3).toDouble();
    bool hasEscR = f?['hasEscR'] ?? false; List<dynamic> listEscR = f?['listEscR'] != null ? List.from(f['listEscR']) : [];

    DateTime dateA = f?['dateA'] != null ? DateTime.parse(f['dateA']) : DateTime(sessionYear, 1, 1);
    DateTime? dateR = f?['dateR'] != null ? DateTime.parse(f['dateR']) : null;

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => DraggableScrollableSheet(initialChildSize: 0.95, builder: (ctx, scrollC) => StatefulBuilder(builder: (ctx, setS) {

      bool dayExists = false;
      if (editIndex == null) {
        dayExists = (_years[_activeYearIndex!]["flights"] as List).any((flight) => DateTime.parse(flight['dateA']).day == dateA.day && DateTime.parse(flight['dateA']).month == dateA.month);
      }

      return Container(
        decoration: const BoxDecoration(color: Color(0xFF0A0E14), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: SingleChildScrollView(controller: scrollC, padding: const EdgeInsets.all(20), child: Column(children: [
          _buildTicketIDDesign(editIndex == null ? "NEW PASS" : "EDIT PASS", "Flight Document"),

          // Date avec Alerte Rouge Doublon
          _dateBtn(dayExists ? "DEJA CREE!" : "DÉPART", dateA, (d) => setS(() => dateA = d), sessionYear, isError: dayExists),

          _dateBtn("RETOUR (Optionnel)", dateR, (d) => setS(() => dateR = d), sessionYear),

          _formSection("ALLER", _getAllianceColor(allA), [
            _boardingHeader("✈️ VOL ALLER", favA, (v) => setS(() => favA = v)),
            _companyDropdown(compA, (c, a) => setS(() { compA = c; allA = a; })),
            _selectionListVertical("AVION", ["Airbus", "Boeing", "Embraer", "Autre", "Aucun"], avionA, (v) => setS(() => avionA = v), (v) => _getConstructorColor(v)),
            _selectionListVertical("HORAIRE", ["Très tôt", "Matin", "Midi", "Après-midi", "Soirée", "Minuit"], momA, (v) => setS(() => momA = v), (v) => _getTimeColor(v)),
            Row(children: [Expanded(child: _input(cDA, "Départ")), const SizedBox(width: 10), Expanded(child: _input(cAA, "Arrivée"))]),
            _checkboxEsc("ESCALE ALLER", hasEscA, (v) { setS(() => hasEscA = v); if(v) _openEscalPage(ctx, listEscA, (nl) => setS(() => listEscA = nl)); }),
            _noteTriple("Repas", rA, (v) => setS(() => rA = v)), _noteTriple("Retard", retA, (v) => setS(() => retA = v)), _noteTriple("Service", sA, (v) => setS(() => sA = v)),
            _selectionListVertical("TURBULENCE", ["Normal", "Moyen", "Pire"], turbA, (v) => setS(() => turbA = v), (v) => _getTurbulenceColor(v)),
          ]),

          if(dateR != null) _formSection("RETOUR", _getAllianceColor(allR), [
            _boardingHeader("🛬 VOL RETOUR", favR, (v) => setS(() => favR = v)),
            _companyDropdown(compR, (c, a) => setS(() { compR = c; allR = a; })),
            _selectionListVertical("AVION", ["Airbus", "Boeing", "Embraer", "Autre", "Aucun"], avionR, (v) => setS(() => avionR = v), (v) => _getConstructorColor(v)),
            _selectionListVertical("HORAIRE", ["Très tôt", "Matin", "Midi", "Après-midi", "Soirée", "Minuit"], momR, (v) => setS(() => momR = v), (v) => _getTimeColor(v)),
            Row(children: [Expanded(child: _input(cDR, "Départ")), const SizedBox(width: 10), Expanded(child: _input(cAR, "Arrivée"))]),
            _checkboxEsc("ESCALE RETOUR", hasEscR, (v) { setS(() => hasEscR = v); if(v) _openEscalPage(ctx, listEscR, (nl) => setS(() => listEscR = nl)); }),
            _noteTriple("Repas", rR, (v) => setS(() => rR = v)), _noteTriple("Retard", retR, (v) => setS(() => retR = v)), _noteTriple("Service", sR, (v) => setS(() => sR = v)),
            _selectionListVertical("TURBULENCE", ["Normal", "Moyen", "Pire"], turbR, (v) => setS(() => turbR = v), (v) => _getTurbulenceColor(v)),
          ]),

          ElevatedButton(onPressed: dayExists ? null : () {
            var data = {
              "dateA": dateA.toIso8601String(), "dateR": dateR?.toIso8601String(),
              "compA": compA, "allA": allA, "depA": cDA.text, "arrA": cAA.text, "favA": favA, "avionA": avionA, "momentA": momA, "repasA": rA.toInt(), "retardA": retA.toInt(), "serviceA": sA.toInt(), "hasEscA": hasEscA, "listEscA": listEscA, "turbAller": turbA,
              "compR": compR, "allR": allR, "depR": cDR.text, "arrR": cAR.text, "favR": favR, "avionR": avionR, "momentR": momR, "repasR": rR.toInt(), "retardR": retR.toInt(), "serviceR": sR.toInt(), "hasEscR": hasEscR, "listEscR": listEscR, "turbRetour": turbR,
            };
            setState(() { if (editIndex == null) _years[_activeYearIndex!]["flights"].add(data); else _years[_activeYearIndex!]["flights"][editIndex] = data; });
            _save(); Navigator.pop(ctx);
          }, style: ElevatedButton.styleFrom(backgroundColor: dayExists ? Colors.grey : Colors.blueAccent, minimumSize: const Size(double.infinity, 60)), child: const Text("VALIDER MON TICKET")),
        ])),
      );
    })));
  }

  Widget _companyDropdown(String current, Function(String, String) onS) => DropdownButtonFormField<String>(
    value: _companyToAlliance.containsKey(current) ? current : "AUCUNE", dropdownColor: const Color(0xFF1A1F26), isExpanded: true,
    decoration: const InputDecoration(labelText: "COMPAGNIE", labelStyle: TextStyle(color: Colors.blueAccent, fontSize: 12)),
    style: const TextStyle(color: Colors.white, fontSize: 16),
    items: _alliancesData.entries.expand((e) => [
      DropdownMenuItem<String>(enabled: false, value: e.key, child: Text(e.key, style: TextStyle(color: _getAllianceColor(e.key), fontWeight: FontWeight.bold, fontSize: 11))),
      ...e.value.map((c) => DropdownMenuItem<String>(value: c, child: Padding(padding: const EdgeInsets.only(left: 10), child: Text(c))))
    ]).toList(),
    onChanged: (v) { if (v != null) onS(v, _companyToAlliance[v] ?? "AUTRE"); },
  );

  Widget _buildDetailedBoardingPass(String title, String comp, String dep, String arr, bool isA, String mom, List<dynamic> esc, dynamic f, Color monthColor) {
    String p = isA ? "A" : "R"; Color theme = _getAllianceColor(f['all$p'] ?? "AUTRE");
    return Container(margin: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(20), border: Border.all(color: monthColor.withOpacity(0.4), width: 2)), child: Column(children: [
      _buildTicketHeader(title, color: monthColor),
      Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _flightInfoBlock(dep, "DEPARTURE"),
          Column(children: [Icon(isA ? Icons.flight_takeoff : Icons.flight_land, color: _getTimeColor(mom)), Text(comp, style: TextStyle(fontSize: 8, color: theme, fontWeight: FontWeight.bold))]),
          _flightInfoBlock(arr, "ARRIVAL"),
        ]),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _infoIcon(Icons.restaurant, f['repas$p'] ?? 3, _getNoteColor((f['repas$p'] ?? 3).toInt())),
          _infoIcon(Icons.timer, f['retard$p'] ?? 3, _getNoteColor((f['retard$p'] ?? 3).toInt())),
          _infoIcon(Icons.person, f['service$p'] ?? 3, _getNoteColor((f['service$p'] ?? 3).toInt())),
          _infoIcon(Icons.waves, "TURB", _getTurbulenceColor(f['turb${isA?"Aller":"Retour"}'] ?? "Normal")),
        ]),
        if (esc.isNotEmpty) ...[const Divider(color: Colors.white10), ...esc.map((e) => _escCard(e)).toList()]
      ])),
      _buildBarcodeArea(),
    ]));
  }

  Widget _escCard(dynamic e) => Container(margin: const EdgeInsets.only(top: 5), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)), child: Row(children: [Icon(Icons.repeat, size: 12, color: _getTimeColor(e['moment'] ?? "Matin")), const SizedBox(width: 10), Expanded(child: Text("${e['comp'] ?? ""} : ${e['ville'] ?? ""} ➔ ${e['villeF'] ?? ""} (${e['avion'] ?? ""})", style: const TextStyle(fontSize: 10, color: Colors.white70)))]));
  Widget _infoIcon(IconData i, dynamic v, Color c) => Column(children: [Icon(i, size: 14, color: c), Text(v is int ? "$v/5" : v.toString(), style: TextStyle(fontSize: 8, color: c))]);
  Widget _selectionListVertical(String t, List<String> o, String cur, Function(String) onS, Color Function(String) col) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 10), Text(t, style: const TextStyle(color: Colors.white38, fontSize: 10)), Wrap(spacing: 5, children: o.map((v) => ChoiceChip(label: Text(v, style: const TextStyle(fontSize: 12)), selected: cur == v, selectedColor: col(v).withOpacity(0.5), onSelected: (s) => onS(v))).toList())]);
  Widget _noteTriple(String l, double v, Function(double) onS) => Row(children: [Expanded(child: Text(l, style: const TextStyle(fontSize: 11, color: Colors.white70))), Slider(value: v, min: 1, max: 5, divisions: 4, activeColor: _getNoteColor(v.toInt()), onChanged: onS), Text("${v.toInt()}/5", style: TextStyle(fontSize: 11, color: _getNoteColor(v.toInt())))]);
  Widget _input(TextEditingController c, String h) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: TextField(controller: c, style: const TextStyle(fontSize: 16, color: Colors.white), decoration: InputDecoration(hintText: h, hintStyle: const TextStyle(color: Colors.white24), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))));

  Widget _dateBtn(String l, DateTime? d, Function(DateTime) onP, int y, {bool isError = false}) => ListTile(
      title: Text(l, style: TextStyle(fontSize: 10, color: isError ? Colors.red : Colors.white38, fontWeight: isError ? FontWeight.bold : FontWeight.normal)),
      subtitle: Text(d == null ? "SÉLECTIONNER" : "${d.day}/${d.month}/${d.year}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      trailing: Icon(Icons.calendar_today, size: 20, color: isError ? Colors.red : Colors.blueAccent),
      onTap: () async { DateTime? p = await showDatePicker(context: context, initialDate: d ?? DateTime(y, 1, 1), firstDate: DateTime(y, 1, 1), lastDate: DateTime(y, 12, 31)); if(p != null) onP(p); }
  );

  Widget _flightInfoBlock(String c, String l) => Column(children: [Text(l, style: const TextStyle(fontSize: 8, color: Colors.white24)), Text(c.isEmpty ? "---" : c.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))]);
  Widget _buildBarcodeArea() => Container(height: 25, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(19))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(30, (i) => Container(width: i % 4 == 0 ? 1 : 2, height: 12, margin: const EdgeInsets.symmetric(horizontal: 1), color: Colors.black))));
  Widget _buildTicketHeader(String t, {Color color = Colors.blue}) => Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(19))), child: Text(t, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)));
  Widget _formSection(String t, Color c, List<Widget> ch) => Container(margin: const EdgeInsets.only(bottom: 15), decoration: BoxDecoration(color: const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.3))), child: Column(children: [_buildTicketHeader(t, color: c), Padding(padding: const EdgeInsets.all(15), child: Column(children: ch))]));
  Widget _boardingHeader(String t, bool f, Function(bool) onF) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyan)), IconButton(icon: Icon(f ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent, size: 24), onPressed: () => onF(!f))]);
  Widget _checkboxEsc(String t, bool v, Function(bool) onC) => CheckboxListTile(title: Text(t, style: const TextStyle(fontSize: 14, color: Colors.white)), value: v, onChanged: (val) => onC(val!), activeColor: Colors.blueAccent);
  Widget _buildTicketIDDesign(String id, String sub) => Container(height: 80, margin: const EdgeInsets.only(bottom: 15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: Row(children: [Container(width: 40, decoration: const BoxDecoration(color: Color(0xFF1D4ED8), borderRadius: BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15))), child: const RotatedBox(quarterTurns: 3, child: Center(child: Text("BOARDING PASS", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))))), Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15), child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(sub, style: const TextStyle(color: Colors.black45, fontSize: 10)), Text(id, style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold))])))]));
  Widget _notationGroup(String title, List<String> labels) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 8), ...List.generate(5, (i) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text("${i + 1} : ${labels[i]}", style: TextStyle(color: _getNoteColor(i + 1), fontSize: 12))))]);

  Color _getNoteColor(int n) => n <= 1 ? Colors.redAccent : n == 2 ? Colors.orangeAccent : n == 3 ? Colors.yellowAccent : n == 4 ? Colors.lightGreenAccent : Colors.greenAccent;
  Color _getTurbulenceColor(String l) => l == "Moyen" ? Colors.orange : l == "Pire" ? Colors.red : Colors.greenAccent;
  Color _getConstructorColor(String t) => t == "Airbus" ? Colors.blue : t == "Boeing" ? Colors.cyan : t == "Embraer" ? Colors.indigo : Colors.white38;
  Color _getAllianceColor(String a) => a == "SKYTEAM" ? Colors.blue : a == "STAR ALLIANCE" ? Colors.cyan : a == "ONEWORLD" ? Colors.redAccent : a == "LOW-COST" ? Colors.amber : Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        title: const Text("MES VOLS LOGS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true, backgroundColor: Colors.transparent,
        leading: _activeYearIndex != null ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => setState(() => _activeYearIndex = null)) : null,
        actions: _activeYearIndex != null ? [
          IconButton(icon: const Icon(Icons.info_outline, color: Colors.white70), onPressed: _showInfoLegend),
          IconButton(icon: const Icon(Icons.star_border, color: Colors.cyanAccent), onPressed: _showNotationLegend),
        ] : null,
      ),
      body: _activeYearIndex == null ? _buildYearList() : _buildFlightList(),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: Colors.blueAccent, onPressed: () => _activeYearIndex == null ? _showYearDialog() : _showFlightForm(), label: Text(_activeYearIndex == null ? "NOUVELLE SESSION" : "AJOUTER UN VOL"), icon: const Icon(Icons.add)),
    );
  }

  Widget _buildYearList() => ListView.builder(padding: const EdgeInsets.all(15), itemCount: _years.length, itemBuilder: (context, i) => Card(
      color: const Color(0xFF1A1F26), child: ListTile(
    leading: const Icon(Icons.folder, color: Colors.blueAccent),
    title: Text("SESSION ${(_years[i]['year'] ?? "").toString()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(icon: const Icon(Icons.edit, color: Colors.white24), onPressed: () => _showYearDialog(editIndex: i)),
      IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () { setState(() => _years.removeAt(i)); _save(); })
    ]),
    onTap: () => setState(() => _activeYearIndex = i),
  )));

  Widget _buildFlightList() {
    var flights = _years[_activeYearIndex!]["flights"] as List<dynamic>;
    flights.sort((a, b) => (a['dateA'] ?? "").toString().compareTo((b['dateA'] ?? "").toString()));
    return ListView.builder(itemCount: flights.length, itemBuilder: (ctx, i) {
      final f = flights[i];
      DateTime dateA = DateTime.parse(f['dateA']);
      Color mCol = _getMonthColor(dateA.month);
      return Padding(padding: const EdgeInsets.all(15), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("TICKET #${i+1}", style: const TextStyle(color: Colors.white24, fontSize: 10)),
          Row(children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20), onPressed: () => _showFlightForm(editIndex: i)),
            IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () { setState(() => flights.removeAt(i)); _save(); }),
          ]),
        ]),
        _buildDetailedBoardingPass("ALLER - ${dateA.day} ${_getMonthName(dateA.month)} ${dateA.year}", f['compA'] ?? "", f['depA'] ?? "", f['arrA'] ?? "", true, f['momentA'] ?? "Matin", f['listEscA'] ?? [], f, mCol),
        if (f['dateR'] != null) _buildDetailedBoardingPass("RETOUR - ${DateTime.parse(f['dateR']).day} ${_getMonthName(DateTime.parse(f['dateR']).month)} ${DateTime.parse(f['dateR']).year}", f['compR'] ?? "", f['depR'] ?? "", f['arrR'] ?? "", false, f['momentR'] ?? "Matin", f['listEscR'] ?? [], f, mCol),
      ]));
    });
  }
}

