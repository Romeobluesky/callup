import 'package:flutter/material.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import '../services/db_manager.dart';
import 'dashboard_screen.dart';
import 'auto_call_screen.dart';

class DbListScreen extends StatefulWidget {
  const DbListScreen({super.key});

  @override
  State<DbListScreen> createState() => _DbListScreenState();
}

class _DbListScreenState extends State<DbListScreen> {
  bool _isOn = false;
  final int _selectedIndex = 0; // Home 탭 선택됨
  final TextEditingController _searchController = TextEditingController();

  // 샘플 DB 리스트 데이터
  final List<Map<String, dynamic>> _dbListData = [
    {
      'id': 'customers_20251020',
      'fileName': 'customers.csv',
      'date': '2025-10-20',
      'title': '테스트01_인천',
      'total': 8,
      'unused': 8,
    },
    {
      'date': '2025-10-14',
      'title': '이벤트01_251014',
      'total': 500,
      'unused': 250,
    },
    {'date': '2025-10-12', 'title': '서울경기_251012', 'total': 500, 'unused': 420},
    {
      'date': '2025-10-10',
      'title': '인천부평구_251010',
      'total': 500,
      'unused': 500,
    },
    {
      'date': '2025-10-07',
      'title': '이벤트01_251007',
      'total': 500,
      'unused': 500,
    },
    {
      'date': '2025-10-07',
      'title': '이벤트01_251007',
      'total': 500,
      'unused': 500,
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

                  // Search Bar & List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Search Bar
                        _buildSearchBar(),

                        const SizedBox(height: 20),

                        // DB List
                        _buildDbList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // START Button
                  _buildStartButton(),
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
                if (index != _selectedIndex) {
                  // 200ms fade+slide 애니메이션으로 대시보드로 이동
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 200),
                      pageBuilder: (context, animation, _) =>
                          const DashboardScreen(),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // Logo & Toggle
          Row(
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

          const SizedBox(height: 20),

          // Back Button & Title
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFFF9F8EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'DB 리스트',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF9F8EB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 372,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              decoration: const InputDecoration(
                hintText: '제목을 검색하세요.',
                hintStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0x80FFFFFF),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const Icon(Icons.search, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildDbList() {
    return Container(
      width: 372,
      height: 400,
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFDCDAD8).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    offset: const Offset(0, 4),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      '날짜',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF9F8EB),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      '제목',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF9F8EB),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      '총갯수/미사용',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF9F8EB),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // List Items
            Expanded(
              child: ListView.separated(
                itemCount: _dbListData.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _dbListData[index];
                  return _buildListItem(item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        // DB 선택
        DBManager().selectDB(item);

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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
              item['date'],
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
                  item['title'],
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
              '${item['total']}/${item['unused']}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF585667),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: 372,
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
                fontSize: 20,
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
