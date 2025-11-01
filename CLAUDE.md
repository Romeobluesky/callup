# CallUp - Mobile Autocall Application

## 프로젝트 개요

**CallUp**은 모바일 자동 통화 시스템 애플리케이션입니다. 상담원이 고객 DB를 효율적으로 관리하고 자동으로 통화를 진행할 수 있도록 지원하는 Flutter 기반 Android 애플리케이션입니다.

### 핵심 기능
- 자동 통화 시스템 (Auto Call)
- 고객 DB 관리 및 검색
- 통화 통계 및 현황 분석
- 상담원 대시보드

### 배포 및 사용 환경

**중요: 권한 및 배포 정책**
- **배포 방식**: Google Play Store 배포 없이 APK 파일로 직접 배포
- **사용 환경**: 오토콜 전용 업무용 휴대폰에서만 사용 (개인 휴대폰 아님)
- **권한 정책**: 모든 필요 권한이 사전 허용된 환경에서 사용
- **개발 방향**: 제한된 권한을 사전에 고려할 필요 없음
  - SYSTEM_ALERT_WINDOW (오버레이)
  - CALL_PHONE (전화 걸기)
  - READ_PHONE_STATE (통화 상태 감지)
  - FOREGROUND_SERVICE (백그라운드 실행)
  - 기타 필요한 모든 시스템 권한

이 정책에 따라 개발 시 권한 요청 UX, 권한 거부 처리, 대체 기능 등을 고려하지 않고 핵심 기능 구현에 집중할 수 있습니다.

## 기술 스택

### 프레임워크 & 언어
- **Flutter SDK**: ^3.8.1
- **Dart**: ^3.8.1
- **Material Design 3**: 최신 디자인 시스템

### 주요 의존성
```yaml
dependencies:
  flutter: sdk
  flutter_localizations: sdk  # 한글 지원
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test: sdk
  flutter_lints: ^5.0.0
```

### 지원 언어
- 한국어 (ko_KR) - 기본 로케일
- 영어 (en_US)

## 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점
├── screens/                           # 화면 컴포넌트
│   ├── signup_screen.dart            # 로그인/회원가입
│   ├── dashboard_screen.dart         # 메인 대시보드
│   ├── db_list_screen.dart          # DB 리스트 관리
│   ├── auto_call_screen.dart        # 자동 통화 화면
│   ├── customer_search_screen.dart  # 고객 검색/관리
│   ├── stats_screen.dart            # 통계 현황
│   ├── call_screen.dart             # 통화 화면
│   └── call_result_screen.dart      # 통화 결과
├── widgets/                          # 재사용 위젯
│   ├── custom_bottom_navigation_bar.dart  # 커스텀 네비게이션
│   └── customer_detail_popup.dart         # 고객 상세 팝업
└── assets/                           # 리소스
    ├── icons/                        # 아이콘 이미지
    └── images/                       # 이미지 리소스
```

## 주요 화면 및 기능

### 1. 로그인 화면 (SignUpScreen)
**파일**: `lib/screens/signup_screen.dart`

**기능**:
- ID, 이름, 비밀번호 입력
- 로그인 상태 유지 옵션
- 대시보드로 자동 전환 (200ms fade+slide 애니메이션)

**디자인 특징**:
- 베이지색 배경 (#F9F8EB)
- 레드 그라디언트 원형 장식 요소
- Material Design 3 기반 UI

**주요 컴포넌트**:
```dart
- TextEditingController: _idController, _nameController, _passwordController
- 로그인 상태 유지: _rememberMe (bool)
- 커스텀 입력 필드: _buildInputField()
```

---

### 2. 대시보드 (DashboardScreen)
**파일**: `lib/screens/dashboard_screen.dart`

**기능**:
- 상담원 정보 표시 (이름, 전화번호, 상태 메시지)
- On/Off 토글 스위치
- 오늘의 통화 통계 요약
- 통화 상태별 통계 (연결성공, 연결실패, 재연락)
- DB 리스트 미리보기 (최근 3개)
- START 버튼 (통화 시작)

**디자인 특징**:
- 다크 그레이 배경 (#585667)
- 반투명 카드 (alpha: 0.3)
- 그림자 효과로 깊이감 표현
- 핑크 계열 강조 색상 (#FF0756, #FFCDDD)

**주요 컴포넌트**:
```dart
- 상담원 카드: _buildConsultantCard()
- 통계 카드: _buildTodayStatsCard(), _buildStatisticsRow()
- 리스트 카드: _buildListCard()
- START 버튼: _buildStartButton()
```

**네비게이션**:
- 하단 네비게이션 바 → Auto Call, 고객관리, 통계 페이지 이동
- 리스트 더보기 → DB 리스트 페이지 이동

---

### 3. DB 리스트 화면 (DbListScreen)
**파일**: `lib/screens/db_list_screen.dart`

**기능**:
- 전체 DB 리스트 조회
- 검색 기능 (제목 검색)
- DB 정보 표시: 날짜, 제목, 총갯수/미사용
- On/Off 토글 스위치
- START 버튼

**데이터 구조**:
```dart
{
  'date': '2025-10-14',
  'title': '이벤트01_251014',
  'total': 500,
  'unused': 250,
}
```

**주요 컴포넌트**:
```dart
- 검색 바: _buildSearchBar()
- DB 리스트: _buildDbList()
- 리스트 아이템: _buildListItem()
```

---

### 4. 자동 통화 화면 (AutoCallScreen)
**파일**: `lib/screens/auto_call_screen.dart`

**기능**:
- START/END 버튼 (자동 통화 시작/중지)
- AUTO 모드 vs 대기중 상태 표시
- 현재 통화 중인 고객 정보 표시
  - DB 정보 (500/120)
  - 제목
  - 전화번호, 고객정보1-4
- 통화 상태 표시 (발신중, 응답대기)
- 180도 회전 애니메이션 아이콘 (pass 아이콘)

**애니메이션**:
```dart
AnimationController: 2초 주기로 180도 회전 반복
CurvedAnimation: easeInOut 곡선
```

**고객 정보 테이블**:
```dart
customerData: [
  {'label': '전화번호', 'value': '010-1234-5678'},
  {'label': '고객정보1', 'value': '홍길동'},
  {'label': '고객정보2', 'value': '인천 부평구'},
  {'label': '고객정보3', 'value': '쿠팡 이벤트'},
  {'label': '고객정보4', 'value': ''},
]
```

---

### 5. 고객 검색 화면 (CustomerSearchScreen)
**파일**: `lib/screens/customer_search_screen.dart`

**기능**:
- 고객명, 전화번호, 제목, 통화결과 검색
- 고객 리스트 표시
  - 날짜, 이벤트명
  - 고객명, 전화번호
  - 통화 상태, 통화 일시/시간
  - 고객 유형, 메모
  - 통화 녹음 여부 (오디오 아이콘)
- 고객 카드 클릭 → 상세 팝업

**데이터 구조**:
```dart
{
  'date': '2025-10-01',
  'event': '이벤트01_경기인천',
  'name': '김숙자',
  'phone': '010-1234-5687',
  'callStatus': '통화성공',
  'callDateTime': '2025-10-15  15:25:00',
  'callDuration': '00:11:24',
  'customerType': '가망고객',
  'memo': '다음주에 다시 통화하기로함',
  'hasAudio': true,
}
```

**통화 상태 종류**:
- 통화성공
- 부재중
- 미사용

---

### 6. 통계 현황 화면 (StatsScreen)
**파일**: `lib/screens/stats_screen.dart`

**기능**:
- 상담원 정보 (이름, ID)
- 기간 선택 (오늘, 이번주, 이번달, 전체)
- 통계 데이터 표시:
  - 통화시간, 통화건수
  - 통화성공, 통화실패
  - 가망고객, 재통화, 무응답
  - 분배DB, 미사용DB

**기간 선택 UI**:
- 4개 버튼 (오늘, 이번주, 이번달, 전체)
- 선택된 항목 배경색 변경 (#FF0756)

**통계 테이블**:
```dart
stats: [
  {'label': '통화시간', 'value': '15:02:45'},
  {'label': '통화건수', 'value': '250'},
  {'label': '통화성공', 'value': '120'},
  ...
]
```

---

### 7. 커스텀 하단 네비게이션 바
**파일**: `lib/widgets/custom_bottom_navigation_bar.dart`

**기능**:
- 4개 탭: Home, 오토콜, 고객, 현황
- 노치(notch) 디자인 (선택된 아이템 강조)
- 커스텀 페인터로 복잡한 곡선 구현

**디자인 특징**:
- 선택된 아이템: 위로 올라가는 애니메이션 + 원형 배경
- 노치 효과: 선택된 아이템 위치에 오목한 곡선 생성
- 라운드 모서리 (radius: 40px)

**네비게이션 구조**:
```dart
[
  {'index': 0, 'icon': Icons.home, 'label': 'Home'},
  {'index': 1, 'icon': Icons.phone_in_talk, 'label': '오토콜'},
  {'index': 2, 'icon': Icons.person, 'label': '고객'},
  {'index': 3, 'icon': Icons.graphic_eq, 'label': '현황'},
]
```

---

## 디자인 시스템

### 색상 팔레트
```dart
// Primary Colors
Color(0xFF524C8A)  // 메인 퍼플 (시드 컬러)
Color(0xFFFF0756)  // 메인 레드 (강조색)
Color(0xFFFFCDDD)  // 라이트 핑크 (서브 강조)

