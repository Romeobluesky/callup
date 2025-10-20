import 'dart:io';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:phone_state/phone_state.dart';

class PhoneService {
  static StreamSubscription<PhoneState>? _phoneStateSubscription;
  static final _phoneStateController = StreamController<PhoneStateStatus>.broadcast();
  static const platform = MethodChannel('com.callup.callup/foreground');

  /// 전화 상태 스트림
  static Stream<PhoneStateStatus> get phoneStateStream => _phoneStateController.stream;

  /// 전화 권한 요청 (CALL_PHONE 권한)
  static Future<bool> requestPhonePermission() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  /// 전화 상태 감지 시작
  static Future<void> startPhoneStateMonitoring() async {
    try {
      // READ_PHONE_STATE 권한 확인
      var status = await Permission.phone.status;
      if (!status.isGranted) {
        status = await Permission.phone.request();
        if (!status.isGranted) {
          debugPrint('전화 상태 읽기 권한이 거부되었습니다.');
          return;
        }
      }

      // 전화 상태 감지 시작
      _phoneStateSubscription = PhoneState.stream.listen((PhoneState state) {
        debugPrint('=== 전화 상태 변경 ===');
        debugPrint('상태: ${state.status}');
        debugPrint('전화번호: ${state.number}');

        _phoneStateController.add(state.status);
      });

      debugPrint('전화 상태 모니터링 시작');
    } catch (e) {
      debugPrint('전화 상태 모니터링 오류: $e');
    }
  }

  /// 전화 상태 감지 중지
  static void stopPhoneStateMonitoring() {
    _phoneStateSubscription?.cancel();
    _phoneStateSubscription = null;
    debugPrint('전화 상태 모니터링 중지');
  }

  /// 전화 걸기 (바로 통화 시작)
  static Future<bool> makePhoneCall(String phoneNumber) async {
    try {
      // 전화번호에서 '-' 제거
      final cleanNumber = phoneNumber.replaceAll('-', '').replaceAll(' ', '');

      // CALL_PHONE 권한 확인 및 요청
      var status = await Permission.phone.status;
      if (!status.isGranted) {
        status = await Permission.phone.request();
        if (!status.isGranted) {
          debugPrint('전화 권한이 거부되었습니다.');
          return false;
        }
      }

      debugPrint('전화 걸기 시도: $cleanNumber');

      // Android에서만 작동
      if (Platform.isAndroid) {
        // Android Intent를 사용하여 바로 전화 걸기
        final intent = AndroidIntent(
          action: 'android.intent.action.CALL',
          data: 'tel:$cleanNumber',
        );

        await intent.launch();
        debugPrint('전화 걸기 성공');
        return true;
      } else {
        debugPrint('Android 플랫폼이 아닙니다.');
        return false;
      }
    } catch (e) {
      debugPrint('전화 걸기 오류: $e');
      return false;
    }
  }

  /// 백그라운드에서 전화 걸기 (앱은 포그라운드 유지)
  static Future<void> makePhoneCallInBackground(String phoneNumber) async {
    try {
      // 전화번호에서 '-' 제거
      final cleanNumber = phoneNumber.replaceAll('-', '').replaceAll(' ', '');

      // CALL_PHONE 권한 확인 및 요청
      var status = await Permission.phone.status;
      if (!status.isGranted) {
        status = await Permission.phone.request();
        if (!status.isGranted) {
          debugPrint('전화 권한이 거부되었습니다.');
          return;
        }
      }

      debugPrint('백그라운드 전화 걸기 시도: $cleanNumber');

      // Android에서만 작동
      if (Platform.isAndroid) {
        // Android Intent를 사용하여 바로 전화 걸기
        final intent = AndroidIntent(
          action: 'android.intent.action.CALL',
          data: 'tel:$cleanNumber',
        );

        await intent.launch();
        debugPrint('백그라운드 전화 걸기 성공');
      }
    } catch (e) {
      debugPrint('백그라운드 전화 걸기 오류: $e');
    }
  }

  /// 앱을 포그라운드로 가져오기
  static Future<void> bringAppToForeground() async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('bringToForeground');
        debugPrint('앱을 포그라운드로 가져왔습니다.');
      }
    } catch (e) {
      debugPrint('앱을 포그라운드로 가져오기 실패: $e');
    }
  }

  /// 전화번호 포맷 검증
  static bool isValidPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll('-', '').replaceAll(' ', '');
    // 한국 전화번호 형식 검증 (010으로 시작하는 10-11자리 또는 02, 031 등 지역번호)
    final phoneRegex = RegExp(r'^(01[0-9]|02|0[3-9]{1}[0-9]{1})[0-9]{3,4}[0-9]{4}$');
    return phoneRegex.hasMatch(cleanNumber);
  }
}
