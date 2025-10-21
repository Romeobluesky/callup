import 'dart:async';
import 'package:flutter/material.dart';
import '../models/auto_call_state.dart';
import 'phone_service.dart';
import 'overlay_service.dart';

/// 자동 전화 서비스 (Singleton)
class AutoCallService {
  // Singleton 인스턴스
  static final AutoCallService _instance = AutoCallService._internal();
  factory AutoCallService() => _instance;
  AutoCallService._internal() {
    _initPhoneStateMonitoring();
  }

  // 상태
  bool isRunning = false;
  List<Map<String, dynamic>> customerQueue = [];
  int currentIndex = 0;
  Timer? _countdownTimer;
  Completer<CallResult>? _callCompleter;
  Map<String, dynamic>? _connectedCustomer;  // 통화 연결된 고객 저장

  // Stream 컨트롤러
  final _stateController = StreamController<AutoCallState>.broadcast();
  final _countdownController = StreamController<int>.broadcast();

  // Stream getter
  Stream<AutoCallState> get stateStream => _stateController.stream;
  Stream<int> get countdownStream => _countdownController.stream;

  // 통화 상태 모니터링
  StreamSubscription<Map<String, dynamic>>? _nativePhoneStateSubscription;

  /// 전화 상태 모니터링 초기화
  void _initPhoneStateMonitoring() {
    // 네이티브 TelephonyManager 기반 상태 스트림 (기본 + callDuration)
    _nativePhoneStateSubscription = PhoneService.nativePhoneStateStream.listen((Map<String, dynamic> data) {
      final state = data['state'] as String;
      final callDuration = data['callDuration'] as int;

      debugPrint('=== 네이티브 통화 상태: $state (통화시간: $callDuration초) ===');

      switch (state) {
        case 'RINGING':
          // 착신 전화 (발신 시에는 발생하지 않음)
          debugPrint('착신 전화 (RINGING)');
          break;

        case 'OFFHOOK':
          // OFFHOOK 발생 (전화 걸기 시작)
          debugPrint('OFFHOOK 감지 (전화 걸기 시작)');
          break;

        case 'IDLE':
          // 통화 종료됨 - Call Log에서 통화 시간 확인
          debugPrint('통화 종료됨 (IDLE) - 통화시간: $callDuration초');

          // 카운트다운 중에 통화가 종료되면
          if (_callCompleter != null && !_callCompleter!.isCompleted) {
            _countdownTimer?.cancel();

            if (callDuration > 0) {
              // 통화시간이 0초 이상 → 상대방이 받았음
              debugPrint('⭐⭐⭐ 통화 연결됨 (통화시간: $callDuration초) ⭐⭐⭐');
              _connectedCustomer = getCurrentCustomer();  // 통화 연결된 고객 저장
              _callCompleter!.complete(CallResult.connected);
            } else {
              // 통화시간 0초 → 무응답
              debugPrint('무응답 (통화시간: 0초) → 타임아웃 처리');
              _callCompleter!.complete(CallResult.timeout);
            }
          } else {
            // 카운트다운이 이미 완료된 후 통화 종료
            if (callDuration > 0 && _connectedCustomer != null) {
              // 통화 연결된 후 종료 → CallResultScreen으로 이동
              debugPrint('통화 종료 → CallResultScreen 전환 신호 발송');
              debugPrint('통화 종료된 고객: ${_connectedCustomer!['name']} (저장된 정보 사용)');
              _stateController.add(AutoCallState(
                status: AutoCallStatus.callEnded,
                customer: _connectedCustomer!,  // 저장된 연결 고객 정보 사용
                progress: '${currentIndex + 1}/${customerQueue.length}',
              ));
              _connectedCustomer = null;  // 사용 후 초기화
            } else {
              debugPrint('카운트다운 완료 후 무응답 종료 (이미 타임아웃 처리됨)');
            }
          }
          break;
      }
    });
  }

  /// 자동 전화 시작
  Future<void> start(List<Map<String, dynamic>> customers) async {
    debugPrint('=== 자동 전화 시작 ===');
    debugPrint('총 고객 수: ${customers.length}');

    customerQueue = customers;
    currentIndex = 0;
    isRunning = true;

    await _processNextCustomer();
  }

  /// 다음 고객 처리
  Future<void> _processNextCustomer() async {
    if (!isRunning) {
      debugPrint('자동 전화 중지됨 (END 버튼)');
      return;
    }

    if (currentIndex >= customerQueue.length) {
      debugPrint('전체 고객 처리 완료');
      _handleComplete();
      return;
    }

    final customer = customerQueue[currentIndex];
    final progress = '${currentIndex + 1}/${customerQueue.length}';

    debugPrint('=== 고객 ${currentIndex + 1} 처리 시작 ===');
    debugPrint('고객명: ${customer['name']}');
    debugPrint('전화번호: ${customer['phone']}');

    // 상태 업데이트: 발신 중
    _stateController.add(AutoCallState(
      status: AutoCallStatus.dialing,
      customer: customer,
      progress: progress,
    ));

    // 잠시 대기 (UI 업데이트 시간)
    await Future.delayed(const Duration(milliseconds: 500));

    // 응답 대기 상태로 변경 + 카운트다운 먼저 시작
    _stateController.add(AutoCallState(
      status: AutoCallStatus.ringing,
      customer: customer,
      progress: progress,
    ));

    // 3초 카운트다운 시작 (전화 걸기 전에!)
    final connectionFuture = _waitForConnection();

    // 카운트다운 시작 후 전화 걸기
    await Future.delayed(const Duration(milliseconds: 500));

    // 오버레이 표시
    await OverlayService.showOverlay(
      customerName: customer['name'] ?? '-',
      customerPhone: customer['phone'] ?? '-',
      progress: progress,
      status: '응답대기',
      countdown: 10,
    );

    PhoneService.makePhoneCallInBackground(customer['phone'] ?? '');

    // 카운트다운 완료 대기
    final result = await connectionFuture;

    // 오버레이 숨기기
    await OverlayService.hideOverlay();

    if (result == CallResult.connected) {
      debugPrint('통화 연결됨 → CallResultScreen 대기');

      // 통화 연결된 고객 정보 저장 (아직 저장 안 되어 있을 수 있음)
      if (_connectedCustomer == null) {
        _connectedCustomer = customer;
        debugPrint('통화 연결된 고객 저장: ${customer['name']}');
      }

      // 통화 연결 → CallResultScreen으로 이동
      _stateController.add(AutoCallState(
        status: AutoCallStatus.connected,
        customer: customer,
        progress: progress,
      ));
      // 여기서 대기, resumeAfterResult()로 재개됨
    } else if (result == CallResult.timeout) {
      debugPrint('10초 타임아웃 → 전화 강제 종료 후 부재중 저장');

      // 현재 통화 강제 종료
      await PhoneService.endCall();
      await Future.delayed(const Duration(milliseconds: 500)); // 통화 종료 대기

      // 부재중 자동 저장
      await _saveAutoResult(customer, '부재중');

      // 다음 고객으로
      currentIndex++;
      await _processNextCustomer();
    } else {
      // cancelled
      debugPrint('사용자가 중지함');
    }
  }