// Background Colors
Color(0xFFF9F8EB)  // 베이지 (밝은 배경)
Color(0xFF585667)  // 다크 그레이 (어두운 배경)
Color(0xFF383743)  // 더 어두운 그레이

// Neutral Colors
Colors.white       // 흰색 (텍스트, 카드)
Colors.black       // 검정 (그림자)
```

### 타이포그래피
```dart
// 로고
fontSize: 42, fontWeight: bold, color: white

// 헤더
fontSize: 14-16, fontWeight: bold

// 본문
fontSize: 12-14, fontWeight: bold
letterSpacing: -0.15

// 버튼
fontSize: 16-20, fontWeight: bold
letterSpacing: 0.8
```

### 컴포넌트 스타일
```dart
// 카드
backgroundColor: white.withValues(alpha: 0.3)
borderRadius: 5px
boxShadow: [
  offset: (0, 4)
  blurRadius: 4
  color: black.withValues(alpha: 0.25)
]

// 버튼
borderRadius: 8px
padding: symmetric(horizontal: 9, vertical: 10)

// 토글 스위치
borderRadius: 360px
animationDuration: 200ms
```

---

## 애니메이션 및 전환 효과

### 페이지 전환
```dart
PageRouteBuilder(
  transitionDuration: Duration(milliseconds: 200),
  transitionsBuilder: (context, animation, _, child) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0.1, 0.0),  // 또는 (-0.1, 0.0)
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  },
)
```

### 토글 스위치 애니메이션
```dart
AnimatedAlign(
  alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
  duration: Duration(milliseconds: 200),
  child: Container(...),
)
```

### 회전 애니메이션 (Auto Call)
```dart
AnimationController(
  duration: Duration(seconds: 2),
  vsync: this,
)..repeat();

Tween<double>(begin: 0, end: 3.14159).animate(
  CurvedAnimation(
    parent: animationController,
    curve: Interval(0.0, 0.5, curve: Curves.easeInOut),
  ),
)
```

---

## 상태 관리

### 현재 구현
- **StatefulWidget** 기반
- 로컬 상태 관리 (_isOn, _selectedIndex, _searchController 등)
- 샘플 데이터 하드코딩

### 향후 개선 방안
- [ ] Provider/Riverpod 도입 (전역 상태 관리)
- [ ] API 연동 (백엔드 통신)
- [ ] 로컬 데이터베이스 (SQLite, Hive)
- [ ] 통화 기능 연동 (Android Native Call API)

---

## 주요 기술적 특징

### 1. 커스텀 디자인
- Material Design 3 기반이지만 완전히 커스터마이징된 UI
- CustomPainter를 활용한 복잡한 곡선 구현
- 독창적인 노치 디자인 네비게이션 바

### 2. 애니메이션 최적화
- 200ms의 빠른 전환 효과
- Cubic 곡선으로 자연스러운 움직임
- SingleTickerProviderStateMixin으로 효율적인 애니메이션 관리

### 3. 반응형 디자인
- MediaQuery로 화면 크기에 따른 동적 레이아웃
- 비율 기반 크기 계산 (screenWidth * 0.9)
- 고정폭과 Expanded를 적절히 혼용

### 4. 다국어 지원
- flutter_localizations로 한글 지원
- GlobalMaterialLocalizations 활성화
- 추가 언어 확장 가능한 구조

---

## 개발 가이드

### 환경 설정
```bash
# Flutter 버전 확인
flutter --version  # 3.8.1 이상

# 의존성 설치
flutter pub get

# 앱 실행
flutter run

# 빌드
flutter build apk --release
```

### 코드 스타일
- **린트 규칙**: flutter_lints ^5.0.0 사용
- **네이밍**: camelCase (변수, 함수), PascalCase (클래스)
- **상태**: private 변수는 언더스코어(_) 시작
- **주석**: 한글 주석 사용

### 주요 개발 패턴
```dart
// 1. 위젯 분리 (메서드로 추출)
Widget _buildHeader() { ... }
Widget _buildCustomerCard() { ... }

// 2. const 생성자 활용 (성능 최적화)
const SizedBox(height: 20)
const Text('Label')

// 3. 리소스 정리 (메모리 누수 방지)
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}

