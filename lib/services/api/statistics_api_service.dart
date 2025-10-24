import '../../config/api_config.dart';
import 'api_client.dart';

/// 통계 API 서비스 - v3.0.0
/// 상담원 통계 조회

class StatisticsApiService {
  static final ApiClient _client = ApiClient();

  /// 상담원 통계 조회
  /// GET /api/statistics?period=today|week|month|all
  static Future<Map<String, dynamic>> getStatistics({
    required String period,
  }) async {
    try {
      final endpoint = '${ApiConfig.statistics}?period=$period';
      final data = await _client.get(endpoint);

      if (data['success'] == true) {
        return {
          'success': true,
          'user': data['data']['user'],
          'period': data['data']['period'],
          'stats': data['data']['stats'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? '통계 조회에 실패했습니다.',
        };
      }
    } on ApiException catch (e) {
      return {
        'success': false,
        'message': e.message,
        'errorCode': e.errorCode,
        'requireLogin': e.isUnauthorized,
      };
    } catch (e) {
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다: ${e.toString()}',
      };
    }
  }
}
