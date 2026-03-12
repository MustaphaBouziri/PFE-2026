import 'package:flutter/material.dart';

class ActionButtonsContainer extends StatefulWidget {
  const ActionButtonsContainer({super.key});

  @override
  State<ActionButtonsContainer> createState() => _ActionButtonsContainerState();
}

class _ActionButtonsContainerState extends State<ActionButtonsContainer> {
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {},
              child: _ActionButton(
                title: "Declare Production",
                icon: Icons.add_circle_outline,
                buttonColor: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {},
              child: _ActionButton(
                title: "Report Reject",
                icon: Icons.warning_amber_outlined,
                buttonColor: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {},
              child: _ActionButton(
                title: "End Production Order",
                icon: Icons.check,
                buttonColor: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {},
              child: _ActionButton(
                title: "Print Label",
                icon: Icons.print_outlined,
                buttonColor: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
      
    );
  }
}

// ── action button design ────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color buttonColor;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
