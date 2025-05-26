import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:learnity/theme/theme.dart';
import '../../navigation_menu.dart';

class SetUsernameScreen extends StatefulWidget {
  final String userId;
  final String? displayName;
  final String? initialEmail;
  final String? avatarUrl;

  const SetUsernameScreen({
    super.key,
    required this.userId,
    this.displayName,
    this.initialEmail,
    this.avatarUrl,
  });

  @override
  State<SetUsernameScreen> createState() => _SetUsernameScreenState();
}

class _SetUsernameScreenState extends State<SetUsernameScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _hintUsername;

  // Biến trạng thái để xác thực thời gian thực
  Timer? _debounce;
  bool _isCheckingUsernameRealtime = false;
  bool? _isUsernameAvailableRealtime;
  String _usernameAvailabilityMessage = '';
  String _lastCheckedUsernameRealtime = '';

  @override
  void initState() {
    super.initState();
    final email = widget.initialEmail?.split('@')[0] ?? 'user';
    final randomnumber = (Random().nextInt(900) + 100).toString();
    _hintUsername = "$email$randomnumber";
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _usernameFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  //hàm xử lý mỗi khi người dùng nhập hoặc thay đổi tên người dùng
  void _onUsernameChanged(String username) {
    //Trước khi đặt Timer mới, huỷ cái cũ nếu còn hoạt động => tránh gọi kiểm tra Firestore liên tục khi người dùng gõ nhanh.
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty) {
      if (mounted) {
        setState(() {
          _isUsernameAvailableRealtime = null;
          _usernameAvailabilityMessage = '';
          _isCheckingUsernameRealtime = false;
        });
      }
    } else if (trimmedUsername.length < 3) {
      if (mounted) {
        setState(() {
          _usernameAvailabilityMessage =
              'Tên người dùng quá ngắn (tối thiểu 3 ký tự).';
          _isUsernameAvailableRealtime = false;
          _isCheckingUsernameRealtime = false;
        });
      }
    } else if (trimmedUsername.contains(' ')) {
      if (mounted) {
        setState(() {
          _usernameAvailabilityMessage =
              'Tên người dùng không được chứa khoảng trắng.';
          _isUsernameAvailableRealtime = false;
          _isCheckingUsernameRealtime = false;
        });
      }
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmedUsername)) {
      if (mounted) {
        setState(() {
          _usernameAvailabilityMessage =
              'Chỉ chứa chữ cái, số, và dấu gạch dưới (_).';
          _isUsernameAvailableRealtime = false;
          _isCheckingUsernameRealtime = false;
        });
      }
    } else {
      // Nếu hợp lệ → chuyển sang trạng thái "đang kiểm tra"
      if (mounted &&
          _usernameAvailabilityMessage.isNotEmpty &&
          _isUsernameAvailableRealtime == false) {
        setState(() {
          _usernameAvailabilityMessage = 'Đang kiểm tra...';
          _isCheckingUsernameRealtime = true;
        });
      }
    }

    // kiểm tra ngay bên client
    _formKey.currentState?.validate();
    //kiểm tra username trên db
    _debounce = Timer(const Duration(milliseconds: 600), () {
      final currentTrimmedUsername = _usernameController.text.trim();
      if (!mounted) return;
      if (currentTrimmedUsername.isEmpty) {
        setState(() {
          _usernameAvailabilityMessage = '';
          _isUsernameAvailableRealtime = null;
          _isCheckingUsernameRealtime = false;
        });
        return;
      }
      // Kiểm tra cú pháp lại một lần nữa
      //Đảm bảo người dùng không chỉnh sửa thành sai cú pháp trong lúc chờ debounce.
      if (currentTrimmedUsername.length < 3 ||
          currentTrimmedUsername.contains(' ') ||
          !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(currentTrimmedUsername)) {
        if (_isCheckingUsernameRealtime) {
          setState(() {
            _isCheckingUsernameRealtime = false;
          });
        }
        return;
      }
      // Nếu tên đã được kiểm tra trước đó => bỏ qua
      if (_lastCheckedUsernameRealtime == currentTrimmedUsername &&
          _isUsernameAvailableRealtime != null &&
          !_isCheckingUsernameRealtime) {
        return;
      }
      _performRealtimeUsernameCheck(currentTrimmedUsername);
    });
  }

  //Kiểm tra realtime xem tên người dùng đã tồn tại trong Firestore
  Future<void> _performRealtimeUsernameCheck(String username) async {
    if (!mounted) return;
    setState(() {
      _isCheckingUsernameRealtime = true;
      _usernameAvailabilityMessage = 'Đang kiểm tra...';
      _isUsernameAvailableRealtime = null;
      _lastCheckedUsernameRealtime = username;
    });

    try {
      final usersRef = FirebaseFirestore.instance.collection('users');
      QuerySnapshot usernameQuery =
          await usersRef.where("username", isEqualTo: username).limit(1).get();

      if (!mounted) return;

      if (usernameQuery.docs.isNotEmpty &&
          usernameQuery.docs.first.id != widget.userId) {
        setState(() {
          _isUsernameAvailableRealtime = false;
          _usernameAvailabilityMessage = 'Tên người dùng này đã được sử dụng.';
        });
      } else {
        setState(() {
          _isUsernameAvailableRealtime = true;
          _usernameAvailabilityMessage = 'Tên người dùng có thể sử dụng!';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUsernameAvailableRealtime = null;
        _usernameAvailabilityMessage = 'Lỗi kiểm tra tên người dùng.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUsernameRealtime = false;
        });
        _formKey.currentState?.validate();
      }
    }
  }

  // update username lên firestore
  Future<void> _submitUsername() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUsername = _usernameController.text.trim();
    if (currentUsername == _lastCheckedUsernameRealtime &&
        _isUsernameAvailableRealtime == false) {
      _showSnackBar(
        _usernameAvailabilityMessage.isNotEmpty
            ? _usernameAvailabilityMessage
            : "Tên người dùng đã được sử dụng.",
        Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);
    final username = _usernameController.text.trim();

    try {
      final usersRef = FirebaseFirestore.instance.collection('users');
      QuerySnapshot usernameQuery =
          await usersRef.where("username", isEqualTo: username).limit(1).get();
      if (usernameQuery.docs.isNotEmpty &&
          usernameQuery.docs.first.id != widget.userId) {
        _showSnackBar(
          "Tên người dùng này đã được sử dụng. Vui lòng chọn tên khác.",
          Colors.orange,
        );
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      await usersRef.doc(widget.userId).update({"username": username});

      _showSnackBar("Tên người dùng đã được thiết lập!", Colors.green);
      Get.offAll(() => const NavigationMenu());
    } catch (e) {
      _showSnackBar(
        "Lỗi khi thiết lập tên người dùng: ${e.toString()}",
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Nhập Tên Người Dùng"),
        centerTitle: true,
        backgroundColor: AppColors.buttonBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Chào mừng, ${widget.displayName ?? widget.initialEmail?.split('@')[0] ?? 'bạn'}!",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF093B29),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Vui lòng chọn một tên người dùng để hoàn tất đăng ký.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _usernameController,
                    focusNode: _usernameFocus,
                    onChanged: _onUsernameChanged,
                    decoration: InputDecoration(
                      labelText: "Tên người dùng",
                      hintText:
                          _hintUsername != null
                              ? "ví dụ: $_hintUsername"
                              : "Nhập tên người dùng",
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage:
                              (widget.avatarUrl != null &&
                                      widget.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(widget.avatarUrl!)
                                  : null,
                          child:
                              (widget.avatarUrl == null ||
                                      widget.avatarUrl!.isEmpty)
                                  ? Icon(
                                    Icons.person,
                                    size: 18,
                                    color: Colors.grey.shade600,
                                  )
                                  : null,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      final trimmedValue = value?.trim();
                      if (trimmedValue == null || trimmedValue.isEmpty) {
                        return "Tên người dùng không được để trống.";
                      }
                      if (trimmedValue.length < 3) {
                        return "Tên người dùng phải có ít nhất 3 ký tự.";
                      }
                      if (trimmedValue.contains(' ')) {
                        return "Tên người dùng không được chứa khoảng trắng.";
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmedValue)) {
                        return "Chỉ chứa chữ cái, số, và dấu gạch dưới (_).";
                      }
                      if (_lastCheckedUsernameRealtime == trimmedValue &&
                          _isUsernameAvailableRealtime == false &&
                          _usernameAvailabilityMessage.isNotEmpty &&
                          _usernameAvailabilityMessage != 'Đang kiểm tra...') {
                        return _usernameAvailabilityMessage;
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitUsername(),
                  ),
                  if (_usernameAvailabilityMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8.0,
                        left: 12.0,
                        right: 12.0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_isCheckingUsernameRealtime)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (_isUsernameAvailableRealtime == true)
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: 18,
                            )
                          else if (_isUsernameAvailableRealtime == false)
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 18,
                            )
                          else
                            SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _usernameAvailabilityMessage,
                              style: TextStyle(
                                color:
                                    _isUsernameAvailableRealtime == true
                                        ? Colors.green
                                        : (_isUsernameAvailableRealtime == false
                                            ? Colors.red
                                            : Colors.grey.shade700),
                                fontSize: 12,
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20), // Adjusted spacing
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitUsername,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonBg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                            : const Text(
                              "Hoàn tất",
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.buttonText,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
