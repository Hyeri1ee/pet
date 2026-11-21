# 4. answers — 내가 한 답변

> 기획 근거: [기획정리.md](../기획정리.md) 3 · 4 (질문 · 답변 연출), 11. 저장되는 정보 ("답변 기록: 날짜, 질문 종류, 질문, 고른 답, 점수 0~100")
> 앞 단계: [question_deliveries](03-question-deliveries.md) / 다음 단계: [balls](05-balls.md)
> 미정 사항: [A-9 답변 → 점수 변환](../기획정리_추가정리필요요소.md) · [B-4 답변 수정](../기획정리_추가정리필요요소.md)

## 왜 필요한가
- 사용자가 질문에 **실제로 한 답**을 저장하는 곳 (앱의 핵심 기록)
- 구슬을 눌렀을 때 보이는 "하루 기록"(그날 답한 질문과 고른 답), 퇴사각 지수, 친밀도(답변할 때마다 오름)가 전부 여기서 나옴
- question_deliveries 는 "나온 질문", answers 는 "그 질문에 한 답" → **나오지 않은 질문에는 답이 있을 수 없음**

## 예시 데이터

사용자 `a1b2…` 가 2026-11-21 에 단기 2개, 11-05 에 장기 1개에 답함 (점수는 **임시 값**, A-9 에서 정해짐)

| delivery (질문) | 답한 내용 | raw_value | score | answer_date |
| --- | --- | --- | --- | --- |
| RESIGN_URGE (사직서 도장) | 도장 7번 | `7` | 70 | 2026-11-21 |
| WORK_STRESS (풍선 불기) | 풍선 4단계 | `4` | 40 | 2026-11-21 |
| WELFARE (선물 상자) | "쓸모 있음" 선택 | `쓸모 있음` | 25 | 2026-11-05 |

- 연출마다 답의 모양이 다름: **숫자**(도장 횟수, 풍선 크기, 서류 높이, HP) vs **3개 중 1개 선택**(성취감, 장기 3개)
- 둘 다 **`raw_value` 한 칸에 문자열로 저장**함 (`7`, `쓸모 있음`). 어떤 모양인지는 질문의 `interaction_key` 로 알 수 있음
- 모두 마지막에는 **0~100점 하나**로 바꿔서 저장 → 서로 다른 질문끼리 평균을 낼 수 있음 (높을수록 퇴사각↑)
- 아직 답하지 않았거나 만료된 질문은 **answers 에 줄이 없음** (deliveries 에만 있음)

## 칸(컬럼) 설명

| 칸 | 뜻 | 예시 | 비고 |
| --- | --- | --- | --- |
| `id` | 답변 고유 번호 | `a9b8c7d6-…` | uuid |
| `delivery_id` | 어떤 "나온 질문"에 한 답인가 | `d1e2f3a4-…` | question_deliveries 의 id. **unique** → 한 번 나온 질문엔 답 하나 |
| `ball_id` | 어떤 구슬에 담기나 | `b5c6…` | balls 의 id. 단기 답 1~3개는 **오늘의 구슬 하나**에, 장기 답은 **특별한 구슬**에 담김. balls 가 먼저 만들어져야 함 |
| `user_id` | 누가 답했나 | `a1b2…` | `auth.users` 의 id. 기본값 `auth.uid()`. RLS 용 |
| `raw_value` | 사용자가 한 답 (원본, 문자열) | `7` / `쓸모 있음` | 숫자형은 도장 횟수 · 풍선 · 서류 높이 · HP 를 글자로, 선택형은 [questions](02-questions.md) `config.choices` 의 값 그대로. **분석에는 안 쓰고** 화면 표시 · 점수 재계산용 |
| `score` | 0~100 점수 | 70 | 높을수록 퇴사각↑. 성취감 · 복지처럼 `direction = positive` 는 뒤집어서 저장 |
| `answer_date` | 답한 날 (사용자 현지 날짜) | 2026-11-21 | 하루 구슬 · 유리병 선반이 날짜로 모으는 기준 |
| `created_at` | 답한 시각 | 2026-11-21 16:10 | |

