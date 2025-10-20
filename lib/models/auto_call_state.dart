/// 자동 전화 상태 열거형
enum AutoCallStatus {
  idle,        // 대기 중
  dialing,     // 발신 중
  ringing,     // 응답 대기 (카운트다운)
  connected,   // 통화 연결됨
  completed,   // 전체 완료
}

/// 통화 결과 열거형
enum CallResult {
  connected,   // 통화 연결
  timeout,     // 10초 타임아웃
  cancelled,   // 사용자가 END 버튼 클릭
}

/// 자동 전화 상태 클래스
class AutoCallState {
  final AutoCallStatus status;
  final Map<String, dynamic>? customer;
  final String? progress;
  final String? message;

  AutoCallState({
    required this.status,
    this.customer,
    this.progress,
    this.message,
  });

  AutoCallState copyWith({
    AutoCallStatus? status,
    Map<String, dynamic>? customer,
    String? progress,
    String? message,
  }) {
    return AutoCallState(
      status: status ?? this.status,
      customer: customer ?? this.customer,
      progress: progress ?? this.progress,
      message: message ?? this.message,
    );
  }
}
