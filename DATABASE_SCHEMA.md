# CallUp 데이터베이스 스키마 설계 v3.0

## 개요

**비즈니스 모델**: 업체별 계정 + 상담원 관리 시스템
- 최고 관리자가 업체 계정 발급 (1개 ID/PW)
- 업체 관리자가 상담원 등록 (이름만)
- 상담원 로그인: 업체 ID + 업체 PW + 상담원 이름

---

## 데이터베이스 생성

```sql
CREATE DATABASE IF NOT EXISTS callup_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE callup_db;
```

---

## 테이블 구조

### 1. companies (업체 계정) ⭐ 신규

업체(사용자)의 계정 정보와 계약 관리

```sql
CREATE TABLE companies (
    company_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '업체 ID',

    -- 로그인 정보
    company_login_id VARCHAR(50) UNIQUE NOT NULL COMMENT '업체 로그인 ID',
    company_password VARCHAR(255) NOT NULL COMMENT '업체 비밀번호 (해시)',
    company_name VARCHAR(100) NOT NULL COMMENT '업체명',

    -- 계약 정보
    max_agents INT DEFAULT 3 COMMENT '최대 상담원 수',
    is_active BOOLEAN DEFAULT TRUE COMMENT '활성 상태 (사용료 지불 여부)',
    subscription_start_date DATE COMMENT '계약 시작일',
    subscription_end_date DATE COMMENT '계약 종료일',

    -- 담당자 정보
    admin_name VARCHAR(50) COMMENT '담당자 이름',
    admin_phone VARCHAR(20) COMMENT '담당자 연락처',
    admin_email VARCHAR(100) COMMENT '담당자 이메일',

    -- 메타 정보
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '최종 수정일',

    INDEX idx_login_id (company_login_id),
    INDEX idx_is_active (is_active),
    INDEX idx_company_name (company_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='업체 계정';
```

---

### 2. users (상담원 정보) ✏️ 수정

업체 소속 상담원 정보 (개별 로그인 ID/PW 없음)

```sql
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '상담원 ID',
    company_id INT NOT NULL COMMENT '소속 업체 ID (외래키)',

    -- 상담원 정보
    user_name VARCHAR(50) NOT NULL COMMENT '상담원 이름',
    user_phone VARCHAR(20) COMMENT '상담원 전화번호',
    user_status_message VARCHAR(200) COMMENT '상태 메시지',

    -- 상태 정보
    is_active BOOLEAN DEFAULT TRUE COMMENT '활성 상태',
    last_login_at TIMESTAMP NULL COMMENT '최종 로그인 시간',

    -- 메타 정보
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '최종 수정일',

    FOREIGN KEY (company_id) REFERENCES companies(company_id) ON DELETE CASCADE,
    INDEX idx_company_id (company_id),
    INDEX idx_name (user_name),
    INDEX idx_company_name (company_id, user_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='상담원 정보';
```

**주요 변경사항**:
- ❌ 삭제: `user_login_id`, `user_password` (업체 계정으로 통합)
- ✅ 추가: `company_id` (소속 업체), `last_login_at` (최종 로그인)

---

### 3. db_lists (DB 리스트) ✏️ 수정

업체별 업로드된 고객 DB 목록

```sql
CREATE TABLE db_lists (
    db_id INT PRIMARY KEY AUTO_INCREMENT COMMENT 'DB ID',
    company_id INT NOT NULL COMMENT '업체 ID (외래키)',

    -- DB 정보
    db_title VARCHAR(100) NOT NULL COMMENT 'DB 제목',
    db_date DATE NOT NULL COMMENT 'DB 날짜',
    total_count INT DEFAULT 0 COMMENT '총 고객 수',
    unused_count INT DEFAULT 0 COMMENT '미사용 고객 수',

    -- 파일 정보
    file_name VARCHAR(255) COMMENT '원본 파일명',
    is_active BOOLEAN DEFAULT TRUE COMMENT '활성 상태 (ON/OFF)',
    upload_date DATE NOT NULL COMMENT '업로드 날짜',

    -- 메타 정보
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '최종 수정일',

    FOREIGN KEY (company_id) REFERENCES companies(company_id) ON DELETE CASCADE,
    INDEX idx_company_id (company_id),
    INDEX idx_db_date (db_date),
    INDEX idx_db_title (db_title),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='DB 리스트';
```

**주요 변경사항**:
- ✅ 추가: `company_id` (업체 소유권 명확화)

---

### 4. db_assignments (DB 할당) ⭐ 신규

