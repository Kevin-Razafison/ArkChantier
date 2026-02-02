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
}