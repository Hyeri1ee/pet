# 7. intimacy_logs — 친밀도가 언제 왜 올랐나

> 기획 근거: [기획정리.md](../기획정리.md) 8. 친밀도 (요인 3가지 · 줄어들지 않음. 하루 상한은 두지 않기로 함)
> 앞 단계: [ghosts](06-ghosts.md) / 다음 단계: settings(8번)
> 미정 사항: [A-5 친밀도 점수 규칙](../기획정리_추가정리필요요소.md) · [B-10 쓰다듬기 정의](../기획정리_추가정리필요요소.md)

## 왜 필요한가
- `ghosts.intimacy_score` 는 **합계 숫자 하나**라서 "언제 · 왜 올랐는지"를 모름
- 그래서 친밀도가 오를 때마다 **한 줄씩 쌓는 장부**(로그)를 둠. 이 장부가 있으면
  - 오른 **이유(`source`) · 시각**이 남음
  - 점수 규칙([A-5](../기획정리_추가정리필요요소.md))이 바뀌어도 **원본(`amount`)으로 다시 따져 볼 수 있음**
  - 합계가 어긋나면 **장부 합계로 다시 맞출 수 있음**
- **하루 상한은 두지 않기로 함 (2026-11-21)** → 상한을 지키려고 쌓는 건 아님. 장부는 **기록 · 재계산용**
- 기존 `exp_events`(경험치 장부) 구조를 친밀도 장부로 그대로 쓰는 것 ([A-5](../기획정리_추가정리필요요소.md) 참고)

## 다른 테이블과 다른 점: 한 번 쌓으면 고치거나 지우지 않음
- **장부(ledger)** 라서 줄을 추가만 함. 수정 · 삭제 없음 (친밀도가 줄어들지 않는다는 기획과도 맞음 → `points` 는 항상 양수)
- 앱은 읽기만 하고, 쌓는 건 **DB 함수**가 함 (점수 조작 방지)

## 예시 데이터

사용자 `a1b2…` 의 2026-11-21 (점수는 [A-5](../기획정리_추가정리필요요소.md) 의 예시 값을 쓴 **임시 값**: 쓰다듬기 1번 +1, 질문 답변 1번 +5, 나타나 있던 1시간 +2. 질문 점수는 A-5 예시의 "답한 날 +10" 을 **답변마다**로 바꿔 임시로 정함)

| source (왜) | amount (양) | points (오른 점수) | log_date | created_at (언제) |
| --- | --- | --- | --- | --- |
| stroke | 1 (쓰다듬기 1번) | 1 | 2026-11-21 | 10:15 |
| stroke | 1 | 1 | 2026-11-21 | 10:15 |
| stroke | 1 | 1 | 2026-11-21 | 10:40 |
| stroke | 1 | 1 | 2026-11-21 | 11:05 |
| stroke | 1 | 1 | 2026-11-21 | 14:20 |
| presence | 60 (60분) | 2 | 2026-11-21 | 12:00 |
| presence | 60 (60분) | 2 | 2026-11-21 | 13:00 |
| answer | 1 (답변 1번) | 5 | 2026-11-21 | 16:10 |
| answer | 1 | 5 | 2026-11-21 | 16:12 |

- 그날 합계 = 쓰다듬기 5번(1+1+1+1+1) + 2 + 2 + 답변 2번(5+5) = **19점**
- `answer` 줄은 [answers](04-answers.md) 예시처럼 그날 **답한 질문마다 한 줄** (2개 답했으니 2줄) → `ghosts.intimacy_score` 에 더해짐
- 답을 하나도 안 한 날은 `answer` 줄이 없음. 유령을 안 켠 날은 `presence` 줄이 없음

## 칸(컬럼) 설명

