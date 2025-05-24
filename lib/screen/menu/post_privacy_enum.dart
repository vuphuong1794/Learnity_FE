enum PostPrivacy {
  everyone,
  myself,
  followers
}

extension PostPrivacyExtension on PostPrivacy {
  String get displayName {
    switch (this) {
      case PostPrivacy.everyone:
        return 'Mọi người';
      case PostPrivacy.myself:
        return 'Chỉ mình tôi';
      case PostPrivacy.followers:
        return 'Người theo dõi';
      default:
        return '';
    }
  }

  String get firestoreValue {
    switch (this) {
      case PostPrivacy.everyone:
        return 'everyone';
      case PostPrivacy.myself:
        return 'myself';
      case PostPrivacy.followers:
        return 'followers';
      default:
        return 'everyone';
    }
  }

  static PostPrivacy fromFirestoreValue(String? value) {
    if (value == 'myself') {
      return PostPrivacy.myself;
    }
    if (value == 'followers') {
      return PostPrivacy.followers;
    }
    return PostPrivacy.everyone;
  }
}