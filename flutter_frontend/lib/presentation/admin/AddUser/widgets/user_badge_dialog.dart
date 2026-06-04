import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pfe_mes/data/admin/models/mes_user_model.dart';
import 'package:pfe_mes/domain/auth/providers/auth_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;

/// Admin dialog — view, export as PDF, or regenerate the badge QR for a user.
///
/// Open from the Add User page / user list row action:
///
///   showDialog(
///     context: context,
///     builder: (_) => UserBadgeDialog(user: mesUser),
///   );
///
/// On open, fetches the current badge secret via GetBadgeSecret.
/// "Export PDF" generates a printable A4 sheet with the QR code and user info.
/// "Regenerate" calls RegenerateBadgeSecret and refreshes the QR.
class UserBadgeDialog extends StatefulWidget {
  final MesUser user;

  const UserBadgeDialog({super.key, required this.user});

  @override
  State<UserBadgeDialog> createState() => _UserBadgeDialogState();
}

class _UserBadgeDialogState extends State<UserBadgeDialog> {
  static const Color _mainColor = Color(0xFF0F172A);

  String? _badgeSecret;
  bool _loading = true;
  String? _error;
  bool _exporting = false;
  bool _regenerating = false;

  @override
  void initState() {
    super.initState();
    _fetchSecret();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _fetchSecret() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final result = await auth.getBadgeSecret(widget.user.userId);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _badgeSecret = result['badgeSecret'] as String?;
        _loading = false;
      });
    } else {
      setState(() {
        _error = result['message']?.toString() ?? 'fetchFailed'.tr();
        _loading = false;
      });
    }
  }

  Future<void> _regenerate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('regenerateBadge'.tr()),
        content: Text(
          'regenerateBadgeWarning'.tr(args: [widget.user.fullName]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'regenerate'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _regenerating = true);

    final auth = context.read<AuthProvider>();
    final result = await auth.regenerateBadge(widget.user.userId);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _badgeSecret = result['badgeSecret'] as String?;
        _regenerating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('badgeRegenerated'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _regenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'regenerateFailed'.tr(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── PDF export ────────────────────────────────────────────────────────────

  Future<void> _exportPdf() async {
    if (_badgeSecret == null) return;
    setState(() => _exporting = true);

    try {
      final qrImage = await _renderQrToBytes(_badgeSecret!);
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => pw.Center(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  '',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  widget.user.fullName.isNotEmpty
                      ? widget.user.fullName
                      : widget.user.userId,
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'ID: ${widget.user.authId}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 24),
                pw.Image(pw.MemoryImage(qrImage), width: 200, height: 200),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Scan this QR code to authenticate',
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
        ),
      );

      final bytes = await pdf.save();

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'badge_${widget.user.userId}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('exportFailed'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// Renders the QR code to raw PNG bytes for embedding in the PDF.
  /// Renders the QR code to raw PNG bytes for embedding in the PDF.
  Future<Uint8List> _renderQrToBytes(String data) async {
    final barcode = bw.Barcode.qrCode(
      errorCorrectLevel: bw.BarcodeQRCorrectionLevel.medium,
    );

    const double size = 400;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final backgroundPaint = Paint()..color = Colors.white;
    final foregroundPaint = Paint()..color = Colors.black;

    canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), backgroundPaint);

    final elements = barcode.make(
      data,
      width: size,
      height: size,
      drawText: false,
    );

    for (final element in elements) {
      if (element is bw.BarcodeBar && element.black) {
        canvas.drawRect(
          Rect.fromLTWH(
            element.left,
            element.top,
            element.width,
            element.height,
          ),
          foregroundPaint,
        );
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return bytes!.buffer.asUint8List();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 26, color: _mainColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'employeeBadge'.tr(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _mainColor,
                          ),
                        ),
                        Text(
                          widget.user.fullName.isNotEmpty
                              ? widget.user.fullName
                              : widget.user.userId,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // QR code area
              if (_loading)
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _fetchSecret,
                          child: Text('retry'.tr()),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_badgeSecret != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: bw.BarcodeWidget(
                    barcode: bw.Barcode.qrCode(
                      errorCorrectLevel: bw.BarcodeQRCorrectionLevel.medium,
                    ),
                    data: _badgeSecret!,
                    width: 200,
                    height: 200,
                    backgroundColor: Colors.white,
                    drawText: false,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'badgeQRDescription'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  // Export PDF
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(color: _mainColor),
                      ),
                      onPressed:
                          (_loading ||
                              _error != null ||
                              _exporting ||
                              _badgeSecret == null)
                          ? null
                          : _exportPdf,
                      icon: _exporting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 16,
                              color: _mainColor,
                            ),
                      label: Text(
                        'exportPDF'.tr(),
                        style: const TextStyle(color: _mainColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Regenerate
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: (_loading || _regenerating)
                          ? null
                          : _regenerate,
                      icon: _regenerating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.refresh,
                              size: 16,
                              color: Colors.white,
                            ),
                      label: Text(
                        'regenerate'.tr(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
