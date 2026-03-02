-- ============================================================
-- schema.sql - PostgreSQL 스키마 초기화 스크립트
-- 기존 테이블이 있으면 삭제 후 재생성
-- ============================================================

-- DROP (CASCADE로 FK 제약조건 포함 삭제)
DROP TABLE IF EXISTS onboarding_preferences CASCADE;
DROP TABLE IF EXISTS withdrawal_requests CASCADE;
DROP TABLE IF EXISTS dev_users CASCADE;
DROP TABLE IF EXISTS user_sns CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS team_season_stats CASCADE;
DROP TABLE IF EXISTS matches CASCADE;
DROP TABLE IF EXISTS clubs CASCADE;
DROP TABLE IF EXISTS stadiums CASCADE;

-- ============================================================
-- stadiums
-- ============================================================
CREATE TABLE stadiums (
    id         BIGINT       PRIMARY KEY,
    region     VARCHAR(50)  NOT NULL,
    ko_name    VARCHAR(100) NOT NULL,
    en_name    VARCHAR(100),
    address    VARCHAR(255),
    created_at TIMESTAMP    NOT NULL,
    updated_at TIMESTAMP    NOT NULL
);

-- ============================================================
-- clubs
-- ============================================================
CREATE TABLE clubs (
    id                   BIGINT       PRIMARY KEY,
    ko_name              VARCHAR(100) NOT NULL,
    en_name              VARCHAR(100),
    logo_img             VARCHAR(255),
    club_color           VARCHAR(20),
    stadium_id           BIGINT       NOT NULL,
    homepage_redirect_url VARCHAR(255),
    created_at           TIMESTAMP    NOT NULL,
    updated_at           TIMESTAMP    NOT NULL,
    CONSTRAINT fk_clubs_stadium_id FOREIGN KEY (stadium_id) REFERENCES stadiums (id)
);

-- ============================================================
-- matches
-- ============================================================
CREATE TABLE matches (
    id           BIGSERIAL   PRIMARY KEY,
    match_at     TIMESTAMP   NOT NULL,
    home_club_id BIGINT      NOT NULL,
    away_club_id BIGINT      NOT NULL,
    stadium_id   BIGINT      NOT NULL,
    sale_status  VARCHAR(20) NOT NULL,
    created_at   TIMESTAMP   NOT NULL,
    updated_at   TIMESTAMP   NOT NULL,
    CONSTRAINT fk_matches_home_club_id FOREIGN KEY (home_club_id) REFERENCES clubs (id),
    CONSTRAINT fk_matches_away_club_id FOREIGN KEY (away_club_id) REFERENCES clubs (id),
    CONSTRAINT fk_matches_stadium_id   FOREIGN KEY (stadium_id)   REFERENCES stadiums (id)
);

-- ============================================================
-- team_season_stats
-- ============================================================
CREATE TABLE team_season_stats (
    id              BIGSERIAL    PRIMARY KEY,
    club_id         BIGINT       NOT NULL,
    season_year     INTEGER      NOT NULL,
    season_ranking  INTEGER,
    wins            INTEGER      DEFAULT 0,
    draws           INTEGER      DEFAULT 0,
    losses          INTEGER      DEFAULT 0,
    win_rate        DECIMAL(5,3),
    batting_average DECIMAL(5,3),
    era             DECIMAL(4,2),
    games_behind    DECIMAL(4,1),
    created_at      TIMESTAMP    NOT NULL,
    updated_at      TIMESTAMP    NOT NULL,
    CONSTRAINT fk_team_season_stats_club_id FOREIGN KEY (club_id) REFERENCES clubs (id)
);

-- ============================================================
-- users
-- ============================================================
CREATE TABLE users (
    id                      BIGSERIAL    PRIMARY KEY,
    status                  VARCHAR(20)  NOT NULL DEFAULT 'ACTIVATE',
    email                   VARCHAR(255),
    nickname                VARCHAR(100),
    profile_image_url       TEXT,
    onboarding_completed    BOOLEAN      NOT NULL DEFAULT false,
    onboarding_completed_at TIMESTAMP,
    last_login_at           TIMESTAMP,
    marketing_consent       BOOLEAN      NOT NULL DEFAULT false,
    marketing_consented_at  TIMESTAMP,
    created_at              TIMESTAMP    NOT NULL,
    updated_at              TIMESTAMP    NOT NULL
);

-- ============================================================
-- user_sns
-- ============================================================
CREATE TABLE user_sns (
    id               BIGSERIAL    PRIMARY KEY,
    user_id          BIGINT       NOT NULL,
    provider         VARCHAR(20)  NOT NULL,
    provider_user_id VARCHAR(128) NOT NULL,
    created_at       TIMESTAMP    NOT NULL,
    updated_at       TIMESTAMP    NOT NULL,
    CONSTRAINT fk_user_sns_user_id  FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT uq_user_sns_provider UNIQUE (provider, provider_user_id)
);

CREATE INDEX idx_user_sns_user_id ON user_sns (user_id);

-- ============================================================
-- dev_users
-- ============================================================
CREATE TABLE dev_users (
    id            BIGSERIAL    PRIMARY KEY,
    login_id      VARCHAR(50)  NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    user_id       BIGINT       NOT NULL UNIQUE,
    created_at    TIMESTAMP    NOT NULL,
    updated_at    TIMESTAMP    NOT NULL,
    CONSTRAINT fk_dev_users_user_id FOREIGN KEY (user_id) REFERENCES users (id)
);

