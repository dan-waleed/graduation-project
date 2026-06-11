# HealthBridge Project Architecture Guide

This document explains how this project is organized, where the frontend and backend live, and what each main layer does.

## 1. Project overview

This repository contains two main parts:

1. `healthbridge_mobile/`
   The Flutter frontend application used by admins, doctors, employees, pharmacists, and insurance officers.
2. Django backend at the repository root
   The backend API, business rules, database models, authentication, notifications, and workflow logic.

The frontend talks to the backend through HTTP API calls under `/api/...`.

## 2. High-level folder map

```text
graduation project/
├── manage.py
├── requirements.txt
├── healthbridge/
│   ├── settings/
│   └── urls.py
├── core/
│   ├── api/
│   │   ├── urls/
│   │   ├── views/
│   │   └── serializers/
│   ├── services/
│   ├── models.py
│   ├── serializers.py
│   ├── permissions.py
│   └── utils.py
├── docs/
│   └── project_architecture_guide.md
└── healthbridge_mobile/
    ├── lib/
    │   └── src/
    │       ├── app/
    │       ├── core/
    │       ├── data/
    │       ├── features/
    │       └── shared/
    ├── assets/
    └── test/
```

## 3. Backend architecture

### 3.1 Backend entry point

- `manage.py`
  Starts Django commands such as `runserver`, `migrate`, and custom seed commands.
- `healthbridge/settings/base.py`
  Main Django settings: installed apps, REST Framework, auth model, database defaults, schema docs, and middleware.
- `healthbridge/settings/dev.py`
  Development settings. In this repo it enables SQLite by default for development unless PostgreSQL is explicitly enabled.
- `healthbridge/urls.py`
  Root URL file. Important routes:
  - `/admin/` for Django admin
  - `/api/` for the application API
  - `/api/schema/`, `/api/docs/swagger/`, `/api/docs/redoc/` for API documentation

### 3.2 Main backend app

The main application logic is in `core/`.

Important files:

- `core/models.py`
  Contains the database models and enums.
- `core/serializers.py`
  Contains the real DRF serializer implementations and validation logic.
- `core/api/views/`
  Contains API views and viewsets.
- `core/api/urls/`
  Splits API endpoints by domain such as auth, users, providers, workflow, and system.
- `core/services/`
  Holds reusable business logic that should not sit directly inside views or serializers.
- `core/permissions.py`
  Contains role-based access helpers.
- `core/utils.py`
  Contains helper functions for audit logs and notifications.

### 3.3 Backend layers and what each one does

#### A. Models layer

Location:

- `core/models.py`

Purpose:

- Defines the database structure.
- Defines core enums such as roles and statuses.
- Stores the main business entities.

Important models in this file:

- `User`
  Custom auth user with `role`, `email`, and `phone_number`.
- `Employee`
  University employee / insured person profile linked to a user.
- `Doctor`
  Doctor profile linked to a user.
- `Pharmacy`
  Pharmacy information.
- `Provider`
  Contracted healthcare provider.
- `MedicalService`
  Service catalog item such as medication or consultation.
- `Prescription`
  Medical order / prescription workflow record.
- `InsuranceRequest`
  Insurance review and approval record.
- `Dispense`
  Pharmacy dispense record.
- `Dependent`
  Employee beneficiaries / family members.
- `Notification`
  System notifications shown to users.
- `AuditLog`
  Administrative action tracking.

#### B. Serializer layer

Locations:

- Main serializer logic: `core/serializers.py`
- API serializer re-export modules: `core/api/serializers/`

Purpose:

- Validates incoming request data.
- Converts Django models to JSON responses.
- Handles nested create/update payloads.
- Enforces many business rules during API input handling.

Examples:

- `UserSerializer`
  Creates and updates users, hashes passwords, and blocks unsupported role changes.
- `UserUpdateSerializer`
  Handles user updates separately from create.
- `LoginRequestSerializer`
  Validates username and password.
- `EmployeeSerializer`
  Handles employee profiles and nested `user` payloads.
- `EmployeeCreateUserSerializer`
  Builds usernames, splits full names, and normalizes nested employee user data.

Important note:

- The files in `core/api/serializers/` are mostly small wrappers that import from `core/serializers.py`.
- If you want the real serializer logic, read `core/serializers.py`.

#### C. View / API layer

Locations:

- `core/api/views/auth.py`
- `core/api/views/users.py`
- `core/api/views/providers.py`
- `core/api/views/workflow.py`
- `core/api/views/system.py`
- shared base view: `core/api/views/common.py`

Purpose:

