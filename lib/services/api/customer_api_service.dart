import '../../config/api_config.dart';
import 'api_client.dart';

/// 고객 관리 API 서비스 - v3.0.0
/// 고객 검색, 고객 상세 조회

class CustomerApiService {
  static final ApiClient _client = ApiClient();

  /// 고객 검색
  /// GET /api/customers/search?name=&phone=&eventName=&callResult=&page=1&limit=20
  static Future<Map<String, dynamic>> searchCustomers({
    String? name,
    String? phone,
    String? eventName,
    String? callResult,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // 쿼리 파라미터 구성
      final queryParams = <String>[];
      if (name != null && name.isNotEmpty) queryParams.add('name=$name');
      if (phone != null && phone.isNotEmpty) queryParams.add('phone=$phone');
      if (eventName != null && eventName.isNotEmpty) queryParams.add('eventName=$eventName');
      if (callResult != null && callResult.isNotEmpty) queryParams.add('callResult=$callResult');
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');

      final endpoint = '${ApiConfig.customersSearch}?${queryParams.join('&')}';
      final data = await _client.get(endpoint);

      if (data['success'] == true) {
        return {
          'success': true,
          'customers': data['data']['customers'],
          'pagination': data['data']['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? '고객 검색에 실패했습니다.',
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

  /// 고객 상세 조회
  /// GET /api/customers/:customerId
  static Future<Map<String, dynamic>> getCustomerDetail({
    required int customerId,
  }) async {
    try {
      final data = await _client.get(ApiConfig.customerDetail(customerId));

      if (data['success'] == true) {
        return {
          'success': true,
          'customer': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? '고객 정보 조회에 실패했습니다.',
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
