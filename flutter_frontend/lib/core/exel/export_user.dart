import 'dart:io';
import 'dart:html' as html;

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:pfe_mes/data/admin/models/mes_user_model.dart';

class ExportUserService {
  Future<void> exportUsersToExcel(List<MesUser> users) async {
    try {
      // create exel document
      var excel = Excel.createExcel();

      //renaming the default name to Users
      String defaultSheet = excel.getDefaultSheet()!;
      excel.rename(defaultSheet, 'Users');

      // get sheet
      Sheet sheetObject = excel['Users'];

      // headers
      List<String> headers = [
        'Full Name',
        'Email',
        'Role',
        'Status',
      ];

      //add headers
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(
          CellIndex.indexByColumnRow(
            columnIndex: i,
            rowIndex: 0,
          ),
        );

        cell.value = TextCellValue(headers[i]);

        cell.cellStyle = CellStyle(
          bold: true,
        );
      }

      // add users data
      for (int i = 0; i < users.length; i++) {
        final user = users[i];
        final rowIndex = i + 1;

        sheetObject
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: 0,
                rowIndex: rowIndex,
              ),
            )
            .value = TextCellValue(user.fullName);

        sheetObject
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: 1,
                rowIndex: rowIndex,
              ),
            )
            .value = TextCellValue(user.email);

        sheetObject
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: 2,
                rowIndex: rowIndex,
              ),
            )
            .value = TextCellValue(user.role);

        sheetObject
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: 3,
                rowIndex: rowIndex,
              ),
            )
            .value = TextCellValue(
          user.isPendingSetup ? 'Pending' : 'Active',
        );
      }

      // Column widths
      sheetObject.setColumnWidth(0, 25);
      sheetObject.setColumnWidth(1, 35);
      sheetObject.setColumnWidth(2, 20);
      sheetObject.setColumnWidth(3, 15);

      // row hight
      sheetObject.setRowHeight(0, 22); 

      for (int i = 1; i <= users.length; i++) {
        sheetObject.setRowHeight(i, 20);
      }

      // encode the file
      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception('Failed to encode Excel file');
      }

      // web
      if (kIsWeb) {
        _downloadFileWeb(bytes);
      }

      // this is for mobile and dezsktop
      else {
        final directory = await getApplicationDocumentsDirectory();

        final filePath =
            '${directory.path}/MES_Users_${DateTime.now().millisecondsSinceEpoch}.xlsx';

        final file = File(filePath);

        await file.writeAsBytes(bytes);

        // share file 
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'MES Users Export',
        );
      }
    } catch (e) {
      throw Exception('Failed to export users: $e');
    }
  }

  // download for web
  void _downloadFileWeb(List<int> bytes) {
    final blob = html.Blob([bytes]);

    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        'MES_Users_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      )
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}