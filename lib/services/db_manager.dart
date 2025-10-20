import 'package:flutter/material.dart';

/// DB 관리 서비스 (Singleton)
/// 선택된 DB 정보를 앱 전체에서 공유
class DBManager {
  // Singleton 인스턴스
  static final DBManager _instance = DBManager._internal();
  factory DBManager() => _instance;
  DBManager._internal();

  // 선택된 DB 정보
  Map<String, dynamic>? selectedDB;

  /// DB 선택
  void selectDB(Map<String, dynamic> db) {
    selectedDB = db;
    debugPrint('=== DB 선택됨 ===');
    debugPrint('파일명: ${db['fileName']}');
    debugPrint('제목: ${db['title']}');
    debugPrint('전체: ${db['total']}명');
  }

  /// 선택된 DB 초기화
  void clearSelection() {
    selectedDB = null;
    debugPrint('DB 선택 해제');
  }

  /// 선택된 DB가 있는지 확인
  bool hasSelection() {
    return selectedDB != null;
  }

  /// 선택된 DB의 파일명 가져오기
  String? getSelectedFileName() {
    return selectedDB?['fileName'];
  }

  /// 선택된 DB의 제목 가져오기
  String? getSelectedTitle() {
    return selectedDB?['title'];
  }

  /// 선택된 DB의 전체 고객 수 가져오기
  int? getSelectedTotal() {
    return selectedDB?['total'];
  }

  /// 선택된 DB의 미사용 고객 수 가져오기
  int? getSelectedUnused() {
    return selectedDB?['unused'];
  }
}
