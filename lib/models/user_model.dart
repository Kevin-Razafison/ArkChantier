import '../services/encryption_service.dart';

enum UserRole { chefProjet, chefDeChantier, client, ouvrier }

class UserModel {
  final String id;
  final String nom;
  final String email;
  final UserRole role;
  final List<String> assignedIds; // Liste d'IDs de projets ou chantiers
  final String passwordHash;
  final String? firebaseUid;
  final bool disabled;

  UserModel({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    List<String>? assignedIds,
    required this.passwordHash,
    this.firebaseUid,
    this.disabled = false,
  }) : assignedIds = assignedIds ?? [];

  // ============ GETTERS DE COMPATIBILITÉ ============

  /// Getter pour compatibilité avec l'ancien code utilisant assignedId (singulier)
  /// Retourne le premier ID assigné ou null si la liste est vide
  String? get assignedId => assignedIds.isEmpty ? null : assignedIds.first;

  /// Liste des IDs de projets assignés (pour les admins qui gèrent plusieurs projets)
  List<String> get assignedProjectIds {
    if (role == UserRole.chefProjet) {
      return assignedIds; // Les admins ont tous leurs projets dans assignedIds
    }
    return [];
  }

  /// ID du projet assigné pour les clients (retourne le premier projet)
  String? get assignedProjectId {
    if (role == UserRole.client && assignedIds.isNotEmpty) {
      return assignedIds.first;
    }
    return null;
  }

  /// ID du chantier assigné pour les ouvriers et chefs de chantier
  String? get assignedChantierId {
    if ((role == UserRole.ouvrier || role == UserRole.chefDeChantier) &&
        assignedIds.isNotEmpty) {
      return assignedIds.first;
    }
    return null;
  }

  // ============ MÉTHODES UTILITAIRES ============

  /// Vérifie si l'utilisateur est assigné à un projet spécifique
  bool isAssignedToProject(String projectId) {
    return assignedIds.contains(projectId);
  }

  /// Vérifie si l'utilisateur est assigné à un chantier spécifique
  bool isAssignedToChantier(String chantierId) {
    return assignedIds.contains(chantierId);
  }

  /// Ajoute une assignation (projet ou chantier)
  UserModel assignTo(String id) {
    if (assignedIds.contains(id)) return this;

    return UserModel(
      id: this.id,
      nom: nom,
      email: email,
      role: role,
      assignedIds: [...assignedIds, id],
      passwordHash: passwordHash,
      firebaseUid: firebaseUid,
      disabled: disabled,
    );
  }

  /// Retire une assignation
  UserModel unassignFrom(String id) {
    return UserModel(
      id: this.id,
      nom: nom,
      email: email,
      role: role,
      assignedIds: assignedIds.where((aid) => aid != id).toList(),
      passwordHash: passwordHash,
      firebaseUid: firebaseUid,
      disabled: disabled,
    );
  }

  /// Remplace toutes les assignations (utile pour migration)
  UserModel withAssignedIds(List<String> newIds) {
    return UserModel(
      id: id,
      nom: nom,
      email: email,
      role: role,
      assignedIds: newIds,
      passwordHash: passwordHash,
      firebaseUid: firebaseUid,
      disabled: disabled,
    );
  }

  // ============ SERIALIZATION ============

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'email': email,
    'role': role.name,
    'assignedIds': assignedIds,
    'passwordHash': passwordHash,
    'firebaseUid': firebaseUid,
    'disabled': disabled,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Résolution du rôle
    final roleData = json['role'];
    UserRole resolvedRole;

    if (roleData is int) {
      resolvedRole = UserRole.values[roleData];
    } else if (roleData is String) {
      resolvedRole = UserRole.values.firstWhere(
        (e) => e.name == roleData,
        orElse: () => UserRole.ouvrier,
      );
    } else {
      resolvedRole = UserRole.ouvrier;
    }

    // Résolution des assignations (support ancien format assignedId)
    List<String> assignedIds = [];

    if (json['assignedIds'] is List) {
      // Nouveau format
      assignedIds = List<String>.from(json['assignedIds']);
    } else if (json['assignedProjectIds'] is List) {
      // Format alternatif
      assignedIds = List<String>.from(json['assignedProjectIds']);
    } else if (json['assignedId'] != null) {
      // Ancien format (migration)
      assignedIds = [json['assignedId'] as String];
    }

    return UserModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      email: json['email'] ?? '',
      role: resolvedRole,
      assignedIds: assignedIds,
      passwordHash: json['passwordHash'] ?? '',
      firebaseUid: json['firebaseUid'],
      disabled: json['disabled'] ?? false,
    );
  }

  // ============ HELPERS ============

  bool get isClient => role == UserRole.client;
  bool get isAdmin => role == UserRole.chefProjet;
  bool get isForeman => role == UserRole.chefDeChantier;
  bool get isWorker => role == UserRole.ouvrier;

  static UserModel mockAdmin({List<String> assignedIds = const []}) {
    return UserModel(
      id: 'admin_default',
      nom: 'Administrateur ARK',
      email: 'admin@ark.com',
      role: UserRole.chefProjet,
      assignedIds: assignedIds,
      passwordHash: EncryptionService.hashPassword("admin123"),
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, nom: $nom, role: ${role.name}, assignedIds: $assignedIds)';
  }
}
