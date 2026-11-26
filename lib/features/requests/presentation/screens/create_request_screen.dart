import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_breakpoints.dart';
import '../../../../app/constants/app_constants.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../../injection/dependency_injection.dart';
import '../../domain/repositories/request_repository.dart';
import '../../domain/validators/request_validator.dart';
import '../cubit/request_form_cubit.dart';
import '../cubit/request_form_state.dart';
import '../cubit/request_list_cubit.dart';
import '../utils/unsaved_draft_store.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _descriptionLength = 0;
  bool _showSimulationGuide = false;

  @override
  void initState() {
    super.initState();
    final savedTitle = UnsavedDraftStore.getSavedTitle();
    final savedDescription = UnsavedDraftStore.getSavedDescription();
    if (savedTitle.isNotEmpty) {
      _titleController.text = savedTitle;
    }
    if (savedDescription.isNotEmpty) {
      _descriptionController.text = savedDescription;
      _descriptionLength = savedDescription.length;
    }

    _titleController.addListener(_onFormInputChanged);
    _descriptionController.addListener(_onFormInputChanged);
  }

  void _onFormInputChanged() {
    UnsavedDraftStore.saveDraft(
      _titleController.text,
      _descriptionController.text,
    );
    if (_descriptionLength != _descriptionController.text.length) {
      setState(() {
        _descriptionLength = _descriptionController.text.length;
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onFormInputChanged);
    _descriptionController.removeListener(_onFormInputChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => RequestFormCubit(sl<RequestRepository>()),
      child: BlocConsumer<RequestFormCubit, RequestFormState>(
        listener: (context, state) {
          if (state is RequestFormSuccess) {
            UnsavedDraftStore.clearDraft();
            context.read<RequestListCubit>().loadRequests();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Request draft created successfully.'),
                backgroundColor: Colors.green,
              ),
            );
            context.pushReplacement('/requests/${state.request.id}');
          } else if (state is RequestFormError) {
            final isSimulation =
                state.message.contains('SIMULATED_NETWORK_FAILURE') ||
                state.message.contains('Simulated API network error');

            if (isSimulation) {
              setState(() {
                _showSimulationGuide = true;
              });
              _showSimulationRecoveryDialog(context);
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isSimulation
                      ? 'API Failure Simulation is ON. Your request could not be saved.'
                      : state.message,
                ),
                backgroundColor: theme.colorScheme.error,
                duration: const Duration(seconds: 6),
                action: isSimulation
                    ? SnackBarAction(
                        label: 'Go to Settings',
                        textColor: Colors.white,
                        onPressed: () => context.go('/settings'),
                      )
                    : SnackBarAction(
                        label: 'Dismiss',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
              ),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state is RequestFormSubmitting;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/requests');
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text('New Request'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/requests');
                    }
                  },
                ),
                actions: [
                  IconButton(
                    key: const ValueKey('create_request_settings_button'),
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                    onPressed: () => context.go('/settings'),
                  ),
                ],
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
                        if (_showSimulationGuide) ...[
                          _buildRecoveryGuideBanner(context),
                          const SizedBox(height: 16),
                        ],
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Request Information',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'All new requests are saved as Drafts. You can edit or submit them for reviewer approval after saving.',
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
                                        'Enter a clear request title (min 3 chars)',
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
                                        'Provide necessary context, justifications, and specifications',
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
                                              ScaffoldMessenger.of(
                                                context,
                                              ).clearSnackBars();
                                              context
                                                  .read<RequestFormCubit>()
                                                  .createDraft(
                                                    title:
                                                        _titleController.text,
                                                    description:
                                                        _descriptionController
                                                            .text,
                                                  );
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
                                                Icons.save_outlined,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Save as Draft'),
                                            ],
                                          ),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton(
                                    onPressed: isSubmitting
                                        ? null
                                        : () {
                                            UnsavedDraftStore.clearDraft();
                                            if (context.canPop()) {
                                              context.pop();
                                            } else {
                                              context.go('/requests');
                                            }
                                          },
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
                                        : () {
                                            UnsavedDraftStore.clearDraft();
                                            if (context.canPop()) {
                                              context.pop();
                                            } else {
                                              context.go('/requests');
                                            }
                                          },
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
                                              ScaffoldMessenger.of(
                                                context,
                                              ).clearSnackBars();
                                              context
                                                  .read<RequestFormCubit>()
                                                  .createDraft(
                                                    title:
                                                        _titleController.text,
                                                    description:
                                                        _descriptionController
                                                            .text,
                                                  );
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
                                                Icons.save_outlined,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Save as Draft'),
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

  void _showSimulationRecoveryDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
            size: 32,
          ),
          title: const Text(
            'API Failure Simulation is ON',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your request could not be saved. Follow these steps to retry:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                _buildGuideStep(
                  context,
                  '1',
                  'Open Settings using the button provided.',
                ),
                const SizedBox(height: 8),
                _buildGuideStep(
                  context,
                  '2',
                  'Turn OFF API Failure Simulation.',
                ),
                const SizedBox(height: 8),
                _buildGuideStep(
                  context,
                  '3',
                  'Return to the Create Request screen.',
                ),
                const SizedBox(height: 8),
                _buildGuideStep(
                  context,
                  '4',
                  'Click Save as Draft again to submit your request successfully.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Dismiss'),
            ),
            FilledButton.icon(
              key: const ValueKey('dialog_go_to_settings_button'),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Go to Settings'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/settings');
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecoveryGuideBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('simulation_recovery_guide_banner'),
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'API Failure Simulation is ON',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Dismiss guide',
                  onPressed: () => setState(() => _showSimulationGuide = false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your request could not be saved. Follow these steps to retry:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _buildGuideStep(
              context,
              '1',
              'Open Settings using the button provided.',
            ),
            const SizedBox(height: 6),
            _buildGuideStep(context, '2', 'Turn OFF API Failure Simulation.'),
            const SizedBox(height: 6),
            _buildGuideStep(
              context,
              '3',
              'Return to the Create Request screen.',
            ),
            const SizedBox(height: 6),
            _buildGuideStep(
              context,
              '4',
              'Click Save as Draft again to submit your request successfully.',
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              key: const ValueKey('banner_go_to_settings_button'),
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: const Text('Go to Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep(BuildContext context, String number, String text) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
          ),
        ),
      ],
    );
  }
}
