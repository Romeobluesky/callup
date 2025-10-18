import 'package:flutter/material.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import 'dashboard_screen.dart';
import 'customer_search_screen.dart';
import 'stats_screen.dart';

class CallResultScreen extends StatefulWidget {
  final Map<String, dynamic> customer;
  final int callDuration;

  const CallResultScreen({
    super.key,
    required this.customer,
    required this.callDuration,
  });

  @override
  State<CallResultScreen> createState() => _CallResultScreenState();
}

class _CallResultScreenState extends State<CallResultScreen> {
  bool _isOn = false;
  final int _selectedIndex = 1;

  String _callResult = '부재';
  String _consultResult = '부재';
  DateTime? _reservationDate;
  TimeOfDay? _reservationTime;
  final TextEditingController _memoController = TextEditingController();

  final List<String> _callResultOptions = ['부재', '통화성공', '통화실패', '번호오류'];
  final List<String> _consultResultOptions = ['부재', '가망고객', '비가망', '상담완료', '재상담'];

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  String _formatCallDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Transform.scale(
          scale: 0.85,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFFF0756),
                onPrimary: Color(0xFFF9F8EB),
                surface: Color(0xFF585667),
                onSurface: Color(0xFFF9F8EB),
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: Color(0xFF585667),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                actionsPadding: EdgeInsets.fromLTRB(8, 0, 8, 8),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF0756),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  minimumSize: const Size(80, 48),
                ),
              ),
              datePickerTheme: DatePickerThemeData(
                headerBackgroundColor: const Color(0xFFFF0756),
                headerForegroundColor: const Color(0xFFF9F8EB),
                backgroundColor: const Color(0xFF585667),
                dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFFF9F8EB);
                  }
                  return const Color(0xFFF9F8EB);
                }),
                dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFFFF0756);
                  }
                  return Colors.transparent;
                }),
                todayForegroundColor: WidgetStateProperty.all(const Color(0xFFFF0756)),
                todayBorder: const BorderSide(color: Color(0xFFFF0756), width: 2),
                headerHeadlineStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF9F8EB),
                ),
                headerHelpStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFF9F8EB),
                ),
                dayOverlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return const Color(0xFFFF0756).withValues(alpha: 0.1);
                  }
                  return Colors.transparent;
                }),
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _reservationDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Transform.scale(
          scale: 0.85,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFFF0756),
                onPrimary: Color(0xFFF9F8EB),
                surface: Color(0xFF585667),
                onSurface: Color(0xFFF9F8EB),
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: Color(0xFF585667),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                actionsPadding: EdgeInsets.fromLTRB(8, 0, 8, 8),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF0756),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  minimumSize: const Size(80, 48),
                ),
              ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: const Color(0xFF585667),
                hourMinuteTextColor: const Color(0xFFF9F8EB),
                hourMinuteColor: WidgetStateColor.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? const Color(0xFFFF0756)
                        : const Color(0xFF585667)),
                dayPeriodTextColor: const Color(0xFFF9F8EB),
                dayPeriodColor: WidgetStateColor.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? const Color(0xFFFF0756)
                        : const Color(0xFF585667)),
                dialHandColor: const Color(0xFFFF0756),
                dialBackgroundColor: const Color(0xFF383743),
                dialTextColor: WidgetStateColor.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? const Color(0xFFF9F8EB)
                        : const Color(0xFFF9F8EB)),
                entryModeIconColor: const Color(0xFFF9F8EB),
                helpTextStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF9F8EB),
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _reservationTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentPadding = 20.0;
    final cardPadding = 20.0;
    final availableWidth = screenWidth - (contentPadding * 2) - (cardPadding * 2);
    final labelWidth = availableWidth * 0.35;
    final buttonWidth = availableWidth * 0.20;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF585667),
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 95),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildCustomerInfoCard(labelWidth, buttonWidth),
                    const SizedBox(height: 20),
                    _buildReservationMemoCard(labelWidth, buttonWidth),
                    const SizedBox(height: 30),
                    _buildStartButton(),
                  ],
                ),
              ),
            ),
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
                }
              },
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          Row(
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
                    color: _isOn ? const Color(0xFFFF0756) : const Color(0xFF383743),
                    borderRadius: BorderRadius.circular(360),
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        alignment: _isOn ? Alignment.centerRight : Alignment.centerLeft,
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
                        alignment: _isOn ? Alignment.centerLeft : Alignment.centerRight,
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
                '통화 결과 입력',
                style: TextStyle(
                  fontSize: 12,
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

  Widget _buildCustomerInfoCard(double labelWidth, double buttonWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
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
            Row(
              children: [
                _buildTableCell('제목', labelWidth, isHeader: true, hasTopBorder: true),
                Expanded(
                  child: _buildTableCell(widget.customer['event'] ?? '', null, hasTopBorder: true, hasLeftBorder: false),
                ),
              ],
            ),
            Row(
              children: [
                _buildTableCell('통화일자', labelWidth, isHeader: true),
                Expanded(
                  child: _buildTableCell(DateTime.now().toString().substring(0, 10), null, hasLeftBorder: false),
                ),
              ],
            ),
            Row(
              children: [
                _buildTableCell('통화시간', labelWidth, isHeader: true),
                Expanded(
                  child: _buildTableCell(_formatCallDuration(widget.callDuration), null, hasLeftBorder: false),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow('전화번호', widget.customer['phone'] ?? '', labelWidth, isFirst: true, valueColor: const Color(0xFF383743)),
            _buildInfoRow('고객정보1', widget.customer['name'] ?? '', labelWidth),
            _buildInfoRow('고객정보2', '인천 부평구', labelWidth),
            _buildInfoRow('고객정보3', '쿠팡 이벤트', labelWidth),
            _buildInfoRow('고객정보4', '#102354', labelWidth),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildTableCell('통화결과', labelWidth, isHeader: true),
                          Expanded(child: _buildDropdown(_callResult, _callResultOptions, (value) {
                            setState(() {
                              _callResult = value!;
                            });
                          })),
                        ],
                      ),
                      Row(
                        children: [
                          _buildTableCell('상담결과', labelWidth, isHeader: true),
                          Expanded(child: _buildDropdown(_consultResult, _consultResultOptions, (value) {
                            setState(() {
                              _consultResult = value!;
                            });
                          })),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildButton('등록', buttonWidth, hasTopBorder: false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationMemoCard(double labelWidth, double buttonWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 280,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildTableCell('통화예약', labelWidth, isHeader: true, hasTopBorder: true),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectDate(context),
                              child: Container(
                                height: 35,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Color(0xFFF9F8EB)),
                                    right: BorderSide(color: Color(0xFFF9F8EB)),
                                    bottom: BorderSide(color: Color(0xFFF9F8EB)),
                                  ),
                                ),
                                child: Center(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: Color(0xFFF9F8EB), size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        _reservationDate != null
                                            ? '${_reservationDate!.year}-${_reservationDate!.month.toString().padLeft(2, '0')}-${_reservationDate!.day.toString().padLeft(2, '0')}'
                                            : '2025-10-30',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF9F8EB),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildTableCell('시간', labelWidth, isHeader: true),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(context),
                              child: Container(
                                height: 35,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: Color(0xFFF9F8EB)),
                                    bottom: BorderSide(color: Color(0xFFF9F8EB)),
                                  ),
                                ),
                                child: Center(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time, color: Color(0xFFF9F8EB), size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        _reservationTime != null
                                            ? '${_reservationTime!.hour.toString().padLeft(2, '0')}:${_reservationTime!.minute.toString().padLeft(2, '0')}'
                                            : '14:00',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF9F8EB),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildButton('알림', buttonWidth),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: labelWidth,
                  height: 117,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFF9F8EB)),
                  ),
                  child: const Center(
                    child: Text(
                      '메모',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF9F8EB),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 117,
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFF9F8EB)),
                        right: BorderSide(color: Color(0xFFF9F8EB)),
                        bottom: BorderSide(color: Color(0xFFF9F8EB)),
                      ),
                    ),
                    child: TextField(
                      controller: _memoController,
                      maxLines: null,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF9F8EB),
                      ),
                      decoration: const InputDecoration(
                        hintText: '메모를 입력하세요.',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0x80F9F8EB),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 62,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF524C8A),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        offset: const Offset(0, 4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '등록',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF9F8EB),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, double labelWidth, {bool isFirst = false, Color? valueColor}) {
    return Row(
      children: [
        Container(
          width: labelWidth,
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            border: Border(
              top: isFirst ? const BorderSide(color: Color(0xFFF9F8EB)) : BorderSide.none,
              left: const BorderSide(color: Color(0xFFF9F8EB)),
              right: const BorderSide(color: Color(0xFFF9F8EB)),
              bottom: const BorderSide(color: Color(0xFFF9F8EB)),
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF9F8EB),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 35,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              border: Border(
                top: isFirst ? const BorderSide(color: Color(0xFFF9F8EB)) : BorderSide.none,
                right: const BorderSide(color: Color(0xFFF9F8EB)),
                bottom: const BorderSide(color: Color(0xFFF9F8EB)),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? const Color(0xFFF9F8EB),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, double? width, {bool isHeader = false, bool hasTopBorder = false, bool hasRightBorder = true, bool hasLeftBorder = true}) {
    return Container(
      width: width,
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          top: hasTopBorder ? const BorderSide(color: Color(0xFFF9F8EB)) : BorderSide.none,
          left: hasLeftBorder ? const BorderSide(color: Color(0xFFF9F8EB)) : BorderSide.none,
          right: hasRightBorder ? const BorderSide(color: Color(0xFFF9F8EB)) : BorderSide.none,
          bottom: const BorderSide(color: Color(0xFFF9F8EB)),
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF9F8EB),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, double width, {bool hasTopBorder = true, bool hasRightBorder = true, bool hasBottomBorder = true, bool hasLeftBorder = false}) {
    return Container(
      width: width,
      height: 70,
      decoration: BoxDecoration(
        border: Border(
          top: hasTopBorder ? const BorderSide(color: Color(0xFFF9F8EB)) : BorderSide.none,
          left: hasLeftBorder ? const BorderSide(color: Color(0xFFF9F8EB)) : BorderSide.none,
          right: hasRightBorder ? const BorderSide(color: Color(0xFFF9F8EB)) : BorderSide.none,
          bottom: hasBottomBorder ? const BorderSide(color: Color(0xFFF9F8EB)) : BorderSide.none,
        ),
      ),
      child: Center(
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: double.infinity,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF524C8A),
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 4),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF9F8EB),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> options, Function(String?) onChanged) {
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFFF9F8EB)),
          bottom: BorderSide(color: Color(0xFFF9F8EB)),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFF9F8EB), size: 20),
          dropdownColor: const Color(0xFF585667),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF9F8EB),
          ),
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
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
            Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
