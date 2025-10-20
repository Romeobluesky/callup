import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phone_state/phone_state.dart';
import '../models/auto_call_state.dart';
import 'phone_service.dart';
// import 'overlay_service.dart'; // 임시 비활성화

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
  StreamSubscription<PhoneStateStatus>? _phoneStateSubscription;

  // Stream 컨트롤러
  final _stateController = StreamController<AutoCallState>.broadcast();
  final _countdownController = StreamController<int>.broadcast();

  // Stream getter
  Stream<AutoCallState> get stateStream => _stateController.stream;
  Stream<int> get countdownStream => _countdownController.stream;

  /// 전화 상태 모니터링 초기화
  void _initPhoneStateMonitoring() {
    _phoneStateSubscription = PhoneService.phoneStateStream.listen((PhoneStateStatus status) {
      debugPrint('=== 전화 상태 감지: $status ===');

      if (status == PhoneStateStatus.CALL_STARTED) {
        debugPrint('통화 연결됨!');
        notifyConnected();
      } else if (status == PhoneStateStatus.CALL_ENDED) {
        debugPrint('통화 종료됨');
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

    // 오버레이 표시 (임시 비활성화 - 테스트용)
    // await OverlayService.showOverlay(
    //   customerName: customer['name'] ?? '-',
    //   customerPhone: customer['phone'] ?? '-',
    //   progress: progress,
    //   status: '응답대기',
    //   countdown: 3,
    // );

    PhoneService.makePhoneCallInBackground(customer['phone'] ?? '');

    // 카운트다운 완료 대기
    final result = await connectionFuture;

    // 오버레이 숨기기 (임시 비활성화 - 테스트용)
    // await OverlayService.hideOverlay();

    if (result == CallResult.connected) {
      debugPrint('통화 연결됨 → CallResultScreen 대기');
      // 통화 연결 → CallResultScreen으로 이동
      _stateController.add(AutoCallState(
        status: AutoCallStatus.connected,
        customer: customer,
        progress: progress,
      ));
      // 여기서 대기, resumeAfterResult()로 재개됨
    } else if (result == CallResult.timeout) {
      debugPrint('타임아웃 → 부재중 자동 저장');
      // 타임아웃 → 부재중 자동 저장
      await _saveAutoResult(customer, '부재중');

      // 다음 고객으로
      currentIndex++;
      await _processNextCustomer();
    } else {
      // cancelled
      debugPrint('사용자가 중지함');
    }
  }

  /// 3초 대기 + 통화 연결 감지
  Future<CallResult> _waitForConnection() async {
    _callCompleter = Completer<CallResult>();
    int countdown = 3;

    debugPrint('3초 카운트다운 시작');

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

  /// 리소스 정리
  void dispose() {
    _countdownTimer?.cancel();
    _phoneStateSubscription?.cancel();
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
