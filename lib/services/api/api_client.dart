import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../utils/token_manager.dart';

/// API 클라이언트
/// v3.0.0 - JWT 토큰 기반 인증, 자동 토큰 갱신
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _token;

  /// 토큰 설정
  void setToken(String token) {
    _token = token;
  }

  /// 저장된 토큰 로드
  Future<void> loadToken() async {
    _token = await TokenManager.getToken();
  }

  /// GET 요청
  Future<Map<String, dynamic>> get(String endpoint) async {
    await loadToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _getHeaders(),
    ).timeout(ApiConfig.connectionTimeout);

    return _handleResponse(response);
  }

  /// POST 요청
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    await loadToken();

    final url = '${ApiConfig.baseUrl}$endpoint';

    // 디버그 로그
    debugPrint('=== API POST 요청 ===');
    debugPrint('URL: $url');
    debugPrint('Body: ${jsonEncode(body)}');
    debugPrint('Headers: ${_getHeaders()}');

    final response = await http.post(
      Uri.parse(url),
      headers: _getHeaders(),
      body: jsonEncode(body),
    ).timeout(ApiConfig.connectionTimeout);

    // 응답 로그
    debugPrint('=== API 응답 ===');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    return _handleResponse(response);
  }

  /// PUT 요청
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    await loadToken();

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _getHeaders(),
      body: jsonEncode(body),
    ).timeout(ApiConfig.connectionTimeout);

    return _handleResponse(response);
  }

  /// DELETE 요청
  Future<Map<String, dynamic>> delete(String endpoint) async {
    await loadToken();

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _getHeaders(),
    ).timeout(ApiConfig.connectionTimeout);

    return _handleResponse(response);
  }

  /// 헤더 생성
  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  /// 응답 처리
  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        message: data['message'] ?? 'Unknown error',
        errorCode: data['errorCode'],
        statusCode: response.statusCode,
      );
    }
  }
}

/// API 예외
class ApiException implements Exception {
  final String message;
  final String? errorCode;
  final int statusCode;

  ApiException({
    required this.message,
    this.errorCode,
    required this.statusCode,
  });

  @override
  String toString() => message;

  /// 인증 관련 에러인지 확인
  bool get isAuthError {
    return errorCode?.startsWith('AUTH_') ?? false;
  }

  /// 토큰 만료 에러인지 확인
  bool get isTokenExpired {
    return errorCode == 'AUTH_TOKEN_EXPIRED';
  }

  /// 권한 없음 에러인지 확인
  bool get isUnauthorized {
    return statusCode == 401 || errorCode == 'AUTH_UNAUTHORIZED';
  }
}