// 4. 애니메이션 컨트롤러 관리
class _StateClass extends State<Widget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(...);
  }
}
```

---

## 알려진 이슈 및 개선 사항

### 현재 제한사항
1. **인증 없음**: 로그인 검증 로직 미구현 (임시로 모든 입력 허용)
2. **하드코딩 데이터**: 모든 데이터가 샘플 데이터
3. **API 미연동**: 백엔드 서버 없음
4. **통화 기능 없음**: 실제 전화 걸기 기능 미구현
5. **검색 기능 미완성**: UI만 있고 실제 필터링 로직 없음

### 향후 개발 계획
- [ ] 백엔드 API 개발 및 연동
- [ ] 실제 통화 기능 구현 (Android Phone API)
- [ ] 인증 시스템 (JWT, OAuth)
- [ ] 데이터베이스 연동 (로컬 + 원격)
- [ ] 푸시 알림 (Firebase Cloud Messaging)
- [ ] 통화 녹음 및 재생 기능
- [ ] 엑셀 내보내기/가져오기
- [ ] 권한 관리 (상담원/관리자)

---

## 파일별 주요 로직

### main.dart
- MaterialApp 설정
- 한글 로케일 지정
- 테마 설정 (seedColor: #524C8A)
- 초기 라우트: SignUpScreen

### signup_screen.dart
- 3개 입력 필드 (ID, NAME, PASSWORD)
- 로그인 상태 유지 체크박스
- 화살표 버튼으로 로그인 (유효성 검사 없음)

### dashboard_screen.dart
- 5개 주요 섹션:
  1. 헤더 (로고 + 설정 아이콘)
  2. 상담원 카드 (정보 + on/off 토글)
  3. 오늘 통계 카드
  4. 3개 통계 카드 (연결성공/실패/재연락)
  5. DB 리스트 미리보기 (최대 3개)

### db_list_screen.dart
- 검색 바 + DB 리스트
- 헤더에 뒤로가기 버튼
- CustomBottomNavigationBar 통합

### auto_call_screen.dart
- START/END 토글 버튼
- AUTO 모드 표시
- 고객 정보 테이블 (5행)
- 통화 상태 표시 + 회전 애니메이션

### customer_search_screen.dart
- 검색 바 (고객명, 전화번호, 제목, 통화결과)
- ListView로 고객 카드 리스트
- 카드 클릭 → CustomerDetailPopup 표시

### stats_screen.dart
- 상담원 정보 테이블
- 기간 선택 (4개 버튼)
- 9개 통계 항목 테이블

### custom_bottom_navigation_bar.dart
- CustomPainter로 노치 곡선 구현
- 4개 아이콘 + 라벨
- 선택된 항목: 원형 배경 + 위로 이동
- 노치 위치 동적 계산

---

## 프로젝트 히스토리

### 최근 커밋
```
c2d63b4  autocall
d7bfb7f  main
e77343c  flutter 초기 세팅
d23bbe1  Initial commit
```

### 현재 브랜치
- **main**: 메인 브랜치

### Git 상태
- Working directory: clean (변경사항 없음)

---

## 참고 자료

### Flutter 공식 문서
- [Flutter Documentation](https://docs.flutter.dev)
- [Material Design 3](https://m3.material.io)
- [CustomPainter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)

### 관련 패키지
- [flutter_localizations](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [cupertino_icons](https://pub.dev/packages/cupertino_icons)

---

## 라이선스
Private (publish_to: 'none')

---

## 연락처
프로젝트 관련 문의: [프로젝트 저장소]

---

## 개발 일지

### 2025-10-20 - 네이티브 Android 오버레이 시스템 구현

#### 작업 목표
전화 앱으로 전환될 때에도 오토콜 진행 상황을 확인할 수 있도록 네이티브 Android 오버레이 시스템 구현

#### 구현 내용

**1. 네이티브 Android 오버레이 시스템 (임시 비활성화)**

구현한 파일:
- `android/app/src/main/kotlin/com/callup/callup/OverlayService.kt` - Foreground Service로 오버레이 생명주기 관리
- `android/app/src/main/kotlin/com/callup/callup/OverlayView.kt` - 전화 앱 위에 표시되는 네이티브 View
- `lib/services/overlay_service.dart` - Flutter-Native 브릿지
- `android/app/src/main/kotlin/com/callup/callup/MainActivity.kt` - MethodChannel 핸들러 추가

오버레이 UI 구성:
- 고객명, 전화번호 표시
- DB 진행상황 (예: 15/500)
- 응답대기 상태 표시
- 3초 카운트다운 타이머
- "통화 연결됨" 버튼 (녹색)
- "다음" 버튼 (빨간색)

권한 및 서비스 등록 (`AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_PHONE_CALL"/>

<service
    android:name=".OverlayService"
    android:exported="false"
    android:foregroundServiceType="phoneCall" />
```

**2. 오버레이 크래시 문제 발견 및 임시 비활성화**

문제:
- START 버튼 클릭 시 오버레이 권한 요청 후 앱 크래시 발생
- "callup 계속 중단됨" 팝업 발생

임시 조치:
- `lib/services/auto_call_service.dart`에서 오버레이 호출 주석 처리
- 기본 통화 기능 우선 안정화

**3. 기본 자동 통화 기능 테스트**

현재 작동 상태:
- ✅ START 버튼 클릭 → 전화 걸기 성공
- ✅ 통화 종료 감지 → 결과 입력 페이지 이동 정상 작동
- ✅ 앱 크래시 없이 안정적으로 작동
- ❌ 3초 타임아웃 미작동 → 무응답 시 다음 고객으로 자동 진행 안 됨

#### 발견된 문제

**1. 3초 타임아웃 미작동**
- 증상: 무응답 고객에게 전화 걸었을 때 3초 후 자동으로 다음 고객으로 넘어가지 않음
- 원인: 전화 앱으로 전환 시 백그라운드에서 타이머가 중단되는 것으로 추정
- 영향: 무응답 고객 처리 자동화 불가

**2. 오버레이 시스템 크래시**
- 증상: 오버레이 권한 요청 후 앱이 계속 중단됨
- 원인: 권한 처리 또는 OverlayService 초기화 과정에서 문제 발생 추정
- 조치: 임시로 오버레이 기능 비활성화하고 기본 통화 기능 우선 안정화

#### 기술적 세부사항

**오버레이 구현 방식**:
- WindowManager를 사용한 TYPE_APPLICATION_OVERLAY
- Foreground Service로 백그라운드 실행 보장
- MethodChannel을 통한 Flutter-Kotlin 통신

**권한 처리**:
- SYSTEM_ALERT_WINDOW 권한 요청 및 확인
- Settings 화면으로 이동하여 수동 권한 허용
- 권한 미허용 시 SnackBar로 안내

**타이머 구현**:
- `AutoCallService`에서 3초 카운트다운 Timer 구현
- PhoneState 모니터링으로 통화 연결 감지
- 타임아웃 시 자동으로 다음 고객으로 진행 (현재 미작동)

#### 다음 작업 계획

**우선순위 1: 3초 타임아웃 수정**
- [ ] 백그라운드에서도 타이머가 작동하도록 수정
- [ ] WakeLock 활용하여 앱이 백그라운드에서도 활성 상태 유지
- [ ] 전화 앱 전환 후에도 카운트다운 지속 보장

**우선순위 2: 오버레이 크래시 디버깅**
- [ ] Android Logcat으로 정확한 크래시 원인 파악
- [ ] OverlayService 초기화 로직 점검
- [ ] 권한 처리 플로우 개선
- [ ] 오버레이 View 생성 시 예외 처리 강화

**우선순위 3: 오버레이 기능 재활성화**
- [ ] 크래시 문제 해결 후 오버레이 기능 복구
- [ ] 전화 앱 위에 고객 정보 표시 정상 작동 확인
- [ ] 3초 카운트다운 UI와 자동 진행 기능 통합 테스트

#### 빌드 정보

**현재 APK**:
- 위치: `build/app/outputs/flutter-apk/app-release.apk`
- 크기: 22.3MB
- 상태: 오버레이 비활성화, 기본 통화 기능만 작동
- 테스트 결과: 전화 걸기 및 통화 종료 감지 정상 작동

#### 추가 의존성

새로 추가된 패키지:
```yaml
dependencies:
  csv: ^6.0.0                      # CSV 파일 처리
  charset_converter: ^2.1.1        # EUC-KR 인코딩 지원
  url_launcher: ^6.3.1             # 전화 걸기
  permission_handler: ^11.3.1      # 권한 관리
  android_intent_plus: ^5.1.0      # Android Intent
  phone_state: ^2.1.1              # 통화 상태 감지
  wakelock_plus: ^1.2.8           # 백그라운드 유지 (추가됨, 미사용)
```

---

### 2025-10-21 - 오버레이 시스템 권한 로직 제거 및 네이티브 타이머 구현

#### 작업 목표
업무용 휴대폰 환경에 맞춰 권한 요청 로직 제거 및 오버레이 시스템 안정화

#### 구현 내용

**1. 권한 요청 로직 완전 제거**

제거된 파일 및 코드:
- `lib/screens/auto_call_screen.dart`: 오버레이 권한 확인/요청 로직 삭제 (244-273줄)
- `lib/services/overlay_service.dart`: `requestOverlayPermission()`, `checkOverlayPermission()` 메서드 삭제
- `android/app/src/main/kotlin/com/callup/callup/MainActivity.kt`: 권한 체크 MethodChannel 핸들러 삭제

이유:
- 업무용 휴대폰 환경에서 모든 권한 사전 허용됨
- APK 직접 배포로 Play Store 정책 무관
- 권한 요청 로직이 오히려 크래시 원인이었을 가능성

**2. Flutter ↔ Native 양방향 통신 구현**

MainActivity.kt 수정:
```kotlin
companion object {
    var instance: MainActivity? = null
    var overlayChannel: MethodChannel? = null
}