상담원별 DB 할당 및 진행 현황 추적

```sql
CREATE TABLE db_assignments (
    assignment_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '할당 ID',

    -- 할당 정보
    db_id INT NOT NULL COMMENT 'DB ID (외래키)',
    user_id INT NOT NULL COMMENT '상담원 ID (외래키)',
    company_id INT NOT NULL COMMENT '업체 ID (외래키)',

    -- 진행 현황
    assigned_count INT DEFAULT 0 COMMENT '할당된 고객 수',
    completed_count INT DEFAULT 0 COMMENT '완료된 고객 수',
    in_progress_count INT DEFAULT 0 COMMENT '진행 중 고객 수',

    -- 메타 정보
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '할당 일시',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '최종 수정일',

    FOREIGN KEY (db_id) REFERENCES db_lists(db_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (company_id) REFERENCES companies(company_id) ON DELETE CASCADE,

    UNIQUE KEY unique_assignment (db_id, user_id),
    INDEX idx_db_id (db_id),
    INDEX idx_user_id (user_id),
    INDEX idx_company_id (company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='DB 할당';
```

---

### 5. customers (고객 정보) ✏️ 수정

개별 고객 정보 및 통화 이력

```sql
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '고객 ID',
    db_id INT NOT NULL COMMENT 'DB ID (외래키)',
    assigned_user_id INT COMMENT '할당된 상담원 ID (외래키)',

    -- CSV 기본 정보 (0-5번 컬럼)
    event_name VARCHAR(100) COMMENT '이벤트명',
    customer_phone VARCHAR(20) NOT NULL COMMENT '전화번호',
    customer_name VARCHAR(50) NOT NULL COMMENT '고객명',
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

    -- 추가 정보
    has_audio BOOLEAN DEFAULT FALSE COMMENT '통화 녹음 여부',
    audio_file_path VARCHAR(500) COMMENT '녹음 파일 경로',

    -- 메타 정보
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '시스템 최종 수정일',

    FOREIGN KEY (db_id) REFERENCES db_lists(db_id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_db_id (db_id),
    INDEX idx_assigned_user (assigned_user_id),
    INDEX idx_phone (customer_phone),
    INDEX idx_name (customer_name),
    INDEX idx_data_status (data_status),
    INDEX idx_call_datetime (call_datetime),
    INDEX idx_reservation_date (reservation_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='고객 정보';
```

**주요 변경사항**:
- ✅ 추가: `assigned_user_id` (할당된 상담원)

---

### 6. call_logs (통화 로그)

개별 통화 이력 로그

```sql
CREATE TABLE call_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '로그 ID',
    user_id INT NOT NULL COMMENT '상담원 ID (외래키)',
    customer_id INT NOT NULL COMMENT '고객 ID (외래키)',
    db_id INT NOT NULL COMMENT 'DB ID (외래키)',
    company_id INT NOT NULL COMMENT '업체 ID (외래키)',

    -- 통화 정보
    call_datetime DATETIME NOT NULL COMMENT '통화 일시',
    call_start_time TIME COMMENT '통화 시작 시간',
    call_end_time TIME COMMENT '통화 종료 시간',
    call_duration VARCHAR(20) COMMENT '통화 시간 (HH:MM:SS)',
    call_result VARCHAR(100) COMMENT '통화 결과',
    consultation_result TEXT COMMENT '상담 결과',
    memo TEXT COMMENT '메모',

    -- 녹음 정보
    has_audio BOOLEAN DEFAULT FALSE COMMENT '통화 녹음 여부',
    audio_file_path VARCHAR(500) COMMENT '녹음 파일 경로',

    -- 메타 정보
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    FOREIGN KEY (db_id) REFERENCES db_lists(db_id) ON DELETE CASCADE,
    FOREIGN KEY (company_id) REFERENCES companies(company_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_customer_id (customer_id),
    INDEX idx_db_id (db_id),
    INDEX idx_company_id (company_id),
    INDEX idx_call_datetime (call_datetime)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='통화 로그';
```

**주요 변경사항**:
- ✅ 추가: `company_id` (업체별 통화 로그 집계)

---

### 7. statistics (통계 정보)

상담원별/업체별 일별 통계

