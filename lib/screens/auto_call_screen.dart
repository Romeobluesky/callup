import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import '../services/auto_call_service.dart';
import '../services/db_manager.dart';
import '../services/phone_service.dart';
import '../services/api/customer_api_service.dart';
import '../models/auto_call_state.dart';
import 'dashboard_screen.dart';
import 'stats_screen.dart';
import 'customer_search_screen.dart';
import 'call_result_screen.dart';
import 'signup_screen.dart';

class AutoCallScreen extends StatefulWidget {
  const AutoCallScreen({super.key});

  @override
  State<AutoCallScreen> createState() => _AutoCallScreenState();
}

class _AutoCallScreenState extends State<AutoCallScreen>
    with SingleTickerProviderStateMixin {
  bool _isOn = false;
  final int _selectedIndex = 1;
  String _callStatus = '대기중';
  bool _isAutoRunning = false; // Auto 실행 상태
  bool _isPaused = false; // 일시정지 상태 (다음 고객 대기)
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  // 자동 전화 관련 상태
  Map<String, dynamic>? _currentCustomer;
  int _countdown = 5;
  String _progress = '0/0';
  List<Map<String, dynamic>> _customers = [];
  int _totalAssignedCount = 0;  // 분배받은 총 개수 (고정값, 절대 변경 금지!)
  int _completedCount = 0;  // 처리 완료한 고객 수 (API에서 받음)

  // Stream 구독
  StreamSubscription<AutoCallState>? _stateSubscription;
  StreamSubscription<int>? _countdownSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _rotationAnimation =
        Tween<double>(
          begin: 0,
          end: 3.14159, // 180도 (π 라디안)
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
          ),
        );

    // 전화 상태 모니터링 시작
    _startPhoneStateMonitoring();

    // AutoCallService Stream 구독
    _subscribeToAutoCallService();

    // DB가 선택되어 있으면 고객 데이터 로드
    _loadSelectedDBCustomers();
  }

  Future<void> _startPhoneStateMonitoring() async {
    await PhoneService.startPhoneStateMonitoring();
  }

  Future<void> _loadSelectedDBCustomers() async {
    final selectedDB = DBManager().selectedDB;
    if (selectedDB == null) {
      // DB가 선택되지 않았으면 기본 DB 선택
      debugPrint('DB가 선택되지 않아 기본 DB 선택');
      DBManager().selectDB({
        'date': '2025-10-14',
        'title': '이벤트01_251014',
        'total': 500,
        'unused': 250,
        'fileName': 'customers.csv',
      });
    }

    await _loadCustomers();
    // 고객이 로드되면 첫 번째 고객 정보 표시
    if (_customers.isNotEmpty && _totalAssignedCount > 0) {
      setState(() {
        _currentCustomer = _customers[0];
        // remainingCount = 실제 미사용 고객 수 (API에서 받은 customers.length)
        final remainingCount = _customers.length;
        _progress = '$remainingCount/$_totalAssignedCount';
        debugPrint('✅ 첫 로드 progress: $remainingCount/$_totalAssignedCount');
      });
    }
  }

  void _subscribeToAutoCallService() {
    _stateSubscription = AutoCallService().stateStream.listen((state) {
      if (!mounted) return;

      setState(() {
        switch (state.status) {
          case AutoCallStatus.dialing:
            _callStatus = '발신중';
            _currentCustomer = state.customer;
            _progress = state.progress ?? '0/0';
            _isPaused = false;
            break;
          case AutoCallStatus.ringing:
            _callStatus = '응답대기';
            _isPaused = false;
            break;
          case AutoCallStatus.connected:
            _callStatus = '통화중';
            _currentCustomer = state.customer;  // 통화 연결된 고객 저장
            _isPaused = false;
            // 통화 연결 시 오토콜 일시정지 (오버레이는 이미 숨겨짐)
            break;
          case AutoCallStatus.callEnded:
            // 통화 종료 시 CallResultScreen으로 이동
            _callStatus = '통화종료';
            _currentCustomer = state.customer;  // 통화 종료된 고객 정보 저장
            _isPaused = false;
            _navigateToCallResult();
            break;
          case AutoCallStatus.paused:
            // 결과 등록 후 일시정지 - 다음 고객 정보 표시
            _callStatus = '대기중';
            _currentCustomer = state.customer;  // 다음 고객 정보
            _progress = state.progress ?? '0/0';
            _isAutoRunning = true;  // 오토콜은 계속 실행 중
            _isPaused = true;  // 일시정지 상태 (다음 고객 대기)
            break;
          case AutoCallStatus.completed:
            _callStatus = '완료';
            _isAutoRunning = false;
            _isPaused = false;
            // 전체 완료 시 0/totalAssignedCount 표시 + 고객 정보 초기화
            if (_totalAssignedCount > 0) {
              _progress = '0/$_totalAssignedCount';
            }
            _currentCustomer = null;  // 고객 정보 지우기
            _showCompletionDialog();
            break;
          case AutoCallStatus.idle:
            _callStatus = '대기중';
            _isAutoRunning = false;
            _isPaused = false;
            // idle 상태일 때 첫 번째 고객 정보 유지 (빈칸으로 만들지 않음)
            if (_customers.isNotEmpty && _currentCustomer == null && _totalAssignedCount > 0) {
              _currentCustomer = _customers[0];
              // remainingCount = 실제 미사용 고객 수
              final remainingCount = _customers.length;
              _progress = '$remainingCount/$_totalAssignedCount';
            }
            break;
        }
      });
    });

    _countdownSubscription = AutoCallService().countdownStream.listen((count) {
      if (!mounted) return;

      setState(() {
        _countdown = count;
      });
    });
  }

  void _navigateToCallResult() {
    if (_currentCustomer == null) return;

    // customer 객체에서 통화 시간 추출 (기본값 0)
    final callDuration = _currentCustomer!['callDuration'] ?? 0;
    debugPrint('=== CallResultScreen으로 이동 ===');
    debugPrint('전체 고객 객체: $_currentCustomer');
    debugPrint('고객 정보: ${_currentCustomer!['name']}');
    debugPrint('customerId: ${_currentCustomer!['customerId']}');
    debugPrint('dbId: ${_currentCustomer!['dbId']}');
    debugPrint('통화 시간 (callDuration): $callDuration초');

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, _) => CallResultScreen(
          customer: _currentCustomer!,
          callDuration: callDuration,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,  // 바깥 클릭으로 닫기 방지
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF585667),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        title: const Text(
          '완료',
          style: TextStyle(color: Color(0xFFF9F8EB)),
        ),
        content: const Text(
          '전체 자동 전화가 완료되었습니다!',
          style: TextStyle(color: Color(0xFFF9F8EB)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 확인 버튼 클릭 후 고객 리스트 초기화
              setState(() {
                _customers.clear();
                debugPrint('✅ 완료 후 고객 리스트 초기화');
              });
            },
            child: const Text('확인', style: TextStyle(color: Color(0xFFFF0756))),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCustomers() async {
    try {
      // 선택된 DB 확인
      final selectedDB = DBManager().selectedDB;
      if (selectedDB == null) {
        debugPrint('선택된 DB가 없습니다.');
        return;
      }

      final dbId = selectedDB['dbId'] ?? selectedDB['id'];
      if (dbId == null) {
        debugPrint('DB ID가 없습니다.');
        return;
      }

      debugPrint('=== DB 로드 시작 (API) ===');
      debugPrint('DB ID: $dbId');
      debugPrint('제목: ${selectedDB['title']}');

      // /api/agent/customers API 사용 (고객 페이지와 동일)
      final result = await CustomerApiService.searchCustomers(
        limit: 1000,  // 최대 1000명
      );

      if (!mounted) return;

      if (result['success'] == true && result['customers'] != null) {
        final allCustomers = result['customers'] as List;

        // 첫 번째 고객 데이터 로그 확인
        if (allCustomers.isNotEmpty) {
          debugPrint('=== API 응답 첫 번째 고객 데이터 ===');
          debugPrint('전체 객체: ${allCustomers[0]}');
          debugPrint('customerId: ${allCustomers[0]['customerId']}');
          debugPrint('dbId: ${allCustomers[0]['dbId']}');
          debugPrint('status: ${allCustomers[0]['status']}');
          debugPrint('eventName: ${allCustomers[0]['eventName']}');
        }

        setState(() {
          // 선택한 DB의 미사용 고객만 필터링
          _customers = allCustomers
            .where((customer) {
              final status = customer['status'] ?? '미사용';
              final customerDbId = customer['dbId'];
              // dbId가 일치하고 미사용인 고객만
              return status == '미사용' && customerDbId == dbId;
            })
            .map((customer) => {
              'customerId': customer['customerId'],
              'dbId': customer['dbId'],
              'event': customer['eventName'] ?? '-',
              'phone': customer['phone'] ?? '-',
              'name': customer['name'] ?? '-',
              'info1': customer['info1'] ?? '-',
              'info2': customer['info2'] ?? '-',
              'info3': customer['info3'] ?? '-',
              'dataStatus': customer['status'] ?? '미사용',
            }).toList();

          debugPrint('✅ API에서 받은 전체 고객: ${allCustomers.length}명');
          debugPrint('✅ DB $dbId의 미사용 고객: ${_customers.length}명');

          // 분배받은 총 개수 = 해당 DB의 전체 고객 수 (미사용 + 사용완료)
          final dbTotalCount = allCustomers.where((c) => c['dbId'] == dbId).length;

          // 분배받은 총 개수 저장 (처음에만, 절대 변경 금지!)
          if (_totalAssignedCount == 0 && dbTotalCount > 0) {
            _totalAssignedCount = dbTotalCount;
            debugPrint('✅ totalAssignedCount 첫 설정: $_totalAssignedCount (고정)');
          } else {
            debugPrint('✅ totalAssignedCount 유지: $_totalAssignedCount (재개 시)');
          }

          // 처리 완료한 고객 수 = 전체 - 미사용
          _completedCount = _totalAssignedCount - _customers.length;
        });

        debugPrint('고객 로드 완료: ${_customers.length}명');
        debugPrint('분배받은 총 개수: $_totalAssignedCount명 (고정)');
        debugPrint('처리 완료한 고객 수: $_completedCount명');
      } else if (result['requireLogin'] == true) {
        // JWT 토큰 만료 → 로그인 화면으로
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 만료되었습니다.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignUpScreen()),
        );
      } else {
        debugPrint('고객 로드 실패: ${result['message']}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '고객 조회에 실패했습니다.')),
        );
      }
    } catch (e) {
      debugPrint('고객 로드 오류: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

  Future<void> _startAutoCalling() async {
    try {
      // 고객 데이터 로드
      if (_customers.isEmpty) {
        await _loadCustomers();
      }

      if (_customers.isEmpty) {
        debugPrint('미사용 고객이 없습니다.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('미사용 고객이 없습니다. 모든 고객 통화가 완료되었습니다.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      debugPrint('고객 데이터 로드 완료: ${_customers.length}명');

      setState(() {
        _isAutoRunning = true;
      });

      // AutoCallService 시작
      debugPrint('AutoCallService 시작 - totalAssignedCount: $_totalAssignedCount, completedCount: $_completedCount');
      await AutoCallService().start(
        _customers,
        totalCount: _totalAssignedCount,
        completedCount: _completedCount,
      );
    } catch (e) {
      debugPrint('_startAutoCalling 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
      setState(() {
        _isAutoRunning = false;
      });
    }
  }

  void _stopAutoCalling() {
    setState(() {
      _isAutoRunning = false;
    });

    AutoCallService().stop();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stateSubscription?.cancel();
    _countdownSubscription?.cancel();
    PhoneService.stopPhoneStateMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.9;

    return Scaffold(
      backgroundColor: const Color(0xFF585667),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 95),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildStartButton(cardWidth),
              const SizedBox(height: 30),
              _buildModeButtons(cardWidth),
              const SizedBox(height: 10),
              _buildCustomerInfoCard(cardWidth),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          if (index == 0) {
            // Dashboard
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 200),
                pageBuilder: (context, animation, _) => const DashboardScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.1, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
              ),
            );
          } else if (index == 3) {
            // 현황
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 200),
                pageBuilder: (context, animation, _) => const StatsScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
              ),
            );
          } else if (index == 2) {
            // 고객관리
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 200),
                pageBuilder: (context, animation, _) => const CustomerSearchScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'CallUp',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF0756),
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: const Offset(0, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Mobile Autocall',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF9F8EB),
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: const Offset(0, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isOn = !_isOn;
              });
            },
            child: Container(
              width: 63,
              height: 27,
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: _isOn
                    ? const Color(0xFFFF0756)
                    : const Color(0xFF383743),
                borderRadius: BorderRadius.circular(360),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    alignment: _isOn
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFCDDD),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Align(
                    alignment: _isOn
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        _isOn ? 'on' : 'off',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFFFCDDD),
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(double cardWidth) {
    return GestureDetector(
      onTap: () async {
        if (_isPaused) {
          // PAUSED 상태 → 다음 고객으로 전화 재개
          await AutoCallService().continueToNextCustomer();
        } else if (!_isAutoRunning) {
          // START 클릭 → 자동 전화 시작
          await _startAutoCalling();
        } else {
          // END 클릭 → 자동 전화 중지
          _stopAutoCalling();
        }
      },
      child: Container(
        width: cardWidth,
        height: 60,
        decoration: BoxDecoration(
          color: _isPaused
              ? const Color(0xFFFF0756)  // 일시정지 상태는 빨간색 (START와 동일)
              : _isAutoRunning
                  ? Colors.white.withValues(alpha: 0.3)
                  : const Color(0xFFFF0756),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isPaused
                  ? 'START'  // 일시정지 상태에서는 START 표시 (다음 고객)
                  : _isAutoRunning
                      ? 'END'
                      : 'START',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButtons(double cardWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (_isAutoRunning) ...[
            const SizedBox(width: 10),
            Image.asset(
              'assets/icons/auto.png',
              width: 24,
              height: 24,
              color: const Color(0xFFFF0756),
            ),
            const SizedBox(width: 6),
            const Text(
              'AUTO',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF9F8EB),
                letterSpacing: -0.15,
              ),
            ),
          ] else ...[
            const SizedBox(width: 13),
            Image.asset(
              'assets/icons/wation.png',
              width: 18,
              height: 18,
              color: const Color(0xFFF9F8EB),
            ),
            const SizedBox(width: 6),
            const Text(
              '대기중',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF9F8EB),
                letterSpacing: -0.15,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard(double cardWidth) {
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DB
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF0756),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'DB : $_progress',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF9F8EB),
                letterSpacing: -0.15,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            '제목 : ${_currentCustomer?['event'] ?? '-'}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF9F8EB),
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 10),

          // Customer Details Table
          _buildCustomerTable(),

          const SizedBox(height: 20),

          // Status Container
          Container(
            height: 150,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
            decoration: BoxDecoration(
              color: const Color(0xFF585667),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/calling.png',
                      width: 28,
                      height: 28,
                      color: const Color(0xFFFF0756),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '상태 : $_callStatus',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF0756),
                        letterSpacing: -0.15,
                      ),
                    ),
                  ],
                ),
                // 응답대기 상태일 때만 카운트다운 표시
                if (_callStatus == '응답대기') ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationAnimation.value,
                            child: child,
                          );
                        },
                        child: Image.asset(
                          'assets/icons/pass.png',
                          width: 24,
                          height: 24,
                          color: const Color(0xFFF9F8EB),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '응답대기 : $_countdown초 후 다음고객으로',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF9F8EB),
                          letterSpacing: -0.15,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTable() {
    final List<Map<String, String>> customerData = [
      {'label': '전화번호', 'value': _currentCustomer?['phone'] ?? '-'},
      {'label': '고객명', 'value': _currentCustomer?['name'] ?? '-'},
      {'label': '고객정보1', 'value': _currentCustomer?['info1'] ?? '-'},
      {'label': '고객정보2', 'value': _currentCustomer?['info2'] ?? '-'},
      {'label': '고객정보3', 'value': _currentCustomer?['info3'] ?? '-'},
    ];

    return Column(
      children: List.generate(customerData.length, (index) {
        final isLastRow = index == customerData.length - 1;

        return Container(
          decoration: BoxDecoration(
            border: Border(
              top: index == 0
                  ? const BorderSide(color: Color(0xFFF9F8EB), width: 1)
                  : BorderSide.none,
              left: const BorderSide(color: Color(0xFFF9F8EB), width: 1),
              bottom: BorderSide.none,
              right: BorderSide.none,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      right: const BorderSide(
                        color: Color(0xFFF9F8EB),
                        width: 1,
                      ),
                      bottom: isLastRow
                          ? const BorderSide(color: Color(0xFFF9F8EB), width: 1)
                          : const BorderSide(
                              color: Color(0xFFF9F8EB),
                              width: 1,
                            ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      customerData[index]['label']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF9F8EB),
                        letterSpacing: -0.15,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F8EB),
                      border: Border(
                        right: const BorderSide(
                          color: Color(0xFFF9F8EB),
                          width: 1,
                        ),
                        bottom: isLastRow
                            ? const BorderSide(
                                color: Color(0xFFF9F8EB),
                                width: 1,
                              )
                            : const BorderSide(
                                color: Color(0xFF383743),
                                width: 1,
                              ),
                      ),
                    ),
                    child: Text(
                      customerData[index]['value']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF383743),
                        letterSpacing: -0.15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
