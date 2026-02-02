class JournalEntry {
  final String id;
  final String date;
  final String contenu;
  final String auteur;
  final String? imagePath;

  JournalEntry({
    required this.id,
    required this.date,
    required this.contenu,
    required this.auteur,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'contenu': contenu,
    'auteur': auteur,
    'imagePath': imagePath,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'],
    date: json['date'],
    contenu: json['contenu'],
    auteur: json['auteur'],
    imagePath: json['imagePath'],
  );
}