| 칸 | 뜻 | 예시 | 비고 |
| --- | --- | --- | --- |
| `id` | 기록 고유 번호 | `l1m2n3o4-…` | uuid |
| `user_id` | 누구의 유령에 쌓였나 | `a1b2…` | `ghosts.user_id` 를 가리킴 (유령 = 사용자당 1마리). 기본값 `auth.uid()` |
| `source` | **왜** 올랐나 (요인) | `stroke` / `answer` / `presence` | 기획의 요인 3가지: 쓰다듬기 / 질문 답변 / 나타나 있던 시간. **질문 답변은 답할 때마다** 한 줄 |
| `amount` | 그 요인의 **양** (원본) | 1 / 1 / 60 | 쓰다듬기 1번(항상 1) · 질문 답변 1번(항상 1) · 나타나 있던 분. 값이 달라지는 건 `presence`(분)뿐. [answers](04-answers.md) 의 `raw_value` 처럼 **원본**을 남김 |
| `points` | 실제로 **오른 점수** | 5 | 양수. `amount` × 요인별 점수([A-5](../기획정리_추가정리필요요소.md)) |
| `log_date` | 어느 날 쌓았나 (사용자 현지 날짜) | 2026-11-21 | 날짜별 조회용 (하루 상한은 없지만, 나중에 상한을 두거나 "오늘 얼마나"를 보여줄 때 기준) |
| `created_at` | **언제** 쌓았나 | 2026-11-21 10:15 | |

### 원본(amount)과 점수(points)를 둘 다 남기는 이유
- [answers](04-answers.md) 와 같은 방식: **점수 규칙([A-5](../기획정리_추가정리필요요소.md))을 나중에 바꿔도** 원본이 있어서 다시 계산해 볼 수 있음
- 이미 쌓은 줄의 `points` 는 **그때 오른 값 그대로** 둠 (역사 기록). 규칙이 바뀌면 이후 줄부터 새 규칙을 씀

## 다른 테이블과 연결
> **유령 1마리에 친밀도 기록이 여러 줄 쌓인다**

```
ghosts ──1:N──< intimacy_logs
 (user_id)        (한 번 오른 기록)

intimacy_logs 에 줄이 생김 ─▶ ghosts.intimacy_score += points ─▶ ghosts.stage 자동 계산
                                 (트리거)                          (06번의 트리거)
```

- **`ghosts.intimacy_score` = 이 사용자의 `points` 합계.** 기록이 원본이고 `ghosts` 의 점수는 읽기 편하게 합계를 들고 있는 것
- 줄이 생길 때 **DB 트리거**가 `ghosts` 의 점수에 자동으로 더함 → 함수가 두 군데를 따로 고치다 어긋날 일이 없음. 점수가 바뀌면 [06번](06-ghosts.md) 트리거가 `stage` 도 맞춤
- 혹시 어긋나면 합계로 다시 맞출 수 있음: `update ghosts set intimacy_score = (select coalesce(sum(points),0) from intimacy_logs where user_id = ghosts.user_id)`

## 어떻게 쌓이나 (DB 함수)

앱이 `intimacy_logs` 에 직접 `insert` 하지 않고 함수를 부름 (점수 조작 방지)

| 요인 | 언제 | 누가 부르나 |
| --- | --- | --- |
| `stroke` 쓰다듬기 | 유령을 **쓰다듬을 때마다 1번씩** | 앱이 `rpc('add_intimacy', { source: 'stroke', amount: 1 })` |
| `presence` 나타나 있던 시간 | 유령이 떠 있는 동안 주기적으로 (예: 일정 시간마다) | 앱이 `rpc('add_intimacy', { source: 'presence', amount: 60 })` |
| `answer` 질문 답변 | 질문에 **답할 때마다** | **`submit_answer` 함수가 안에서 호출** (앱이 따로 안 부름) |

`add_intimacy` 함수가 하는 일:

1. `source` · `amount` 가 올바른지 확인 (정해진 요인 · 양수)
2. `amount` 로 오를 **점수 계산** (요인별 점수는 A-5 에서 정함)
3. `presence` 면 **직전 기록 이후 지난 시간보다 큰 `amount` 는 잘라냄** (부풀리기 방지)
4. `intimacy_logs` 에 한 줄 저장 → 트리거가 `ghosts` 점수에 더함

