import 'package:flutter/material.dart';

class EngineStatWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const EngineStatWidget({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Carlingue extérieure du moteur
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.grey[800]!, Colors.black],
                  stops: const [0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(color: Colors.white24, width: 2),
              ),
            ),
            // Pales de la turbine (Effet visuel)
            RotationTransition(
              turns: const AlwaysStoppedAnimation(45 / 360),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.45, 0.5, 0.55],
                  ),
                ),
              ),
            ),
            // Centre du moteur avec l'icône
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A1A1A),
              ),
              child: Icon(icon, color: Colors.cyanAccent, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Texte sous le moteur
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          title,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }
}