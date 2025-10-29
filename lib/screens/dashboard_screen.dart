import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import '../services/db_manager.dart';
import '../services/api/dashboard_api_service.dart';
import 'customer_search_screen.dart';
import 'db_list_screen.dart';
import 'auto_call_screen.dart';
import 'stats_screen.dart';
import 'signup_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isOn = true;
  int _selectedIndex = 0;
  bool _isLoading = true;

  // API 데이터
  String _userName = '';
  String _userPhone = '';
  String _statusMessage = '';
  String _lastActiveTime = '';
  int _todayCallCount = 0;
  String _todayCallDuration = '00:00:00';
  int _successCount = 0;      // 통화성공 (call_result)
  int _absentCount = 0;       // 부재중 (call_result)
  int _recruitmentCount = 0;  // 가입유치 (consultation_result)
  List<dynamic> _dbLists = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 저장된 날짜와 현재 날짜 비교
      final savedDate = prefs.getString('active_date');
      final today = DateTime.now().toString().substring(0, 10); // YYYY-MM-DD

      // 날짜가 바뀌면 초기화 (다음날 출근 시)
      if (savedDate != today) {
        await prefs.remove('active_login_time');
        await prefs.remove('active_date');
        await prefs.remove('is_active_today');
      }

      final savedLoginTime = prefs.getString('active_login_time');
      final isActiveToday = prefs.getBool('is_active_today') ?? false;

      // API 호출
      final result = await DashboardApiService.getDashboard();

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];

        setState(() {
          // 사용자 정보
          _userName = data['user']['userName'] ?? '상담원';
          _userPhone = data['user']['userPhone'] ?? '-';
          _statusMessage = data['user']['userStatusMessage'] ?? '업무 중';

          // 출근 시간 표시 (출근 전에는 '-')
          _lastActiveTime = savedLoginTime ?? '-';

          // 토글 상태: 오늘 ON한 적이 있으면 ON 유지, 없으면 OFF
          _isOn = isActiveToday;

          // 오늘 통계
          _todayCallCount = data['todayStats']?['callCount'] ?? 0;
          _todayCallDuration = data['todayStats']?['callDuration'] ?? '00:00:00';

          // 통화 결과 통계
          _successCount = data['callStats']?['successCount'] ?? 0;        // 통화성공
          _absentCount = data['callStats']?['absentCount'] ?? 0;          // 부재중
          _recruitmentCount = data['callStats']?['recruitmentCount'] ?? 0; // 가입유치

          // DB 리스트 (최대 3개)
          _dbLists = (data['dbLists'] as List?)?.take(3).toList() ?? [];

          _isLoading = false;
        });
      } else if (result['requireLogin'] == true) {
        // 로그인 만료 → 로그인 화면으로 이동
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignUpScreen()),
          );
        }
      } else {
        // 에러 처리
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? '데이터 로딩 실패'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('네트워크 오류: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleUserStatus() async {
    // 낙관적 업데이트 (UI 먼저 변경)
    final previousState = _isOn;
    setState(() {
      _isOn = !_isOn;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toString().substring(0, 10); // YYYY-MM-DD

      // ON으로 변경: 출근 시간 기록
      if (_isOn) {
        final currentTime = DateTime.now().toString().substring(0, 19);
        await prefs.setString('active_login_time', currentTime);
        await prefs.setString('active_date', today);
        await prefs.setBool('is_active_today', true);
        setState(() {
          _lastActiveTime = currentTime;
        });
      } else {
        // OFF로 변경: 출근 상태만 해제 (시간은 유지)
        await prefs.setBool('is_active_today', false);
      }

      // API 호출
      final result = await DashboardApiService.toggleStatus(isOn: _isOn);

      if (result['success'] != true) {
        // 실패 시 원래 상태로 복구
        setState(() {
          _isOn = previousState;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? '상태 업데이트 실패'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 에러 시 원래 상태로 복구
      setState(() {
        _isOn = previousState;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('네트워크 오류: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF585667),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0756)),
              ),
            )
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 95),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),

                    const SizedBox(height: 20),

                    // Consultant Card
                    _buildConsultantCard(),

                    const SizedBox(height: 20),

                    // Today's Statistics Card
                    _buildTodayStatsCard(),

                    const SizedBox(height: 20),

                    // Statistics Cards Row
                    _buildStatisticsRow(),

                    const SizedBox(height: 20),

                    // List Card
                    _buildListCard(),

                    const SizedBox(height: 30),

                    // START Button
                    _buildStartButton(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

          // Bottom Navigation Bar (로딩 중이 아닐 때만 표시)
          if (!_isLoading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNavigationBar(
              selectedIndex: _selectedIndex,
              onItemTapped: (index) {
                if (index == 1) {
                  // Auto Call 아이콘 클릭 시 Auto Call 페이지로 이동
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 200),
                      pageBuilder: (context, animation, _) =>
                          const AutoCallScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.1, 0.0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                    ),
                  );
                } else if (index == 2) {
                  // 고객관리 아이콘 클릭 시 고객 검색 페이지로 이동
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 200),
                      pageBuilder: (context, animation, _) =>
                          const CustomerSearchScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.1, 0.0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                    ),
                  );
                } else if (index == 3) {
                  // 현황 아이콘 클릭 시 통계 페이지로 이동
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 200),
                      pageBuilder: (context, animation, _) =>
                          const StatsScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.1, 0.0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                    ),
                  );
                } else {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'CallUp',
                style: TextStyle(
                  fontSize: 14,
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
                  fontSize: 10,
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
          Image.asset(
            'assets/icons/setting.png',
            width: 24,
            height: 24,
            color: const Color(0xFF383743),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultantCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.9;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(10),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Login Time
          Row(
            children: [
              Image.asset(
                'assets/icons/date.png',
                width: 20,
                height: 20,
                color: const Color(0xFF383743),
              ),
              const SizedBox(width: 10),
              const Text(
                '로그인시간',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF9F8EB),
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _isOn
                    ? (_lastActiveTime.isNotEmpty && _lastActiveTime != '-'
                        ? _lastActiveTime
                        : '출근')
                    : '미출근',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF9F8EB),
                  letterSpacing: -0.15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Name and Phone
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCDDD),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/icons/Profile.png',
                        width: 18,
                        height: 18,
                        color: const Color(0xFFFF0756),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$_userName님',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF9F8EB),
                      letterSpacing: -0.15,
                    ),
                  ),
                ],
              ),
              Text(
                _userPhone,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF9F8EB),
                  letterSpacing: -0.15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Status and Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _statusMessage.isNotEmpty
                      ? _statusMessage
                      : '상태 메시지 없음',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF9F8EB),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _toggleUserStatus,
                child: Container(
                  width: 70,
                  height: 34,
                  padding: const EdgeInsets.all(2.5),
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
                          width: 29,
                          height: 29,
                          decoration: const BoxDecoration(
                            color: Colors.white,
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
                              fontSize: 11,
                              color: Color(0xFFFFCDDD),
                              fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }

  Widget _buildTodayStatsCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.9;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(10),
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
      child: Row(
        children: [
          Image.asset(
            'assets/icons/stats.png',
            width: 24,
            height: 24,
            color: const Color(0xFF383743),
          ),
          const SizedBox(width: 10),
          const Text(
            '오늘은',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '통화건 : $_todayCallCount건',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFCDDD),
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '통화시간 : $_todayCallDuration',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFCDDD),
              letterSpacing: -0.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.9 - 40) / 3;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard('통화성공 : $_successCount건', cardWidth),
          _buildStatCard('부재중 : $_absentCount건', cardWidth),
          _buildStatCard('가입유치 : $_recruitmentCount건', cardWidth),
        ],
      ),
    );
  }

  Widget _buildStatCard(String text, double width) {
    // 텍스트를 ":" 기준으로 분리
    final parts = text.split(' : ');
    final label = parts[0];
    final value = parts.length > 1 ? parts[1] : '';

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8EB),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF585667),
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF585667),
              letterSpacing: -0.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.9;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
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
        children: [
          // List items (최대 3개만 표시)
          if (_dbLists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'DB 리스트가 없습니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFF9F8EB),
                ),
              ),
            )
          else
            ...List.generate(
              _dbLists.length > 3 ? 3 : _dbLists.length,
              (index) {
                final dbItem = _dbLists[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index < 2 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () {
                      // DB 선택
                      DBManager().selectDB({
                        'dbId': dbItem['dbId'],
                        'date': dbItem['date'],
                        'title': dbItem['title'],
                        'totalCount': dbItem['totalCount'],
                        'unusedCount': dbItem['unusedCount'],
                      });

                  // AutoCallScreen으로 이동
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 200),
                      pageBuilder: (context, animation, _) => const AutoCallScreen(),
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
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F8EB),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        offset: const Offset(0, 4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 날짜 (날짜만 표시, 시간 제거)
                          Text(
                            dbItem['date']?.toString().substring(0, 10) ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF585667),
                            ),
                          ),
                          // 제목
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              child: Text(
                                dbItem['title']?.toString() ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF585667),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                          // 갯수
                          Text(
                            '${dbItem['totalCount']}/${dbItem['unusedCount']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF585667),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
          // More button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                // DB 리스트 페이지로 이동
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 200),
                    pageBuilder: (context, animation, _) => const DbListScreen(),
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF524C8A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                elevation: 4,
              ),
              child: const Text(
                '리스트 더보기',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF9F8EB),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.9;

    return GestureDetector(
      onTap: () {
        // Handle START action
      },
      child: Container(
        width: cardWidth,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFFF0756),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'START',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward, color: Colors.white, size: 32),
          ],
        ),
      ),
    );
  }
}
