import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pfe_mes/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class GeneratePasswordDialog extends StatelessWidget {
  final String userId;
  const GeneratePasswordDialog({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    String generatedPassword = "";

    String generatePassword() {
      const chars = 'AZERTYUIOQSDFGHJKXCVBN';
      final random = Random();
      return List.generate(
        10,
        (index) => chars[random.nextInt(chars.length)],
      ).join();
    }

    final authProvider = context.watch<AuthProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(12),
      ),
      child: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            children: [
              Text(generatedPassword),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    generatedPassword = generatePassword();
                  });
                },
                child: Text('genetrate password'),
              ),

              ElevatedButton(
                onPressed: () {
                  setState(() async {
                    final token = 'aaaaa';
                    final success = await context
                        .read<AuthProvider>()
                        .adminSetPassword(
                          token: token,
                          userId: userId,
                          newPassword: generatedPassword,
                        );
                    if (success) {
                      Navigator.pop(context);
                    }
                  });
                },
                child: Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
  }
}