- Exposes REST API endpoints.
- Connects HTTP requests to serializers, models, and services.
- Applies authentication and role-based restrictions.
- Supports list/create/update/delete operations through DRF viewsets.

Important pieces:

- `BaseOwnedModelViewSet` in `core/api/views/common.py`
  Shared base class for many endpoints. It:
  - requires authentication
  - applies role checks
  - supports exact query filtering
  - logs create/update/delete actions

- `LoginView`, `LogoutView`, `MeView`, `DashboardSummaryView`
  Authentication and dashboard endpoints.

- `UserViewSet`, `EmployeeViewSet`, `DoctorViewSet`, `DependentViewSet`
  User and profile management endpoints.

- `PrescriptionViewSet`, `InsuranceRequestViewSet`, `DispenseViewSet`
  Main workflow endpoints.

- `NotificationViewSet`, `AuditLogViewSet`
  Notifications and admin logs.

#### D. URL routing layer

Locations:

- `healthbridge/urls.py`
- `core/api/urls/__init__.py`
- `core/api/urls/auth.py`
- `core/api/urls/users.py`
- `core/api/urls/providers.py`
- `core/api/urls/workflow.py`
- `core/api/urls/system.py`

Purpose:

- Registers all backend endpoints.
- Splits endpoints by feature area.

How it works:

1. `healthbridge/urls.py` sends `/api/` traffic into `core.api.urls`.
2. `core/api/urls/__init__.py` includes multiple domain-specific URL modules.
3. Each domain module registers DRF routes such as `users`, `employees`, `notifications`, or `prescriptions`.

#### E. Service layer

Location:

- `core/services/`

Purpose:

- Holds business logic separate from views and serializers.
- Keeps the code easier to maintain and test.

Important services:

- `access_service.py`
  Role-aware queryset filtering such as limiting what each role can see.
- `dashboard_service.py`
  Builds dashboard metrics and recent activity per role.
- `user_profile_service.py`
  Creates related role profiles automatically and builds usernames.
- `workflow_service.py`
  Handles prescription, insurance, and dispense transitions and coverage calculations.

Examples:

- `ensure_role_profile(user)`
  Automatically creates linked employee/doctor/pharmacist/insurance profiles.
- `apply_coverage_calculations(payload)`
  Calculates coverage percentage, covered amount, employee share, and final price.
- `sync_prescription_status_from_insurance(...)`
  Updates prescription status after insurance review.
- `sync_prescription_status_from_dispense(...)`
  Updates prescription status after dispensing.

#### F. Permissions and utility layer

Locations:

- `core/permissions.py`
- `core/utils.py`

Purpose:

- `core/permissions.py`
  Contains `RoleAccessMixin`, which checks whether the current user can perform the current action.
- `core/utils.py`
  Contains helper functions for:
  - creating audit logs
  - creating notifications
  - notifying users when prescriptions, insurance, or dispense records change

### 3.4 Backend request flow

A typical backend request flows like this:

1. Request enters `healthbridge/urls.py`
2. It is routed into one of the `core/api/urls/...` modules
3. A DRF view or viewset in `core/api/views/...` receives it
4. A serializer in `core/serializers.py` validates or formats data
5. Models in `core/models.py` are read or updated
6. Optional business logic from `core/services/...` is applied
7. Response JSON is returned to the frontend

Example:

- Frontend calls `POST /api/auth/login/`
- `LoginView` handles the request
- `LoginRequestSerializer` validates credentials
- Django auth checks username/password
- Token is returned with serialized user data

## 4. Frontend architecture

### 4.1 Frontend entry point

Important files:

- `healthbridge_mobile/lib/main.dart`
  The Flutter app entry point.
- `healthbridge_mobile/lib/src/app/app.dart`
  Creates `MaterialApp.router`, Arabic locale setup, theme, and app router.
- `healthbridge_mobile/lib/src/app/router/app_router.dart`
  Handles navigation, auth redirects, and route guards.

In `main.dart`, the app builds a `MultiProvider` tree that creates and wires:

- `TokenStorage`
- `ApiClient`
- `AppDataService`
- `AppRepository`
- `DashboardService`
- `DashboardRepository`
- `AuthService`
- `AuthRepository`
- `AuthViewModel`
- `NotificationCenterViewModel`

This means dependency wiring is done at app startup.

### 4.2 Frontend folder structure

Location:

- `healthbridge_mobile/lib/src/`

Main folders:

- `app/`
  App shell, routing, and theme.
- `core/`
  Base config, networking, and shared app-level errors.
- `data/`
  Models, repositories, services, and local token storage.
- `features/`
  Role-based screens and feature-specific presentation code.
- `shared/`
  Shared widgets and utility helpers.

