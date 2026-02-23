import 'package:flutter/material.dart';

class MachineCard extends StatelessWidget {
  final dynamic machine;
  const MachineCard({super.key, required this.machine});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLarge = constraints.maxWidth > 600;

        final titleSize = isLarge ? 22.0 : 18.0;
        final textSize = isLarge ? 16.0 : 14.0;
        final padding = isLarge ? 24.0 : 16.0;
        final statusHeight = isLarge ? 36.0 : 30.0;
        final statusWidth = isLarge ? 120.0 : 100.0;

        final status = (machine.status ?? '').toString().trim().toLowerCase();

        Color statusBg;
        Color statusText;

        if (status == 'idle') {
          statusBg = const Color.fromARGB(76, 158, 158, 158);
          statusText = const Color.fromARGB(255, 85, 85, 85);
        } else if (status == 'running') {
          statusBg = const Color.fromARGB(40, 40, 197, 92);
          statusText = Colors.green;
        } else {
          statusBg = const Color.fromARGB(40, 40, 197, 92);
          statusText = Colors.green;
        }

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      machine.machineName,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    height: statusHeight,
                    width: statusWidth,
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        machine.status ?? 'Running',
                        style: TextStyle(
                          fontSize: textSize,
                          fontWeight: FontWeight.bold,
                          color: statusText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text("departmentName", style: TextStyle(fontSize: textSize)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Current Order:", style: TextStyle(fontSize: textSize)),
                  Text("bluhbluh", style: TextStyle(fontSize: textSize)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Operator:", style: TextStyle(fontSize: textSize)),
                  Text("ahmed ben salah", style: TextStyle(fontSize: textSize)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
