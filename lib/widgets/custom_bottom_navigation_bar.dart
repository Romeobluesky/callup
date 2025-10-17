import 'package:flutter/material.dart';

/// 커스텀 하단 네비게이션 바 위젯
/// 노치(notch)가 있는 독특한 디자인의 네비게이션 바
class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const padding = 50.0;
    final availableWidth = screenWidth - padding * 2;
    final itemWidth = availableWidth / 4;
    final iconCenterOffset = itemWidth / 2;

    return SizedBox(
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 네비게이션 바 배경
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomPaint(
              size: Size(screenWidth, 75),
              painter: BottomNavPainter(
                selectedIndex: selectedIndex,
                itemWidth: itemWidth,
                backgroundColor: const Color(0xFFF9F8EB),
                padding: padding,
              ),
            ),
          ),
          // 네비게이션 아이템들
          ..._buildNavItems(padding, itemWidth, iconCenterOffset),
        ],
      ),
    );
  }

  /// 네비게이션 아이템(아이콘 + 타이틀) 생성
  List<Widget> _buildNavItems(
    double padding,
    double itemWidth,
    double iconCenterOffset,
  ) {
    final items = <Widget>[];
    const navData = [
      {'index': 0, 'icon': Icons.home, 'label': 'Home'},
      {'index': 1, 'icon': Icons.phone_in_talk, 'label': '오토콜'},
      {'index': 2, 'icon': Icons.person, 'label': '고객'},
      {'index': 3, 'icon': Icons.graphic_eq, 'label': '현황'},
    ];

    for (var data in navData) {
      final index = data['index'] as int;
      final icon = data['icon'] as IconData;
      final label = data['label'] as String;
      final selected = selectedIndex == index;
      final centerX = padding + (itemWidth * index) + iconCenterOffset;

      // 아이콘 추가
      items.add(
        Positioned(
          left: centerX - 32,
          bottom: selected ? 35 : 18,
          child: GestureDetector(
            onTap: () => onItemTapped(index),
            child: SizedBox(
              width: 64,
              height: 64,
              child: Center(
                child: selected
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9F8EB),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 24,
                          color: const Color(0xFFFF0756),
                        ),
                      )
                    : Icon(
                        icon,
                        size: 24,
                        color: const Color(0xFF585667),
                      ),
              ),
            ),
          ),
        ),
      );

      // 타이틀 추가
      items.add(
        Positioned(
          left: centerX - 32,
          bottom: 10,
          child: GestureDetector(
            onTap: () => onItemTapped(index),
            child: SizedBox(
              width: 64,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? const Color(0xFFFF0756)
                      : const Color(0xFF585667),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return items;
  }
}

/// 노치가 있는 네비게이션 바 배경을 그리는 CustomPainter
class BottomNavPainter extends CustomPainter {
  final int selectedIndex;
  final double itemWidth;
  final Color backgroundColor;
  final double padding;

  BottomNavPainter({
    required this.selectedIndex,
    required this.itemWidth,
    required this.backgroundColor,
    required this.padding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();

    // 노치 위치 계산
    final notchCenterX = padding + (itemWidth * selectedIndex) + (itemWidth / 2);
    const notchRadius = 32.0;
    const notchSpread = 30.0;
    final notchStartX = notchCenterX - notchRadius - notchSpread;

    // 왼쪽 하단에서 시작
    path.moveTo(0, size.height);

    // 왼쪽 상단 라운드
    path.lineTo(0, 40);
    path.quadraticBezierTo(0, 0, 40, 0);

    // 노치까지 연결
    if (notchStartX > 40) {
      // 일반 케이스: 왼쪽 끝에서 충분히 떨어진 경우
      path.lineTo(notchStartX, 0);
      path.cubicTo(
        notchCenterX - notchRadius - notchSpread * 0.5,
        0,
        notchCenterX - notchRadius - notchSpread * 0.2,
        5,
        notchCenterX - notchRadius,
        15,
      );
    } else {
      // 홈 버튼 선택: 왼쪽 끝과 가까운 경우 부드러운 연결
      const startX = 40.0;
      final endX = notchCenterX - notchRadius;
      path.cubicTo(
        startX + (endX - startX) * 0.5,
        0,
        startX + (endX - startX) * 0.7,
        5,
        endX,
        15,
      );
    }

    // 노치 오목한 부분 (원호)
    path.arcToPoint(
      Offset(notchCenterX + notchRadius, 15),
      radius: const Radius.circular(notchRadius + 2),
      clockwise: false,
    );

    // 노치 끝에서 오른쪽으로 연결
    final notchEndX = notchCenterX + notchRadius + notchSpread;
    if (notchEndX < size.width - 40) {
      // 일반 케이스: 오른쪽 끝에서 충분히 떨어진 경우
      path.cubicTo(
        notchCenterX + notchRadius + notchSpread * 0.2,
        5,
        notchCenterX + notchRadius + notchSpread * 0.5,
        0,
        notchEndX,
        0,
      );
      path.lineTo(size.width - 40, 0);
    } else {
      // 현황 버튼 선택: 오른쪽 끝과 가까운 경우 부드러운 연결
      final startX = notchCenterX + notchRadius;
      final endX = size.width - 40.0;
      path.cubicTo(
        startX + (endX - startX) * 0.3,
        5,
        startX + (endX - startX) * 0.5,
        0,
        endX,
        0,
      );
    }

    // 오른쪽 상단 라운드
    path.quadraticBezierTo(size.width, 0, size.width, 40);

    // 오른쪽 하단 라운드
    path.lineTo(size.width, size.height - 40);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - 40,
      size.height,
    );

    // 하단 직선
    path.lineTo(40, size.height);

    // 왼쪽 하단 라운드
    path.quadraticBezierTo(0, size.height, 0, size.height - 40);
    path.close();

    // 그림자와 배경 그리기
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BottomNavPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex;
  }
}
