import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AeroLogWidgetManager {
  // Remplace par ton identifiant de groupe si tu es sur iOS (ex: group.aerolog.app)
  static const String appGroupId = 'group.aerolog.data';
  static const String androidWidgetName = 'AeroLogWidgetProvider';
  static const String iosWidgetName = 'AeroLogWidget';

  // --- PERSISTANCE : _loadState() ---
  // Cette fonction prend tes données de l'app et les pousse vers le widget
  static Future<void> updateHomeScreenWidget() async {
    final prefs = await SharedPreferences.getInstance();

    // Récupération des données réelles
    int totalVols = prefs.getInt('total_vols') ?? 0;
    String username = prefs.getString('user_name') ?? "Pilote";
    String derniereDest = prefs.getString('last_destination') ?? "N/A";

    try {
      // On écrit les données dans le stockage partagé du Widget
      await HomeWidget.saveWidgetData<String>('widget_user', username);
      await HomeWidget.saveWidgetData<int>('widget_vols', totalVols);
      await HomeWidget.saveWidgetData<String>('widget_dest', derniereDest);

      // On demande au système de rafraîchir l'affichage du widget
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iosWidgetName,
      );
    } on PlatformException catch (e) {
      print("Erreur Widget: ${e.message}");
    }
  }

  // --- PERSISTANCE : _onItemTapped() ---
  // Appelle cette fonction dès qu'un vol est ajouté pour que le widget change instantanément
  static void refreshAfterAction() {
    updateHomeScreenWidget();
  }
}