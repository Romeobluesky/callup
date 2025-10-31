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
    final phoneNumber = widget.customer['customerPhone'] ?? widget.customer['customer_phone'] ?? '';

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

  String _formatReservation(dynamic date, dynamic time) {
    if (date == null && time == null) return '';
    if (date == null) return time.toString();
    if (time == null) return date.toString();
    return '$date    $time';
  }

  String _extractDate(dynamic dateTime) {
    if (dateTime == null) return '';
    final dateStr = dateTime.toString();

    // ISO 8601 형식: "2025-10-31T14:30:00" → "2025-10-31"
    if (dateStr.contains('T')) {
      return dateStr.split('T')[0];
    }

    // 공백 구분 형식: "2025-10-24 14:30:00" → "2025-10-24"
    if (dateStr.contains(' ')) {
      return dateStr.split(' ')[0];
    }

    // 날짜만 있는 경우: "2025-10-24" → "2025-10-24"
    return dateStr;
  }

  List<Widget> _buildCallHistoryRows() {
    final callHistory = widget.customer['callHistory'] as List<dynamic>?;
    if (callHistory == null || callHistory.isEmpty) return [];

    return callHistory.map((history) {
      final historyMap = history as Map<String, dynamic>;
      return Row(
        children: [
          Expanded(
            flex: 35,
            child: _buildHistoryCell(
              _extractDate(historyMap['callDateTime']),
              isFirst: true
            )
          ),
          Expanded(
            flex: 30,
            child: _buildHistoryCell(historyMap['callDuration'] ?? '')
          ),
          Expanded(
            flex: 35,
            child: _buildHistoryCell(
              historyMap['callResult'] ?? '',
              isLast: true
            )
          ),
        ],
      );
    }).toList();
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
                      '제목 : ${widget.customer['eventName'] ?? widget.customer['event_name'] ?? ''}     #${widget.customer['customerId'] ?? widget.customer['customer_id'] ?? ''}',
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
                      '분배날짜 : ${widget.customer['uploadDate'] ?? widget.customer['created_at']?.toString().substring(0, 10) ?? ''}',
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
                      _buildTableValue(
                        widget.customer['customerPhone'] ?? widget.customer['customer_phone'] ?? '',
                        valueWidth,
                        isFirst: true
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTableLabel('고객정보1', labelWidth),
                      _buildTableValue(
                        widget.customer['customerInfo1'] ?? widget.customer['customer_info1'] ?? widget.customer['info1'] ?? '',
                        valueWidth
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTableLabel('고객정보2', labelWidth),
                      _buildTableValue(
                        widget.customer['customerInfo2'] ?? widget.customer['customer_info2'] ?? widget.customer['info2'] ?? '',
                        valueWidth
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTableLabel('고객정보3', labelWidth),
                      _buildTableValue(
                        widget.customer['customerInfo3'] ?? widget.customer['customer_info3'] ?? widget.customer['info3'] ?? '',
                        valueWidth
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTableLabel('디비상태', labelWidth),
                      _buildTableValue(
                        widget.customer['dataStatus'] ?? widget.customer['data_status'] ?? '미사용',
                        valueWidth
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTableLabel('통화결과', labelWidth),
                      _buildTableValue(
                        widget.customer['callResult'] ?? widget.customer['call_result'] ?? '',
                        valueWidth
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTableLabel('상담결과', labelWidth),
                      _buildTableValue(
                        widget.customer['consultationResult'] ?? widget.customer['consultation_result'] ?? '',
                        valueWidth
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTableLabel('통화예약', labelWidth),
                      _buildTableValue(
                        _formatReservation(
                          widget.customer['reservationDate'],
                          widget.customer['reservationTime']
                        ),
                        valueWidth
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTableLabel('메모', labelWidth, isLarge: true),
                      _buildTableValue(
                        widget.customer['memo'] ?? '',
                        valueWidth,
                        isLarge: true
                      ),
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
                  // 통화 이력 표시 (API에서 제공되는 경우)
                  if (widget.customer['callHistory'] != null)
                    ..._buildCallHistoryRows()
                  else if (widget.customer['callDateTime'] != null)
                    // 단일 통화 기록이 있는 경우
                    Row(
                      children: [
                        Expanded(
                          flex: 35,
                          child: _buildHistoryCell(
                            _extractDate(widget.customer['callDateTime']),
                            isFirst: true
                          )
                        ),
                        Expanded(
                          flex: 30,
                          child: _buildHistoryCell(
                            widget.customer['callDuration'] ?? ''
                          )
                        ),
                        Expanded(
                          flex: 35,
                          child: _buildHistoryCell(
                            widget.customer['callResult'] ?? widget.customer['callStatus'] ?? '',
                            isLast: true
                          )
                        ),
                      ],
                    )
                  else
                    // 통화 기록이 없는 경우
                    Row(
                      children: [
                        Expanded(
                          flex: 35,
                          child: _buildHistoryCell('-', isFirst: true)
                        ),
                        Expanded(
                          flex: 30,
                          child: _buildHistoryCell('-')
                        ),
                        Expanded(
                          flex: 35,
                          child: _buildHistoryCell('미사용', isLast: true)
                        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
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
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.visible,
          maxLines: 1,
        ),
      ),
    );
  }
}
