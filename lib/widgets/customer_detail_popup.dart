import 'package:flutter/material.dart';
import '../screens/call_result_screen.dart';
import '../services/phone_service.dart';

class CustomerDetailPopup extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailPopup({super.key, required this.customer});

  @override
  State<CustomerDetailPopup> createState() => _CustomerDetailPopupState();
}

class _CustomerDetailPopupState extends State<CustomerDetailPopup> with WidgetsBindingObserver {
  DateTime? _callStartTime;
  bool _isCallInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isCallInProgress) {
      _handleCallEnded();
    }
  }

  Future<void> _makePhoneCall() async {
    final phoneNumber = widget.customer['phone'] ?? '';

    if (!PhoneService.isValidPhoneNumber(phoneNumber)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('유효하지 않은 전화번호입니다.')),
        );
      }
      return;
    }

    final success = await PhoneService.makePhoneCall(phoneNumber);

    if (success) {
      setState(() {
        _callStartTime = DateTime.now();
        _isCallInProgress = true;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전화를 걸 수 없습니다.')),
        );
      }
    }
  }

  void _handleCallEnded() {
    if (_callStartTime == null) return;

    final callDuration = DateTime.now().difference(_callStartTime!);
    final callDurationInSeconds = callDuration.inSeconds;

    setState(() {
      _isCallInProgress = false;
      _callStartTime = null;
    });

    Navigator.of(context).pop();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, _) => CallResultScreen(
          customer: widget.customer,
          callDuration: callDurationInSeconds,
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogPadding = 30.0;
    final contentPadding = 20.0;
    final availableWidth = screenWidth - (dialogPadding * 2) - (contentPadding * 2);
    final labelWidth = availableWidth * 0.35;
    final valueWidth = availableWidth * 0.65;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF585667),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _makePhoneCall,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF383743).withValues(alpha: 0.5),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '전화걸기',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF9F8EB),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.phone, color: const Color(0xFFFF0756), size: 24),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Icon(
                    Icons.close,
                    color: const Color(0xFFF9F8EB),
                    size: 30,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text(
                      '제목 : ${widget.customer['event']}     #102354',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text(
                      '분배날짜 : ${widget.customer['date']}',
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

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildTableLabel('전화번호', labelWidth, isFirst: true),
                      _buildTableValue(widget.customer['phone'], valueWidth, isFirst: true),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTableLabel('고객정보1', labelWidth),
                      _buildTableValue(widget.customer['name'], valueWidth),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTableLabel('고객정보2', labelWidth),
                      _buildTableValue(widget.customer['info2'] ?? '', valueWidth),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTableLabel('고객정보3', labelWidth),
                      _buildTableValue(widget.customer['info3'] ?? '', valueWidth),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTableLabel('통화결과', labelWidth),
                      _buildTableValue(widget.customer['callStatus'] ?? '미사용', valueWidth),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTableLabel('상담결과', labelWidth),
                      _buildTableValue(widget.customer['customerType'] ?? '', valueWidth),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTableLabel('통화예약', labelWidth),
                      _buildTableValue('2025-10-25    15:30:00', valueWidth),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTableLabel('메모', labelWidth, isLarge: true),
                      _buildTableValue(widget.customer['memo'] ?? '', valueWidth, isLarge: true),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(flex: 35, child: _buildHistoryHeader('통화일자', isFirst: true)),
                      Expanded(flex: 30, child: _buildHistoryHeader('통화시간')),
                      Expanded(flex: 35, child: _buildHistoryHeader('통화결과', isLast: true)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(flex: 35, child: _buildHistoryCell('2025-10-10', isFirst: true)),
                      Expanded(flex: 30, child: _buildHistoryCell('14:02:11')),
                      Expanded(flex: 35, child: _buildHistoryCell('부재', isLast: true)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(flex: 35, child: _buildHistoryCell('2025-10-01', isFirst: true)),
                      Expanded(flex: 30, child: _buildHistoryCell('12:25:23')),
                      Expanded(flex: 35, child: _buildHistoryCell('통화성공', isLast: true)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableLabel(
    String label,
    double width, {
    bool isFirst = false,
    bool isLarge = false,
  }) {
    return Container(
      width: width,
      height: isLarge ? 80 : 32,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          top: isFirst ? const BorderSide(color: Color(0xFFF9F8EB)) : BorderSide.none,
          left: const BorderSide(color: Color(0xFFF9F8EB)),
          bottom: const BorderSide(color: Color(0xFFF9F8EB)),
          right: const BorderSide(color: Color(0xFFF9F8EB)),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTableValue(
    String value,
    double width, {
    bool isFirst = false,
    bool isLarge = false,
  }) {
    return Container(
      width: width,
      height: isLarge ? 80 : 32,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border(
          top: isFirst ? const BorderSide(color: Color(0xFFF9F8EB)) : BorderSide.none,
          left: BorderSide.none,
          bottom: const BorderSide(color: Color(0xFFF9F8EB)),
          right: const BorderSide(color: Color(0xFFF9F8EB)),
        ),
      ),
      child: Align(
        alignment: isLarge ? Alignment.topLeft : Alignment.centerLeft,
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryHeader(
    String label, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          top: const BorderSide(color: Color(0xFFF9F8EB)),
          left: isFirst ? BorderSide.none : const BorderSide(color: Color(0xFFF9F8EB)),
          bottom: const BorderSide(color: Color(0xFFF9F8EB)),
          right: BorderSide.none,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCell(
    String value, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide.none,
          left: isFirst ? BorderSide.none : const BorderSide(color: Color(0xFFF9F8EB)),
          bottom: const BorderSide(color: Color(0xFFF9F8EB)),
          right: BorderSide.none,
        ),
      ),
      child: Center(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
