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

**마지막 업데이트**: 2025-10-21
**버전**: 1.0.0+2
**플랫폼**: Android
