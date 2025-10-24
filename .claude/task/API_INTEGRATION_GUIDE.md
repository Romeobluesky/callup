# CallUp Flutter 앱 API 연동 가이드

## 📌 개요

CallUp Flutter 앱과 백엔드 API 서버를 연동한 작업 내용을 정리한 문서입니다.

**작업 일자**: 2025-10-24
**API 서버**: `https://api.autocallup.com`
**프레임워크**: Flutter 3.8.1 + Dart 3.8.1

---

## 🎯 완료된 작업

### 완료 현황
- ✅ API 서비스 레이어 구축 (6개 서비스 클래스)
- ✅ JWT 토큰 관리 시스템
- ✅ 로그인 화면 API 연동
- ✅ 대시보드 화면 API 연동
- ✅ 자동 통화 화면 API 연동 (AutoCallScreen + CallResultScreen)

### 1단계: API 서비스 레이어 구축 ✅

#### 1.1 패키지 추가
```yaml
dependencies:
  http: ^1.2.0                    # HTTP 통신
  shared_preferences: ^2.2.2      # 로컬 저장소 (JWT 토큰)
```

#### 1.2 설정 파일
**[lib/config/api_config.dart](../lib/config/api_config.dart)**
- Base URL 및 12개 엔드포인트 정의
- 타임아웃 설정 (30초)
- 헤더 생성 함수

#### 1.3 유틸리티
**[lib/utils/token_manager.dart](../lib/utils/token_manager.dart)**
- JWT 토큰 저장/조회/삭제
- 사용자 정보 저장/조회
- 로그인 상태 확인

#### 1.4 API 서비스 클래스 (6개)

1. **[AuthApiService](../lib/services/api/auth_api_service.dart)** - 인증
   - `login()` - 로그인 및 JWT 토큰 저장
   - `logout()` - 토큰 삭제
   - `isLoggedIn()` - 로그인 상태 확인

2. **[DashboardApiService](../lib/services/api/dashboard_api_service.dart)** - 대시보드
   - `getDashboard()` - 대시보드 데이터 조회
   - `updateUserStatus()` - 사용자 상태 업데이트

3. **[AutoCallApiService](../lib/services/api/auto_call_api_service.dart)** - 자동 통화
   - `getNextCustomer()` - 다음 고객 조회
   - `saveCallLog()` - 통화 결과 등록

4. **[CustomerApiService](../lib/services/api/customer_api_service.dart)** - 고객 관리
   - `searchCustomers()` - 고객 검색
   - `getCustomerDetail()` - 고객 상세 조회

5. **[StatisticsApiService](../lib/services/api/statistics_api_service.dart)** - 통계
   - `getStatistics()` - 기간별 통계 조회

6. **[DbListApiService](../lib/services/api/db_list_api_service.dart)** - DB 리스트
   - `getDbLists()` - DB 리스트 조회
   - `getDbCustomers()` - DB별 고객 목록 조회

---

### 2단계: 화면별 API 연동 ✅

#### 2.1 로그인 화면 (SignUpScreen)
**파일**: [lib/screens/signup_screen.dart](../lib/screens/signup_screen.dart)

**변경 사항**:
- 입력 검증 추가 (모든 필드 필수)
- `AuthApiService.login()` 호출
- 로딩 인디케이터 표시 (`CircularProgressIndicator`)
- 에러 처리 및 사용자 피드백 (`SnackBar`)
- JWT 토큰 자동 저장

**주요 코드**:
```dart
Future<void> _handleSignIn() async {
  // 입력 검증
  if (_idController.text.trim().isEmpty || ...) {
    ScaffoldMessenger.of(context).showSnackBar(...);
    return;
  }

  setState(() {
    _isLoading = true;
  });

  // API 로그인 호출
  final result = await AuthApiService.login(
    userId: _idController.text.trim(),
    userName: _nameController.text.trim(),
    password: _passwordController.text.trim(),
  );

  if (result['success'] == true) {
    // 로그인 성공 - 대시보드로 이동
    Navigator.pushReplacement(...);
  } else {
    // 로그인 실패
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

#### 2.2 대시보드 화면 (DashboardScreen)
**파일**: [lib/screens/dashboard_screen.dart](../lib/screens/dashboard_screen.dart)

**변경 사항**:
- `initState()`에서 `getDashboard()` 자동 호출
- 로딩 상태 표시
- API 데이터로 UI 업데이트:
  - 상담원 정보 (이름, 전화번호, 상태 메시지, 활성 시간)
  - 오늘의 통계 (통화 건수, 통화 시간)
  - 통화 결과 (연결성공, 연결실패, 재연락)
  - DB 리스트 (최대 3개 표시)
- On/Off 토글 시 `updateUserStatus()` 호출
- JWT 토큰 만료 시 자동 로그아웃 → 로그인 화면 이동

**주요 코드**:
```dart
@override
void initState() {
  super.initState();
  _loadDashboardData();
}

