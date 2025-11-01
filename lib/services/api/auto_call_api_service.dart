import '../../config/api_config.dart';
import 'api_client.dart';

/// 자동 통화 API 서비스 - v3.0.0
/// 고객 큐 가져오기, 자동 통화 로그 저장

class AutoCallApiService {
  static final ApiClient _client = ApiClient();

  /// 자동 통화 시작 (고객 큐 가져오기)
  /// POST /api/auto-call/start
  static Future<Map<String, dynamic>> startAutoCalling({
    required int dbId,
    required int count,
  }) async {
    try {
      final data = await _client.post(
        ApiConfig.autoCallStart,
        {
          'dbId': dbId,
          'count': count,
        },
      );

      if (data['success'] == true) {
        return {
          'success': true,
          'customers': data['data']['customers'],
          'totalCount': data['data']['totalCount'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? '고객 큐 조회에 실패했습니다.',
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

  /// 자동 통화 로그 저장 (부재중, 자동 스킵 등)
  /// POST /api/auto-call/log
  static Future<Map<String, dynamic>> saveAutoCallLog({
    required int customerId,
    required int dbId,
    required String callResult,
    String? consultationResult,
    String? callDuration,
  }) async {
    try {
      final data = await _client.post(
        ApiConfig.autoCallLog,
        {
          'customerId': customerId,
          'dbId': dbId,
          'callResult': callResult,
          if (consultationResult != null) 'consultationResult': consultationResult,
          if (callDuration != null) 'callDuration': callDuration,
        },
      );

      if (data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'logId': data['data']['logId'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? '통화 로그 저장에 실패했습니다.',
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

  /// 수동 통화 결과 저장 (통화 연결됨)
  /// POST /api/call-result
  static Future<Map<String, dynamic>> saveCallResult({
    required int customerId,
    required int dbId,
    required String callResult,
    String? consultationResult,  // nullable로 변경
    String? memo,
    required String callStartTime,
    required String callEndTime,
    required String callDuration,
    String? reservationDate,
    String? reservationTime,
  }) async {
    try {
      final data = await _client.post(
        ApiConfig.callResult,
        {
          'customerId': customerId,
          'dbId': dbId,
          'callResult': callResult,
          if (consultationResult != null) 'consultationResult': consultationResult,  // null 체크 추가
          if (memo != null) 'memo': memo,
          'callStartTime': callStartTime,
          'callEndTime': callEndTime,
          'callDuration': callDuration,
          if (reservationDate != null) 'reservationDate': reservationDate,
          if (reservationTime != null) 'reservationTime': reservationTime,
        },
      );

      if (data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'logId': data['data']['logId'],
          'customerId': data['data']['customerId'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? '통화 결과 저장에 실패했습니다.',
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
