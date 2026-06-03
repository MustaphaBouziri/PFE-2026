import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class AdminDashboardTutorial {
  static Future<void> show(BuildContext context, List<GlobalKey> keys) async {
    final prefs = await SharedPreferences.getInstance();
    final tutorialShown = prefs.getBool('tutorial_shown_admin') ?? false;
    if (tutorialShown) return;

    // Ensure the overlay is mounted before showing
    if (!context.mounted) return;

    final targets = [
      TargetFocus(
        identify: "add_user_button",
        keyTarget: keys[0],
        shape: ShapeLightFocus.RRect,
        radius: 8,
        enableOverlayTab: true,
        enableTargetTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 600;
                return Text(
                  'Click here to add a new user.',
                  style: TextStyle(color: Colors.white, fontSize: isSmall ? 14 : 16),
                );
              },
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "user_table",
        keyTarget: keys[1],
        shape: ShapeLightFocus.RRect,
        radius: 8,
        enableOverlayTab: true,
        enableTargetTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 600;
                return Text(
                  'This table shows users, roles, work center, status, and last seen.',
                  style: TextStyle(color: Colors.white, fontSize: isSmall ? 14 : 16),
                );
              },
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "user_action_menu",
        keyTarget: keys[2],
        shape: ShapeLightFocus.Circle,
        radius: 10,
        enableOverlayTab: true,
        enableTargetTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.left,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 600;
                return Text(
                  'Open this menu to: change role, generate password, view badge, activate or deactivate.',
                  style: TextStyle(color: Colors.white, fontSize: isSmall ? 14 : 16),
                );
              },
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: 'skip'.tr(),
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      paddingFocus: 8,
      opacityShadow: 0.9,
      hideSkip: false,
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

