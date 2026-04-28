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
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOperators();
  }

  // Fetches operators for every work center the supervisor belongs to,
  // merges the results, and deduplicates by userId.
  Future<void> _loadOperators() async {
    final provider = context.read<MesUserProvider>();
    final Map<String, MesUser> seen = {};
    String? error;

    try {
      for (final wcId in widget.workCenterIds) {
        await provider.fetchUsersByWc(wcId: wcId);
        for (final user in provider.users) {
          if (user.role == 'Operator') {
            seen[user.userId] = user;
          }
        }
      }
    } catch (e) {
      error = e.toString();
    }

    if (mounted) {
      setState(() {
        _errorMessage = error;
        _operators = error == null ? seen.values.toList() : [];
        _isLoading = false;
      });
    }
  }

  void _handleSelection(MesUser? user) {
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

        DropdownMenu<MesUser?>(
          key: ValueKey(_operators.length),
          width: 300,

          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(Colors.white),
          ),

          // enable search
          enableFilter: true,

          //default value is null, meaning self-declaration
          initialSelection: null,

          // selection callback
          onSelected: _handleSelection,

          hintText: 'selectOperator'.tr(),

          // styling
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),

          // menu items
          dropdownMenuEntries: [
            DropdownMenuEntry<MesUser?>(
              value: null,
              label: 'selfDeclaration'.tr(),
            ),
            ..._operators.map(
              (operator) => DropdownMenuEntry<MesUser?>(
                value: operator,
                label: operator.fullName.isNotEmpty
                    ? operator.fullName
                    : operator.authId,
                leadingIcon: EmployeeAvatar(
                  imageBase64: operator.imageBase64,
                  radius: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}