Future<void> _loadDashboardData() async {
  final result = await DashboardApiService.getDashboard();

  if (result['success'] == true) {
    final data = result['data'];
    setState(() {
      _userName = data['user']['userName'] ?? '사용자';
      _userPhone = data['user']['phone'] ?? '000-0000-0000';
      _todayCallCount = data['todayStats']['callCount'] ?? 0;
      _todayCallDuration = data['todayStats']['callDuration'] ?? '00:00:00';
      _connectedCount = data['callResults']['connected'] ?? 0;
      _failedCount = data['callResults']['failed'] ?? 0;
      _callbackCount = data['callResults']['callback'] ?? 0;
      _dbLists = (data['dbLists'] as List).take(3).toList();
      _isLoading = false;
    });
  } else if (result['requireLogin'] == true) {
    // JWT 토큰 만료 → 로그인 화면으로
    Navigator.pushReplacement(...);
  }
}

Future<void> _toggleUserStatus() async {
  final newStatus = !_isOn;
  setState(() { _isOn = newStatus; });

  final result = await DashboardApiService.updateUserStatus(
    isActive: newStatus,
    statusMessage: _statusMessage,
  );

  if (result['success'] != true) {
    // 실패 시 원복
    setState(() { _isOn = !newStatus; });
  }
}
```

---

## 🔑 주요 기능

### JWT 토큰 관리
- 로그인 성공 시 자동 저장 (`SharedPreferences`)
- 모든 API 호출 시 `Authorization: Bearer <token>` 헤더 자동 추가
- 토큰 만료 시 자동 로그아웃 처리

### 에러 처리
- 네트워크 오류: `try-catch`로 예외 처리
- HTTP 상태 코드 확인: 200 (성공), 401 (인증 만료), 기타 (에러)
- 사용자 피드백: `SnackBar`로 에러 메시지 표시

### 로딩 상태 관리
- `_isLoading` 플래그로 로딩 상태 추적
- 로딩 중 `CircularProgressIndicator` 표시
- 버튼 비활성화로 중복 요청 방지

---

## 📊 API 응답 형식

### 성공 응답
```json
{
  "success": true,
  "message": "성공 메시지",
  "data": { ... }
}
```

### 에러 응답
```json
{
  "success": false,
  "message": "에러 메시지",
  "errorCode": "ERROR_CODE"
}
```

### 인증 만료
```json
{
  "success": false,
  "message": "로그인이 만료되었습니다.",
  "requireLogin": true
}
```

---

## 🧪 테스트 방법

### 1. 로그인 테스트
1. 앱 실행 → 로그인 화면
2. ID: `admin01`, NAME: `김상담`, PASSWORD: `password123` 입력
3. 화살표 버튼 클릭 → 로딩 인디케이터 표시
4. 로그인 성공 → 대시보드 화면 이동

### 2. 대시보드 테스트
1. 대시보드 화면 로드 → 로딩 인디케이터 표시
2. API 데이터 로드 완료 → 사용자 정보, 통계, DB 리스트 표시
3. On/Off 토글 클릭 → 상태 업데이트 API 호출
4. DB 리스트 아이템 클릭 → AutoCallScreen 이동

### 3. 에러 처리 테스트
1. 잘못된 로그인 정보 입력 → "로그인 실패" SnackBar 표시
2. 네트워크 연결 끊기 → "네트워크 오류" SnackBar 표시
3. JWT 토큰 삭제 후 대시보드 로드 → 로그인 화면으로 자동 이동

#### 2.3 자동 통화 화면 (AutoCallScreen + CallResultScreen)
**파일**:
- [lib/screens/auto_call_screen.dart](../lib/screens/auto_call_screen.dart)
- [lib/screens/call_result_screen.dart](../lib/screens/call_result_screen.dart)

**변경 사항**:
- CSV 로드 로직을 API 호출로 대체
- `getNextCustomer()` API로 고객 데이터 가져오기
- 고객 정보 필드명 변경 (API 응답 구조에 맞춤)
- CallResultScreen에서 `saveCallLog()` API 연동
- 통화 결과, 상담 결과, 메모, 예약 정보 저장

**주요 코드**:
```dart
// AutoCallScreen - 고객 데이터 로드
Future<void> _loadCustomers() async {
  final selectedDB = DBManager().selectedDB;
  final dbId = selectedDB['dbId'] ?? selectedDB['id'];

  // API에서 다음 고객 가져오기
  final result = await AutoCallApiService.getNextCustomer(dbId: dbId);

  if (result['success'] == true && result['customer'] != null) {
    final customer = result['customer'];
    setState(() {
      _customers = [{
        'customerId': customer['customerId'],
        'event': customer['eventName'] ?? '-',
        'phone': customer['phone'] ?? '-',
        'name': customer['name'] ?? '-',
        'info1': customer['customerInfo1'] ?? '-',
        'info2': customer['customerInfo2'] ?? '-',
        'info3': customer['customerInfo3'] ?? '-',
      }];
    });
  }
}

