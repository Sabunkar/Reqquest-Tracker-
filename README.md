# Tracker - Request Management & Governance System

**Tracker** is an enterprise-grade role-based request management, governance, and approval application built with Flutter using **Feature-First Clean Architecture** and the **Cubit** state management pattern.

---

## 1. Project Overview & Features

Tracker provides a structured internal governance pipeline for organizations. Team members create and track requests (e.g. software licenses, hardware equipment, travel authorizations, and budget allowances), while designated reviewers evaluate, approve, or reject submissions with documented justifications.

### Key Features
- **Role-Based Workflows**: Requester drafting and submission; Reviewer queue, inspection, approvals, and justified rejections.
- **Optimistic Concurrency Control**: Prevents stale overwrites using `expectedVersion` version tracking (`v1` $\rightarrow$ `v2` $\rightarrow$ `v3`).
- **Resilient Offline / Mock API**: Simulates network delays and backend API failure modes via a toggle in Settings.
- **Step-by-Step Failure Recovery Guide**: When API failure simulation is active, users receive an inline guide and dialog explaining recovery steps (`Open Settings` $\rightarrow$ `Turn OFF Failure Simulation` $\rightarrow$ `Return to Form` $\rightarrow$ `Save as Draft`).
- **Unsaved Form State Preservation**: Form inputs (Title & Description) are safely preserved in-memory and in `SharedPreferences` across navigation until explicitly saved or discarded.
- **Dashboard & Metric Overview**:
  - Live circular **Total Requests** summary badge inside the greeting card.
  - Dedicated 4-card metric overview (**Draft**, **Submitted**, **Approved**, **Rejected**) with adaptive responsive columns and tap-to-filter capability.
  - Quick theme toggle directly in the Dashboard AppBar (Light/Dark mode) with persistent preference.
- **Document Export**: High-fidelity PDF export with structured tables, status chips, and confidentiality metadata.
- **Application-Wide Responsive Design**: Zero RenderFlex overflows across compact mobile (320dp, 360dp, 390dp), tablet, desktop, and up to 1.5x accessibility text scaling.

---

## 2. Technologies & Packages Used

### Runtime Dependencies
| Package | Version | Purpose |
|---|---|---|
| **Flutter SDK** | `>=3.12.2` | Cross-platform UI toolkit |
| **flutter_bloc** | `^8.1.6` | Predictable state management via Cubit |
| **equatable** | `^2.0.7` | Value equality comparison for states & entities |
| **go_router** | `^14.8.1` | Declarative routing and deep linking with ShellRoute |
| **shared_preferences** | `^2.3.5` | Persistent local storage for requests, sessions, and settings |
| **pdf** | `^3.11.2` | Programmatic vector PDF document generation |
| **printing** | `^5.13.3` | Native PDF preview, printing, and file sharing |
| **intl** | `^0.20.2` | Date/time parsing and formatting |
| **uuid** | `^4.5.1` | Secure UUID v4 generation for request IDs |

### Development & Testing
| Package | Version | Purpose |
|---|---|---|
| **flutter_test** | SDK | Unit, widget, and integration testing harness |
| **bloc_test** | `^9.1.7` | Streamlined testing of Cubit state emission sequences |
| **mocktail** | `^1.0.4` | Mocking dependencies without build-runner code generation |
| **flutter_lints** | `^6.0.0` | Strict Dart & Flutter static analysis rules |

---

## 3. Architecture & Design Principles

Tracker follows **Feature-First Clean Architecture**, separating business modules first, and then segmenting by architectural layer:

