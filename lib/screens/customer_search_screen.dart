import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:charset_converter/charset_converter.dart';
import 'dart:typed_data';
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

  // CSV에서 로드한 데이터
  List<Map<String, dynamic>> _customerData = [];
  List<Map<String, dynamic>> _filteredCustomerData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  // CSV 파일에서 고객 데이터 로드
  Future<void> _loadCustomerData() async {
    try {
      debugPrint('=== CSV 로딩 시작 ===');

      // ByteData로 읽어서 EUC-KR 디코딩
      debugPrint('파일 읽기 시작: assets/test_data/customers.csv');
      final ByteData bytes = await rootBundle.load('assets/test_data/customers.csv');
      debugPrint('파일 크기: ${bytes.lengthInBytes} bytes');

      final Uint8List uint8list = bytes.buffer.asUint8List();

      // EUC-KR을 UTF-8로 변환
      debugPrint('EUC-KR → UTF-8 변환 시작');
      final String csvString = await CharsetConverter.decode("EUC-KR", uint8list);
      debugPrint('변환 완료, 문자열 길이: ${csvString.length}');

      // CSV 파싱
      debugPrint('CSV 파싱 시작');
      List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(
        csvString,
        eol: '\n',
        fieldDelimiter: ',',
      );
      debugPrint('파싱 완료: ${rowsAsListOfValues.length}행');

      if (rowsAsListOfValues.isEmpty) {
        debugPrint('경고: CSV 데이터가 비어있습니다');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      debugPrint('첫 번째 행 (헤더): ${rowsAsListOfValues[0]}');

      // 데이터 파싱 (헤더 스킵하고 인덱스로 직접 접근)
      // CSV 컬럼 순서: 제목, 전화번호, 고객정보1, 고객정보2, 고객정보3, 고객정보4, 날짜, 통화결과, 통화유형, 통화시간, 시간, 메모, 통화녹음, 통화시각, 파일업로드날짜, 데이터설명
      final List<Map<String, dynamic>> data = [];
      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        final row = rowsAsListOfValues[i];
        if (row.isEmpty || row.length < 7) continue;

        String getValue(int index, [String defaultValue = '']) {
          if (index < row.length) {
            String value = row[index].toString().trim();
            return (value.isEmpty || value == 'null') ? defaultValue : value;
          }
          return defaultValue;
        }

        String? getNullableValue(int index) {
          if (index < row.length) {
            String value = row[index].toString().trim();
            return (value.isEmpty || value == 'null') ? null : value;
          }
          return null;
        }

        // 필수 필드 매핑 (인덱스 기반)
        final customerData = {
          'event': getValue(0),           // 제목
          'phone': getValue(1),           // 전화번호
          'name': getValue(2),            // 고객정보1
          'info2': getValue(3),           // 고객정보2
          'info3': getValue(4),           // 고객정보3
          'info4': getValue(5),           // 고객정보4
          'date': getValue(14, getValue(6, '2025-10-01')), // 파일업로드날짜 (14번) 또는 날짜(6번) 폴백
          'callStatus': getValue(7, '미사용'), // 통화결과
          'customerType': getNullableValue(8), // 통화유형
          'callDateTime': getNullableValue(9) != null && getNullableValue(6) != null
              ? '${getValue(6)}  ${getValue(9)}'
              : null, // 날짜 + 통화시간
          'callDuration': getNullableValue(10), // 시간
          'memo': getNullableValue(11), // 메모
          'hasAudio': getValue(12) == 'true' || getValue(12) == '1', // 통화녹음
          'uploadDate': getValue(14), // 파일업로드날짜
          'description': getValue(15), // 데이터설명
        };

        data.add(customerData);
      }

      setState(() {
        _customerData = data;
        _filteredCustomerData = data;
        _isLoading = false;
      });

      // 디버깅: 로드된 데이터 확인
      debugPrint('CSV 로드 완료: ${data.length}개 고객');
      if (data.isNotEmpty) {
        debugPrint('첫 번째 고객: ${data[0]}');
      }
    } catch (e) {
      debugPrint('CSV 로드 에러: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 검색 필터링
  void _filterCustomers(String query) {
    debugPrint('검색어: "$query"');

    if (query.isEmpty) {
      setState(() {
        _filteredCustomerData = _customerData;
      });
      debugPrint('검색어 비어있음, 전체 표시: ${_customerData.length}개');
      return;
    }

    final filtered = _customerData.where((customer) {
      final name = (customer['name'] ?? '').toString().toLowerCase();
      final phone = (customer['phone'] ?? '').toString().toLowerCase();
      final event = (customer['event'] ?? '').toString().toLowerCase();
      final callStatus = (customer['callStatus'] ?? '').toString().toLowerCase();
      final searchLower = query.toLowerCase();

      final matches = name.contains(searchLower) ||
          phone.contains(searchLower) ||
          event.contains(searchLower) ||
          callStatus.contains(searchLower);

      return matches;
    }).toList();

    setState(() {
      _filteredCustomerData = filtered;
    });

    debugPrint('검색 결과: ${filtered.length}개');
  }

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

                  const SizedBox(height: 10),

                  // 디버그 정보
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Text(
                      '전체: ${_customerData.length}개 / 표시: ${_filteredCustomerData.length}개',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

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
                _filterCustomers(value);
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

    // 로딩 중일 때
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF0756),
        ),
      );
    }

    // 데이터가 없을 때
    if (_filteredCustomerData.isEmpty) {
      return const Center(
        child: Text(
          '검색 결과가 없습니다.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _filteredCustomerData.length,
      itemBuilder: (context, index) {
        final customer = _filteredCustomerData[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < _filteredCustomerData.length - 1 ? 10 : 0,
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
          // 업로드 날짜 및 이벤트 제목 (같은 줄)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                // 파일 업로드 날짜 (왼쪽 고정폭)
                SizedBox(
                  width: 80,
                  child: Text(
                    customer['date'] ?? '',
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
                      customer['event'] ?? '',
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
