import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class MachineListTutorial {
  static Future<void> show(BuildContext context, List<GlobalKey> keys) async {
    final prefs = await SharedPreferences.getInstance();
    final tutorialShown = prefs.getBool('tutorial_shown_user') ?? false;
    if (tutorialShown) return;

    final targets = [
      TargetFocus(
        identify: "search_and_filter",
        keyTarget: keys[0],
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              "Use this search bar to find machines by name or work center, and filter them by their status (All, Working, Idle).",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "machine_card",
        keyTarget: keys[4],
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              "Tap any machine card to view its details, current order, and operations.",
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
      opacityShadow: 0.95,
      onFinish: () {
        prefs.setBool('tutorial_shown_user', true);
        return true;
      },
      onSkip: () {
        prefs.setBool('tutorial_shown_user', true);
        return true;
      },
    ).show(context: context);
  }
}