import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_breakpoints.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/cubit/settings_state.dart';
import '../cubit/request_list_cubit.dart';
import '../cubit/request_list_state.dart';
import '../widgets/request_card.dart';
import '../widgets/request_filter_bar.dart';

class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<RequestListCubit>().loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        drawer: const AppDrawer(currentLocation: '/requests'),
        appBar: AppBar(
          title: const Text('Requests'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back to Dashboard',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          actions: [
            BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                if (state.role.isUser) {
                  return IconButton(
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Create Request',
                    onPressed: () => context.push('/requests/create'),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => context.go('/settings'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<RequestListCubit, RequestListState>(
          builder: (context, state) {
            if (state is RequestListLoading) {
              return const LoadingWidget(message: 'Loading requests...');
            }

            if (state is RequestListError) {
              return CustomErrorWidget(
                message: state.message,
                onRetry: () => context.read<RequestListCubit>().loadRequests(),
              );
            }

            if (state is RequestListLoaded) {
              final hasSearch = state.searchQuery.isNotEmpty;
              final hasFilter = state.selectedFilter != null;

              return ResponsiveContainer(
                maxWidth: AppBreakpoints.maxContentWidthWide,
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by title or description...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 20,
                                  ),
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    context
                                        .read<RequestListCubit>()
                                        .clearSearch();
                                    setState(() {});
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (val) {
                          context.read<RequestListCubit>().search(val);
                          setState(() {});
                        },
                      ),
                    ),

                    // Status Filter Chips
                    RequestFilterBar(
                      selectedFilter: state.selectedFilter,
                      onFilterSelected: (status) {
                        context.read<RequestListCubit>().filterByStatus(status);
                      },
                    ),
                    const Divider(height: 12),

                    // Requests List or Empty States
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => context
                            .read<RequestListCubit>()
                            .loadRequests(isRefresh: true),
                        child: _buildListContent(
                          context,
                          state,
                          hasSearch,
                          hasFilter,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildListContent(
    BuildContext context,
    RequestListLoaded state,
    bool hasSearch,
    bool hasFilter,
  ) {
    if (state.allRequests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: EmptyWidget(
              title: 'No requests yet',
              subtitle:
                  'Create your first request to get started with the approval workflow.',
              action: BlocBuilder<SettingsCubit, SettingsState>(
                builder: (context, settingsState) {
                  if (settingsState.role.isUser) {
                    return ElevatedButton.icon(
                      onPressed: () => context.push('/requests/create'),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Request'),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      );
    }

    if (state.filteredRequests.isEmpty) {
      if (hasSearch) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: EmptyWidget(
                title: 'No matches found',
                subtitle:
                    'No requests match "${state.searchQuery}". Try a different search term.',
                icon: Icons.search_off_rounded,
                action: OutlinedButton.icon(
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    context.read<RequestListCubit>().clearSearch();
                    setState(() {});
                  },
                  label: const Text('Clear Search'),
                ),
              ),
            ),
          ],
        );
      }

      if (hasFilter) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: EmptyWidget(
                title: 'No ${state.selectedFilter!.displayName} requests',
                subtitle: 'There are currently no requests in this status.',
                icon: Icons.filter_alt_off_outlined,
                action: OutlinedButton(
                  onPressed: () {
                    context.read<RequestListCubit>().filterByStatus(null);
                  },
                  child: const Text('Show All Requests'),
                ),
              ),
            ),
          ],
        );
      }
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: state.filteredRequests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final request = state.filteredRequests[index];
        return RequestCard(
          request: request,
          onTap: () async {
            await context.push('/requests/${request.id}');
            if (context.mounted) {
              context.read<RequestListCubit>().loadRequests();
            }
          },
        );
      },
    );
  }
}
