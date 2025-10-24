import '../../config/api_config.dart';
import 'api_client.dart';

/// 대시보드 API 서비스 - v3.0.0
/// 대시보드 데이터 조회, 상담원 상태 토글

class DashboardApiService {
  static final ApiClient _client = ApiClient();

  /// 대시보드 데이터 조회
  /// GET /api/dashboard
  static Future<Map<String, dynamic>> getDashboard() async {
    try {
      final data = await _client.get(ApiConfig.dashboard);

      if (data['success'] == true) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? '데이터 조회에 실패했습니다.',
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

  /// 상담원 상태 토글
  /// PUT /api/dashboard/status
  static Future<Map<String, dynamic>> toggleStatus({
    required bool isOn,
  }) async {
    try {
      final data = await _client.put(
        ApiConfig.dashboardStatus,
        {'isOn': isOn},
      );

      if (data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'isOn': data['data']['isOn'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? '상태 업데이트에 실패했습니다.',
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
