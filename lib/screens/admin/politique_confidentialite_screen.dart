import 'package:flutter/material.dart';

class PolitiqueConfidentialiteScreen extends StatelessWidget {
  const PolitiqueConfidentialiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Politique de Confidentialité"),
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
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.privacy_tip,
                      color: Colors.purple,
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
                            "Protection de vos Données Personnelles",
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

          // Introduction
          _buildSection(
            isDark,
            "Introduction",
            """ARK Chantier s'engage à protéger la vie privée de ses utilisateurs.

Cette Politique de Confidentialité explique :
• Quelles données nous collectons
• Comment nous les utilisons
• Comment nous les protégeons
• Vos droits concernant vos données

En utilisant ARK Chantier, vous acceptez les pratiques décrites dans cette politique.""",
          ),

          // Section 1
          _buildSection(
            isDark,
            "1. Responsable du Traitement",
            """ARK Chantier
Application de gestion de chantiers
Email : privacy@arkchantier.com
Localisation : Madagascar

Le responsable du traitement est l'entité qui détermine les finalités et les moyens du traitement de vos données personnelles.""",
          ),

          // Section 2
          _buildSection(
            isDark,
            "2. Données Collectées",
            """2.1 Données d'Identification
• Nom complet
• Adresse email
• Rôle dans le projet (Chef de Projet, Chef de Chantier, Ouvrier, Client)
• Mot de passe (stocké de manière chiffrée)

2.2 Données Professionnelles
• Projets assignés
• Chantiers de travail
• Spécialité professionnelle (pour les ouvriers)
• Salaire (journalier ou mensuel)

2.3 Données de Localisation
• Localisation des chantiers
• Coordonnées GPS des sites de construction

2.4 Données de Pointage
• Heures d'arrivée et de départ
• Jours de présence
• Absences et congés

2.5 Données Financières
• Informations de paie
• Budgets de projets
• Dépenses et reçus

2.6 Données de Contenu
• Photos de chantier
• Rapports de travail
• Documents téléchargés
• Messages de chat
• Signalements d'incidents

2.7 Données Techniques
• Type d'appareil
• Système d'exploitation
• Version de l'application
• Logs d'erreurs
• Données de synchronisation""",
          ),

          // Section 3
          _buildSection(
            isDark,
            "3. Finalités du Traitement",
            """Nous collectons et utilisons vos données pour :

3.1 Gestion de Compte
• Créer et gérer votre compte utilisateur
• Authentifier votre identité
• Personnaliser votre expérience

3.2 Fonctionnement du Service
• Assigner des projets et chantiers
• Suivre la présence et le pointage
• Générer des rapports
• Calculer les paies
• Gérer les stocks et matériels

3.3 Communication
• Envoyer des notifications importantes
• Faciliter la communication entre utilisateurs
• Répondre à vos demandes de support

3.4 Amélioration du Service
• Analyser l'utilisation de l'application
• Corriger les bugs
• Développer de nouvelles fonctionnalités

3.5 Conformité Légale
• Respecter nos obligations légales
• Répondre aux demandes des autorités
• Protéger nos droits légaux""",
          ),

          // Section 4
          _buildSection(
            isDark,
            "4. Base Légale du Traitement",
            """Nous traitons vos données sur la base de :

• Contrat : Nécessaire pour fournir le service
• Intérêt légitime : Amélioration du service et sécurité
• Consentement : Pour certaines fonctionnalités optionnelles
• Obligation légale : Conformité aux lois applicables""",
          ),

          // Section 5
          _buildSection(
            isDark,
            "5. Stockage des Données",
            """5.1 Stockage Local (Offline-First)
• Les données sont stockées localement sur votre appareil
• Utilisation de SharedPreferences (Android/iOS)
• Chiffrement des données sensibles
• Accès restreint aux données de l'application

5.2 Stockage Cloud (Firebase)
• Synchronisation avec Firebase Firestore
• Serveurs situés dans les centres de données Google
• Chiffrement en transit (HTTPS/TLS)
• Chiffrement au repos
• Redondance et sauvegardes automatiques

5.3 Authentification
• Firebase Authentication
• Mots de passe hachés avec bcrypt
• Tokens de session sécurisés
• Authentification à deux facteurs (option future)""",
          ),

          // Section 6
          _buildSection(
            isDark,
            "6. Partage des Données",
            """6.1 Au sein de l'Application
Vos données sont visibles par :

• Chef de Projet : Accès complet à toutes les données
• Chef de Chantier : Données de son chantier uniquement
• Ouvriers : Leurs propres données et informations de chantier
• Clients : Progression de leur projet uniquement

6.2 Fournisseurs de Services
Nous partageons des données avec :

• Firebase (Google) : Hébergement et authentification
• Fournisseurs de stockage cloud : Sauvegarde
• Services d'analyse : Amélioration de l'application

6.3 Autorités
Nous pouvons divulguer vos données si :

• Requis par la loi
• Nécessaire pour protéger nos droits
• En cas d'urgence de sécurité publique

6.4 Nous ne vendons JAMAIS vos données à des tiers.""",
          ),