// overlayChannel을 static으로 관리하여 OverlayView에서 접근 가능
```

OverlayView.kt 콜백 구현:
```kotlin
// "통화 연결됨" 버튼 클릭
MainActivity.overlayChannel?.invokeMethod("onCallConnected", null)

// "다음" 버튼 클릭 또는 3초 타임아웃
MainActivity.overlayChannel?.invokeMethod("onTimeout", null)
```

overlay_service.dart 핸들러 추가:
```dart
static void setupCallbackHandler() {
  _channel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'onCallConnected':
        AutoCallService().notifyConnected();
        break;
      case 'onTimeout':
        // 타임아웃 처리
        break;
    }
  });
}
```

main.dart 초기화:
```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  OverlayService.setupCallbackHandler(); // 콜백 핸들러 설정
  runApp(const MyApp());
}
```

**3. AutoCallService 오버레이 연동 활성화**

재활성화된 코드:
```dart
// 오버레이 표시 (103-109줄)
await OverlayService.showOverlay(
  customerName: customer['name'] ?? '-',
  customerPhone: customer['phone'] ?? '-',
  progress: progress,
  status: '응답대기',
  countdown: 3,
);

// 오버레이 숨기기 (117줄)
await OverlayService.hideOverlay();
```

**4. 네이티브 타이머 작동 원리**

전화 앱 전환 시에도 작동하는 이유:
```
1. Flutter 앱에서 OverlayService.showOverlay() 호출
2. → MainActivity에서 OverlayService (Foreground Service) 시작
3. → OverlayView가 전화 앱 위에 TYPE_APPLICATION_OVERLAY로 표시
4. → OverlayView.startCountdown()에서 Handler.postDelayed()로 1초마다 카운트다운
5. → Foreground Service이므로 앱이 백그라운드여도 계속 실행
6. → 3초 후 MainActivity.overlayChannel.invokeMethod("onTimeout") 호출
7. → Flutter의 AutoCallService.notifyConnected() 또는 타임아웃 처리
```

핵심:
- **Foreground Service**: 백그라운드에서도 중단되지 않음
- **TYPE_APPLICATION_OVERLAY**: 전화 앱 위에 항상 표시
- **Handler.postDelayed()**: 네이티브 안드로이드 타이머로 Flutter 타이머보다 안정적
- **MethodChannel 양방향 통신**: Native → Flutter 콜백 가능

#### 기술적 개선사항

**권한 처리 간소화**:
- Before: 권한 확인 → 요청 → 재확인 → SnackBar → 설정 이동
- After: AndroidManifest.xml 선언만으로 모든 권한 자동 허용

**오버레이 안정성**:
- Foreground Service로 생명주기 보장
- 예외 처리 강화 (try-catch)
- WindowManager 파라미터 최적화

**타이머 안정성**:
- Flutter Timer (불안정) → Android Handler (안정적)
- 전화 앱 전환 시에도 지속 작동
- 정확한 1초 간격 보장

#### 예상되는 개선 효과

1. ✅ 오버레이 크래시 해결 (권한 로직 제거)
2. ✅ 3초 타임아웃 정상 작동 (네이티브 타이머)
3. ✅ 전화 앱 전환 시에도 고객 정보 표시 (오버레이)
4. ✅ 자동으로 다음 고객 진행 (타임아웃 콜백)
5. ✅ 수동 통화 연결 확인 (버튼 콜백)

#### 다음 테스트 항목

- [ ] START 버튼 클릭 → 오버레이 표시 확인
- [ ] 전화 걸기 → 오버레이가 전화 앱 위에 표시되는지 확인
- [ ] 3초 카운트다운 정상 작동 확인
- [ ] 타임아웃 시 자동으로 다음 고객 진행 확인
- [ ] "통화 연결됨" 버튼 → CallResultScreen 이동 확인
- [ ] "다음" 버튼 → 다음 고객 진행 확인

---

### 2025-10-21 - 일시정지 후 다음 고객 정보 표시 및 통화 재개 기능 구현

#### 작업 목표
통화 결과 등록 후 AutoCallScreen으로 복귀했을 때 다음 고객 정보를 미리 표시하고, START 버튼으로 재개할 수 있도록 구현

#### 구현 내용

**1. 새로운 상태 추가: `AutoCallStatus.paused`**

파일: `lib/models/auto_call_state.dart`
```dart
enum AutoCallStatus {
  idle,        // 대기 중
  dialing,     // 발신 중
  ringing,     // 응답 대기 (카운트다운)
  connected,   // 통화 연결됨 (오토콜 일시정지)
  callEnded,   // 통화 종료됨 (결과 입력 페이지로 이동)
  paused,      // 결과 등록 후 일시정지 (다음 고객 대기) ← NEW
  completed,   // 전체 완료
}
```

**2. AutoCallService 수정**

파일: `lib/services/auto_call_service.dart`

- `resumeAfterResult()` 수정: 결과 등록 후 `paused` 상태로 전환하고 다음 고객 정보 전달
- `continueToNextCustomer()` 추가: 일시정지 상태에서 다음 고객으로 전화 재개

```dart
Future<void> resumeAfterResult() async {
  currentIndex++;

  final nextCustomer = getCurrentCustomer();
  if (nextCustomer != null) {
    _stateController.add(AutoCallState(
      status: AutoCallStatus.paused,  // 일시정지 상태
      customer: nextCustomer,         // 다음 고객 정보
      progress: '${currentIndex + 1}/${customerQueue.length}',
    ));
  } else {
    _handleComplete();
  }
}

Future<void> continueToNextCustomer() async {
  await _processNextCustomer();  // 다음 고객으로 전화 시작
}
```

**3. AutoCallScreen 수정**

파일: `lib/screens/auto_call_screen.dart`

- `_isPaused` 상태 변수 추가
- `AutoCallStatus.paused` 핸들러 추가
- START 버튼 로직 수정: 일시정지 상태에서는 `continueToNextCustomer()` 호출

```dart
// 상태 리스너
case AutoCallStatus.paused:
  _callStatus = '대기중';
  _currentCustomer = state.customer;  // 다음 고객 정보
  _progress = state.progress ?? '0/0';
  _isAutoRunning = true;
  _isPaused = true;  // 일시정지 상태
  break;