```sql
CREATE TABLE statistics (
    stat_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '통계 ID',
    user_id INT NOT NULL COMMENT '상담원 ID (외래키)',
    company_id INT NOT NULL COMMENT '업체 ID (외래키)',
    stat_date DATE NOT NULL COMMENT '통계 날짜',

    -- 통화 통계
    total_call_time VARCHAR(20) DEFAULT '00:00:00' COMMENT '총 통화 시간',
    total_call_count INT DEFAULT 0 COMMENT '총 통화 건수',
    success_count INT DEFAULT 0 COMMENT '통화 성공 건수',
    failed_count INT DEFAULT 0 COMMENT '통화 실패 건수',
    callback_count INT DEFAULT 0 COMMENT '재통화 건수',
    no_answer_count INT DEFAULT 0 COMMENT '무응답 건수',

    -- DB 통계
    assigned_db_count INT DEFAULT 0 COMMENT '분배 DB 건수',
    unused_db_count INT DEFAULT 0 COMMENT '미사용 DB 건수',

    -- 메타 정보
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '최종 수정일',

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (company_id) REFERENCES companies(company_id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_date (user_id, stat_date),
    INDEX idx_user_id (user_id),
    INDEX idx_company_id (company_id),
    INDEX idx_stat_date (stat_date),
    INDEX idx_company_date (company_id, stat_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='통계 정보';
```

**주요 변경사항**:
- ✅ 추가: `company_id` (업체별 통계 집계)

---

## 샘플 데이터

### 1. 업체 계정

```sql
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
) VALUES
('company_a', SHA2('password123', 256), 'A텔레마케팅', 5, TRUE, '2025-01-01', '2025-12-31', '김관리', '010-1111-1111', 'admin@company-a.com'),
('company_b', SHA2('password456', 256), 'B컨설팅', 3, TRUE, '2025-01-15', '2025-12-31', '이담당', '010-2222-2222', 'admin@company-b.com'),
('company_c', SHA2('password789', 256), 'C마케팅', 10, FALSE, '2024-12-01', '2024-12-31', '박대표', '010-3333-3333', 'admin@company-c.com');
```

### 2. 상담원 정보

```sql
INSERT INTO users (company_id, user_name, user_phone, user_status_message, is_active) VALUES
-- A업체 상담원 (3명)
(1, '김철수', '010-1234-5678', '열심히 일하겠습니다', TRUE),
(1, '이영희', '010-2345-6789', '고객 만족을 위해', TRUE),
(1, '박민수', '010-3456-7890', '오늘도 화이팅', TRUE),

-- B업체 상담원 (2명)
(2, '최상담', '010-4567-8901', '친절한 상담', TRUE),
(2, '정상담', '010-5678-9012', '정확한 안내', TRUE),

-- C업체 상담원 (5명, 비활성 업체)
(3, '강상담', '010-6789-0123', '최선을 다하겠습니다', TRUE),
(3, '조상담', '010-7890-1234', '항상 밝게', TRUE),
(3, '윤상담', '010-8901-2345', '성실하게', TRUE),
(3, '임상담', '010-9012-3456', '열정적으로', TRUE),
(3, '한상담', '010-0123-4567', '고객 중심', TRUE);
```

### 3. DB 리스트

```sql
INSERT INTO db_lists (
    company_id,
    db_title,
    db_date,
    total_count,
    unused_count,
    file_name,
    is_active,
    upload_date
) VALUES
-- A업체 DB
(1, 'A업체_인천지역_251014', '2025-10-14', 500, 250, 'company_a_incheon.csv', TRUE, '2025-10-14'),
(1, 'A업체_경기지역_251015', '2025-10-15', 300, 150, 'company_a_gyeonggi.csv', TRUE, '2025-10-15'),

-- B업체 DB
(2, 'B업체_서울지역_251010', '2025-10-10', 800, 400, 'company_b_seoul.csv', TRUE, '2025-10-10'),

-- C업체 DB (비활성 업체)
(3, 'C업체_전국_251001', '2025-10-01', 1000, 500, 'company_c_nationwide.csv', FALSE, '2025-10-01');
```

### 4. DB 할당

```sql
INSERT INTO db_assignments (db_id, user_id, company_id, assigned_count, completed_count) VALUES
-- A업체 DB 1번을 3명 상담원에게 분배
(1, 1, 1, 200, 50),  -- 김철수에게 200명 할당, 50명 완료
(1, 2, 1, 200, 80),  -- 이영희에게 200명 할당, 80명 완료
(1, 3, 1, 100, 20),  -- 박민수에게 100명 할당, 20명 완료

-- B업체 DB 3번을 2명 상담원에게 분배
(3, 4, 2, 400, 150), -- 최상담에게 400명 할당, 150명 완료
(3, 5, 2, 400, 250); -- 정상담에게 400명 할당, 250명 완료
```