### 원본값(raw_value)과 점수(score)를 둘 다 저장하는 이유
- **원본**: 사용자가 실제로 한 것 ("도장 7번"). 화면에 "사직서 도장 7번" 을 다시 보여줄 때 필요
- **점수**: 분석 · 평균용 (**숫자 칸**). 점수 규칙([A-9](../기획정리_추가정리필요요소.md))을 나중에 바꿔도 **원본이 있어서 다시 계산**할 수 있음
- 점수를 저장해 두므로 나중에 구슬을 점수별 색으로 나눌 수 있음 (A-3)

## 다른 테이블과 연결

```
auth.users ──< answers >── question_deliveries ── questions
 (누가)        (답 한 줄)      (나온 질문 한 줄)       (어떤 질문)
                  │
                  └── answers.ball_id → balls  ← 답이 담기는 구슬 ([balls](05-balls.md))
```

- 나온 질문 1줄 → 답변 **0개 또는 1개**
- 질문이 무엇인지는 `delivery_id` → `question_deliveries` → `questions` 로 알 수 있어서 **answers 에 `question_id` 를 따로 두지 않음** (두면 둘이 어긋날 수 있음)
- 단기 / 장기 구분도 같은 길로 알 수 있음 → 특별한 구슬(장기)과 오늘의 구슬(단기)을 나누는 데 씀

## 어떻게 저장되나 (DB 함수)

앱이 `answers` 에 직접 `insert` 하지 않고 **답변 함수**를 부름 (점수 조작 · 아무 질문에나 답하기 방지)

```js
await supabase.rpc('submit_answer', { delivery_id: '…', raw_value: '7' })        // 숫자형
await supabase.rpc('submit_answer', { delivery_id: '…', raw_value: '쓸모 있음' })  // 선택형
```

함수가 하는 일:

1. 내 질문인가? `pending` 인가? 만료(`expires_at`) 안 됐는가? 확인
2. 값이 맞는 형태인가? (**DB 가 아니라 함수가 검사**: 숫자형 질문인데 숫자가 아니거나 범위를 넘으면 거부, 선택형인데 선택지에 없는 값이면 거부)
3. **함수 안에서 점수 계산**
4. **구슬 찾기 · 만들기** ([balls](05-balls.md)): 단기는 오늘의 구슬(오늘 첫 답이면 새로 생성), 장기는 특별한 구슬 생성
5. `answers` 에 한 줄 저장 (`ball_id` 포함)
6. `question_deliveries.status` 를 `answered` 로. 장기면 같은 `draw_group` 의 나머지를 `skipped` 로
7. 구슬의 퇴사각 지수(`score`) 갱신

## SQL 초안

```sql
create table answers (
  id          uuid primary key default gen_random_uuid(),
  delivery_id uuid not null unique references question_deliveries(id) on delete cascade,
  ball_id     uuid not null references balls(id) on delete cascade,   -- balls 를 먼저 만들 것
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  raw_value   text not null,                 -- 사용자가 한 답 원본: '7' | '쓸모 있음'
  score       numeric not null check (score between 0 and 100),
  answer_date date not null,                 -- 사용자 현지 날짜
  created_at  timestamptz not null default now()
);

-- 날짜로 조회 (구슬병 · 하루 기록)
create index on answers (user_id, answer_date);

alter table answers enable row level security;

-- 내 것만 읽기. insert / update / delete 정책은 만들지 않음 → 변경은 DB 함수만
create policy "내 답변만 읽기" on answers
  for select to authenticated using (user_id = (select auth.uid()));
```

- `delivery_id` 의 unique 가 "한 번 나온 질문엔 답 하나" 를 DB 가 보장
- 인덱스는 공통 규칙의 `(user_id, created_at)` 대신 **`(user_id, answer_date)`**: 화면이 날짜로 조회해서