// START 버튼
Widget _buildStartButton(double cardWidth) {
  return GestureDetector(
    onTap: () async {
      if (_isPaused) {
        // 일시정지 상태 → 다음 고객으로 전화 재개
        await AutoCallService().continueToNextCustomer();
      } else if (!_isAutoRunning) {
        // 초기 시작
        await _startAutoCalling();
      } else {
        // 중지
        _stopAutoCalling();
      }
    },
    // 일시정지 상태에서도 START 버튼 표시 (빨간색)
    child: Container(
      color: _isPaused ? Color(0xFFFF0756) : ...,
      child: Text(_isPaused ? 'START' : ...),
    ),
  );
}
```

**4. CallResultScreen 네비게이션 수정**

파일: `lib/screens/call_result_screen.dart`

- '등록' 버튼: `resumeAfterResult()` 호출 후 `Navigator.pop()`
- 오토콜 탭 클릭: 항상 AutoCallScreen 시작 페이지로 이동

#### 동작 흐름

1. **고객 1 통화 완료** → 결과 등록
2. **AutoCallScreen 복귀** → `AutoCallStatus.paused` 상태
   - 화면: 고객 2 정보 표시
   - 상태: "대기중"
   - 버튼: "START" (빨간색)
3. **START 버튼 클릭** → `continueToNextCustomer()` 호출
4. **고객 2 전화 시작** → `AutoCallStatus.dialing`

#### 발견된 문제 및 해결

**문제 1: 통화 종료 후 잘못된 고객 정보 표시**

증상:
- 1번 통화 → 2/3/4번 부재중 → 5번 통화 종료 시 **3번 고객 정보가 표시**

원인:
- 타이밍 이슈: 무응답으로 다음 고객으로 넘어갈 때 `currentIndex` 증가
- 이전 고객의 통화 종료 IDLE 이벤트가 늦게 도착
- `getCurrentCustomer()`가 이미 변경된 `currentIndex`로 잘못된 고객 반환

해결:
- `_connectedCustomer` 변수 추가하여 통화 연결 시 고객 정보 저장
- `callEnded` 발생 시 저장된 고객 정보 사용

```dart
// Line 24
Map<String, dynamic>? _connectedCustomer;

// Line 68: 카운트다운 중 통화 연결
_connectedCustomer = getCurrentCustomer();

// Line 172-175: 카운트다운 완료 후 통화 연결
if (_connectedCustomer == null) {
  _connectedCustomer = customer;
}

// Line 236: 오버레이 버튼 클릭
_connectedCustomer = getCurrentCustomer();

// Line 77-86: 통화 종료 시 저장된 정보 사용
if (callDuration > 0 && _connectedCustomer != null) {
  _stateController.add(AutoCallState(
    status: AutoCallStatus.callEnded,
    customer: _connectedCustomer!,
  ));
  _connectedCustomer = null;
}
```

**문제 2: 통화 종료 후 결과 입력 페이지로 이동하지 않음**

증상:
- 통화 완료 → 오토콜 시작 페이지로 이동 (결과 입력 페이지 아님)

원인:
- `notifyConnected()` 메서드에서 `_connectedCustomer` 미저장
- `callEnded` 조건 `_connectedCustomer != null` 불만족

해결:
- `notifyConnected()` 메서드에 `_connectedCustomer` 저장 로직 추가 (Line 236)
- 카운트다운 완료 후 통화 연결 시에도 저장 (Line 172-175)

#### 최종 구현 상태

**통화 연결된 고객 정보 저장 경로 (3가지)**:
1. 카운트다운 중 자동 감지 (Line 68)
2. 카운트다운 완료 후 통화 연결 (Line 172-175)
3. 오버레이 "통화 연결됨" 버튼 클릭 (Line 236)

**통화 종료 처리**:
- `_connectedCustomer != null` 조건으로 정확한 고객 정보 사용
- `callEnded` 상태 발생 → CallResultScreen 이동

#### 빌드 정보

**APK**:
- 위치: `build/app/outputs/flutter-apk/app-release.apk`
- 크기: 22.3MB
- 상태: 일시정지 후 다음 고객 재개 기능 + 통화 종료 후 정확한 고객 정보 표시 완료

---

### 2025-10-22 - 일시정지 버튼 구현 및 오버레이 반응형 디자인

#### 작업 목표
오버레이 창에 일시정지 버튼 추가 및 반응형 디자인으로 모든 화면 크기에서 정상 표시

#### 구현 내용

**1. 일시정지 버튼 추가 (3개 버튼 레이아웃)**

파일: `android/app/src/main/kotlin/com/callup/callup/OverlayView.kt`

3개 버튼 구성:
- **통화 연결됨** (녹색, 18sp): 통화 연결 → 결과 입력 페이지
- **일시정지** (주황색, 16sp): 전화 종료 → 다음 고객 정보 표시 → 대기 상태
- **다음** (빨간색, 14sp): 전화 종료 → 부재중 처리 → 자동 다음 고객

버튼 간격: 화면 높이의 1.2% (반응형)

**2. Flutter-Native 양방향 통신**

파일: `lib/services/overlay_service.dart`
```dart
static void setupCallbackHandler() {
  _channel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'onConnected':
        AutoCallService().notifyConnected();
        break;
      case 'onPause':  // NEW
        AutoCallService().notifyPause();
        break;
      case 'onTimeout':
        AutoCallService().notifySkip();
        break;
    }
  });
}
```

**3. 일시정지 로직 구현**

파일: `lib/services/auto_call_service.dart`
```dart
Future<void> notifyPause() async {
  debugPrint('일시정지 알림 받음 (일시정지 버튼)');
  _countdownTimer?.cancel();

  if (_callCompleter != null && !_callCompleter!.isCompleted) {
    _callCompleter!.complete(CallResult.cancelled);
  }

  // 1. 전화 강제 종료
  await PhoneService.endCall();

  // 2. 다음 고객으로 인덱스 이동
  currentIndex++;
  final nextCustomer = getCurrentCustomer();

  // 3. 다음 고객 정보로 paused 상태 전송
  _stateController.add(AutoCallState(
    status: AutoCallStatus.paused,
    customer: nextCustomer,
    progress: '${currentIndex + 1}/${customerQueue.length}',
  ));

  // 4. isRunning = true 유지 (재개 가능)
  isRunning = true;
}
```

**4. 오버레이 반응형 디자인**

파일: `android/app/src/main/kotlin/com/callup/callup/OverlayView.kt`

모든 크기를 화면 비율 기반으로 변경:
```kotlin
// 화면 크기 가져오기
val screenWidth = resources.displayMetrics.widthPixels
val screenHeight = resources.displayMetrics.heightPixels

// 반응형 패딩 (3% / 2%)
val horizontalPadding = (screenWidth * 0.03).toInt()
val verticalPadding = (screenHeight * 0.02).toInt()

// 반응형 마진 (0.8% / 1.5% / 2%)
val baseMargin = (screenHeight * 0.015).toInt()
val smallMargin = (screenHeight * 0.008).toInt()
val largeMargin = (screenHeight * 0.02).toInt()

// 고정 텍스트 크기 (반응형에서 고정으로 변경)
val textSizeSmall = 14f
val textSizeMedium = 16f
val textSizeLarge = 28f

// 반응형 버튼 크기
val buttonTextLarge = 18f
val buttonTextMedium = 16f
val buttonTextSmall = 14f
val buttonPaddingLarge = (screenHeight * 0.018).toInt()
val buttonPaddingMedium = (screenHeight * 0.015).toInt()
val buttonPaddingSmall = (screenHeight * 0.012).toInt()
val buttonSpacing = (screenHeight * 0.012).toInt()
```

파일: `android/app/src/main/kotlin/com/callup/callup/OverlayService.kt`
```kotlin
params.width = (resources.displayMetrics.widthPixels * 0.9).toInt()  // 90% 너비
params.height = (resources.displayMetrics.heightPixels * 0.75).toInt()  // 75% 높이
```

**5. 안내 문구 줄 간격 조정**

파일: `android/app/src/main/kotlin/com/callup/callup/OverlayView.kt`
```kotlin
val warningText = TextView(context).apply {
    text = "통화가 연결되면\n⚠️ 반드시 통화연결됨 버튼을 눌러주세요!!⚠️\n누르지 않으면 연결이 끊어집니다"
    setLineSpacing(8f, 1.0f)  // 줄 간격 8dp 추가
    ...
}
```

**6. 서비스 안정성 강화 (앱 종료 방지)**

파일: `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

파일: `android/app/src/main/kotlin/com/callup/callup/OverlayService.kt`

