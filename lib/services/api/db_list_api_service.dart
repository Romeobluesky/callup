import '../../config/api_config.dart';
import 'api_client.dart';

/// DB 리스트 API 서비스 - v3.0.0
/// DB 리스트 조회, DB 활성화/비활성화

class DbListApiService {
  static final ApiClient _client = ApiClient();

  /// DB 리스트 조회
  /// GET /api/db-lists?search=keyword
  static Future<Map<String, dynamic>> getDbLists({String? search}) async {
    try {
      String endpoint = ApiConfig.dbLists;
      if (search != null && search.isNotEmpty) {
        endpoint += '?search=$search';
      }

      final data = await _client.get(endpoint);

      if (data['success'] == true) {
        return {
          'success': true,
          'dbLists': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'DB 리스트 조회에 실패했습니다.',
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

  /// DB 활성화/비활성화 토글
  /// PUT /api/db-lists/:dbId/toggle
  static Future<Map<String, dynamic>> toggleDbList({
    required int dbId,
    required bool isActive,
  }) async {
    try {
      final data = await _client.put(
        ApiConfig.dbListToggle(dbId),
        {'isActive': isActive},
      );

      if (data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'dbId': data['data']['dbId'],
          'isActive': data['data']['isActive'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'DB 상태 업데이트에 실패했습니다.',
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
