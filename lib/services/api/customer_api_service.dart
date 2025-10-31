import '../../config/api_config.dart';
import 'api_client.dart';

/// 고객 관리 API 서비스 - v3.0.0
/// 고객 검색, 고객 상세 조회

class CustomerApiService {
  static final ApiClient _client = ApiClient();

  /// 고객 검색 (상담원 배정 고객)
  /// GET /api/agent/customers
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
      String queryParams = '';
      if (eventName != null && eventName.isNotEmpty) {
        queryParams += '?event_name=$eventName';
      }
      if (callResult != null && callResult.isNotEmpty) {
        queryParams += queryParams.isEmpty ? '?' : '&';
        queryParams += 'data_status=$callResult';
      }

      // API 호출
      final data = await _client.get('${ApiConfig.agentCustomers}$queryParams');

      if (data['success'] == true) {
        // data['data']가 List인지 Map인지 확인
        List<dynamic> customers;
        if (data['data'] is List) {
          customers = data['data'] as List;
        } else if (data['data'] is Map) {
          // Map 구조인 경우 (예: { total: 10, customers: [...] })
          final dataMap = data['data'] as Map<String, dynamic>;
          customers = dataMap['customers'] as List? ?? [];
        } else {
          customers = [];
        }

        return {
          'success': true,
          'customers': customers,
          'pagination': {
            'totalPages': 1,
            'currentPage': 1,
            'totalCount': customers.length,
          },
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
