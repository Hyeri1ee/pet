# 2. questions — 질문 목록

> 기획 근거: [기획정리.md](../기획정리.md) 3. 오늘의 질문(단기 5개) · 4. 이달의 질문(장기 3개) — 둘 다 **확정**
> 장기 질문 주기: **한 달에 한 번** (2026-11-21 결정, [A-6](../기획정리_추가정리필요요소.md) 해결. 기획정리.md 표의 "분기별" 은 이 결정으로 대체)
> 미정 사항: [A-9 답변 → 점수 변환](../기획정리_추가정리필요요소.md)
> 배경: [Supabase 구조](00-supabase-구조.md) · 앞 단계: [users](01-users.md)

## 왜 필요한가
- 앱이 사용자에게 보여줄 **질문의 원본 목록** (모두 8개)
- 누구에게 언제 어떤 질문이 나왔는지는 `question_deliveries`(3번), 사용자의 답은 `answers`(4번)에 따로 저장함 → 여기에는 **질문 자체**만 둠
- 질문은 앱 코드가 아니라 **DB 테이블에 seed 로 넣음** → 나중에 관리자 웹에서 바로 수정 가능 ([A-7](../기획정리_추가정리필요요소.md) 결정)

## 다른 테이블과 다른 점: `user_id` 가 없음
- 질문은 **모든 사용자가 같이 보는 공용 데이터**라 "누구 것" 칸이 필요 없음 → 공통 규칙의 `user_id` 예외
- RLS: **로그인한 사람은 읽기만 가능**, 쓰기 · 수정 · 삭제 정책은 만들지 않음 (질문은 대시보드나 나중에 관리자 웹에서만 바꿈)

## 예시 데이터 (기획 확정 8개)

| kind | code | 평가 항목 | 질문 | 주기 | 연출 (`interaction_key`) |
| --- | --- | --- | --- | --- | --- |
| short | RESIGN_URGE | 퇴사 충동 | 오늘 회사를 그만두고 싶다는 생각이 얼마나 들었나요? | 매일 | 사직서 도장 찍기 `STAMP` |
| short | WORK_STRESS | 업무 스트레스 | 오늘 업무로 인해 얼마나 스트레스를 받았나요? | 매일 | 풍선 불기 → 터뜨리기 `BALLOON` |
| short | WORKLOAD | 업무량 | 오늘 업무량은 감당할 수 있는 수준이었나요? | 매일 | 서류 쌓기 `DOC_STACK` |
| short | EMOTION_DRAIN | 감정 소모 | 오늘 직장에서 감정적으로 얼마나 지쳤나요? | 매일 | HP바 슬라이더 `HP_BAR` |
| short | ACHIEVEMENT | 성취감 | 오늘 업무를 마치고 얼마나 뿌듯함을 느꼈나요? | 매일 | 도장 3개 중 1개 `STAMP_CHOICE` |
| long | WELFARE | 복지 | 현재 회사의 복지 제도가 내 생활에 실질적으로 도움이 되나요? | 월 1회 | 선물 상자 열기 `GIFT_BOX` |
| long | CULTURE | 조직문화 | 회사의 업무 방식과 의사결정 과정에 만족하나요? | 월 1회 | 회의할 때 내 모습 `POSTURE` |
| long | STABILITY | 고용 · 사업 안정성 | 회사의 미래와 나의 고용 안정성에 대해 얼마나 긍정적으로 생각하나요? | 월 1회 | 우리 회사의 날씨 `WEATHER` |

- `short` = 오늘의 질문 (5개 중 매일 3개 랜덤), `long` = 이달의 질문 (3개 중 1개 선택)
- 3개 중 1개를 고르는 질문(성취감, 장기 3개)은 **선택지**가 필요함 → `config` 칸에 넣음

## 칸(컬럼) 설명

