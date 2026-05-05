import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/presentation/auth/paring/widgets/scanner_dialog.dart';
import '../../../widgets/language_selector.dart';

class ParingForm extends StatefulWidget {
  final TextEditingController companyHostController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;
  final double maxWidth;
  final bool isCompact;
  const ParingForm({
    super.key,
    required this.companyHostController,
    required this.formKey,
    required this.onSubmit,
    required this.maxWidth,
    required this.isCompact,
  });

  @override
  State<ParingForm> createState() => _LoginSharedFormState();
}

class _LoginSharedFormState extends State<ParingForm> {
  static const Color mainColor = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //___________________ LANGUAGE SELECTOR ___________________
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [LanguageSelector(isCompact: widget.isCompact)],
            ),

            //___________________ companyhost id LABEL ___________________
            Text(
              "companyHostUrl".tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: mainColor,
              ),
            ),
            const SizedBox(height: 8),

            //___________________ Company Host Url INPUT ___________________
            TextFormField(
              controller: widget.companyHostController,
              decoration: InputDecoration(
                hintText: "enterCompanyHostUrl".tr(),
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                suffixIcon: const Icon(Icons.link_rounded, color: mainColor),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 212, 212, 212),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: mainColor, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) {
                final v = value?.trim();

                if (v == null || v.isEmpty) {
                  return "pleaseEnterCompanyHostId".tr();
                }

                if (v.contains(' ')) {
                  return "noSpacesAllowed".tr();
                }

                if (v.contains('\\')) {
                  return "backslashNotAllowed".tr();
                }

                if (RegExp(r'[<>"\[\]{}|^`]').hasMatch(v)) {
                  return "invalidCharacters".tr();
                }

                return null;
              },
            ),
            const SizedBox(height: 8),
           TextButton(
                onPressed: () async {
                  //we open dialog and wait for the result
                  final result = await showDialog(
                    context: context,
                    builder: (_) => const QrScannerDialog(),
                  );
                  // result from qr code on pop meaning on successfull scan it will give the value and it will be displayed on the input
                  if (result != null) {
                    widget.companyHostController.text = result;
                  }
                },
                child: Text(
                  "orScanQrCode".tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 31, 89, 215),
                  ),
                ),
              ),
            

            const SizedBox(height: 36),

            //___________________ submit BUTTON ___________________
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: widget.onSubmit,
                child: Text(
                  "submit".tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
