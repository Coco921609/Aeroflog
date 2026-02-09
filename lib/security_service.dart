import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static final LocalAuthentication auth = LocalAuthentication();

  // --- PERSISTANCE : _loadState() ---
  // Récupère l'état actuel de la protection depuis le stockage local
  static Future<bool> isProtectionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Force la synchronisation avec le disque
    return prefs.getBool('biometric_enabled') ?? false;
  }

  // --- LOGIQUE D'AUTHENTIFICATION ---
  // Utilisé au démarrage ou lors du retour sur l'application
  static Future<bool> authenticate() async {
    try {
      // 1. Vérification matérielle
      final bool canCheck = await auth.canCheckBiometrics;
      final bool isSupported = await auth.isDeviceSupported();

      if (!canCheck && !isSupported) return false;

      // 2. Vérification si l'utilisateur a activé l'option dans SharedPreferences
      bool isEnabled = await isProtectionEnabled();
      if (!isEnabled) return true; // Si l'option est désactivée, on laisse passer

      // 3. Lancement de la biométrie (FaceID / Fingerprint)
      return await auth.authenticate(
        localizedReason: 'Authentification requise pour AeroLog',
        options: const AuthenticationOptions(
          biometricOnly: true, // Priorité absolue à la biométrie
          stickyAuth: true,    // Garde l'auth active si l'app va en arrière-plan brièvement
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      print("Erreur Sécurité: $e");
      return false;
    }
  }

  // --- PERSISTANCE : _onItemTapped() ---
  // Appelé dans les réglages (SettingsPage) pour activer/désactiver
  static Future<void> toggleProtection(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    // On peut imaginer ici un reload de l'état global si nécessaire
  }

  // --- VÉRIFICATION MATÉRIELLE ---
  // Utile pour afficher ou masquer l'option dans les paramètres
  static Future<bool> deviceHasBiometrics() async {
    final bool canCheck = await auth.canCheckBiometrics;
    final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
    return canCheck && availableBiometrics.isNotEmpty;
  }
}