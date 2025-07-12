import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:learnity/theme/theme.dart';

class AdminPostTagPage extends StatefulWidget {
  const AdminPostTagPage({super.key});

  @override
  State<AdminPostTagPage> createState() => _AdminPostTagPageState();
}

class _AdminPostTagPageState extends State<AdminPostTagPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  String? _editingId;

  // Lấy danh sách tags
  Stream<QuerySnapshot> _getTags() {
    return _firestore.collection('post_tags').snapshots();
  }

  // Thêm hoặc cập nhật tag
  Future<void> _saveTag() async {
    String name = _nameController.text.trim();
    if (name.isEmpty) return;

    if (_editingId == null) {
      // Thêm mới
      await _firestore.collection('post_tags').add({'name': name});
    } else {
      // Cập nhật
      await _firestore.collection('post_tags').doc(_editingId).update({
        'name': name,
      });
    }

    _nameController.clear();
    setState(() {
      _editingId = null;
    });
  }

  // Xóa tag
  Future<void> _deleteTag(String id) async {
    await _firestore.collection('post_tags').doc(id).delete();
  }

  // Chọn tag để chỉnh sửa
  void _editTag(DocumentSnapshot tag) {
    _nameController.text = tag['name'];
    setState(() {
      _editingId = tag.id;
    });
  }

  // Huỷ chỉnh sửa
  void _cancelEdit() {
    _nameController.clear();
    setState(() {
      _editingId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(false),
      appBar: AppBar(
        title: const Text(
          'Quản lý Tag Bài Viết',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Tên tag'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveTag,
                  child: Text(_editingId == null ? 'Thêm' : 'Cập nhật'),
                ),
                if (_editingId != null)
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: _cancelEdit,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Danh sách tags
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getTags(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Text('Lỗi tải dữ liệu');
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final tags = snapshot.data!.docs;
                  if (tags.isEmpty) return const Text('Chưa có tag nào.');

                  return ListView.builder(
                    itemCount: tags.length,
                    itemBuilder: (context, index) {
                      final tag = tags[index];
                      return ListTile(
                        title: Text(tag['name']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editTag(tag),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTag(tag.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
