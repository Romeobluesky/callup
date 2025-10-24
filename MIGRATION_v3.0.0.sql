-- ============================================
-- CallUp Database Migration Script
-- Version: v2.0.0 → v3.0.0
-- 업체 계정 시스템 도입 (Company-based Architecture)
-- ============================================

-- 실행 전 필수 확인 사항:
-- 1. 기존 데이터베이스 전체 백업 완료
-- 2. 개발 환경에서 먼저 테스트
-- 3. 운영 환경 적용 시 유지보수 시간 확보
-- 4. 롤백 스크립트 준비 완료

-- ============================================
-- STEP 1: 백업 테이블 생성
-- ============================================

-- 기존 테이블 백업 (롤백 시 사용)
CREATE TABLE IF NOT EXISTS users_backup_v2 AS SELECT * FROM users;
CREATE TABLE IF NOT EXISTS db_lists_backup_v2 AS SELECT * FROM db_lists;
CREATE TABLE IF NOT EXISTS customers_backup_v2 AS SELECT * FROM customers;
CREATE TABLE IF NOT EXISTS call_logs_backup_v2 AS SELECT * FROM call_logs;
CREATE TABLE IF NOT EXISTS statistics_backup_v2 AS SELECT * FROM statistics;

-- 백업 완료 확인
SELECT
    'users' AS table_name, COUNT(*) AS backup_count FROM users_backup_v2
UNION ALL SELECT 'db_lists', COUNT(*) FROM db_lists_backup_v2
UNION ALL SELECT 'customers', COUNT(*) FROM customers_backup_v2
UNION ALL SELECT 'call_logs', COUNT(*) FROM call_logs_backup_v2
UNION ALL SELECT 'statistics', COUNT(*) FROM statistics_backup_v2;


-- ============================================
-- STEP 2: 외래 키 제약 조건 임시 해제
-- ============================================

SET FOREIGN_KEY_CHECKS = 0;


-- ============================================
-- STEP 3: 새로운 테이블 생성
-- ============================================

