# 3. question_deliveries — 누구에게 언제 어떤 질문이 나왔나

> 기획 근거: [기획정리.md](../기획정리.md) 3. 오늘의 질문(매일 5개 중 3개 랜덤) · 4. 이달의 질문(월 1회, 3개 중 1개 고르기)
> 앞 단계: [users](01-users.md) · [questions](02-questions.md) / 다음 단계: answers(4번)

## 왜 필요한가
- questions 는 질문 **8개의 원본 목록**일 뿐, **누구에게 오늘 어떤 질문이 나왔는지**는 모름
- "오늘 나에게 나온 3개", "이번 달 이달의 질문 3개" 를 기억하는 곳
- 이게 없으면 앱을 껐다 켜거나 여러 번 열 때마다 **질문이 다시 뽑혀서 바뀜**
- 답변(`answers`)은 이 "나온 질문" 한 줄에 **붙는 것** → 나오지 않은 질문에는 답할 수 없음

## 다른 테이블과 다른 점
- **기록 테이블**이라 `user_id` 가 있음 (RLS 로 내 것만 보임)
- 하지만 앱이 직접 `insert` · `update` 하지 않음. **DB 함수가 뽑고 상태를 바꿈** → 앱이 마음대로 "이 질문 나왔다고" 만들 수 없게 (조작 방지)

## 예시 데이터

사용자 `a1b2…` 의 2026-11-21 (오늘의 질문, 오후 4시에 3개 뽑힘) + 이번 달 이달의 질문

| user_id | 질문 (`code`) | period_key | draw_group | status | delivered_at | expires_at |
| --- | --- | --- | --- | --- | --- | --- |
| `a1b2…` | RESIGN_URGE | `D:2026-11-21` | (없음) | answered | 11-21 16:02 | 11-22 00:00 |
| `a1b2…` | WORK_STRESS | `D:2026-11-21` | (없음) | answered | 11-21 16:02 | 11-22 00:00 |
| `a1b2…` | EMOTION_DRAIN | `D:2026-11-21` | (없음) | pending | 11-21 16:02 | 11-22 00:00 |
| `a1b2…` | WELFARE | `M:2026-11` | `g-1111` | answered | 11-05 10:00 | 11-06 00:00 |
| `a1b2…` | CULTURE | `M:2026-11` | `g-1111` | skipped | 11-05 10:00 | 11-06 00:00 |
| `a1b2…` | STABILITY | `M:2026-11` | `g-1111` | skipped | 11-05 10:00 | 11-06 00:00 |

- 위 3줄(단기): 5개 중 **3개가 뽑혀** 3줄 생김. 2개 답했고 1개는 아직 → 자정이 지나면 "만료"
- 아래 3줄(장기): 3개가 **모두 한 번에** 나옴(같은 `draw_group`). 마음에 드는 1개(복지)에 답했고 나머지 2개는 `skipped`. 11월 5일 안에 답하지 않았다면 3줄 모두 자정에 만료되고 **그 달 이달의 질문은 없음**
- 같은 날 나온 3줄은 `period_key` 가 같음 (`D:날짜`). 이달의 질문은 `M:연-월`

## 칸(컬럼) 설명

| 칸 | 뜻 | 예시 | 비고 |
| --- | --- | --- | --- |
| `id` | 이 "나온 질문" 한 줄의 고유 번호 | `d1e2f3a4-…` | uuid. answers 가 이 번호를 가리킴 |
| `user_id` | 누구에게 나왔나 | `a1b2…` | `auth.users` 의 id. 기본값 `auth.uid()` |
| `question_id` | 어떤 질문이 나왔나 | `q1a2…` | questions 의 id |
| `period_key` | 어느 기간의 질문인가 | `D:2026-11-21` / `M:2026-11` | `D:` 하루, `M:` 한 달. **같은 기간에 같은 질문이 두 번 나오는 걸 막는 열쇠** |
| `draw_group` | 같이 나온 묶음 | `g-1111` | 장기에서 "3개 중 1개 고르기" 묶음. 단기는 비어 있음(null) |
| `status` | 지금 상태 | `pending` / `answered` / `skipped` | 아래 표 참고 |
| `delivered_at` | 언제 나왔나 | 2026-11-21 16:02 | |
| `expires_at` | 언제까지 답할 수 있나 | 2026-11-22 00:00 | 단기 · 장기 모두 **나온 날 자정** (2026-11-21 결정) |

### status 3가지

| 값 | 뜻 |
| --- | --- |
| `pending` | 나왔고 아직 답 안 함 |
| `answered` | 답함 (answers 에 한 줄 생김) |
| `skipped` | 장기 3개 중 **고르지 않은 것** |

- "**만료**(expired)"는 칸으로 저장하지 않음. **`pending` 인데 `expires_at` 이 지난 것** = 만료. 자정에 값을 바꾸는 작업을 따로 돌리지 않아도 됨
- 0개 답한 날: 3줄 모두 `pending` 인 채로 자정이 지나 만료 → 불이익 없음 (기획)
- 장기도 똑같음: 나온 날 안에 답하지 않으면 만료, 다음 달에 새로 나옴

## 다른 테이블과 연결

```
auth.users ──< question_deliveries >── questions
  (누구에게)       (나온 질문 한 줄)       (어떤 질문)
                        │
                        └── answers.delivery_id  ← 답은 이 한 줄에 붙음 (4번)
```

