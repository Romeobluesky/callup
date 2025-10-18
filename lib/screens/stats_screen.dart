import 'package:flutter/material.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import 'dashboard_screen.dart';
import 'auto_call_screen.dart';
import 'customer_search_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isOn = false;
  final int _selectedIndex = 3;
  String _selectedPeriod = '오늘';

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
              _buildStatsCard(cardWidth),
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
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(-0.1, 0.0),
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
          } else if (index == 1) {
            // Auto Call
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 200),
                pageBuilder: (context, animation, _) => const AutoCallScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(-0.1, 0.0),
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
            // 고객관리
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 200),
                pageBuilder: (context, animation, _) =>
                    const CustomerSearchScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(-0.1, 0.0),
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
          }
          // index == 3은 현재 페이지(StatsScreen)이므로 아무 동작 안 함
        },
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
    );
  }

  Widget _buildStatsCard(double cardWidth) {
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
        children: [
          // 상담원 정보
          _buildInfoRow(),
          const SizedBox(height: 24),
          // 기간 선택
          _buildPeriodSelector(),
          const SizedBox(height: 24),
          // 통계 데이터
          _buildStatsTable(),
        ],
      ),
    );
  }

  Widget _buildInfoRow() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.9 - 40; // padding 20 * 2 제외
    final labelWidth = cardWidth * 0.24; // 24%
    final nameWidth = cardWidth * 0.52; // 52%
    final idWidth = cardWidth * 0.24; // 24%

    return Row(
      children: [
        _buildInfoCell('상담원', labelWidth, isHeader: true),
        _buildInfoCell('이상담', nameWidth),
        _buildInfoCell('#002', idWidth),
      ],
    );
  }

  Widget _buildInfoCell(String text, double width, {bool isHeader = false}) {
    return Container(
      width: width,
      height: 35,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF9F8EB), width: 1),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF9F8EB),
            letterSpacing: -0.15,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.9 - 40; // padding 20 * 2 제외
    final cellWidth = cardWidth / 4; // 전체를 4개로 균등 분할

    final periods = ['오늘', '이번주', '이번달', '전체'];

    return Row(
      children: [
        ...periods.asMap().entries.map((entry) {
          final index = entry.key;
          final period = entry.value;
          final isSelected = _selectedPeriod == period;
          final isLast = index == periods.length - 1;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPeriod = period;
              });
            },
            child: _buildPeriodCell(period, cellWidth, isSelected: isSelected, isLast: isLast),
          );
        }),
      ],
    );
  }

  Widget _buildPeriodCell(
    String text,
    double width, {
    bool isSelected = false,
    bool isLast = false,
  }) {
    return Container(
      width: width,
      height: 35,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFF0756) : Colors.transparent,
        border: Border(
          left: const BorderSide(color: Color(0xFFF9F8EB), width: 1),
          top: const BorderSide(color: Color(0xFFF9F8EB), width: 1),
          bottom: const BorderSide(color: Color(0xFFF9F8EB), width: 1),
          right: isLast
              ? const BorderSide(color: Color(0xFFF9F8EB), width: 1)
              : BorderSide.none,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF9F8EB),
            letterSpacing: -0.15,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsTable() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.9 - 40; // padding 20 * 2 제외
    final labelWidth = cardWidth * 0.48; // 48%

    final stats = [
      {'label': '통화시간', 'value': '15:02:45'},
      {'label': '통화건수', 'value': '250'},
      {'label': '통화성공', 'value': '120'},
      {'label': '통화실패', 'value': '130'},
      {'label': '가망고객', 'value': '52'},
      {'label': '재통화', 'value': '100'},
      {'label': '무응답', 'value': '30'},
      {'label': '분배DB', 'value': '1000'},
      {'label': '미사용DB', 'value': '320'},
    ];

    return Column(
      children: List.generate(stats.length, (index) {
        final isFirst = index == 0;

        return Container(
          decoration: BoxDecoration(
            border: Border(
              top: isFirst
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
                  width: labelWidth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Color(0xFFF9F8EB), width: 1),
                      bottom: BorderSide(color: Color(0xFFF9F8EB), width: 1),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      stats[index]['label'] as String,
                      style: const TextStyle(
                        fontSize: 12,
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9F8EB),
                      border: Border(
                        right: BorderSide(color: Color(0xFFF9F8EB), width: 1),
                        bottom: BorderSide(color: Color(0xFF383743), width: 1),
                      ),
                    ),
                    child: Text(
                      stats[index]['value'] as String,
                      style: const TextStyle(
                        fontSize: 12,
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
