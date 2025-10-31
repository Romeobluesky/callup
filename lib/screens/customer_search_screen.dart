import 'package:flutter/material.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import '../widgets/customer_detail_popup.dart';
import '../services/api/customer_api_service.dart';
import 'dashboard_screen.dart';
import 'auto_call_screen.dart';
import 'stats_screen.dart';
import 'signup_screen.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> with WidgetsBindingObserver {
  bool _isOn = false;
  final int _selectedIndex = 2; // 고객관리 탭 선택됨
  final TextEditingController _searchController = TextEditingController();

  // API에서 로드한 데이터
  List<Map<String, dynamic>> _customerData = [];
  List<Map<String, dynamic>> _filteredCustomerData = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCustomerData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 다시 활성화되면 데이터 새로고침
    if (state == AppLifecycleState.resumed) {
      _loadCustomerData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 표시될 때마다 새로고침
    // (다른 화면에서 pushReplacement로 돌아올 때도 작동)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadCustomerData();
      }
    });
  }

  // API에서 고객 데이터 로드
  Future<void> _loadCustomerData({String? searchQuery}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await CustomerApiService.searchCustomers(
        name: searchQuery,
        phone: searchQuery,
        eventName: searchQuery,
        callResult: searchQuery,
        page: _currentPage,
        limit: 50,
      );

      if (!mounted) return;

      if (result['requireLogin'] == true) {
        // JWT 토큰 만료
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 만료되었습니다.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignUpScreen()),
        );
        return;
      }

      if (result['success'] == true) {
        final customers = result['customers'] as List<dynamic>;
        final pagination = result['pagination'] as Map<String, dynamic>;

        setState(() {
          _customerData = customers.map((c) => c as Map<String, dynamic>).toList();
          _filteredCustomerData = _customerData;
          _totalPages = pagination['totalPages'] ?? 1;
          _isLoading = false;
        });

        debugPrint('고객 데이터 로드 완료: ${customers.length}개');
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? '데이터 로드 실패')),
          );
        }
      }
    } catch (e) {
      debugPrint('고객 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('네트워크 오류: $e')),
        );
      }
    }
  }

  // 검색 필터링 (API 호출)
  void _filterCustomers(String query) {
    debugPrint('검색어: "$query"');

    // 검색 시 페이지를 1로 리셋
    setState(() {
      _currentPage = 1;
    });

    // API로 검색 수행
    _loadCustomerData(searchQuery: query.isEmpty ? null : query);
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

                  // 페이지 정보
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_customerData.length}개 고객',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        if (_totalPages > 1)
                          Text(
                            '$_currentPage / $_totalPages 페이지',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Customer List
                  Expanded(child: _buildCustomerList()),

                  // 페이지네이션 버튼
                  if (_totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 이전 페이지
                          IconButton(
                            onPressed: _currentPage > 1 ? () {
                              setState(() {
                                _currentPage--;
                              });
                              _loadCustomerData(searchQuery: _searchController.text.isEmpty ? null : _searchController.text);
                            } : null,
                            icon: Icon(
                              Icons.chevron_left,
                              color: _currentPage > 1 ? Colors.white : Colors.white.withValues(alpha: 0.3),
                            ),
                          ),

                          // 페이지 번호
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF0756),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '$_currentPage / $_totalPages',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          // 다음 페이지
                          IconButton(
                            onPressed: _currentPage < _totalPages ? () {
                              setState(() {
                                _currentPage++;
                              });
                              _loadCustomerData(searchQuery: _searchController.text.isEmpty ? null : _searchController.text);
                            } : null,
                            icon: Icon(
                              Icons.chevron_right,
                              color: _currentPage < _totalPages ? Colors.white : Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
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
    // API 응답 필드 매핑
    // 프로덕션 서버: camelCase (customerId, name, phone, info1, status, dbTitle, dbDate)
    // 로컬 서버: snake_case (customer_id, customer_name, customer_phone, data_status)
    final customerId = customer['customerId'] ?? customer['customer_id'];
    final dbId = customer['dbId'] ?? customer['db_id'];
    final eventName = customer['dbTitle'] ?? customer['event_name'] ?? customer['db_title'] ?? '';
    final customerPhone = customer['phone'] ?? customer['customer_phone'] ?? '';
    final customerName = customer['name'] ?? customer['customer_name'] ?? '';
    final customerInfo1 = customer['info1'] ?? customer['customerInfo1'] ?? customer['customer_info1'];
    final customerInfo2 = customer['info2'] ?? customer['customerInfo2'] ?? customer['customer_info2'];
    final customerInfo3 = customer['info3'] ?? customer['customerInfo3'] ?? customer['customer_info3'];
    final dataStatus = customer['status'] ?? customer['callStatus'] ?? customer['data_status'] ?? '미사용';
    final uploadDate = _formatUploadDate(customer['dbDate'] ?? customer['date'] ?? customer['created_at']);

    // 통화 관련 정보 (camelCase 우선, snake_case 폴백)
    // ⚠️ 프로덕션 서버에는 아직 통화 관련 필드가 없을 수 있음
    final callResult = customer['callResult'] ?? customer['call_result'];
    final callDateTime = customer['callDateTime'] ?? customer['call_datetime'];
    final callDuration = customer['callDuration'] ?? customer['call_duration'];
    final consultationResult = customer['consultationResult'] ?? customer['consultation_result'];
    final memo = customer['memo'];
    final hasAudio = customer['hasAudio'] == true || customer['hasAudio'] == 1 || customer['has_audio'] == true || customer['has_audio'] == 1;

    debugPrint('=== 고객 카드 데이터 확인 ===');
    debugPrint('customerId: $customerId, name: $customerName, phone: $customerPhone');
    debugPrint('eventName: $eventName, dataStatus: $dataStatus, uploadDate: $uploadDate');
    debugPrint('callResult: $callResult, callDateTime: $callDateTime, consultationResult: $consultationResult');

    return GestureDetector(
      onTap: () {
        // 백엔드 필드를 카멜케이스로 변환하여 팝업에 전달
        final normalizedCustomer = {
          'customerId': customerId,
          'dbId': dbId,
          'eventName': eventName,
          'customerPhone': customerPhone,
          'customerName': customerName,
          'customerInfo1': customerInfo1,
          'customerInfo2': customerInfo2,
          'customerInfo3': customerInfo3,
          'dataStatus': dataStatus,
          'callResult': callResult,
          'callDateTime': callDateTime,
          'callDuration': callDuration,
          'consultationResult': consultationResult,
          'memo': memo,
          'hasAudio': hasAudio,
          'uploadDate': uploadDate,
        };

        showDialog(
          context: context,
          builder: (context) => CustomerDetailPopup(customer: normalizedCustomer),
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
                    uploadDate,
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
                      eventName,
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
                    customerName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // 전화번호 (왼쪽)
                Text(
                  customerPhone,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                // 통화 상태 (왼쪽 고정폭)
                SizedBox(
                  width: 70,
                  child: Text(
                    dataStatus,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // 통화 일시 및 시간 (사용완료일 때만 표시)
                if (dataStatus == '사용완료' && callDateTime != null)
                  Expanded(
                    child: Text(
                      () {
                        final dateTime = _formatCallDateTime(callDateTime);
                        final duration = callDuration != null ? _formatCallTime(callDuration) : '';

                        // 통화시간이 있으면 함께 표시
                        if (duration.isNotEmpty && duration != '00:00:00') {
                          return '$dateTime  $duration';
                        }
                        return dateTime;
                      }(),
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

          // 통화결과 및 상담결과 (사용완료일 때만 표시)
          if (dataStatus == '사용완료')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  // 통화결과 (있을 때만 표시)
                  if (callResult != null && callResult.toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        callResult.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFCDDD),
                        ),
                      ),
                    ),
                  // 간격
                  if (callResult != null && callResult.toString().isNotEmpty && consultationResult != null && consultationResult.toString().isNotEmpty)
                    const SizedBox(width: 8),
                  // 상담결과 (있을 때만 표시)
                  if (consultationResult != null && consultationResult.toString().isNotEmpty)
                    Expanded(
                      child: Text(
                        consultationResult.toString().length > 15
                            ? '${consultationResult.toString().substring(0, 15)}...'
                            : consultationResult.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // 메모 및 녹취 아이콘
          if (memo != null && memo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  // 메모 (10자 초과 시 말줄임표)
                  Expanded(
                    child: Text(
                      '메모: ${memo.length > 10 ? '${memo.substring(0, 10)}...' : memo}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // 녹취 아이콘 (hasAudio가 실제로 true인 경우만)
                  if (hasAudio)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.volume_up,
                        color: Color(0xFFFFCDDD),
                        size: 26,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      ),
    );
  }

  // 통화 일시를 한국 시간 기준으로 포맷 (2025-10-31 14:30)
  String _formatCallDateTime(dynamic callDateTime) {
    if (callDateTime == null) return '';

    try {
      DateTime dt;
      if (callDateTime is String) {
        // 빈 문자열 체크
        String dateStr = callDateTime.trim();
        if (dateStr.isEmpty) return '';

        // ISO 8601 형식 (2025-10-31T14:30:00Z 또는 2025-10-31T14:30:00.000Z)
        if (dateStr.contains('T')) {
          dt = DateTime.parse(dateStr);
        }
        // 공백 구분 형식 (2025-10-31 14:30:00)
        else if (dateStr.contains(' ')) {
          dt = DateTime.parse(dateStr.replaceAll(' ', 'T'));
        }
        // 날짜만 있는 경우 (2025-10-31)
        else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
          dt = DateTime.parse('${dateStr}T00:00:00');
        }
        else {
          // 빈 문자열이 아닌 경우만 로그 출력
          if (dateStr.isNotEmpty) {
            debugPrint('지원되지 않는 날짜 형식: "$dateStr"');
          }
          return '';
        }
      } else if (callDateTime is DateTime) {
        dt = callDateTime;
      } else {
        return '';
      }

      // 이미 로컬 시간이면 그대로, UTC이면 KST로 변환
      final kst = dt.isUtc ? dt.add(const Duration(hours: 9)) : dt;

      // 2025-10-31 14:30 형태로 포맷
      return '${kst.year}-${kst.month.toString().padLeft(2, '0')}-${kst.day.toString().padLeft(2, '0')} '
             '${kst.hour.toString().padLeft(2, '0')}:${kst.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint('통화 일시 포맷 오류: $e (입력값: "$callDateTime")');
      return '';
    }
  }

  // 통화 시간을 00:00:00 형태로 포맷 (24시간)
  String _formatCallTime(dynamic callDuration) {
    if (callDuration == null) return '';

    try {
      if (callDuration is String) {
        // 이미 00:00:00 형태면 그대로 반환
        if (RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(callDuration)) {
          return callDuration;
        }

        // 숫자만 있는 경우 초로 변환
        final seconds = int.tryParse(callDuration);
        if (seconds != null) {
          final hours = seconds ~/ 3600;
          final minutes = (seconds % 3600) ~/ 60;
          final secs = seconds % 60;
          return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
        }
      } else if (callDuration is int) {
        // 초 단위로 전달된 경우
        final hours = callDuration ~/ 3600;
        final minutes = (callDuration % 3600) ~/ 60;
        final secs = callDuration % 60;
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
      }

      return '';
    } catch (e) {
      debugPrint('통화 시간 포맷 오류: $e');
      return '';
    }
  }

  // 업로드 날짜를 한국 시간 기준으로 포맷 (2025-10-24)
  String _formatUploadDate(dynamic uploadDate) {
    if (uploadDate == null) return '';

    try {
      DateTime dt;
      if (uploadDate is String) {
        String dateStr = uploadDate.trim();
        if (dateStr.isEmpty) return '';

        // ISO 8601 형식 (2025-10-24T15:00:00.000Z)
        if (dateStr.contains('T')) {
          dt = DateTime.parse(dateStr);
        }
        // 날짜만 있는 경우 (2025-10-24)
        else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
          dt = DateTime.parse('${dateStr}T00:00:00Z');  // UTC로 파싱
        }
        else {
          return dateStr.substring(0, 10);  // 그대로 반환
        }
      } else if (uploadDate is DateTime) {
        dt = uploadDate;
      } else {
        return '';
      }

      // UTC이면 KST로 변환 (UTC+9)
      final kst = dt.isUtc ? dt.add(const Duration(hours: 9)) : dt;

      // 2025-10-24 형태로 포맷
      return '${kst.year}-${kst.month.toString().padLeft(2, '0')}-${kst.day.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint('업로드 날짜 포맷 오류: $e (입력값: "$uploadDate")');
      return '';
    }
  }

}
