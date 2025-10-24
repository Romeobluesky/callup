// API 설정 파일
// Base URL, 엔드포인트, 타임아웃 등 API 관련 상수 정의

class ApiConfig {
  // Base URL
  static const String baseUrl = 'https://api.autocallup.com';

  // API 엔드포인트
  static const String login = '/api/auth/login';
  static const String dashboard = '/api/dashboard';
  static const String userStatus = '/api/users/status';
  static const String dbLists = '/api/db-lists';
  static String dbListCustomers(int dbId) => '/api/db-lists/$dbId/customers';
  static const String autoCallNextCustomer = '/api/auto-call/next-customer';
  static const String callLogs = '/api/call-logs';
  static const String customerSearch = '/api/customers/search';
  static String customerDetail(int customerId) => '/api/customers/$customerId';
  static const String statistics = '/api/statistics';
  static const String csvUpload = '/api/db-lists/upload';
  static const String dbTest = '/api/db/test';

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
