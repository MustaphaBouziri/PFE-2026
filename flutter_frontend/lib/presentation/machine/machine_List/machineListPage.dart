import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_machine_model.dart';
import 'package:provider/provider.dart';

import '../../../domain/machines/providers/mes_machines_provider.dart';
import '../../widgets/language_selector.dart';
import 'MachineCard.dart';

class Machinelistpage extends StatefulWidget {
  const Machinelistpage({super.key});

  @override
  State<Machinelistpage> createState() => _MachinelistpageState();
}

class _MachinelistpageState extends State<Machinelistpage> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MesMachinesProvider>(
      context,
      listen: false,
    ); // go up to the widget tree find the mesMachineProvider and give me access to it // false mean i just wanna the provider object and i do not wanna this widget to rebuild when it change , we did this cuz we got stream

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage('https://picsum.photos/200/200'),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ahmed Ben Hamed',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Text(
                  'ID: 00012036',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            const LanguageSelector(isCompact: true),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout, size: 16),
              label: Text('logout'.tr()),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
          ],
        ),
      ),

      body: StreamBuilder(
        //stream: provider.getMachinesStream(user.workCenters),
        stream: provider.streamOrderedMachinePerDepartments(["100", "200"]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // machine is a list because the provider stream will return a List<machineModel> so dart auto know so there is no need to type final List<MachineModel> machines = snapshot.data!;
          final machines =
              snapshot.data!; // snapshot.data means the latest emitted value

          if (machines.isEmpty) {
            return Center(child: Text('noMachinesFound'.tr()));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      "machinesList".tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white,
                        border: Border.all(color: Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              backgroundColor: Color.fromARGB(255, 40, 197, 92),
                              radius: 5,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Running',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white,
                        border: Border.all(color: Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              backgroundColor: Color.fromARGB(
                                255,
                                134,
                                134,
                                134,
                              ),
                              radius: 5,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Idle',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final groupedMachines = snapshot.data!; // ✅ the actual Map

                    int crossAxisCount = constraints.maxWidth < 600
                        ? 1
                        : constraints.maxWidth < 1024
                        ? 2
                        : 4;

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: groupedMachines.entries.map((entry) {
                        final workCenter = entry.key;
                        final machinesList = entry.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Department title
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                "Department $workCenter",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Grid for this department
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: machinesList.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: constraints.maxWidth < 900
                                        ? 1.8
                                        : constraints.maxWidth < 1400
                                        ? 1.5
                                        : 1.8,
                                  ),
                              itemBuilder: (context, index) {
                                return MachineCard(
                                  machine: machinesList[index],
                                );
                              },
                            ),

                            const SizedBox(height: 24),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
