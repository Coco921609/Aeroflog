import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppWidgetService {
  // Ce nom doit correspondre à celui configuré dans le code natif
  static const platform = MethodChannel('com.aerolog.app/widget');

  // --- PERSISTANCE : _loadState() ---
  // On récupère les données pour les envoyer au widget du téléphone
  static Future<void> updateWidgetData() async {
    final prefs = await SharedPreferences.getInstance();

    // On récupère tes stats actuelles
    int vols = prefs.getInt('total_vols') ?? 0;
    String lastDest = prefs.getString('last_destination') ?? "N/A";
    String username = prefs.getString('user_name') ?? "Pilote";

    try {
      // On envoie les données au système iOS/Android
      await platform.invokeMethod('updateWidget', {
        "vols": vols,
        "destination": lastDest,
        "username": username,
      });
    } on PlatformException catch (e) {
      print("Erreur mise à jour widget: ${e.message}");
    }
  }

  // --- PERSISTANCE : _onItemTapped() ---
  // À appeler chaque fois que tu ajoutes un vol
  static void onFlightAdded() {
    updateWidgetData();
  }
}