// CallResultScreen - 통화 결과 저장
Future<void> _saveCallResult() async {
  final customerId = widget.customer['customerId'];
  final dbId = widget.customer['dbId'];

  // 날짜/시간 포맷 변환
  String? formattedDate = _reservationDate != null
    ? '${_reservationDate!.year}-${_reservationDate!.month.toString().padLeft(2, '0')}-${_reservationDate!.day.toString().padLeft(2, '0')}'
    : null;

  String? formattedTime = _reservationTime != null
    ? '${_reservationTime!.hour.toString().padLeft(2, '0')}:${_reservationTime!.minute.toString().padLeft(2, '0')}:00'
    : null;

  // API 호출
  final result = await AutoCallApiService.saveCallLog(
    customerId: customerId,
    dbId: dbId,
    callResult: _callResult,
    consultationResult: _consultResult,
    memo: _memoController.text.trim(),
    callDuration: _formatCallDuration(widget.callDuration),
    reservationDate: formattedDate,
    reservationTime: formattedTime,
  );

  if (result['success'] == true) {
    // 자동 전화 재개
    if (AutoCallService().isRunning) {
      AutoCallService().resumeAfterResult();
    }
    Navigator.pop(context);
  }
}
```

**고객 정보 필드 매핑**:
| CSV/로컬 | API 응답 |
|---------|---------|
| event | eventName |
| phone | phone |
| name | name |
| info2 → info1 | customerInfo1 |
| info3 → info2 | customerInfo2 |
| info4 → info3 | customerInfo3 |

**에러 처리**:
- DB ID 없음 → SnackBar 알림
- API 실패 → 에러 메시지 표시
- JWT 만료 → 로그인 화면 이동 (TODO)

---

## 📝 다음 작업 (미완료)

### 화면별 API 연동 (남은 작업)
- [x] **AutoCallScreen** - 자동 통화 화면 ✅
  - `getNextCustomer()` 연동 완료
  - `saveCallLog()` 연동 완료 (CallResultScreen)

- [ ] **CustomerSearchScreen** - 고객 검색 화면
  - `searchCustomers()` 연동
  - `getCustomerDetail()` 연동

- [ ] **StatsScreen** - 통계 화면
  - `getStatistics()` 연동 (기간별: today/week/month/all)

- [ ] **DbListScreen** - DB 리스트 화면
  - `getDbLists()` 연동
  - `getDbCustomers()` 연동

### 추가 개선 사항
- [ ] 네트워크 연결 상태 감지
- [ ] 오프라인 모드 지원 (로컬 캐싱)
- [ ] API 재시도 로직 추가
- [ ] 에러 로그 기록
- [ ] 토큰 자동 갱신 (Refresh Token)

---

## 🔧 트러블슈팅

### 문제 1: "로그인이 만료되었습니다" 메시지 반복
**원인**: JWT 토큰이 만료되었거나 유효하지 않음
**해결**: 로그인 화면으로 이동하여 다시 로그인

### 문제 2: API 호출 타임아웃
**원인**: 네트워크 연결 불안정 또는 서버 응답 지연
**해결**:
- 네트워크 연결 확인
- 타임아웃 시간 증가 (`ApiConfig.connectionTimeout`)

### 문제 3: CORS 에러 (웹 환경)
**원인**: API 서버에서 CORS 설정이 되어 있지 않음
**해결**: 서버 측에서 CORS 허용 헤더 추가

---

## 📚 참고 문서

- [API 엔드포인트 명세](API_ENDPOINTS.md)
- [데이터베이스 스키마](../DATABASE_SCHEMA.md)
- [API 서버 사양서](../API_SERVER_SPEC.md)
- [배포 가이드](DEPLOYMENT.md)

---

**마지막 업데이트**: 2025-10-24
**작성자**: Claude Code
**버전**: 1.0.0
