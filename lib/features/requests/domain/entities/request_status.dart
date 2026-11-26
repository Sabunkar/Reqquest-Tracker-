enum RequestStatus {
  draft,
  submitted,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case RequestStatus.draft:
        return 'Draft';
      case RequestStatus.submitted:
        return 'Submitted';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isDraft => this == RequestStatus.draft;
  bool get isSubmitted => this == RequestStatus.submitted;
  bool get isApproved => this == RequestStatus.approved;
  bool get isRejected => this == RequestStatus.rejected;

  /// Approved and Rejected requests are final and read-only.
  bool get isFinal => isApproved || isRejected;

  /// Only Draft requests can be edited.
  bool get canEdit => isDraft;

  /// Only Draft requests can be submitted.
  bool get canSubmit => isDraft;

  /// Reviewers can only approve or reject Submitted requests.
  bool get canReview => isSubmitted;
}
