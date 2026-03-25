import 'package:flutter/material.dart';

import '../../../data/machine/models/mes_machine_model.dart';
import '../machine_details/tabsMain.dart';

class MachineCard extends StatefulWidget {
  final MachineModel machine;

  const MachineCard({super.key, required this.machine});

  @override
  State<MachineCard> createState() => _MachineCardState();
}

class _MachineCardState extends State<MachineCard> {
  bool _isHovered = false;

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

        final status = (widget.machine.status ?? '').toString().trim().toLowerCase();

        Color statusBg;
        Color statusText;
        Color leftBorder;

        if (status == 'idle') {
          statusBg = const Color.fromARGB(76, 158, 158, 158);
          statusText = const Color.fromARGB(255, 85, 85, 85);
          leftBorder = const Color.fromARGB(255, 158, 158, 158);
        } else if (status == 'running') {
          statusBg = const Color.fromARGB(40, 40, 197, 92);
          statusText = Colors.green;
          leftBorder = Colors.green;
        } else {
          statusBg = const Color.fromARGB(40, 40, 197, 92);
          statusText = Colors.green;
          leftBorder = Colors.green;
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) {
            setState(() {
              _isHovered = true;
            });
          },
          onExit: (_) {
            setState(() {
              _isHovered = false;
            });
          },
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MachineMainPage(
                    machineNo: widget.machine.machineNo,
                    machineName: widget.machine.machineName,
                  ),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white,
                border: Border.all(
                  color: _isHovered
                      ? Theme.of(context).primaryColor.withOpacity(0.35)
                      : Colors.transparent,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isHovered ? 0.18 : 0.08),
                    blurRadius: _isHovered ? 14 : 10,
                    spreadRadius: _isHovered ? -2 : 0,
                    offset: _isHovered ? const Offset(0, 10) : const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      width: 5,
                      child: ColoredBox(color: leftBorder),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: padding + 5,
                        right: padding,
                        top: padding,
                        bottom: padding,
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
                                  widget.machine.machineName,
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
                                    widget.machine.status ?? 'Running',
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
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Current Order:",
                                style: TextStyle(fontSize: textSize),
                              ),
                              Text(
                                widget.machine.currentOrder.isEmpty
                                    ? 'No active order'
                                    : widget.machine.currentOrder,
                                style: TextStyle(fontSize: textSize),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}