| 칸 | 뜻 | 예시 | 비고 |
| --- | --- | --- | --- |
| `id` | 질문 고유 번호 | `q1a2c3d4-…` | uuid |
| `code` | 질문을 가리키는 짧은 이름 | `RESIGN_URGE` | 겹치지 않음(unique). seed 를 다시 넣어도 중복 안 되게 하고, 앱 · 함수가 사람이 읽을 수 있는 이름으로 부르게 함 |
| `kind` | 단기 / 장기 | `short` / `long` | 허용값 두 개만 |
| `indicator` | 평가 항목 이름 | 퇴사 충동 | 화면에 보여줄 항목명 |
| `body` | 질문 문구 | 오늘 회사를 그만두고 싶다는 … | 비어 있으면 안 됨 |
| `cycle` | 나오는 주기 | 단기 `daily`, 장기 `monthly` | 허용값 두 개만. 장기는 한 달에 한 번 정해진 날 ([기획정리.md](../기획정리.md) 4) |
| `interaction_key` | 답변 연출 종류 | `STAMP` | 앱에 이미 만들어진 연출 중에서 고름. 관리자 웹에서 바꿀 수 있음 |
| `direction` | 점수 방향 | `negative` / `positive` | positive(성취감 등)는 점수를 뒤집어 저장 → 전부 "높을수록 퇴사각↑" |
| `config` | 연출별 세부값 (jsonb) | `{"choices":["때려치워","이걸해냄","내가짱이야"]}` | 선택지, 최대값 등. **점수 변환 규칙이 정해지면 채움** ([A-9](../기획정리_추가정리필요요소.md)) |
| `sort_order` | 표시 순서 | 1~5 / 1~3 | |
| `is_active` | 지금 쓰는 질문인지 | true / false | 질문을 지우지 않고 빼기 위해 |
| `created_at` | 만든 시각 | 2026-11-21 10:00 | |

## 다른 테이블과 연결
> **질문 하나는 여러 번 나올 수 있고, 여러 사람이 답할 수 있다**

```
questions (8개)
  ├── question_deliveries.question_id   ← 누구에게 언제 나왔나 (3번)
  └── answers.question_id               ← 누가 어떻게 답했나 (4번)
```

- "5개 중 매일 3개 랜덤"은 questions 가 아니라 **DB 함수**(`draw_daily_questions`)가 뽑고, 결과가 `question_deliveries` 에 쌓임

## SQL 초안

```sql
create table questions (
  id              uuid primary key default gen_random_uuid(),
  code            text not null unique,
  kind            text not null check (kind in ('short', 'long')),
  indicator       text not null,
  body            text not null,
  cycle           text not null check (cycle in ('daily', 'monthly')),
  interaction_key text not null,
  direction       text not null check (direction in ('negative', 'positive')),
  config          jsonb not null default '{}',
  sort_order      int  not null default 0,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now()
);

alter table questions enable row level security;

-- 로그인한 사람(익명 로그인 포함)은 읽기만. insert/update/delete 정책은 만들지 않음
create policy "질문 읽기" on questions
  for select to authenticated using (true);
```

- 읽기 정책을 `using (is_active)` 가 아니라 `using (true)` 로 둔 이유: **과거 답변 화면에서 지금은 안 쓰는 질문의 문구도 보여줘야 함.** 쓰는 질문만 뽑는 건 DB 함수가 `is_active` 로 걸러서 함
- 인덱스: 8개 안팎이라 **기본키 + `code` unique 만으로 충분**

## 결정 · 메모
- **지표 테이블(`indicators`)을 따로 만들지 않음**: 지표가 질문과 1:1 (단기 5 · 장기 3 = 질문 8개)이라 `indicator` · `direction` 을 questions 에 같이 둠. 기존 legacy ERD 의 `indicators` · `question_options` 는 합침
- **선택지 테이블(`question_options`)도 따로 만들지 않음**: 선택지가 있는 질문이 4개뿐이고 항상 3개라 `config` 에 넣음. 선택지마다 점수를 따로 관리해야 하면 그때 분리
- **문구가 바뀌는 경우**: 질문 문구를 고치면 과거 답변과 어긋날 수 있음 → 문구 수정 대신 새 질문을 추가하고 이전 질문은 `is_active = false`. 답변에 질문 문구를 같이 남길지는 `answers` 단계에서 결정
- **장기 질문 주기 = 한 달에 한 번 (2026-11-21)**: 3주 안도 검토했으나 **월 1회로 확정**. "이달의 질문" 이름 · "이번 달 유리병"과도 그대로 맞음
- 월 1회라 `question_deliveries` 의 `period_key` 를 기획 문서대로 `M:2026-11` 형태로 쓸 수 있음 (한 달에 한 번만 나오게 막기 쉬움)
- **미정**: 답변 → 점수 변환(A-9). 정해지면 `config` 값만 채우면 되고 **칸 구조는 안 바뀜**
- **다음 단계에서 정할 것**: 매달 **며칠에** 나오는지("정해진 날"), 그날 답하지 않으면 그 달은 없는지

## 이해 확인

<details>
<summary>질문 3개 (펼치기)</summary>

1. questions 에는 왜 `user_id` 칸이 없을까?
2. 질문을 지우지 않고 `is_active` 로 빼는 이유는?
3. 앱이 questions 에 새 질문을 `insert` 하려고 하면 어떻게 될까?

| # | 혜리 님 답 | 확인 |
| --- | --- | --- |
| 1 | | |
| 2 | | |
| 3 | | |

> ✅ questions 이해 완료 (2026-11-21)

</details>
