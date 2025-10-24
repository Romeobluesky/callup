import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../utils/token_manager.dart';

/// 인증 API 서비스
/// 로그인, 로그아웃 등 인증 관련 API 호출

class AuthApiService {
  /// 로그인
  /// POST /api/auth/login
  static Future<Map<String, dynamic>> login({
    required String userId,
    required String userName,
    required String password,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.getUrl(ApiConfig.login));
      final response = await http
          .post(
            url,
            headers: ApiConfig.defaultHeaders,
            body: jsonEncode({
              'userId': userId,
              'userName': userName,
              'password': password,
            }),
          )
          .timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // JWT 토큰 저장
        final token = data['data']['token'];
        await TokenManager.saveToken(token);

        // 사용자 정보 저장
        await TokenManager.saveUserInfo(
          userId: data['data']['user']['userId'],
          userName: data['data']['user']['userName'],
        );

        return {
          'success': true,
          'message': data['message'],
          'user': data['data']['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? '로그인에 실패했습니다.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다: ${e.toString()}',
      };
    }
  }

  /// 로그아웃
  /// 로컬에 저장된 토큰 및 사용자 정보 삭제
  static Future<void> logout() async {
    await TokenManager.clearAll();
  }

  /// 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    return await TokenManager.isLoggedIn();
  }

  /// 현재 사용자 정보 조회
  static Future<Map<String, String?>> getCurrentUser() async {
    final userId = await TokenManager.getUserId();
    final userName = await TokenManager.getUserName();
    return {
      'userId': userId,
      'userName': userName,
    };
  }
}
