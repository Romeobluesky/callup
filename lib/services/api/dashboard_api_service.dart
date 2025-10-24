import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../utils/token_manager.dart';

/// 대시보드 API 서비스
/// 대시보드 데이터 조회, 사용자 상태 업데이트

class DashboardApiService {
  /// 대시보드 데이터 조회
  /// GET /api/dashboard
  static Future<Map<String, dynamic>> getDashboard() async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': '로그인이 필요합니다.',
        };
      }

      final url = Uri.parse(ApiConfig.getUrl(ApiConfig.dashboard));
      final response = await http
          .get(
            url,
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else if (response.statusCode == 401) {
        // 토큰 만료
        await TokenManager.clearAll();
        return {
          'success': false,
          'message': '로그인이 만료되었습니다. 다시 로그인해주세요.',
          'requireLogin': true,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? '데이터 조회에 실패했습니다.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다: ${e.toString()}',
      };
    }
  }

  /// 사용자 상태 업데이트
  /// PATCH /api/users/status
  static Future<Map<String, dynamic>> updateUserStatus({
    required bool isActive,
    required String statusMessage,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': '로그인이 필요합니다.',
        };
      }

      final url = Uri.parse(ApiConfig.getUrl(ApiConfig.userStatus));
      final response = await http
          .patch(
            url,
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode({
              'isActive': isActive,
              'statusMessage': statusMessage,
            }),
          )
          .timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else if (response.statusCode == 401) {
        await TokenManager.clearAll();
        return {
          'success': false,
          'message': '로그인이 만료되었습니다.',
          'requireLogin': true,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? '상태 업데이트에 실패했습니다.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다: ${e.toString()}',
      };
    }
  }
}
