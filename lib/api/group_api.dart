import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:learnity/config.dart';
import 'package:learnity/models/group_post_model.dart';

// .env
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroupApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get _currentUser => _auth.currentUser;

  final Cloudinary cloudinary = Cloudinary.full(
    // apiKey: dotenv.env['CLOUDINARY_API_KEY2']!,
    // apiSecret: dotenv.env['CLOUDINARY_API_SECRET2']!,
    // cloudName: dotenv.env['CLOUDINARY_CLOUD_NAME2']!,
    apiKey: Config.cloudinaryApiKey2,
    apiSecret: Config.cloudinaryApiSecret2,
    cloudName: Config.cloudinaryCloudName2,
  );
  Future<Map<String, dynamic>?> loadGroupData(String groupId) async {
    final user = _currentUser;
    if (user == null) return null;

    final groupDoc =
        await _firestore.collection('communityGroups').doc(groupId).get();
    if (!groupDoc.exists) {
      return {
        'groupData': null,
        'recentPosts': <GroupPostModel>[],
        'groupMembers': <Map<String, dynamic>>[],
        'isMember': false,
        'isAdmin': false,
      };
    }

    final groupData = groupDoc.data()!;
    final membersList =
        (groupData['membersList'] as List<dynamic>? ?? [])
            .map((m) => Map<String, dynamic>.from(m))
            .toList();

    bool isMember = false;
    bool isAdmin = false;
    final memberData = membersList.firstWhere(
      (m) => m['uid'] == user.uid,
      orElse: () => {},
    );
    if (memberData.isNotEmpty) {
      isMember = true;
      isAdmin = memberData['isAdmin'] == true;
    }

    final postsSnapshot =
        await _firestore
            .collection('communityGroups')
            .doc(groupId)
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .get();
    final posts =
        postsSnapshot.docs
            .map((doc) => GroupPostModel.fromDocument(doc))
            .toList();

    return {
      'groupData': groupData,
      'recentPosts': posts,
      'groupMembers': membersList,
      'isMember': isMember,
      'isAdmin': isAdmin,
    };
  }

  //Xóa bài đăng nhóm
  Future<bool> deletePostGroup(
    String groupId,
    String postId,
    List<String>? imageUrls,
  ) async {
    final user = _currentUser;
    if (user == null) return false;

    final postRef = _firestore
        .collection('communityGroups')
        .doc(groupId)
        .collection('posts')
        .doc(postId);
    final postDoc = await postRef.get();
    if (!postDoc.exists ||
        (postDoc.data() as Map<String, dynamic>)['authorUid'] != user.uid) {
      return false;
    }

    try {
      if (imageUrls != null && imageUrls.isNotEmpty) {
        for (final url in imageUrls) {
          try {
            await _storage.refFromURL(url).delete();
          } catch (e) {
            print('Không thể xóa ảnh: $url - $e');
          }
        }
      }

      await postRef.delete();
      return true;
    } catch (e) {
      print("Error in API deletePostGroup: $e");
      return false;
    }
  }

  // Thích hoặc bỏ thích bài viết.
  Future<void> handleLikePost(
    String groupId,
    String postId,
    bool currentLikeStatus,
  ) async {
    final user = _currentUser;
    if (user == null) return;

    final postRef = _firestore
        .collection('communityGroups')
        .doc(groupId)
        .collection('posts')
        .doc(postId);
    if (currentLikeStatus) {
      await postRef.update({
        'likedBy': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await postRef.update({
        'likedBy': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  // Tham gia nhóm hoặc gửi yêu cầu.
  Future<String> joinGroupInternally(
    String groupId,
    Map<String, dynamic> groupData,
  ) async {
    final user = _currentUser;
    if (user == null) return "error_not_logged_in";

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception("User document not found.");

      if (groupData['privacy'] == 'Riêng tư') {
        await _firestore
            .collection('communityGroups')
            .doc(groupId)
            .collection('join_requests')
            .doc(user.uid)
            .set({});
        return "request_sent";
      } else {
        await _firestore.collection('communityGroups').doc(groupId).update({});
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('communityGroups')
            .doc(groupId)
            .set({});
        return "joined_successfully";
      }
    } catch (e) {
      print("Error in API joinGroupInternally: $e");
      return "error_unknown";
    }
  }

  // Rời khỏi nhóm.
  Future<String> leaveGroup(String groupId) async {
    final user = _currentUser;
    if (user == null) return "error_not_logged_in";

    try {
      final groupRef = _firestore.collection('communityGroups').doc(groupId);
      DocumentSnapshot groupSnapshot = await groupRef.get();
      if (!groupSnapshot.exists) return "error_group_not_found";

      final groupData = groupSnapshot.data() as Map<String, dynamic>;
      final membersList =
          (groupData['membersList'] as List<dynamic>? ?? [])
              .map((m) => Map<String, dynamic>.from(m))
              .toList();

      final currentUserData = membersList.firstWhere(
        (m) => m['uid'] == user.uid,
        orElse: () => {},
      );

      if (currentUserData['isAdmin'] == true) {
        final adminCount =
            membersList.where((m) => m['isAdmin'] == true).length;
        if (adminCount <= 1) {
          return "error_last_admin";
        }
      }
      // Nếu không phải là admin cuối cùng, hoặc không phải admin, tiến hành rời nhóm
      final updatedMembers = List.from(membersList);
      updatedMembers.removeWhere((member) => member['uid'] == user.uid);

      WriteBatch batch = _firestore.batch();

      batch.update(groupRef, {
        'membersList': updatedMembers,
        'membersCount': FieldValue.increment(-1),
      });

      batch.delete(
        _firestore
            .collection('users')
            .doc(user.uid)
            .collection('communityGroups')
            .doc(groupId),
      );

      await batch.commit();
      return "success";
    } catch (e) {
      print("Error in API leaveGroup: $e");
      return "error_unknown";
    }
  }

  // Xóa vĩnh viễn nhóm.
  Future<bool> deleteGroup(
    String groupId,
    List<Map<String, dynamic>> groupMembers,
  ) async {
    try {
      final groupRef = _firestore.collection('communityGroups').doc(groupId);
      final WriteBatch batch = _firestore.batch();

      final postsSnapshot = await groupRef.collection('posts').get();
      for (final postDoc in postsSnapshot.docs) {
        final imageUrl = postDoc.data()['imageUrl'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            await _storage.refFromURL(imageUrl).delete();
          } catch (e) {
            print('Could not delete image: $e');
          }
        }
        batch.delete(postDoc.reference);
      }

      final joinRequestsSnapshot =
          await groupRef.collection('join_requests').get();
      for (final requestDoc in joinRequestsSnapshot.docs) {
        batch.delete(requestDoc.reference);
      }

      for (final memberMap in groupMembers) {
        if (memberMap['uid'] != null) {
          final userGroupRef = _firestore
              .collection('users')
              .doc(memberMap['uid'])
              .collection('communityGroups')
              .doc(groupId);
          batch.delete(userGroupRef);
        }
      }

      batch.delete(groupRef);
      await batch.commit();
      return true;
    } catch (e) {
      print("Error in API deleteGroup: $e");
      return false;
    }
  }

  // Chia sẻ bài viết trong ứng dụng.
  Future<bool> shareInternally(
    String groupId,
    String groupName,
    GroupPostModel postToShare,
  ) async {
    final sharer = _currentUser;
    if (sharer == null) {
      print("Lỗi: Người dùng chưa đăng nhập để chia sẻ.");
      return false;
    }
    final sharerDoc =
        await _firestore.collection('users').doc(sharer.uid).get();
    if (!sharerDoc.exists) {
      print("Lỗi: Không tìm thấy thông tin người dùng chia sẻ.");
      return false;
    }
    final sharerData = sharerDoc.data()!;

    try {
      // Sử dụng transaction để đảm bảo cả hai thao tác cùng thành công hoặc thất bại
      await _firestore.runTransaction((transaction) async {
        final originalPostRef = _firestore
            .collection('communityGroups')
            .doc(groupId)
            .collection('posts')
            .doc(postToShare.postId);

        // Lấy ID cho bài viết mới sẽ được tạo
        final newSharedPostRef = _firestore.collection('shared_posts').doc();
        final newPostId = newSharedPostRef.id;

        // Tăng lượt chia sẻ của bài viết gốc
        transaction.update(originalPostRef, {
          'sharesCount': FieldValue.increment(1),
        });

        // Tạo dữ liệu bài viết được chia sẻ
        final newPostData = {
          'postId': newPostId,
          'title': postToShare.title,
          'text': postToShare.text,
          'imageUrl': postToShare.imageUrls,
          'originUserId': postToShare.authorUid,
          'sharerUserId': sharer.uid,
          'authorUsername': sharerData['username'] ?? 'Không tên',
          'authorAvatarUrl': sharerData['avatarUrl'] ?? '',
          'sharedAt': Timestamp.now(),
          'commentsCount': 0,
          'sharesCount': 0,
          'isSharedPost': true,
          'sharedInfo': {
            'originalPostId': postToShare.postId,
            'originalAuthorUid': postToShare.authorUid,
            'originalAuthorUsername': postToShare.authorUsername,
            'originalGroupId': groupId,
            'originalGroupName': groupName,
          },
        };
        transaction.set(newSharedPostRef, newPostData);
      });
      return true;
    } catch (e) {
      print("Error in API shareInternally: $e");
      return false;
    }
  }

  Future<String?> createPostInGroup({
    required String groupId,
    String? title,
    String? text,
    List<File>? imageFiles,
  }) async {
    final user = _currentUser;
    if (user == null) {
      print("Lỗi: Người dùng chưa đăng nhập.");
      return null;
    }

    // Tạo một ID mới cho bài viết
    final postId =
        _firestore
            .collection('communityGroups')
            .doc(groupId)
            .collection('posts')
            .doc()
            .id;

    List<String> uploadedImageUrls = [];

    try {
      final groupDoc =
          await _firestore.collection('communityGroups').doc(groupId).get();
      if (!groupDoc.exists) {
        print("Lỗi: Không tìm thấy nhóm với ID: $groupId");
        return null;
      }
      final groupData = groupDoc.data()!;
      final bool isPrivateGroup = groupData['privacy'] == 'Riêng tư';
      final List<dynamic> membersList = groupData['membersList'] ?? [];
      final bool isUserAdmin = _isUserAdminInList(membersList, user.uid);
      final bool needsApproval = isPrivateGroup && !isUserAdmin;

      // Tải ảnh lên Cloudinary
      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (int i = 0; i < imageFiles.length; i++) {
          final imageFile = imageFiles[i];
          final response = await cloudinary.uploadFile(
            filePath: imageFile.path,
            resourceType: CloudinaryResourceType.image,
            folder: 'Learnity/GroupPosts/$groupId',
            fileName: '${postId}_$i',
          );
          if (response.isSuccessful && response.secureUrl != null) {
            uploadedImageUrls.add(response.secureUrl!);
          } else {
            print('Cloudinary upload failed for image $i: ${response.error}');
          }
        }
      }

      // Lấy thông tin mới nhất của người dùng
      String authorUsername = user.displayName ?? "Người dùng";
      String? authorAvatarUrl = user.photoURL;
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        authorUsername = userData['username'] ?? authorUsername;
        authorAvatarUrl = userData['avatarUrl'] ?? authorAvatarUrl;
      }

      //  Tạo đối tượng Post
      final post = GroupPostModel(
        postId: postId,
        groupId: groupId,
        authorUid: user.uid,
        authorUsername: authorUsername,
        authorAvatarUrl: authorAvatarUrl,
        title: (title != null && title.isNotEmpty) ? title : null,
        text: (text != null && text.isNotEmpty) ? text : null,
        imageUrls: uploadedImageUrls,
        createdAt: DateTime.now(),
      );

      //  Lưu bài viết vào Firestore
      if (needsApproval) {
        final pendingRef = _firestore
            .collection('communityGroups')
            .doc(groupId)
            .collection('pendingPosts')
            .doc(postId);

        await pendingRef.set(post.toMap());
        return 'pending';
      } else {
        final batch = _firestore.batch();

        final postRef = _firestore
            .collection('communityGroups')
            .doc(groupId)
            .collection('posts')
            .doc(postId);
        final groupRef = _firestore.collection('communityGroups').doc(groupId);

        batch.set(postRef, post.toMap());
        batch.update(groupRef, {'postsCount': FieldValue.increment(1)});

        await batch.commit();
        return "approved";
      }
    } catch (e) {
      print("Error in createPostInGroup API: $e");
      return null;
    }
  }

  // laays pót detail
  Future<GroupPostModel?> getPostDetails(String groupId, String postId) async {
    try {
      final postDoc =
          await _firestore
              .collection('communityGroups')
              .doc(groupId)
              .collection('posts')
              .doc(postId)
              .get();

      if (postDoc.exists) {
        return GroupPostModel.fromDocument(postDoc);
      }
      return null;
    } catch (e) {
      print("Error in API getPostDetails: $e");
      return null;
    }
  }

  // Gửi một bình luận mới cho bài viết.
  Future<bool> postComment(
    String groupId,
    String postId,
    String commentText,
  ) async {
    final user = _currentUser;
    if (user == null || commentText.trim().isEmpty) return false;

    try {
      // Lấy thông tin người dùng để đính kèm vào bình luận
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final username =
          userDoc.data()?['username'] ?? user.displayName ?? 'Người dùng';
      final userAvatarUrl = userDoc.data()?['avatarUrl'] ?? user.photoURL;

      final commentData = {
        'authorUid': user.uid,
        'authorUsername': username,
        'authorAvatarUrl': userAvatarUrl,
        'content': commentText,
        'createdAt': FieldValue.serverTimestamp(),
        'likedBy': [],
      };

      // Dùng WriteBatch để đảm bảo cả hai thao tác cùng thành công
      final WriteBatch batch = _firestore.batch();

      //  Thêm bình luận mới
      final commentRef =
          _firestore
              .collection('communityGroups')
              .doc(groupId)
              .collection('posts')
              .doc(postId)
              .collection('comments')
              .doc();
      batch.set(commentRef, commentData);

      //  Cập nhật (tăng) số lượng bình luận trên bài viết
      final postRef = _firestore
          .collection('communityGroups')
          .doc(groupId)
          .collection('posts')
          .doc(postId);
      batch.update(postRef, {'commentsCount': FieldValue.increment(1)});

      await batch.commit();
      return true;
    } catch (e) {
      print("Error in API postComment: $e");
      return false;
    }
  }

  // Lấy stream các bình luận của một bài viết để hiển thị real-time.
  Stream<QuerySnapshot> getCommentsStream(String groupId, String postId) {
    return _firestore
        .collection('communityGroups')
        .doc(groupId)
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getJoinRequests(String groupId) async {
    try {
      final snapshot =
          await _firestore
              .collection('communityGroups')
              .doc(groupId)
              .collection('join_requests')
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => {...doc.data(), 'uid': doc.id})
          .toList();
    } catch (e) {
      print("Error in API getJoinRequests: $e");
      return [];
    }
  }

  // Chấp nhận một yêu cầu tham gia nhóm.
  Future<bool> acceptJoinRequest(
    String groupId,
    String groupName,
    Map<String, dynamic> requestData,
  ) async {
    final requestingUserId = requestData['uid']?.toString();
    if (requestingUserId == null) return false;

    try {
      final groupRef = _firestore.collection('communityGroups').doc(groupId);
      final userRef = _firestore.collection('users').doc(requestingUserId);
      final requestRef = groupRef
          .collection('join_requests')
          .doc(requestingUserId);

      final memberData = {
        'uid': requestingUserId,
        'username': requestData['username'] ?? ' ',
        'email': requestData['email'] ?? '',
        'isAdmin': false,
        "avatarUrl": requestData['avatarUrl'] ?? '',
        'joinedAt': Timestamp.now(),
      };

      final batch = _firestore.batch();
      batch.update(groupRef, {
        'membersList': FieldValue.arrayUnion([memberData]),
        'membersCount': FieldValue.increment(1),
      });

      // Thêm tham chiếu nhóm vào subcollection của người dùng
      batch.set(userRef.collection('communityGroups').doc(groupId), {
        'groupId': groupId,
        'joinedAt': Timestamp.now(),
        'groupName': groupName,
      });

      // Xóa yêu cầu đã được duyệt
      batch.delete(requestRef);

      await batch.commit();
      return true;
    } catch (e) {
      print("Error in API acceptJoinRequest: $e");
      return false;
    }
  }

  // Từ chối một yêu cầu tham gia nhóm.
  Future<bool> denyJoinRequest(String groupId, String requestingUserId) async {
    try {
      await _firestore
          .collection('communityGroups')
          .doc(groupId)
          .collection('join_requests')
          .doc(requestingUserId)
          .delete();
      return true;
    } catch (e) {
      print("Error in API denyJoinRequest: $e");
      return false;
    }
  }

  // Lấy danh sách thành viên của một nhóm.
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    try {
      final doc =
          await _firestore.collection('communityGroups').doc(groupId).get();
      if (doc.exists && doc.data()?['membersList'] != null) {
        return List<Map<String, dynamic>>.from(doc.data()!['membersList']);
      }
      return [];
    } catch (e) {
      print("Error in API getGroupMembers: $e");
      return [];
    }
  }

  // Cấp hoặc hủy quyền admin cho một thành viên.
  Future<bool> toggleMemberAdminStatus(
    String groupId,
    String memberUid,
    bool currentIsAdmin,
  ) async {
    try {
      final docRef = _firestore.collection('communityGroups').doc(groupId);
      // Dùng transaction để đảm bảo dữ liệu được cập nhật an toàn
      await _firestore.runTransaction((transaction) async {
        final snap = await transaction.get(docRef);
        if (!snap.exists) throw Exception("Group not found!");

        final members = List<Map<String, dynamic>>.from(snap['membersList']);
        final index = members.indexWhere((m) => m['uid'] == memberUid);

        if (index != -1) {
          // Cập nhật trạng thái admin của thành viên
          members[index]['isAdmin'] = !currentIsAdmin;
          transaction.update(docRef, {'membersList': members});
        }
      });
      return true;
    } catch (e) {
      print("Error in API toggleMemberAdminStatus: $e");
      return false;
    }
  }

  //Xóa một thành viên khỏi nhóm.
  Future<bool> removeMemberFromGroup(String groupId, String memberUid) async {
    try {
      final groupRef = _firestore.collection('communityGroups').doc(groupId);
      final userGroupRef = _firestore
          .collection('users')
          .doc(memberUid)
          .collection('communityGroups')
          .doc(groupId);
      await _firestore.runTransaction((transaction) async {
        final snap = await transaction.get(groupRef);
        if (!snap.exists) throw Exception("Group not found!");

        final members = List<Map<String, dynamic>>.from(snap['membersList']);
        members.removeWhere((m) => m['uid'] == memberUid);

        //  Cập nhật lại danh sách thành viên và số lượng
        transaction.update(groupRef, {
          'membersList': members,
          'membersCount': FieldValue.increment(-1),
        });
        // Xóa tham chiếu nhóm khỏi người dùng
        transaction.delete(userGroupRef);
      });
      return true;
    } catch (e) {
      print("Error in API removeMemberFromGroup: $e");
      return false;
    }
  }

  Future<bool> uploadAvtGroup({
    required String groupId,
    required String name,
    required String privacy,
    File? newAvatarFile,
    String? description,
  }) async {
    try {
      String? newAvatarUrl;

      if (newAvatarFile != null) {
        final response = await cloudinary.uploadFile(
          filePath: newAvatarFile.path,
          resourceType: CloudinaryResourceType.image,
          folder: 'Learnity/GroupAvatars',
        );

        if (response.isSuccessful && response.secureUrl != null) {
          newAvatarUrl = response.secureUrl;
        } else {
          log('Lỗi tải ảnh lên Cloudinary: ${response.error}');
          return false;
        }
      }

      final Map<String, dynamic> dataToUpdate = {
        'name': name.trim(),
        'privacy': privacy,
        if (newAvatarUrl != null) 'avatarUrl': newAvatarUrl,
        if (description != null) 'description': description.trim(),
      };

      await _firestore
          .collection('communityGroups')
          .doc(groupId)
          .update(dataToUpdate);

      return true;
    } catch (e) {
      log("Lỗi: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getGroupInfo(String groupId) async {
    try {
      final doc =
          await _firestore.collection('communityGroups').doc(groupId).get();

      if (doc.exists) {
        return doc.data();
      } else {
        return null;
      }
    } catch (e) {
      log("Lỗi khi lấy chi tiết nhóm: $e");
      return null;
    }
  }

  // Hàm kiểm tra Admin
  bool _isUserAdminInList(List<dynamic> membersList, String userId) {
    try {
      var memberData = membersList.firstWhere(
        (member) => member is Map && member['uid'] == userId,
        orElse: () => null,
      );
      if (memberData != null && memberData['isAdmin'] == true) {
        return true;
      }
    } catch (e) {
      print("Lỗi khi kiểm tra admin trong membersList: $e");
    }
    return false;
  }

  // Duyệt một bài viết bằng cách di chuyển nó từ 'pendingPosts' sang 'posts'.
  Future<bool> approvePost({
    required String groupId,
    required String postId,
    required Map<String, dynamic> postData,
  }) async {
    try {
      final groupRef = _firestore.collection('communityGroups').doc(groupId);
      final pendingPostRef = groupRef.collection('pendingPosts').doc(postId);
      final approvedPostRef = groupRef.collection('posts').doc(postId);

      await _firestore.runTransaction((transaction) async {
        // Sao chép dữ liệu bài viết sang collection `posts`
        transaction.set(approvedPostRef, postData);

        // Xóa bài viết khỏi collection `pendingPosts`
        transaction.delete(pendingPostRef);

        // Cập nhật số lượng bài viết của nhóm
        transaction.update(groupRef, {'postsCount': FieldValue.increment(1)});
      });

      print("Đã duyệt bài viết thành công!");
      return true;
    } catch (e) {
      print("Lỗi khi duyệt bài viết: $e");
      return false;
    }
  }

  // Lấy các bài viết cần duyệt
  Future<List<GroupPostModel>> getPendingPosts(String groupId) async {
    try {
      final snapshot =
          await _firestore
              .collection('communityGroups')
              .doc(groupId)
              .collection('pendingPosts')
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => GroupPostModel.fromDocument(doc))
          .toList();
    } catch (e) {
      print("Lỗi khi lấy bài viết chờ duyệt: $e");
      return [];
    }
  }

  //Từ chối bài viết (xóa khỏi `pendingPosts`)
  Future<bool> rejectPost({
    required String groupId,
    required String postId,
    List<String>? imageUrls,
  }) async {
    try {
      // Xóa tài liệu khỏi Firestore
      await _firestore
          .collection('communityGroups')
          .doc(groupId)
          .collection('pendingPosts')
          .doc(postId)
          .delete();

      if (imageUrls != null && imageUrls.isNotEmpty) {
        for (final url in imageUrls) {
          try {
            await _storage.refFromURL(url).delete();
          } catch (e) {
            print('Lỗi khi xóa ảnh $url: $e');
          }
        }
      }

      return true;
    } catch (e) {
      print("Lỗi khi từ chối bài viết: $e");
      return false;
    }
  }

  // Duyệt tất cả bài viết trong nhóm RT
  Future<bool> approveAllPosts({
    required String groupId,
    required List<GroupPostModel> postsToApprove,
  }) async {
    if (postsToApprove.isEmpty) return true;

    try {
      final groupRef = _firestore.collection('communityGroups').doc(groupId);
      final batch = _firestore.batch();
      //Lặp qua danh sách bài viết cần duyệt và thêm các thao tác vào batch
      for (final post in postsToApprove) {
        final pendingPostRef = groupRef
            .collection('pendingPosts')
            .doc(post.postId);
        final approvedPostRef = groupRef.collection('posts').doc(post.postId);
        batch.set(approvedPostRef, post.toMap());
        batch.delete(pendingPostRef);
      }
      batch.update(groupRef, {
        'postsCount': FieldValue.increment(postsToApprove.length),
      });
      await batch.commit();
      return true;
    } catch (e) {
      print("Lỗi khi duyệt tất cả bài viết: $e");
      return false;
    }
  }
}
