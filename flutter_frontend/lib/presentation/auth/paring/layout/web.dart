import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/presentation/auth/paring/widgets/paring_form.dart';


class ParingWebLayout extends StatelessWidget {
  final TextEditingController companyHostController;
 
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;

  const ParingWebLayout({
    super.key,
    required this.companyHostController,
    required this.formKey,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    const Color mainColor = Color(0xFF0F172A);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: Center(
          child: Container(
            width: 700,
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 50),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //___________________ LOGO / TITLE ___________________
                Column(
                  children:  [
                    Icon(Icons.link_outlined, size: 60, color: mainColor),
                    const SizedBox(height: 20),
                    Text(
                      "paringPage".tr(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                //___________________ Paring FORM ___________________
                ParingForm(
                  companyHostController: companyHostController,
                  
                  formKey: formKey,
                  onSubmit: onSubmit,
                  maxWidth: 450,
                  isCompact: false,
                ),

                const SizedBox(height: 30),

                //___________________ FOOTER ___________________
                 Text(
                  "copyright".tr(),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