## 결정 · 메모
- **`question_id` · 단기/장기 구분 칸을 두지 않음**: `delivery_id` 로 알 수 있고, 중복 저장하면 어긋날 위험이 있음 (legacy 에는 `question_id` 가 있었음)
- **원본 답을 `raw_value` 문자열 한 칸으로 합침 (2026-11-21)**: 이번 기획의 답은 숫자 또는 3지선다뿐이고, 원본은 표시 · 재계산용이라 한 칸으로 충분함. 숫자 칸 + 선택 칸으로 나누면 "둘 중 하나만" 규칙과 형태 검사가 DB 에 들어가지만 그만큼 복잡해짐
  - 대신 **형태 검사는 `submit_answer` 함수가 함** (DB 가 글자 · 숫자를 막아 주지 않음)
  - 원본 숫자로 통계("도장 평균 몇 번")를 낼 일이 생기면 `raw_value::numeric` 으로 바꾸거나 숫자 칸을 추가. **분석 · 평균은 `score`(숫자)로 함**
  - legacy 의 `text_value`, `option_id`, 슬라이더 / 이모지 / 예-아니오 형식은 뺌. 선택지는 `questions.config` 에 있어서 `question_options` 테이블도 없음
- **`updated_at` 을 두지 않음**: 답변을 고칠 수 있는지 미정 ([B-4](../기획정리_추가정리필요요소.md)). 고칠 수 있게 하면 `updated_at` 추가 + 고친 뒤 구슬 · 점수 갱신 규칙 필요. 지금은 **한 번 답하면 끝** 으로 둠
- **점수 규칙은 A-9 가 정해지면**: 질문별로 "최대 도장 횟수", 선택지별 점수가 필요. 함수 안의 계산식과 `questions.config` 값만 채우면 되고 **answers 의 칸 구조는 안 바뀜**
- **구슬과의 연결 (2026-11-21 결정)**: `answers.ball_id` 로 답이 담긴 구슬을 가리킴. 구슬을 누르면 `ball_id` 로 그 답들을 바로 찾음. 자세한 내용은 [05-balls.md](05-balls.md)
- 퇴사각 지수 계산 방식([A-10](../기획정리_추가정리필요요소.md))은 이 테이블의 `score` 를 쓰지만, 계산은 나중에 정해지면 함수로 만듦 (answers 는 점수만 저장)

## 이해 확인

<details>
<summary>질문 3개 (펼치기)</summary>

1. 점수(`score`)만 저장하지 않고 원본 값(`raw_value`)도 같이 저장하는 이유는?
2. `delivery_id` 를 unique 로 두면 어떤 일이 막힐까?
3. 앱이 `answers` 에 직접 insert 하지 못하게 하고 DB 함수로만 저장하게 하는 이유는?

| # | 혜리 님 답 | 확인 |
| --- | --- | --- |
| 1 | 나중에 가공하기 위해서 | ⭕ 맞음. 점수 규칙(A-9)이 바뀌면 원본으로 다시 계산하고, 화면에 "도장 7번" 을 다시 보여줄 때도 씀 |
| 2 | 다음날 같은 deliver_id 못 사용 | △ 방향은 비슷함. 정확히는 **같은 나온 질문에 답이 두 번 저장되는 것(중복 답변)** 을 막음 (버튼 두 번 누름, 요청 재전송 등). 다음 날엔 새 질문이 새 `delivery_id` 로 나옴 |
| 3 | unique? → (다시) 조작 방지 | ⭕ 맞음. (처음 답 "unique?" 는 2번 이야기였음)  3번은 **조작 방지**: 앱이 직접 insert 하면 점수를 0점으로 보내거나, 안 나온 · 만료된 질문에 답하거나, 장기 3개 모두에 답할 수 있음 → 함수가 확인하고 점수도 함수 안에서 계산 |

> ✅ answers 이해 완료 (2026-11-21)

</details>
