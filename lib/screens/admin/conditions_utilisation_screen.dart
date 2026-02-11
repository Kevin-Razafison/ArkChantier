import 'package:flutter/material.dart';

class ConditionsUtilisationScreen extends StatelessWidget {
  const ConditionsUtilisationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Conditions d'Utilisation"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A334D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1A334D).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.architecture,
                      color: const Color(0xFF1A334D),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ARK CHANTIER",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Conditions Générales d'Utilisation",
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: isDark ? Colors.white24 : Colors.black26),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.update,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Dernière mise à jour : 11 Février 2026",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 1
          _buildSection(
            isDark,
            "1. Acceptation des Conditions",
            """En accédant et en utilisant ARK Chantier (ci-après "l'Application"), vous acceptez d'être lié par les présentes Conditions Générales d'Utilisation.

Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser l'Application.""",
          ),

          // Section 2
          _buildSection(
            isDark,
            "2. Description du Service",
            """ARK Chantier est une application de gestion de chantiers de construction qui permet :

• La gestion de projets de construction
• Le suivi des équipes et du personnel
• La gestion des stocks et matériels
• Le suivi budgétaire et financier
• La communication entre les différents intervenants
• La génération de rapports et documents

L'Application fonctionne en mode "offline-first", permettant une utilisation même sans connexion internet avec synchronisation ultérieure.""",
          ),

          // Section 3
          _buildSection(
            isDark,
            "3. Types d'Utilisateurs",
            """L'Application distingue quatre types d'utilisateurs :

• Chef de Projet : Administration complète du système
• Chef de Chantier : Gestion opérationnelle du chantier
• Ouvrier : Consultation et pointage
• Client : Suivi de l'avancement du projet

Chaque type d'utilisateur dispose de droits et fonctionnalités spécifiques.""",
          ),

          // Section 4
          _buildSection(
            isDark,
            "4. Création de Compte",
            """Pour utiliser l'Application, vous devez :

• Être âgé d'au moins 18 ans
• Fournir des informations exactes et à jour
• Maintenir la confidentialité de vos identifiants
• Informer immédiatement l'administrateur en cas d'utilisation non autorisée

Seul un Chef de Projet peut créer des comptes utilisateurs.""",
          ),

          // Section 5
          _buildSection(
            isDark,
            "5. Utilisation Acceptable",
            """Vous vous engagez à :

✓ Utiliser l'Application uniquement à des fins professionnelles légitimes
✓ Respecter la confidentialité des données des autres utilisateurs
✓ Ne pas tenter d'accéder à des données non autorisées
✓ Maintenir l'exactitude des informations saisies
✓ Respecter les délais de pointage et de reporting

Vous vous engagez à ne pas :

✗ Partager vos identifiants avec des tiers
✗ Utiliser l'Application pour des activités illégales
✗ Tenter de contourner les mesures de sécurité
✗ Introduire des virus ou codes malveillants
✗ Copier ou modifier le code de l'Application""",
          ),

          // Section 6
          _buildSection(
            isDark,
            "6. Propriété Intellectuelle",
            """Tous les droits de propriété intellectuelle relatifs à ARK Chantier appartiennent à ses développeurs.

Vous obtenez une licence limitée, non exclusive et non transférable pour utiliser l'Application dans le cadre de votre activité professionnelle.

Vous ne pouvez pas :
• Copier, modifier ou distribuer l'Application
• Effectuer de l'ingénierie inverse
• Créer des œuvres dérivées""",
          ),

          // Section 7
          _buildSection(
            isDark,
            "7. Données et Confidentialité",
            """Vos données sont traitées conformément à notre Politique de Confidentialité.

L'Application collecte et traite :
• Données d'identification (nom, email)
• Données de localisation (chantiers)
• Données de pointage et présence
• Données financières (salaires, budgets)
• Photos et documents de chantier

Mode Offline :
Les données sont stockées localement sur votre appareil et synchronisées avec le cloud lorsqu'une connexion est disponible.""",
          ),

          // Section 8
          _buildSection(
            isDark,
            "8. Sécurité des Données",
            """Nous mettons en œuvre des mesures de sécurité appropriées :

• Chiffrement des données sensibles
• Authentification Firebase
• Stockage sécurisé local
• Synchronisation chiffrée
• Contrôles d'accès par rôle

Cependant, aucune transmission de données sur internet n'est totalement sécurisée. Vous utilisez l'Application à vos propres risques.""",
          ),

          // Section 9
          _buildSection(
            isDark,
            "9. Disponibilité du Service",
            """Nous nous efforçons de maintenir l'Application disponible 24h/24, 7j/7.

Toutefois, nous ne garantissons pas :
• Une disponibilité ininterrompue
• L'absence d'erreurs ou de bugs
• La compatibilité avec tous les appareils

Nous nous réservons le droit d'interrompre le service pour :
• Maintenance programmée
• Mises à jour de sécurité
• Corrections de bugs
• Améliorations techniques""",
          ),

          // Section 10
          _buildSection(
            isDark,
            "10. Limitations de Responsabilité",
            """Dans la mesure permise par la loi, ARK Chantier et ses développeurs ne seront pas responsables :

• Des pertes de données dues à des pannes techniques
• Des erreurs de saisie des utilisateurs
• Des décisions prises sur la base des informations de l'Application
• Des dommages indirects ou consécutifs
• De l'utilisation non autorisée de vos identifiants

L'Application est fournie "en l'état" sans garantie d'aucune sorte.""",
          ),

          // Section 11
          _buildSection(
            isDark,
            "11. Modifications des Conditions",
            """Nous nous réservons le droit de modifier ces Conditions à tout moment.

Les modifications prendront effet :
• Immédiatement pour les nouvelles fonctionnalités
• 30 jours après notification pour les changements substantiels

Votre utilisation continue de l'Application après modification constitue votre acceptation des nouvelles conditions.""",
          ),

          // Section 12
          _buildSection(
            isDark,
            "12. Résiliation",
            """Vous pouvez cesser d'utiliser l'Application à tout moment.

Nous pouvons suspendre ou résilier votre accès si :
• Vous violez ces Conditions
• Votre compte est inactif pendant plus de 12 mois
• Nous cessons de fournir le service
• Des raisons légales l'exigent

En cas de résiliation :
• Vos données locales restent sur votre appareil
• L'accès aux services cloud sera révoqué
• Les données peuvent être supprimées après 90 jours""",
          ),

          // Section 13
          _buildSection(
            isDark,
            "13. Loi Applicable",
            """Ces Conditions sont régies par les lois de Madagascar.

Tout litige sera soumis à la juridiction exclusive des tribunaux de Madagascar.""",
          ),

          // Section 14
          _buildSection(
            isDark,
            "14. Contact",
            """Pour toute question concernant ces Conditions, contactez :

Email : support@arkchantier.com
Application : Section "Aide & Support"

Nous nous engageons à répondre dans un délai de 72 heures ouvrées.""",
          ),

          const SizedBox(height: 24),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "En utilisant ARK Chantier, vous confirmez avoir lu, compris et accepté ces Conditions d'Utilisation.",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(bool isDark, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A334D),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
