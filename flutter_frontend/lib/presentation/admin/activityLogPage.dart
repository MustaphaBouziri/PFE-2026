import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/admin/models/mes_log_model.dart';
import 'package:pfe_mes/domain/admin/providers/mes_log_provider.dart';
import 'package:pfe_mes/presentation/widgets/expandableText.dart';
import 'package:pfe_mes/presentation/widgets/searchBar.dart';
import 'package:provider/provider.dart';

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  final TextEditingController searchController = TextEditingController();
  String selectedType = 'All';
  final List<String> type = ['All', 'Status', 'Productions', 'Scraps', 'Scans'];
  int _currentPage = 0;
  static const int _pageSize = 15;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LogProvider>().fetchActivityLog();
    });
  }

  String _label(int h) {
    if (h < 24) return 'Last ${h}h';
    if (h == 24) return 'Last 24h';
    if (h == 48) return 'Last 48h';
    return 'Last 7d';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LogProvider>();
    final logs = provider.activityLogs;

    final filteredActivityLogs = logs.where((log) {
      final typeMatch =
          selectedType == 'All' || log.type == log.mapType(selectedType);
      final searchMatch =
          log.operatorName.toLowerCase().contains(
            searchController.text.toLowerCase(),
          ) ||
          log.machineNo.toLowerCase().contains(
            searchController.text.toLowerCase(),
          ) ||
          log.action.toLowerCase().contains(
            searchController.text.toLowerCase(),
          );
      return typeMatch && searchMatch;
    }).toList();
    final totalPages = (filteredActivityLogs.length / _pageSize).ceil();
    final pageLogs = filteredActivityLogs
        .skip(_currentPage * _pageSize)
        .take(_pageSize)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'activityLogTitle'.tr(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          DropdownButton<int>(
            value: provider.selectedHours,
            underline: const SizedBox(),
            items: provider.hourOptions
                .map((h) => DropdownMenuItem(value: h, child: Text(_label(h))))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                provider.setHours(val);
                provider.fetchActivityLog();
                setState(() => _currentPage = 0);
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
          ? Center(child: Text(provider.errorMessage!))
          : Column(
              children: [
                // search bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GlobalSearchBar(
                    controller: searchController,
                    onSearchChanged: (val) => setState(() => _currentPage = 0),
                    dropdownItems: type.map((t) => t.tr()).toList(),
                    selectedValue: selectedType.tr(),
                    onDropdownChanged: (val) => setState(() {
                      final key = type.firstWhere(
                        (k) => k.tr() == val,
                        orElse: () => selectedType,
                      );
                      selectedType = key;
                      _currentPage = 0;
                    }),
                  ),
                ),
                // table header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: const Color(0xFFF8FAFC),
                  child: Row(
                    children: [
                      SizedBox(width: 32),
                      Expanded(flex: 2, child: tabletTitle(title: 'operator')),
                      Expanded(flex: 2, child: tabletTitle(title: 'machine')),
                      Expanded(flex: 3, child: tabletTitle(title: 'action')),
                      Expanded(flex: 2, child: tabletTitle(title: 'time')),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // list rows
                Expanded(
                  child: ListView.separated(
                    itemCount: pageLogs.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final log = pageLogs[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(log.icon, color: log.color, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: rowValue(
                                value: log.operatorName.isEmpty
                                    ? log.operatorId
                                    : log.operatorName,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: rowValue(value: log.machineNo),
                            ),
                            Expanded(
                              flex: 3,
                              child: rowValue(value: log.action),
                            ),
                            Expanded(
                              flex: 2,
                              child: rowValue(value: log.timestamp),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // pagination
                if (totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentPage > 0
                              ? () => setState(() => _currentPage--)
                              : null,
                        ),
                        Text(
                          '${_currentPage + 1} / $totalPages',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _currentPage < totalPages - 1
                              ? () => setState(() => _currentPage++)
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class rowValue extends StatelessWidget {
  String value;
  rowValue({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return ExpandableText(
      text: 
      value,
      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
    );
  }
}

class tabletTitle extends StatelessWidget {
  String title;
  tabletTitle({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.tr(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF64748B),
      ),
    );
  }
}