### 4.3 Frontend layers and what each one does

#### A. App layer

Location:

- `healthbridge_mobile/lib/src/app/`

Purpose:

- Initializes app shell and theme.
- Configures route registration and route permissions.

Important files:

- `app.dart`
  Builds the main app widget.
- `router/app_router.dart`
  Redirects users based on auth state and role.
- `router/app_route_registry.dart`
  Registers all screens.
- `router/app_route_access.dart`
  Defines which routes each role is allowed to open.
- `theme/app_theme.dart`
  App visual theme.

#### B. Core layer

Location:

- `healthbridge_mobile/lib/src/core/`

Purpose:

- Provides application-level technical utilities.

Important files:

- `config/app_config.dart`
  Decides which backend base URL to use. Supports local host, Android emulator host, and optional LAN override.
- `network/api_client.dart`
  Central HTTP client for `GET`, `POST`, `PATCH`, and `DELETE`.
- `errors/app_exception.dart`
  Shared app exception type.

#### C. Data layer

Location:

- `healthbridge_mobile/lib/src/data/`

Purpose:

- Connects the UI to backend APIs and local storage.

Sub-layers:

- `models/`
  Dart data models such as `UserModel`, `SessionModel`, `PrescriptionModel`, `EmployeeModel`, and notification models.
- `services/`
  Raw data access and API calls.
- `repositories/`
  Thin abstraction used by view models and screens.
- `storage/`
  Local persistence such as saved auth session/token.

Important service files:

- `services/auth_service.dart`
  Handles login, logout, restore session, and demo login fallback.
- `services/app_data_service.dart`
  Handles most business data calls: users, employees, dependents, prescriptions, notifications, coverage, insurance, and dispenses.
- `services/dashboard_service.dart`
  Fetches dashboard summaries.

Important repository files:

- `repositories/auth_repository.dart`
  Wraps `AuthService`.
- `repositories/app_repository.dart`
  Wraps `AppDataService`.
- `repositories/dashboard_repository.dart`
  Wraps `DashboardService`.

Important note about demo mode:

- `AppDataService` and `AuthService` support local demo behavior.
- When a demo token is used, the app can serve local in-memory debug data instead of real backend data.
- This is useful for development and testing when the backend is unavailable.

#### D. Presentation / feature layer

Location:

- `healthbridge_mobile/lib/src/features/`

Purpose:

- Contains role-specific screens and view models.

Current feature folders in this repo:

- `admin/presentation/views/admin_views.dart`
- `auth/presentation/views/login_screen.dart`
- `auth/presentation/viewmodels/auth_view_model.dart`
- `common/presentation/views/notifications_screen.dart`
- `common/presentation/views/profile_screen.dart`
- `common/presentation/viewmodels/notification_center_view_model.dart`
- `doctor/presentation/views/doctor_views.dart`
- `employee/presentation/views/employee_views.dart`
- `insurance_officer/presentation/views/insurance_officer_views.dart`
- `pharmacist/presentation/views/pharmacist_views.dart`
- `provider/presentation/views/provider_portal_views.dart`
- `splash/presentation/views/splash_screen.dart`

What these screens do:

- `admin_views.dart`
  Admin user management, statistics, settings, and create/edit user forms.
- `doctor_views.dart`
  Search employees, create prescriptions, and review prescription history/details.
- `employee_views.dart`
  View own prescriptions, QR code, medication history, and dependents.
- `insurance_officer_views.dart`
  Review insurance requests and coverage catalog data.
- `pharmacist_views.dart`
  Search prescriptions, scan/lookup QR records, and confirm dispensing.
- `notifications_screen.dart`
  Reads and marks notifications.
- `profile_screen.dart`
  Displays current user information.
- `splash_screen.dart`
  Temporary app start screen while auth state is restored.

#### E. Shared layer

Location:

- `healthbridge_mobile/lib/src/shared/`

Purpose:

- Reusable UI and helper utilities shared across multiple features.

Important folders:

- `shared/widgets/`
  Shared UI components like scaffold, cards, status chips, button rows, inputs, and navigation.
- `shared/utils/`
  Shared constants and helpers like roles, labels, and password validation.

Examples:

- `hb_scaffold.dart`
  Common page scaffold.
- `hb_bottom_nav.dart`
  Role-aware bottom navigation.
- `app_roles.dart`
  Central role constants used in routing and UI logic.
- `password_strength_validator.dart`
  Strong password validation used by the admin user form.

### 4.4 Where the ViewModel is and what it does

This project currently has a light ViewModel usage pattern.

Locations:

