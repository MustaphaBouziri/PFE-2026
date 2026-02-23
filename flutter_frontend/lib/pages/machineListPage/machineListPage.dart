import 'package:flutter/material.dart';
import 'package:pfe_mes/pages/machineListPage/MachineCard.dart';
import 'package:pfe_mes/providers/mes_machines_provider.dart';
import 'package:provider/provider.dart';

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
      appBar: AppBar(),
      body: StreamBuilder(
        stream: provider.getMachinesStream("300"),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // machine is a list because the provider stream will return a List<machineModel> so dart auto know so there is no need to type final List<MachineModel> machines = snapshot.data!;
          final machines =
              snapshot.data!; // snapshot.data means the latest emitted value

          if (machines.isEmpty) {
            return const Center(child: Text('no machines found'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text(
                      "Machines List",
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
                    if (constraints.maxWidth < 600) {
                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 8),
                        itemCount: machines.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: MachineCard(machine: machines[index]),
                          );
                        },
                      );
                    } else {
                      int crossAxisCount = constraints.maxWidth < 1024 ? 2 : 4;

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: constraints.maxWidth < 900
                              ? 1.8 // tablet
                              : constraints.maxWidth < 1400
                              ? 1.5 // small PC / laptop
                              : 1.8, // large desktop
                        ),
                        itemCount: machines.length,
                        itemBuilder: (context, index) {
                          return MachineCard(machine: machines[index]);
                        },
                      );
                    }
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
