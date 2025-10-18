import 'package:flutter/material.dart';
import 'dart:async';
import 'call_result_screen.dart';

class CallScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CallScreen({super.key, required this.customer});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });

    // 5초 후 자동으로 통화 결과 입력 페이지로 이동
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _endCall();
      }
    });
  }

  void _endCall() {
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, _) => CallResultScreen(
          customer: widget.customer,
          callDuration: _seconds,
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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF585667),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 고객 이름
              Text(
                widget.customer['name'] ?? '',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF9F8EB),
                ),
              ),

              const SizedBox(height: 20),

              // 전화번호
              Text(
                widget.customer['phone'] ?? '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF9F8EB),
                ),
              ),

              const SizedBox(height: 60),

              // 통화 시간
              Text(
                _formatTime(_seconds),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF0756),
                ),
              ),

              const SizedBox(height: 100),

              // 통화 종료 버튼
              GestureDetector(
                onTap: _endCall,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF0756),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                '통화 종료',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF9F8EB),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