알림 우선순위 상향:
```kotlin
.setPriority(NotificationCompat.PRIORITY_HIGH)  // LOW → HIGH
.setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)

// 알림 채널
NotificationManager.IMPORTANCE_HIGH  // LOW → HIGH
```

서비스 재시작 메커니즘:
```kotlin
override fun onTaskRemoved(rootIntent: Intent?) {
    super.onTaskRemoved(rootIntent)

    // 앱이 최근 앱 목록에서 제거되어도 1초 후 서비스 재시작
    val restartServiceIntent = Intent(applicationContext, OverlayService::class.java)
    val restartServicePendingIntent = PendingIntent.getService(...)

    val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
    alarmManager.set(
        android.app.AlarmManager.ELAPSED_REALTIME,
        android.os.SystemClock.elapsedRealtime() + 1000,
        restartServicePendingIntent
    )
}
```

#### 동작 흐름 (일시정지 버튼)

**4번 고객 통화 중 일시정지 클릭 시**:
1. 오버레이 "일시정지" 버튼 클릭
2. `notifyPause()` 호출 → 전화 강제 종료
3. `currentIndex++` → 5번 고객으로 이동
4. `AutoCallStatus.paused` 상태로 5번 고객 정보 전송
5. AutoCallScreen: "대기중" 상태 + 5번 고객 정보 표시 + START 버튼 활성화
6. START 버튼 클릭 → 5번 고객에게 전화 시작

#### 개선 효과

**반응형 디자인**:
- 작은 화면 (1280x720): 모든 요소 적절히 축소
- 큰 화면 (2340x1080): 모든 요소 적절히 확대
- 특대 화면 (3840x2160): 버튼 3개 모두 충분한 공간 확보

**서비스 안정성**:
- 알림 우선순위 상향 → 시스템이 서비스를 덜 종료
- FOREGROUND_SERVICE_IMMEDIATE → 서비스가 즉시 포그라운드로 전환
- WAKE_LOCK → CPU 슬립 모드 방지
- 배터리 최적화 제외 → 시스템이 배터리 절약을 위해 종료하지 않음
- onTaskRemoved() → 앱이 최근 앱 목록에서 제거되어도 1초 후 자동 재시작

---

### 2025-10-22 - MySQL 데이터베이스 스키마 설계

#### 작업 목표
CSV 파일 구조를 기반으로 MySQL 데이터베이스 스키마 설계 및 SQL 문서 작성

#### 생성된 파일

**DATABASE_SCHEMA.md**: MySQL 데이터베이스 완전한 스키마 설계

#### 데이터베이스 구조 (5개 테이블)

**1. users (상담원 정보)**
- user_id (PK), user_login_id, user_name, user_password (SHA2 해시)
- user_phone, user_status_message
- is_active, created_at, updated_at

**2. db_lists (DB 리스트)**
- db_id (PK), db_title, db_date
- total_count, unused_count
- file_name, is_active (ON/OFF)
- upload_date, created_at, updated_at

**3. customers (고객 정보)**

CSV 기본 정보 (0-5번 컬럼):
- event_name, customer_phone, customer_name
- customer_info1, customer_info2, customer_info3 (관리자 자유 입력)

CSV 통화 관련 정보 (7-16번 컬럼):
- data_status ENUM('미사용', '사용완료') - DB 사용 여부
- call_result VARCHAR(100) - 통화 결과
- consultation_result TEXT - 상담 결과
- memo TEXT
- call_datetime DATETIME
- call_start_time TIME - 통화 시작 시간
- call_end_time TIME - 통화 종료 시간
- call_duration VARCHAR(20)
- reservation_date DATE - 통화 예약일
- reservation_time TIME - 통화 예약 시간

CSV 메타 정보 (17-18번 컬럼):
- upload_date DATE
- last_modified_date DATETIME

**4. call_logs (통화 로그)**
- log_id (PK), user_id (FK), customer_id (FK), db_id (FK)
- call_datetime, call_start_time, call_end_time, call_duration
- call_result, consultation_result, memo
- has_audio, audio_file_path

**5. statistics (통계 정보)**
- stat_id (PK), user_id (FK), stat_date
- total_call_time, total_call_count
- success_count, failed_count, callback_count, no_answer_count
- assigned_db_count, unused_db_count

#### CSV 컬럼 매핑 (18개)

| 인덱스 | 컬럼명 | MySQL 필드 |
|--------|--------|-----------|
| 0 | 이벤트명 | event_name |
| 1 | 전화번호 | customer_phone |
| 2 | 고객명 | customer_name |
| 3 | 고객정보1 | customer_info1 |
| 4 | 고객정보2 | customer_info2 |
| 5 | 고객정보3 | customer_info3 |
| 7 | 상태 | data_status |
| 8 | 통화결과 | call_result |
| 9 | 상담결과 | consultation_result |
| 10 | 메모 | memo |
| 11 | 통화일시 | call_datetime |
| 12 | 통화시작시간 | call_start_time |
| 13 | 통화종료시간 | call_end_time |
| 14 | 통화시간 | call_duration |
| 15 | 통화예약일 | reservation_date |
| 16 | 통화예약시간 | reservation_time |
| 17 | 업로드날짜 | upload_date |
| 18 | 최종수정일 | last_modified_date |

#### 주요 기능

**트리거 (자동 업데이트)**:
1. customers 테이블 변경 시 db_lists의 unused_count 자동 갱신
2. call_logs 삽입 시 statistics 자동 갱신

**주요 쿼리 8개**:
1. 특정 DB의 미사용 고객 목록 조회
2. 상담원별 오늘 통계 조회
3. DB 리스트 조회 (미사용 개수 포함)
4. 고객 검색 (이름, 전화번호, 이벤트명)
5. 통화 로그 기록
6. 고객 통화 정보 업데이트
7. 통화 예약 설정
8. 예약된 통화 목록 조회 (오늘 기준)

**인덱스 최적화**:
- users: user_login_id, user_name
- db_lists: db_date, is_active
- customers: db_id, phone, data_status, reservation_date
- call_logs: user_id, customer_id, call_datetime
- statistics: user_id, stat_date

#### 변경 사항 (v2.0.0)

- 고객정보1-3으로 축소 (관리자 자유 입력)
- ~~고객정보4 삭제~~
- ~~고객유형 삭제~~
- 통화상태 → 데이터상태로 변경 (미사용/사용완료)
- 통화시작시간, 통화종료시간 추가
- 통화예약일, 통화예약시간 추가
- 통화결과, 상담결과 분리
- CSV 컬럼 18개로 확정

#### 빌드 정보

**APK**:
- 위치: `build/app/outputs/flutter-apk/app-release.apk`
- 크기: 22.3MB
- 상태: 일시정지 버튼 구현 + 반응형 오버레이 + 서비스 안정성 강화 완료

---

### 2025-10-24 - 업체 기반 인증 시스템 전환 및 로그인 UX 개선

#### 작업 목표
개인 계정 → 업체 기반 계정 시스템으로 전환하고 로그인 화면 전환 UX 개선

#### 구현 내용

**1. 업체 기반 인증 시스템으로 변경**

변경 전 (개인 계정):
- 개별 사용자 회원가입
- 사용자 ID/비밀번호 기반 인증
- 독립적인 사용자 관리

변경 후 (업체 기반):
- 업체 단위로 계정 관리
- 업체 ID + 비밀번호 + 상담원 이름으로 로그인
- 한 업체에 여러 상담원 소속
- JWT 토큰에 업체ID, 사용자ID, 상담원명, 역할 정보 포함

**2. API 연동 완료**

