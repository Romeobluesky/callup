import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    // 필수값 검증 없이 바로 대시보드로 이동
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, _) => const DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0.0),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8EB),
      body: Stack(
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

          // Main content
          Center(
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
                          // ID input
                          _buildInputField(
                            controller: _idController,
                            label: 'ID :',
                          ),
                          const SizedBox(height: 20),

                          // NAME input
                          _buildInputField(
                            controller: _nameController,
                            label: 'NAME :',
                          ),
                          const SizedBox(height: 20),

                          // Password input
                          _buildInputField(
                            controller: _passwordController,
                            label: 'PASSWORD :',
                            obscureText: true,
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
        ],
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
