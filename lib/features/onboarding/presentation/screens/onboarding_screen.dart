import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_breakpoints.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  /// Tracks whether the user has finished or skipped onboarding during this app launch session.
  static bool hasCompletedThisLaunch = false;

  /// Resets session status (primarily used for unit and widget testing).
  static void resetSession() {
    hasCompletedThisLaunch = false;
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    OnboardingScreen.hasCompletedThisLaunch = true;
    context.go('/dashboard');
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pages = [
      _OnboardingPageData(
        title: 'What is Request Tracker?',
        subtitle:
            'A unified enterprise workspace designed to create, submit, track, and audit organizational requests with full role-based governance and immutable history.',
        icon: Icons.hub_rounded,
        iconColor: AppColors.primary,
        stepBadge: 'OVERVIEW',
      ),
      _OnboardingPageData(
        title: 'Create & Track Requests',
        subtitle:
            'Requesters can draft requests, update specifications, and submit them for review. Watch real-time activity timelines and version tracking as requests advance.',
        icon: Icons.edit_note_rounded,
        iconColor: AppColors.statusDraft,
        stepBadge: 'FOR REQUESTERS',
      ),
      _OnboardingPageData(
        title: 'Reviewer Decisions & Approvals',
        subtitle:
            'Reviewers inspect submitted requests from the review queue. Authorize approvals with a single tap, or reject with clear recorded justifications.',
        icon: Icons.verified_user_rounded,
        iconColor: AppColors.statusApproved,
        stepBadge: 'FOR REVIEWERS',
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidthCompact,
            ),
            child: Column(
              children: [
                // Header with Skip Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.track_changes_rounded,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tracker',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (_currentPage < 2)
                        TextButton(
                          onPressed: _finishOnboarding,
                          child: const Text('Skip'),
                        )
                      else
                        const SizedBox(height: 48),
                    ],
                  ),
                ),

                // PageView with Three Screens
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildOnboardingPage(
                        context,
                        pages[index],
                        isDark,
                      );
                    },
                  ),
                ),

                // Bottom Navigation Bar with Dots & Buttons
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Page Indicator Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (idx) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            height: 8.0,
                            width: _currentPage == idx ? 24.0 : 8.0,
                            decoration: BoxDecoration(
                              color: _currentPage == idx
                                  ? theme.colorScheme.primary
                                  : (isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Navigation Action Buttons
                      Row(
                        children: [
                          if (_currentPage > 0)
                            Expanded(
                              flex: 2,
                              child: OutlinedButton(
                                onPressed: _prevPage,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                ),
                                child: const Text('Back'),
                              ),
                            )
                          else
                            const Spacer(flex: 2),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: FilledButton(
                              onPressed: _currentPage == 2
                                  ? _finishOnboarding
                                  : _nextPage,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 48),
                              ),
                              child: Text(
                                _currentPage == 2 ? 'Get Started' : 'Next',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(
    BuildContext context,
    _OnboardingPageData data,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: data.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: data.iconColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              data.stepBadge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: data.iconColor,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Illustration Container
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: data.iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: data.iconColor.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: Icon(data.icon, size: 64, color: data.iconColor),
          ),
          const SizedBox(height: 36),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 14),

          // Subtitle / Description
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String stepBadge;

  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.stepBadge,
  });
}
