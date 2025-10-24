import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../utils/token_manager.dart';

/// 자동 통화 API 서비스
/// 다음 고객 조회, 통화 결과 등록

class AutoCallApiService {
  /// 다음 고객 가져오기
  /// GET /api/auto-call/next-customer?dbId=1
  static Future<Map<String, dynamic>> getNextCustomer({
    required int dbId,
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
        ApiConfig.getUrl(ApiConfig.autoCallNextCustomer),
      ).replace(queryParameters: {'dbId': dbId.toString()});

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
          'message': data['message'] ?? '고객 조회에 실패했습니다.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다: ${e.toString()}',
      };
    }
  }

  /// 통화 결과 등록
  /// POST /api/call-logs
  static Future<Map<String, dynamic>> saveCallLog({
    required int customerId,
    required int dbId,
    required String callResult,
    String? consultationResult,
    String? memo,
    String? callStartTime,
    String? callEndTime,
    String? callDuration,
    String? reservationDate,
    String? reservationTime,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': '로그인이 필요합니다.',
        };
      }

      final url = Uri.parse(ApiConfig.getUrl(ApiConfig.callLogs));
      final body = {
        'customerId': customerId,
        'dbId': dbId,
        'callResult': callResult,
        if (consultationResult != null) 'consultationResult': consultationResult,
        if (memo != null) 'memo': memo,
        if (callStartTime != null) 'callStartTime': callStartTime,
        if (callEndTime != null) 'callEndTime': callEndTime,
        if (callDuration != null) 'callDuration': callDuration,
        if (reservationDate != null) 'reservationDate': reservationDate,
        if (reservationTime != null) 'reservationTime': reservationTime,
      };

      final response = await http
          .post(
            url,
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'callLogId': data['data']['callLogId'],
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
          'message': data['message'] ?? '통화 결과 저장에 실패했습니다.',
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
