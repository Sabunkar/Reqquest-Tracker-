import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/request_status.dart';

class StatusChip extends StatelessWidget {
  final RequestStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color textColor;
    Color backgroundColor;

    switch (status) {
      case RequestStatus.draft:
        textColor = isDark ? AppColors.statusDraftDark : AppColors.statusDraft;
        backgroundColor = isDark
            ? AppColors.statusDraftBgDark
            : AppColors.statusDraftBgLight;
        break;
      case RequestStatus.submitted:
        textColor = isDark
            ? AppColors.statusSubmittedDark
            : AppColors.statusSubmitted;
        backgroundColor = isDark
            ? AppColors.statusSubmittedBgDark
            : AppColors.statusSubmittedBgLight;
        break;
      case RequestStatus.approved:
        textColor = isDark
            ? AppColors.statusApprovedDark
            : AppColors.statusApproved;
        backgroundColor = isDark
            ? AppColors.statusApprovedBgDark
            : AppColors.statusApprovedBgLight;
        break;
      case RequestStatus.rejected:
        textColor = isDark
            ? AppColors.statusRejectedDark
            : AppColors.statusRejected;
        backgroundColor = isDark
            ? AppColors.statusRejectedBgDark
            : AppColors.statusRejectedBgLight;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: textColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