-- ============================================================
-- withdrawal_requests
-- ============================================================
CREATE TABLE withdrawal_requests (
    id           BIGSERIAL   PRIMARY KEY,
    user_id      BIGINT      NOT NULL UNIQUE,
    requested_at TIMESTAMP   NOT NULL,
    effective_at TIMESTAMP   NOT NULL,
    status       VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',
    cancelled_at TIMESTAMP,
    created_at   TIMESTAMP   NOT NULL,
    CONSTRAINT fk_withdrawal_requests_user_id FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE INDEX idx_withdrawal_requests_effective_at ON withdrawal_requests (effective_at);

-- ============================================================
-- onboarding_preferences
-- ============================================================
CREATE TABLE onboarding_preferences (
    id                      BIGSERIAL   PRIMARY KEY,
    user_id                 BIGINT      NOT NULL,
    priority                INTEGER     NOT NULL,
    viewpoint               VARCHAR(30) NOT NULL,
    seat_height             VARCHAR(20) NOT NULL,
    section                 VARCHAR(20) NOT NULL,
    seat_position_pref      VARCHAR(20) NOT NULL DEFAULT 'ANY',
    environment_pref        VARCHAR(20) NOT NULL DEFAULT 'ANY',
    mood_pref               VARCHAR(20) NOT NULL DEFAULT 'ANY',
    obstruction_sensitivity VARCHAR(30) NOT NULL DEFAULT 'NORMAL',
    price_mode              VARCHAR(20) NOT NULL DEFAULT 'ANY',
    price_min               INTEGER,
    price_max               INTEGER,
    created_at              TIMESTAMP   NOT NULL,
    updated_at              TIMESTAMP   NOT NULL,
    CONSTRAINT fk_onboarding_preferences_user_id  FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT uq_onboarding_pref_priority         UNIQUE (user_id, priority),
    CONSTRAINT uq_onboarding_pref_viewpoint        UNIQUE (user_id, viewpoint),
    CONSTRAINT uq_onboarding_pref_seat_height      UNIQUE (user_id, seat_height),
    CONSTRAINT uq_onboarding_pref_section          UNIQUE (user_id, section)
);

CREATE INDEX idx_onboarding_preferences_user_id    ON onboarding_preferences (user_id);
CREATE INDEX idx_onboarding_preferences_price_mode ON onboarding_preferences (price_mode);
CREATE INDEX idx_onboarding_preferences_price_min  ON onboarding_preferences (price_min);
CREATE INDEX idx_onboarding_preferences_price_max  ON onboarding_preferences (price_max);
-- ========================================
-- STADIUMS 테이블 INSERT (region: 구장 약칭, 11개 구장)
-- ========================================

INSERT INTO stadiums (id, region, ko_name, en_name, address, created_at, updated_at) 
VALUES (1, '잠실', '잠실종합운동장 잠실야구장', 'Jamsil Baseball Stadium', '서울 송파구 올림픽로 19-2 서울종합운동장', NOW(), NOW());

INSERT INTO stadiums (id, region, ko_name, en_name, address, created_at, updated_at) 
VALUES (2, '문학', '인천SSG 랜더스필드', 'Incheon SSG Landers Field', '인천광역시 남동구 매소홀로 618', NOW(), NOW());

INSERT INTO stadiums (id, region, ko_name, en_name, address, created_at, updated_at) 
VALUES (3, '대구', '대구삼성라이온즈파크', 'Daegu Samsung Lions Park', '대구 수성구 야구전설로 1 대구삼성라이온즈파크', NOW(), NOW());

INSERT INTO stadiums (id, region, ko_name, en_name, address, created_at, updated_at) 
VALUES (4, '창원', '창원NC파크', 'Changwon NC Park', '경남 창원시 마산회원구 삼호로 63', NOW(), NOW());

INSERT INTO stadiums (id, region, ko_name, en_name, address, created_at, updated_at) 
VALUES (5, '대전', '대전한화생명볼파크', 'Hanwha Life Eagles Park', '대전 중구 대종로 373', NOW(), NOW());

INSERT INTO stadiums (id, region, ko_name, en_name, address, created_at, updated_at) 
VALUES (6, '사직', '부산사직종합운동장 사직야구장', 'Sajik Baseball Stadium', '부산 동래구 사직로 55-32', NOW(), NOW());

INSERT INTO stadiums (id, region, ko_name, en_name, address, created_at, updated_at) 
VALUES (7, '수원', '수원KT위즈파크', 'Suwon KT Wiz Park', '경기 수원시 장안구 경수대로 893 수원종합운동장(주경기장)', NOW(), NOW());

INSERT INTO stadiums (id, region, ko_name, en_name, address, created_at, updated_at) 
VALUES (8, '광주', '광주기아챔피언스필드', 'Gwangju-Kia Champions Field', '광주 북구 서림로 10 무등종합경기장', NOW(), NOW());

INSERT INTO stadiums (id, region, ko_name, en_name, address, created_at, updated_at) 
VALUES (9, '고척', '고척스카이돔', 'Gocheok Sky Dome', '서울 구로구 경인로 430', NOW(), NOW());

-- 스프링 캠프 구장 (전지훈련)
INSERT INTO stadiums (id, region, ko_name, en_name, address, created_at, updated_at) 
VALUES (10, '마산', '마산야구장', 'Masan Baseball Stadium', '경남 창원시 마산회원구 삼호로 63 마산공설운동장', NOW(), NOW());

INSERT INTO stadiums (id, region, ko_name, en_name, address, created_at, updated_at) 
VALUES (11, '이천', '두산베어스파크', 'Doosan Bears Park', '경기 이천시 백사면 원적로 668', NOW(), NOW());

-- ========================================
-- CLUBS 테이블 INSERT
-- ========================================

INSERT INTO clubs (id, ko_name, en_name, logo_img, club_color, stadium_id, homepage_redirect_url, created_at, updated_at)
VALUES (1, '두산 베어스', 'Doosan Bears', 'doosan-bears.png', '#121130', 1, NULL, NOW(), NOW());

INSERT INTO clubs (id, ko_name, en_name, logo_img, club_color, stadium_id, homepage_redirect_url, created_at, updated_at)
VALUES (2, '삼성 라이온즈', 'Samsung Lions', 'samsung-lions.png', '#0472C4', 3, NULL, NOW(), NOW());

INSERT INTO clubs (id, ko_name, en_name, logo_img, club_color, stadium_id, homepage_redirect_url, created_at, updated_at)
VALUES (3, '키움 히어로즈', 'Kiwoom Heroes', 'kiwoom-heroes.png', '#6C1126', 9, NULL, NOW(), NOW());

INSERT INTO clubs (id, ko_name, en_name, logo_img, club_color, stadium_id, homepage_redirect_url, created_at, updated_at)
VALUES (4, '한화 이글스', 'Hanwha Eagles', 'hanwha-eagles.png', '#E27032', 5, NULL, NOW(), NOW());

INSERT INTO clubs (id, ko_name, en_name, logo_img, club_color, stadium_id, homepage_redirect_url, created_at, updated_at)
VALUES (5, '롯데 자이언츠', 'Lotte Giants', 'lotte-giants.png', '#072C5A', 6, NULL, NOW(), NOW());

INSERT INTO clubs (id, ko_name, en_name, logo_img, club_color, stadium_id, homepage_redirect_url, created_at, updated_at)
VALUES (6, 'LG 트윈스', 'LG Twins', 'lg-twins.png', '#A32C41', 1, NULL, NOW(), NOW());

INSERT INTO clubs (id, ko_name, en_name, logo_img, club_color, stadium_id, homepage_redirect_url, created_at, updated_at)
VALUES (7, 'NC 다이노스', 'NC Dinos', 'nc-dinos.png', '#1C467D', 4, NULL, NOW(), NOW());

INSERT INTO clubs (id, ko_name, en_name, logo_img, club_color, stadium_id, homepage_redirect_url, created_at, updated_at)
VALUES (8, 'SSG 랜더스', 'SSG Landers', 'ssg-landers.png', '#BB2F45', 2, NULL, NOW(), NOW());

INSERT INTO clubs (id, ko_name, en_name, logo_img, club_color, stadium_id, homepage_redirect_url, created_at, updated_at)
VALUES (9, 'kt 위즈', 'kt wiz', 'kt-wiz.png', '#231F20', 7, NULL, NOW(), NOW());

INSERT INTO clubs (id, ko_name, en_name, logo_img, club_color, stadium_id, homepage_redirect_url, created_at, updated_at)
VALUES (10, 'KIA 타이거즈', 'KIA Tigers', 'kia-tigers.png', '#A32425', 8, NULL, NOW(), NOW());

-- ========================================
-- USERS 테이블 INSERT (10명)
-- ========================================
INSERT INTO users (id, status, email, nickname, onboarding_completed, created_at, updated_at) VALUES
  (1, 'ACTIVATE', 'test1@test.com', '테스트유저1', false, NOW(), NOW()),
  (2, 'ACTIVATE', 'test2@test.com', '테스트유저2', false, NOW(), NOW()),
  (3, 'ACTIVATE', 'test3@test.com', '테스트유저3', false, NOW(), NOW()),
  (4, 'ACTIVATE', 'test4@test.com', '테스트유저4', false, NOW(), NOW()),
  (5, 'ACTIVATE', 'test5@test.com', '테스트유저5', false, NOW(), NOW()),
  (6, 'ACTIVATE', 'admin@test.com', '관리자', false, NOW(), NOW()),
  (7, 'ACTIVATE', 'dev@test.com', '개발자', false, NOW(), NOW()),
  (8, 'ACTIVATE', 'tester@test.com', '테스터', false, NOW(), NOW()),
  (9, 'ACTIVATE', 'demo@test.com', '데모유저', false, NOW(), NOW()),
  (10, 'ACTIVATE', 'guest@test.com', '게스트', false, NOW(), NOW());

-- ========================================
-- DEV_USERS 테이블 INSERT (비밀번호: 1234)
-- bcrypt hash: $2a$12$3e9.mC5v.Ho.fRz5O.ppPe3ND3CMLjzQcaiPPHfjM4OvS6t/JAu9e
-- ========================================
INSERT INTO dev_users (id, login_id, password_hash, user_id, created_at, updated_at) VALUES
  (1, 'test1', '$2a$12$3e9.mC5v.Ho.fRz5O.ppPe3ND3CMLjzQcaiPPHfjM4OvS6t/JAu9e', 1, NOW(), NOW()),
  (2, 'test2', '$2a$12$3e9.mC5v.Ho.fRz5O.ppPe3ND3CMLjzQcaiPPHfjM4OvS6t/JAu9e', 2, NOW(), NOW()),
  (3, 'test3', '$2a$12$3e9.mC5v.Ho.fRz5O.ppPe3ND3CMLjzQcaiPPHfjM4OvS6t/JAu9e', 3, NOW(), NOW()),
  (4, 'test4', '$2a$12$3e9.mC5v.Ho.fRz5O.ppPe3ND3CMLjzQcaiPPHfjM4OvS6t/JAu9e', 4, NOW(), NOW()),
  (5, 'test5', '$2a$12$3e9.mC5v.Ho.fRz5O.ppPe3ND3CMLjzQcaiPPHfjM4OvS6t/JAu9e', 5, NOW(), NOW()),
  (6, 'admin', '$2a$12$3e9.mC5v.Ho.fRz5O.ppPe3ND3CMLjzQcaiPPHfjM4OvS6t/JAu9e', 6, NOW(), NOW()),
  (7, 'dev', '$2a$12$3e9.mC5v.Ho.fRz5O.ppPe3ND3CMLjzQcaiPPHfjM4OvS6t/JAu9e', 7, NOW(), NOW()),
  (8, 'tester', '$2a$12$3e9.mC5v.Ho.fRz5O.ppPe3ND3CMLjzQcaiPPHfjM4OvS6t/JAu9e', 8, NOW(), NOW()),
  (9, 'demo', '$2a$12$3e9.mC5v.Ho.fRz5O.ppPe3ND3CMLjzQcaiPPHfjM4OvS6t/JAu9e', 9, NOW(), NOW()),
  (10, 'guest', '$2a$12$3e9.mC5v.Ho.fRz5O.ppPe3ND3CMLjzQcaiPPHfjM4OvS6t/JAu9e', 10, NOW(), NOW());

-- Sequence 업데이트
SELECT setval('users_id_seq', 10);
SELECT setval('dev_users_id_seq', 10);

-- ========================================
-- MATCHES 테이블 INSERT (2월 15일 ~ 4월 15일, 매일 5경기)
-- ENDED: 과거 경기, ON_SALE: 현재 판매중, UPCOMING: 예정
-- ========================================
-- MATCHES 테이블 INSERT (3월 1일 ~ 5월 4일, 매일 5경기)
-- ON_SALE: 3/1~3/7, UPCOMING: 3/8~5/4
-- ========================================
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES
  -- 3월 1일 (토) - ON_SALE
  ('2026-03-01 14:00:00', 1, 2, 1, 'ON_SALE', NOW(), NOW()),
  ('2026-03-01 14:00:00', 3, 4, 9, 'ON_SALE', NOW(), NOW()),
  ('2026-03-01 14:00:00', 5, 6, 6, 'ON_SALE', NOW(), NOW()),
  ('2026-03-01 14:00:00', 7, 8, 4, 'ON_SALE', NOW(), NOW()),
  ('2026-03-01 14:00:00', 9, 10, 7, 'ON_SALE', NOW(), NOW()),
  -- 3월 2일 (일) - ON_SALE
  ('2026-03-02 14:00:00', 2, 1, 3, 'ON_SALE', NOW(), NOW()),
  ('2026-03-02 14:00:00', 4, 3, 5, 'ON_SALE', NOW(), NOW()),
  ('2026-03-02 14:00:00', 6, 5, 1, 'ON_SALE', NOW(), NOW()),
  ('2026-03-02 14:00:00', 8, 7, 2, 'ON_SALE', NOW(), NOW()),
  ('2026-03-02 14:00:00', 10, 9, 8, 'ON_SALE', NOW(), NOW()),
  -- 3월 3일 (월) - ON_SALE
  ('2026-03-03 18:30:00', 1, 3, 1, 'ON_SALE', NOW(), NOW()),
  ('2026-03-03 18:30:00', 2, 4, 3, 'ON_SALE', NOW(), NOW()),
  ('2026-03-03 18:30:00', 5, 7, 6, 'ON_SALE', NOW(), NOW()),
  ('2026-03-03 18:30:00', 6, 8, 1, 'ON_SALE', NOW(), NOW()),
  ('2026-03-03 18:30:00', 9, 10, 7, 'ON_SALE', NOW(), NOW()),
  -- 3월 4일 (화) - ON_SALE
  ('2026-03-04 18:30:00', 3, 1, 9, 'ON_SALE', NOW(), NOW()),
  ('2026-03-04 18:30:00', 4, 2, 5, 'ON_SALE', NOW(), NOW()),
  ('2026-03-04 18:30:00', 7, 5, 4, 'ON_SALE', NOW(), NOW()),
  ('2026-03-04 18:30:00', 8, 6, 2, 'ON_SALE', NOW(), NOW()),
  ('2026-03-04 18:30:00', 10, 9, 8, 'ON_SALE', NOW(), NOW()),
  -- 3월 5일 (수) - ON_SALE
  ('2026-03-05 18:30:00', 1, 4, 1, 'ON_SALE', NOW(), NOW()),
  ('2026-03-05 18:30:00', 2, 5, 3, 'ON_SALE', NOW(), NOW()),
  ('2026-03-05 18:30:00', 3, 6, 9, 'ON_SALE', NOW(), NOW()),
  ('2026-03-05 18:30:00', 7, 10, 4, 'ON_SALE', NOW(), NOW()),
  ('2026-03-05 18:30:00', 8, 9, 2, 'ON_SALE', NOW(), NOW()),
  -- 3월 6일 (목) - ON_SALE
  ('2026-03-06 18:30:00', 4, 1, 5, 'ON_SALE', NOW(), NOW()),
  ('2026-03-06 18:30:00', 5, 2, 6, 'ON_SALE', NOW(), NOW()),
  ('2026-03-06 18:30:00', 6, 3, 1, 'ON_SALE', NOW(), NOW()),
  ('2026-03-06 18:30:00', 10, 7, 8, 'ON_SALE', NOW(), NOW()),
  ('2026-03-06 18:30:00', 9, 8, 7, 'ON_SALE', NOW(), NOW()),
  -- 3월 7일 (금) - ON_SALE
  ('2026-03-07 18:30:00', 1, 5, 1, 'ON_SALE', NOW(), NOW()),
  ('2026-03-07 18:30:00', 2, 6, 3, 'ON_SALE', NOW(), NOW()),
  ('2026-03-07 18:30:00', 3, 7, 9, 'ON_SALE', NOW(), NOW()),
  ('2026-03-07 18:30:00', 4, 8, 5, 'ON_SALE', NOW(), NOW()),
  ('2026-03-07 18:30:00', 9, 10, 7, 'ON_SALE', NOW(), NOW()),
  -- 3월 8일 (토) - UPCOMING
  ('2026-03-08 14:00:00', 5, 1, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-03-08 14:00:00', 6, 2, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-08 14:00:00', 7, 3, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-03-08 14:00:00', 8, 4, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-03-08 14:00:00', 10, 9, 8, 'UPCOMING', NOW(), NOW()),
  -- 3월 9일 (일) - UPCOMING
  ('2026-03-09 14:00:00', 1, 6, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-09 14:00:00', 2, 7, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-03-09 14:00:00', 3, 8, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-03-09 14:00:00', 4, 9, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-03-09 14:00:00', 5, 10, 6, 'UPCOMING', NOW(), NOW()),
  -- 3월 10일 (월) - UPCOMING
  ('2026-03-10 18:30:00', 6, 1, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-10 18:30:00', 7, 2, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-03-10 18:30:00', 8, 3, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-03-10 18:30:00', 9, 4, 7, 'UPCOMING', NOW(), NOW()),
  ('2026-03-10 18:30:00', 10, 5, 8, 'UPCOMING', NOW(), NOW()),
  -- 3월 11일 (화) - UPCOMING
  ('2026-03-11 18:30:00', 1, 7, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-11 18:30:00', 2, 8, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-03-11 18:30:00', 3, 9, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-03-11 18:30:00', 4, 10, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-03-11 18:30:00', 5, 6, 6, 'UPCOMING', NOW(), NOW()),
  -- 3월 12일 (수) - UPCOMING
  ('2026-03-12 18:30:00', 7, 1, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-03-12 18:30:00', 8, 2, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-03-12 18:30:00', 9, 3, 7, 'UPCOMING', NOW(), NOW()),
  ('2026-03-12 18:30:00', 10, 4, 8, 'UPCOMING', NOW(), NOW()),
  ('2026-03-12 18:30:00', 6, 5, 1, 'UPCOMING', NOW(), NOW()),
  -- 3월 13일 (목) - UPCOMING
  ('2026-03-13 18:30:00', 1, 8, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-13 18:30:00', 2, 9, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-03-13 18:30:00', 3, 10, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-03-13 18:30:00', 4, 5, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-03-13 18:30:00', 6, 7, 1, 'UPCOMING', NOW(), NOW()),
  -- 3월 14일 (금) - UPCOMING
  ('2026-03-14 18:30:00', 8, 1, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-03-14 18:30:00', 9, 2, 7, 'UPCOMING', NOW(), NOW()),
  ('2026-03-14 18:30:00', 10, 3, 8, 'UPCOMING', NOW(), NOW()),
  ('2026-03-14 18:30:00', 5, 4, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-03-14 18:30:00', 7, 6, 4, 'UPCOMING', NOW(), NOW()),
  -- 3월 15일 (토) - UPCOMING
  ('2026-03-15 14:00:00', 1, 9, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-15 14:00:00', 2, 10, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-03-15 14:00:00', 3, 5, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-03-15 14:00:00', 4, 6, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-03-15 14:00:00', 7, 8, 4, 'UPCOMING', NOW(), NOW()),
  -- 3월 16일 (일) - UPCOMING
  ('2026-03-16 14:00:00', 9, 1, 7, 'UPCOMING', NOW(), NOW()),
  ('2026-03-16 14:00:00', 10, 2, 8, 'UPCOMING', NOW(), NOW()),
  ('2026-03-16 14:00:00', 5, 3, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-03-16 14:00:00', 6, 4, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-16 14:00:00', 8, 7, 2, 'UPCOMING', NOW(), NOW()),
  -- 3월 17일 (월) - UPCOMING
  ('2026-03-17 18:30:00', 1, 10, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-17 18:30:00', 2, 5, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-03-17 18:30:00', 3, 6, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-03-17 18:30:00', 4, 7, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-03-17 18:30:00', 8, 9, 2, 'UPCOMING', NOW(), NOW()),
  -- 3월 18일 (화) - UPCOMING
  ('2026-03-18 18:30:00', 10, 1, 8, 'UPCOMING', NOW(), NOW()),
  ('2026-03-18 18:30:00', 5, 2, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-03-18 18:30:00', 6, 3, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-18 18:30:00', 7, 4, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-03-18 18:30:00', 9, 8, 7, 'UPCOMING', NOW(), NOW()),
  -- 3월 19일 (수) - UPCOMING
  ('2026-03-19 18:30:00', 1, 2, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-19 18:30:00', 3, 4, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-03-19 18:30:00', 5, 6, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-03-19 18:30:00', 7, 8, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-03-19 18:30:00', 9, 10, 7, 'UPCOMING', NOW(), NOW()),
  -- 3월 20일 (목) - UPCOMING
  ('2026-03-20 18:30:00', 2, 1, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-03-20 18:30:00', 4, 3, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-03-20 18:30:00', 6, 5, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-20 18:30:00', 8, 7, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-03-20 18:30:00', 10, 9, 8, 'UPCOMING', NOW(), NOW()),
  -- 3월 21일 (금) - UPCOMING
  ('2026-03-21 18:30:00', 1, 3, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-21 18:30:00', 2, 4, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-03-21 18:30:00', 5, 7, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-03-21 18:30:00', 6, 8, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-21 18:30:00', 9, 10, 7, 'UPCOMING', NOW(), NOW()),
  -- 3월 22일 (토) - UPCOMING
  ('2026-03-22 14:00:00', 3, 1, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-03-22 14:00:00', 4, 2, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-03-22 14:00:00', 7, 5, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-03-22 14:00:00', 8, 6, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-03-22 14:00:00', 10, 9, 8, 'UPCOMING', NOW(), NOW()),
  -- 3월 23일 (일) - UPCOMING
  ('2026-03-23 14:00:00', 1, 4, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-23 14:00:00', 2, 5, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-03-23 14:00:00', 3, 6, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-03-23 14:00:00', 7, 10, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-03-23 14:00:00', 8, 9, 2, 'UPCOMING', NOW(), NOW()),
  -- 3월 24일 (월) - UPCOMING
  ('2026-03-24 18:30:00', 4, 1, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-03-24 18:30:00', 5, 2, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-03-24 18:30:00', 6, 3, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-24 18:30:00', 10, 7, 8, 'UPCOMING', NOW(), NOW()),
  ('2026-03-24 18:30:00', 9, 8, 7, 'UPCOMING', NOW(), NOW()),
  -- 3월 25일 (화) - UPCOMING
  ('2026-03-25 18:30:00', 1, 5, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-25 18:30:00', 2, 6, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-03-25 18:30:00', 3, 7, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-03-25 18:30:00', 4, 8, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-03-25 18:30:00', 9, 10, 7, 'UPCOMING', NOW(), NOW()),
  -- 3월 26일 (수) - UPCOMING
  ('2026-03-26 18:30:00', 5, 1, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-03-26 18:30:00', 6, 2, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-26 18:30:00', 7, 3, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-03-26 18:30:00', 8, 4, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-03-26 18:30:00', 10, 9, 8, 'UPCOMING', NOW(), NOW()),
  -- 3월 27일 (목) - UPCOMING
  ('2026-03-27 18:30:00', 1, 6, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-27 18:30:00', 2, 7, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-03-27 18:30:00', 3, 8, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-03-27 18:30:00', 4, 9, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-03-27 18:30:00', 5, 10, 6, 'UPCOMING', NOW(), NOW()),
  -- 3월 28일 (금) - UPCOMING
  ('2026-03-28 18:30:00', 6, 1, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-28 18:30:00', 7, 2, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-03-28 18:30:00', 8, 3, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-03-28 18:30:00', 9, 4, 7, 'UPCOMING', NOW(), NOW()),
  ('2026-03-28 18:30:00', 10, 5, 8, 'UPCOMING', NOW(), NOW()),
  -- 3월 29일 (토) - UPCOMING
  ('2026-03-29 14:00:00', 1, 7, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-29 14:00:00', 2, 8, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-03-29 14:00:00', 3, 9, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-03-29 14:00:00', 4, 10, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-03-29 14:00:00', 5, 6, 6, 'UPCOMING', NOW(), NOW()),
  -- 3월 30일 (일) - UPCOMING
  ('2026-03-30 14:00:00', 7, 1, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-03-30 14:00:00', 8, 2, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-03-30 14:00:00', 9, 3, 7, 'UPCOMING', NOW(), NOW()),
  ('2026-03-30 14:00:00', 10, 4, 8, 'UPCOMING', NOW(), NOW()),
  ('2026-03-30 14:00:00', 6, 5, 1, 'UPCOMING', NOW(), NOW()),
  -- 3월 31일 (월) - UPCOMING
  ('2026-03-31 18:30:00', 1, 8, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-03-31 18:30:00', 2, 9, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-03-31 18:30:00', 3, 10, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-03-31 18:30:00', 4, 5, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-03-31 18:30:00', 6, 7, 1, 'UPCOMING', NOW(), NOW()),
  -- 4월 1일 (화) - UPCOMING
  ('2026-04-01 18:30:00', 8, 1, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-04-01 18:30:00', 9, 2, 7, 'UPCOMING', NOW(), NOW()),
  ('2026-04-01 18:30:00', 10, 3, 8, 'UPCOMING', NOW(), NOW()),
  ('2026-04-01 18:30:00', 5, 4, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-04-01 18:30:00', 7, 6, 4, 'UPCOMING', NOW(), NOW()),
  -- 4월 2일 (수) - UPCOMING
  ('2026-04-02 18:30:00', 1, 9, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-02 18:30:00', 2, 10, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-04-02 18:30:00', 3, 5, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-04-02 18:30:00', 4, 6, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-04-02 18:30:00', 7, 8, 4, 'UPCOMING', NOW(), NOW()),
  -- 4월 3일 (목) - UPCOMING
  ('2026-04-03 18:30:00', 9, 1, 7, 'UPCOMING', NOW(), NOW()),
  ('2026-04-03 18:30:00', 10, 2, 8, 'UPCOMING', NOW(), NOW()),
  ('2026-04-03 18:30:00', 5, 3, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-04-03 18:30:00', 6, 4, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-03 18:30:00', 8, 7, 2, 'UPCOMING', NOW(), NOW()),
  -- 4월 4일 (금) - UPCOMING
  ('2026-04-04 18:30:00', 1, 10, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-04 18:30:00', 2, 5, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-04-04 18:30:00', 3, 6, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-04-04 18:30:00', 4, 7, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-04-04 18:30:00', 8, 9, 2, 'UPCOMING', NOW(), NOW()),
  -- 4월 5일 (토) - UPCOMING
  ('2026-04-05 14:00:00', 10, 1, 8, 'UPCOMING', NOW(), NOW()),
  ('2026-04-05 14:00:00', 5, 2, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-04-05 14:00:00', 6, 3, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-05 14:00:00', 7, 4, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-04-05 14:00:00', 9, 8, 7, 'UPCOMING', NOW(), NOW()),
  -- 4월 6일 (일) - UPCOMING
  ('2026-04-06 14:00:00', 1, 2, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-06 14:00:00', 3, 4, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-04-06 14:00:00', 5, 6, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-04-06 14:00:00', 7, 8, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-04-06 14:00:00', 9, 10, 7, 'UPCOMING', NOW(), NOW()),
  -- 4월 7일 (월) - UPCOMING
  ('2026-04-07 18:30:00', 2, 1, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-04-07 18:30:00', 4, 3, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-04-07 18:30:00', 6, 5, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-07 18:30:00', 8, 7, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-04-07 18:30:00', 10, 9, 8, 'UPCOMING', NOW(), NOW()),
  -- 4월 8일 (화) - UPCOMING
  ('2026-04-08 18:30:00', 1, 3, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-08 18:30:00', 2, 4, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-04-08 18:30:00', 5, 7, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-04-08 18:30:00', 6, 8, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-08 18:30:00', 9, 10, 7, 'UPCOMING', NOW(), NOW()),
  -- 4월 9일 (수) - UPCOMING
  ('2026-04-09 18:30:00', 3, 1, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-04-09 18:30:00', 4, 2, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-04-09 18:30:00', 7, 5, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-04-09 18:30:00', 8, 6, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-04-09 18:30:00', 10, 9, 8, 'UPCOMING', NOW(), NOW()),
  -- 4월 10일 (목) - UPCOMING
  ('2026-04-10 18:30:00', 1, 4, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-10 18:30:00', 2, 5, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-04-10 18:30:00', 3, 6, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-04-10 18:30:00', 7, 10, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-04-10 18:30:00', 8, 9, 2, 'UPCOMING', NOW(), NOW()),
  -- 4월 11일 (금) - UPCOMING
  ('2026-04-11 18:30:00', 4, 1, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-04-11 18:30:00', 5, 2, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-04-11 18:30:00', 6, 3, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-11 18:30:00', 10, 7, 8, 'UPCOMING', NOW(), NOW()),
  ('2026-04-11 18:30:00', 9, 8, 7, 'UPCOMING', NOW(), NOW()),
  -- 4월 12일 (토) - UPCOMING
  ('2026-04-12 14:00:00', 1, 5, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-12 14:00:00', 2, 6, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-04-12 14:00:00', 3, 7, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-04-12 14:00:00', 4, 8, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-04-12 14:00:00', 9, 10, 7, 'UPCOMING', NOW(), NOW()),
  -- 4월 13일 (일) - UPCOMING
  ('2026-04-13 14:00:00', 5, 1, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-04-13 14:00:00', 6, 2, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-13 14:00:00', 7, 3, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-04-13 14:00:00', 8, 4, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-04-13 14:00:00', 10, 9, 8, 'UPCOMING', NOW(), NOW()),
  -- 4월 14일 (월) - UPCOMING
  ('2026-04-14 18:30:00', 1, 6, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-14 18:30:00', 2, 7, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-04-14 18:30:00', 3, 8, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-04-14 18:30:00', 4, 9, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-04-14 18:30:00', 5, 10, 6, 'UPCOMING', NOW(), NOW()),
  -- 4월 15일 (화) - UPCOMING
  ('2026-04-15 18:30:00', 6, 1, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-15 18:30:00', 7, 2, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-04-15 18:30:00', 8, 3, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-04-15 18:30:00', 9, 4, 7, 'UPCOMING', NOW(), NOW()),
  ('2026-04-15 18:30:00', 10, 5, 8, 'UPCOMING', NOW(), NOW()),
  -- 4월 16일 (수) - UPCOMING
  ('2026-04-16 18:30:00', 1, 7, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-16 18:30:00', 2, 8, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-04-16 18:30:00', 3, 9, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-04-16 18:30:00', 4, 10, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-04-16 18:30:00', 5, 6, 6, 'UPCOMING', NOW(), NOW()),
  -- 4월 17일 (목) - UPCOMING
  ('2026-04-17 18:30:00', 7, 1, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-04-17 18:30:00', 8, 2, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-04-17 18:30:00', 9, 3, 7, 'UPCOMING', NOW(), NOW()),
  ('2026-04-17 18:30:00', 10, 4, 8, 'UPCOMING', NOW(), NOW()),
  ('2026-04-17 18:30:00', 6, 5, 1, 'UPCOMING', NOW(), NOW()),
  -- 4월 18일 (금) - UPCOMING
  ('2026-04-18 18:30:00', 1, 8, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-18 18:30:00', 2, 9, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-04-18 18:30:00', 3, 10, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-04-18 18:30:00', 4, 5, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-04-18 18:30:00', 6, 7, 1, 'UPCOMING', NOW(), NOW()),
  -- 4월 19일 (토) - UPCOMING
  ('2026-04-19 14:00:00', 8, 1, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-04-19 14:00:00', 9, 2, 7, 'UPCOMING', NOW(), NOW()),
  ('2026-04-19 14:00:00', 10, 3, 8, 'UPCOMING', NOW(), NOW()),
  ('2026-04-19 14:00:00', 5, 4, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-04-19 14:00:00', 7, 6, 4, 'UPCOMING', NOW(), NOW()),
  -- 4월 20일 (일) - UPCOMING
  ('2026-04-20 14:00:00', 1, 9, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-20 14:00:00', 2, 10, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-04-20 14:00:00', 3, 5, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-04-20 14:00:00', 4, 6, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-04-20 14:00:00', 7, 8, 4, 'UPCOMING', NOW(), NOW()),
  -- 4월 21일 (월) - UPCOMING
  ('2026-04-21 18:30:00', 9, 1, 7, 'UPCOMING', NOW(), NOW()),
  ('2026-04-21 18:30:00', 10, 2, 8, 'UPCOMING', NOW(), NOW()),
  ('2026-04-21 18:30:00', 5, 3, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-04-21 18:30:00', 6, 4, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-21 18:30:00', 8, 7, 2, 'UPCOMING', NOW(), NOW()),
  -- 4월 22일 (화) - UPCOMING
  ('2026-04-22 18:30:00', 1, 10, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-22 18:30:00', 2, 5, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-04-22 18:30:00', 3, 6, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-04-22 18:30:00', 4, 7, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-04-22 18:30:00', 8, 9, 2, 'UPCOMING', NOW(), NOW()),
  -- 4월 23일 (수) - UPCOMING
  ('2026-04-23 18:30:00', 10, 1, 8, 'UPCOMING', NOW(), NOW()),
  ('2026-04-23 18:30:00', 5, 2, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-04-23 18:30:00', 6, 3, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-23 18:30:00', 7, 4, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-04-23 18:30:00', 9, 8, 7, 'UPCOMING', NOW(), NOW()),
  -- 4월 24일 (목) - UPCOMING
  ('2026-04-24 18:30:00', 1, 2, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-24 18:30:00', 3, 4, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-04-24 18:30:00', 5, 6, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-04-24 18:30:00', 7, 8, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-04-24 18:30:00', 9, 10, 7, 'UPCOMING', NOW(), NOW()),
  -- 4월 25일 (금) - UPCOMING
  ('2026-04-25 18:30:00', 2, 1, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-04-25 18:30:00', 4, 3, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-04-25 18:30:00', 6, 5, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-25 18:30:00', 8, 7, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-04-25 18:30:00', 10, 9, 8, 'UPCOMING', NOW(), NOW()),
  -- 4월 26일 (토) - UPCOMING
  ('2026-04-26 14:00:00', 1, 3, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-26 14:00:00', 2, 4, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-04-26 14:00:00', 5, 7, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-04-26 14:00:00', 6, 8, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-26 14:00:00', 9, 10, 7, 'UPCOMING', NOW(), NOW()),
  -- 4월 27일 (일) - UPCOMING
  ('2026-04-27 14:00:00', 3, 1, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-04-27 14:00:00', 4, 2, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-04-27 14:00:00', 7, 5, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-04-27 14:00:00', 8, 6, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-04-27 14:00:00', 10, 9, 8, 'UPCOMING', NOW(), NOW()),
  -- 4월 28일 (월) - UPCOMING
  ('2026-04-28 18:30:00', 1, 4, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-28 18:30:00', 2, 5, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-04-28 18:30:00', 3, 6, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-04-28 18:30:00', 7, 10, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-04-28 18:30:00', 8, 9, 2, 'UPCOMING', NOW(), NOW()),
  -- 4월 29일 (화) - UPCOMING
  ('2026-04-29 18:30:00', 4, 1, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-04-29 18:30:00', 5, 2, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-04-29 18:30:00', 6, 3, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-29 18:30:00', 10, 7, 8, 'UPCOMING', NOW(), NOW()),
  ('2026-04-29 18:30:00', 9, 8, 7, 'UPCOMING', NOW(), NOW()),
  -- 4월 30일 (수) - UPCOMING
  ('2026-04-30 18:30:00', 1, 5, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-04-30 18:30:00', 2, 6, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-04-30 18:30:00', 3, 7, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-04-30 18:30:00', 4, 8, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-04-30 18:30:00', 9, 10, 7, 'UPCOMING', NOW(), NOW()),
  -- 5월 1일 (목) - UPCOMING
  ('2026-05-01 14:00:00', 5, 1, 6, 'UPCOMING', NOW(), NOW()),
  ('2026-05-01 14:00:00', 6, 2, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-05-01 14:00:00', 7, 3, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-05-01 14:00:00', 8, 4, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-05-01 14:00:00', 10, 9, 8, 'UPCOMING', NOW(), NOW()),
  -- 5월 2일 (금) - UPCOMING
  ('2026-05-02 18:30:00', 1, 6, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-05-02 18:30:00', 2, 7, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-05-02 18:30:00', 3, 8, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-05-02 18:30:00', 4, 9, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-05-02 18:30:00', 5, 10, 6, 'UPCOMING', NOW(), NOW()),
  -- 5월 3일 (토) - UPCOMING
  ('2026-05-03 14:00:00', 6, 1, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-05-03 14:00:00', 7, 2, 4, 'UPCOMING', NOW(), NOW()),
  ('2026-05-03 14:00:00', 8, 3, 2, 'UPCOMING', NOW(), NOW()),
  ('2026-05-03 14:00:00', 9, 4, 7, 'UPCOMING', NOW(), NOW()),
  ('2026-05-03 14:00:00', 10, 5, 8, 'UPCOMING', NOW(), NOW()),
  -- 5월 4일 (일) - UPCOMING
  ('2026-05-04 14:00:00', 1, 7, 1, 'UPCOMING', NOW(), NOW()),
  ('2026-05-04 14:00:00', 2, 8, 3, 'UPCOMING', NOW(), NOW()),
  ('2026-05-04 14:00:00', 3, 9, 9, 'UPCOMING', NOW(), NOW()),
  ('2026-05-04 14:00:00', 4, 10, 5, 'UPCOMING', NOW(), NOW()),
  ('2026-05-04 14:00:00', 5, 6, 6, 'UPCOMING', NOW(), NOW());
