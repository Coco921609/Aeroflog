import 'package:flutter/material.dart';

class ModelesAvionPage extends StatelessWidget {
  const ModelesAvionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0D12),
        appBar: AppBar(
          backgroundColor: const Color(0xFF10141D),
          elevation: 0,
          title: const Text("ENCYCLOPÉDIE DE FLOTTE", style: TextStyle(letterSpacing: 1.5, fontSize: 16, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            isScrollable: false, // Suppression du défilement des onglets
            indicatorColor: Color(0xFFD4AF37),
            labelColor: Color(0xFFD4AF37),
            unselectedLabelColor: Colors.white38,
            labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), // Texte légèrement plus petit pour tout faire tenir
            tabs: [
              Tab(text: "AIRBUS"),
              Tab(text: "BOEING"),
              Tab(text: "EMBRAER"),
              Tab(text: "LÉGENDES"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAirbusList(),
            _buildBoeingList(),
            _buildEmbraerList(),
            _buildLegacyList(),
          ],
        ),
      ),
    );
  }

  // --- FLOTTE AIRBUS ---
  Widget _buildAirbusList() {
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        _avionCard("A220", "Anciennement Bombardier CSeries, c'est l'avion le plus moderne pour les trajets courts/moyens. Très silencieux et écologique.", "120-150", "30 ans", "6 300 km", Colors.cyanAccent),
        _avionCard("A318", "Le 'Baby Bus'. Le plus petit de la famille A320, capable d'atterrir sur des pistes très courtes comme London City.", "107-132", "25 ans", "5 700 km", Colors.blueGrey),
        _avionCard("A319", "Version raccourcie de l'A320, très utilisé pour les vols en montagne grâce à sa puissance moteur.", "124-156", "25 ans", "6 900 km", Colors.blue),
        _avionCard("A320", "L'avion le plus vendu au monde. Un vol d'A320 décolle ou atterrit toutes les 2 secondes sur Terre. C'est l'un des modèles les plus sûrs de l'histoire.", "150-180", "25-30 ans", "6 100 km", Colors.greenAccent, special: "🏆 MODÈLE LE PLUS SÛR ET LE PLUS UTILISÉ AU MONDE"),
        _avionCard("A320 NEO", "Version remotorisée (New Engine Option). Consomme 15% de carburant en moins et réduit le bruit de 50%.", "165-195", "30 ans", "6 500 km", Colors.lightGreenAccent),
        _avionCard("A321", "La version allongée de l'A320. Idéal pour les lignes à forte densité.", "185-236", "25 ans", "5 900 km", Colors.tealAccent),
        _avionCard("A321 NEO", "Le champion du rendement. Capable de traverser l'Atlantique avec un seul couloir (version LR/XLR).", "200-244", "30 ans", "7 400 km", Colors.green),
        _avionCard("A330", "Le long-courrier polyvalent. Très apprécié pour son confort cabine et sa fiabilité exemplaire.", "250-440", "30 ans", "13 400 km", Colors.blueAccent),
        _avionCard("A340", "Le géant à 4 moteurs. Conçu à une époque où les moteurs étaient moins fiables, ses 4 moteurs lui permettaient de survoler les océans sans restrictions ETOPS.", "290-440", "25 ans", "14 400 km", Colors.indigoAccent, special: "⚙️ POURQUOI 4 MOTEURS ? Sécurité maximale pré-ETOPS."),
        _avionCard("A350", "Le 'Extra Wide Body'. Fabriqué en composite (carbone), c'est le futur du long-courrier haute technologie.", "300-410", "35 ans", "15 000 km", Colors.purpleAccent),
        _avionCard("A380", "Le 'Super Jumbo'. Seul avion à double pont intégral. Une véritable ville volante avec un silence incroyable.", "525-853", "25 ans", "15 200 km", Colors.amberAccent),
      ],
    );
  }

  // --- FLOTTE BOEING ---
  Widget _buildBoeingList() {
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        _avionCard("737 NG", "Le concurrent direct de l'A320. Un classique robuste utilisé par presque toutes les compagnies.", "130-190", "25 ans", "5 500 km", Colors.orangeAccent),
        _avionCard("737 MAX", "La dernière génération du 737. Plus efficace, avec des winglets en forme de 'ciseau' distinctifs.", "150-230", "30 ans", "6 500 km", Colors.deepOrangeAccent),
        _avionCard("747-400/8", "La 'Reine des Cieux'. Premier avion à deux ponts, reconnaissable à sa bosse caractéristique.", "416-600", "30 ans", "14 000 km", Colors.redAccent),
        _avionCard("757", "Le 'Cigar volant'. Un avion très puissant capable de décoller sur des pistes très courtes malgré sa taille.", "200-295", "25 ans", "7 200 km", Colors.brown),
        _avionCard("767", "Le pilier des vols transatlantiques des années 90. Très fiable et spacieux.", "210-375", "30 ans", "11 000 km", Colors.blueGrey),
        _avionCard("777-200ER", "L'un des plus gros bimoteurs au monde. Conçu pour relier n'importe quelle ville.", "300-440", "30 ans", "13 000 km", Colors.blue),
        _avionCard("777-300ER", "Le modèle préféré des compagnies pour remplacer le 747. Une puissance moteur phénoménale.", "365-550", "30 ans", "14 500 km", Colors.blueAccent),
        _avionCard("787-8 Dreamliner", "Premier avion majeur en carbone. Hublots géants électroniques et meilleure humidité en cabine.", "242", "35 ans", "13 600 km", Colors.lightBlueAccent),
        _avionCard("787-9 Dreamliner", "Version allongée du 787. C'est l'équilibre parfait entre capacité et distance.", "290", "35 ans", "14 100 km", Colors.cyan),
        _avionCard("787-10 Dreamliner", "Le plus grand des Dreamliners, optimisé pour transporter plus de passagers.", "330", "35 ans", "11 900 km", Colors.teal),
      ],
    );
  }

  // --- FLOTTE EMBRAER ---
  Widget _buildEmbraerList() {
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        _avionCard("E175", "Le roi des vols régionaux aux USA. Offre un confort supérieur car il n'y a pas de siège au milieu.", "76-88", "25 ans", "3 700 km", Colors.grey),
        _avionCard("E175-E2", "Nouvelle génération avec des moteurs plus larges et une consommation réduite de 16%.", "80-90", "30 ans", "3 800 km", Colors.white70),
        _avionCard("E195", "Le plus grand de la famille E-Jet originale. Très efficace pour les trajets européens.", "106-124", "25 ans", "4 000 km", Colors.yellowAccent),
        _avionCard("E195-E2", "Le 'Profit Hunter'. Des ailes technologiques et un silence en cabine exceptionnel.", "120-146", "30 ans", "4 800 km", Colors.yellow),
      ],
    );
  }

  // --- FLOTTE LÉGENDES ---
  Widget _buildLegacyList() {
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        _avionCard("CONCORDE", "L'oiseau blanc. Le seul avion de ligne supersonique à avoir eu un succès commercial. Traversait l'Atlantique en 3h30.", "100", "27 ans", "7 200 km (Mach 2.04)", Colors.white, special: "⚡ VITESSE SUPERSONIQUE : Plus rapide que le son."),
        _avionCard("DC-10", "Le célèbre triréacteur de McDonnell Douglas. Reconnaissable à son moteur intégré dans la dérive verticale.", "250-380", "30 ans", "10 600 km", Colors.red),
        _avionCard("MD-11", "Évolution du DC-10, plus long et avec des winglets. Un des derniers grands triréacteurs au monde.", "285-410", "25 ans", "12 600 km", Colors.redAccent),
        _avionCard("LOCKHEED L-1011", "Le Tristar. Technologiquement très en avance sur son temps, notamment pour son système d'atterrissage automatique.", "250-400", "25 ans", "9 800 km", Colors.pinkAccent),
      ],
    );
  }

  // --- WIDGET DE CARTE D'AVION ---
  Widget _avionCard(String nom, String desc, String sieges, String vie, String vol, Color accentColor, {String? special}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(nom, style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(Icons.airplanemode_active, color: accentColor.withOpacity(0.5), size: 20),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                if (special != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(special, style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
                const SizedBox(height: 15),
                const Divider(color: Colors.white10),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _specItem("SIÈGES", sieges, Icons.event_seat, accentColor),
                    _specItem("VIE UTILE", vie, Icons.timer, accentColor),
                    _specItem("DISTANCE", vol, Icons.map, accentColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _specItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: color.withOpacity(0.5)),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}