### 5. 고객 정보

```sql
INSERT INTO customers (
    db_id,
    assigned_user_id,
    event_name,
    customer_phone,
    customer_name,
    customer_info1,
    customer_info2,
    customer_info3,
    data_status,
    upload_date
) VALUES
-- A업체 DB - 김철수 할당 고객
(1, 1, 'A업체_인천지역_251014', '010-1111-1111', '고객1', '인천 부평구', '쿠팡 이벤트', '#A001', '미사용', '2025-10-14'),
(1, 1, 'A업체_인천지역_251014', '010-1111-2222', '고객2', '인천 남동구', '쿠팡 이벤트', '#A002', '사용완료', '2025-10-14'),

-- A업체 DB - 이영희 할당 고객
(1, 2, 'A업체_인천지역_251014', '010-2222-1111', '고객3', '인천 계양구', '쿠팡 이벤트', '#A003', '미사용', '2025-10-14'),

-- B업체 DB - 최상담 할당 고객
(3, 4, 'B업체_서울지역_251010', '010-3333-1111', '고객4', '서울 강남구', '네이버 이벤트', '#B001', '미사용', '2025-10-10');
```

---

## 트리거 (자동 업데이트)

### 1. DB 할당 시 customers의 assigned_user_id 업데이트

```sql
DELIMITER $$

CREATE TRIGGER update_customer_assignment_after_db_assignment
AFTER INSERT ON db_assignments
FOR EACH ROW
BEGIN
    -- 해당 DB의 미사용 고객들을 상담원에게 할당
    -- (실제로는 백엔드에서 수동으로 처리하는 것이 좋음)
    -- 이 트리거는 참고용
END$$

DELIMITER ;
```

### 2. customers 변경 시 db_lists의 unused_count 자동 업데이트

```sql
DELIMITER $$

CREATE TRIGGER update_unused_count_after_customer_insert
AFTER INSERT ON customers
FOR EACH ROW
BEGIN
    UPDATE db_lists
    SET
        total_count = (SELECT COUNT(*) FROM customers WHERE db_id = NEW.db_id),
        unused_count = (SELECT COUNT(*) FROM customers WHERE db_id = NEW.db_id AND data_status = '미사용')
    WHERE db_id = NEW.db_id;
END$$

CREATE TRIGGER update_unused_count_after_customer_update
AFTER UPDATE ON customers
FOR EACH ROW
BEGIN
    UPDATE db_lists
    SET unused_count = (SELECT COUNT(*) FROM customers WHERE db_id = NEW.db_id AND data_status = '미사용')
    WHERE db_id = NEW.db_id;

    -- DB 할당 통계 업데이트
    IF NEW.assigned_user_id IS NOT NULL THEN
        UPDATE db_assignments
        SET
            completed_count = (SELECT COUNT(*) FROM customers WHERE db_id = NEW.db_id AND assigned_user_id = NEW.assigned_user_id AND data_status = '사용완료'),
            in_progress_count = (SELECT COUNT(*) FROM customers WHERE db_id = NEW.db_id AND assigned_user_id = NEW.assigned_user_id AND data_status = '미사용')
        WHERE db_id = NEW.db_id AND user_id = NEW.assigned_user_id;
    END IF;
END$$

CREATE TRIGGER update_unused_count_after_customer_delete
AFTER DELETE ON customers
FOR EACH ROW
BEGIN
    UPDATE db_lists
    SET
        total_count = (SELECT COUNT(*) FROM customers WHERE db_id = OLD.db_id),
        unused_count = (SELECT COUNT(*) FROM customers WHERE db_id = OLD.db_id AND data_status = '미사용')
    WHERE db_id = OLD.db_id;
END$$

DELIMITER ;
```

### 3. call_logs 삽입 시 statistics 자동 업데이트

