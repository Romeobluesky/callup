import 'package:flutter/services.dart';
import 'auto_call_service.dart';

class OverlayService {
  static const MethodChannel _channel = MethodChannel('com.callup.callup/overlay');

  /// MethodChannel 핸들러 설정 (Native → Flutter 콜백)
  static void setupCallbackHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onConnected':
          // 오버레이에서 "통화 연결됨" 버튼 클릭
          AutoCallService().notifyConnected();
          break;
        case 'onTimeout':
          // 오버레이에서 "다음" 버튼 클릭 또는 카운트다운 타임아웃
          AutoCallService().notifySkip();
          break;
      }
    });
  }

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
      // 오버레이 표시 실패 시 무시
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
      // 오버레이 업데이트 실패 시 무시
    }
  }

  /// 오버레이 숨기기
  static Future<void> hideOverlay() async {
    try {
      await _channel.invokeMethod('hideOverlay');
    } catch (e) {
      // 오버레이 숨기기 실패 시 무시
    }
  }
}
