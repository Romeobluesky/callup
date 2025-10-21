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
  static final _fullPhoneStateController = StreamController<PhoneState>.broadcast();
  static final _nativeStateController = StreamController<Map<String, dynamic>>.broadcast(); // 네이티브 상태 전달
  static const platform = MethodChannel('com.callup.callup/foreground');
  static const phoneStatePlatform = MethodChannel('com.callup.callup/phone_state');

  // 중복 방지를 위한 이전 상태 저장
  static String? _lastNativeState;

  /// 전화 상태 스트림 (상태만)
  static Stream<PhoneStateStatus> get phoneStateStream => _phoneStateController.stream;

  /// 전체 전화 상태 스트림 (PhoneState 객체)
  static Stream<PhoneState> get fullPhoneStateStream => _fullPhoneStateController.stream;

  /// 네이티브 통화 상태 스트림 (IDLE, OFFHOOK, RINGING + callDuration)
  static Stream<Map<String, dynamic>> get nativePhoneStateStream => _nativeStateController.stream;

  /// 전화 권한 요청 (CALL_PHONE 권한)
  static Future<bool> requestPhonePermission() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  /// 네이티브 통화 상태 감지 시작 (TelephonyManager 사용)
  static Future<void> startNativePhoneStateMonitoring() async {
    try {
      // 네이티브 통화 상태 콜백 등록
      phoneStatePlatform.setMethodCallHandler((call) async {
        // 기본 통화 상태 (IDLE, OFFHOOK, RINGING)
        if (call.method == 'onCallStateChanged') {
          final state = call.arguments['state'] as String;
          final callDuration = call.arguments['callDuration'] as int?;
          debugPrint('=== 기본 통화 상태: $state (통화시간: ${callDuration ?? 0}초) ===');

          // 중복 상태 필터링 (IDLE은 통화시간 정보가 있으므로 중복 체크 안 함)
          if (state != 'IDLE' && _lastNativeState == state) {
            return;
          }
          _lastNativeState = state;

          // 네이티브 상태를 Map으로 전달
          _nativeStateController.add({
            'state': state,
            'callDuration': callDuration ?? 0,
          });
        }
        // PreciseCallState (DIALING, ALERTING, ACTIVE, DISCONNECTED)
        else if (call.method == 'onPreciseCallStateChanged') {
          final state = call.arguments['state'] as String;
          debugPrint('=== ⭐ PreciseCallState: $state ⭐ ===');

          // PreciseCallState를 네이티브 스트림으로 전달
          _nativeStateController.add({
            'state': 'PRECISE_$state',
            'callDuration': 0,
          });
        }
      });

      // 네이티브 모니터링 시작
      await phoneStatePlatform.invokeMethod('startMonitoring');
      debugPrint('네이티브 통화 상태 모니터링 시작');
    } catch (e) {
      debugPrint('네이티브 통화 상태 모니터링 오류: $e');
    }
  }

  /// 전화 상태 감지 시작 (기존 phone_state 패키지 - 사용 안 함)
  static Future<void> startPhoneStateMonitoring() async {
    // 네이티브 TelephonyManager 사용으로 대체됨
    await startNativePhoneStateMonitoring();
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

  /// 현재 통화 종료
  static Future<void> endCall() async {
    try {
      if (Platform.isAndroid) {
        // MethodChannel을 통해 네이티브 통화 종료 호출
        await platform.invokeMethod('endCall');
        debugPrint('통화 종료 요청 완료');
      }
    } catch (e) {
      debugPrint('통화 종료 오류: $e');
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
