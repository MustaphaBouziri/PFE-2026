import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/core/app_constants.dart';
import 'package:pfe_mes/presentation/auth/Login/loginPage.dart';
import 'package:pfe_mes/presentation/auth/paring/layout/mobile.dart';
import 'package:pfe_mes/presentation/auth/paring/layout/tablet.dart';
import 'package:pfe_mes/presentation/auth/paring/layout/web.dart';
import 'package:provider/provider.dart';

import '/domain/auth/providers/auth_provider.dart';


class ParingPage extends StatefulWidget {
  const ParingPage({super.key});

  @override
  State<ParingPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<ParingPage> {
  final TextEditingController companyHostController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void onSubmit() async {
  if (!formKey.currentState!.validate()) return;

 await AppConstants.changeHost(companyHostController.text.trim());
  Navigator.pushReplacement(context, MaterialPageRoute(builder:(context) => LoginPage(),));
}

  @override
  void dispose() {
    companyHostController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            return Stack(
              children: [
                Builder(
                  builder: (context) {
                    if (width < 600) {
                      return ParingMobileLayout(
                        companyHostController: companyHostController,
                        
                        formKey: formKey,
                        onSubmit: onSubmit,
                      );
                    } else if (width < 1024) {
                      return ParingTabletLayout(
                        companyHostController: companyHostController,
                        
                        formKey: formKey,
                        onSubmit: onSubmit,
                      );
                    } else {
                      return ParingWebLayout(
                        companyHostController: companyHostController,
                        
                        formKey: formKey,
                        onSubmit: onSubmit,
                      );
                    }
                  },
                ),
                // Loading overlay
                if (auth.isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child:  Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text('paring'.tr()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
