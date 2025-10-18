import 'package:flutter/material.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import 'dashboard_screen.dart';
import 'stats_screen.dart';
import 'customer_search_screen.dart';

class AutoCallScreen extends StatefulWidget {
  const AutoCallScreen({super.key});

  @override
  State<AutoCallScreen> createState() => _AutoCallScreenState();
}

class _AutoCallScreenState extends State<AutoCallScreen>
    with SingleTickerProviderStateMixin {
  bool _isOn = false;
  final int _selectedIndex = 1;
  final String _callStatus = '발신중';
  bool _isAutoRunning = false; // Auto 실행 상태
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      onTap: () {
        setState(() {
          _isAutoRunning = !_isAutoRunning;
        });
      },
      child: Container(
        width: cardWidth,
        height: 60,
        decoration: BoxDecoration(
          color: _isAutoRunning
              ? Colors.white.withValues(alpha: 0.3)
              : const Color(0xFFFF0756),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isAutoRunning ? 'END' : 'START',
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
            child: const Text(
              'DB : 500/120',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF9F8EB),
                letterSpacing: -0.15,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          const Text(
            '제목 : 이벤트01_경기인천',
            style: TextStyle(
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
                    const Text(
                      '응답대기 : 10초 후 다음고객으로',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF9F8EB),
                        letterSpacing: -0.15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTable() {
    final List<Map<String, String>> customerData = [
      {'label': '전화번호', 'value': '010-1234-5678'},
      {'label': '고객정보1', 'value': '홍길동'},
      {'label': '고객정보2', 'value': '인천 부평구'},
      {'label': '고객정보3', 'value': '쿠팡 이벤트'},
      {'label': '고객정보4', 'value': ''},
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
