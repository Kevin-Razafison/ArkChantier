🏗️ ArkChantier - Système de Gestion de Chantier SaaS

ArkChantier est une solution mobile complète de gestion de chantiers conçue pour les entreprises de construction. Elle permet une gestion centralisée du personnel, un suivi précis du pointage et une communication en temps réel, même en zone blanche (mode offline).
🚀 Fonctionnalités Clés

    Multi-Tenancy (SaaS) : Architecture isolée par adminId. Chaque entreprise gère ses propres données de manière totalement étanche.

    Authentification Hybride : Connexion sécurisée via Firebase Auth avec gestion des rôles (Chef de Projet, Chef de Chantier, Client, Ouvrier).

    Gestion du Personnel & Pointage : Système de pointage journalier (manuel ou via QR Code) pour un suivi précis de la main-d'œuvre.

    Dashboard Analytics : Visualisation des coûts, de l'avancement des travaux et des statistiques de présence en temps réel.

    Communication Cloud : Chat intégré par chantier utilisant Firebase Firestore pour une coordination fluide entre les équipes.

    Mode Offline (Persistance) : Fonctionne sans connexion internet. Les données sont synchronisées automatiquement dès le retour du réseau.

    Export PDF : Génération automatique de rapports de chantier détaillés (en cours d'implémentation).

🛠️ Stack Technique

    Framework : Flutter (Multi-plateforme Android/iOS/Web/Linux).

    Backend : Firebase (Authentication, Firestore Database).

    Stockage Local : SharedPreferences (préférences UI) & Firestore Persistence (données métier).

    Design : Material Design 3 avec support complet du Mode Sombre (Dark Mode).

📂 Structure du Projet (Domain-Driven)

Conformément à l'organisation par domaines, le code est segmenté pour une maintenabilité maximale :
Plaintext

lib/
├── models/         # Structures de données (User, Projet, Ouvrier, etc.)
├── screens/        # Écrans organisés par rôles (Admin, Worker, Login)
├── services/       # Logique métier (Encryption, DataStorage, Firebase)
├── widgets/        # Composants réutilisables (Sidebar, Cards, Dialogs)
└── main.dart       # Point d'entrée avec gestion de l'état global (Auto-Login)

⚙️ Installation & Configuration
Prérequis

    Flutter SDK (dernière version stable)

    Un projet Firebase configuré

Installation

    Cloner le dépôt :
    Bash

    git clone https://github.com/Kevin-Razafison/mon_chantier_app.git

    Installer les dépendances :
    Bash

    flutter pub get

    Configurer Firebase :

        Ajouter vos fichiers google-services.json (Android) et GoogleService-Info.plist (iOS).

        Ou utiliser flutterfire configure.

    Lancer l'application :
    Bash

    flutter run

🔒 Sécurité & Confidentialité

    Chiffrement : Les mots de passe sont hachés localement avant d'être traités (via EncryptionService).

    Filtrage Firestore : Chaque requête est bridée par le UID de l'administrateur propriétaire pour garantir la confidentialité entre les clients.

    Règles de sécurité Firebase : Accès restreint aux documents selon le rôle de l'utilisateur.

📈 Roadmap & Évolutions

    [x] Authentification & Rôles

    [x] Gestion du Personnel (SaaS Ready)

    [x] Chat en temps réel par chantier

    [x] Mode Sombre adaptatif

    [ ] Finalisation de l'export PDF des rapports

    [ ] Notifications Push pour les alertes de sécurité

    Note de développement : Ce projet a été conçu avec une approche agile, en mettant l'accent sur l'expérience utilisateur sur le terrain (interface simplifiée pour les ouvriers, lisibilité accrue sous le soleil).
