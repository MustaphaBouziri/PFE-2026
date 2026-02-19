import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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
          success: false, message: 'Please generate a password first.');
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
        final message =
        raw.startsWith('Exception: ') ? raw.substring(11) : raw;
        if (mounted) _showResultDialog(success: false, message: message);
        return;
      }

      if (!mounted) return;

      if (success) {
        _showResultDialog(success: true);
      } else {
        // FIX: was silently doing nothing when success == false.
        // adminSetPassword() returns false (not throw) when the API fails,
        // so we read the error message from the provider and show it.
        final errorMsg = authProvider.errorMessage ??
            'Password update failed. Please try again.';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(success ? 'Success' : 'Failed'),
          ],
        ),
        content: success
            ? RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            children: [
              const TextSpan(text: 'Password for user '),
              TextSpan(
                text: widget.userId,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' ('),
              TextSpan(
                text: widget.authId,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                  text:
                  ') was updated successfully.\n\nNew password:\n\n'),
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
            : Text(message ?? 'An unexpected error occurred.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close result dialog
              if (success) Navigator.pop(context); // close generate dialog
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Generate Password',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              _generatedPassword.isEmpty
                  ? 'No password generated yet'
                  : _generatedPassword,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color:
                _generatedPassword.isEmpty ? Colors.grey : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _generatedPassword = GeneratePasswordDialog.generatePassword();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Generate Password'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : _confirmPassword,
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}