import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../services/api/auth_api_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _companyIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _agentNameController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _companyIdController.dispose();
    _passwordController.dispose();
    _agentNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    // 키보드 즉시 닫기 (오버플로우 방지)
    FocusScope.of(context).unfocus();

    // 필수값 검증
    if (_companyIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('업체 ID를 입력해주세요.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호를 입력해주세요.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_agentNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('상담원 이름을 입력해주세요.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 키보드가 완전히 닫힐 때까지 짧은 딜레이 (오버플로우 방지)
    await Future.delayed(const Duration(milliseconds: 150));

    // 로딩 표시
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF524C8A)),
      ),
    );

    try {
      // API 로그인 호출
      final result = await AuthApiService.login(
        companyLoginId: _companyIdController.text.trim(),
        companyPassword: _passwordController.text.trim(),
        userName: _agentNameController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // 로딩 다이얼로그 먼저 닫기
        Navigator.pop(context);

        // 키보드를 확실하게 닫기 (다시 올라오는 것 방지)
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();

        // 짧은 딜레이 후 부드럽게 대시보드로 전환
        await Future.delayed(const Duration(milliseconds: 150));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, animation, _) => const DashboardScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      } else {
        // 로그인 실패 → 로딩 닫고 메시지 표시
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인 정보를 확인하세요.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // 로딩 닫기
      Navigator.pop(context);

      // 네트워크 에러
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('네트워크 오류: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 화면 탭 시 키보드 숨기기
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F8EB),
        resizeToAvoidBottomInset: true,
        body: ClipRect(
          child: Stack(
            children: [
            // Background decorative circles
            Positioned(
            left: -355,
            top: 717,
            child: Container(
              width: 700,
              height: 700,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF1744).withValues(alpha: 0.9),
                    const Color(0xFFFF1744).withValues(alpha: 0.6),
                    const Color(0xFFFF1744).withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: -79,
            top: -334,
            child: Container(
              width: 700,
              height: 700,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF1744).withValues(alpha: 0.9),
                    const Color(0xFFFF1744).withValues(alpha: 0.6),
                    const Color(0xFFFF1744).withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Main content (스크롤 가능)
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                // Title section
                const Column(
                  children: [
                    Text(
                      'Call Up',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Mobile Autocall',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 143),

                // Input form section
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Input fields
                      Column(
                        children: [
                          // Company ID input
                          _buildInputField(
                            controller: _companyIdController,
                            label: '업체 ID :',
                          ),
                          const SizedBox(height: 20),

                          // Password input
                          _buildInputField(
                            controller: _passwordController,
                            label: '비밀번호 :',
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),

                          // Agent Name input
                          _buildInputField(
                            controller: _agentNameController,
                            label: '상담원 :',
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Remember me checkbox
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            },
                            child: Container(
                              width: 19,
                              height: 19,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F8EB),
                                border: Border.all(
                                  color: const Color(0xFF524C8A),
                                  width: 2,
                                ),
                              ),
                              child: _rememberMe
                                  ? const Icon(
                                      Icons.check,
                                      size: 15,
                                      color: Color(0xFF524C8A),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Text(
                            '로그인 상태 유지',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF585667),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Sign In button
                      GestureDetector(
                        onTap: _handleSignIn,
                        child: Container(
                          width: 116,
                          height: 58,
                          decoration: BoxDecoration(
                            color: const Color(0xFF524C8A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 19),
      decoration: BoxDecoration(
        color: const Color(0xFF585667).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