  /// 10초 대기 + 통화 연결 감지
  Future<CallResult> _waitForConnection() async {
    _callCompleter = Completer<CallResult>();
    int countdown = 10;

    debugPrint('10초 카운트다운 시작');

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isRunning) {
        // END 버튼으로 중지됨
        timer.cancel();
        if (!_callCompleter!.isCompleted) {
          _callCompleter!.complete(CallResult.cancelled);
        }
        return;
      }

      countdown--;
      _countdownController.add(countdown);
      debugPrint('카운트다운: $countdown초');

      if (countdown <= 0) {
        timer.cancel();
        debugPrint('10초 타임아웃 → 전화 강제 종료');

        if (!_callCompleter!.isCompleted) {
          _callCompleter!.complete(CallResult.timeout);
        }
      }
    });

    return _callCompleter!.future;
  }

  /// 통화 연결됨 처리 (외부에서 호출)
  void notifyConnected() {
    debugPrint('통화 연결 알림 받음');
    _countdownTimer?.cancel();

    // 통화 연결된 고객 정보 저장
    _connectedCustomer = getCurrentCustomer();

    if (_callCompleter != null && !_callCompleter!.isCompleted) {
      _callCompleter!.complete(CallResult.connected);
    }
  }

  /// 통화 결과 입력 후 재개
  Future<void> resumeAfterResult() async {
    debugPrint('=== 통화 결과 입력 완료, 다음 고객으로 진행 ===');

    if (!isRunning) {
      debugPrint('자동 전화가 중지된 상태');
      return;
    }

    currentIndex++;

    // 다음 고객 정보가 있으면 paused 상태로 전환 (AutoCallScreen에 다음 고객 표시)
    final nextCustomer = getCurrentCustomer();
    if (nextCustomer != null) {
      debugPrint('다음 고객 정보 표시 (일시정지 상태)');
      _stateController.add(AutoCallState(
        status: AutoCallStatus.paused,
        customer: nextCustomer,
        progress: '${currentIndex + 1}/${customerQueue.length}',
      ));
    } else {
      // 다음 고객이 없으면 완료
      _handleComplete();
    }
  }

  /// paused 상태에서 다음 고객으로 전화 재개
  Future<void> continueToNextCustomer() async {
    debugPrint('=== paused 상태에서 다음 고객으로 전화 재개 ===');

    if (!isRunning) {
      debugPrint('자동 전화가 중지된 상태');
      return;
    }

    // 현재 고객으로 전화 걸기
    await _processNextCustomer();
  }

  /// 자동 부재중 저장
  Future<void> _saveAutoResult(Map<String, dynamic> customer, String result) async {
    debugPrint('자동 저장: ${customer['name']} - $result');
    // TODO: CSV 업데이트 또는 DB 저장
    // 현재는 로그만 출력
  }

  /// 자동 전화 중지 (END 버튼)
  void stop() {
    debugPrint('=== 자동 전화 중지 ===');
    isRunning = false;
    _countdownTimer?.cancel();

    _stateController.add(AutoCallState(
      status: AutoCallStatus.idle,
    ));
  }

  /// 전체 완료
  void _handleComplete() {
    debugPrint('=== 전체 자동 전화 완료! ===');
    isRunning = false;
    _countdownTimer?.cancel();

    _stateController.add(AutoCallState(
      status: AutoCallStatus.completed,
      message: '전체 자동 전화 완료!',
    ));
  }

  /// 현재 고객 정보 가져오기
  Map<String, dynamic>? getCurrentCustomer() {
    if (currentIndex < customerQueue.length) {
      return customerQueue[currentIndex];
    }
    return null;
  }

  /// 다음 고객 정보 가져오기 (미리보기용)
  Map<String, dynamic>? getNextCustomer() {
    if (currentIndex + 1 < customerQueue.length) {
      return customerQueue[currentIndex + 1];
    }
    return null;
  }

  /// 리소스 정리
  void dispose() {
    _countdownTimer?.cancel();
    _nativePhoneStateSubscription?.cancel();
    _stateController.close();
    _countdownController.close();
  }
}

/// 통화 결과 enum
enum CallResult {
  connected,  // 통화 연결됨
  timeout,    // 타임아웃 (무응답)
  cancelled,  // 사용자 취소
}