          // Section 7
          _buildSection(
            isDark,
            "7. Durée de Conservation",
            """• Compte actif : Données conservées tant que le compte existe
• Après résiliation : 90 jours puis suppression
• Données financières : 5 ans (obligation légale)
• Logs techniques : 12 mois maximum
• Sauvegardes : 30 jours

Vous pouvez demander la suppression de vos données à tout moment.""",
          ),

          // Section 8
          _buildSection(
            isDark,
            "8. Sécurité des Données",
            """Nous mettons en œuvre des mesures de sécurité techniques et organisationnelles :

Mesures Techniques :
✓ Chiffrement des données sensibles (AES-256)
✓ Connexions sécurisées (HTTPS/TLS)
✓ Authentification forte
✓ Contrôles d'accès basés sur les rôles
✓ Logs de sécurité et surveillance
✓ Sauvegardes régulières chiffrées

Mesures Organisationnelles :
✓ Formation du personnel
✓ Accès restreint aux données
✓ Politique de mots de passe forts
✓ Audits de sécurité réguliers
✓ Plan de réponse aux incidents

Cependant, aucun système n'est totalement sécurisé. Vous devez :
• Protéger vos identifiants
• Ne pas partager votre compte
• Utiliser un mot de passe fort
• Signaler toute activité suspecte""",
          ),

          // Section 9
          _buildSection(
            isDark,
            "9. Vos Droits",
            """Vous disposez des droits suivants :

9.1 Droit d'Accès
Obtenir une copie de vos données personnelles

9.2 Droit de Rectification
Corriger les données inexactes ou incomplètes

9.3 Droit à l'Effacement
Demander la suppression de vos données

9.4 Droit à la Limitation
Restreindre le traitement de vos données

9.5 Droit à la Portabilité
Recevoir vos données dans un format structuré

9.6 Droit d'Opposition
Vous opposer au traitement de vos données

9.7 Droit de Retirer le Consentement
Retirer votre consentement à tout moment

Pour exercer vos droits :
• Email : privacy@arkchantier.com
• Dans l'application : Section "Paramètres > Confidentialité"
• Réponse sous 30 jours maximum""",
          ),

          // Section 10
          _buildSection(
            isDark,
            "10. Cookies et Technologies Similaires",
            """ARK Chantier n'utilise pas de cookies web traditionnels.

Technologies Utilisées :
• SharedPreferences : Stockage local des préférences
• Firebase Analytics : Analyse d'utilisation (anonymisée)
• Session Tokens : Authentification

Vous pouvez désactiver l'analyse dans les paramètres de l'application.""",
          ),

          // Section 11
          _buildSection(
            isDark,
            "11. Transferts Internationaux",
            """Vos données peuvent être transférées et stockées sur des serveurs situés en dehors de Madagascar.

Nous assurons un niveau de protection adéquat par :
• Utilisation de fournisseurs conformes (Google Firebase)
• Clauses contractuelles types
• Chiffrement des données en transit et au repos

Les serveurs Firebase sont principalement situés dans :
• Union Européenne
• États-Unis (avec garanties de protection)""",
          ),

          // Section 12
          _buildSection(
            isDark,
            "12. Mineurs",
            """ARK Chantier est destiné aux utilisateurs âgés de 18 ans et plus.

Nous ne collectons pas sciemment de données d'enfants de moins de 18 ans.

Si vous pensez qu'un mineur a fourni des données :
• Contactez-nous immédiatement
• Nous supprimerons ces données rapidement""",
          ),

          // Section 13
          _buildSection(
            isDark,
            "13. Modifications de la Politique",
            """Nous pouvons modifier cette Politique de Confidentialité.

En cas de changements importants :
• Notification dans l'application
• Email aux utilisateurs enregistrés
• Nouvelle acceptation requise pour changements substantiels

Date d'effet : 30 jours après notification

Consultez régulièrement cette page pour rester informé.""",
          ),

          // Section 14
          _buildSection(
            isDark,
            "14. Réclamations",
            """Si vous estimez que vos droits ne sont pas respectés :

1. Contactez-nous d'abord :
   privacy@arkchantier.com

2. Si non résolu, contactez l'autorité de protection des données de Madagascar

Nous nous engageons à résoudre toute plainte dans les 45 jours.""",
          ),

          // Section 15
          _buildSection(
            isDark,
            "15. Contact",
            """Pour toute question sur cette Politique :

Email : privacy@arkchantier.com
Support : support@arkchantier.com

Application : Paramètres > Aide & Support

Délai de réponse : 72 heures ouvrées maximum""",
          ),

          const SizedBox(height: 24),

          // Footer - Engagement
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Notre Engagement",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Nous nous engageons à protéger vos données personnelles et à respecter votre vie privée. Votre confiance est notre priorité.",
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
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
              color: isDark ? Colors.white : Colors.purple.shade700,
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
