import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../../domain/auth/providers/auth_provider.dart';

/// Shown inside the LoginPage after a successful password check when the
/// server returns twoFAEnabled: true.
///
/// Usage (inside LoginPage._login() after auth.login() returns true):
///
///   if (auth.pendingBadge) {
///     final passed = await showDialog<bool>(
///       context: context,
///       barrierDismissible: false,
///       builder: (_) => const BadgeScanDialog(),
///     );
///     // On success _AuthGate reroutes automatically via isAuthenticated.
///     // On cancel auth.cancelBadgeScan() is already called by the dialog.
///   }
///
/// The dialog pops with true on success and false (or null) on cancel.
/// Navigation after success is handled by _AuthGate listening to isAuthenticated.
class BadgeScanDialog extends StatefulWidget {
  const BadgeScanDialog({super.key});

  @override
  State<BadgeScanDialog> createState() => _BadgeScanDialogState();
}

class _BadgeScanDialogState extends State<BadgeScanDialog> {
  static const Color _mainColor = Color(0xFF0F172A);

  bool _verifying      = false;
  bool _showManual     = false;
  bool _scannerActive  = true;
  final TextEditingController _manualCtrl = TextEditingController();

  @override
  void dispose() {
    _manualCtrl.dispose();
    super.dispose();
  }

  // ── Verification ──────────────────────────────────────────────────────────

  Future<void> _verify(String scannedValue) async {
    final trimmed = scannedValue.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _verifying     = true;
      _scannerActive = false; // freeze scanner while verifying
    });

    final auth    = context.read<AuthProvider>();
    final success = await auth.verifyBadge(trimmed);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      // _AuthGate will reroute to dashboard / change-password page automatically
      return;
    }

    // Failed — re-enable scanner so they can try again
    setState(() {
      _verifying     = false;
      _scannerActive = true;
    });
  }

  void _cancel() {
    context.read<AuthProvider>().cancelBadgeScan();
    Navigator.of(context).pop(false);
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 28, color: _mainColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'scanYourBadge'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _mainColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _cancel,
                    tooltip: 'cancel'.tr(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'holdBadgeToCamera'.tr(),
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // QR scanner viewport
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: Stack(
                    children: [
                      if (_scannerActive)
                        MobileScanner(
                          onDetect: (capture) {
                            final raw = capture.barcodes.first.rawValue;
                            if (raw != null && !_verifying) _verify(raw);
                          },
                        )
                      else
                        Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                      // Targeting frame overlay
                      Center(
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Error message
              if (auth.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Manual entry toggle
              TextButton(
                onPressed: () =>
                    setState(() => _showManual = !_showManual),
                child: Text(
                  _showManual
                      ? 'hideManualEntry'.tr()
                      : 'enterCodeManually'.tr(),
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF1F59D7)),
                ),
              ),

              if (_showManual) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _manualCtrl,
                  decoration: InputDecoration(
                    labelText: 'badgeCode'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(color: _mainColor, width: 2),
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 12),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mainColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _verifying
                        ? null
                        : () => _verify(_manualCtrl.text),
                    child: Text(
                      'verify'.tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Cancel link
              TextButton(
                onPressed: _cancel,
                child: Text(
                  'cancelAndGoBack'.tr(),
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
