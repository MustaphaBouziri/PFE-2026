// =============================================================================
// ApiClient
// Path   : lib/core/network/api_client.dart
// Purpose: Single, configured Dio HTTP client for all BC API calls.
//          Provides two call surfaces:
//            postODataAction()  — OData unbound action POST
//            getEntitySet()     — Custom API GET (returns OData value array)
//
//          All authentication headers, company scoping, timeout, and logging
//          are configured here from AppConfig.  No other file creates Dio.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../errors/app_exceptions.dart';

class ApiClient {
  ApiClient._() : _dio = _createDio();

  /// Singleton — created once at startup and reused everywhere.
  static final ApiClient instance = ApiClient._();

  final Dio _dio;

  // ---------------------------------------------------------------------------
  // Dio configuration
  // ---------------------------------------------------------------------------

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: AppConfig.network.connectTimeout,
        receiveTimeout: AppConfig.network.receiveTimeout,
        headers: _buildHeaders(),
        followRedirects: false,
        // Accept everything below 500 so we can inspect 401/403 ourselves.
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (AppConfig.features.enableHttpLogging) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, requestHeader: false),
      );
    }

    return dio;
  }

  static Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader:      'application/json',
    };

    // On-premises basic auth (ignored when OAuth is configured)
    if (!AppConfig.oauth.isConfigured && AppConfig.auth.hasBasicAuth) {
      final encoded = base64.encode(
        utf8.encode('${AppConfig.auth.bcUsername}:${AppConfig.auth.bcPassword}'),
      );
      headers[HttpHeaders.authorizationHeader] = 'Basic $encoded';
    }

    return headers;
  }

  // ---------------------------------------------------------------------------
  // Company scoping
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _companyParams([Map<String, dynamic>? extra]) {
    final params = <String, dynamic>{};
    if (AppConfig.bc.companyName.isNotEmpty) {
      params[AppConstants.api.companyQueryParam] = AppConfig.bc.companyName;
    }
    if (extra != null) params.addAll(extra);
    return params;
  }

  // ---------------------------------------------------------------------------
  // OData unbound action POST
  //
  // URL: <odataBaseUrl>/<serviceName>_<actionName>?company=<n>
  // Returns the parsed JSON map on success (success=true already verified).
  // Throws AppException on any failure.
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> postODataAction(
      String serviceName,
      String actionName,
      Map<String, dynamic> body,
      ) async {
    final url =
        '${AppConfig.odataBaseUrl}/$serviceName${AppConstants.api.actionSeparator}$actionName';
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: body,
        queryParameters: _companyParams(),
      );
      return _processODataResponse(response);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Custom API GET — returns the OData "value" array
  //
  // URL: <customApiBaseUrl>/companies(<companyId>)/<entitySet>
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getEntitySet(
      String companyId,
      String entitySet, {
        Map<String, dynamic>? queryParams,
      }) async {
    final url = '${AppConfig.customApiBaseUrl}/companies($companyId)/$entitySet';
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: _companyParams(queryParams),
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const UnauthorizedException();
      }
      if (response.statusCode != 200) {
        throw ApiException(
          'Unexpected HTTP ${response.statusCode}',
          code: AppConstants.errorCodes.internalError,
        );
      }

      final data = response.data;
      if (data == null) throw const UnexpectedException('Empty response body');

      final value = data[AppConstants.api.fieldValue];
      return value is List ? value.cast<Map<String, dynamic>>() : [];
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Response processing
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _processODataResponse(
      Response<Map<String, dynamic>> response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const UnauthorizedException();
    }

    final data = response.data;
    if (data == null) throw const UnexpectedException('Empty response body');

    final success = data[AppConstants.api.fieldSuccess] as bool? ?? false;
    if (!success) {
      throw ApiException(
        data[AppConstants.api.fieldMessage] as String? ?? 'Unknown error',
        code: data[AppConstants.api.fieldError] as String?,
      );
    }
    return data;
  }

  // ---------------------------------------------------------------------------
  // Dio error → typed AppException
  // ---------------------------------------------------------------------------

  AppException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('Request timed out. Check your network connection.');
      case DioExceptionType.connectionError:
        return const NetworkException(
            'Cannot reach the server. Check bc.base_url in app_config.yaml.');
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 401 || status == 403) return const UnauthorizedException();
        return ApiException('Server returned HTTP $status',
            code: AppConstants.errorCodes.internalError);
      default:
        return UnexpectedException(e.message ?? 'Network error');
    }
  }
}
