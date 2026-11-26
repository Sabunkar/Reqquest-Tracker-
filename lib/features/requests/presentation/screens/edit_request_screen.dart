import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_breakpoints.dart';
import '../../../../app/constants/app_constants.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../../injection/dependency_injection.dart';
import '../../domain/entities/request.dart';
import '../../domain/repositories/request_repository.dart';
import '../../domain/validators/request_validator.dart';
import '../cubit/request_form_cubit.dart';
import '../cubit/request_form_state.dart';
import '../cubit/request_list_cubit.dart';

class EditRequestScreen extends StatefulWidget {
  final String requestId;

  const EditRequestScreen({super.key, required this.requestId});

  @override
  State<EditRequestScreen> createState() => _EditRequestScreenState();
}

class _EditRequestScreenState extends State<EditRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Request? _loadedRequest;
  int _descriptionLength = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(() {
      setState(() {
        _descriptionLength = _descriptionController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _populateFields(Request request) {
    if (!_isInitialized) {
      _loadedRequest = request;
      _titleController.text = request.title;
      _descriptionController.text = request.description;
      _descriptionLength = request.description.length;
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) =>
          RequestFormCubit(sl<RequestRepository>())
            ..loadRequestForEdit(widget.requestId),
      child: BlocConsumer<RequestFormCubit, RequestFormState>(
        listener: (context, state) {
          if (state is RequestFormLoadedForEdit) {
            _populateFields(state.request);
          } else if (state is RequestFormSuccess) {
            context.read<RequestListCubit>().loadRequests();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Request updated successfully.'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop(true);
          } else if (state is RequestFormError) {
            if (state.isConflict && state.latestRequest != null) {
              _showConflictDialog(context, state.latestRequest!);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: theme.colorScheme.error,
                  action: SnackBarAction(
                    label: 'Dismiss',
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is RequestFormLoadingEdit && !_isInitialized) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Request')),
              body: const LoadingWidget(message: 'Loading request details...'),
            );
          }

          if (state is RequestFormError && !_isInitialized) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Request')),
              body: EmptyWidget(
                title: 'Cannot Edit Request',
                subtitle: state.message,
                icon: Icons.lock_outline_rounded,
                action: ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Go Back'),
                ),
              ),
            );
          }

          final isSubmitting = state is RequestFormSubmitting;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              context.pop();
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  'Edit Request ${_loadedRequest != null ? '(v${_loadedRequest!.version})' : ''}',
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: ResponsiveContainer(
                  maxWidth: AppBreakpoints.maxContentWidthForm,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Request Content',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Saving changes will increment the version from v${_loadedRequest?.version ?? 1} to v${(_loadedRequest?.version ?? 1) + 1}.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Title Field
                                TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Title *',
                                    hintText:
                                        'Enter request title (min 3 chars)',
                                    prefixIcon: Icon(Icons.title_rounded),
                                  ),
                                  maxLength: AppConstants.titleMaxLength,
                                  validator: RequestValidator.validateTitle,
                                  enabled: !isSubmitting,
                                ),
                                const SizedBox(height: 16),

                                // Description Field with Live Counter
                                TextFormField(
                                  controller: _descriptionController,
                                  decoration: InputDecoration(
                                    labelText: 'Description',
                                    hintText:
                                        'Provide additional details, context, and justifications',
                                    alignLabelWithHint: true,
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(bottom: 80),
                                      child: Icon(Icons.description_outlined),
                                    ),
                                    counterText:
                                        '$_descriptionLength / ${AppConstants.descriptionMaxLength}',
                                    counterStyle: _descriptionLength > 1900
                                        ? TextStyle(
                                            color: theme.colorScheme.error,
                                            fontWeight: FontWeight.bold,
                                          )
                                        : null,
                                  ),
                                  maxLines: 5,
                                  maxLength: AppConstants.descriptionMaxLength,
                                  validator:
                                      RequestValidator.validateDescription,
                                  enabled: !isSubmitting,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Actions
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow =
                                constraints.maxWidth <
                                AppBreakpoints.compactMobile;

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton(
                                    onPressed: isSubmitting
                                        ? null
                                        : () {
                                            if (_formKey.currentState
                                                    ?.validate() ??
                                                false) {
                                              if (_loadedRequest != null) {
                                                context
                                                    .read<RequestFormCubit>()
                                                    .updateDraft(
                                                      id: _loadedRequest!.id,
                                                      title:
                                                          _titleController.text,
                                                      description:
                                                          _descriptionController
                                                              .text,
                                                      expectedVersion:
                                                          _loadedRequest!
                                                              .version,
                                                    );
                                              }
                                            }
                                          },
                                    child: isSubmitting
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.check_rounded,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Save Changes'),
                                            ],
                                          ),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton(
                                    onPressed: isSubmitting
                                        ? null
                                        : () => context.pop(),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isSubmitting
                                        ? null
                                        : () => context.pop(),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: isSubmitting
                                        ? null
                                        : () {
                                            if (_formKey.currentState
                                                    ?.validate() ??
                                                false) {
                                              if (_loadedRequest != null) {
                                                context
                                                    .read<RequestFormCubit>()
                                                    .updateDraft(
                                                      id: _loadedRequest!.id,
                                                      title:
                                                          _titleController.text,
                                                      description:
                                                          _descriptionController
                                                              .text,
                                                      expectedVersion:
                                                          _loadedRequest!
                                                              .version,
                                                    );
                                              }
                                            }
                                          },
                                    child: isSubmitting
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.check_rounded,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Save Changes'),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showConflictDialog(BuildContext context, Request latest) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sync_problem_rounded,
              color: Colors.orange,
              size: 36,
            ),
          ),
          title: const Text('Version Conflict Detected'),
          actionsOverflowButtonSpacing: 8,
          actionsOverflowDirection: VerticalDirection.down,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This request was updated by another operation or user while you were editing.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Your editing version:'),
                          Text(
                            'v${_loadedRequest?.version ?? 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current server version:'),
                          Text(
                            'v${latest.version}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose how you want to proceed:\n'
                  '• "Reload Latest Data" discards your unsaved changes and loads the latest content.\n'
                  '• "Reapply My Changes" submits your edits on top of version v${latest.version}.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() {
                  _isInitialized = false;
                  _populateFields(latest);
                });
              },
              child: const Text('Reload Latest Data'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() {
                  _loadedRequest = latest;
                });
                context.read<RequestFormCubit>().updateDraft(
                  id: latest.id,
                  title: _titleController.text,
                  description: _descriptionController.text,
                  expectedVersion: latest.version,
                );
              },
              child: const Text('Reapply My Changes'),
            ),
          ],
        );
      },
    );
  }
}
