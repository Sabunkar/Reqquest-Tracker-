enum UserRole {
  user,
  reviewer;

  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'Requester (User)';
      case UserRole.reviewer:
        return 'Approver (Reviewer)';
    }
  }

  bool get isUser => this == UserRole.user;
  bool get isReviewer => this == UserRole.reviewer;
}
