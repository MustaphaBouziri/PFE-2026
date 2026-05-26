// export_user_web.dart
import 'dart:html' as html;

Future<void> downloadFile(List<int> bytes, String fileName) async {
  try {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();

    html.Url.revokeObjectUrl(url);
  } catch (e) {
    throw Exception('Failed to download file on web: $e');
  }
}