새로 추가된 파일:
- `lib/services/api/api_client.dart` - HTTP 클라이언트 (토큰 관리, 에러 처리)
- `lib/services/api/auth_api_service.dart` - 로그인 API
- `lib/services/api/dashboard_api_service.dart` - 대시보드 API
- `lib/services/token_storage.dart` - JWT 토큰 저장/관리 (SharedPreferences)

API 엔드포인트:
- `POST /api/auth/login` - 로그인
- `GET /api/dashboard` - 대시보드 데이터 조회
- `POST /api/dashboard/toggle-status` - 상담원 상태 토글

**3. 로그인 화면 수정**

파일: `lib/screens/signup_screen.dart`

입력 필드 변경:
- 기존: ID, 이름, 비밀번호
- 변경: 업체 ID, 비밀번호, 상담원 이름

```dart
_companyIdController    // 업체 로그인 ID
_passwordController     // 업체 비밀번호
_agentNameController    // 상담원 이름
```

**4. 대시보드 API 연동**

파일: `lib/screens/dashboard_screen.dart`

API 응답 데이터 구조:
```dart
{
  "user": {
    "userId": 2,
    "userName": "김상담",
    "phone": "010-2345-6789",
    "statusMessage": "업무 중",
    "isActive": 1,
    "lastActiveTime": "2025-10-24T13:19:13.000Z"
  },
  "todayStats": {
    "callCount": 25,
    "callDuration": "01:23:45",
    "connectedCount": 15,
    "failedCount": 8,
    "callbackCount": 2
  },
  "dbLists": [
    {
      "dbId": 1,
      "title": "이벤트01_251014",
      "date": "2025-10-14",
      "totalCount": 500,
      "unusedCount": 250,
      "isActive": 1
    }
  ]
}
```

**5. 출근 시스템 구현**

파일: `lib/screens/dashboard_screen.dart`

출근 시스템 로직 (SharedPreferences):
- `active_login_time`: 출근 시간 기록
- `active_date`: 출근 날짜 (YYYY-MM-DD)
- `is_active_today`: 오늘 출근 여부 (true/false)

동작 방식:
1. **첫 로그인**: 토글 OFF 상태, 로그인시간 표시 없음
2. **토글 ON**: 현재 시간 저장 + "출근" 표시
3. **페이지 이동 후 복귀**: 저장된 출근 시간 유지
4. **앱 재시작**: 같은 날짜면 출근 상태 유지
5. **다음날 로그인**: 자동으로 OFF 상태로 리셋

표시 텍스트:
- 토글 OFF: "미출근"
- 토글 ON (시간 없음): "출근"
- 토글 ON (시간 있음): "2025-10-24 09:30:15"

**6. 토글 버튼 스타일 통일**

대시보드와 오토콜 화면의 토글 버튼 스타일 일치:
- ON 상태: #FF0756 (핑크)
- OFF 상태: #383743 (다크 그레이)
- 높이: 34px
- 원형 버튼: 29px (흰색)
- 텍스트: 11sp, bold

**7. 로그인 화면 전환 UX 개선**

문제 상황:
- 키보드 올라온 상태에서 로그인 → 오버플로우 발생
- 로딩 다이얼로그 닫힌 후 빈 화면 표시
- 대시보드로 갔다가 다시 로그인 화면으로 돌아옴
- 하단 네비게이션 바 깜빡임
- 키보드가 다시 올라왔다 내려감

해결 방법:

**문제 1: 키보드 오버플로우**
- Positioned 위젯의 고정 좌표가 키보드로 인한 화면 축소 시 화면 밖으로 벗어남
- 해결: Stack을 ClipRect로 감싸서 화면 밖 요소 잘라내기

```dart
body: ClipRect(
  child: Stack(
    children: [
      // Positioned 배경 원들...
      Center(
        child: SingleChildScrollView(...)
      )
    ]
  )
)
```

**문제 2: 로그인 후 대시보드 → 로그인으로 돌아옴**
- 원인: `Navigator.pushReplacement` 후 `Navigator.pop` 호출 → 대시보드가 닫힘
- 해결: pop을 먼저 호출하고 그 다음 pushReplacement

```dart
// Before (잘못된 순서)
Navigator.pushReplacement(...);  // 대시보드로 이동
await Future.delayed(100ms);
Navigator.pop(context);  // 이미 대시보드인데 pop → 로그인으로 돌아감!

// After (올바른 순서)
Navigator.pop(context);  // 로딩 다이얼로그 닫기
await Future.delayed(100ms);
Navigator.pushReplacement(...);  // 대시보드로 이동
```

**문제 3: 하단 네비게이션 바 깜빡임**
- 원인: 대시보드 로딩 중(`_isLoading = true`)에도 네비게이션 바 렌더링
- 해결: 로딩 중에는 네비게이션 바 숨기기

```dart
// Bottom Navigation Bar (로딩 중이 아닐 때만 표시)
if (!_isLoading)
  Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: CustomBottomNavigationBar(...),
  ),
```

**문제 4: 키보드 재출현**
- 원인: 로딩 다이얼로그 닫은 후 TextField가 포커스 유지
- 해결: 이중 포커스 해제 + 충분한 딜레이

```dart
// 1. 로딩 다이얼로그 닫기
Navigator.pop(context);

// 2. 키보드를 확실하게 닫기 (이중 방어)
FocusScope.of(context).unfocus();
FocusManager.instance.primaryFocus?.unfocus();

// 3. 150ms 대기 (키보드 완전히 닫힐 때까지)
await Future.delayed(const Duration(milliseconds: 150));

// 4. 대시보드로 전환
Navigator.pushReplacement(...);
```

**8. JWT 토큰 만료 처리**

파일: `lib/screens/auto_call_screen.dart`, `lib/screens/call_result_screen.dart`

TODO 주석 구현:
```dart
if (result['requireLogin'] == true) {
  // JWT 토큰 만료 → 로그인 화면으로
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('로그인이 만료되었습니다.')),
  );
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const SignUpScreen()),
  );
}
```

**9. 디버그 로그 정리**

모든 `print()` 문을 `debugPrint()`로 변경:
- `lib/screens/signup_screen.dart` (5개)
- `lib/services/api/api_client.dart` (7개)
- `lib/services/api/auth_api_service.dart` (3개)

#### 로그인 전환 타임라인 (최종)

```
0ms   ─ 로그인 버튼 클릭
0ms   ─ FocusScope.unfocus() (키보드 닫기)
150ms ─ 로딩 다이얼로그 표시
      ─ API 호출
      ─ ... (API 처리 시간)
      ─ API 완료
0ms   ─ 로딩 다이얼로그 닫기
0ms   ─ 이중 포커스 해제 (키보드 확실히 닫기)
150ms ─ 키보드 완전히 사라짐
150ms ─ 대시보드 페이드 인 시작 (300ms)
450ms ─ 대시보드 완전히 표시
```

#### 기술적 세부사항

**API 클라이언트 구조**:
- 싱글톤 패턴으로 전역 HTTP 클라이언트 관리
- JWT 토큰 자동 헤더 추가
- 401 에러 자동 감지 및 재로그인 유도
- 타임아웃 설정 (30초)
- 에러 로깅 및 예외 처리

**토큰 저장**:
- SharedPreferences 사용
- 앱 재시작 후에도 토큰 유지
- 토큰 만료 시 자동 삭제

**상태 관리**:
- SharedPreferences로 출근 상태 영구 저장
- 날짜 변경 자동 감지 및 초기화
- 토글 상태와 API 동기화

#### 발견된 문제 및 해결

**문제 1: API 필드명 불일치**
- 증상: 전화번호 "-" 표시 (데이터는 있음)
- 원인: 코드에서 `userPhone` 사용, API는 `phone` 반환
- 해결: 필드명 수정 (`userPhone` → `phone`, `userStatusMessage` → `statusMessage`)

