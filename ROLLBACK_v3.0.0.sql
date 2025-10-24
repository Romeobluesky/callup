-- ============================================
-- CallUp Database Rollback Script
-- Version: v3.0.0 → v2.0.0
-- 마이그레이션 실패 시 원상 복구용
-- ============================================

-- 경고: 이 스크립트는 v3.0.0 마이그레이션을 완전히 되돌립니다.
-- 마이그레이션 후 생성된 데이터는 모두 손실됩니다!

-- 실행 전 확인:
-- 1. 백업 테이블이 존재하는지 확인
-- 2. 롤백 사유 문서화
-- 3. 관련 팀원에게 알림

-- ============================================
-- STEP 1: 백업 테이블 존재 확인
-- ============================================

SELECT
    'users_backup_v2' AS backup_table,
    COUNT(*) AS row_count
FROM users_backup_v2
UNION ALL SELECT 'db_lists_backup_v2', COUNT(*) FROM db_lists_backup_v2
UNION ALL SELECT 'customers_backup_v2', COUNT(*) FROM customers_backup_v2
UNION ALL SELECT 'call_logs_backup_v2', COUNT(*) FROM call_logs_backup_v2
UNION ALL SELECT 'statistics_backup_v2', COUNT(*) FROM statistics_backup_v2;

-- 백업이 없으면 여기서 중단!
-- 백업 테이블이 모두 존재하는지 확인 후 계속 진행


-- ============================================
-- STEP 2: 외래 키 제약 조건 해제
-- ============================================

SET FOREIGN_KEY_CHECKS = 0;


-- ============================================
-- STEP 3: 트리거 삭제
-- ============================================

DROP TRIGGER IF EXISTS after_customer_update;
DROP TRIGGER IF EXISTS after_call_log_insert;


-- ============================================
-- STEP 4: v3.0.0에서 추가된 테이블 삭제
-- ============================================

DROP TABLE IF EXISTS db_assignments;
DROP TABLE IF EXISTS companies;


-- ============================================
-- STEP 5: 기존 테이블 삭제 및 백업으로 복원
-- ============================================

-- 5-1. 현재 테이블 삭제
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS db_lists;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS call_logs;
DROP TABLE IF EXISTS statistics;

-- 5-2. 백업 테이블로부터 복원
CREATE TABLE users AS SELECT * FROM users_backup_v2;
CREATE TABLE db_lists AS SELECT * FROM db_lists_backup_v2;
CREATE TABLE customers AS SELECT * FROM customers_backup_v2;
CREATE TABLE call_logs AS SELECT * FROM call_logs_backup_v2;
CREATE TABLE statistics AS SELECT * FROM statistics_backup_v2;


-- ============================================
-- STEP 6: v2.0.0 테이블 구조 재생성
-- ============================================

-- 6-1. users 테이블
ALTER TABLE users
ADD PRIMARY KEY (user_id),
ADD UNIQUE KEY unique_user_login (user_login_id),
ADD INDEX idx_user_login (user_login_id),
ADD INDEX idx_user_name (user_name);

ALTER TABLE users MODIFY user_id INT AUTO_INCREMENT;

-- 6-2. db_lists 테이블
ALTER TABLE db_lists
ADD PRIMARY KEY (db_id),
ADD INDEX idx_db_date (db_date),
ADD INDEX idx_db_active (is_active);

ALTER TABLE db_lists MODIFY db_id INT AUTO_INCREMENT;

-- 6-3. customers 테이블
ALTER TABLE customers
ADD PRIMARY KEY (customer_id),
ADD INDEX idx_customer_db (db_id),
ADD INDEX idx_customer_phone (customer_phone),
ADD INDEX idx_customer_status (data_status),
ADD INDEX idx_customer_reservation (reservation_date);

ALTER TABLE customers MODIFY customer_id INT AUTO_INCREMENT;

-- 6-4. call_logs 테이블
ALTER TABLE call_logs
ADD PRIMARY KEY (log_id),
ADD INDEX idx_call_user (user_id),
ADD INDEX idx_call_customer (customer_id),
ADD INDEX idx_call_datetime (call_datetime);

ALTER TABLE call_logs MODIFY log_id INT AUTO_INCREMENT;

