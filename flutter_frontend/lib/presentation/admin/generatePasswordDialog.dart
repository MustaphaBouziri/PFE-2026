import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/auth/providers/auth_provider.dart';

class GeneratePasswordDialog extends StatelessWidget {
  final String userId;
  final String authId;

  const GeneratePasswordDialog({
    super.key,
    required this.userId,
    required this.authId,
  });

  static String generatePassword() {
    const chars =
        'AZERTYUIOQSDFGHJKXCVBNazertyuioqsdfghjkxcvbn0123456789!@#\$%';
    final random = Random.secure();
    return List.generate(
      10,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: _GeneratePasswordDialogContent(userId: userId, authId: authId),
    );
  }
}

class _GeneratePasswordDialogContent extends StatefulWidget {
  final String userId;
  final String authId;

  const _GeneratePasswordDialogContent({
    required this.userId,
    required this.authId,
  });

  @override
  State<_GeneratePasswordDialogContent> createState() =>
      _GeneratePasswordDialogContentState();
}

class _GeneratePasswordDialogContentState
    extends State<_GeneratePasswordDialogContent> {
  String _generatedPassword = '';
  bool _isLoading = false;

  Future<void> _confirmPassword() async {
    if (_generatedPassword.isEmpty) {
      _showResultDialog(
        success: false,
        message: 'pleaseGeneratePasswordFirst'.tr(),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success = false;
      try {
        success = await authProvider.adminSetPassword(
          userId: widget.userId,
          newPassword: _generatedPassword,
        );
      } catch (e) {
        final raw = e.toString();
        final message = raw.startsWith('Exception: ') ? raw.substring(11) : raw;
        if (mounted) _showResultDialog(success: false, message: message);
        return;
      }

      if (!mounted) return;

      if (success) {
        _showResultDialog(success: true);
      } else {
        final errorMsg =
            authProvider.errorMessage ??
            'passwordUpdateFailed'.tr();
        _showResultDialog(success: false, message: errorMsg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showResultDialog({required bool success, String? message}) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
            ),
            const SizedBox(width: 8),
            Text(success ? 'success'.tr() : 'failed'.tr()),
          ],
        ),
        content: success
            ? RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  children: [
                     TextSpan(text: 'passwordFor'.tr()),
                    TextSpan(
                      text: widget.userId,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                     TextSpan(text: 'wasUpdated'.tr()),
                    TextSpan(
                      text: _generatedPassword,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : Text(message ?? 'unexpectedError'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (success) Navigator.pop(context);
            },
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                  'generatePassword'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Text(
              'forUser'.tr() + '${widget.userId}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                _generatedPassword.isEmpty
                    ? 'noPasswordGenerated'.tr()
                    : _generatedPassword,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,

                  color: _generatedPassword.isEmpty
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF1E40AF),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(
                      () => _generatedPassword =
                          GeneratePasswordDialog.generatePassword(),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: Text('generate'.tr()),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _confirmPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'confirm'.tr(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
