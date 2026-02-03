class Report {
  final String id;
  final String chantierId;
  final String comment;
  final String imagePath;
  final DateTime date;

  Report({
    required this.id,
    required this.chantierId,
    required this.comment,
    required this.imagePath,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'chantierId': chantierId,
    'comment': comment,
    'imagePath': imagePath,
    'date': date.toIso8601String(),
  };

  factory Report.fromJson(Map<String, dynamic> json) => Report(
    id: json['id'],
    chantierId: json['chantierId'],
    comment: json['comment'],
    imagePath: json['imagePath'],
    date: DateTime.parse(json['date']),
  );
}
