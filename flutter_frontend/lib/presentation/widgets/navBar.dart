import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class TopNavigationBar extends StatelessWidget{
  final int selectedIndex;
  final Function(int) onTabChanged;

  const TopNavigationBar({
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          NavButton(
            title: "orders".tr(),
            selected: selectedIndex == 0,
            onTap: () => onTabChanged(0),
          ),
          NavButton(
            title: "progress".tr(),
            selected: selectedIndex == 1,
            onTap: () => onTabChanged(1),
          ),
          NavButton(
            title: "consumable".tr(),
            selected: selectedIndex == 2,
            onTap: () => onTabChanged(2),
          ),
          NavButton(
            title: "history".tr(),
            selected: selectedIndex == 3,
            onTap: () => onTabChanged(3),
          ),
        ],
      ),
    );
  }
  
}

class NavButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const NavButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: selected
                  ? BorderSide(color: Colors.black, width: 2)
                  : BorderSide.none,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
