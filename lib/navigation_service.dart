import 'package:flutter/material.dart';

class NavigationService {
  // Cette liste mémorise l'ordre des onglets visités
  static final List<int> _history = [0];

  static Future<int> handleTabSwitch(int index, int currentIndex, Function updateData) async {
    if (index == currentIndex) return currentIndex;
    _history.add(index);
    await updateData(); // Persistance
    return index;
  }

  // --- MISE À JOUR : Gestion intelligente du retour ---
  static int handleBackPress(int currentIndex, Function updateData, {bool isFormulaireVisible = false, Function? onBackToDate}) {

    // 1. Si on est sur le formulaire (étape 2 du vol), on revient à la date (étape 1)
    if (currentIndex == 1 && isFormulaireVisible && onBackToDate != null) {
      onBackToDate(); // Cette fonction doit repasser ton booléen 'showForm' à false
      return 1; // On reste sur l'onglet 1 (Enregistrer), mais l'affichage change
    }

    // 2. Sinon, on utilise l'historique classique des onglets
    if (_history.length > 1) {
      _history.removeLast(); // On retire l'onglet actuel
      updateData();
      return _history.last; // On revient au précédent
    }

    return 0; // Retour par défaut à l'accueil (onglet 0)
  }

  static Future<void> goTo(BuildContext context, Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  static void goBack(BuildContext context, {Function? onRefresh}) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      if (onRefresh != null) onRefresh();
    }
  }

  static void replaceWith(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}