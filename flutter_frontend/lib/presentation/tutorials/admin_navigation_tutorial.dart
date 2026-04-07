import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class AdminNavigationTutorial {
  static Future<void> show(BuildContext context, GlobalKey sidebarKey) async {
    final prefs = await SharedPreferences.getInstance();
    final tutorialShown = prefs.getBool('tutorial_shown_admin_navigation') ?? false;
    if (tutorialShown) return;

    final targets = [
      TargetFocus(
        identify: "admin_sidebar",
        keyTarget: sidebarKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;
                return Text(
                  'tutorialAdminNavigation'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black87,
      textSkip: 'skip'.tr(),
      paddingFocus: 6,
      opacityShadow: 0.92,
      onFinish: () {
        prefs.setBool('tutorial_shown_admin_navigation', true);
        return true;
      },
      onSkip: () {
        prefs.setBool('tutorial_shown_admin_navigation', true);
        return true;
      },
    ).show(context: context);
  }
}