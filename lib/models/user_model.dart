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
  final String?
  assignedProjectId; // NOUVEAU: ID du projet assigné spécifiquement

  UserModel({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    List<String>? assignedIds,
    required this.passwordHash,
    this.firebaseUid,
    this.disabled = false,
    this.assignedProjectId, // NOUVEAU
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

  /// ID du projet assigné (priorité: assignedProjectId, puis premier assignedIds pour client)
  String? get assignedProjectIdValue {
    // 1. Si assignedProjectId est défini, l'utiliser (priorité)
    if (assignedProjectId != null && assignedProjectId!.isNotEmpty) {
      return assignedProjectId;
    }

    // 2. Pour les clients, utiliser le premier assignedIds
    if (role == UserRole.client && assignedIds.isNotEmpty) {
      return assignedIds.first;
    }

    // 3. Pour les autres rôles, null
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
    // Vérifier assignedProjectId d'abord
    if (assignedProjectId == projectId) return true;

    // Vérifier dans assignedIds
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
      assignedProjectId: assignedProjectId, // Conserver l'ID de projet
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
      assignedProjectId: assignedProjectId,
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
      assignedProjectId: assignedProjectId,
    );
  }

  /// Définit l'ID du projet assigné
  UserModel withAssignedProjectId(String? projectId) {
    return UserModel(
      id: id,
      nom: nom,
      email: email,
      role: role,
      assignedIds: assignedIds,
      passwordHash: passwordHash,
      firebaseUid: firebaseUid,
      disabled: disabled,
      assignedProjectId: projectId,
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
    'assignedProjectId': assignedProjectId, // NOUVEAU
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
      assignedProjectId: json['assignedProjectId'], // NOUVEAU
    );
  }

  // ============ HELPERS ============

  bool get isClient => role == UserRole.client;
  bool get isAdmin => role == UserRole.chefProjet;
  bool get isForeman => role == UserRole.chefDeChantier;
  bool get isWorker => role == UserRole.ouvrier;

  static UserModel mockAdmin({List<String> assignedIds = const []}) {
    return UserModel(
      id: 'temp_admin',
      nom: 'Admin Temporaire',
      email: 'temp@ark.com',
      role: UserRole.chefProjet,
      assignedIds: assignedIds,
      passwordHash: EncryptionService.hashPassword("temp123"),
      assignedProjectId: null,
      disabled: true, // Marquer comme désactivé
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, nom: $nom, role: ${role.name}, assignedIds: $assignedIds, assignedProjectId: $assignedProjectId)';
  }

  factory UserModel.adminFromFirebase(
    String firebaseUid,
    String email,
    String nom,
  ) {
    return UserModel(
      id: firebaseUid,
      nom: nom,
      email: email,
      role: UserRole.chefProjet,
      assignedIds: [],
      passwordHash: '',
      firebaseUid: firebaseUid,
      disabled: false,
    );
  }
}
