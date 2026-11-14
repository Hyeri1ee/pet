-- =====================================================================
-- 퇴사각 펫 — 개발 DB 스키마 (SQLite, 로컬 우선)
-- 서버(PostgreSQL)로 옮길 때도 테이블 구조는 그대로 쓰도록 user_id를 모든 기록에 둠
-- 점수 규칙: normalized_score 는 0~100, 100에 가까울수록 "퇴사각 높음(나쁨)"
-- =====================================================================
PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------
-- 1. 사용자
-- ---------------------------------------------------------------------
CREATE TABLE users (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    nickname             TEXT    NOT NULL,
    work_start_time      TEXT    NOT NULL DEFAULT '09:00',   -- 출근 인사 / 시간대 행동 기준
    work_end_time        TEXT    NOT NULL DEFAULT '18:00',   -- 퇴근 독촉 / 야근 판정 기준
    lunch_time           TEXT    NOT NULL DEFAULT '12:00',
    daily_question_time  TEXT    NOT NULL DEFAULT '16:00',   -- 단기 질문 노출 시각
    daily_question_count INTEGER NOT NULL DEFAULT 2,          -- 하루 랜덤 질문 수
    timezone             TEXT    NOT NULL DEFAULT 'Asia/Seoul',
    tutorial_done        INTEGER NOT NULL DEFAULT 0,          -- 답변 가이드(최소~최대값 설명) 완료 여부
    created_at           TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at           TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- [후순위] 사용자 목표 → 목표별 질문/알림 분기
CREATE TABLE user_goals (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    goal_code   TEXT    NOT NULL,          -- 'PERSONAL_TIME' | 'CAREER_GROWTH' ...
    is_active   INTEGER NOT NULL DEFAULT 1,
    created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------
-- 2. 지표 · 질문 (마스터 데이터, 앱 배포 시 seed)
-- ---------------------------------------------------------------------
CREATE TABLE indicators (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    code        TEXT    NOT NULL UNIQUE,   -- 'RESIGN_URGE', 'SALARY' ...
    name        TEXT    NOT NULL,          -- '퇴사 충동', '연봉·보상'
    category    TEXT    NOT NULL CHECK (category IN ('LONG','SHORT','WORK_LOG')),
    cycle       TEXT    NOT NULL CHECK (cycle IN ('DAILY','WEEKLY','MONTHLY','QUARTERLY')),
    direction   TEXT    NOT NULL CHECK (direction IN ('NEGATIVE','POSITIVE')),
                -- NEGATIVE: 원점수 높을수록 퇴사각↑ (퇴사충동, 스트레스)
                -- POSITIVE: 원점수 높을수록 퇴사각↓ (성취감, 만족도) → 역산
    weight      REAL    NOT NULL DEFAULT 1.0,  -- 종합 점수 가중치
    is_active   INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE questions (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    indicator_id INTEGER NOT NULL REFERENCES indicators(id),
    text         TEXT    NOT NULL,
    answer_type  TEXT    NOT NULL CHECK (answer_type IN ('CHOICE','EMOJI','SLIDER','TEXT','YES_NO')),
    min_value    REAL,                      -- SLIDER/CHOICE 의 원점수 범위
    max_value    REAL,
    min_label    TEXT,                      -- '전혀 아니다'
    max_label    TEXT,                      -- '매우 그렇다'
    version      INTEGER NOT NULL DEFAULT 1,  -- 문구 바뀌어도 과거 답변 해석 유지
    is_active    INTEGER NOT NULL DEFAULT 1,
    created_at   TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- 객관식(5지선다)·이모지 선택지. 각 선택지가 원점수를 가짐
CREATE TABLE question_options (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    sort_order  INTEGER NOT NULL,
    label       TEXT    NOT NULL,
    emoji       TEXT,
    raw_score   REAL    NOT NULL,
    UNIQUE (question_id, sort_order)
);

-- ---------------------------------------------------------------------
-- 3. 질문 노출 · 답변
-- ---------------------------------------------------------------------
-- 질문을 "언제 누구에게 냈는지" 기록. period_key + UNIQUE 로 중복 노출/응답 방지
CREATE TABLE question_deliveries (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question_id   INTEGER NOT NULL REFERENCES questions(id),
    period_key    TEXT    NOT NULL,   -- 'D:2026-11-14' | 'W:2026-W46' | 'M:2026-11' | 'Q:2026-Q4'
    draw_group    TEXT,               -- 장기지표 '3장 중 1장 고르기' 묶음 ID (선택 안 된 카드는 SKIPPED)
    channel       TEXT    NOT NULL DEFAULT 'NOTE' CHECK (channel IN ('BUBBLE','NOTE','CARD')),
    status        TEXT    NOT NULL DEFAULT 'PENDING'
                  CHECK (status IN ('PENDING','ANSWERED','SKIPPED','EXPIRED')),
    delivered_at  TEXT    NOT NULL DEFAULT (datetime('now')),
    expires_at    TEXT,
    UNIQUE (user_id, question_id, period_key)
);

-- 답변: 형식이 달라도 normalized_score(0~100) 하나로 표준화해서 분석
CREATE TABLE answers (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    delivery_id      INTEGER NOT NULL UNIQUE REFERENCES question_deliveries(id) ON DELETE CASCADE,
    user_id          INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question_id      INTEGER NOT NULL REFERENCES questions(id),
    answer_date      TEXT    NOT NULL,          -- 'YYYY-MM-DD' (캘린더 조회 키)
    option_id        INTEGER REFERENCES question_options(id),  -- CHOICE / EMOJI
    raw_value        REAL,                      -- SLIDER 값 or 선택지 raw_score or YES_NO(0/1)
    text_value       TEXT,                      -- TEXT 자유 입력
    normalized_score REAL CHECK (normalized_score BETWEEN 0 AND 100),  -- TEXT 는 NULL(점수 제외)
    answered_at      TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at       TEXT    NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX idx_answers_user_date ON answers(user_id, answer_date);

-- ---------------------------------------------------------------------
-- 4. 감정 · 업무 기록
-- ---------------------------------------------------------------------
CREATE TABLE daily_records (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id           INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    record_date       TEXT    NOT NULL,
    mood_morning      INTEGER CHECK (mood_morning   BETWEEN 1 AND 5),  -- 이모지 5단계
    mood_afternoon    INTEGER CHECK (mood_afternoon BETWEEN 1 AND 5),
    mood_evening      INTEGER CHECK (mood_evening   BETWEEN 1 AND 5),
    is_overtime       INTEGER,                  -- 야근 여부 (단기 질문 답과 동기화)
    overtime_minutes  INTEGER,
    memo_today        TEXT,                     -- 오늘 있었던 일
    memo_stress_cause TEXT,                     -- 스트레스 원인
    memo_moment       TEXT,                     -- 기억하고 싶은 순간
    created_at        TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at        TEXT    NOT NULL DEFAULT (datetime('now')),
    UNIQUE (user_id, record_date)
);

-- 업무 기록(회의 건수, 업무 완료, 신규 업무) → 경험치 원천
CREATE TABLE work_logs (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    log_date    TEXT    NOT NULL,
    log_type    TEXT    NOT NULL CHECK (log_type IN ('MEETING','TASK_DONE','TASK_NEW')),
    title       TEXT,
    quantity    INTEGER NOT NULL DEFAULT 1,
    created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX idx_work_logs_user_date ON work_logs(user_id, log_date);

-- ---------------------------------------------------------------------
-- 5. 퇴사각 지수 (집계 캐시)
-- ---------------------------------------------------------------------
-- 지표별·기간별 점수 캐시. 과거 답변 수정 시 is_dirty=1 → 재계산
CREATE TABLE score_snapshots (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    period_type   TEXT    NOT NULL CHECK (period_type IN ('DAY','WEEK','MONTH','QUARTER')),
    period_key    TEXT    NOT NULL,          -- '2026-11-14' | '2026-W46' | '2026-11' | '2026-Q4'
    indicator_id  INTEGER REFERENCES indicators(id),  -- NULL 이면 해당 기간 "전체 퇴사각 지수"
    short_score   REAL,                      -- 전체 행에서만 사용
    long_score    REAL,                      -- 전체 행에서만 사용 (최근 장기 답변 이월)
    score         REAL,                      -- 지표 점수 or 종합 점수 (0~100)
    answer_count  INTEGER NOT NULL DEFAULT 0,
    worker_type_id INTEGER REFERENCES worker_types(id),  -- 직장인 유형 (전체 행)
    is_dirty      INTEGER NOT NULL DEFAULT 0,
    computed_at   TEXT    NOT NULL DEFAULT (datetime('now'))
);
-- indicator_id 가 NULL 인 행도 유일하게 하려고 COALESCE 사용
CREATE UNIQUE INDEX ux_score_snapshots
    ON score_snapshots(user_id, period_type, period_key, COALESCE(indicator_id, 0));

-- 직장인 유형 (점수 구간 → 유형 & 설명)
CREATE TABLE worker_types (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    code        TEXT    NOT NULL UNIQUE,
    name        TEXT    NOT NULL,           -- '번아웃 직전형' ...
    description TEXT    NOT NULL,
    rule_json   TEXT    NOT NULL            -- {"RESIGN_URGE":[70,100],"STRESS":[60,100]}
);

-- ---------------------------------------------------------------------
-- 6. 펫
-- ---------------------------------------------------------------------
CREATE TABLE pet_species (                  -- 뽑기 대상 캐릭터 목록
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    code        TEXT    NOT NULL UNIQUE,
    name        TEXT    NOT NULL,
    rarity      TEXT    NOT NULL DEFAULT 'COMMON',
    asset_key   TEXT    NOT NULL,           -- 스프라이트 시트 폴더명
    is_active   INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE user_pets (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    species_id  INTEGER NOT NULL REFERENCES pet_species(id),
    name        TEXT    NOT NULL,
    level       INTEGER NOT NULL DEFAULT 1,  -- exp_events 합계로 재계산 가능한 캐시
    total_exp   INTEGER NOT NULL DEFAULT 0,
    affection   INTEGER NOT NULL DEFAULT 0,  -- 쓰다듬기·클릭 등으로 증가
    is_active   INTEGER NOT NULL DEFAULT 1,  -- 현재 화면에 나와 있는 펫
    obtained_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- 경험치 원장: 어디서 얼마 받았는지 전부 남김 (수정/삭제 시 역분개 가능)
CREATE TABLE exp_events (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_pet_id INTEGER NOT NULL REFERENCES user_pets(id) ON DELETE CASCADE,
    source_type TEXT    NOT NULL CHECK (source_type IN ('ANSWER','DAILY_RECORD','WORK_LOG','STREAK','INTERACTION')),
    source_id   INTEGER,                    -- answers.id / daily_records.id / work_logs.id ...
    exp_delta   INTEGER NOT NULL,
    created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
    UNIQUE (source_type, source_id, user_pet_id)  -- 같은 기록으로 두 번 경험치 받기 방지
);

-- [후순위] 장신구
CREATE TABLE pet_items (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    code        TEXT    NOT NULL UNIQUE,
    name        TEXT    NOT NULL,
    slot        TEXT    NOT NULL,           -- 'HEAD' | 'BODY' ...
    asset_key   TEXT    NOT NULL
);
CREATE TABLE user_pet_items (
    user_pet_id INTEGER NOT NULL REFERENCES user_pets(id) ON DELETE CASCADE,
    item_id     INTEGER NOT NULL REFERENCES pet_items(id),
    is_equipped INTEGER NOT NULL DEFAULT 0,
    obtained_at TEXT    NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (user_pet_id, item_id)
);

-- 펫 상태 규칙: 여러 조건이 동시에 맞으면 priority 높은 것 하나만 적용
CREATE TABLE pet_state_rules (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    state_code     TEXT    NOT NULL,        -- 'SLEEP','URGE_LEAVE','COMFORT','WORK_TOGETHER','DANCE' ...
    priority       INTEGER NOT NULL,        -- 클수록 우선
    condition_type TEXT    NOT NULL CHECK (condition_type IN ('TIME','EMOTION','BUSY','INTERACTION','EVENT')),
    condition_json TEXT    NOT NULL,        -- {"after":"work_end"} / {"stress_gte":70} / {"idle_min_lt":1,"active_min_gte":60}
    animation_key  TEXT    NOT NULL,        -- 스프라이트 애니메이션 이름
    is_active      INTEGER NOT NULL DEFAULT 1
);

-- 대사: 시간대 고정 / 랜덤 / 기록 기반 맞춤
CREATE TABLE pet_dialogues (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    state_code     TEXT,                    -- NULL 이면 상태 무관
    dialogue_type  TEXT    NOT NULL CHECK (dialogue_type IN ('FIXED_TIME','RANDOM','PERSONAL')),
    time_slot      TEXT CHECK (time_slot IN ('MORNING','LUNCH','AFTERNOON','LEAVE','NIGHT')),
    condition_json TEXT,                    -- PERSONAL: {"indicator":"STRESS","gte":70,"streak_days":3}
    text           TEXT    NOT NULL,        -- '{nickname}, 일이 많구나. 내가 도와줄 수 있는 게 있을까?'
    weight         INTEGER NOT NULL DEFAULT 1,
    is_active      INTEGER NOT NULL DEFAULT 1
);

-- 인터랙션 로그 (애정도 산정 / 반응 다양화 분석용, 오래된 건 주기적으로 정리)
CREATE TABLE pet_interactions (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    user_pet_id      INTEGER NOT NULL REFERENCES user_pets(id) ON DELETE CASCADE,
    interaction_type TEXT    NOT NULL CHECK (interaction_type IN ('CLICK','DRAG','PET','TALK')),
    occurred_at      TEXT    NOT NULL DEFAULT (datetime('now'))
);
