import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/models/user_model.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';
import 'package:healthbridge_mobile/modelView/features/admin/admin_home_view_model.dart';
import 'package:healthbridge_mobile/modelView/features/admin/admin_settings_view_model.dart';
import 'package:healthbridge_mobile/modelView/features/admin/admin_user_management_view_model.dart';
import 'package:healthbridge_mobile/view/features/common/profile_screen.dart';
import 'package:healthbridge_mobile/model/utils/app_roles.dart';
import 'package:healthbridge_mobile/model/utils/password_strength_validator.dart';
import 'package:healthbridge_mobile/model/utils/role_label.dart';
import 'package:healthbridge_mobile/view/widgets/hb_custom_card.dart';
import 'package:healthbridge_mobile/view/widgets/hb_empty_state.dart';
import 'package:healthbridge_mobile/view/widgets/hb_info_row.dart';
import 'package:healthbridge_mobile/view/widgets/hb_primary_button_row.dart';
import 'package:healthbridge_mobile/view/widgets/hb_scaffold.dart';
import 'package:healthbridge_mobile/view/widgets/hb_section_card.dart';
import 'package:healthbridge_mobile/view/widgets/hb_stat_card.dart';
import 'package:healthbridge_mobile/view/widgets/hb_status_chip.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  static const routeName = 'admin-home';
  static const routePath = '/admin';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          AdminHomeViewModel(appRepository: context.read<AppRepository>())
            ..load(),
      child: HbScaffold(
        title: 'الصفحة الرئيسية لمدير النظام',
        actions: _commonActions(context),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 920;
            final actionCardWidth = isWide
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth > 620
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            final generalCardWidth = constraints.maxWidth > 620
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            final viewModel = context.watch<AdminHomeViewModel>();
            final stats = viewModel.stats;

            return ListView(
              children: [
                if (viewModel.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (viewModel.error != null)
                  HbSectionCard(
                    title: 'معلومات عامة',
                    subtitle: 'تعذر تحميل المعلومات السريعة.',
                    child: HbEmptyState(
                      title: 'لا يمكن تحميل الإحصاءات',
                      message: viewModel.error.toString(),
                      icon: Icons.cloud_off_rounded,
                    ),
                  )
                else if (stats != null)
                  HbSectionCard(
                    title: 'معلومات عامة',
                    subtitle: 'مؤشرات سريعة مباشرة من قاعدة البيانات الحالية.',
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: generalCardWidth,
                          child: HbStatCard(
                            label: 'عدد المستخدمين',
                            value: '${stats.totalUsers}',
                            icon: Icons.groups_rounded,
                          ),
                        ),
                        SizedBox(
                          width: generalCardWidth,
                          child: HbStatCard(
                            label: 'الحسابات الفعالة',
                            value: '${stats.activeUsersCount}',
                            icon: Icons.verified_user_rounded,
                          ),
                        ),
                        SizedBox(
                          width: generalCardWidth,
                          child: HbStatCard(
                            label: 'الحسابات غير الفعالة',
                            value: '${stats.inactiveUsersCount}',
                            icon: Icons.person_off_rounded,
                          ),
                        ),
                        SizedBox(
                          width: generalCardWidth,
                          child: HbStatCard(
                            label: 'عدد الأطباء',
                            value: '${stats.doctorsCount}',
                            icon: Icons.medical_services_rounded,
                          ),
                        ),
                        SizedBox(
                          width: generalCardWidth,
                          child: HbStatCard(
                            label: 'عدد الموظفين الجامعيين',
                            value: '${stats.employeesCount}',
                            icon: Icons.personal_injury_rounded,
                          ),
                        ),
                        SizedBox(
                          width: generalCardWidth,
                          child: HbStatCard(
                            label: 'عدد الوصفات',
                            value: '${stats.prescriptionsCount}',
                            icon: Icons.description_outlined,
                          ),
                        ),
                        SizedBox(
                          width: generalCardWidth,
                          child: HbStatCard(
                            label: 'الطلبات المعلقة',
                            value: '${stats.pendingRequestsCount}',
                            icon: Icons.pending_actions_rounded,
                          ),
                        ),
                        SizedBox(
                          width: generalCardWidth,
                          child: HbStatCard(
                            label: 'عمليات الصرف',
                            value: '${stats.dispensesCount}',
                            icon: Icons.local_pharmacy_outlined,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const HbEmptyState(
                    title: 'لا توجد بيانات متاحة',
                    message: 'تعذر تكوين الملخص العام حاليًا.',
                    icon: Icons.info_outline_rounded,
                  ),
                const SizedBox(height: 16),
                Text(
                  'الإجراءات السريعة',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: actionCardWidth,
                      child: _AdminActionCard(
                        title: 'إدارة المستخدمين',
                        subtitle:
                            'عرض المستخدمين والبحث عنهم وتحديث صلاحياتهم.',
                        icon: Icons.manage_accounts_rounded,
                        onTap: () =>
                            context.push(AdminUserManagementScreen.routePath),
                      ),
                    ),
                    SizedBox(
                      width: actionCardWidth,
                      child: _AdminActionCard(
                        title: 'إضافة مستخدم',
                        subtitle:
                            'إنشاء حساب جديد للطبيب أو الموظف الجامعي أو الصيدلي أو موظف التأمين فقط.',
                        icon: Icons.person_add_alt_1_rounded,
                        onTap: () =>
                            context.push(AdminUserCreateScreen.routePath),
                      ),
                    ),
                    SizedBox(
                      width: actionCardWidth,
                      child: _AdminActionCard(
                        title: 'إعدادات / إدارة النظام',
                        subtitle:
                            'إدارة إعدادات النظام والتنبيهات والخيارات التشغيلية.',
                        icon: Icons.settings_suggest_rounded,
                        onTap: () =>
                            context.push(AdminSettingsScreen.routePath),
                      ),
                    ),
                    SizedBox(
                      width: actionCardWidth,
                      child: _AdminActionCard(
                        title: 'سجل المتابعة',
                        subtitle:
                            'مراجعة سجل الإجراءات والمتابعة الإدارية داخل النظام.',
                        icon: Icons.fact_check_outlined,
                        onTap: () =>
                            context.push(AdminAuditLogScreen.routePath),
                      ),
                    ),
                    SizedBox(
                      width: actionCardWidth,
                      child: _AdminActionCard(
                        title: 'الإحصاءات العامة',
                        subtitle: 'متابعة مؤشرات النظام والتقارير المختصرة.',
                        icon: Icons.insert_chart_outlined_rounded,
                        onTap: () =>
                            context.push(AdminStatisticsScreen.routePath),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0x140E5C4A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF0E5C4A), size: 26),
              ),
              const SizedBox(height: 14),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 14),
              Text(
                'فتح',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF0E5C4A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});

  static const routeName = 'admin-user-management';
  static const routePath = '/admin/users';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AdminUserManagementViewModel(
        appRepository: context.read<AppRepository>(),
      )..loadUsers(),
      child: const _AdminUserManagementScreenView(),
    );
  }
}

