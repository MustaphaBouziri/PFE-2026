import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pfe_mes/domain/auth/providers/auth_provider.dart';
import 'package:pfe_mes/presentation/auth/ChangePassword/changePassPage.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {


  const ProfilePage({
    super.key,
   
  });

  void _showLanguageMenu(BuildContext context, TapDownDetails details) async {
    final selected = await showMenu<String>(
      color: Colors.white,
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        PopupMenuItem(value: 'en', child: Text('languageEnglish'.tr())),
        PopupMenuItem(value: 'fr', child: Text('languageFrench'.tr())),
        PopupMenuItem(value: 'ar', child: Text('languageArabic'.tr())),
      ],
    );

    if (selected != null) {
      context.setLocale(Locale(selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fullName = auth.userData?['fullName']?.toString() ?? 'User';
    final email = auth.userData?['email']?.toString() ?? 'email';
    final imageBytes = auth.profileImageBytes;
    final isPhone = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(title: Text('account'.tr()), centerTitle: true),
      body: Column(
        children: [
          const SizedBox(height: 30),
          CircleAvatar(
  radius: 40,
  backgroundImage: imageBytes != null
      ? MemoryImage(imageBytes)
      : const NetworkImage('https://picsum.photos/200/200') as ImageProvider,
),
          const SizedBox(height: 8),
          Text(
            fullName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: isPhone
                ? EdgeInsets.all(16)
                : const EdgeInsets.symmetric(horizontal: 70, vertical: 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF1F5F9),
              ),
              child: Column(
                children: [
                  ProfileTile(
                    title: 'changeLanguage',
                    icon: Icons.language,
                    onTapDown: (details) => _showLanguageMenu(context, details),
                  ),
                  ProfileTile(
                    title: 'changePassword',
                    icon: Icons.lock,
                    onTap :() => Navigator.push(context, MaterialPageRoute(builder:(context) => ChangePasswordPage(),)),
                  ),
                  ProfileTile(
                    title: 'logout',
                    icon: Icons.logout,
                    color: Colors.red,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final void Function(TapDownDetails)? onTapDown;
  final Color? color;

  const ProfileTile({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
    this.onTapDown,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? Colors.black87;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.grey.withOpacity(0.08),
        splashColor: Colors.grey.withOpacity(0.2),
        onTap: onTap,
        onTapDown: onTapDown,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: itemColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: itemColor),
          ),
          title: Text(
            title.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: itemColor,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }
}
