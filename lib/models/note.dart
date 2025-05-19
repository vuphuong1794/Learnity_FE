class Note {
  final String id;
  final String title;
  final String subtitle;
  final String time;

  Note({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    title: json['title'] as String,
    subtitle: json['subtitle'] as String,
    time: json['time'] as String,
  );

  // Note -> JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'time': time,
  };
}