class _AdminUserManagementScreenView extends StatelessWidget {
  const _AdminUserManagementScreenView();

  Future<void> _openEditUser(BuildContext context, int userId) async {
    final updated = await context.push<bool>(
      '${AdminUserEditScreen.routePath}?id=$userId',
    );
    if (!context.mounted) return;
    if (updated == true) {
      await context.read<AdminUserManagementViewModel>().loadUsers();
    }
  }

  Future<void> _toggleUserStatus(BuildContext context, UserModel user) async {
    try {
      final message = await context
          .read<AdminUserManagementViewModel>()
          .toggleUserStatus(user);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _deleteUser(BuildContext context, UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف المستخدم'),
          content: Text(
            'هل أنت متأكد من حذف الحساب "${user.displayName}"؟ لا يمكن التراجع عن هذا الإجراء.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final message = await context
          .read<AdminUserManagementViewModel>()
          .deleteUser(user);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Widget _buildHeaderCard(
    BuildContext context,
    AdminUserManagementViewModel viewModel,
  ) {
    return HbCustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إدارة المستخدمين',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'عرض جميع الحسابات والبحث عنها وتعديلها من صفحة مستقلة عن إضافة المستخدم.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: viewModel.searchController,
            decoration: const InputDecoration(
              labelText: 'البحث عن مستخدم',
              hintText: 'ابحث بالاسم أو اسم المستخدم أو البريد',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: viewModel.updateSearchQuery,
          ),
          const SizedBox(height: 10),
          Text(
            'عدد المستخدمين: ${viewModel.filteredUsers.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(
    BuildContext context,
    AdminUserManagementViewModel viewModel,
    UserModel user,
  ) {
    return HbCustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              HbStatusChip(user.isActive ? 'فعّال' : 'غير فعّال'),
            ],
          ),
          const SizedBox(height: 10),
          HbInfoRow(label: 'اسم المستخدم', value: user.username),
          HbInfoRow(
            label: 'البريد',
            value: user.email.isEmpty ? 'غير متوفر' : user.email,
          ),
          HbInfoRow(label: 'الدور', value: roleLabel(user.role)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: viewModel.isBusy
                    ? null
                    : () => _openEditUser(context, user.id),
                child: const Text('عرض / تعديل'),
              ),
              OutlinedButton(
                onPressed: viewModel.isBusy || user.role == AppRoles.admin
                    ? null
                    : () => _toggleUserStatus(context, user),
                child: Text(user.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب'),
              ),
              OutlinedButton(
                onPressed: viewModel.isBusy || user.role == AppRoles.admin
                    ? null
                    : () => _deleteUser(context, user),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('حذف الحساب'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminUserManagementViewModel>();

    return HbScaffold(
      title: 'إدارة المستخدمين',
      actions: _commonActions(context),
      body: RefreshIndicator(
        onRefresh: () => viewModel.loadUsers(),
        child: ListView(
          children: [
            _buildHeaderCard(context, viewModel),
            const SizedBox(height: 16),
            if (viewModel.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (viewModel.errorMessage != null)
              HbEmptyState(
                title: 'تعذر تحميل المستخدمين',
                message: viewModel.errorMessage!,
                icon: Icons.cloud_off_rounded,
              )
            else if (viewModel.filteredUsers.isEmpty)
              const HbEmptyState(
                title: 'لا يوجد مستخدمون للعرض',
                message:
                    'لم يتم العثور على مستخدمين مطابقين لعبارة البحث الحالية.',
                icon: Icons.people_alt_outlined,
              )
            else
              ...viewModel.filteredUsers.map((user) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildUserTile(context, viewModel, user),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class AdminUserCreateScreen extends StatelessWidget {
  const AdminUserCreateScreen({super.key});

  static const routeName = 'admin-user-create';
  static const routePath = '/admin/users/create';

  @override
  Widget build(BuildContext context) {
    return const _AdminUserFormScreen(
      title: 'إضافة مستخدم',
      primaryLabel: 'حفظ المستخدم',
    );
  }
}

class AdminUserEditScreen extends StatelessWidget {
  const AdminUserEditScreen({super.key, this.userId});

  static const routeName = 'admin-user-edit';
  static const routePath = '/admin/users/edit';

  final int? userId;

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const HbScaffold(
        title: 'تعديل مستخدم',
        body: HbEmptyState(
          title: 'لا يوجد مستخدم محدد',
          message: 'يرجى اختيار مستخدم أولًا.',
        ),
      );
    }

    return FutureBuilder<List<UserModel>>(
      future: context.read<AppRepository>().getUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const HbScaffold(
            title: 'تعديل مستخدم',
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return HbScaffold(
            title: 'تعديل مستخدم',
            body: HbEmptyState(
              title: 'تعذر تحميل المستخدم',
              message: snapshot.error.toString(),
            ),
          );
        }

        final users = snapshot.data ?? const [];
        final matched = users.where((user) => user.id == userId).toList();
        if (matched.isEmpty) {
          return const HbScaffold(
            title: 'تعديل مستخدم',
            body: HbEmptyState(
              title: 'المستخدم غير متوفر',
              message: 'تعذر العثور على المستخدم المطلوب.',
            ),
          );
        }

        return _AdminUserFormScreen(
          title: 'تعديل مستخدم',
          primaryLabel: 'حفظ التعديلات',
          initialUser: matched.first,
        );
      },
    );
  }
}

class _AdminUserFormScreen extends StatefulWidget {
  const _AdminUserFormScreen({
    required this.title,
    required this.primaryLabel,
    this.initialUser,
  });

  final String title;
  final String primaryLabel;
  final UserModel? initialUser;

  @override
  State<_AdminUserFormScreen> createState() => _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends State<_AdminUserFormScreen> {
  final _formKey = GlobalKey<FormState>();

  static const _statusOptions = ['فعّال', 'غير فعّال'];

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late String _selectedRole;
  late String _selectedStatus;
  PatientModel? _patientProfile;
  final List<_EditableDependentForm> _dependents = [];
  final Set<int> _deletedDependentIds = <int>{};
  bool _isLoadingPatientData = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialUser?.displayName ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.initialUser?.username ?? '',
    );
    _emailController = TextEditingController(
      text: widget.initialUser?.email ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialUser?.phoneNumber ?? '',
    );
    _passwordController = TextEditingController();
    final initialRoleArabic = widget.initialUser == null
        ? ''
        : roleLabel(widget.initialUser!.role);
    final assignableLabels = assignableRoleOptions
        .map((item) => item.label)
        .toList();
    _selectedRole = assignableLabels.contains(initialRoleArabic)
        ? initialRoleArabic
        : (widget.initialUser?.role == AppRoles.admin
              ? roleLabel(AppRoles.admin)
              : assignableRoleOptions.first.label);
    _selectedStatus = widget.initialUser?.isActive == false
        ? _statusOptions[1]
        : _statusOptions[0];
    _loadPatientDataIfNeeded();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    for (final dependent in _dependents) {
      dependent.dispose();
    }
    super.dispose();
  }

  bool get _isPatientRole => _roleToBackend(_selectedRole) == 'Employee';
  bool get _isPrimaryAdmin => widget.initialUser?.role == AppRoles.admin;

  Future<void> _loadPatientDataIfNeeded() async {
    if (widget.initialUser?.role != 'Employee') {
      return;
    }

    setState(() => _isLoadingPatientData = true);
    try {
      final patient = await context.read<AppRepository>().getEmployeeByUser(
        username: widget.initialUser!.username,
        email: widget.initialUser!.email,
      );
      if (!mounted || patient == null) {
        return;
      }

      for (final dependent in _dependents) {
        dependent.dispose();
      }
      _dependents
        ..clear()
        ..addAll(patient.dependents.map(_EditableDependentForm.fromModel));

      setState(() {
        _patientProfile = patient;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تحميل بيانات المستفيدين للموظف الجامعي المحدد.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingPatientData = false);
      }
    }
  }

  void _addDependent() {
    setState(() {
      _dependents.add(_EditableDependentForm.empty());
    });
  }

  void _removeDependent(_EditableDependentForm dependent) {
    setState(() {
      if (dependent.id != null) {
        _deletedDependentIds.add(dependent.id!);
      }
      _dependents.remove(dependent);
      dependent.dispose();
    });
  }

  Future<void> _pickDependentDate(_EditableDependentForm dependent) async {
    final initialDate = dependent.dateOfBirth ?? DateTime(2010);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      dependent.dateOfBirth = picked;
      dependent.dateOfBirthController.text = _formatDate(picked);
    });
  }

  List<Map<String, dynamic>> _buildDependentsPayload() {
    return _dependents.map((dependent) {
      return {
        'full_name': dependent.fullNameController.text.trim(),
        'national_id': dependent.nationalIdController.text.trim(),
        'relation': dependent.relation,
        'date_of_birth': dependent.dateOfBirth == null
            ? null
            : _formatIsoDate(dependent.dateOfBirth!),
        'is_active': dependent.isActive,
      };
    }).toList();
  }

  Future<void> _syncDependents({required int patientId}) async {
    final service = context.read<AppRepository>();

    for (final dependentId in _deletedDependentIds) {
      await service.deleteDependent(dependentId);
    }

    for (final dependent in _dependents) {
      final payload = {
        'employee': patientId,
        'full_name': dependent.fullNameController.text.trim(),
        'national_id': dependent.nationalIdController.text.trim(),
        'relation': dependent.relation,
        'date_of_birth': dependent.dateOfBirth == null
            ? null
            : _formatIsoDate(dependent.dateOfBirth!),
        'is_active': dependent.isActive,
      };

      if (dependent.id == null) {
        await service.createDependent(payload);
      } else {
        await service.updateDependent(dependent.id!, payload);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: widget.title,
      body: ListView(
        children: [
          Form(
            key: _formKey,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال الاسم الكامل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المستخدم',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال اسم المستخدم';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال البريد الإلكتروني';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: widget.initialUser == null
                            ? 'كلمة المرور'
                            : 'كلمة المرور الجديدة',
                        helperText:
                            '8+ أحرف مع حرف كبير وحرف صغير ورقم ورمز خاص',
                      ),
                      validator: (value) => PasswordStrengthValidator.validate(
                        value,
                        isRequired: widget.initialUser == null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(labelText: 'الدور'),
                      items:
                          (_isPrimaryAdmin
                                  ? const [
                                      AppRoleOption(
                                        backendValue: AppRoles.admin,
                                        label: 'مدير النظام',
                                      ),
                                    ]
                                  : assignableRoleOptions)
                              .map(
                                (role) => DropdownMenuItem<String>(
                                  value: role.label,
                                  child: Text(role.label),
                                ),
                              )
                              .toList(),
                      onChanged: _isPrimaryAdmin
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _selectedRole = value);
                            },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'حالة الحساب',
                      ),
                      items: _statusOptions
                          .map(
                            (status) => DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: _isPrimaryAdmin
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _selectedStatus = value);
                            },
                    ),
                    if (_isPatientRole) ...[
                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'المستفيدون',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addDependent,
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            label: const Text('إضافة مستفيد'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingPatientData)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(),
                        )
                      else if (_dependents.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F8F7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'لا يوجد مستفيدون حاليًا. يمكنك إضافة مستفيد جديد من الزر أعلاه.',
                          ),
                        )
                      else
                        ..._dependents.asMap().entries.map((entry) {
                          final index = entry.key;
                          final dependent = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _DependentEditorCard(
                              index: index + 1,
                              dependent: dependent,
                              onRemove: () => _removeDependent(dependent),
                              onPickDate: () => _pickDependentDate(dependent),
                              onToggleActive: (value) {
                                setState(() {
                                  dependent.isActive = value;
                                });
                              },
                            ),
                          );
                        }),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          HbPrimaryButtonRow(
            primaryLabel: _isSaving ? 'جاري الحفظ...' : widget.primaryLabel,
            onPrimaryPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              setState(() => _isSaving = true);
              final userPayload = {
                'first_name': _splitName(_nameController.text).$1,
                'last_name': _splitName(_nameController.text).$2,
                'username': _usernameController.text.trim(),
                'email': _emailController.text.trim(),
                'phone_number': _phoneController.text.trim(),
                'role': _roleToBackend(_selectedRole),
                'is_active': _isPrimaryAdmin
                    ? true
                    : _selectedStatus == 'فعّال',
                if (_passwordController.text.trim().isNotEmpty)
                  'password': _passwordController.text.trim(),
              };
              final appDataService = context.read<AppRepository>();

              try {
                if (_isPatientRole) {
                  if (widget.initialUser == null) {
                    await appDataService.createEmployee({
                      'user': {
                        'full_name': _nameController.text.trim(),
                        'username': _usernameController.text.trim(),
                        'email': _emailController.text.trim(),
                        'phone': _phoneController.text.trim(),
                        'is_active': _isPrimaryAdmin
                            ? true
                            : _selectedStatus == 'فعّال',
                        if (_passwordController.text.trim().isNotEmpty)
                          'password': _passwordController.text.trim(),
                      },
                      'dependents': _buildDependentsPayload(),
                    });
                  } else {
                    await appDataService.updateUser(
                      widget.initialUser!.id,
                      userPayload,
                    );
                    final patient =
                        _patientProfile ??
                        await appDataService.getEmployeeByUser(
                          username: _usernameController.text.trim(),
                          email: _emailController.text.trim(),
                        );
                    if (patient == null) {
                      throw Exception(
                        'تعذر العثور على ملف الموظف الجامعي لتحديث المستفيدين.',
                      );
                    }
                    _patientProfile = patient;
                    await _syncDependents(patientId: patient.id);
                  }
                } else {
                  if (widget.initialUser == null) {
                    await appDataService.createUser(userPayload);
                  } else {
                    await appDataService.updateUser(
                      widget.initialUser!.id,
                      userPayload,
                    );
                  }
                }

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.initialUser == null
                          ? 'تم إنشاء المستخدم بنجاح'
                          : 'تم تحديث المستخدم بنجاح',
                    ),
                  ),
                );
                context.pop(true);
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error.toString())));
              } finally {
                if (mounted) {
                  setState(() => _isSaving = false);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

String _roleToBackend(String role) {
  for (final option in assignableRoleOptions) {
    if (option.label == role) {
      return option.backendValue;
    }
  }
  return switch (role) {
    'مدير النظام' => AppRoles.admin,
    'الطبيب' => AppRoles.doctor,
    'الموظف الجامعي' => AppRoles.employee,
    'الصيدلي' => AppRoles.pharmacist,
    'موظف التأمين' => AppRoles.insuranceOfficer,
    _ => AppRoles.employee,
  };
}

(String, String) _splitName(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return ('', '');
  }
  if (parts.length == 1) {
    return (parts.first, '');
  }
  return (parts.first, parts.sublist(1).join(' '));
}

String _formatDate(DateTime value) {
  return DateFormat('yyyy/MM/dd').format(value);
}

String _formatIsoDate(DateTime value) {
  return DateFormat('yyyy-MM-dd').format(value);
}

class _EditableDependentForm {
  _EditableDependentForm({
    this.id,
    required String fullName,
    required String nationalId,
    required this.relation,
    required this.isActive,
    required this.dateOfBirth,
  }) : fullNameController = TextEditingController(text: fullName),
       nationalIdController = TextEditingController(text: nationalId),
       dateOfBirthController = TextEditingController(
         text: dateOfBirth == null ? '' : _formatDate(dateOfBirth),
       );

  factory _EditableDependentForm.empty() {
    return _EditableDependentForm(
      fullName: '',
      nationalId: '',
      relation: _DependentEditorCard.relationOptions.first.$1,
      isActive: true,
      dateOfBirth: null,
    );
  }

  factory _EditableDependentForm.fromModel(DependentModel model) {
    return _EditableDependentForm(
      id: model.id,
      fullName: model.fullName,
      nationalId: model.nationalId,
      relation: model.relation.isEmpty
          ? _DependentEditorCard.relationOptions.first.$1
          : model.relation,
      isActive: model.isActive,
      dateOfBirth: model.dateOfBirth,
    );
  }

  final int? id;
  final TextEditingController fullNameController;
  final TextEditingController nationalIdController;
  final TextEditingController dateOfBirthController;
  String relation;
  bool isActive;
  DateTime? dateOfBirth;

  void dispose() {
    fullNameController.dispose();
    nationalIdController.dispose();
    dateOfBirthController.dispose();
  }
}

class _DependentEditorCard extends StatelessWidget {
  const _DependentEditorCard({
    required this.index,
    required this.dependent,
    required this.onRemove,
    required this.onPickDate,
    required this.onToggleActive,
  });

  static const relationOptions = [
    ('son', 'ابن'),
    ('daughter', 'ابنة'),
    ('wife', 'زوجة'),
  ];

  final int index;
  final _EditableDependentForm dependent;
  final VoidCallback onRemove;
  final VoidCallback onPickDate;
  final ValueChanged<bool> onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E8E2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'المستفيد $index',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: 'حذف المستفيد',
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          TextFormField(
            controller: dependent.fullNameController,
            decoration: const InputDecoration(
              labelText: 'الاسم الكامل للمستفيد',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال اسم المستفيد';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: dependent.nationalIdController,
            decoration: const InputDecoration(
              labelText: 'رقم الهوية - اختياري',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: dependent.relation,
            decoration: const InputDecoration(labelText: 'صلة القرابة'),
            items: relationOptions
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.$1,
                    child: Text(item.$2),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              dependent.relation = value;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى اختيار صلة القرابة';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: dependent.dateOfBirthController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'تاريخ الميلاد - اختياري',
              suffixIcon: IconButton(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_month_outlined),
              ),
            ),
            onTap: onPickDate,
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('المستفيد فعّال'),
            value: dependent.isActive,
            onChanged: onToggleActive,
          ),
        ],
      ),
    );
  }
}

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  static const routeName = 'admin-audit-logs';
  static const routePath = '/admin/logs';

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'سجل المتابعة',
      actions: _commonActions(context),
      body: FutureBuilder<List<AuditLogModel>>(
        future: context.read<AppRepository>().getAuditLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return HbEmptyState(
              title: 'تعذر تحميل سجل المتابعة',
              message: snapshot.error.toString(),
              icon: Icons.cloud_off_rounded,
            );
          }

          final logs = (snapshot.data ?? const <AuditLogModel>[]).where((log) {
            final q = _query.trim().toLowerCase();
            if (q.isEmpty) return true;
            return log.action.toLowerCase().contains(q) ||
                log.actorUsername.toLowerCase().contains(q) ||
                log.targetModel.toLowerCase().contains(q) ||
                log.details.toLowerCase().contains(q);
          }).toList();

          return ListView(
            children: [
              HbCustomCard(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'البحث في السجل',
                    hintText: 'ابحث بالفعل أو المستخدم أو التفاصيل',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const SizedBox(height: 16),
              if (logs.isEmpty)
                const HbEmptyState(
                  title: 'لا توجد سجلات',
                  message:
                      'لم يتم العثور على سجلات مطابقة أو لا توجد أنشطة مسجلة بعد.',
                  icon: Icons.fact_check_outlined,
                )
              else
                ...logs.map((log) {
                  final timestamp = log.createdAt == null
                      ? 'غير محدد'
                      : DateFormat(
                          'yyyy/MM/dd - HH:mm',
                        ).format(log.createdAt!.toLocal());
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: HbCustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  log.action,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              HbStatusChip(
                                log.targetModel.isEmpty
                                    ? 'System'
                                    : log.targetModel,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          HbInfoRow(
                            label: 'المنفذ',
                            value: log.actorUsername.isEmpty
                                ? 'غير معروف'
                                : log.actorUsername,
                          ),
                          HbInfoRow(
                            label: 'العنصر',
                            value: log.targetId.isEmpty
                                ? (log.targetModel.isEmpty
                                      ? 'غير محدد'
                                      : log.targetModel)
                                : '${log.targetModel} #${log.targetId}',
                          ),
                          HbInfoRow(label: 'الوقت', value: timestamp),
                          if (log.details.trim().isNotEmpty)
                            HbInfoRow(label: 'التفاصيل', value: log.details),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  static const routeName = 'admin-statistics';
  static const routePath = '/admin/statistics';

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'الإحصاءات العامة',
      actions: _commonActions(context),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          context.read<AppRepository>().getUsers(),
          context.read<AppRepository>().getPrescriptions(),
          context.read<AppRepository>().getInsuranceRequests(),
          context.read<AppRepository>().getDispenses(),
          context.read<AppRepository>().getAuditLogs(),
          context.read<AppRepository>().getSystemSettings(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return HbEmptyState(
              title: 'تعذر تحميل لوحة الإحصاءات',
              message: snapshot.error.toString(),
              icon: Icons.cloud_off_rounded,
            );
          }

          final users = snapshot.data![0] as List<UserModel>;
          final prescriptions = snapshot.data![1] as List<PrescriptionModel>;
          final insuranceRequests =
              snapshot.data![2] as List<InsuranceRequestModel>;
          final dispenses = snapshot.data![3] as List<DispenseModel>;
          final auditLogs = snapshot.data![4] as List<AuditLogModel>;
          final systemSettings = snapshot.data![5] as SystemSettingsModel;

          final totalUsers = users.length;
          final activeUsersCount = users.where((u) => u.isActive).length;
          final inactiveUsersCount = totalUsers - activeUsersCount;
          final doctorsCount = users
              .where((u) => u.role == AppRoles.doctor)
              .length;
          final employeesCount = users
              .where((u) => u.role == AppRoles.employee)
              .length;
          final pharmacistsCount = users
              .where((u) => u.role == AppRoles.pharmacist)
              .length;
          final insuranceCount = users
              .where((u) => u.role == AppRoles.insuranceOfficer)
              .length;
          final adminsCount = users
              .where((u) => u.role == AppRoles.admin)
              .length;
          final pendingRequests = insuranceRequests
              .where((r) => r.status == 'Pending')
              .length;
          final approvedRequests = insuranceRequests
              .where((r) => r.status == 'Approved')
              .length;
          final completedDispenses = dispenses
              .where((item) => item.status == 'Completed')
              .length;
          final latestAuditLog = auditLogs.isEmpty ? null : auditLogs.first;
          final latestPrescription = prescriptions.isEmpty
              ? null
              : prescriptions.first;
          final latestSettingsUpdate = systemSettings.updatedAt;

          final roleSegments = _buildRoleSegments(
            totalUsers: totalUsers,
            employeesCount: employeesCount,
            doctorsCount: doctorsCount,
            pharmacistsCount: pharmacistsCount,
            insuranceCount: insuranceCount,
            adminsCount: adminsCount,
          );
          final monthlySeries = _buildPrescriptionSeries(prescriptions);
          final prescriptionProgress = prescriptions.isEmpty
              ? 0.0
              : prescriptions.where((item) => item.status != 'Draft').length /
                    prescriptions.length;
          final insuranceProgress = insuranceRequests.isEmpty
              ? 0.0
              : insuranceRequests
                        .where((item) => item.status != 'Pending')
                        .length /
                    insuranceRequests.length;
          final dispenseProgress = dispenses.isEmpty
              ? 0.0
              : dispenses.where((item) => item.status == 'Completed').length /
                    dispenses.length;

          return LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = constraints.maxWidth > 980
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0E5C4A), Color(0xFF177864)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'لوحة الإحصاءات والتحليل',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${systemSettings.systemName.isEmpty ? 'HealthBridge' : systemSettings.systemName} • ${systemSettings.organizationName.isEmpty ? 'النظام متصل بقاعدة البيانات الحالية' : systemSettings.organizationName}',
                          style: const TextStyle(
                            color: Color(0xFFEAF7F3),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _statisticsCard(
                        'عدد المستخدمين',
                        '$totalUsers',
                        Icons.groups_rounded,
                      ),
                      _statisticsCard(
                        'الحسابات الفعالة',
                        '$activeUsersCount',
                        Icons.verified_user_rounded,
                      ),
                      _statisticsCard(
                        'الحسابات غير الفعالة',
                        '$inactiveUsersCount',
                        Icons.person_off_rounded,
                      ),
                      _statisticsCard(
                        'عدد الأطباء',
                        '$doctorsCount',
                        Icons.medical_services_rounded,
                      ),
                      _statisticsCard(
                        'عدد الموظفين الجامعيين',
                        '$employeesCount',
                        Icons.personal_injury_rounded,
                      ),
                      _statisticsCard(
                        'عدد الوصفات',
                        '${prescriptions.length}',
                        Icons.description_outlined,
                      ),
                      _statisticsCard(
                        'الطلبات المعلقة',
                        '$pendingRequests',
                        Icons.pending_actions_rounded,
                      ),
                      _statisticsCard(
                        'عمليات الصرف',
                        '${dispenses.length}',
                        Icons.local_pharmacy_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: chartWidth,
                        child: HbSectionCard(
                          title: 'اتجاه الوصفات خلال الأشهر الستة الأخيرة',
                          subtitle:
                              'عدد الوصفات الطبية المسجلة شهريًا وفق قاعدة البيانات الحالية.',
                          child: Column(
                            children: [
                              SizedBox(
                                height: 240,
                                child: CustomPaint(
                                  painter: _BarChartPainter(
                                    values: monthlySeries.$1,
                                    labels: monthlySeries.$2,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _InsightCallout(
                                title: 'تحليل',
                                message:
                                    'تم احتساب هذا المخطط من ${prescriptions.length} وصفة محفوظة حاليًا في النظام.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: HbSectionCard(
                          title: 'توزيع المستخدمين حسب الدور',
                          subtitle:
                              'النسب الحالية مستخرجة من حسابات المستخدمين الفعلية.',
                          child: Column(
                            children: [
                              SizedBox(
                                height: 240,
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: CustomPaint(
                                        painter: _DonutChartPainter(
                                          roleSegments,
                                          totalUsers,
                                        ),
                                        child: const SizedBox.expand(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: roleSegments
                                            .map(
                                              (segment) =>
                                                  _LegendTile(segment: segment),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _InsightCallout(
                                title: 'تحليل',
                                message: totalUsers == 0
                                    ? 'لا توجد حسابات مستخدمين بعد لعرض توزيع الأدوار.'
                                    : 'التوزيع الحالي مبني على $totalUsers حسابًا فعليًا، وأكثر الأدوار ظهورًا هو الدور ذو النسبة الأعلى في الرسم.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: HbSectionCard(
                          title: 'مؤشرات التشغيل الحالية',
                          subtitle:
                              'نسب مبنية على حالة السجلات الحالية داخل النظام.',
                          child: Column(
                            children: [
                              _ProgressMetric(
                                label: 'إرسال الوصفات',
                                valueText:
                                    '${(prescriptionProgress * 100).round()}%',
                                progress: prescriptionProgress,
                                color: const Color(0xFF0E5C4A),
                              ),
                              const SizedBox(height: 14),
                              _ProgressMetric(
                                label: 'معالجة طلبات التأمين',
                                valueText:
                                    '${(insuranceProgress * 100).round()}%',
                                progress: insuranceProgress,
                                color: const Color(0xFF4C6FFF),
                              ),
                              const SizedBox(height: 14),
                              _ProgressMetric(
                                label: 'اكتمال الصرف',
                                valueText:
                                    '${(dispenseProgress * 100).round()}%',
                                progress: dispenseProgress,
                                color: const Color(0xFFE2A93B),
                              ),
                              const SizedBox(height: 12),
                              _InsightCallout(
                                title: 'تحليل',
                                message:
                                    'من أصل ${prescriptions.length} وصفة و${insuranceRequests.length} طلب تأمين و${dispenses.length} عملية صرف، يتم تحديث هذه النسب مباشرة من حالة السجلات في قاعدة البيانات.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: HbSectionCard(
                          title: 'ملخص إداري',
                          subtitle:
                              'مؤشرات مباشرة من البيانات الحالية تساعد في المتابعة واتخاذ القرار.',
                          child: Column(
                            children: [
                              HbInfoRow(
                                label: 'اسم النظام',
                                value: systemSettings.systemName.isEmpty
                                    ? 'غير محدد'
                                    : systemSettings.systemName,
                              ),
                              HbInfoRow(
                                label: 'الجهة',
                                value: systemSettings.organizationName.isEmpty
                                    ? 'غير محددة'
                                    : systemSettings.organizationName,
                              ),
                              HbInfoRow(
                                label: 'عدد سجلات المتابعة',
                                value: '${auditLogs.length}',
                              ),
                              HbInfoRow(
                                label: 'طلبات التأمين المعتمدة',
                                value: '$approvedRequests',
                              ),
                              HbInfoRow(
                                label: 'عمليات الصرف المكتملة',
                                value: '$completedDispenses',
                              ),
                              HbInfoRow(
                                label: 'آخر إجراء مسجل',
                                value: latestAuditLog == null
                                    ? 'لا توجد سجلات'
                                    : '${latestAuditLog.action} - ${latestAuditLog.actorUsername}',
                              ),
                              HbInfoRow(
                                label: 'آخر وصفة مسجلة',
                                value: latestPrescription == null
                                    ? 'لا توجد وصفات'
                                    : latestPrescription.prescriptionNumber,
                              ),
                              HbInfoRow(
                                label: 'الإشعارات النظامية',
                                value: systemSettings.notificationsEnabled
                                    ? 'مفعلة'
                                    : 'متوقفة',
                              ),
                              HbInfoRow(
                                label: 'مسار التأمين',
                                value: systemSettings.insuranceWorkflowEnabled
                                    ? 'مفعل'
                                    : 'متجاوز',
                              ),
                              HbInfoRow(
                                label: 'آخر تحديث للإعدادات',
                                value: latestSettingsUpdate == null
                                    ? 'لا يوجد'
                                    : DateFormat(
                                        'yyyy/MM/dd - HH:mm',
                                      ).format(latestSettingsUpdate.toLocal()),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  static const routeName = 'admin-settings';
  static const routePath = '/admin/settings';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          AdminSettingsViewModel(appRepository: context.read<AppRepository>())
            ..loadSettings(),
      child: const _AdminSettingsScreenView(),
    );
  }
}

class _AdminSettingsScreenView extends StatelessWidget {
  const _AdminSettingsScreenView();

  Future<void> _saveSettings(BuildContext context) async {
    try {
      final message = await context
          .read<AdminSettingsViewModel>()
          .saveSettings();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminSettingsViewModel>();

    return HbScaffold(
      title: 'إعدادات النظام',
      actions: _commonActions(context),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.error != null
          ? HbEmptyState(
              title: 'تعذر تحميل إعدادات النظام',
              message: viewModel.error.toString(),
              icon: Icons.cloud_off_rounded,
            )
          : ListView(
              children: [
                HbSectionCard(
                  title: 'الهوية العامة للنظام',
                  subtitle: 'إعدادات أساسية تظهر في النظام والواجهات الإدارية.',
                  child: Column(
                    children: [
                      TextField(
                        controller: viewModel.systemNameController,
                        decoration: InputDecoration(
                          labelText: 'اسم النظام',
                          hintText: 'هيلث بريدج',
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: viewModel.organizationNameController,
                        decoration: InputDecoration(
                          labelText: 'اسم الجهة',
                          hintText: 'جامعة بوليتكنك فلسطين',
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: viewModel.shortDescriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'وصف مختصر',
                          hintText:
                              'نظام إلكتروني لإدارة الوصفات الطبية والتأمين والصرف',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                HbSectionCard(
                  title: 'الإعدادات التشغيلية',
                  subtitle: 'التحكم بسلوك النظام والإشعارات وسير العمل.',
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: viewModel.notificationsEnabled,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('تفعيل الإشعارات النظامية'),
                        subtitle: const Text(
                          'إرسال إشعارات للمستخدمين عند تغير حالة الوصفة أو التأمين',
                        ),
                        onChanged: viewModel.setNotificationsEnabled,
                      ),
                      SwitchListTile.adaptive(
                        value: viewModel.insuranceWorkflowEnabled,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('تفعيل سير موافقات التأمين'),
                        subtitle: const Text(
                          'تمرير الوصفات إلى موظف التأمين قبل الصرف عند الحاجة',
                        ),
                        onChanged: viewModel.setInsuranceWorkflowEnabled,
                      ),
                      SwitchListTile.adaptive(
                        value: viewModel.pharmacistNotesRequired,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('إلزام الصيدلي بإضافة ملاحظة'),
                        subtitle: const Text(
                          'مفيد لتوثيق عمليات الصرف في البيئة الجامعية',
                        ),
                        onChanged: viewModel.setPharmacistNotesRequired,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: viewModel.selectedLanguage,
                        key: ValueKey(viewModel.selectedLanguage),
                        decoration: const InputDecoration(
                          labelText: 'لغة الواجهة',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'العربية',
                            child: Text('العربية'),
                          ),
                          DropdownMenuItem(
                            value: 'English',
                            child: Text('English'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          viewModel.setSelectedLanguage(value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: viewModel.selectedSessionTimeout,
                        key: ValueKey(viewModel.selectedSessionTimeout),
                        decoration: const InputDecoration(
                          labelText: 'مدة الجلسة',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: '15 دقيقة',
                            child: Text('15 دقيقة'),
                          ),
                          DropdownMenuItem(
                            value: '30 دقيقة',
                            child: Text('30 دقيقة'),
                          ),
                          DropdownMenuItem(
                            value: '60 دقيقة',
                            child: Text('60 دقيقة'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          viewModel.setSelectedSessionTimeout(value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                HbSectionCard(
                  title: 'ملاحظات إدارية',
                  subtitle:
                      'ملاحظات حول النشر أو العرض التقديمي أو سياسات العمل.',
                  child: TextField(
                    controller: viewModel.adminNotesController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات',
                      hintText:
                          'يمكن كتابة سياسات داخلية أو ملاحظات تخص العرض أو بيئة التشغيل...',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                HbPrimaryButtonRow(
                  primaryLabel: viewModel.isSaving
                      ? 'جاري الحفظ...'
                      : 'حفظ الإعدادات',
                  onPrimaryPressed: viewModel.isSaving
                      ? null
                      : () => _saveSettings(context),
                  secondaryLabel: 'معاينة الملف الشخصي',
                  onSecondaryPressed: () =>
                      context.push(ProfileScreen.routePath),
                ),
              ],
            ),
    );
  }
}

class _InsightCallout extends StatelessWidget {
  const _InsightCallout({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.label,
    required this.valueText,
    required this.progress,
    required this.color,
  });

  final String label;
  final String valueText;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(valueText, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: progress,
            backgroundColor: const Color(0xFFE9EEF4),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _LegendTile extends StatelessWidget {
  const _LegendTile({required this.segment});

  final _ChartSegment segment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: segment.color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(segment.label)),
          Text('${segment.value.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }
}

class _ChartSegment {
  const _ChartSegment(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    const axisColor = Color(0xFFB8C4D2);
    const barColor = Color(0xFF0E5C4A);
    const labelColor = Color(0xFF5F6B6D);
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.2;
    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;
    final gridPaint = Paint()
      ..color = const Color(0xFFE9EEF4)
      ..strokeWidth = 1;

    const leftPadding = 16.0;
    const bottomPadding = 28.0;
    const topPadding = 12.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final chartWidth = size.width - leftPadding;
    final maxValue = values.reduce(math.max);

    for (var i = 0; i < 4; i++) {
      final y = topPadding + (chartHeight / 3) * i;
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width, y), gridPaint);
    }

    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, size.height - bottomPadding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftPadding, size.height - bottomPadding),
      Offset(size.width, size.height - bottomPadding),
      axisPaint,
    );

    final spacing = chartWidth / values.length;
    const barWidth = 26.0;

    for (var i = 0; i < values.length; i++) {
      final normalized = values[i] / maxValue;
      final barHeight = normalized * (chartHeight - 10);
      final x = leftPadding + spacing * i + (spacing - barWidth) / 2;
      final y = size.height - bottomPadding - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(10),
      );
      canvas.drawRRect(rect, barPaint);

      final valuePainter = TextPainter(
        text: TextSpan(
          text: values[i].toInt().toString(),
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF102A43),
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      valuePainter.paint(
        canvas,
        Offset(x + (barWidth - valuePainter.width) / 2, y - 18),
      );

      final labelPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            fontSize: 11,
            color: labelColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout(maxWidth: spacing);
      labelPainter.paint(
        canvas,
        Offset(
          leftPadding + spacing * i + (spacing - labelPainter.width) / 2,
          size.height - bottomPadding + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter(this.segments, this.totalUsers);

  final List<_ChartSegment> segments;
  final int totalUsers;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: math.min(size.width, size.height) / 2.4,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;

    var startAngle = -math.pi / 2;
    for (final segment in segments) {
      final sweep = 2 * math.pi * (segment.value / 100);
      paint.color = segment.color;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }

    final centerPainter = TextPainter(
      text: TextSpan(
        text: '$totalUsers\nمستخدم',
        style: TextStyle(
          color: Color(0xFF102A43),
          fontSize: 16,
          fontWeight: FontWeight.w800,
          height: 1.4,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: 80);

    centerPainter.paint(
      canvas,
      Offset(
        size.width / 2 - centerPainter.width / 2,
        size.height / 2 - centerPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}

SizedBox _statisticsCard(String label, String value, IconData icon) {
  return SizedBox(
    width: 320,
    child: HbStatCard(label: label, value: value, icon: icon),
  );
}

List<_ChartSegment> _buildRoleSegments({
  required int totalUsers,
  required int employeesCount,
  required int doctorsCount,
  required int pharmacistsCount,
  required int insuranceCount,
  required int adminsCount,
}) {
  double percent(int count) => totalUsers == 0 ? 0 : (count / totalUsers) * 100;

  return [
    _ChartSegment('موظفون', percent(employeesCount), const Color(0xFF0E5C4A)),
    _ChartSegment('أطباء', percent(doctorsCount), const Color(0xFF1F8F75)),
    _ChartSegment('صيادلة', percent(pharmacistsCount), const Color(0xFFE2A93B)),
    _ChartSegment('تأمين', percent(insuranceCount), const Color(0xFF4C6FFF)),
    _ChartSegment('إدارة', percent(adminsCount), const Color(0xFF8E44AD)),
  ].where((segment) => segment.value > 0).toList();
}

(List<double>, List<String>) _buildPrescriptionSeries(
  List<PrescriptionModel> prescriptions,
) {
  final now = DateTime.now();
  final months = List.generate(6, (index) {
    final date = DateTime(now.year, now.month - (5 - index), 1);
    final count = prescriptions.where((item) {
      final issued = item.issuedAt?.toLocal();
      if (issued == null) return false;
      return issued.year == date.year && issued.month == date.month;
    }).length;
    return (date, count.toDouble());
  });

  final labels = months
      .map((entry) => DateFormat('MMM', 'ar').format(entry.$1))
      .toList();
  final values = months.map((entry) => entry.$2).toList();
  final safeValues = values.every((value) => value == 0)
      ? values.map((_) => 1.0).toList()
      : values;
  return (safeValues, labels);
}

List<Widget> _commonActions(BuildContext context) {
  return [
    IconButton(
      onPressed: () => context.push(AdminAuditLogScreen.routePath),
      icon: const Icon(Icons.fact_check_outlined),
      tooltip: 'سجل التتبع',
    ),
    IconButton(
      onPressed: () => context.push(ProfileScreen.routePath),
      icon: const Icon(Icons.person_outline_rounded),
      tooltip: 'الملف الشخصي',
    ),
  ];
}
