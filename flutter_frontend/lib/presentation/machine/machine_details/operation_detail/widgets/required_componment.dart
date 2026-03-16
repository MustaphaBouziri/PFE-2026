import 'package:flutter/material.dart';

class _ComponentItem {
  final String name;
  final double stock;
  final String status;

  const _ComponentItem({
    required this.name,
    required this.stock,
    required this.status,
  });
}

class RequiredComponent extends StatefulWidget {
  const RequiredComponent({super.key});

  @override
  State<RequiredComponent> createState() => _RequiredComponentState();
}

class _RequiredComponentState extends State<RequiredComponent> {

  final List<_ComponentItem> _components = const [
    _ComponentItem(name: 'Steel Plate', stock: 120, status: 'Available'),
    _ComponentItem(name: 'Bolt M8', stock: 15, status: 'Low Stock'),
    _ComponentItem(name: 'Rubber Gasket', stock: 0, status: 'Missing'),
    _ComponentItem(name: 'Gear Shaft', stock: 45, status: 'Available'),
    _ComponentItem(name: 'Bearing 6205', stock: 3, status: 'Low Stock'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // title
            const Text(
              "Required Components",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
      
            const SizedBox(height: 16),
      
            // list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _components.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final component = _components[index];
      
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: component.status == 'Available'
                        ? const Color(0xFFF0FDF4)
                        : component.status == 'Low Stock'
                        ? const Color(0xFFFEFCE8)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: component.status == 'Available'
                          ? const Color(0xFF1AA44D).withOpacity(0.2)
                          : component.status == 'Low Stock'
                          ? const Color(0xFFD39D2B).withOpacity(0.2)
                          : const Color(0xFFE03B3B).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      // icon
                      Icon(
                        component.status == 'Available'
                            ? Icons.check_circle_outline
                            : component.status == 'Low Stock'
                            ? Icons.warning_amber_outlined
                            : Icons.cancel_outlined,
                        color: component.status == 'Available'
                            ? const Color(0xFF1AA44D)
                            : component.status == 'Low Stock'
                            ? const Color(0xFFD39D2B)
                            : const Color(0xFFE03B3B),
                        size: 22,
                      ),
      
                      const SizedBox(width: 12),
      
                      // name +stock
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              component.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Stock: ${component.stock}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
      
                      // status label
                      Text(
                        component.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: component.status == 'Available'
                              ? const Color(0xFF1AA44D)
                              : component.status == 'Low Stock'
                              ? const Color(0xFFD39D2B)
                              : const Color(0xFFE03B3B),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      
    );
  }
}
