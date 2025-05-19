import 'package:flutter/material.dart';
import '../../../../models/note_setion.dart';
import 'NoteDetailPage.dart';

class Notecard extends StatelessWidget {
  final NoteSection section;

  const Notecard({Key? key, required this.section}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ...section.notes.map(
                (note) => Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              color: Colors.white.withOpacity(0.7),
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  note.title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  note.time +" "+ note.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoteDetailPage(note: note),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
