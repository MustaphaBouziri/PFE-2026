import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguageSelector extends StatefulWidget {
  final bool isCompact;

  const LanguageSelector({
    super.key,
    this.isCompact = false,
  });

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  late String _selectedLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLanguage = context.locale.languageCode;
  }

  final Map<String, String> languages = {
    'en': 'English',
    'fr': 'Français',
    'ar': 'العربية',
  };

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      // Compact version for appbar
      return PopupMenuButton<String>(
        icon: const Icon(Icons.language, size: 20),
        onSelected: (String languageCode) {
          setState(() => _selectedLanguage = languageCode);
          context.setLocale(Locale(languageCode));
        },
        itemBuilder: (BuildContext context) {
          return languages.entries.map((entry) {
            return PopupMenuItem<String>(
              value: entry.key,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (entry.key == _selectedLanguage)
                    const Icon(Icons.check, size: 16, color: Colors.blue),
                  if (entry.key == _selectedLanguage)
                    const SizedBox(width: 8),
                  Text(entry.value),
                ],
              ),
            );
          }).toList();
        },
      );
    } else {
      // Full version for login page
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedLanguage,
            dropdownColor: Colors.white,
            icon: const Icon(Icons.language, size: 20),
            items: languages.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  entry.value,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (String? newLanguage) {
              if (newLanguage != null) {
                setState(() => _selectedLanguage = newLanguage);
                context.setLocale(Locale(newLanguage));
              }
            },
          ),
        ),
      );
    }
  }
}