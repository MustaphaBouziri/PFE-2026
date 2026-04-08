import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../data/admin/models/mes_user_model.dart';
import '../../../../../domain/admin/providers/mes_user_provider.dart';
import '../../../../widgets/employee_avatar.dart';

/// Displays a dropdown of Operator-role users belonging to the given work centers.
/// Calls [onOperatorSelected] with the chosen userId, or null when cleared.
/// Intended for Supervisor users who need to declare production on behalf of an operator.
class OperatorSelector extends StatefulWidget {
  final List<String> workCenterIds;
  final void Function(String? operatorUserId) onOperatorSelected;

  const OperatorSelector({
    super.key,
    required this.workCenterIds,
    required this.onOperatorSelected,
  });

  @override
  State<OperatorSelector> createState() => _OperatorSelectorState();
}

class _OperatorSelectorState extends State<OperatorSelector> {
  List<MesUser> _operators = [];
  MesUser? _selectedOperator;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOperators();
  }

  /// Fetches operators for every work center the supervisor belongs to,
  /// merges the results, and deduplicates by userId.
  ///
  /// FIX: The original code called setState twice — once to update _errorMessage
  /// and once to set _operators + _isLoading = false.  The gap between the two
  /// calls caused a single frame where _isLoading was still true but _operators
  /// was already populated, which rendered both the loading indicator AND the
  /// dropdown simultaneously, producing the text-superimposition bug.
  /// Now all state mutations are batched into a single setState at the end.
  Future<void> _loadOperators() async {
    final provider = context.read<MesUserProvider>();
    final Map<String, MesUser> seen = {};
    String? error;

    try {
      for (final wcId in widget.workCenterIds) {
        await provider.fetchUsersByWc(wcId: wcId);
        for (final user in provider.users) {
          // Only operators can be the target of a proxy declaration.
          if (user.role == 'Operator') {
            seen[user.userId] = user;
          }
        }
      }
    } catch (e) {
      error = e.toString();
    }

    // FIX: single setState — no intermediate partial-state frame.
    if (mounted) {
      setState(() {
        _errorMessage = error;
        _operators = error == null ? seen.values.toList() : [];
        _isLoading = false;
      });
    }
  }

  void _handleSelection(MesUser? user) {
    setState(() => _selectedOperator = user);
    widget.onOperatorSelected(user?.userId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Loading operators…', style: TextStyle(fontSize: 13)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Text(
        'Failed to load operators: $_errorMessage',
        style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
      );
    }

    if (_operators.isEmpty) {
      return Text(
        'noOperatorsFound'.tr(),
        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'declareOnBehalfOf'.tr(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        // FIX: ValueKey on the operator count so Flutter fully replaces the
        // dropdown widget when the list changes, preventing a stale item
        // reference that could crash or show ghost entries.
        DropdownButtonFormField<MesUser>(
          key: ValueKey(_operators.length),
          value: _selectedOperator,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'selectOperator'.tr(),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
          dropdownColor: Colors.white,
          // null item lets the supervisor clear the selection (= self-declaration)
          items: [
            DropdownMenuItem<MesUser>(
              value: null,
              child: Text(
                'selfDeclaration'.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            ..._operators.map(
                  (operator) => DropdownMenuItem<MesUser>(
                value: operator,
                child: Row(
                  children: [
                    EmployeeAvatar(
                      fallbackLabel: _initials(operator.fullName),
                      radius: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        operator.fullName.isNotEmpty
                            ? operator.fullName
                            : operator.authId,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: _handleSelection,
        ),
      ],
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || fullName.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