```sql
DELIMITER $$

CREATE TRIGGER update_statistics_after_call
AFTER INSERT ON call_logs
FOR EACH ROW
BEGIN
    INSERT INTO statistics (
        user_id,
        company_id,
        stat_date,
        total_call_count,
        success_count,
        failed_count,
        callback_count,
        no_answer_count
    )
    VALUES (
        NEW.user_id,
        NEW.company_id,
        DATE(NEW.call_datetime),
        1,
        IF(NEW.call_result LIKE '%성공%', 1, 0),
        IF(NEW.call_result LIKE '%실패%' OR NEW.call_result LIKE '%부재%', 1, 0),
        IF(NEW.call_result LIKE '%재통화%' OR NEW.call_result LIKE '%재연락%', 1, 0),
        IF(NEW.call_result LIKE '%무응답%', 1, 0)
    )
    ON DUPLICATE KEY UPDATE
        total_call_count = total_call_count + 1,
        success_count = success_count + IF(NEW.call_result LIKE '%성공%', 1, 0),
        failed_count = failed_count + IF(NEW.call_result LIKE '%실패%' OR NEW.call_result LIKE '%부재%', 1, 0),
        callback_count = callback_count + IF(NEW.call_result LIKE '%재통화%' OR NEW.call_result LIKE '%재연락%', 1, 0),
        no_answer_count = no_answer_count + IF(NEW.call_result LIKE '%무응답%', 1, 0);
END$$

DELIMITER ;
```

---

## 주요 쿼리

### 1. 로그인 인증

```sql
-- Step 1: 업체 계정 인증
SELECT
    company_id,
    company_name,
    max_agents,
    is_active,
    subscription_end_date
FROM companies
WHERE company_login_id = ?
AND company_password = SHA2(?, 256);

-- Step 2: 업체 활성 상태 확인
-- is_active = FALSE면 "사용료 미납" 에러

-- Step 3: 상담원 조회
SELECT
    u.user_id,
    u.user_name,
    u.user_phone,
    u.is_active,
    u.last_login_at,
    c.company_id,
    c.company_name
FROM users u
JOIN companies c ON u.company_id = c.company_id
WHERE c.company_id = ?
AND u.user_name = ?;

-- Step 4: 상담원 수 확인
SELECT COUNT(*) as agent_count, max_agents
FROM users u
JOIN companies c ON u.company_id = c.company_id
WHERE c.company_id = ?
GROUP BY max_agents;

-- Step 5: 최종 로그인 시간 업데이트
UPDATE users
SET last_login_at = NOW()
WHERE user_id = ?;
```

### 2. 상담원별 할당된 DB 목록 조회

```sql
SELECT
    d.db_id,
    d.db_title,
    d.db_date,
    d.total_count,
    d.unused_count,
    a.assigned_count,
    a.completed_count,
    a.in_progress_count
FROM db_assignments a
JOIN db_lists d ON a.db_id = d.db_id
WHERE a.user_id = ?
ORDER BY d.db_date DESC;
```

### 3. 상담원별 미사용 고객 조회 (다음 고객 가져오기)

```sql
SELECT
    customer_id,
    customer_name,
    customer_phone,
    customer_info1,
    customer_info2,
    customer_info3,
    event_name
FROM customers
WHERE db_id = ?
AND assigned_user_id = ?
AND data_status = '미사용'
ORDER BY customer_id
LIMIT 1;
```

### 4. 업체별 전체 통계 조회 (업체 관리자용)

```sql
-- 업체 전체 통계 (모든 상담원 합계)
SELECT
    c.company_name,
    COUNT(DISTINCT u.user_id) as total_agents,
    SUM(s.total_call_count) as total_calls,
    SUM(s.success_count) as total_success,
    SUM(s.failed_count) as total_failed
FROM companies c
LEFT JOIN users u ON c.company_id = u.company_id
LEFT JOIN statistics s ON u.user_id = s.user_id AND s.stat_date = CURDATE()
WHERE c.company_id = ?
GROUP BY c.company_id, c.company_name;

-- 상담원별 상세 통계
SELECT
    u.user_name,
    u.user_phone,
    s.total_call_count,
    s.total_call_time,
    s.success_count,
    s.failed_count,
    s.callback_count,
    s.no_answer_count
FROM users u
LEFT JOIN statistics s ON u.user_id = s.user_id AND s.stat_date = CURDATE()
WHERE u.company_id = ?
ORDER BY u.user_name;
```

### 5. 슈퍼 어드민용 - 전체 업체 현황

```sql
SELECT
    c.company_id,
    c.company_login_id,
    c.company_name,
    c.is_active,
    c.max_agents,
    COUNT(DISTINCT u.user_id) as current_agents,
    COUNT(DISTINCT d.db_id) as total_dbs,
    SUM(d.total_count) as total_customers,
    c.subscription_end_date
FROM companies c
LEFT JOIN users u ON c.company_id = u.company_id
LEFT JOIN db_lists d ON c.company_id = d.company_id
GROUP BY c.company_id
ORDER BY c.is_active DESC, c.company_name;
```

