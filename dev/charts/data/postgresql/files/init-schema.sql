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

INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-03-28T14:00:00', 6, 9, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-03-28T14:00:00', 8, 10, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-03-28T14:00:00', 2, 5, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-03-28T14:00:00', 7, 1, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-03-28T14:00:00', 4, 3, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-03-29T14:00:00', 6, 9, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-03-29T14:00:00', 8, 10, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-03-29T14:00:00', 2, 5, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-03-29T14:00:00', 7, 1, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-03-29T14:00:00', 4, 3, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-03-31T18:30:00', 6, 10, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-03-31T18:30:00', 8, 3, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-03-31T18:30:00', 2, 1, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-03-31T18:30:00', 7, 5, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-03-31T18:30:00', 4, 9, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-01T18:30:00', 6, 10, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-01T18:30:00', 8, 3, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-01T18:30:00', 2, 1, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-01T18:30:00', 7, 5, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-01T18:30:00', 4, 9, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-02T18:30:00', 6, 10, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-02T18:30:00', 8, 3, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-02T18:30:00', 2, 1, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-02T18:30:00', 7, 5, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-02T18:30:00', 4, 9, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-03T18:30:00', 1, 4, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-03T18:30:00', 5, 8, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-03T18:30:00', 9, 2, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-03T18:30:00', 10, 7, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-03T18:30:00', 3, 6, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-04T17:00:00', 1, 4, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-04T17:00:00', 5, 8, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-04T17:00:00', 9, 2, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-04T17:00:00', 10, 7, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-04T17:00:00', 3, 6, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-05T14:00:00', 1, 4, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-05T14:00:00', 5, 8, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-05T14:00:00', 9, 2, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-05T14:00:00', 10, 7, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-05T14:00:00', 3, 6, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-07T18:30:00', 1, 3, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-07T18:30:00', 8, 4, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-07T18:30:00', 5, 9, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-07T18:30:00', 7, 6, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-07T18:30:00', 10, 2, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-08T18:30:00', 1, 3, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-08T18:30:00', 8, 4, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-08T18:30:00', 5, 9, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-08T18:30:00', 7, 6, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-08T18:30:00', 10, 2, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-09T18:30:00', 1, 3, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-09T18:30:00', 8, 4, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-09T18:30:00', 5, 9, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-09T18:30:00', 7, 6, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-09T18:30:00', 10, 2, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-10T18:30:00', 6, 8, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-10T18:30:00', 2, 7, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-10T18:30:00', 9, 1, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-10T18:30:00', 3, 5, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-10T18:30:00', 4, 10, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-11T17:00:00', 6, 8, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-11T17:00:00', 2, 7, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-11T17:00:00', 9, 1, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-11T17:00:00', 3, 5, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-11T17:00:00', 4, 10, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-12T14:00:00', 6, 8, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-12T14:00:00', 2, 7, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-12T14:00:00', 9, 1, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-12T14:00:00', 3, 5, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-12T14:00:00', 4, 10, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-14T18:30:00', 6, 5, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-14T18:30:00', 8, 1, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-14T18:30:00', 7, 9, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-14T18:30:00', 10, 3, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-14T18:30:00', 4, 2, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-15T18:30:00', 6, 5, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-15T18:30:00', 8, 1, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-15T18:30:00', 7, 9, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-15T18:30:00', 10, 3, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-15T18:30:00', 4, 2, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-16T18:30:00', 6, 5, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-16T18:30:00', 8, 1, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-16T18:30:00', 7, 9, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-16T18:30:00', 10, 3, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-16T18:30:00', 4, 2, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-17T18:30:00', 1, 10, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-17T18:30:00', 5, 4, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-17T18:30:00', 2, 6, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-17T18:30:00', 7, 8, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-17T18:30:00', 9, 3, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-18T17:00:00', 1, 10, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-18T17:00:00', 5, 4, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-18T17:00:00', 2, 6, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-18T17:00:00', 7, 8, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-18T17:00:00', 9, 3, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-19T14:00:00', 1, 10, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-19T14:00:00', 5, 4, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-19T14:00:00', 2, 6, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-19T14:00:00', 7, 8, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-19T14:00:00', 9, 3, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-21T18:30:00', 6, 4, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-21T18:30:00', 5, 1, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-21T18:30:00', 2, 8, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-21T18:30:00', 9, 10, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-21T18:30:00', 3, 7, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-22T18:30:00', 6, 4, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-22T18:30:00', 5, 1, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-22T18:30:00', 2, 8, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-22T18:30:00', 9, 10, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-22T18:30:00', 3, 7, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-23T18:30:00', 6, 4, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-23T18:30:00', 5, 1, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-23T18:30:00', 2, 8, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-23T18:30:00', 9, 10, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-23T18:30:00', 3, 7, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-24T18:30:00', 1, 6, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-24T18:30:00', 8, 9, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-24T18:30:00', 10, 5, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-24T18:30:00', 3, 2, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-24T18:30:00', 4, 7, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-25T17:00:00', 1, 6, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-25T17:00:00', 8, 9, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-25T17:00:00', 10, 5, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-25T17:00:00', 3, 2, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-25T17:00:00', 4, 7, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-26T14:00:00', 1, 6, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-26T14:00:00', 8, 9, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-26T14:00:00', 10, 5, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-26T14:00:00', 3, 2, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-26T14:00:00', 4, 7, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-28T18:30:00', 1, 2, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-28T18:30:00', 5, 3, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-28T18:30:00', 7, 10, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-28T18:30:00', 9, 6, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-28T18:30:00', 4, 8, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-29T18:30:00', 1, 2, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-29T18:30:00', 5, 3, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-29T18:30:00', 7, 10, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-29T18:30:00', 9, 6, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-29T18:30:00', 4, 8, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-30T18:30:00', 1, 2, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-30T18:30:00', 5, 3, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-30T18:30:00', 7, 10, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-30T18:30:00', 9, 6, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-04-30T18:30:00', 4, 8, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-01T18:30:00', 6, 7, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-01T18:30:00', 8, 5, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-01T18:30:00', 2, 4, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-01T18:30:00', 10, 9, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-01T18:30:00', 3, 1, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-02T17:00:00', 6, 7, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-02T17:00:00', 8, 5, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-02T17:00:00', 2, 4, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-02T17:00:00', 10, 9, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-02T17:00:00', 3, 1, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-03T14:00:00', 6, 7, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-03T14:00:00', 8, 5, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-03T14:00:00', 2, 4, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-03T14:00:00', 10, 9, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-03T14:00:00', 3, 1, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-05T14:00:00', 6, 1, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-05T14:00:00', 8, 7, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-05T14:00:00', 2, 3, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-05T14:00:00', 9, 5, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-05T14:00:00', 10, 4, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-06T18:30:00', 6, 1, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-06T18:30:00', 8, 7, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-06T18:30:00', 2, 3, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-06T18:30:00', 9, 5, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-06T18:30:00', 10, 4, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-07T18:30:00', 6, 1, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-07T18:30:00', 8, 7, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-07T18:30:00', 2, 3, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-07T18:30:00', 9, 5, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-07T18:30:00', 10, 4, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-08T18:30:00', 1, 8, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-08T18:30:00', 5, 10, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-08T18:30:00', 7, 2, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-08T18:30:00', 3, 9, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-08T18:30:00', 4, 6, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-09T17:00:00', 1, 8, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-09T17:00:00', 5, 10, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-09T17:00:00', 7, 2, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-09T17:00:00', 3, 9, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-09T17:00:00', 4, 6, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-10T14:00:00', 1, 8, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-10T14:00:00', 5, 10, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-10T14:00:00', 7, 2, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-10T14:00:00', 3, 9, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-10T14:00:00', 4, 6, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-12T18:30:00', 6, 2, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-12T18:30:00', 5, 7, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-12T18:30:00', 9, 8, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-12T18:30:00', 10, 1, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-12T18:30:00', 3, 4, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-13T18:30:00', 6, 2, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-13T18:30:00', 5, 7, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-13T18:30:00', 9, 8, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-13T18:30:00', 10, 1, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-13T18:30:00', 3, 4, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-14T18:30:00', 6, 2, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-14T18:30:00', 5, 7, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-14T18:30:00', 9, 8, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-14T18:30:00', 10, 1, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-14T18:30:00', 3, 4, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-15T18:30:00', 1, 5, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-15T18:30:00', 8, 6, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-15T18:30:00', 2, 10, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-15T18:30:00', 7, 3, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-15T18:30:00', 9, 4, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-16T17:00:00', 1, 5, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-16T17:00:00', 8, 6, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-16T17:00:00', 2, 10, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-16T17:00:00', 7, 3, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-16T17:00:00', 9, 4, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-17T14:00:00', 1, 5, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-17T14:00:00', 8, 6, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-17T14:00:00', 2, 10, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-17T14:00:00', 7, 3, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-17T14:00:00', 9, 4, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-19T18:30:00', 1, 7, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-19T18:30:00', 2, 9, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-19T18:30:00', 10, 6, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-19T18:30:00', 3, 8, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-19T18:30:00', 4, 5, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-20T18:30:00', 1, 7, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-20T18:30:00', 2, 9, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-20T18:30:00', 10, 6, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-20T18:30:00', 3, 8, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-20T18:30:00', 4, 5, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-21T18:30:00', 1, 7, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-21T18:30:00', 2, 9, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-21T18:30:00', 10, 6, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-21T18:30:00', 3, 8, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-21T18:30:00', 4, 5, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-22T18:30:00', 6, 3, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-22T18:30:00', 5, 2, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-22T18:30:00', 9, 7, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-22T18:30:00', 10, 8, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-22T18:30:00', 4, 1, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-23T17:00:00', 6, 3, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-23T17:00:00', 5, 2, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-23T17:00:00', 9, 7, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-23T17:00:00', 10, 8, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-23T17:00:00', 4, 1, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-24T14:00:00', 6, 3, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-24T14:00:00', 5, 2, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-24T14:00:00', 9, 7, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-24T14:00:00', 10, 8, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-24T14:00:00', 4, 1, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-26T18:30:00', 1, 9, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-26T18:30:00', 8, 2, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-26T18:30:00', 5, 6, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-26T18:30:00', 7, 4, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-26T18:30:00', 3, 10, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-27T18:30:00', 1, 9, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-27T18:30:00', 8, 2, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-27T18:30:00', 5, 6, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-27T18:30:00', 7, 4, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-27T18:30:00', 3, 10, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-28T18:30:00', 1, 9, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-28T18:30:00', 8, 2, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-28T18:30:00', 5, 6, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-28T18:30:00', 7, 4, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-28T18:30:00', 3, 10, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-29T18:30:00', 6, 10, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-29T18:30:00', 2, 1, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-29T18:30:00', 7, 5, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-29T18:30:00', 3, 9, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-29T18:30:00', 4, 8, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-30T17:00:00', 6, 10, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-30T17:00:00', 2, 1, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-30T17:00:00', 7, 5, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-30T17:00:00', 3, 9, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-30T17:00:00', 4, 8, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-31T14:00:00', 6, 10, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-31T14:00:00', 2, 1, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-31T14:00:00', 7, 5, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-31T14:00:00', 3, 9, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-05-31T14:00:00', 4, 8, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-02T18:30:00', 1, 4, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-02T18:30:00', 8, 3, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-02T18:30:00', 2, 7, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-02T18:30:00', 9, 6, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-02T18:30:00', 10, 5, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-03T17:00:00', 1, 4, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-03T17:00:00', 8, 3, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-03T17:00:00', 2, 7, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-03T17:00:00', 9, 6, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-03T17:00:00', 10, 5, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-04T18:30:00', 1, 4, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-04T18:30:00', 8, 3, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-04T18:30:00', 2, 7, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-04T18:30:00', 9, 6, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-04T18:30:00', 10, 5, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-05T18:30:00', 1, 3, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-05T18:30:00', 8, 9, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-05T18:30:00', 5, 4, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-05T18:30:00', 7, 6, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-05T18:30:00', 10, 2, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-06T17:00:00', 1, 3, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-06T17:00:00', 8, 9, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-06T17:00:00', 5, 4, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-06T17:00:00', 7, 6, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-06T17:00:00', 10, 2, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-07T17:00:00', 1, 3, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-07T17:00:00', 8, 9, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-07T17:00:00', 5, 4, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-07T17:00:00', 7, 6, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-07T17:00:00', 10, 2, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-09T18:30:00', 6, 8, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-09T18:30:00', 5, 1, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-09T18:30:00', 9, 2, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-09T18:30:00', 3, 7, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-09T18:30:00', 4, 10, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-10T18:30:00', 6, 8, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-10T18:30:00', 5, 1, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-10T18:30:00', 9, 2, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-10T18:30:00', 3, 7, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-10T18:30:00', 4, 10, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-11T18:30:00', 6, 8, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-11T18:30:00', 5, 1, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-11T18:30:00', 9, 2, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-11T18:30:00', 3, 7, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-11T18:30:00', 4, 10, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-12T18:30:00', 6, 5, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-12T18:30:00', 2, 8, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-12T18:30:00', 9, 7, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-12T18:30:00', 10, 1, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-12T18:30:00', 3, 4, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-13T17:00:00', 6, 5, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-13T17:00:00', 2, 8, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-13T17:00:00', 9, 7, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-13T17:00:00', 10, 1, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-13T17:00:00', 3, 4, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-14T14:00:00', 3, 4, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-14T17:00:00', 6, 5, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-14T17:00:00', 2, 8, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-14T17:00:00', 9, 7, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-14T17:00:00', 10, 1, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-16T18:30:00', 1, 9, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-16T18:30:00', 8, 5, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-16T18:30:00', 2, 3, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-16T18:30:00', 7, 4, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-16T18:30:00', 10, 6, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-17T18:30:00', 1, 9, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-17T18:30:00', 8, 5, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-17T18:30:00', 2, 3, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-17T18:30:00', 7, 4, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-17T18:30:00', 10, 6, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-18T18:30:00', 1, 9, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-18T18:30:00', 8, 5, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-18T18:30:00', 2, 3, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-18T18:30:00', 7, 4, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-18T18:30:00', 10, 6, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-19T18:30:00', 6, 1, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-19T18:30:00', 7, 8, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-19T18:30:00', 9, 10, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-19T18:30:00', 3, 5, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-19T18:30:00', 4, 2, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-20T17:00:00', 6, 1, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-20T17:00:00', 7, 8, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-20T17:00:00', 9, 10, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-20T17:00:00', 3, 5, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-20T17:00:00', 4, 2, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-21T14:00:00', 3, 5, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-21T17:00:00', 6, 1, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-21T17:00:00', 7, 8, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-21T17:00:00', 9, 10, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-21T17:00:00', 4, 2, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-23T18:30:00', 6, 2, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-23T18:30:00', 5, 7, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-23T18:30:00', 9, 8, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-23T18:30:00', 3, 10, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-23T18:30:00', 4, 1, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-24T18:30:00', 6, 2, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-24T18:30:00', 5, 7, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-24T18:30:00', 9, 8, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-24T18:30:00', 3, 10, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-24T18:30:00', 4, 1, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-25T18:30:00', 6, 2, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-25T18:30:00', 5, 7, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-25T18:30:00', 9, 8, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-25T18:30:00', 3, 10, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-25T18:30:00', 4, 1, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-26T18:30:00', 1, 10, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-26T18:30:00', 8, 4, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-26T18:30:00', 5, 6, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-26T18:30:00', 2, 9, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-26T18:30:00', 7, 3, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-27T17:00:00', 1, 10, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-27T17:00:00', 8, 4, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-27T17:00:00', 5, 6, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-27T17:00:00', 2, 9, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-27T17:00:00', 7, 3, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-28T17:00:00', 1, 10, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-28T17:00:00', 8, 4, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-28T17:00:00', 5, 6, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-28T17:00:00', 2, 9, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-28T17:00:00', 7, 3, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-30T18:30:00', 1, 5, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-30T18:30:00', 7, 2, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-30T18:30:00', 10, 8, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-30T18:30:00', 3, 6, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-06-30T18:30:00', 4, 9, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-01T18:30:00', 1, 5, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-01T18:30:00', 7, 2, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-01T18:30:00', 10, 8, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-01T18:30:00', 3, 6, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-01T18:30:00', 4, 9, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-02T18:30:00', 1, 5, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-02T18:30:00', 7, 2, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-02T18:30:00', 10, 8, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-02T18:30:00', 3, 6, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-02T18:30:00', 4, 9, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-03T18:30:00', 6, 4, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-03T18:30:00', 8, 2, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-03T18:30:00', 9, 5, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-03T18:30:00', 10, 7, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-03T18:30:00', 3, 1, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-04T18:00:00', 6, 4, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-04T18:00:00', 8, 2, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-04T18:00:00', 9, 5, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-04T18:00:00', 10, 7, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-04T18:00:00', 3, 1, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-05T14:00:00', 3, 1, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-05T18:00:00', 6, 4, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-05T18:00:00', 8, 2, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-05T18:00:00', 9, 5, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-05T18:00:00', 10, 7, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-07T18:30:00', 1, 8, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-07T18:30:00', 5, 10, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-07T18:30:00', 2, 6, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-07T18:30:00', 9, 3, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-07T18:30:00', 4, 7, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-08T18:30:00', 1, 8, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-08T18:30:00', 5, 10, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-08T18:30:00', 2, 6, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-08T18:30:00', 9, 3, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-08T18:30:00', 4, 7, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-09T18:30:00', 1, 8, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-09T18:30:00', 5, 10, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-09T18:30:00', 2, 6, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-09T18:30:00', 9, 3, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-09T18:30:00', 4, 7, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-16T18:30:00', 6, 9, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-16T18:30:00', 8, 10, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-16T18:30:00', 2, 5, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-16T18:30:00', 7, 1, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-16T18:30:00', 4, 3, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-17T18:30:00', 6, 9, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-17T18:30:00', 8, 10, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-17T18:30:00', 2, 5, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-17T18:30:00', 7, 1, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-17T18:30:00', 4, 3, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-18T18:00:00', 6, 9, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-18T18:00:00', 8, 10, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-18T18:00:00', 2, 5, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-18T18:00:00', 7, 1, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-18T18:00:00', 4, 3, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-19T18:00:00', 6, 9, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-19T18:00:00', 8, 10, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-19T18:00:00', 2, 5, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-19T18:00:00', 7, 1, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-19T18:00:00', 4, 3, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-21T18:30:00', 6, 7, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-21T18:30:00', 5, 8, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-21T18:30:00', 9, 1, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-21T18:30:00', 10, 4, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-21T18:30:00', 3, 2, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-22T18:30:00', 6, 7, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-22T18:30:00', 5, 8, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-22T18:30:00', 9, 1, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-22T18:30:00', 10, 4, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-22T18:30:00', 3, 2, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-23T18:30:00', 6, 7, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-23T18:30:00', 5, 8, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-23T18:30:00', 9, 1, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-23T18:30:00', 10, 4, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-23T18:30:00', 3, 2, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-24T18:30:00', 1, 2, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-24T18:30:00', 8, 7, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-24T18:30:00', 5, 9, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-24T18:30:00', 10, 3, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-24T18:30:00', 4, 6, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-25T18:00:00', 1, 2, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-25T18:00:00', 8, 7, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-25T18:00:00', 5, 9, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-25T18:00:00', 10, 3, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-25T18:00:00', 4, 6, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-26T18:00:00', 1, 2, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-26T18:00:00', 8, 7, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-26T18:00:00', 5, 9, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-26T18:00:00', 10, 3, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-26T18:00:00', 4, 6, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-28T18:30:00', 6, 3, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-28T18:30:00', 8, 1, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-28T18:30:00', 2, 10, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-28T18:30:00', 7, 9, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-28T18:30:00', 4, 5, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-29T18:30:00', 6, 3, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-29T18:30:00', 8, 1, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-29T18:30:00', 2, 10, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-29T18:30:00', 7, 9, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-29T18:30:00', 4, 5, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-30T18:30:00', 6, 3, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-30T18:30:00', 8, 1, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-30T18:30:00', 2, 10, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-30T18:30:00', 7, 9, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-30T18:30:00', 4, 5, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-31T18:30:00', 1, 6, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-31T18:30:00', 5, 2, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-31T18:30:00', 7, 10, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-31T18:30:00', 9, 4, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-07-31T18:30:00', 3, 8, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-01T18:00:00', 1, 6, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-01T18:00:00', 5, 2, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-01T18:00:00', 7, 10, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-01T18:00:00', 9, 4, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-01T18:00:00', 3, 8, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-02T14:00:00', 3, 8, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-02T18:00:00', 1, 6, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-02T18:00:00', 5, 2, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-02T18:00:00', 7, 10, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-02T18:00:00', 9, 4, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-04T18:30:00', 1, 7, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-04T18:30:00', 8, 6, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-04T18:30:00', 5, 3, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-04T18:30:00', 2, 4, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-04T18:30:00', 10, 9, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-05T18:30:00', 1, 7, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-05T18:30:00', 8, 6, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-05T18:30:00', 5, 3, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-05T18:30:00', 2, 4, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-05T18:30:00', 10, 9, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-06T18:30:00', 1, 7, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-06T18:30:00', 8, 6, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-06T18:30:00', 5, 3, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-06T18:30:00', 2, 4, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-06T18:30:00', 10, 9, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-07T18:30:00', 6, 10, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-07T18:30:00', 2, 1, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-07T18:30:00', 7, 8, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-07T18:30:00', 9, 5, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-07T18:30:00', 4, 3, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-08T18:00:00', 6, 10, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-08T18:00:00', 2, 1, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-08T18:00:00', 7, 8, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-08T18:00:00', 9, 5, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-08T18:00:00', 4, 3, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-09T18:00:00', 6, 10, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-09T18:00:00', 2, 1, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-09T18:00:00', 7, 8, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-09T18:00:00', 9, 5, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-09T18:00:00', 4, 3, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-11T18:30:00', 1, 4, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-11T18:30:00', 8, 5, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-11T18:30:00', 7, 9, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-11T18:30:00', 10, 2, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-11T18:30:00', 3, 6, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-12T18:30:00', 1, 4, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-12T18:30:00', 8, 5, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-12T18:30:00', 7, 9, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-12T18:30:00', 10, 2, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-12T18:30:00', 3, 6, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-13T18:30:00', 1, 4, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-13T18:30:00', 8, 5, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-13T18:30:00', 7, 9, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-13T18:30:00', 10, 2, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-13T18:30:00', 3, 6, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-14T18:30:00', 6, 8, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-14T18:30:00', 5, 7, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-14T18:30:00', 2, 4, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-14T18:30:00', 9, 3, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-14T18:30:00', 10, 1, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-15T18:00:00', 6, 8, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-15T18:00:00', 5, 7, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-15T18:00:00', 2, 4, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-15T18:00:00', 9, 3, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-15T18:00:00', 10, 1, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-16T18:00:00', 6, 8, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-16T18:00:00', 5, 7, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-16T18:00:00', 2, 4, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-16T18:00:00', 9, 3, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-16T18:00:00', 10, 1, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-18T18:30:00', 6, 9, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-18T18:30:00', 5, 3, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-18T18:30:00', 2, 8, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-18T18:30:00', 7, 1, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-18T18:30:00', 4, 10, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-19T18:30:00', 6, 9, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-19T18:30:00', 5, 3, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-19T18:30:00', 2, 8, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-19T18:30:00', 7, 1, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-19T18:30:00', 4, 10, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-20T18:30:00', 6, 9, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-20T18:30:00', 5, 3, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-20T18:30:00', 2, 8, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-20T18:30:00', 7, 1, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-20T18:30:00', 4, 10, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-21T18:30:00', 1, 5, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-21T18:30:00', 8, 9, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-21T18:30:00', 7, 2, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-21T18:30:00', 3, 10, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-21T18:30:00', 4, 6, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-22T18:00:00', 1, 5, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-22T18:00:00', 8, 9, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-22T18:00:00', 7, 2, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-22T18:00:00', 3, 10, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-22T18:00:00', 4, 6, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-23T14:00:00', 3, 10, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-23T18:00:00', 1, 5, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-23T18:00:00', 8, 9, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-23T18:00:00', 7, 2, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-23T18:00:00', 4, 6, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-25T18:30:00', 6, 7, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-25T18:30:00', 8, 4, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-25T18:30:00', 9, 1, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-25T18:30:00', 10, 5, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-25T18:30:00', 3, 2, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-26T18:30:00', 6, 7, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-26T18:30:00', 8, 4, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-26T18:30:00', 9, 1, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-26T18:30:00', 10, 5, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-26T18:30:00', 3, 2, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-27T18:30:00', 6, 7, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-27T18:30:00', 8, 4, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-27T18:30:00', 9, 1, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-27T18:30:00', 10, 5, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-27T18:30:00', 3, 2, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-28T18:30:00', 1, 3, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-28T18:30:00', 5, 6, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-28T18:30:00', 2, 9, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-28T18:30:00', 10, 8, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-28T18:30:00', 4, 7, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-29T18:00:00', 1, 3, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-29T18:00:00', 5, 6, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-29T18:00:00', 2, 9, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-29T18:00:00', 10, 8, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-29T18:00:00', 4, 7, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-30T18:00:00', 1, 3, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-30T18:00:00', 5, 6, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-30T18:00:00', 2, 9, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-30T18:00:00', 10, 8, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-08-30T18:00:00', 4, 7, 5, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-01T18:30:00', 1, 6, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-01T18:30:00', 2, 5, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-01T18:30:00', 10, 7, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-01T18:30:00', 4, 9, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-01T18:30:00', 3, 8, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-02T18:30:00', 1, 6, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-02T18:30:00', 2, 5, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-02T18:30:00', 10, 7, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-02T18:30:00', 4, 9, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-02T18:30:00', 3, 8, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-03T18:30:00', 1, 6, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-03T18:30:00', 2, 5, 3, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-03T18:30:00', 10, 7, 4, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-03T18:30:00', 4, 9, 7, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-03T18:30:00', 3, 8, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-04T18:30:00', 6, 2, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-04T18:30:00', 8, 1, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-04T18:30:00', 5, 4, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-04T18:30:00', 10, 9, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-04T18:30:00', 3, 7, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-05T17:00:00', 6, 2, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-05T17:00:00', 8, 1, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-05T17:00:00', 5, 4, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-05T17:00:00', 10, 9, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-05T17:00:00', 3, 7, 9, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-06T14:00:00', 6, 2, 1, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-06T14:00:00', 8, 1, 2, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-06T14:00:00', 5, 4, 6, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-06T14:00:00', 10, 9, 8, 'UPCOMING', NOW(), NOW());
INSERT INTO matches (match_at, home_club_id, away_club_id, stadium_id, sale_status, created_at, updated_at) VALUES ('2026-09-06T14:00:00', 3, 7, 9, 'UPCOMING', NOW(), NOW());