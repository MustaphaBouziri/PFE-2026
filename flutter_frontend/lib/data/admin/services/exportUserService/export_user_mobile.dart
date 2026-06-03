// export_user_mobile.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadFile(List<int> bytes, String fileName) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    await file.writeAsBytes(bytes);

    // Share file
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'MES Users Export',
    );
  } catch (e) {
    throw Exception('Failed to download file: $e');
  }
}