```
lib/
├── app/                              # Global configuration, themes, routing, and constants
│   ├── constants/                    # Centralized constants (AppBreakpoints, AppConstants)
│   ├── routes/                       # GoRouter route hierarchy & ShellRoute navigation
│   ├── theme/                        # Material 3 light/dark theme system & WCAG AA palettes
│   └── app.dart                      # Root widget providing global Cubits & MaterialApp
│
├── core/                             # Shared, domain-agnostic components
│   ├── errors/                       # AppException, ConflictException hierarchy
│   ├── utils/                        # Shared utility formatters (DateFormatter)
│   └── widgets/                      # ResponsiveContainer, AppDrawer, Loading, Error, Empty widgets
│
├── features/                         # Modular business features
│   ├── auth/                         # Authentication & session persistence (data, domain, presentation)
│   ├── splash/                       # Branded splash startup screen
│   ├── onboarding/                   # 3-step walkthrough screens
│   ├── requests/                     # Core Request lifecycle
│   │   ├── data/                     # Datasources, models, repositories, PDF generation service
│   │   ├── domain/                   # Request entities, contracts, field validators
│   │   └── presentation/             # Cubits, screens (Dashboard, List, Detail, Create, Edit, Queue, History)
│   ├── settings/                     # User preferences, role switching, failure simulation toggle
│   ├── profile/                      # User profile & permissions matrix view
│   ├── notifications/                # In-app notifications screen
│   └── about/                        # Application information view
│
├── injection/                        # ServiceLocator manual dependency injection (sl)
└── main.dart                         # Application entrypoint
```

### Core Architectural Principles
1. **Selective Layering**: Core features (`requests`, `auth`, `settings`) maintain strict `data/`, `domain/`, and `presentation/` separation. Simpler presentation views avoid empty boilerplate.
2. **Domain Isolation**: The `domain/` layer has zero dependencies on Flutter UI libraries, data serialization, or storage packages.
3. **Optimistic Concurrency**: Stale updates are caught by verifying `expectedVersion == currentVersion` before applying mutations, preventing race conditions.
4. **Data Source Encapsulation**: Storage and serialization are hidden behind repository interfaces.

---

## 4. Setup & Installation

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.12.2 or higher)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- Android Studio / Xcode / VS Code with Flutter extension

### Installation Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/<YOUR_USERNAME>/<YOUR_REPO_NAME>.git
   cd "request tracker"
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Verify environment setup:
   ```bash
   flutter doctor
   ```

---

## 5. How to Run the Application

Run on your connected device, emulator, or desktop platform:

```bash
# Run in debug mode (default device)
flutter run

# Run on Chrome
flutter run -d chrome

# Run on Windows desktop
flutter run -d windows

# Run in release mode on Android
flutter run --release -d android
```

---

## 6. How to Run Tests & Verification

Tracker includes a comprehensive test suite of **143 tests** covering input validation, status transitions, failure/retry lifecycle, optimistic concurrency, and responsive layouts.

```bash
# Run the full automated test suite (143 tests)
flutter test

# Run focused lifecycle and retry tests
flutter test test/features/requests/focused/failure_and_retry_test.dart

# Run static analysis (verifies 0 errors, 0 warnings, 0 lints)
flutter analyze

# Verify code formatting
dart format --set-exit-if-changed .
```

---

## 7. Login Credentials & Role-Switching Instructions

### Startup & Login Flow
Every fresh app launch begins with the **Splash Screen** and moves to the **Login Screen**. The user can sign in using direct, one-click demo credentials:
- **`Continue as Requester`**: Signs in as **Alex Johnson** (Requester role, Engineering Operations department).
- **`Continue as Reviewer`**: Signs in as **Sarah Miller** (Approver role, Compliance & Approvals department).

### Switching Roles On-the-Fly
Users do not need to sign out to evaluate reviewer capabilities:
1. Open the **Navigation Drawer** (tap the hamburger menu icon $\equiv$ in the top-left of any main screen).
2. Tap the interactive **Role Selector Switcher** at the top of the drawer to toggle between **Requester** and **Reviewer**.
3. The application updates UI controls, navigation destinations (such as the *Review Queue*), and permissions instantly.

---

## 8. Request Lifecycle Summary

```
[ Draft ] ──(Submit)──> [ Submitted ] ──(Approve)──> [ Approved (Final) ]
                                      └──(Reject)───> [ Rejected (Final) ]
```

- **Draft**: Editable and submittable only by the Requester.
- **Submitted**: Placed into the Review Queue. Read-only for Requester. Approvers can Approve or Reject.
- **Approved / Rejected**: Immutable final states. Read-only for all roles with full PDF export and activity timeline tracking.
