// lib/presentation/admin/screens/mes_settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pfe_mes/domain/admin/providers/mes_settings_provider.dart';

class MesSettingsPage extends StatefulWidget {
  const MesSettingsPage({super.key});

  @override
  State<MesSettingsPage> createState() => _MesSettingsPageState();
}

class _MesSettingsPageState extends State<MesSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _periodController;
  late ValueNotifier<bool> _isDirty;
  String _savedValue = '';

  @override
  void initState() {
    super.initState();
    _isDirty = ValueNotifier(false);
    _periodController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MesSettingsProvider>();
      provider.fetchSettings().then((_) {
        if (provider.settings != null) {
          _savedValue = provider.settings!.pwChangePeriod;
          _periodController.text = _savedValue;
        }
      });
    });
    _periodController.addListener(() {
      _isDirty.value = _periodController.text.trim() != _savedValue.trim();
    });
  }

  @override
  void dispose() {
    _periodController.dispose();
    _isDirty.dispose();
    super.dispose();
  }

  Future<void> _save(MesSettingsProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await provider.updateSettings(_periodController.text.trim());
    if (!mounted) return;
    if (ok) {
      _savedValue = _periodController.text.trim();
      _isDirty.value = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Settings saved successfully'),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D5E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (provider.saveError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Error: ${provider.saveError}')),
            ],
          ),
          backgroundColor: const Color(0xFFC0392B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MesSettingsProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF1A1F36),
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'System Settings',
              style: TextStyle(
                color: Color(0xFF1A1F36),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFFE8EAF0), height: 1),
            ),
          ),
          body: provider.isLoading
              ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF3B6FF0),
              strokeWidth: 2.5,
            ),
          )
              : provider.saveError != null
              ? _ErrorView(
            message: provider.errorMessage ?? 'Failed to load settings',
            onRetry: provider.fetchSettings,
          )
              : provider.settings == null
              ? const SizedBox.shrink()
              : _SettingsBody(
            formKey: _formKey,
            periodController: _periodController,
            isSaving: provider.isSaving,
            isDirty: _isDirty,
            onSave: () => _save(provider),
            onDiscard: () {
              _periodController.text = _savedValue;
            },
          ),
        );
      },
    );
  }
}

// ─── Settings Body ────────────────────────────────────────────────────────────

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.formKey,
    required this.periodController,
    required this.isSaving,
    required this.isDirty,
    required this.onSave,
    required this.onDiscard,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController periodController;
  final bool isSaving;
  final ValueNotifier<bool> isDirty;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  const _SectionLabel(label: 'Password Policy'),
                  const SizedBox(height: 12),

                  // Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8EAF0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.lock_reset_rounded,
                                  color: Color(0xFF3B6FF0),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Password Change Period',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0xFF1A1F36),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Days between mandatory password resets',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8892A4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: periodController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1F36),
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. 90',
                              hintStyle: const TextStyle(color: Color(0xFFBBC2CF)),
                              suffixText: 'days',
                              suffixStyle: const TextStyle(
                                color: Color(0xFF8892A4),
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FC),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                const BorderSide(color: Color(0xFFE8EAF0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                const BorderSide(color: Color(0xFFE8EAF0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3B6FF0),
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                const BorderSide(color: Color(0xFFC0392B)),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'This field is required';
                              }
                              final n = int.tryParse(v.trim());
                              if (n == null || n < 1) {
                                return 'Enter a valid number of days (min. 1)';
                              }
                              if (n > 3650) return 'Maximum allowed is 3650 days';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Persistent bottom action bar — only this subtree rebuilds on dirty changes
        ValueListenableBuilder<bool>(
          valueListenable: isDirty,
          builder: (context, dirty, _) {
            return AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: dirty
                  ? Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE8EAF0)),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFB45309),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Unsaved changes',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: isSaving ? null : onDiscard,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        side: const BorderSide(color: Color(0xFFCDD2DC)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Discard',
                        style: TextStyle(
                          color: Color(0xFF6B7385),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: isSaving ? null : onSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3B6FF0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: Color(0xFF8892A4),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Color(0xFFCDD2DC),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Color(0xFF8892A4), fontSize: 14),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}