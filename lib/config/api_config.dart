// API 설정 파일 - v3.0.0 (업체 기반 시스템)
// Base URL, 엔드포인트, 타임아웃 등 API 관련 상수 정의

class ApiConfig {
  // Base URL
  static const String baseUrl = 'https://api.autocallup.com';

  // API 버전
  static const String apiVersion = 'v3.0.0';

  // 인증 API
  static const String authLogin = '/api/auth/login';
  static const String authRefresh = '/api/auth/refresh';
  static const String authLogout = '/api/auth/logout';

  // 대시보드 API
  static const String dashboard = '/api/dashboard';
  static const String dashboardStatus = '/api/dashboard/status';

  // DB 리스트 API
  static const String dbLists = '/api/db-lists';
  static String dbListToggle(int dbId) => '/api/db-lists/$dbId/toggle';

  // 자동 통화 API
  static const String autoCallStart = '/api/auto-call/start';
  static const String autoCallLog = '/api/auto-call/log';

  // 통화 결과 API
  static const String callResult = '/api/call-result';

  // 고객 관리 API
  static const String customersSearch = '/api/customers/search';
  static String customerDetail(int customerId) => '/api/customers/$customerId';

  // 통계 API
  static const String statistics = '/api/statistics';

  // 업체 관리자 API
  static const String companyAdminAgents = '/api/company-admin/agents';
  static String companyAdminAgentDelete(int userId) => '/api/company-admin/agents/$userId';
  static const String companyAdminStatistics = '/api/company-admin/statistics';
  static const String companyAdminDbAssign = '/api/company-admin/db-assign';

  // 슈퍼 관리자 API
  static const String adminCompanies = '/api/admin/companies';
  static String adminCompanyToggle(int companyId) => '/api/admin/companies/$companyId/toggle';
  static String adminCompanyDelete(int companyId) => '/api/admin/companies/$companyId';

  // 타임아웃 설정
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // HTTP 헤더
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
      };

  static Map<String, String> authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // 전체 URL 생성
  static String getUrl(String endpoint) => '$baseUrl$endpoint';
}