-- 3-1. companies 테이블 (업체 계정)
CREATE TABLE IF NOT EXISTS companies (
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

-- 3-2. db_assignments 테이블 (DB 할당 추적)
CREATE TABLE IF NOT EXISTS db_assignments (
    assignment_id INT PRIMARY KEY AUTO_INCREMENT,
    db_id INT NOT NULL COMMENT 'DB 리스트 ID',
    user_id INT NOT NULL COMMENT '상담원 ID',
    company_id INT NOT NULL COMMENT '업체 ID',
    assigned_count INT DEFAULT 0 COMMENT '할당된 고객 수',
    completed_count INT DEFAULT 0 COMMENT '완료된 고객 수',
    in_progress_count INT DEFAULT 0 COMMENT '진행 중인 고객 수',
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_assignment_db (db_id),
    INDEX idx_assignment_user (user_id),
    INDEX idx_assignment_company (company_id),
    UNIQUE KEY unique_assignment (db_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='DB 할당 추적';


-- ============================================
-- STEP 4: 기존 데이터를 위한 레거시 업체 생성
-- ============================================

-- 기존 데이터를 하나의 "레거시 업체"로 통합
INSERT INTO companies (
    company_login_id,
    company_password,
    company_name,
    max_agents,
    is_active,
    subscription_start_date,
    admin_name,
    admin_phone
) VALUES (
    'legacy_company',
    SHA2('legacy_password_change_me', 256),
    '레거시 데이터 통합 업체',
    999,  -- 기존 모든 상담원 수용
    TRUE,
    CURDATE(),
    '시스템 관리자',
    '000-0000-0000'
);

-- 레거시 업체 ID 저장
SET @legacy_company_id = LAST_INSERT_ID();

SELECT @legacy_company_id AS 'Legacy Company ID Created';


-- ============================================
-- STEP 5: users 테이블 수정
-- ============================================

-- 5-1. company_id 컬럼 추가
ALTER TABLE users
ADD COLUMN company_id INT COMMENT '업체 ID' AFTER user_id,
ADD COLUMN last_login_at TIMESTAMP NULL COMMENT '최종 로그인 시간';

-- 5-2. 기존 모든 사용자를 레거시 업체에 할당
UPDATE users SET company_id = @legacy_company_id WHERE company_id IS NULL;

-- 5-3. company_id NOT NULL 제약 조건 추가
ALTER TABLE users MODIFY company_id INT NOT NULL;

-- 5-4. 불필요한 컬럼 제거 (로그인 정보는 업체 레벨로 이동)
ALTER TABLE users
DROP COLUMN user_login_id,
DROP COLUMN user_password;

-- 5-5. 외래 키 추가
ALTER TABLE users
ADD CONSTRAINT fk_users_company
FOREIGN KEY (company_id) REFERENCES companies(company_id);

-- 5-6. 인덱스 추가
CREATE INDEX idx_users_company ON users(company_id);
CREATE INDEX idx_users_name ON users(user_name);


-- ============================================
-- STEP 6: db_lists 테이블 수정
-- ============================================

-- 6-1. company_id 컬럼 추가
ALTER TABLE db_lists
ADD COLUMN company_id INT COMMENT '업체 ID' AFTER db_id;

-- 6-2. 기존 모든 DB를 레거시 업체에 할당
UPDATE db_lists SET company_id = @legacy_company_id WHERE company_id IS NULL;

-- 6-3. company_id NOT NULL 제약 조건 추가
ALTER TABLE db_lists MODIFY company_id INT NOT NULL;

-- 6-4. 외래 키 추가
ALTER TABLE db_lists
ADD CONSTRAINT fk_db_lists_company
FOREIGN KEY (company_id) REFERENCES companies(company_id);

-- 6-5. 인덱스 추가
CREATE INDEX idx_db_lists_company ON db_lists(company_id);


-- ============================================
-- STEP 7: customers 테이블 수정
-- ============================================

-- 7-1. assigned_user_id 컬럼 추가 (할당된 상담원)
ALTER TABLE customers
ADD COLUMN assigned_user_id INT NULL COMMENT '할당된 상담원 ID' AFTER db_id;

-- 7-2. 외래 키 추가
ALTER TABLE customers
ADD CONSTRAINT fk_customers_assigned_user
FOREIGN KEY (assigned_user_id) REFERENCES users(user_id);

-- 7-3. 인덱스 추가
CREATE INDEX idx_customers_assigned_user ON customers(assigned_user_id);


-- ============================================
-- STEP 8: call_logs 테이블 수정
-- ============================================

-- 8-1. company_id 컬럼 추가
ALTER TABLE call_logs
ADD COLUMN company_id INT COMMENT '업체 ID' AFTER log_id;

-- 8-2. 기존 통화 로그를 레거시 업체에 할당
UPDATE call_logs SET company_id = @legacy_company_id WHERE company_id IS NULL;

-- 8-3. company_id NOT NULL 제약 조건 추가
ALTER TABLE call_logs MODIFY company_id INT NOT NULL;

-- 8-4. 외래 키 추가
ALTER TABLE call_logs
ADD CONSTRAINT fk_call_logs_company
FOREIGN KEY (company_id) REFERENCES companies(company_id);

-- 8-5. 인덱스 추가
CREATE INDEX idx_call_logs_company ON call_logs(company_id);


-- ============================================
-- STEP 9: statistics 테이블 수정
-- ============================================

-- 9-1. company_id 컬럼 추가
ALTER TABLE statistics
ADD COLUMN company_id INT COMMENT '업체 ID' AFTER stat_id;

-- 9-2. 기존 통계를 레거시 업체에 할당
UPDATE statistics SET company_id = @legacy_company_id WHERE company_id IS NULL;

-- 9-3. company_id NOT NULL 제약 조건 추가
ALTER TABLE statistics MODIFY company_id INT NOT NULL;

-- 9-4. 외래 키 추가
ALTER TABLE statistics
ADD CONSTRAINT fk_statistics_company
FOREIGN KEY (company_id) REFERENCES companies(company_id);

-- 9-5. 인덱스 추가
CREATE INDEX idx_statistics_company ON statistics(company_id);


-- ============================================
-- STEP 10: 외래 키 제약 조건 재활성화
-- ============================================

SET FOREIGN_KEY_CHECKS = 1;


-- ============================================
-- STEP 11: 트리거 재생성
-- ============================================

-- 기존 트리거 삭제
DROP TRIGGER IF EXISTS after_customer_update;
DROP TRIGGER IF EXISTS after_call_log_insert;

-- 11-1. customers 변경 시 db_lists.unused_count 자동 갱신
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

-- 11-2. call_logs 삽입 시 statistics 자동 갱신 (업체 ID 포함)
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
-- STEP 12: 데이터 무결성 검증
-- ============================================

-- 12-1. 모든 users가 유효한 company_id를 가지는지 확인
SELECT 'Users without valid company' AS check_name, COUNT(*) AS count
FROM users u
LEFT JOIN companies c ON u.company_id = c.company_id
WHERE c.company_id IS NULL;

-- 12-2. 모든 db_lists가 유효한 company_id를 가지는지 확인
SELECT 'DB Lists without valid company' AS check_name, COUNT(*) AS count
FROM db_lists d
LEFT JOIN companies c ON d.company_id = c.company_id
WHERE c.company_id IS NULL;

-- 12-3. 모든 call_logs가 유효한 company_id를 가지는지 확인
SELECT 'Call Logs without valid company' AS check_name, COUNT(*) AS count
FROM call_logs cl
LEFT JOIN companies c ON cl.company_id = c.company_id
WHERE c.company_id IS NULL;

-- 12-4. 모든 statistics가 유효한 company_id를 가지는지 확인
SELECT 'Statistics without valid company' AS check_name, COUNT(*) AS count
FROM statistics s
LEFT JOIN companies c ON s.company_id = c.company_id
WHERE c.company_id IS NULL;

-- 12-5. 외래 키 관계 확인
SELECT
    TABLE_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE()
    AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;


-- ============================================
-- STEP 13: 마이그레이션 완료 요약
-- ============================================

SELECT '=== Migration v3.0.0 Complete ===' AS status;

SELECT
    'Companies' AS table_name,
    COUNT(*) AS total_rows,
    SUM(is_active) AS active_companies
FROM companies
UNION ALL
SELECT
    'Users',
    COUNT(*),
    SUM(is_active)
FROM users
UNION ALL
SELECT
    'DB Lists',
    COUNT(*),
    SUM(is_active)
FROM db_lists
UNION ALL
SELECT
    'Customers',
    COUNT(*),
    COUNT(CASE WHEN data_status = '미사용' THEN 1 END)
FROM customers
UNION ALL
SELECT
    'Call Logs',
    COUNT(*),
    NULL
FROM call_logs
UNION ALL
SELECT
    'Statistics',
    COUNT(*),
    NULL
FROM statistics
UNION ALL
SELECT
    'DB Assignments',
    COUNT(*),
    NULL
FROM db_assignments;


-- ============================================
-- 완료 후 확인 사항
-- ============================================

-- 1. 레거시 업체 로그인 정보:
--    - 업체 ID: legacy_company
--    - 비밀번호: legacy_password_change_me (반드시 변경 필요!)
--
-- 2. 기존 상담원들:
--    - 모두 레거시 업체에 자동 할당됨
--    - 로그인: legacy_company + legacy_password_change_me + 상담원이름
--
-- 3. 새로운 업체 추가 방법:
--    INSERT INTO companies (company_login_id, company_password, company_name, max_agents)
--    VALUES ('new_company_id', SHA2('password', 256), '신규업체', 5);
--
-- 4. 상담원 추가 방법:
--    INSERT INTO users (company_id, user_name, user_phone)
--    VALUES (1, '홍길동', '010-1234-5678');
--
-- 5. 백업 테이블 삭제 (검증 완료 후):
--    DROP TABLE users_backup_v2, db_lists_backup_v2, customers_backup_v2,
--               call_logs_backup_v2, statistics_backup_v2;
