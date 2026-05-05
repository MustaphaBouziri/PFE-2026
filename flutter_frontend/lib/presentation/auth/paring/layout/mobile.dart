import 'package:flutter/material.dart';
import 'package:pfe_mes/presentation/auth/paring/widgets/paring_form.dart';
import 'package:easy_localization/easy_localization.dart';


class ParingMobileLayout extends StatelessWidget {
  final TextEditingController companyHostController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;

  const ParingMobileLayout({
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    //___________________ LOGO ___________________
                    const Icon(
                      Icons.link_outlined,
                      size: 70,
                      color: mainColor,
                    ),

                    const SizedBox(height: 20),

                     Text(
                      "paringPage".tr(),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                    ),

                    const SizedBox(height: 40),

                    //___________________ FORM CARD ___________________
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ParingForm(
                            companyHostController: companyHostController,
                          
                            formKey: formKey,
                            onSubmit: onSubmit,
                            maxWidth: 420,
                            isCompact: true,
                          ),
                        ),
                        const SizedBox(height: 26),

                         Text(
                         "copyright".tr(),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
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
