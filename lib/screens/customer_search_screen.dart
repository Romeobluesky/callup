import 'package:flutter/material.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import '../widgets/customer_detail_popup.dart';
import 'dashboard_screen.dart';
import 'auto_call_screen.dart';
import 'stats_screen.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  bool _isOn = false;
  final int _selectedIndex = 2; // 고객관리 탭 선택됨
  final TextEditingController _searchController = TextEditingController();

  // 샘플 데이터
  final List<Map<String, dynamic>> _customerData = [
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
    },
    {
      'date': '2025-10-01',
      'event': '이벤트01_경기인천',
      'name': '정아영',
      'phone': '010-8521-7412',
      'callStatus': '부재중',
      'callDateTime': '2025-10-14  15:25:00',
      'callDuration': '00:11:24',
      'customerType': '가망고객',
      'memo': '안받음',
      'hasAudio': false,
    },
    {
      'date': '2025-10-01',
      'event': '이벤트01_경기인천',
      'name': '이민희',
      'phone': '010-5632-8547',
      'callStatus': '미사용',
      'callDateTime': null,
      'callDuration': null,
      'customerType': null,
      'memo': null,
      'hasAudio': false,
    },
    {
      'date': '2025-10-01',
      'event': '이벤트01_경기인천',
      'name': '박정민',
      'phone': '010-2541-3698',
      'callStatus': '미사용',
      'callDateTime': null,
      'callDuration': null,
      'customerType': null,
      'memo': null,
      'hasAudio': false,
    },
    {
      'date': '2025-10-01',
      'event': '이벤트01_경기인천',
      'name': '김민수',
      'phone': '010-3698-2541',
      'callStatus': '미사용',
      'callDateTime': null,
      'callDuration': null,
      'customerType': null,
      'memo': null,
      'hasAudio': false,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

                  // Search Bar
                  _buildSearchBar(),

                  const SizedBox(height: 20),

                  // Customer List
                  Expanded(child: _buildCustomerList()),
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
                } else if (index == 1) {
                  // Auto Call
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 200),
                      pageBuilder: (context, animation, _) => const AutoCallScreen(),
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
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
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

          // Toggle Switch
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
    );
  }

  Widget _buildSearchBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final searchBarWidth = screenWidth * 0.9;

    return Container(
      width: searchBarWidth,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: '고객명, 전화번호, 제목, 통화결과를 검색하세요.',
                hintStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                setState(() {
                  // 검색 로직 구현
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.7),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.9;

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _customerData.length,
      itemBuilder: (context, index) {
        final customer = _customerData[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < _customerData.length - 1 ? 10 : 0,
          ),
          child: Center(child: _buildCustomerCard(customer, cardWidth)),
        );
      },
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer, double width) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => CustomerDetailPopup(customer: customer),
        );
      },
      child: Container(
        width: width,
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
        children: [
          // 날짜 및 이벤트 (같은 줄)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                // 날짜 (왼쪽 고정폭)
                SizedBox(
                  width: 80,
                  child: Text(
                    customer['date'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // 이벤트 제목 (중앙)
                Expanded(
                  child: Center(
                    child: Text(
                      customer['event'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 이름 및 전화번호 (같은 줄)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                // 이름 (왼쪽 고정폭)
                SizedBox(
                  width: 70,
                  child: Text(
                    customer['name'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // 전화번호 (왼쪽)
                Text(
                  customer['phone'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // 통화 상태 및 통화 일시/시간 (같은 줄)
          if (customer['callDateTime'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  // 통화 상태 (왼쪽 고정폭)
                  SizedBox(
                    width: 70,
                    child: Text(
                      customer['callStatus'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // 통화 일시 및 시간 (왼쪽)
                  Text(
                    '${customer['callDateTime']}  ${customer['callDuration']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  // 통화 상태 (왼쪽 고정폭)
                  SizedBox(
                    width: 70,
                    child: Text(
                      customer['callStatus'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 고객 유형 및 메모 (같은 줄)
          if (customer['customerType'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  // 고객 유형 (왼쪽 고정폭)
                  SizedBox(
                    width: 70,
                    child: Text(
                      customer['customerType'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // 메모 (왼쪽)
                  Expanded(
                    child: Text(
                      customer['memo'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // 오디오 아이콘 (오른쪽)
                  if (customer['hasAudio'])
                    const Icon(
                      Icons.volume_up,
                      color: Color(0xFFFFCDDD),
                      size: 26,
                    ),
                ],
              ),
            ),
        ],
      ),
      ),
    );
  }
}