**문제 2: 로그인 화면 왼쪽으로 몰림**
- 증상: 입력 필드들이 화면 왼쪽으로 밀림
- 원인: ConstrainedBox와 IntrinsicHeight 사용으로 Center 무효화
- 해결: `Center` 위젯으로 감싸기

**문제 3: Navigator.pop 순서 오류**
- 증상: 대시보드 진입 후 즉시 로그인 화면으로 돌아옴
- 원인: pushReplacement 후 pop 호출 → 대시보드가 닫힘
- 해결: pop을 먼저 호출한 후 pushReplacement

#### 개선 효과

✅ 업체 기반 계정 시스템으로 전환 완료
✅ API 연동 완료 (로그인, 대시보드, 토글)
✅ 출근 시스템 구현 (날짜 자동 리셋)
✅ 키보드 오버플로우 완전 해결
✅ 로그인 화면 전환 부드럽고 자연스럽게 개선
✅ 하단 네비게이션 깜빡임 해결
✅ JWT 토큰 만료 처리 구현
✅ 디버그 로그 정리 (debugPrint 사용)

#### 빌드 정보

**APK**:
- 위치: `build/app/outputs/flutter-apk/app-release.apk`
- 크기: 24.5MB
- 상태: 업체 기반 인증 시스템 + 로그인 UX 개선 완료

---

### 2025-11-01 - 녹취 파일 자동 업로드 API 호환성 작업

#### 작업 목표
백엔드 API 명세에 맞춰 녹취 파일 업로드 시스템 수정 및 호환성 확보

#### 구현 내용

**1. API 명세 문서 작성**

생성된 파일: `RECORDING_API_SPEC.md`

백엔드 팀을 위한 종합 API 명세서:
- POST /api/recordings/upload 엔드포인트 명세
- Request/Response 형식 상세 설명
- 데이터베이스 스키마 권장사항 (customers, recordings 테이블)
- 파일 저장 전략 및 디렉토리 구조
- 보안 고려사항 (JWT, 파일 검증)
- Jest 기반 테스트 가이드
- FAQ 섹션

**2. API 문서 비교 분석**

생성된 파일: `RECORDING_IMPLEMENTATION_REVIEW.md`

API 팀이 제공한 문서와 현재 구현 비교:
- `API_ENDPOINTS.md` - API 엔드포인트 명세
- `RECORDING_SYSTEM_SETUP.md` - 실제 구현 문서

발견된 불일치 사항:
1. **recordedAt 형식 불일치** (HIGH): Unix timestamp → ISO 8601 변환 필요
2. **파일 크기 검증 누락** (MEDIUM): 50MB 제한 체크 추가 필요
3. **에러 메시지 개선** (LOW): HTTP 상태 코드별 한글 메시지 추가

**3. RecordingUploadService 수정**

파일: `android/app/src/main/kotlin/com/callup/callup/recording/RecordingUploadService.kt`

**수정 1: ISO 8601 날짜 형식 변환 (Lines 203-206)**
```kotlin
// recordedAt을 ISO 8601 형식으로 변환
val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
dateFormat.timeZone = TimeZone.getTimeZone("UTC")
val recordedAtISO = dateFormat.format(Date(matchedCall.callTimestamp))
```

**수정 2: 파일 크기 검증 추가 (Lines 188-194)**
```kotlin
// 파일 크기 검증 (50MB 제한)
val maxSize = 50 * 1024 * 1024L  // 50MB
if (file.length() > maxSize) {
    val fileSizeMB = file.length() / (1024.0 * 1024.0)
    Log.w(TAG, "파일 크기 초과: ${String.format("%.2f", fileSizeMB)}MB (최대 50MB)")
    throw Exception("파일 크기가 50MB를 초과합니다")
}
```

**수정 3: 에러 메시지 개선 (Lines 233-243)**
```kotlin
// API 에러 코드별 메시지
val errorMessage = when (response.code) {
    401 -> "JWT 토큰이 만료되었습니다"
    413 -> "파일 크기가 50MB를 초과합니다"
    415 -> "지원하지 않는 파일 형식입니다"
    500 -> "서버 오류가 발생했습니다"
    else -> "업로드 실패: ${response.code}"
}
```

**수정 4: 필수 Import 추가 (Lines 25-28)**
```kotlin
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
```

#### 기술적 세부사항

**ISO 8601 형식 변환**:
- Before: Unix timestamp (Long) → "1730361600000"
- After: ISO 8601 (String) → "2025-01-15T14:30:52Z"
- UTC 시간대 사용으로 시간대 문제 해결

**파일 크기 검증**:
- 업로드 전 클라이언트 측에서 50MB 제한 확인
- 네트워크 대역폭 절약
- 사용자에게 즉시 피드백 제공

**에러 처리 개선**:
- HTTP 상태 코드별 한글 메시지 매핑
- 사용자 친화적인 에러 메시지
- 디버깅을 위한 상세 로깅

#### API 호환성 검증

**변경 전후 비교**:

| 항목 | 변경 전 | 변경 후 | 상태 |
|------|---------|---------|------|
| recordedAt 형식 | Unix timestamp | ISO 8601 | ✅ 수정 완료 |
| 파일 크기 검증 | 없음 | 50MB 제한 체크 | ✅ 추가 완료 |
| 에러 메시지 | 일반 메시지 | 상태 코드별 한글 | ✅ 개선 완료 |
| JWT 인증 | Bearer 토큰 | Bearer 토큰 | ✅ 기존 유지 |
| 파일 형식 | m4a, mp3, amr 등 | m4a, mp3, amr 등 | ✅ 기존 유지 |
| 업로드 주기 | 10분 | 10분 | ✅ 기존 유지 |

#### 파일 구조

**녹취 시스템 관련 파일**:
```
android/app/src/main/kotlin/com/callup/callup/recording/
├── RecordingUploadService.kt      # 자동 업로드 서비스 (수정됨)
├── RecordingAutoCollector.kt      # 녹취 파일 스캔
├── CallRecordingMatcher.kt        # 통화 기록 매칭
└── RecordingPlayerHelper.kt       # 녹취 재생

lib/services/
└── recording_service.dart          # Flutter-Native 브릿지

문서/
├── RECORDING_API_SPEC.md          # API 명세서 (신규)
└── RECORDING_IMPLEMENTATION_REVIEW.md  # 비교 분석 (신규)
```

#### 빌드 정보

**APK**:
- 위치: `build/app/outputs/flutter-apk/app-release.apk`
- 크기: 24.8MB
- 상태: API 호환성 수정 완료, 빌드 성공

**의존성**:
- OkHttp 4.12.0 (HTTP 클라이언트)
- SimpleDateFormat (날짜 형식 변환)

#### 향후 개선 사항 (선택 사항)

문서에 기록된 추가 개선 가능 항목:
- [ ] 업로드 실패 시 재시도 로직 (지수 백오프)
- [ ] 업로드 진행률 알림
- [ ] 서버 스트리밍 재생 지원 (현재는 로컬 재생만)

#### 테스트 항목

API 연동 후 확인 필요:
- [ ] 녹취 파일 자동 업로드 (10분 간격)
- [ ] ISO 8601 형식 서버 파싱 정상 작동
- [ ] 50MB 초과 파일 업로드 거부
- [ ] JWT 토큰 만료 시 401 에러 처리
- [ ] 파일 형식 검증 (m4a, mp3, amr, 3gp, wav, aac)
- [ ] 중복 업로드 방지 (SharedPreferences)

---

**마지막 업데이트**: 2025-11-01
**버전**: 1.0.0+4
**플랫폼**: Android
