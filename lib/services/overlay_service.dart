import 'package:flutter/services.dart';

class OverlayService {
  static const MethodChannel _channel = MethodChannel('com.callup.callup/overlay');

  /// 오버레이 표시
  static Future<void> showOverlay({
    required String customerName,
    required String customerPhone,
    required String progress,
    required String status,
    required int countdown,
  }) async {
    try {
      await _channel.invokeMethod('showOverlay', {
        'customerName': customerName,
        'customerPhone': customerPhone,
        'progress': progress,
        'status': status,
        'countdown': countdown,
      });
    } catch (e) {
      print('오버레이 표시 실패: $e');
    }
  }

  /// 오버레이 업데이트
  static Future<void> updateOverlay({
    required String customerName,
    required String customerPhone,
    required String progress,
    required String status,
    required int countdown,
  }) async {
    try {
      await _channel.invokeMethod('updateOverlay', {
        'customerName': customerName,
        'customerPhone': customerPhone,
        'progress': progress,
        'status': status,
        'countdown': countdown,
      });
    } catch (e) {
      print('오버레이 업데이트 실패: $e');
    }
  }

  /// 오버레이 숨기기
  static Future<void> hideOverlay() async {
    try {
      await _channel.invokeMethod('hideOverlay');
    } catch (e) {
      print('오버레이 숨기기 실패: $e');
    }
  }

  /// 오버레이 권한 요청
  static Future<bool> requestOverlayPermission() async {
    try {
      final bool? result = await _channel.invokeMethod('requestOverlayPermission');
      return result ?? false;
    } catch (e) {
      print('오버레이 권한 요청 실패: $e');
      return false;
    }
  }

  /// 오버레이 권한 확인
  static Future<bool> checkOverlayPermission() async {
    try {
      final bool? result = await _channel.invokeMethod('checkOverlayPermission');
      return result ?? false;
    } catch (e) {
      print('오버레이 권한 확인 실패: $e');
      return false;
    }
  }
}
