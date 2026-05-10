import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../../../../data/models/app_models.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/app_data_service.dart';
import '../../../../features/common/presentation/screens/notifications_screen.dart';
import '../../../../features/common/presentation/screens/profile_screen.dart';
import '../../../../shared/utils/role_label.dart';
import '../../../../shared/widgets/hb_custom_card.dart';
import '../../../../shared/widgets/hb_dashboard_overview.dart';
import '../../../../shared/widgets/hb_empty_state.dart';
import '../../../../shared/widgets/hb_info_row.dart';
import '../../../../shared/widgets/hb_notification_action.dart';
import '../../../../shared/widgets/hb_primary_button_row.dart';
import '../../../../shared/widgets/hb_scaffold.dart';
import '../../../../shared/widgets/hb_section_card.dart';
import '../../../../shared/widgets/hb_stat_card.dart';
import '../../../../shared/widgets/hb_status_chip.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  static const routeName = 'admin-home';
  static const routePath = '/admin';

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
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

          return ListView(
            children: [
              const HbDashboardOverview(
                recentTitle: 'آخر التنبيهات والإجراءات',
                emptyMessage: 'ستظهر هنا أحدث التنبيهات المرتبطة بإدارة النظام.',
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
                      subtitle: 'عرض المستخدمين والبحث عنهم وتحديث صلاحياتهم.',
                      icon: Icons.manage_accounts_rounded,
                      onTap: () => context.push(AdminUserManagementScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionCardWidth,
                    child: _AdminActionCard(
                      title: 'إضافة مستخدم',
                      subtitle: 'إنشاء حساب جديد للطبيب أو الموظف الجامعي أو الصيدلي أو موظف التأمين أو الجهات الطبية.',
                      icon: Icons.person_add_alt_1_rounded,
                      onTap: () => context.push(AdminUserCreateScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionCardWidth,
                    child: _AdminActionCard(
                      title: 'إعدادات / إدارة النظام',
                      subtitle: 'إدارة إعدادات النظام والتنبيهات والخيارات التشغيلية.',
                      icon: Icons.settings_suggest_rounded,
                      onTap: () => context.push(AdminSettingsScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionCardWidth,
                    child: _AdminActionCard(
                      title: 'الإشعارات',
                      subtitle: 'مراجعة أحدث التنبيهات والتنبيهات النظامية.',
                      icon: Icons.notifications_active_outlined,
                      onTap: () => context.push(NotificationsScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionCardWidth,
                    child: _AdminActionCard(
                      title: 'الإحصاءات العامة',
                      subtitle: 'متابعة مؤشرات النظام والتقارير المختصرة.',
                      icon: Icons.insert_chart_outlined_rounded,
                      onTap: () => context.push(AdminStatisticsScreen.routePath),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              HbSectionCard(
                title: 'نظرة تشغيلية سريعة',
                subtitle: 'ملخص يساعدك في متابعة حالة النظام خلال اليوم.',
                child: Column(
                  children: const [
                    HbInfoRow(label: 'المستخدمون النشطون', value: '117 مستخدمًا'),
                    HbInfoRow(label: 'الوصفات الجديدة اليوم', value: '24 وصفة'),
                    HbInfoRow(label: 'طلبات التأمين المعلقة', value: '6 طلبات'),
                    HbInfoRow(label: 'عمليات الصرف اليوم', value: '13 عملية'),
                  ],
                ),
              ),
            ],
          );
        },
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
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  static const routeName = 'admin-user-management';
  static const routePath = '/admin/users';

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final _searchController = TextEditingController();
  List<UserModel> _users = const [];
  bool _isLoading = true;
  bool _isBusy = false;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final users = await context.read<AppDataService>().getUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openEditUser(int userId) async {
    final updated = await context.push<bool>(
      '${AdminUserEditScreen.routePath}?id=$userId',
    );
    if (!context.mounted) return;
    if (updated == true) {
      await _loadUsers();
    }
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    setState(() => _isBusy = true);
    try {
      await context.read<AppDataService>().updateUser(
        user.id,
        {
          'is_active': !user.isActive,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.isActive ? 'تم تعطيل المستخدم' : 'تم تفعيل المستخدم',
          ),
        ),
      );
      await _loadUsers();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  List<UserModel> get _filteredUsers {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    return _users.where((user) {
      if (normalizedQuery.isEmpty) return true;
      return user.displayName.toLowerCase().contains(normalizedQuery) ||
          user.username.toLowerCase().contains(normalizedQuery) ||
          user.email.toLowerCase().contains(normalizedQuery) ||
          roleLabel(user.role).toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  Widget _buildHeaderCard(BuildContext context) {
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
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'البحث عن مستخدم',
              hintText: 'ابحث بالاسم أو اسم المستخدم أو البريد',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 10),
          Text(
            'عدد المستخدمين: ${_filteredUsers.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, UserModel user) {
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
          HbInfoRow(label: 'البريد', value: user.email.isEmpty ? 'غير متوفر' : user.email),
          HbInfoRow(label: 'الدور', value: roleLabel(user.role)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _isBusy ? null : () => _openEditUser(user.id),
                child: const Text('عرض / تعديل'),
              ),
              TextButton(
                onPressed: _isBusy ? null : () => _toggleUserStatus(user),
                child: Text(user.isActive ? 'تعطيل' : 'تفعيل'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'إدارة المستخدمين',
      actions: _commonActions(context),
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView(
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              HbEmptyState(
                title: 'تعذر تحميل المستخدمين',
                message: _errorMessage!,
                icon: Icons.cloud_off_rounded,
              )
            else if (_filteredUsers.isEmpty)
              const HbEmptyState(
              title: 'لا يوجد مستخدمون للعرض',
                message: 'لم يتم العثور على مستخدمين مطابقين لعبارة البحث الحالية.',
                icon: Icons.people_alt_outlined,
              )
            else
              ..._filteredUsers.map((user) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildUserTile(context, user),
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
  const AdminUserEditScreen({
    super.key,
    this.userId,
  });

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
      future: context.read<AppDataService>().getUsers(),
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
  static const _roleOptions = [
    'مدير النظام',
    'الطبيب',
    'الموظف الجامعي',
    'الصيدلي',
    'موظف التأمين',
    'مختبر',
    'مركز التصوير الطبي',
    'مركز طبي',
  ];

  static const _statusOptions = [
    'فعّال',
    'غير فعّال',
  ];

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
    _nameController = TextEditingController(text: widget.initialUser?.displayName ?? '');
    _usernameController = TextEditingController(text: widget.initialUser?.username ?? '');
    _emailController = TextEditingController(text: widget.initialUser?.email ?? '');
    _phoneController = TextEditingController(text: widget.initialUser?.phoneNumber ?? '');
    _passwordController = TextEditingController();
    final initialRoleArabic = widget.initialUser == null ? '' : roleLabel(widget.initialUser!.role);
    _selectedRole = _roleOptions.contains(initialRoleArabic) ? initialRoleArabic : _roleOptions[1];
    _selectedStatus = widget.initialUser?.isActive == false ? _statusOptions[1] : _statusOptions[0];
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

  Future<void> _loadPatientDataIfNeeded() async {
    if (widget.initialUser?.role != 'Employee') {
      return;
    }

    setState(() => _isLoadingPatientData = true);
    try {
      final patient = await context.read<AppDataService>().getEmployeeByUser(
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
        const SnackBar(content: Text('تعذر تحميل بيانات المستفيدين للموظف الجامعي المحدد.')),
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
        'date_of_birth': dependent.dateOfBirth == null ? null : _formatIsoDate(dependent.dateOfBirth!),
        'is_active': dependent.isActive,
      };
    }).toList();
  }

  Future<void> _syncDependents({
    required int patientId,
  }) async {
    final service = context.read<AppDataService>();

    for (final dependentId in _deletedDependentIds) {
      await service.deleteDependent(dependentId);
    }

    for (final dependent in _dependents) {
      final payload = {
        'employee': patientId,
        'full_name': dependent.fullNameController.text.trim(),
        'national_id': dependent.nationalIdController.text.trim(),
        'relation': dependent.relation,
        'date_of_birth': dependent.dateOfBirth == null ? null : _formatIsoDate(dependent.dateOfBirth!),
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
                      decoration: const InputDecoration(labelText: 'الاسم الكامل'),
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
                      decoration: const InputDecoration(labelText: 'اسم المستخدم'),
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
                      decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
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
                      decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: widget.initialUser == null ? 'كلمة المرور' : 'كلمة المرور الجديدة',
                      ),
                      validator: (value) {
                        if (widget.initialUser == null && (value == null || value.trim().isEmpty)) {
                          return 'يرجى إدخال كلمة المرور';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(labelText: 'الدور'),
                      items: _roleOptions
                          .map(
                            (role) => DropdownMenuItem<String>(
                              value: role,
                              child: Text(role),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedRole = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(labelText: 'حالة الحساب'),
                      items: _statusOptions
                          .map(
                            (status) => DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
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
                          child: const Text('لا يوجد مستفيدون حاليًا. يمكنك إضافة مستفيد جديد من الزر أعلاه.'),
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
                'is_active': _selectedStatus == 'فعّال',
                if (_passwordController.text.trim().isNotEmpty)
                  'password': _passwordController.text.trim(),
              };
              final appDataService = context.read<AppDataService>();

              try {
                if (_isPatientRole) {
                  if (widget.initialUser == null) {
                    await appDataService.createEmployee({
                      'user': {
                        'full_name': _nameController.text.trim(),
                        'username': _usernameController.text.trim(),
                        'email': _emailController.text.trim(),
                        'phone': _phoneController.text.trim(),
                        'is_active': _selectedStatus == 'فعّال',
                        if (_passwordController.text.trim().isNotEmpty)
                          'password': _passwordController.text.trim(),
                      },
                      'dependents': _buildDependentsPayload(),
                    });
                  } else {
                    await appDataService.updateUser(widget.initialUser!.id, userPayload);
                    final patient = _patientProfile ??
                        await appDataService.getEmployeeByUser(
                          username: _usernameController.text.trim(),
                          email: _emailController.text.trim(),
                        );
                    if (patient == null) {
                      throw Exception('تعذر العثور على ملف الموظف الجامعي لتحديث المستفيدين.');
                    }
                    _patientProfile = patient;
                    await _syncDependents(patientId: patient.id);
                  }
                } else {
                  if (widget.initialUser == null) {
                    await appDataService.createUser(userPayload);
                  } else {
                    await appDataService.updateUser(widget.initialUser!.id, userPayload);
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error.toString())),
                );
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
  switch (role) {
    case 'مدير النظام':
      return 'Admin';
    case 'الطبيب':
      return 'Doctor';
    case 'الموظف الجامعي':
      return 'Employee';
    case 'الصيدلي':
      return 'Pharmacist';
    case 'موظف التأمين':
      return 'InsuranceOfficer';
    case 'مختبر':
      return 'Laboratory';
    case 'مركز التصوير الطبي':
      return 'ImagingCenter';
    case 'مركز طبي':
      return 'MedicalCenter';
    default:
      return 'Employee';
  }
}

(String, String) _splitName(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
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
  })  : fullNameController = TextEditingController(text: fullName),
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
      relation: model.relation.isEmpty ? _DependentEditorCard.relationOptions.first.$1 : model.relation,
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
            decoration: const InputDecoration(labelText: 'الاسم الكامل للمستفيد'),
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
            decoration: const InputDecoration(labelText: 'رقم الهوية - اختياري'),
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

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  static const routeName = 'admin-statistics';
  static const routePath = '/admin/statistics';

  @override
  Widget build(BuildContext context) {
    const monthlyPrescriptions = [18.0, 24.0, 21.0, 29.0, 34.0, 38.0];
    const roleDistribution = [
      _ChartSegment('موظفون', 62, Color(0xFF0E5C4A)),
      _ChartSegment('أطباء', 14, Color(0xFF1F8F75)),
      _ChartSegment('صيادلة', 10, Color(0xFFE2A93B)),
      _ChartSegment('تأمين', 8, Color(0xFF4C6FFF)),
      _ChartSegment('إدارة', 6, Color(0xFF8E44AD)),
    ];

    return HbScaffold(
      title: 'الإحصاءات العامة',
      actions: _commonActions(context),
      body: LayoutBuilder(
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لوحة الإحصاءات والتحليل',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'عرض تحليلي لمؤشرات الاستخدام، النشاط الشهري، توزيع الأدوار، وحالة التشغيل العامة داخل منصة هيلث بريدج.',
                      style: TextStyle(
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
                children: const [
                  SizedBox(
                    width: 320,
                    child: HbStatCard(
                      label: 'عدد المستخدمين',
                      value: '128',
                      icon: Icons.groups_rounded,
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: HbStatCard(
                      label: 'عدد الأطباء',
                      value: '18',
                      icon: Icons.medical_services_rounded,
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: HbStatCard(
                      label: 'عدد الموظفين الجامعيين',
                      value: '264',
                      icon: Icons.personal_injury_rounded,
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: HbStatCard(
                      label: 'عدد الوصفات',
                      value: '342',
                      icon: Icons.description_outlined,
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: HbStatCard(
                      label: 'الطلبات المعلقة',
                      value: '6',
                      icon: Icons.pending_actions_rounded,
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: HbStatCard(
                      label: 'عمليات الصرف',
                      value: '190',
                      icon: Icons.local_pharmacy_outlined,
                    ),
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
                      subtitle: 'يوضح هذا المخطط نمو عدد الوصفات الطبية الإلكترونية بشكل تدريجي ومستقر.',
                      child: Column(
                        children: [
                          SizedBox(
                            height: 240,
                            child: CustomPaint(
                              painter: _BarChartPainter(
                                values: monthlyPrescriptions,
                                labels: const ['نوف', 'ديس', 'ينا', 'فبر', 'مار', 'أبر'],
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const _InsightCallout(
                            title: 'تحليل',
                            message:
                                'هناك ارتفاع واضح في أبريل، ما يشير إلى زيادة الاعتماد على الوصفات الإلكترونية مع تحسن سير العمل في العيادات الجامعية.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: chartWidth,
                    child: HbSectionCard(
                      title: 'توزيع المستخدمين حسب الدور',
                      subtitle: 'يبين المخطط النسبي الفئات الأكثر استخدامًا داخل النظام.',
                      child: Column(
                        children: [
                          SizedBox(
                            height: 240,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: CustomPaint(
                                    painter: _DonutChartPainter(roleDistribution),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: roleDistribution
                                        .map((segment) => _LegendTile(segment: segment))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const _InsightCallout(
                            title: 'تحليل',
                            message:
                                'يشكل الموظفون الجامعيون النسبة الأكبر من الحسابات النشطة، بينما تبقى فئات الأطباء والصيادلة والتأمين والجهات الطبية ضمن نطاق تشغيلي متوازن.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: chartWidth,
                    child: HbSectionCard(
                      title: 'مؤشرات التشغيل اليومية',
                      subtitle: 'مقارنة سريعة بين الأداء الحالي والمستهدف في أهم العمليات.',
                      child: Column(
                        children: const [
                          _ProgressMetric(
                            label: 'إرسال الوصفات',
                            valueText: '92%',
                            progress: 0.92,
                            color: Color(0xFF0E5C4A),
                          ),
                          SizedBox(height: 14),
                          _ProgressMetric(
                            label: 'معالجة طلبات التأمين',
                            valueText: '81%',
                            progress: 0.81,
                            color: Color(0xFF4C6FFF),
                          ),
                          SizedBox(height: 14),
                          _ProgressMetric(
                            label: 'اكتمال الصرف',
                            valueText: '88%',
                            progress: 0.88,
                            color: Color(0xFFE2A93B),
                          ),
                          SizedBox(height: 12),
                          _InsightCallout(
                            title: 'تحليل',
                            message:
                                'أفضل أداء حالي هو في إرسال الوصفات، بينما يحتاج مسار التأمين إلى تقليل زمن الاستجابة لتحسين التجربة العامة.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: chartWidth,
                    child: HbSectionCard(
                      title: 'ملخص إداري وتوصيات',
                      subtitle: 'استنتاجات تشغيلية مختصرة تساعد في اتخاذ القرار.',
                      child: Column(
                        children: const [
                          HbInfoRow(label: 'متوسط زمن المراجعة', value: '1.8 يوم'),
                          HbInfoRow(label: 'أكثر وحدة نشاطًا', value: 'العيادة العامة'),
                          HbInfoRow(label: 'أكثر وصفة شيوعًا', value: 'علاجات الجهاز التنفسي'),
                          HbInfoRow(label: 'حالة النظام', value: 'مستقر مع حمل متوسط'),
                          SizedBox(height: 12),
                          _InsightCallout(
                            title: 'توصية',
                            message:
                                'يوصى بزيادة متابعة الطلبات المعلقة في التأمين وتوسيع التدريب على الصرف الإلكتروني لتحسين سرعة الإنجاز.',
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
      ),
    );
  }
}

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  static const routeName = 'admin-settings';
  static const routePath = '/admin/settings';

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool notificationsEnabled = true;
  bool insuranceWorkflowEnabled = true;
  bool pharmacistNotesRequired = false;
  String selectedLanguage = 'العربية';
  String selectedSessionTimeout = '30 دقيقة';

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'إعدادات النظام',
      actions: _commonActions(context),
      body: ListView(
        children: [
          HbSectionCard(
            title: 'الهوية العامة للنظام',
            subtitle: 'إعدادات أساسية تظهر في النظام والواجهات الإدارية.',
            child: Column(
              children: const [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'اسم النظام',
                    hintText: 'هيلث بريدج',
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'اسم الجهة',
                    hintText: 'جامعة بوليتكنك فلسطين',
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'وصف مختصر',
                    hintText: 'نظام إلكتروني لإدارة الوصفات الطبية والتأمين والصرف',
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
                  value: notificationsEnabled,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تفعيل الإشعارات النظامية'),
                  subtitle: const Text('إرسال إشعارات للمستخدمين عند تغير حالة الوصفة أو التأمين'),
                  onChanged: (value) => setState(() => notificationsEnabled = value),
                ),
                SwitchListTile.adaptive(
                  value: insuranceWorkflowEnabled,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تفعيل سير موافقات التأمين'),
                  subtitle: const Text('تمرير الوصفات إلى موظف التأمين قبل الصرف عند الحاجة'),
                  onChanged: (value) => setState(() => insuranceWorkflowEnabled = value),
                ),
                SwitchListTile.adaptive(
                  value: pharmacistNotesRequired,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('إلزام الصيدلي بإضافة ملاحظة'),
                  subtitle: const Text('مفيد لتوثيق عمليات الصرف في البيئة الجامعية'),
                  onChanged: (value) => setState(() => pharmacistNotesRequired = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedLanguage,
                  decoration: const InputDecoration(labelText: 'لغة الواجهة'),
                  items: const [
                    DropdownMenuItem(value: 'العربية', child: Text('العربية')),
                    DropdownMenuItem(value: 'English', child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedLanguage = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedSessionTimeout,
                  decoration: const InputDecoration(labelText: 'مدة الجلسة'),
                  items: const [
                    DropdownMenuItem(value: '15 دقيقة', child: Text('15 دقيقة')),
                    DropdownMenuItem(value: '30 دقيقة', child: Text('30 دقيقة')),
                    DropdownMenuItem(value: '60 دقيقة', child: Text('60 دقيقة')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedSessionTimeout = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HbSectionCard(
            title: 'ملاحظات إدارية',
            subtitle: 'ملاحظات حول النشر أو العرض التقديمي أو سياسات العمل.',
            child: const TextField(
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'ملاحظات',
                hintText: 'يمكن كتابة سياسات داخلية أو ملاحظات تخص العرض أو بيئة التشغيل...',
              ),
            ),
          ),
          const SizedBox(height: 16),
          HbPrimaryButtonRow(
            primaryLabel: 'حفظ الإعدادات',
            onPrimaryPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حفظ إعدادات النظام بنجاح')),
              );
            },
            secondaryLabel: 'معاينة الملف الشخصي',
            onSecondaryPressed: () => context.push(ProfileScreen.routePath),
          ),
        ],
      ),
    );
  }
}

class _InsightCallout extends StatelessWidget {
  const _InsightCallout({
    required this.title,
    required this.message,
  });

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
            Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
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
  const _LegendTile({
    required this.segment,
  });

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
  _BarChartPainter({
    required this.values,
    required this.labels,
  });

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
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        gridPaint,
      );
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
  _DonutChartPainter(this.segments);

  final List<_ChartSegment> segments;

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
      text: const TextSpan(
        text: '128\nمستخدم',
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

List<Widget> _commonActions(BuildContext context) {
  return [
    const HbNotificationAction(),
    IconButton(
      onPressed: () => context.push(ProfileScreen.routePath),
      icon: const Icon(Icons.person_outline_rounded),
      tooltip: 'الملف الشخصي',
    ),
  ];
}
