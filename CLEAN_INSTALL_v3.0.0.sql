-- ============================================
-- CallUp Database Clean Install Script
-- Version: v3.0.0 (업체 계정 시스템)
-- ============================================

-- 주의: 이 스크립트는 기존 데이터를 모두 삭제합니다!
-- 개발 환경 또는 임시 데이터만 있는 환경에서만 사용하세요.

-- ============================================
-- STEP 1: 기존 테이블 및 트리거 완전 삭제
-- ============================================

SET FOREIGN_KEY_CHECKS = 0;

-- 기존 테이블 삭제
DROP TABLE IF EXISTS db_assignments;
DROP TABLE IF EXISTS statistics;
DROP TABLE IF EXISTS call_logs;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS db_lists;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS companies;

-- 백업 테이블도 삭제 (있다면)
DROP TABLE IF EXISTS users_backup_v2;
DROP TABLE IF EXISTS db_lists_backup_v2;
DROP TABLE IF EXISTS customers_backup_v2;
DROP TABLE IF EXISTS call_logs_backup_v2;
DROP TABLE IF EXISTS statistics_backup_v2;

-- 기존 트리거 삭제
DROP TRIGGER IF EXISTS after_customer_update;
DROP TRIGGER IF EXISTS after_call_log_insert;

SET FOREIGN_KEY_CHECKS = 1;


-- ============================================
-- STEP 2: 새 테이블 생성 (v3.0.0)
-- ============================================

