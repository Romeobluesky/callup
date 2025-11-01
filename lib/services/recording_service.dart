import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 녹취 파일 관리 서비스
/// Flutter ↔ Native 브릿지
class RecordingService {
  static const MethodChannel _channel = MethodChannel('com.callup/recording');

  /// 자동 업로드 백그라운드 서비스 시작
  static Future<bool> startAutoUploadService() async {
    try {
      final result = await _channel.invokeMethod('startAutoUpload');
      return result as bool;
    } catch (e) {
      debugPrint('자동 업로드 서비스 시작 오류: $e');
      return false;
    }
  }

  /// 자동 업로드 서비스 중지
  static Future<bool> stopAutoUploadService() async {
    try {
      final result = await _channel.invokeMethod('stopAutoUpload');
      return result as bool;
    } catch (e) {
      debugPrint('자동 업로드 서비스 중지 오류: $e');
      return false;
    }
  }

  /// 특정 전화번호의 녹취 파일 존재 여부 확인
  static Future<bool> hasRecording(String phoneNumber) async {
    try {
      final result = await _channel.invokeMethod('hasRecording', {
        'phoneNumber': phoneNumber,
      });
      return result as bool;
    } catch (e) {
      debugPrint('녹취 확인 오류: $e');
      return false;
    }
  }

  /// 녹취 파일 재생 (휴대폰 기본 플레이어)
  static Future<void> playRecording(String phoneNumber) async {
    try {
      await _channel.invokeMethod('playRecording', {
        'phoneNumber': phoneNumber,
      });
    } catch (e) {
      debugPrint('녹취 재생 오류: $e');
      rethrow;
    }
  }
}