### 6. 업체 활성/비활성 설정 (슈퍼 어드민)

```sql
-- 비활성화 (사용료 미납 등)
UPDATE companies
SET is_active = FALSE,
    updated_at = NOW()
WHERE company_id = ?;

-- 활성화
UPDATE companies
SET is_active = TRUE,
    updated_at = NOW()
WHERE company_id = ?;
```

### 7. 상담원 등록 (업체 관리자)

```sql
-- 상담원 수 확인
SELECT COUNT(*) as current_count, max_agents
FROM users u
JOIN companies c ON u.company_id = c.company_id
WHERE c.company_id = ?
GROUP BY max_agents;

-- 제한 내에서 상담원 추가
INSERT INTO users (company_id, user_name, user_phone, user_status_message)
VALUES (?, ?, ?, ?);
```

### 8. DB 할당 (업체 관리자)

```sql
-- DB 내 고객들을 상담원에게 할당
UPDATE customers
SET assigned_user_id = ?,
    last_modified_date = NOW()
WHERE db_id = ?
AND data_status = '미사용'
AND assigned_user_id IS NULL
LIMIT ?;  -- 할당할 고객 수

-- DB 할당 기록 생성/업데이트
INSERT INTO db_assignments (db_id, user_id, company_id, assigned_count)
VALUES (?, ?, ?, ?)
ON DUPLICATE KEY UPDATE
    assigned_count = assigned_count + VALUES(assigned_count),
    updated_at = NOW();
```

---

## 인덱스 최적화

- **companies**: company_login_id (로그인), is_active (활성 상태 필터)
- **users**: company_id + user_name (로그인), company_id (업체별 조회)
- **db_lists**: company_id (업체별 DB), db_date (날짜순 정렬)
- **db_assignments**: user_id (상담원별 할당), db_id + user_id (중복 방지)
- **customers**: assigned_user_id + data_status (미사용 고객 조회), db_id (DB별 고객)
- **call_logs**: company_id + call_datetime (업체별 로그), user_id (상담원별 로그)
- **statistics**: company_id + stat_date (업체별 통계), user_id + stat_date (상담원별 통계)

---

## 마이그레이션 가이드

### 기존 데이터 → 새 구조 변환

```sql
-- 1. 기존 users 데이터 백업
CREATE TABLE users_backup AS SELECT * FROM users;

-- 2. 임시 업체 생성 (기존 상담원들을 위한)
INSERT INTO companies (company_login_id, company_password, company_name, max_agents)
VALUES ('legacy_company', SHA2('temp_password', 256), '기존 사용자', 100);

-- 3. 기존 상담원들을 임시 업체에 할당
UPDATE users SET company_id = 1;  -- legacy_company의 ID가 1이라고 가정

-- 4. user_login_id, user_password 컬럼 삭제
ALTER TABLE users DROP COLUMN user_login_id;
ALTER TABLE users DROP COLUMN user_password;

-- 5. 기존 db_lists에 company_id 할당
UPDATE db_lists SET company_id = 1;  -- 모든 DB를 legacy_company에 할당
```

---

## 보안 권장사항

1. **업체 비밀번호**: SHA2(256) 또는 bcrypt 사용
2. **JWT 토큰**: userId, companyId, agentName 포함
3. **접근 제어**:
   - 상담원은 자신이 할당받은 DB만 접근
   - 업체 관리자는 자신의 업체 데이터만 접근
   - 슈퍼 어드민만 전체 업체 관리 가능
4. **정기 백업**: 일별 자동 백업
5. **감사 로그**: 업체 활성/비활성 변경 이력 기록

---

## 변경 이력

**v3.0.0** (2025-10-24):
- ✅ companies 테이블 추가 (업체 계정)
- ✅ db_assignments 테이블 추가 (DB 할당 추적)
- ✅ users 테이블 수정 (company_id 추가, login_id/password 삭제)
- ✅ db_lists 테이블 수정 (company_id 추가)
- ✅ customers 테이블 수정 (assigned_user_id 추가)
- ✅ call_logs 테이블 수정 (company_id 추가)
- ✅ statistics 테이블 수정 (company_id 추가)
- ✅ 로그인 프로세스 변경 (업체 ID/PW + 상담원 이름)

**v2.0.0** (2025-10-22):
- 고객정보1-3으로 축소
- 통화시작/종료시간 추가
- 통화예약일/시간 추가
- CSV 컬럼 18개로 확정

**v1.0.0** (2025-10-14):
- 최초 설계