-- 2-1. companies 테이블 (업체 계정)
CREATE TABLE companies (
    company_id INT PRIMARY KEY AUTO_INCREMENT,
    company_login_id VARCHAR(50) UNIQUE NOT NULL COMMENT '업체 로그인 ID',
    company_password VARCHAR(255) NOT NULL COMMENT '업체 비밀번호 (SHA2 해시)',
    company_name VARCHAR(100) NOT NULL COMMENT '업체명',
    max_agents INT DEFAULT 3 COMMENT '최대 상담원 수',
    is_active BOOLEAN DEFAULT TRUE COMMENT '활성화 상태 (결제 기반)',
    subscription_start_date DATE COMMENT '구독 시작일',
    subscription_end_date DATE COMMENT '구독 종료일',
    admin_name VARCHAR(50) COMMENT '관리자 이름',
    admin_phone VARCHAR(20) COMMENT '관리자 전화번호',
    admin_email VARCHAR(100) COMMENT '관리자 이메일',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_company_login (company_login_id),
    INDEX idx_company_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='업체 계정 정보';

-- 2-2. users 테이블 (상담원)
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    company_id INT NOT NULL COMMENT '업체 ID',
    user_name VARCHAR(50) NOT NULL COMMENT '상담원 이름',
    user_phone VARCHAR(20) COMMENT '상담원 전화번호',
    user_status_message VARCHAR(200) COMMENT '상태 메시지',
    is_active BOOLEAN DEFAULT TRUE COMMENT '활성화 여부',
    last_login_at TIMESTAMP NULL COMMENT '최종 로그인 시간',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(company_id),
    INDEX idx_users_company (company_id),
    INDEX idx_users_name (user_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='상담원 정보';

-- 2-3. db_lists 테이블 (DB 리스트)
CREATE TABLE db_lists (
    db_id INT PRIMARY KEY AUTO_INCREMENT,
    company_id INT NOT NULL COMMENT '업체 ID',
    db_title VARCHAR(200) NOT NULL COMMENT 'DB 제목',
    db_date DATE NOT NULL COMMENT 'DB 날짜',
    total_count INT DEFAULT 0 COMMENT '전체 고객 수',
    unused_count INT DEFAULT 0 COMMENT '미사용 고객 수',
    file_name VARCHAR(255) COMMENT '원본 파일명',
    is_active BOOLEAN DEFAULT TRUE COMMENT '활성화 여부 (ON/OFF)',
    upload_date DATE COMMENT '업로드 날짜',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(company_id),
    INDEX idx_db_lists_company (company_id),
    INDEX idx_db_date (db_date),
    INDEX idx_db_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='DB 리스트';

-- 2-4. customers 테이블 (고객 정보)
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    db_id INT NOT NULL COMMENT 'DB 리스트 ID',
    assigned_user_id INT NULL COMMENT '할당된 상담원 ID',

    -- CSV 기본 정보 (0-5번 컬럼)
    event_name VARCHAR(200) COMMENT '이벤트명',
    customer_phone VARCHAR(20) NOT NULL COMMENT '전화번호',
    customer_name VARCHAR(50) COMMENT '고객명',
    customer_info1 VARCHAR(200) COMMENT '고객정보1 (관리자 자유 입력)',
    customer_info2 VARCHAR(200) COMMENT '고객정보2 (관리자 자유 입력)',
    customer_info3 VARCHAR(200) COMMENT '고객정보3 (관리자 자유 입력)',

    -- CSV 통화 관련 정보 (7-16번 컬럼)
    data_status ENUM('미사용', '사용완료') DEFAULT '미사용' COMMENT 'DB 사용 여부',
    call_result VARCHAR(100) COMMENT '통화 결과',
    consultation_result TEXT COMMENT '상담 결과',
    memo TEXT COMMENT '메모',
    call_datetime DATETIME COMMENT '통화 일시',
    call_start_time TIME COMMENT '통화 시작 시간',
    call_end_time TIME COMMENT '통화 종료 시간',
    call_duration VARCHAR(20) COMMENT '통화 시간 (HH:MM:SS)',
    reservation_date DATE COMMENT '통화 예약일',
    reservation_time TIME COMMENT '통화 예약 시간',

    -- CSV 메타 정보 (17-18번 컬럼)
    upload_date DATE COMMENT '업로드 날짜',
    last_modified_date DATETIME COMMENT '최종 수정일',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (db_id) REFERENCES db_lists(db_id),
    FOREIGN KEY (assigned_user_id) REFERENCES users(user_id),
    INDEX idx_customer_db (db_id),
    INDEX idx_customer_phone (customer_phone),
    INDEX idx_customer_status (data_status),
    INDEX idx_customer_reservation (reservation_date),
    INDEX idx_customers_assigned_user (assigned_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='고객 정보';

-- 2-5. call_logs 테이블 (통화 로그)
CREATE TABLE call_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    company_id INT NOT NULL COMMENT '업체 ID',
    user_id INT NOT NULL COMMENT '상담원 ID',
    customer_id INT NOT NULL COMMENT '고객 ID',
    db_id INT NOT NULL COMMENT 'DB 리스트 ID',

    call_datetime DATETIME NOT NULL COMMENT '통화 일시',
    call_start_time TIME COMMENT '통화 시작 시간',
    call_end_time TIME COMMENT '통화 종료 시간',
    call_duration VARCHAR(20) COMMENT '통화 시간 (HH:MM:SS)',
    call_result VARCHAR(100) COMMENT '통화 결과',
    consultation_result TEXT COMMENT '상담 결과',
    memo TEXT COMMENT '메모',
    has_audio BOOLEAN DEFAULT FALSE COMMENT '녹음 파일 존재 여부',
    audio_file_path VARCHAR(500) COMMENT '녹음 파일 경로',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(company_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (db_id) REFERENCES db_lists(db_id),
    INDEX idx_call_logs_company (company_id),
    INDEX idx_call_user (user_id),
    INDEX idx_call_customer (customer_id),
    INDEX idx_call_datetime (call_datetime)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='통화 로그';

-- 2-6. statistics 테이블 (통계 정보)
CREATE TABLE statistics (
    stat_id INT PRIMARY KEY AUTO_INCREMENT,
    company_id INT NOT NULL COMMENT '업체 ID',
    user_id INT NOT NULL COMMENT '상담원 ID',
    stat_date DATE NOT NULL COMMENT '통계 날짜',

    total_call_time TIME DEFAULT '00:00:00' COMMENT '총 통화 시간',
    total_call_count INT DEFAULT 0 COMMENT '총 통화 건수',
    success_count INT DEFAULT 0 COMMENT '통화 성공 건수',
    failed_count INT DEFAULT 0 COMMENT '통화 실패 건수',
    callback_count INT DEFAULT 0 COMMENT '재통화 건수',
    no_answer_count INT DEFAULT 0 COMMENT '무응답 건수',
    assigned_db_count INT DEFAULT 0 COMMENT '분배된 DB 수',
    unused_db_count INT DEFAULT 0 COMMENT '미사용 DB 수',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(company_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    UNIQUE KEY unique_user_date (company_id, user_id, stat_date),
    INDEX idx_statistics_company (company_id),
    INDEX idx_stat_user (user_id),
    INDEX idx_stat_date (stat_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='통계 정보';

-- 2-7. db_assignments 테이블 (DB 할당 추적)
CREATE TABLE db_assignments (
    assignment_id INT PRIMARY KEY AUTO_INCREMENT,
    db_id INT NOT NULL COMMENT 'DB 리스트 ID',
    user_id INT NOT NULL COMMENT '상담원 ID',
    company_id INT NOT NULL COMMENT '업체 ID',
    assigned_count INT DEFAULT 0 COMMENT '할당된 고객 수',
    completed_count INT DEFAULT 0 COMMENT '완료된 고객 수',
    in_progress_count INT DEFAULT 0 COMMENT '진행 중인 고객 수',
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (db_id) REFERENCES db_lists(db_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (company_id) REFERENCES companies(company_id),
    UNIQUE KEY unique_assignment (db_id, user_id),
    INDEX idx_assignment_db (db_id),
    INDEX idx_assignment_user (user_id),
    INDEX idx_assignment_company (company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='DB 할당 추적';


-- ============================================
-- STEP 3: 트리거 생성
-- ============================================

-- 3-1. customers 변경 시 db_lists.unused_count 자동 갱신
DELIMITER //
CREATE TRIGGER after_customer_update
AFTER UPDATE ON customers
FOR EACH ROW
BEGIN
    IF OLD.data_status != NEW.data_status THEN
        UPDATE db_lists
        SET unused_count = (
            SELECT COUNT(*)
            FROM customers
            WHERE db_id = NEW.db_id AND data_status = '미사용'
        )
        WHERE db_id = NEW.db_id;
    END IF;
END//
DELIMITER ;

-- 3-2. call_logs 삽입 시 statistics 자동 갱신
DELIMITER //
CREATE TRIGGER after_call_log_insert
AFTER INSERT ON call_logs
FOR EACH ROW
BEGIN
    DECLARE today_date DATE;
    SET today_date = DATE(NEW.call_datetime);

    -- statistics 레코드 존재 확인 및 생성
    INSERT INTO statistics (company_id, user_id, stat_date, total_call_time, total_call_count)
    VALUES (NEW.company_id, NEW.user_id, today_date, '00:00:00', 0)
    ON DUPLICATE KEY UPDATE stat_id = stat_id;

    -- 통계 갱신
    UPDATE statistics
    SET
        total_call_time = ADDTIME(total_call_time, COALESCE(NEW.call_duration, '00:00:00')),
        total_call_count = total_call_count + 1,
        success_count = success_count + IF(NEW.call_result = '통화성공', 1, 0),
        failed_count = failed_count + IF(NEW.call_result IN ('부재중', '무응답'), 1, 0),
        callback_count = callback_count + IF(NEW.call_result = '재통화', 1, 0),
        no_answer_count = no_answer_count + IF(NEW.call_result = '무응답', 1, 0)
    WHERE company_id = NEW.company_id AND user_id = NEW.user_id AND stat_date = today_date;
END//
DELIMITER ;


-- ============================================
-- STEP 4: 샘플 데이터 삽입 (테스트용)
-- ============================================

-- 4-1. 슈퍼 관리자용 업체 (개발/테스트용)
INSERT INTO companies (
    company_login_id,
    company_password,
    company_name,
    max_agents,
    is_active,
    subscription_start_date,
    admin_name,
    admin_phone,
    admin_email
) VALUES (
    'admin',
    SHA2('admin123', 256),
    '슈퍼 관리자',
    999,
    TRUE,
    CURDATE(),
    '시스템 관리자',
    '010-0000-0000',
    'admin@callup.com'
);

-- 4-2. 테스트 업체 A
INSERT INTO companies (
    company_login_id,
    company_password,
    company_name,
    max_agents,
    is_active,
    subscription_start_date,
    subscription_end_date,
    admin_name,
    admin_phone,
    admin_email
) VALUES (
    'company_a',
    SHA2('test123', 256),
    'A 업체',
    5,
    TRUE,
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 1 YEAR),
    '김관리자',
    '010-1111-1111',
    'admin@company-a.com'
);

-- 4-3. 테스트 업체 B
INSERT INTO companies (
    company_login_id,
    company_password,
    company_name,
    max_agents,
    is_active,
    subscription_start_date,
    subscription_end_date,
    admin_name,
    admin_phone,
    admin_email
) VALUES (
    'company_b',
    SHA2('test123', 256),
    'B 업체',
    3,
    TRUE,
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 1 YEAR),
    '이관리자',
    '010-2222-2222',
    'admin@company-b.com'
);

-- 4-4. 테스트 상담원들 (A 업체)
INSERT INTO users (company_id, user_name, user_phone, user_status_message) VALUES
(2, '홍길동', '010-1111-1111', '업무 중'),
(2, '김영희', '010-1111-2222', '업무 중'),
(2, '이철수', '010-1111-3333', '대기 중');

-- 4-5. 테스트 상담원들 (B 업체)
INSERT INTO users (company_id, user_name, user_phone, user_status_message) VALUES
(3, '박민수', '010-2222-1111', '업무 중'),
(3, '최지영', '010-2222-2222', '업무 중');

-- 4-6. 테스트 DB 리스트 (A 업체)
INSERT INTO db_lists (company_id, db_title, db_date, total_count, unused_count, is_active) VALUES
(2, '이벤트01_251014', '2025-10-14', 500, 500, TRUE),
(2, '이벤트02_251015', '2025-10-15', 300, 300, TRUE);

-- 4-7. 테스트 DB 리스트 (B 업체)
INSERT INTO db_lists (company_id, db_title, db_date, total_count, unused_count, is_active) VALUES
(3, '프로모션01_251014', '2025-10-14', 200, 200, TRUE);

-- 4-8. 테스트 고객 데이터 (A 업체 - DB 1)
INSERT INTO customers (
    db_id, event_name, customer_phone, customer_name,
    customer_info1, customer_info2, customer_info3,
    data_status, upload_date
) VALUES
(1, '이벤트01_경기인천', '010-1234-5678', '김철수', '인천 부평구', '30대 남성', '쿠팡 이벤트', '미사용', CURDATE()),
(1, '이벤트01_경기인천', '010-1234-5679', '이영희', '인천 남동구', '40대 여성', '네이버 이벤트', '미사용', CURDATE()),
(1, '이벤트01_경기인천', '010-1234-5680', '박민수', '인천 연수구', '20대 남성', '카카오 이벤트', '미사용', CURDATE());

-- 4-9. 테스트 고객 데이터 (B 업체 - DB 3)
INSERT INTO customers (
    db_id, event_name, customer_phone, customer_name,
    customer_info1, customer_info2, customer_info3,
    data_status, upload_date
) VALUES
(3, '프로모션01_서울', '010-2222-5678', '최수진', '서울 강남구', '30대 여성', '프로모션 A', '미사용', CURDATE()),
(3, '프로모션01_서울', '010-2222-5679', '정대호', '서울 서초구', '40대 남성', '프로모션 B', '미사용', CURDATE());


-- ============================================
-- STEP 5: 설치 완료 확인
-- ============================================

SELECT '=== Clean Install v3.0.0 Complete ===' AS status;

SELECT
    'companies' AS table_name,
    COUNT(*) AS total_rows,
    SUM(is_active) AS active_count
FROM companies
UNION ALL
SELECT 'users', COUNT(*), SUM(is_active) FROM users
UNION ALL
SELECT 'db_lists', COUNT(*), SUM(is_active) FROM db_lists
UNION ALL
SELECT 'customers', COUNT(*), COUNT(CASE WHEN data_status = '미사용' THEN 1 END) FROM customers
UNION ALL
SELECT 'call_logs', COUNT(*), NULL FROM call_logs
UNION ALL
SELECT 'statistics', COUNT(*), NULL FROM statistics
UNION ALL
SELECT 'db_assignments', COUNT(*), NULL FROM db_assignments;

-- 외래 키 관계 확인
SELECT
    TABLE_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE()
    AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;

-- 트리거 확인
SELECT
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    EVENT_OBJECT_TABLE,
    ACTION_TIMING
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
ORDER BY EVENT_OBJECT_TABLE, ACTION_TIMING;


-- ============================================
-- 테스트 로그인 정보
-- ============================================

SELECT '=== 테스트 계정 정보 ===' AS info;

SELECT
    company_login_id AS '업체 ID',
    company_name AS '업체명',
    '비밀번호' AS '항목',
    CASE
        WHEN company_login_id = 'admin' THEN 'admin123'
        ELSE 'test123'
    END AS '값',
    max_agents AS '최대 상담원 수'
FROM companies
ORDER BY company_id;

SELECT
    c.company_login_id AS '업체 ID',
    u.user_name AS '상담원 이름',
    u.user_phone AS '전화번호',
    u.user_status_message AS '상태'
FROM users u
JOIN companies c ON u.company_id = c.company_id
ORDER BY c.company_id, u.user_id;

-- ============================================
-- 샘플 로그인 쿼리
-- ============================================

-- A 업체 - 홍길동 상담원 로그인 예시
SELECT '=== 로그인 예시: A 업체 - 홍길동 ===' AS example;

-- Step 1: 업체 인증
SELECT company_id, company_name, max_agents, is_active
FROM companies
WHERE company_login_id = 'company_a'
    AND company_password = SHA2('test123', 256);

-- Step 2: 상담원 조회 (company_id = 2 사용)
SELECT u.user_id, u.user_name, u.company_id
FROM users u
WHERE u.company_id = 2 AND u.user_name = '홍길동';

-- Step 3: 할당된 DB 조회
SELECT
    d.db_id,
    d.db_title,
    d.total_count,
    d.unused_count
FROM db_lists d
WHERE d.company_id = 2 AND d.is_active = TRUE;
