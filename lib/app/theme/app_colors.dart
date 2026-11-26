import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Primary Navy & Indigo Tones
  static const Color primary = Color(0xFF1E3A8A); // Deep Navy
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF0F172A);

  // Neutral Backgrounds & Surfaces (Light)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Neutral Backgrounds & Surfaces (Dark)
  static const Color backgroundDark = Color(0xFF0B0F17);
  static const Color surfaceDark = Color(0xFF131B2E);
  static const Color surfaceVariantDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Accent & Functional
  static const Color accent = Color(0xFF0EA5E9);

  // Status Colors (Strictly WCAG AA Verified)
  // Draft: neutral grey
  static const Color statusDraft = Color(0xFF475569);
  static const Color statusDraftDark = Color(0xFFE2E8F0);
  static const Color statusDraftBgLight = Color(0xFFF1F5F9);
  static const Color statusDraftBgDark = Color(0xFF1E293B);

  // Submitted: blue
  static const Color statusSubmitted = Color(0xFF1D4ED8);
  static const Color statusSubmittedDark = Color(0xFF93C5FD);
  static const Color statusSubmittedBgLight = Color(0xFFEFF6FF);
  static const Color statusSubmittedBgDark = Color(0xFF1E3A5F);

  // Approved: green
  static const Color statusApproved = Color(0xFF15803D);
  static const Color statusApprovedDark = Color(0xFF86EFAC);
  static const Color statusApprovedBgLight = Color(0xFFF0FDF4);
  static const Color statusApprovedBgDark = Color(0xFF14532D);

  // Rejected: red
  static const Color statusRejected = Color(0xFFB91C1C);
  static const Color statusRejectedDark = Color(0xFFFCA5A5);
  static const Color statusRejectedBgLight = Color(0xFFFEF2F2);
  static const Color statusRejectedBgDark = Color(0xFF7F1D1D);

  // Generic Error, Warning, Success
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
}
