import 'dart:convert';
import 'package:http/http.dart' as http;

class IAService {
  static const String _apiKey = "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";

  // NOUVEAU MODÈLE : Plus stable et plus récent (Mistral-Nemo)
  static const String _modelUrl = "https://api-inference.huggingface.co/models/mistralai/Mistral-Nemo-Instruct-2407";

  static Future<String> chatWithAI(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_modelUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "inputs": "<s>[INST] Tu es l'assistant expert AeroLog. Réponds en français de manière concise. Question: $message [/INST]",
          "parameters": {
            "max_new_tokens": 500,
            "temperature": 0.7,
            "top_p": 0.95,
          },
          "options": {
            "wait_for_model": true, // Très important pour éviter les erreurs de chargement
            "use_cache": true
          }
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        String text = data[0]['generated_text'] ?? "";

        // On nettoie pour ne pas afficher le rappel de la question
        if (text.contains("[/INST]")) {
          text = text.split("[/INST]").last.trim();
        }
        return text;
      } else if (response.statusCode == 503 || response.statusCode == 429) {
        return "L'IA prépare son plan de vol (chargement)... Réessaie dans quelques secondes.";
      } else if (response.statusCode == 410) {
        return "Erreur 410 : Le modèle est en maintenance. Je tente une reconnexion...";
      } else {
        return "Zone de turbulences (Erreur ${response.statusCode}). Réessaie bientôt.";
      }
    } catch (e) {
      return "Connexion perdue. Vérifie ton accès internet.";
    }
  }
}