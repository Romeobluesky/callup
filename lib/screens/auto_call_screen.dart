import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:charset_converter/charset_converter.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import '../services/auto_call_service.dart';
import '../services/db_manager.dart';
import '../services/phone_service.dart';
import '../services/overlay_service.dart';
import '../models/auto_call_state.dart';
import 'dashboard_screen.dart';
import 'stats_screen.dart';
import 'customer_search_screen.dart';
import 'call_result_screen.dart';

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
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  // 자동 전화 관련 상태
  Map<String, dynamic>? _currentCustomer;
  int _countdown = 5;
  String _progress = '0/0';
  List<Map<String, dynamic>> _customers = [];

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
    if (selectedDB != null) {
      await _loadCustomers();
      // 고객이 로드되면 첫 번째 고객 정보 표시
      if (_customers.isNotEmpty) {
        setState(() {
          _currentCustomer = _customers[0];
          _progress = '1/${_customers.length}';
        });
      }
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
            break;
          case AutoCallStatus.ringing:
            _callStatus = '응답대기';
            break;
          case AutoCallStatus.connected:
            _callStatus = '통화 연결';
            _navigateToCallResult();
            break;
          case AutoCallStatus.completed:
            _callStatus = '완료';
            _isAutoRunning = false;
            _showCompletionDialog();
            break;
          case AutoCallStatus.idle:
            _callStatus = '대기중';
            _isAutoRunning = false;
            _currentCustomer = null;
            _progress = '0/0';
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

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, _) => CallResultScreen(
          customer: _currentCustomer!,
          callDuration: 0,
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
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF585667),
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
            onPressed: () => Navigator.pop(context),
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

      final fileName = selectedDB['fileName'] ?? 'customers.csv';
      debugPrint('=== DB 로드 시작 ===');
      debugPrint('파일명: $fileName');
      debugPrint('제목: ${selectedDB['title']}');

      final ByteData bytes = await rootBundle.load('assets/test_data/$fileName');
      final Uint8List uint8list = bytes.buffer.asUint8List();
      final String csvString = await CharsetConverter.decode("EUC-KR", uint8list);

      List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);

      if (csvData.isEmpty) return;

      csvData.removeAt(0); // 헤더 제거

      setState(() {
        _customers = csvData.map((row) {
          String getValue(int index, [String defaultValue = '']) {
            if (index < row.length && row[index] != null) {
              return row[index].toString().trim();
            }
            return defaultValue;
          }

          return {
            'event': getValue(0),
            'phone': getValue(1),
            'name': getValue(2),
            'info2': getValue(3),
            'info3': getValue(4),
            'info4': getValue(5),
            'date': getValue(14, getValue(6, '2025-10-01')),
            'callStatus': getValue(7, '미사용'),
            'customerType': getValue(8).isEmpty ? null : getValue(8),
            'callDateTime': getValue(12).isEmpty ? null : getValue(12),
            'callDuration': getValue(13).isEmpty ? null : getValue(13),
            'memo': getValue(11).isEmpty ? null : getValue(11),
            'hasAudio': false,
            'uploadDate': getValue(14),
            'description': getValue(15),
          };
        }).toList();
      });

      debugPrint('고객 로드 완료: ${_customers.length}명');
    } catch (e) {
      debugPrint('고객 로드 오류: $e');
    }
  }

  Future<void> _startAutoCalling() async {
    try {
      // 오버레이 권한 확인
      final hasPermission = await OverlayService.checkOverlayPermission();
      debugPrint('오버레이 권한 상태: $hasPermission');

      if (!hasPermission) {
        // 권한 요청
        debugPrint('오버레이 권한 요청 중...');
        await OverlayService.requestOverlayPermission();

        // 권한 요청 후 다시 확인
        await Future.delayed(const Duration(milliseconds: 500));
        final permissionGranted = await OverlayService.checkOverlayPermission();

        if (!permissionGranted) {
          debugPrint('오버레이 권한이 거부되었습니다.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('오버레이 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      debugPrint('오버레이 권한 확인 완료');

      // 고객 데이터 로드
      if (_customers.isEmpty) {
        await _loadCustomers();
      }

      if (_customers.isEmpty) {
        debugPrint('고객 데이터가 없습니다.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('고객 데이터가 없습니다.')),
          );
        }
        return;
      }

      debugPrint('고객 데이터 로드 완료: ${_customers.length}명');

      setState(() {
        _isAutoRunning = true;
      });

      // AutoCallService 시작
      debugPrint('AutoCallService 시작');
      await AutoCallService().start(_customers);
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
        if (!_isAutoRunning) {
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
      {'label': '고객정보1', 'value': _currentCustomer?['name'] ?? '-'},
      {'label': '고객정보2', 'value': _currentCustomer?['info2'] ?? '-'},
      {'label': '고객정보3', 'value': _currentCustomer?['info3'] ?? '-'},
      {'label': '고객정보4', 'value': _currentCustomer?['info4'] ?? '-'},
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
