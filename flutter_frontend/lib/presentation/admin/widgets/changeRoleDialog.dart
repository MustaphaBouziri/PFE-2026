import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/admin/models/mes_user_model.dart';
import '../../../domain/admin/providers/erp_workCenter_provider.dart';
import '../../../domain/admin/providers/mes_user_provider.dart';

/// Dialog that lets an Admin change the role of an existing [MesUser].
///
/// Changing the role also resets the user's work-center assignments, because
/// the valid cardinality differs per role:
///   Operator   → exactly 1 work center   (single-select)
///   Supervisor → 1 or more work centers  (multi-select)
///   Admin      → no work centers         (selector hidden)
///
/// On success, pops with `true` so the caller can show a confirmation.
class ChangeRoleDialog extends StatefulWidget {
  final MesUser user;

  const ChangeRoleDialog({super.key, required this.user});

  @override
  State<ChangeRoleDialog> createState() => _ChangeRoleDialogState();
}

class _ChangeRoleDialogState extends State<ChangeRoleDialog> {
  // ── Role state ─────────────────────────────────────────────────────────────
  // Initialised to the user's current role so the dialog opens pre-selected.
  late int _selectedRoleIndex;
  late String _selectedRole;

  // ── Work-center state ──────────────────────────────────────────────────────
  List<int> _selectedWcIndexes = [];
  List<String> _selectedWcIds = [];

  bool _isSubmitting = false;
  String? _errorMessage;

  // ── Role metadata ──────────────────────────────────────────────────────────
  static const _roles = [
    _RoleMeta(index: 0, key: 'Operator', color: Color(0xFF2563EB), bg: Color(0xFFEFF6FF)),
    _RoleMeta(index: 1, key: 'Supervisor', color: Color(0xFF16A34A), bg: Color(0xFFF0FDF4)),
    _RoleMeta(index: 2, key: 'Admin', color: Color(0xFF7C3AED), bg: Color(0xFFF5F3FF)),
  ];

  bool get _isMultiSelect => _selectedRole == 'Supervisor';
  bool get _showWorkCenters => _selectedRole != 'Admin';

  @override
  void initState() {
    super.initState();
    // Derive current role index from the user's role string.
    _selectedRole = _capitalize(widget.user.role);
    _selectedRoleIndex =
        _roles.indexWhere((r) => r.key == _selectedRole).clamp(0, 2);

    // Pre-populate current work centers (if available on the model).
    // MesUser.workCenters is assumed to be List<String>; adjust if the field
    // name differs in your model.
    if (widget.user.workCenterNames != null) {
      // We don't have index-based pre-selection here because the ErpWorkcenter
      // list isn't loaded yet.  Indexes are resolved after the provider loads.
    }
  }

  void _selectRole(int index, String role) {
    setState(() {
      _selectedRoleIndex = index;
      _selectedRole = role;
      // Clear work-center selection whenever the role changes.
      _selectedWcIndexes = [];
      _selectedWcIds = [];
    });
  }

  void _toggleWorkCenter(int index, String wcId) {
    setState(() {
      if (_selectedWcIndexes.contains(index)) {
        _selectedWcIndexes.remove(index);
        _selectedWcIds.remove(wcId);
      } else {
        if (!_isMultiSelect && _selectedWcIndexes.isNotEmpty) {
          // Operator: clear before adding the new single selection.
          _selectedWcIndexes.clear();
          _selectedWcIds.clear();
        }
        _selectedWcIndexes.add(index);
        _selectedWcIds.add(wcId);
      }
    });
  }

  Future<void> _submit() async {
    // Validate: non-Admin roles require at least one work center.
    if (_showWorkCenters && _selectedWcIds.isEmpty) {
      setState(() =>
          _errorMessage = 'pleaseSelectAtLeastOneWorkCenter'.tr());
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<MesUserProvider>();
      final success = await provider.changeUserRole(
        targetUserId: widget.user.userId,
        newRoleInt: _selectedRoleIndex,
        workCenterList: _showWorkCenters ? _selectedWcIds : [],
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() =>
            _errorMessage = provider.errorMessage ?? 'failedToUpdateRole'.tr());
      }
    } catch (e) {
      setState(() =>
          _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workCenters = context.watch<ErpWorkcenterProvider>().workCenters;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.manage_accounts_outlined,
                      color: Color(0xFFEA580C)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'changeRole'.tr(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          widget.user.fullName.isNotEmpty
                              ? widget.user.fullName
                              : widget.user.authId,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current role info banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Text(
                            '${'currentRole'.tr()}: ${_capitalize(widget.user.role)}',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Role selector ────────────────────────────────────────
                    Text(
                      'selectNewRole'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: _roles.map((role) {
                        return Padding(
                          padding: EdgeInsets.only(
                              right: role.index < 2 ? 10 : 0),
                          child: _roleButton(role),
                        );
                      }).toList(),
                    ),

                    // ── Work-center selector (hidden for Admin) ──────────────
                    if (_showWorkCenters) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'selectWorkCenter'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_isMultiSelect)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFF16A34A)),
                              ),
                              child: Text(
                                'multiSelect'.tr(),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF16A34A)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 200,
                        child: workCenters.isEmpty
                            ? const Center(
                                child: CircularProgressIndicator())
                            : ListView.separated(
                                itemCount: workCenters.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final wc = workCenters[index];
                                  final isSelected =
                                      _selectedWcIndexes.contains(index);

                                  return GestureDetector(
                                    onTap: () =>
                                        _toggleWorkCenter(index, wc.id),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFF0FDF4)
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF16A34A)
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                wc.workCenterName,
                                                style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                wc.id,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF16A34A),
                                              size: 18,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],

                    // ── Error message ────────────────────────────────────────
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 16, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFDC2626)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Submit ───────────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.save_outlined,
                                color: Colors.white),
                        label: Text(
                          _isSubmitting
                              ? 'saving'.tr()
                              : 'saveChanges'.tr(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleButton(_RoleMeta role) {
    final isSelected = _selectedRoleIndex == role.index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectRole(role.index, role.key),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? role.bg : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isSelected ? role.color : Colors.grey.shade300),
          ),
          child: Text(
            role.key.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isSelected ? role.color : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

/// Immutable metadata for a role button.
class _RoleMeta {
  final int index;
  final String key;
  final Color color;
  final Color bg;

  const _RoleMeta({
    required this.index,
    required this.key,
    required this.color,
    required this.bg,
  });
}
