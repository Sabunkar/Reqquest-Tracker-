import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/cubit/settings_state.dart';
import '../../domain/entities/request_status.dart';
import '../cubit/request_list_cubit.dart';
import '../cubit/request_list_state.dart';
import '../widgets/request_card.dart';

class ReviewQueueScreen extends StatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  @override
  void initState() {
    super.initState();
    // Load and filter submitted requests
    final cubit = context.read<RequestListCubit>();
    cubit.loadRequests().then((_) {
      if (mounted) {
        cubit.filterByStatus(RequestStatus.submitted);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        drawer: const AppDrawer(currentLocation: '/review-queue'),
        appBar: AppBar(
          title: const Text('Review Queue'),
          leading: Builder(
            builder: (ctx) {
              if (context.canPop()) {
                return IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                );
              }
              return IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Open navigation drawer',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh Queue',
              onPressed: () {
                final cubit = context.read<RequestListCubit>();
                cubit.loadRequests(isRefresh: true).then((_) {
                  cubit.filterByStatus(RequestStatus.submitted);
                });
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            final isReviewer = settingsState.role.isReviewer;

            return BlocBuilder<RequestListCubit, RequestListState>(
              builder: (context, state) {
                if (state is RequestListLoading) {
                  return const LoadingWidget(
                    message: 'Loading review queue...',
                  );
                }

                if (state is RequestListError) {
                  return CustomErrorWidget(
                    message: state.message,
                    onRetry: () {
                      final cubit = context.read<RequestListCubit>();
                      cubit.loadRequests().then((_) {
                        cubit.filterByStatus(RequestStatus.submitted);
                      });
                    },
                  );
                }

                if (state is RequestListLoaded) {
                  // Filter only submitted requests
                  final submittedRequests = state.allRequests
                      .where((r) => r.status == RequestStatus.submitted)
                      .toList();

                  return ResponsiveContainer(
                    maxWidth: 960,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Role banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isReviewer
                                ? AppColors.statusSubmittedBgLight
                                : AppColors.surfaceVariantLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isReviewer
                                  ? AppColors.statusSubmitted.withValues(
                                      alpha: 0.3,
                                    )
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isReviewer
                                    ? Icons.verified_user_outlined
                                    : Icons.info_outline_rounded,
                                color: isReviewer
                                    ? AppColors.statusSubmitted
                                    : AppColors.textSecondaryLight,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isReviewer
                                      ? 'As an Approver (Reviewer), you have authority to approve or reject these requests.'
                                      : 'Showing requests currently awaiting approval. Only Reviewers can approve or reject.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isReviewer
                                        ? (isDark
                                              ? AppColors.statusSubmittedDark
                                              : AppColors.statusSubmitted)
                                        : (isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Pending Approvals (${submittedRequests.length})',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 12),

                        Expanded(
                          child: submittedRequests.isEmpty
                              ? const EmptyWidget(
                                  title: 'No Requests Pending Review',
                                  subtitle:
                                      'All submitted requests have been reviewed and approved or rejected.',
                                  icon: Icons.task_alt_rounded,
                                )
                              : ListView.separated(
                                  itemCount: submittedRequests.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final request = submittedRequests[index];
                                    return RequestCard(
                                      request: request,
                                      onTap: () => context.push(
                                        '/requests/${request.id}',
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }
}
