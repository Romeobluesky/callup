import 'package:shared_preferences/shared_preferences.dart';

/// JWT 토큰 관리 유틸리티
/// 로그인 후 받은 JWT 토큰을 로컬에 저장/조회/삭제하는 클래스

class TokenManager {
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';

  /// JWT 토큰 저장
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// JWT 토큰 조회
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// JWT 토큰 삭제
  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// 사용자 정보 저장
  static Future<void> saveUserInfo({
    required String userId,
    required String userName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userNameKey, userName);
  }

  /// 사용자 ID 조회
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// 사용자 이름 조회
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  /// 사용자 정보 삭제
  static Future<void> deleteUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
  }

  /// 전체 로그아웃 (토큰 + 사용자 정보 삭제)
  static Future<void> clearAll() async {
    await deleteToken();
    await deleteUserInfo();
  }

  /// 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
