import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class MachineDetailTabsTutorial {
  static Future<void> show(BuildContext context, GlobalKey navBarKey) async {
    final prefs = await SharedPreferences.getInstance();
    final tutorialShown = prefs.getBool('tutorial_shown_machine_detail_tabs') ?? false;
    if (tutorialShown) return;

    final targets = [
      TargetFocus(
        identify: "machine_detail_nav",
        keyTarget: navBarKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
  "Use these tabs to switch between Orders, Progress, Consumable and History for this machine:\n\n"
  "• Orders tab: View all orders assigned to this machine.\n"
  "• Progress tab: Monitor currently active orders, including running and paused operations.\n"
  "• History tab: View all previously completed or canceled orders for this machine.",
  style: TextStyle(color: Colors.white, fontSize: 16),
),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black87,
      textSkip: "SKIP",
      paddingFocus: 6,
      opacityShadow: 0.92,
      onFinish: () {
        prefs.setBool('tutorial_shown_machine_detail_tabs', true);
        return true;
      },
      onSkip: () {
        prefs.setBool('tutorial_shown_machine_detail_tabs', true);
        return true;
      },
    ).show(context: context);
  }
}
