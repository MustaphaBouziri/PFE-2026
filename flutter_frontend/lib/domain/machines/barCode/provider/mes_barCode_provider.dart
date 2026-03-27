// lib/providers/barcode_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/barCode/models/mes_barCode_model.dart';
import 'package:pfe_mes/data/machine/barCode/models/services/mes_barCode_service.dart';

class MesBarcodeProvider with ChangeNotifier {
  final MesBarcodeService _service = MesBarcodeService();

  List<ItemBarcodeModel> barcodes = [];
  bool isLoading = false;
  String? errorMessage;

  /// fetch all barcodes and update state.
  Future<void> fetchAllBarcodes() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      barcodes = await _service.fetchAllBarcodes();
    } catch (e) {
      errorMessage = e.toString();
      
    } 
     isLoading = false;
      notifyListeners();
  }

  Future<bool> insertScans(
    String executionId,
    List<Map<String, dynamic>> scans,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.insertScans(executionId, scans);
      return result;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}