- 사용자 1명 → 나온 질문 **여러 줄** (매일 3줄 + 달마다 3줄)
- 질문 1개 → 나온 질문 **여러 줄** (여러 사람 · 여러 날)
- 나온 질문 1줄 → 답변 **0개 또는 1개** (한 번 나온 질문엔 답 하나만)

## 어떻게 만들어지나 (DB 함수)

| 언제 | 함수 | 하는 일 |
| --- | --- | --- |
| 질문 받을 시간 앞뒤 20분 사이(기본 오후 4시쯤)에 앱이 호출 | `draw_daily_questions()` | 오늘(`D:날짜`) 아직 안 뽑았으면 `short` 5개 중 3개를 랜덤으로 뽑아 3줄 생성. **이미 뽑았으면 같은 3줄을 돌려줌** (여러 번 불러도 결과 같음) |
| 한 달에 한 번 정해진 날 | `draw_monthly_questions()` | 이번 달(`M:연-월`) 아직 안 뽑았으면 `long` 3개 모두 한 묶음(`draw_group`)으로 생성 |
| 사용자가 답할 때 | 답변 함수 (4번에서) | 내 질문인지 · `pending` 인지 · 만료 안 됐는지 확인 → 답 저장 + `answered` (장기는 나머지를 `skipped`) |

- 앱을 껐다 켜도 같은 3개가 나옴 → 질문 바꿔치기 방지
- "하루 최대 3개 답변"은 하루에 **3줄만 만들어서** 자연스럽게 지켜짐

## SQL 초안

```sql
create table question_deliveries (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  question_id  uuid not null references questions(id),
  period_key   text not null,                 -- 'D:2026-11-21' | 'M:2026-11'
  draw_group   uuid,                          -- 장기 3개 묶음, 단기는 null
  status       text not null default 'pending'
               check (status in ('pending', 'answered', 'skipped')),
  delivered_at timestamptz not null default now(),
  expires_at   timestamptz,                   -- 단기 · 장기 모두 나온 날 자정
  unique (user_id, question_id, period_key)   -- 같은 기간에 같은 질문 두 번 X
);

-- 오늘(이번 달)의 질문 조회 + 내 기록 조회용
create index on question_deliveries (user_id, period_key);
create index on question_deliveries (user_id, delivered_at desc);

alter table question_deliveries enable row level security;

-- 내 것만 읽기. insert / update / delete 정책은 만들지 않음 → 변경은 DB 함수(security definer)만
create policy "내 질문만 읽기" on question_deliveries
  for select to authenticated using (user_id = (select auth.uid()));
```

- `unique (user_id, question_id, period_key)` 가 중복을 막아 주고, 이 unique 도 인덱스 역할을 함
- 읽기만 열어 둔 이유: 앱이 `status` 를 직접 `answered` 로 바꾸거나 질문을 골라 넣으면 **조작이 가능**해서

## 결정 · 메모
- **legacy 와 달라진 점**: `channel`(말풍선 / 쪽지 / 카드) 칸을 뺌 → 새 흐름은 **질문 아이콘을 눌러 시작**하는 한 가지뿐. `question_version` 도 뺌 (문구 수정 대신 새 질문 추가, [questions 메모](02-questions.md))
- **`expired` 를 저장하지 않음**: `pending` + `expires_at` 지남으로 판단. 필요하면 나중에 추가
- **날짜 기준**: `D:2026-11-21` 의 날짜와 "자정"은 **사용자의 현지 시간** 기준 (Asia/Seoul 등). 앱이 현지 날짜를 함수에 넘기거나, 설정에 시간대를 저장해야 함 → 개발 때 확인
- **단기 뽑기 규칙**: "최근 3일 안에 나온 질문은 가중치 낮춤" 을 유지할지 ([A-1](../기획정리_추가정리필요요소.md) 확인 사항). 풀이 5개라 3개씩 뽑으면 같은 질문이 자주 반복됨. 이 테이블에서 최근 기록을 조회하면 가능
- **장기도 `expires_at` = 나온 날 자정 (2026-11-21)**: 단기와 같은 규칙. 그날 답하지 않으면 그 달 이달의 질문은 없음 ([A-6](../기획정리_추가정리필요요소.md) 중 "그날 답하지 않으면?" 해결)
- **미정 (기획 대조 필요)**
  - 장기 질문이 나오는 **날짜**(매달 며칠, "정해진 날")
  - 장기 질문이 나오는 날 **오늘의 질문도 같이** 나오는지
  - 질문 도착 시각: **설정한 질문 받을 시간의 앞뒤 20분 사이 랜덤**으로 정해짐 ([08-settings](08-settings.md)). 남은 것: 그 시각에 컴퓨터가 꺼져 있었으면 켤 때 도착하는지 ([B-1](../기획정리_추가정리필요요소.md))
  - 주말 · 공휴일에도 질문이 오는지 ([B-2](../기획정리_추가정리필요요소.md)) → 오지 않으면 함수가 그날은 안 뽑음

## 이해 확인

<details>
<summary>질문 3개 (펼치기)</summary>

1. questions 만 있으면 안 되고 question_deliveries 가 따로 필요한 이유는?
2. 앱을 껐다 켜도 오늘 나온 질문 3개가 바뀌지 않으려면 어떻게 해야 할까?
3. 이달의 질문 3개 중 1개에 답하면 나머지 2개는 어떤 상태가 될까?

| # | 혜리 님 답 | 확인 |
| --- | --- | --- |
| 1 | | |
| 2 | | |
| 3 | | |

> ✅ question_deliveries 이해 완료 (2026-11-21)

</details>
