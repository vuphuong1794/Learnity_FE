import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learnity/theme/theme.dart';
import 'package:permission_handler/permission_handler.dart';

class CreateGroup extends StatefulWidget {
  const CreateGroup({super.key});

  @override
  State<CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  File? _avatarImage;
  String _currentAvatarUrl = "";

  Future<void> _pickImage() async {
    try {
      PermissionStatus storageStatus = PermissionStatus.denied;
      PermissionStatus photosStatus = PermissionStatus.denied;

      if (Platform.isAndroid) {
        storageStatus = await Permission.storage.request();
      }

      photosStatus = await Permission.photos.request();

      if (storageStatus.isGranted || photosStatus.isGranted) {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (pickedFile != null && mounted) {
          setState(() {
            _avatarImage = File(pickedFile.path);
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng cấp quyền truy cập để chọn ảnh'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        if (storageStatus.isPermanentlyDenied ||
            photosStatus.isPermanentlyDenied) {
          await openAppSettings();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Tạo nhóm',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.black, height: 1.0),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Dismiss keyboard on tap
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn ảnh đại diện',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child:
                      _avatarImage == null
                          ? IconButton(
                            icon: const Icon(
                              Icons.add_a_photo,
                              size: 30,
                              color: Colors.grey,
                            ),
                            onPressed: _pickImage,
                          )
                          : GestureDetector(
                            onTap: _pickImage,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _avatarImage!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                ),
              ),

              const Text(
                'Tên nhóm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),

                  hintText: 'Đặt tên nhóm',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quyền riêng tư',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                value: 'Công khai',
                items: const [
                  DropdownMenuItem(
                    value: 'Công khai',
                    child: Text('Công khai'),
                  ),
                  DropdownMenuItem(value: 'Riêng tư', child: Text('Riêng tư')),
                ],
                onChanged: (value) {
                  if (kDebugMode) {
                    print('Selected privacy: $value');
                  }
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0x9EB9A8),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Logic to create group
                  },
                  child: const Text('Tạo nhóm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
