import 'package:flutter/material.dart';
import 'package:pfe_mes/data/admin/models/mes_user_model.dart';
import 'package:pfe_mes/presentation/admin/AddUser/widgets/tableHeader.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pfe_mes/presentation/admin/AddUser/widgets/userListRow.dart';

class UserListTable extends StatefulWidget {
  final List<MesUser> users;
  final int totalPages;
  final int currentPage;
  final Function(int) onPageChanged;
  final String currentUserId;
  final GlobalKey tableKey;

  const UserListTable({
    super.key,
    required this.users,
    required this.totalPages,
    required this.currentPage,
    required this.onPageChanged,
    required this.currentUserId,
    required this.tableKey,
  });

  @override
  State<UserListTable> createState() => _UserListTableState();
}

class _UserListTableState extends State<UserListTable> {
  static const _shadow = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 12,
    spreadRadius: 1,
    offset: Offset(0, 4),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        key: widget.tableKey,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [_shadow],
        ),
        child: Column(
          children: [
            const TableHeader(),
            Expanded(
              child: widget.users.isEmpty
                  ? Center(
                      child: Text(
                        'noUsersFound'.tr(),
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  : RepaintBoundary(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: widget.users.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, index) {
                          final user = widget.users[index];
                          return UserListRow(
                            key: ValueKey(user.userId),
                            user: user,
                            isCurrentUser:
                                user.userId == widget.currentUserId,
                          );
                        },
                      ),
                    ),
            ),
            if (widget.totalPages > 1)
              RepaintBoundary(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: widget.currentPage > 0
                            ? () =>
                                widget.onPageChanged(widget.currentPage - 1)
                            : null,
                      ),
                      Text(
                        '${widget.currentPage + 1} / ${widget.totalPages}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed:
                            widget.currentPage < widget.totalPages - 1
                                ? () =>
                                    widget.onPageChanged(widget.currentPage + 1)
                                : null,
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
}