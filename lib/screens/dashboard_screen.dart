import 'package:flutter/material.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import '../services/db_manager.dart';
import 'customer_search_screen.dart';
import 'db_list_screen.dart';
import 'auto_call_screen.dart';
import 'stats_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isOn = true;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF585667),
      body: Stack(
        children: [
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

          // Bottom Navigation Bar
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
          // Date
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
                '2025-10-15 14:15:25',
                style: TextStyle(
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
                  const Text(
                    '김상담님',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF9F8EB),
                      letterSpacing: -0.15,
                    ),
                  ),
                ],
              ),
              const Text(
                '010-1234-5678',
                style: TextStyle(
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
              const Text(
                '오늘은 대박나는 날~!!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF9F8EB),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isOn = !_isOn;
                  });
                },
                child: Container(
                  width: 70,
                  height: 32,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
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
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _isOn
                                ? const Color(0xFFFFCDDD)
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Align(
                        alignment: _isOn
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _isOn ? 'on' : 'off',
                            style: const TextStyle(
                              fontSize: 12,
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
          const Text(
            '통화건 : 125건',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFCDDD),
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            '통화시간 : 05:20:15',
            style: TextStyle(
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
          _buildStatCard('연결성공 : 100건', cardWidth),
          _buildStatCard('연결실패 : 25건', cardWidth),
          _buildStatCard('재연락 : 10건', cardWidth),
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

    // 실제로는 customers.csv 파일 정보를 표시
    final List<Map<String, dynamic>> listData = [
      {
        'id': 'customers_20251020',
        'fileName': 'customers.csv',
        'date': '2025-10-20',
        'title': '테스트01_인천',
        'total': 8,
        'unused': 8,
        'count': '8/8'
      },
      {'date': '2025-10-14', 'title': '이벤트01_251014', 'total': 500, 'unused': 250, 'count': '500/250'},
      {'date': '2025-10-12', 'title': '서울경기_251012', 'total': 500, 'unused': 420, 'count': '500/420'},
      {'date': '2025-10-10', 'title': '인천부평구_251010', 'total': 500, 'unused': 500, 'count': '500/500'},
    ];

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
          ...List.generate(
            listData.length > 3 ? 3 : listData.length,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: index < 2 ? 8 : 0),
              child: GestureDetector(
                onTap: () {
                  // DB 선택
                  DBManager().selectDB(listData[index]);

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
                      // 날짜
                      Text(
                        listData[index]['date']!.toString(),
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
                            listData[index]['title']!.toString(),
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
                        listData[index]['count']!.toString(),
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
            ),
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