- `healthbridge_mobile/lib/src/features/auth/presentation/viewmodels/auth_view_model.dart`
- `healthbridge_mobile/lib/src/features/common/presentation/viewmodels/notification_center_view_model.dart`

What each ViewModel does:

- `AuthViewModel`
  - stores auth state
  - logs in and logs out
  - restores saved session on app start
  - exposes current user and token
  - notifies the UI when auth state changes

- `NotificationCenterViewModel`
  - stores unread notification count
  - refreshes unread count periodically
  - updates notification badge state for the UI

Important note:

- Many screens in this project still call repositories directly through `Provider` instead of having a dedicated ViewModel per screen.
- So the architecture is a hybrid:
  - ViewModel pattern for app-level state like auth and notifications
  - direct repository usage in many feature screens

### 4.5 Frontend request/data flow

A typical frontend data flow looks like this:

1. User opens a screen
2. Screen calls a repository using `context.read<...>()`
3. Repository forwards the request to a service
4. Service uses `ApiClient` to call the backend
5. Response JSON is converted into Dart models
6. UI updates with the result

Example login flow:

1. `login_screen.dart` collects username and password
2. It calls `AuthViewModel.login(...)`
3. `AuthViewModel` calls `AuthRepository`
4. `AuthRepository` calls `AuthService`
5. `AuthService` sends `POST auth/login/` through `ApiClient`
6. Returned token and user are saved through `TokenStorage`
7. Router redirects the user to the correct home screen based on role

### 4.6 Frontend routing and role-based access

Important files:

- `app_route_registry.dart`
- `app_route_access.dart`
- `app_router.dart`

What they do:

- `app_route_registry.dart`
  Lists every route and screen builder.
- `app_route_access.dart`
  Returns:
  - the correct home screen for a role
  - the allowed routes for each role
- `app_router.dart`
  Redirects users depending on:
  - bootstrapping state
  - logged out state
  - logged in state
  - role access restrictions

## 5. How frontend and backend connect

The main integration path is:

1. Flutter screen or ViewModel asks for data
2. Frontend repository/service sends HTTP request with `ApiClient`
3. Backend receives the request in `/api/...`
4. Backend validates data with serializers
5. Backend reads/writes models and runs business logic
6. Backend returns JSON
7. Frontend parses JSON into models and updates the UI

Examples of matching areas:

- Frontend auth service -> Backend `auth/login/`, `auth/logout/`, `auth/me/`
- Frontend user management -> Backend `users/`
- Frontend employee/dependent screens -> Backend `employees/` and `dependents/`
- Frontend prescription screens -> Backend `prescriptions/`
- Frontend insurance screens -> Backend `insurance-requests/`
- Frontend notifications -> Backend `notifications/`

## 6. Current architecture style

The project is mainly organized as:

- Backend:
  Django + DRF with layered separation:
  - models 
  - serializers
  - viewsets/views
  - services
  - permissions/utilities

- Frontend:
  Flutter with layered separation:
  - app/core
  - data
  - features/presentation
  - shared

It is not a strict full MVVM app in every screen.

Instead, the frontend uses:

- MVVM-style state for global concerns like auth and notifications
- service/repository-driven screens for many feature pages

## 7. Best files to read first

If someone wants to understand the project quickly, read these first:

### Backend

1. `manage.py`
2. `healthbridge/urls.py`
3. `core/models.py`
4. `core/serializers.py`
5. `core/api/views/common.py`
6. `core/api/views/users.py`
7. `core/api/views/workflow.py`
8. `core/services/workflow_service.py`

### Frontend

1. `healthbridge_mobile/lib/main.dart`
2. `healthbridge_mobile/lib/src/app/app.dart`
3. `healthbridge_mobile/lib/src/app/router/app_router.dart`
4. `healthbridge_mobile/lib/src/core/network/api_client.dart`
5. `healthbridge_mobile/lib/src/data/services/auth_service.dart`
6. `healthbridge_mobile/lib/src/data/services/app_data_service.dart`
7. `healthbridge_mobile/lib/src/features/auth/presentation/viewmodels/auth_view_model.dart`
8. `healthbridge_mobile/lib/src/features/admin/presentation/views/admin_views.dart`

## 8. Summary

This repo is a full-stack system with:

- Django backend for auth, business rules, workflows, notifications, and persistence
- Flutter frontend for all user roles
- role-based navigation on the frontend
- role-based access control on the backend
- repository/service pattern in Flutter
- serializer/viewset/service pattern in Django

If you want to add a new feature, the usual path is:

1. Add or update backend model/serializer/view/API logic
2. Add frontend model/service/repository support
3. Add or update screen/ViewModel behavior
4. Register route if the feature needs a new page
