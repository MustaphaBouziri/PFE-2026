import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class AdminDashboardTutorial {
  static Future<void> show(BuildContext context, List<GlobalKey> keys) async {
    final prefs = await SharedPreferences.getInstance();
    final tutorialShown = prefs.getBool('tutorial_shown_admin') ?? false;
    if (tutorialShown) return;

    final targets = [
      TargetFocus(
        identify: "search_bar",
        keyTarget: keys[0],
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              "This is the admin dashboard search. Find users by name or email here.",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "role_dropdown",
        keyTarget: keys[1],
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              "Filter users by role: All, Admin, Supervisor, or Operator.",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "add_user_button",
        keyTarget: keys[2],
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              "Click here to add a new user to the system.",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "user_table",
        keyTarget: keys[3],
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              "This table shows all users. You can edit or manage user roles here.",
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
        prefs.setBool('tutorial_shown_admin', true);
        return true;
      },
      onSkip: () {
        prefs.setBool('tutorial_shown_admin', true);
        return true;
      },
    ).show(context: context);
  }
}