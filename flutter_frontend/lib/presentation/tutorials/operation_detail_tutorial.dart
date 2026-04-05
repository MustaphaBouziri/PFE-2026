import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class OperationDetailTutorial {
  static Future<void> show(BuildContext context, List<GlobalKey> keys) async {
    final prefs = await SharedPreferences.getInstance();
    final tutorialShown = prefs.getBool('tutorial_shown_operation') ?? false;
    if (tutorialShown) return;

    final targets = [
      TargetFocus(
        identify: "current_order_info",
        keyTarget: keys[0],
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              "This section shows your current production order details: quantity, status, and progress.",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "action_buttons",
        keyTarget: keys[2],
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              "Use these buttons to declare production, report scrap, print labels, or finish/cancel the order.",
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
        prefs.setBool('tutorial_shown_operation', true);
        return true;
      },
      onSkip: () {
        prefs.setBool('tutorial_shown_operation', true);
        return true;
      },
    ).show(context: context);
  }
}