-- 6-5. statistics 테이블
ALTER TABLE statistics
ADD PRIMARY KEY (stat_id),
ADD UNIQUE KEY unique_user_date (user_id, stat_date),
ADD INDEX idx_stat_user (user_id),
ADD INDEX idx_stat_date (stat_date);

ALTER TABLE statistics MODIFY stat_id INT AUTO_INCREMENT;


-- ============================================
-- STEP 7: 외래 키 복원
-- ============================================

ALTER TABLE customers
ADD CONSTRAINT fk_customers_db
FOREIGN KEY (db_id) REFERENCES db_lists(db_id);

ALTER TABLE call_logs
ADD CONSTRAINT fk_call_logs_user
FOREIGN KEY (user_id) REFERENCES users(user_id),
ADD CONSTRAINT fk_call_logs_customer
FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
ADD CONSTRAINT fk_call_logs_db
FOREIGN KEY (db_id) REFERENCES db_lists(db_id);

ALTER TABLE statistics
ADD CONSTRAINT fk_statistics_user
FOREIGN KEY (user_id) REFERENCES users(user_id);


-- ============================================
-- STEP 8: v2.0.0 트리거 재생성
-- ============================================

-- 8-1. customers 변경 시 db_lists.unused_count 자동 갱신
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

-- 8-2. call_logs 삽입 시 statistics 자동 갱신
DELIMITER //
CREATE TRIGGER after_call_log_insert
AFTER INSERT ON call_logs
FOR EACH ROW
BEGIN
    DECLARE today_date DATE;
    SET today_date = DATE(NEW.call_datetime);

    -- statistics 레코드 존재 확인 및 생성
    INSERT INTO statistics (user_id, stat_date, total_call_time, total_call_count)
    VALUES (NEW.user_id, today_date, '00:00:00', 0)
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
    WHERE user_id = NEW.user_id AND stat_date = today_date;
END//
DELIMITER ;


-- ============================================
-- STEP 9: 외래 키 제약 조건 재활성화
-- ============================================

SET FOREIGN_KEY_CHECKS = 1;


-- ============================================
-- STEP 10: 데이터 무결성 검증
-- ============================================

-- 10-1. 테이블 행 수 확인
SELECT
    'Users' AS table_name,
    COUNT(*) AS current_rows,
    (SELECT COUNT(*) FROM users_backup_v2) AS backup_rows
FROM users
UNION ALL
SELECT 'DB Lists', COUNT(*), (SELECT COUNT(*) FROM db_lists_backup_v2) FROM db_lists
UNION ALL
SELECT 'Customers', COUNT(*), (SELECT COUNT(*) FROM customers_backup_v2) FROM customers
UNION ALL
SELECT 'Call Logs', COUNT(*), (SELECT COUNT(*) FROM call_logs_backup_v2) FROM call_logs
UNION ALL
SELECT 'Statistics', COUNT(*), (SELECT COUNT(*) FROM statistics_backup_v2) FROM statistics;

-- 10-2. 외래 키 관계 확인
SELECT
    TABLE_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE()
    AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;


-- ============================================
-- STEP 11: 롤백 완료 요약
-- ============================================

SELECT '=== Rollback to v2.0.0 Complete ===' AS status;

SELECT
    'users' AS table_name,
    COUNT(*) AS total_rows,
    'user_login_id column exists' AS verification
FROM users
WHERE user_login_id IS NOT NULL
UNION ALL
SELECT
    'companies table',
    COUNT(*),
    'should be 0 (dropped)'
FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_name = 'companies'
UNION ALL
SELECT
    'db_assignments table',
    COUNT(*),
    'should be 0 (dropped)'
FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_name = 'db_assignments';


-- ============================================
-- 완료 후 확인 사항
-- ============================================

-- 1. 모든 테이블이 v2.0.0 구조로 복원되었는지 확인
-- 2. users 테이블에 user_login_id, user_password 컬럼 존재 확인
-- 3. companies, db_assignments 테이블 삭제 확인
-- 4. 백업 테이블 보관 (추가 복구 필요 시 사용)
-- 5. 롤백 사유 및 향후 계획 문서화
--
-- 백업 테이블 삭제는 충분한 검증 후 수동으로 실행:
-- DROP TABLE users_backup_v2, db_lists_backup_v2, customers_backup_v2,
--            call_logs_backup_v2, statistics_backup_v2;