- **하루 상한은 없음**: 쌓을 때마다 계산한 `points` 가 그대로 쌓임. 그래서 쓰다듬기 연타 · 켜 두기로 점수가 부풀 수 있음 → 요인별 점수를 작게 잡거나 최소 간격을 두는 건 [A-5](../기획정리_추가정리필요요소.md) 에서 정함
- `answer` 는 **답할 때마다 한 줄**: 하루에 단기 최대 3개 + 장기 1개라 줄 수가 자연히 제한됨. 같은 답에 두 번 쌓이지 않는 건 [answers](04-answers.md) 의 `delivery_id` unique + `submit_answer` 가 확인하는 `pending` 상태가 막아 줌

## SQL 초안

```sql
create table intimacy_logs (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references ghosts(user_id) on delete cascade,
  source     text not null check (source in ('stroke', 'answer', 'presence')),
  amount     int  not null check (amount > 0),     -- 쓰다듬기 1 · 질문 답변 1 · 나타나 있던 분
  points     int  not null check (points > 0),     -- 실제로 오른 점수 (줄지 않음)
  log_date   date not null,                        -- 사용자 현지 날짜 (날짜별 조회용)
  created_at timestamptz not null default now()
);

-- 줄이 생기면 유령의 점수에 자동으로 더함 (stage 는 06번 트리거가 맞춤)
create function add_points_to_ghost() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update public.ghosts
     set intimacy_score = intimacy_score + new.points, updated_at = now()
   where user_id = new.user_id;
  return new;
end $$;

create trigger intimacy_log_added
  after insert on intimacy_logs
  for each row execute function add_points_to_ghost();

alter table intimacy_logs enable row level security;

-- 내 것만 읽기. insert / update / delete 정책은 만들지 않음 → 쌓는 건 DB 함수만
create policy "내 친밀도 기록만 읽기" on intimacy_logs
  for select to authenticated using (user_id = (select auth.uid()));
```

- **만드는 순서**: `ghosts` → `intimacy_logs` (`ghosts.user_id` 를 가리키므로)
- 읽기만 열어 둔 이유: 앱이 줄을 마음대로 만들면 점수를 마음대로 올릴 수 있어서
- 인덱스: 앱이 기록 목록을 자주 조회하지 않아서 **지금은 없음**. 하루 상한을 두거나 기록을 날짜별로 보여주게 되면 `(user_id, log_date, source)` 인덱스를 추가

