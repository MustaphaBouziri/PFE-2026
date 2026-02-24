// =============================================================================
// AppConfig
// Path   : lib/core/config/app_config.dart
// Purpose: Single source of truth for all runtime-configurable values.
//          Parses app_config.yaml (bundled as a Flutter asset) and exposes
//          typed, named getters throughout the app.
//
//          No other file should load or parse app_config.yaml directly —
//          always go through AppConfig.
//
// USAGE
//   // In main.dart, before runApp():
//   await AppConfig.load();
//
//   // Anywhere in the app:
//   final url  = AppConfig.bc.baseUrl;
//   final id   = AppConfig.session.deviceId;
//   final flag = AppConfig.features.enableHttpLogging;
// =============================================================================

import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

class AppConfig {
  AppConfig._();

  static late final _BcConfig     _bc;
  static late final _AuthConfig   _auth;
  static late final _OAuthConfig  _oauth;
  static late final _NetworkConfig _network;
  static late final _SessionConfig _session;
  static late final _FeaturesConfig _features;

  static _BcConfig       get bc       => _bc;
  static _AuthConfig     get auth     => _auth;
  static _OAuthConfig    get oauth    => _oauth;
  static _NetworkConfig  get network  => _network;
  static _SessionConfig  get session  => _session;
  static _FeaturesConfig get features => _features;

  // Convenience shortcuts most commonly used across the app
  static String get odataBaseUrl =>
      '${_bc.baseUrl}/ODataV4';

  static String get customApiBaseUrl =>
      '${_bc.baseUrl}/api/${_bc.apiPublisher}/${_bc.apiGroup}/${_bc.apiVersion}';

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Must be awaited in main() before runApp().
  static Future<void> load({String assetPath = 'app_config.yaml'}) async {
    final raw = await rootBundle.loadString(assetPath);
    final yaml = loadYaml(raw) as YamlMap;

    _bc       = _BcConfig._from(yaml['bc']           as YamlMap? ?? YamlMap());
    _auth     = _AuthConfig._from(yaml['auth']        as YamlMap? ?? YamlMap());
    _oauth    = _OAuthConfig._from(yaml['oauth']      as YamlMap? ?? YamlMap());
    _network  = _NetworkConfig._from(yaml['network']  as YamlMap? ?? YamlMap());
    _session  = _SessionConfig._from(yaml['session']  as YamlMap? ?? YamlMap());
    _features = _FeaturesConfig._from(yaml['features'] as YamlMap? ?? YamlMap());
  }
}

// =============================================================================
// Section config objects — one per top-level YAML key
// =============================================================================

class _BcConfig {
  _BcConfig._from(YamlMap y)
      : baseUrl           = _str(y, 'base_url',           'http://localhost:7048/BC210'),
        companyName        = _str(y, 'company_name',        ''),
        odataServiceName   = _str(y, 'odata_service_name',  'MESUnboundActions'),
        machineServiceName = _str(y, 'machine_service_name','MESMachineActions'),
        apiPublisher       = _str(y, 'api_publisher',       'yourcompany'),
        apiGroup           = _str(y, 'api_group',           'v1'),
        apiVersion         = _str(y, 'api_version',         'v1.0');

  final String baseUrl;
  final String companyName;
  final String odataServiceName;
  final String machineServiceName;
  final String apiPublisher;
  final String apiGroup;
  final String apiVersion;
}

class _AuthConfig {
  _AuthConfig._from(YamlMap y)
      : bcUsername = _str(y, 'bc_username', ''),
        bcPassword = _str(y, 'bc_password', '');

  final String bcUsername;
  final String bcPassword;

  bool get hasBasicAuth => bcUsername.isNotEmpty && bcPassword.isNotEmpty;
}

class _OAuthConfig {
  _OAuthConfig._from(YamlMap y)
      : tenantId     = _str(y, 'tenant_id',     ''),
        clientId     = _str(y, 'client_id',     ''),
        clientSecret = _str(y, 'client_secret', ''),
        scope        = _str(y, 'scope',          'https://api.businesscentral.dynamics.com/.default');

  final String tenantId;
  final String clientId;
  final String clientSecret;
  final String scope;

  bool get isConfigured => tenantId.isNotEmpty && clientId.isNotEmpty;
}

class _NetworkConfig {
  _NetworkConfig._from(YamlMap y)
      : connectTimeout = Duration(seconds: _int(y, 'connect_timeout_seconds', 10)),
        receiveTimeout = Duration(seconds: _int(y, 'receive_timeout_seconds', 30));

  final Duration connectTimeout;
  final Duration receiveTimeout;
}

class _SessionConfig {
  _SessionConfig._from(YamlMap y)
      : expiryWarningMinutes = _int(y, 'expiry_warning_minutes', 30),
        deviceId             = _str(y, 'device_id',             'mes-device-001');

  final int    expiryWarningMinutes;
  final String deviceId;
}

class _FeaturesConfig {
  _FeaturesConfig._from(YamlMap y)
      : enableHttpLogging          = _bool(y, 'enable_http_logging',          false),
        enableDebugScreen          = _bool(y, 'enable_debug_screen',          false),
        enableManualMachineRefresh = _bool(y, 'enable_manual_machine_refresh', true),
        machineListRefreshSeconds  = _int(y,  'machine_list_refresh_seconds',  30);

  final bool enableHttpLogging;
  final bool enableDebugScreen;
  final bool enableManualMachineRefresh;
  final int  machineListRefreshSeconds;

  Duration? get machineListRefreshInterval => machineListRefreshSeconds > 0
      ? Duration(seconds: machineListRefreshSeconds)
      : null;
}

// =============================================================================
// Private YAML parsing helpers
// =============================================================================

String _str(YamlMap y, String key, String fallback) {
  final v = y[key];
  if (v == null) return fallback;
  final s = v.toString().trim();
  return s.isEmpty ? fallback : s;
}

int _int(YamlMap y, String key, int fallback) {
  final v = y[key];
  if (v is int) return v;
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

bool _bool(YamlMap y, String key, bool fallback) {
  final v = y[key];
  if (v is bool) return v;
  final s = v?.toString().toLowerCase();
  if (s == 'true') return true;
  if (s == 'false') return false;
  return fallback;
}
