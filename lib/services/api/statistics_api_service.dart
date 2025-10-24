import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../utils/token_manager.dart';

/// 통계 API 서비스
/// 기간별 통계 조회

class StatisticsApiService {
  /// 통계 조회
  /// GET /api/statistics?period=today
  static Future<Map<String, dynamic>> getStatistics({
    required String period, // 'today', 'week', 'month', 'all'
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': '로그인이 필요합니다.',
        };
      }

      final url = Uri.parse(
        ApiConfig.getUrl(ApiConfig.statistics),
      ).replace(queryParameters: {'period': period});

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
          'statistics': data['data'],
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
          'message': data['message'] ?? '통계 조회에 실패했습니다.',
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
