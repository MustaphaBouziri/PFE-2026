import 'package:flutter/material.dart';
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
    final provider = Provider.of<MesMachinesProvider>(context,listen: false);// go up to the widget tree find the mesMachineProvider and give me access to it // false mean i just wanna the provider object and i do not wanna this widget to rebuild when it change , we did this cuz we got stream
    return Scaffold(
      body: StreamBuilder(stream: provider.getMachinesStream("400"),
       builder:(context, snapshot) {
        if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
// machine is a list because the provider stream will return a List<machineModel> so dart auto know so there is no need to type final List<MachineModel> machines = snapshot.data!;
          final machines = snapshot.data!; // snapshot.data means the latest emitted value

          if(machines.isEmpty){
            return const Center(child: Text('no machines found'),);
          }

          return ListView.builder(
            itemCount: machines.length,
            itemBuilder:(context, index) {
              return Container();

            
          },);

         
       },),
    );
  }
}