enum UserRole {
  client,
  ouvrier, // Ajouté pour correspondre à ton Login et Main
  chefChantier,
  chefProjet,
}

class UserModel {
  final String id;
  final String nom;
  final String email;
  final UserRole role;
  final String? chantierId;

  UserModel({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    this.chantierId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'email': email,
    'role': role.index,
    'chantierId': chantierId,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '0',
      nom: json['nom'] ?? 'Inconnu',
      email: json['email'] ?? '',
      role:
          UserRole.values[(json['role'] is int &&
                  json['role'] < UserRole.values.length)
              ? json['role']
              : 0],
      chantierId: json['chantierId'],
    );
  }
  static UserModel mockAdmin() => UserModel(
    id: '1',
    nom: 'Jean Projet',
    email: 'admin@btp.com',
    role: UserRole.chefProjet,
  );
}
