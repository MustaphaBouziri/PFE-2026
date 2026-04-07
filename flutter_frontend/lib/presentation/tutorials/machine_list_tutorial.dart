import 'package:easy_localization/easy_localization.dart';
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
        identify: "profile_picture",
        keyTarget: keys[0],
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;
                return Text(
                  'tutorialProfilePicture'.tr(),
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
      TargetFocus(
        identify: "search_and_filter",
        keyTarget: keys[1],
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;
                return Text(
                  'tutorialSearchFilter'.tr(),
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
      TargetFocus(
        identify: "machine_card",
        keyTarget: keys[4],
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;
                return Text(
                  'tutorialMachineCard'.tr(),
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