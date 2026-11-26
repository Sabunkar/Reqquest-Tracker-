import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/request_status.dart';

/// Represents a filter item in [RequestFilterBar].
class _FilterOption {
  final String label;
  final RequestStatus? status;

  const _FilterOption(this.label, this.status);
}

/// A responsive, accessible horizontal filter bar displaying all request status filters.
///
/// Features:
/// - Clear labels for All, Draft, Submitted, Approved, and Rejected.
/// - Unselected filters have subtle background/border and high-contrast visible text.
/// - Selected filter has blue background, white text, and checkmark icon.
/// - Adaptive chip widths that never collapse or hide labels.
/// - Horizontal scrolling for narrow viewports (e.g. 320dp) and high text scaling.
class RequestFilterBar extends StatelessWidget {
  final RequestStatus? selectedFilter;
  final ValueChanged<RequestStatus?> onFilterSelected;

  const RequestFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  static const List<_FilterOption> _options = [
    _FilterOption('All', null),
    _FilterOption('Draft', RequestStatus.draft),
    _FilterOption('Submitted', RequestStatus.submitted),
    _FilterOption('Approved', RequestStatus.approved),
    _FilterOption('Rejected', RequestStatus.rejected),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Selected styling: Blue background with white text and check icon
    final selectedBgColor = isDark
        ? const Color(
            0xFF2563EB,
          ) // Vibrant blue passing WCAG AA (>4.5:1) with white
        : AppColors
              .primary; // Deep navy blue passing WCAG AA (>10:1) with white

    // Unselected styling: Subtle background, visible border, and high-contrast text
    final unselectedBgColor = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;

    final unselectedBorderColor = isDark
        ? AppColors.borderDark
        : AppColors.borderLight;

    final unselectedTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < _options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _buildFilterChip(
              option: _options[i],
              isSelected: selectedFilter == _options[i].status,
              selectedBgColor: selectedBgColor,
              unselectedBgColor: unselectedBgColor,
              unselectedBorderColor: unselectedBorderColor,
              unselectedTextColor: unselectedTextColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required _FilterOption option,
    required bool isSelected,
    required Color selectedBgColor,
    required Color unselectedBgColor,
    required Color unselectedBorderColor,
    required Color unselectedTextColor,
  }) {
    final chipKey = ValueKey('filter_chip_${option.status?.name ?? 'all'}');

    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      color: isSelected ? Colors.white : unselectedTextColor,
    );

    return FilterChip(
      key: chipKey,
      label: Text(option.label, softWrap: false),
      labelStyle: labelStyle,
      selected: isSelected,
      onSelected: (_) => onFilterSelected(option.status),
      showCheckmark: isSelected,
      checkmarkColor: Colors.white,
      selectedColor: selectedBgColor,
      backgroundColor: unselectedBgColor,
      side: BorderSide(
        color: isSelected ? selectedBgColor : unselectedBorderColor,
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