## 결정 · 메모
- **장부(로그) 방식 (2026-11-21)**: 점수를 `ghosts` 한 칸에만 두지 않고 한 줄씩 쌓음. 처음엔 하루 상한을 지키려는 목적이 컸지만 **상한을 두지 않기로 해서(2026-11-21)** 지금은 기록 · 재계산 · 합계 복구가 목적. `ghosts.intimacy_score` 는 그 합계를 읽기 편하게 들고 있는 값
- **하루 상한을 두지 않음 (2026-11-21)**: 기획의 "하루에 쌓을 수 있는 양이 정해져 있음" 을 뺌. [기획정리.md](../../기획정리.md) 8 · [A-5](../../기획정리_추가정리필요요소.md) 도 같이 고침. 로그 테이블은 그대로 두고, 나중에 상한이 필요해지면 `log_date` + 인덱스로 바로 도입할 수 있음
- **질문 답변은 답할 때마다 쌓음 (2026-11-21 확정)**: 처음 기획은 "하루 단위로 답했는지만 봄, 개수는 안 봄" 이었으나 **답변마다 오르는 것으로 바꿈**. 그래서 하루 1번만 쌓게 막던 unique 인덱스를 뺌. [기획정리.md](../../기획정리.md) 8 · [A-5](../../기획정리_추가정리필요요소.md) 도 같이 고침
- **쓰다듬기는 한 번에 한 줄**: 쓰다듬는 건 한 번 한 번의 사건이라 `amount` 는 항상 1. 상한이 없어서 연타하면 줄이 계속 쌓이므로, 연타를 막으려면 **같은 요인의 직전 기록과 최소 간격**을 두는 방법이 있음 ([B-10](../기획정리_추가정리필요요소.md) 정의와 함께 결정)
- **`points` 는 항상 양수**: "친밀도는 줄어들지 않는다" 규칙을 DB 가 그대로 보장 (음수 줄이 들어올 수 없음)
- **`user_id` 가 `ghosts.user_id` 를 가리킴**: 유령 1마리당 기록이 여러 줄. `auth.users` 를 바로 가리켜도 되지만 "유령의 기록"이라는 뜻이 분명해서 `ghosts` 를 가리킴
- **서버가 시간을 검증하기 어려움**: `presence`(나타나 있던 분)는 앱이 보낸 값이라 부풀릴 수 있음 → 함수가 **직전 `presence` 기록 이후 지난 시간(`created_at`)보다 큰 `amount` 는 잘라냄**. **하루 상한이 없으므로 이 검증이 부풀리기를 막는 유일한 장치**
- **`log_date`(하루 기준)**: 사용자 현지 날짜. 앱이 날짜를 보내면 조작 가능 → 서버가 **사용자의 시간대**로 계산하는 게 안전함 (시간대는 8번 `settings` 에 저장할지 개발 때 확인, [03번 메모](03-question-deliveries.md))
- **legacy 와 달라진 점**: `exp_events`(경험치 장부)의 구조를 따르되, 레벨 · 경험치 · 애정도 두 축이 아니라 **친밀도 하나**를 올림. 파일 먹이기는 친밀도에 반영하지 않음(기획) → `source` 에 없음
- **미정 ([A-5](../기획정리_추가정리필요요소.md))**
  - 요인별 점수 (쓰다듬기 1번 · 질문 답변 1번 · 나타나 있던 1시간 각각 몇 점)
  - ~~하루 상한 · 요인별 상한~~: **두지 않기로 결정**. 대신 연타 · 켜 두기 부풀림을 어떻게 다룰지(요인별 점수를 작게 / 최소 간격)
  - 질문 답변 점수를 **단기와 장기가 같게** 줄지 (이달의 질문 답이 더 높을 수 있음) → 다르게 하려면 `source` 를 `answer_short` / `answer_long` 으로 나누거나 함수가 질문 종류로 점수를 정함
  - 나타나 있던 시간에 **숨김 · 졸기 상태**를 포함할지, 자리 비움은 뺄지
  - [B-10](../기획정리_추가정리필요요소.md) **쓰다듬기**의 정의 (마우스 문지르기? 클릭?). 지금은 **쓰다듬기 1번 = 줄 1개(`amount` 1)** 로 둠. 서버 요청이 너무 잦으면 앱이 모아서 보내는 방식(`amount` 여러 번)도 가능하니 정의가 정해질 때 함께 결정
  - 이 값들이 정해지면 **함수의 계산식만 바뀌고 `intimacy_logs` 칸 구조는 그대로**

## 이해 확인

<details>
<summary>질문 3개 (펼치기)</summary>

1. 친밀도를 `ghosts.intimacy_score` 한 칸에만 두지 않고 `intimacy_logs` 에 한 줄씩 쌓는 이유는?
2. `points` 에 `check (points > 0)` 를 걸면 기획의 어떤 규칙이 DB 에서 지켜질까?
3. 앱이 `intimacy_logs` 에 직접 insert 하지 못하게 하고 함수로만 쌓게 하는 이유는?

| # | 혜리 님 답 | 확인 |
| --- | --- | --- |
| 1 | 이 로그 기반으로 친밀도 계산하려고 | ⭕ 맞음. `ghosts.intimacy_score` 는 로그의 합계이고, 로그가 있으면 오른 이유 · 시각이 남고 규칙이 바뀌어도 다시 계산할 수 있음 (하루 상한은 두지 않기로 해서 상한 때문은 아님) |
| 2 | (질문이 바뀜) | 이전 질문 "하루에 너무 많이 오르지 않게 하는 장치" 는 **하루 상한을 두지 않기로 해서 없앰**. 이전 답 "질문 개수 정해짐" 은 줄 수가 자연히 제한된다는 면에서만 맞음 |
| 3 | 조작x | ⭕ 맞음. 앱이 직접 insert 하면 점수를 마음대로 올릴 수 있음 |

> ✅ intimacy_logs 이해 완료 (2026-11-21)

</details>
