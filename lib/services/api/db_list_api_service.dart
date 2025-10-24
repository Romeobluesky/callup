import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../utils/token_manager.dart';

/// DB 리스트 API 서비스
/// DB 리스트 조회, 특정 DB의 고객 목록 조회

class DbListApiService {
  /// DB 리스트 전체 조회
  /// GET /api/db-lists?search=이벤트
  static Future<Map<String, dynamic>> getDbLists({
    String? search,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': '로그인이 필요합니다.',
        };
      }

      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final url = Uri.parse(
        ApiConfig.getUrl(ApiConfig.dbLists),
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

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
          'dbLists': data['data'],
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
          'message': data['message'] ?? 'DB 리스트 조회에 실패했습니다.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다: ${e.toString()}',
      };
    }
  }

  /// 특정 DB의 고객 목록 조회
  /// GET /api/db-lists/:dbId/customers?status=미사용&page=1&limit=50
  static Future<Map<String, dynamic>> getDbCustomers({
    required int dbId,
    String? status, // '미사용' or '사용완료'
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': '로그인이 필요합니다.',
        };
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final url = Uri.parse(
        ApiConfig.getUrl(ApiConfig.dbListCustomers(dbId)),
      ).replace(queryParameters: queryParams);

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
          'dbInfo': data['data']['dbInfo'],
          'customers': data['data']['customers'],
          'pagination': data['data']['pagination'],
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
          'message': data['message'] ?? '고객 목록 조회에 실패했습니다.',
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
