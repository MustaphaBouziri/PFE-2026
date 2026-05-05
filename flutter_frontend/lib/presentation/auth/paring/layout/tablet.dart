import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/presentation/auth/paring/widgets/paring_form.dart';


class ParingTabletLayout extends StatelessWidget {
  final TextEditingController companyHostController;

  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;

  const ParingTabletLayout({
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: 600,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    //___________________ HEADER ___________________
                    const Icon(
                      Icons.link_outlined,
                      size: 80,
                      color: mainColor,
                    ),

                    const SizedBox(height: 24),

                     Text(
                      "paringPage".tr(),
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                    ),

                    const SizedBox(height: 40),

                    //___________________ FORM ___________________
                    ParingForm(
                      companyHostController: companyHostController,
                      formKey: formKey,
                      onSubmit: onSubmit,
                      maxWidth: 600,
                      isCompact: false,
                    ),
                    SizedBox(height: 26),
                     Text(
                      "copyright".tr(),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
