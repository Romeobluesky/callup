import '../../config/api_config.dart';
import '../../utils/token_manager.dart';
import 'api_client.dart';

/// 인증 API 서비스 - v3.0.0
/// 로그인, 로그아웃, 토큰 갱신 등 인증 관련 API 호출

class AuthApiService {
  static final ApiClient _client = ApiClient();

  /// 업체 기반 로그인 (v3.0.0)
  /// POST /api/auth/login
  /// 업체 ID + 비밀번호 + 상담원 이름으로 로그인
  static Future<Map<String, dynamic>> login({
    required String companyLoginId,
    required String companyPassword,
    required String userName,
  }) async {
    try {
      final data = await _client.post(
        ApiConfig.authLogin,
        {
          'companyLoginId': companyLoginId,
          'companyPassword': companyPassword,
          'userName': userName,
        },
      );

      if (data['success'] == true) {
        // JWT 토큰 저장
        final token = data['data']['token'];
        await TokenManager.saveToken(token);
        _client.setToken(token);

        // 사용자 정보 저장
        await TokenManager.saveUserInfo(
          userId: data['data']['user']['userId'].toString(),
          userName: data['data']['user']['userName'],
          companyId: data['data']['company']['companyId'].toString(),
          companyName: data['data']['company']['companyName'],
        );

        return {
          'success': true,
          'message': data['message'],
          'user': data['data']['user'],
          'company': data['data']['company'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? '로그인에 실패했습니다.',
        };
      }
    } on ApiException catch (e) {
      return {
        'success': false,
        'message': e.message,
        'errorCode': e.errorCode,
      };
    } catch (e) {
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다: ${e.toString()}',
      };
    }
  }

  /// 로그아웃
  /// 로컬에 저장된 토큰 및 사용자 정보 삭제
  static Future<void> logout() async {
    await TokenManager.clearAll();
  }

  /// 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    return await TokenManager.isLoggedIn();
  }

  /// 현재 사용자 정보 조회
  static Future<Map<String, String?>> getCurrentUser() async {
    final userId = await TokenManager.getUserId();
    final userName = await TokenManager.getUserName();
    return {
      'userId': userId,
      'userName': userName,
    };
  }
}
