import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../utils/token_manager.dart';

/// 고객 관리 API 서비스
/// 고객 검색, 상세 조회

class CustomerApiService {
  /// 고객 검색
  /// GET /api/customers/search?name=홍길동&phone=010-1234-5678
  static Future<Map<String, dynamic>> searchCustomers({
    String? name,
    String? phone,
    String? eventName,
    String? callResult,
    int page = 1,
    int limit = 20,
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
        if (name != null && name.isNotEmpty) 'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (eventName != null && eventName.isNotEmpty) 'eventName': eventName,
        if (callResult != null && callResult.isNotEmpty)
          'callResult': callResult,
      };

      final url = Uri.parse(
        ApiConfig.getUrl(ApiConfig.customerSearch),
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
          'message': data['message'] ?? '고객 검색에 실패했습니다.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다: ${e.toString()}',
      };
    }
  }

  /// 고객 상세 조회
  /// GET /api/customers/:customerId
  static Future<Map<String, dynamic>> getCustomerDetail({
    required int customerId,
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
        ApiConfig.getUrl(ApiConfig.customerDetail(customerId)),
      );

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
          'customer': data['data'],
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
          'message': data['message'] ?? '고객 정보 조회에 실패했습니다.',
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
