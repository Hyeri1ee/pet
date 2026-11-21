# 8. settings — 메뉴 설정값

> 기획 근거: [기획정리.md](../기획정리.md) 9. 우클릭 메뉴(숨기기 · 행동 및 크기 · 말하기 · 설정), 11. 저장되는 정보("메뉴 설정값: 질문 받을 시간, 크기, 투명도, 말 거는 빈도, 숨김 여부, 언어")
> 앞 단계: [intimacy_logs](07-intimacy-logs.md) / 마지막 테이블
> 미정 사항: [B-1 질문 도착 시간](../기획정리_추가정리필요요소.md) · [C-5 언어 범위](../기획정리_추가정리필요요소.md) · [C-4 화면 배치](../기획정리_추가정리필요요소.md)

## 왜 필요한가
- 사용자가 우클릭 메뉴에서 바꾼 **취향 값**(유령 크기, 투명도, 말 거는 빈도 등)을 저장하는 곳
- 앱을 다시 켜거나 **다른 컴퓨터에서 로그인해도** 같은 설정이 이어지게 함
- 언어 · 시간대처럼 **서버 함수가 읽는 값**도 있음 (질문 받을 시간은 앱이 읽어서 도착 시각을 정함)

## 저장 위치: 설정도 Supabase 에만 저장 (2026-11-21 결정)
- 모든 설정을 `settings` 테이블에 저장함. **PC 에는 설정을 따로 저장하지 않음** ([C-6](../기획정리_추가정리필요요소.md) 의 "PC 에는 설정값만 저장"을 이 결정으로 대체)
- 앱은 켜질 때 `settings` 를 **읽어서 화면에 적용**하고, 설정을 바꾸면 `update` 로 Supabase 에 저장함
- 인터넷이 끊겼을 때 설정이 어떻게 적용될지(기본값으로 뜨는지 등)는 C-6 의 미정 항목(연결이 끊겼을 때 동작)과 함께 정함

| 설정 | 메뉴 | 칸 |
| --- | --- | --- |
| 질문 받을 시간 | 설정 | `question_time` |
| 언어 | 설정 | `language` |
| 컴퓨터 켜면 자동 실행 | 설정 | `auto_launch` |
| 말하기 켜기 / 끄기 | 말하기 | `talk_enabled` |
| 말 거는 빈도 (5단계) | 말하기 | `talk_frequency` |
| 말풍선이 떠 있는 시간 | 말하기 | `bubble_seconds` |
| 크기 (작게 / 기본 / 크게) | 행동 및 크기 | `ghost_size` |
| 투명도 | 행동 및 크기 | `opacity` |
| 걸어다니기 / 가만히 있기 | 행동 및 크기 | `movement` |
| 중력 | 행동 및 크기 | `gravity` |
| 숨기기 (30분 · 1시간 · 3시간) | 숨기기 | `hidden_until` |
| 숨기기 단축키 | 숨기기 | `hide_shortcut` |
| (내부 값) 시간대 | 없음 | `timezone` |

- 메뉴에 있어도 **값이 아닌 동작**은 칸이 없음: 계정 연결, 업데이트 확인, 종료, 이름 짓기(이름은 [ghosts](06-ghosts.md))
- **유령의 화면 위치는 저장하지 않음**: 유령이 걸어다니고 모니터 · 작업표시줄 위치에 따라 달라져서([C-4](../기획정리_추가정리필요요소.md)) 저장할 값이 아니라고 봄. 필요해지면 칸을 추가

## 다른 테이블과 다른 점
- [ghosts](06-ghosts.md) 처럼 **사용자당 1줄**이라 `user_id` 가 기본키 (공통 규칙의 `id` 예외)
- 점수와 달리 **앱이 직접 바꿔도 되는 값**: 설정은 조작해도 이득이 없는 개인 취향이라 앱이 `update` 하게 열어 둠 (값의 범위는 DB 가 `check` 로 막음)

## 예시 데이터

[users](01-users.md) 의 두 사용자와 같은 id (기본값은 **임시**)

| user_id | question_time | language | auto_launch | talk_enabled | talk_frequency | bubble_seconds |
| --- | --- | --- | --- | --- | --- | --- |
| `a1b2…` | 17:00 | ko | true | true | 2 | 5 |
| `c3d4…` | 16:00 | ko | false | true | 3 | 5 |

| user_id | ghost_size | opacity | movement | gravity | hidden_until | hide_shortcut | timezone |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `a1b2…` | large | 80 | still | false | 2026-11-21 15:30 | Ctrl+Shift+G | Asia/Seoul |
| `c3d4…` | normal | 100 | walk | true | (없음) | (기본 단축키) | Asia/Seoul |

- 첫 번째 줄: 설정을 바꾼 사용자 (질문은 5시, 말은 조금만, 크게, 약간 투명, 가만히, 지금 3시 반까지 숨김 중)
- 두 번째 줄: 아무것도 안 바꾼 사용자 = **기본값 그대로** (`hidden_until` 과 `hide_shortcut` 은 비어 있음)

## 칸(컬럼) 설명

| 칸 | 뜻 | 예시 | 기본값 | 비고 |
| --- | --- | --- | --- | --- |
| `user_id` | 누구의 설정인가 (**기본키**) | `a1b2…` | | `auth.users` 의 id. 사용자 1명당 1줄 |
| `question_time` | 질문 받을 **기준 시각** | 17:00 | 16:00 | 정확히 이 시각이 아니라 **앞뒤 20분 사이 랜덤**에 도착 ([아래](#question_time--정확한-시각이-아니라-그-즈음)). 기본값은 기획의 "오후 4시쯤" |
| `language` | 언어 | `ko` | `ko` | 지원 언어 범위는 [C-5](../기획정리_추가정리필요요소.md) 에서 정함 (그래서 값 제한은 아직 없음) |
| `auto_launch` | 컴퓨터 켜면 자동 실행 | true | false | 임시. 실제 실행 등록은 앱이 운영체제에 함 |
| `talk_enabled` | 말하기 켜기 / 끄기 | true | true | |
| `talk_frequency` | 말 거는 빈도 (5단계) | 2 | 3 | 1~5. 기획의 "5단계" |
| `bubble_seconds` | 말풍선이 떠 있는 시간(초) | 5 | 5 | 0보다 커야 함. 시간 범위는 임시 |
| `ghost_size` | 유령 크기 | `large` | `normal` | `small` / `normal` / `large` (작게 / 기본 / 크게) |
| `opacity` | 투명도 (%) | 80 | 100 | 0~100. 너무 투명하면 안 보이므로 최소값은 앱에서 정함 |
| `movement` | 걸어다니기 / 가만히 있기 | `still` | `walk` | `walk` / `still` |
| `gravity` | 중력 | false | true | 중력의 정확한 의미는 앱 쪽에서 정함 |
| `hidden_until` | 이 시각까지 숨김 | 2026-11-21 15:30 | 비어 있음(null) | 숨기기를 누르면 지금 + 30분 · 1시간 · 3시간으로 채움. **null 이거나 지난 시각이면 숨김 아님**. "다시 나타나기"는 null 로 되돌림 |
| `hide_shortcut` | 숨기기 단축키 | `Ctrl+Shift+G` | 비어 있음(null) | null 이면 앱의 기본 단축키 |
| `timezone` | 사용자 시간대 | `Asia/Seoul` | `Asia/Seoul` | **기획 메뉴에는 없는 내부 값.** 앱이 컴퓨터 시간대로 자동으로 채움 (아래 설명) |
| `created_at` / `updated_at` | 만든 / 마지막 변경 시각 | | | |

### `question_time` — 정확한 시각이 아니라 "그 즈음"
- 질문은 `question_time` **앞뒤 20분 사이의 랜덤 시각**에 도착함. 예: 17:00 → **16:40 ~ 17:20** 사이
- 도착 시각은 **하루에 한 번 앱이 랜덤으로 정함**. 알림이 뜨는 시각일 뿐이라 서버가 정할 필요가 없고, 조작해도 얻는 게 없음
- 그 시각이 되면 앱이 `draw_daily_questions()` ([03](03-question-deliveries.md)) 를 불러 질문을 뽑고 질문 아이콘을 띄움
- 하루 안에서만: `question_time` 이 자정 근처면 00:00~23:59 안으로 자름 (예: 23:50 → 23:30~23:59)
- **±20분은 고정 규칙**이라 칸으로 만들지 않음 (메뉴에 없음). 바꾸고 싶으면 앱의 상수 하나만 고치면 됨
- 앱을 껐다 켜서 도착 시각을 다시 정해도, 그날 질문이 이미 뽑혔으면 **같은 질문이 그대로** 나옴 ([03](03-question-deliveries.md) 의 "여러 번 불러도 결과 같음")

### `hidden_until` — "숨김 여부"를 시각으로 저장
- 기획 11 의 "숨김 여부"는 30분 / 1시간 / 3시간 **동안만** 숨는 것이라 true / false 가 아니라 **언제까지 숨는지**를 저장하면 끝나는 시점이 자동으로 정해짐 (따로 "숨김 해제"를 저장할 필요 없음)
- 현재 시각이 `hidden_until` 보다 이르면 숨김, 아니면 보임 → 앱이 꺼졌다 켜져도 남은 시간이 이어짐

### `timezone` 이 필요한 이유 (내부 값, 넣기로 확정)
- 지금까지 [03](03-question-deliveries.md) · [05](05-balls.md) · [07](07-intimacy-logs.md) 에서 "하루 기준은 **사용자 현지 날짜**, 자정에 만료"라고 정했는데, **서버가 사용자의 시간대를 알아야** 현지 날짜를 정확히 셀 수 있음
- 앱이 날짜를 직접 보내면 조작할 수 있어서 **서버가 `timezone` 으로 계산**하는 게 안전함
- 사용자가 메뉴에서 고르는 값이 아니라 **앱이 운영체제의 시간대로 채움**. 이사 · 출장으로 바뀌면 갱신

## 다른 테이블과 연결

```
auth.users ──1:1── settings
auth.users ──1:1── ghosts
```

- `settings` 는 다른 테이블이 가리키지 않음. 대신 **함수가 읽어서 씀**
  - `timezone` → 질문 뽑기 · 하루 경계 ([03](03-question-deliveries.md))
  - `question_time` → **앱이** 읽어서 질문 도착 시각을 정함 (서버 함수는 안 읽음)
  - `timezone` → `ball_date` · `log_date` · `answer_date` 계산 ([04](04-answers.md) · [05](05-balls.md) · [07](07-intimacy-logs.md))
  - `language` → 질문 · 대사 언어 (번역 범위는 C-5)
  - 나머지(크기 · 투명도 · 말하기 · 숨김 · 단축키 등)는 **앱 화면이 읽어서** 적용 (서버 로직은 안 씀)

## 어떻게 만들어지고 바뀌나

| 언제 | 누가 | 하는 일 |
| --- | --- | --- |
| 사용자가 처음 생길 때 | **DB 트리거** | [06번](06-ghosts.md) 의 같은 트리거가 `ghosts` 와 함께 `settings` 도 기본값으로 1줄 만듦 |
| 앱이 켜질 때 | 앱 | `settings` 를 읽어 화면에 적용 (PC 에 저장하지 않음). `timezone` 이 운영체제와 다르면 갱신 |
| 메뉴에서 값을 바꿀 때 | 앱이 직접 | `update settings set ghost_size = 'large' where …` (내 줄만) |

## SQL 초안

```sql
create table settings (
  user_id         uuid primary key references auth.users(id) on delete cascade,
  question_time   time     not null default '16:00',
  language        text     not null default 'ko',
  auto_launch     boolean  not null default false,
  talk_enabled    boolean  not null default true,
  talk_frequency  smallint not null default 3  check (talk_frequency between 1 and 5),
  bubble_seconds  int      not null default 5  check (bubble_seconds > 0),
  ghost_size      text     not null default 'normal' check (ghost_size in ('small', 'normal', 'large')),
  opacity         smallint not null default 100 check (opacity between 0 and 100),
  movement        text     not null default 'walk' check (movement in ('walk', 'still')),
  gravity         boolean  not null default true,
  hidden_until    timestamptz,                    -- null = 숨김 아님
  hide_shortcut   text,                           -- null = 기본 단축키
  timezone        text     not null default 'Asia/Seoul',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

alter table settings enable row level security;

create policy "내 설정 읽기" on settings
  for select to authenticated using (user_id = (select auth.uid()));

-- 설정은 앱이 직접 바꿈 (취향 값이라 조작해도 이득 없음). user_id 를 남의 것으로 바꾸는 건 with check 가 막음
create policy "내 설정 바꾸기" on settings
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
-- insert / delete 정책은 만들지 않음 → 줄은 가입 때 트리거가 만듦
```

- **만드는 순서**: `settings` → `handle_new_user` 트리거 함수([06번](06-ghosts.md))에 `settings` insert 추가
- `timezone` 은 값 확인(`check`)을 일부러 넣지 않음. 잘못된 이름이면 함수가 변환 단계에서 오류가 나므로, 앱이 운영체제 값을 쓰거나 `pg_timezone_names` 로 확인하는 편이 나음 → 개발 때 확인
- 기본키가 `user_id` 라서 **추가 인덱스는 필요 없음**

## 결정 · 메모
- **설정은 전부 Supabase 에 저장 (2026-11-21)**: PC 에 따로 저장하지 않음. 대신 아래 점을 알고 있어야 함
  - **기기마다 다른 값도 사용자 하나에 한 벌**: `auto_launch` · `hide_shortcut` · `hidden_until` 은 원래 컴퓨터마다 다른 값인데, 한 줄이라 **컴퓨터가 여러 대면 서로 영향을 줌** (예: 집 컴퓨터에서 3시간 숨기면 회사 컴퓨터의 유령도 숨음, 자동 실행도 같이 켜짐). 한 명이 한 컴퓨터만 쓰면 문제없음
  - 기기별로 다르게 하고 싶어지면 `device_settings`(`user_id` + 기기 id) 테이블을 **나중에 따로 추가**하면 되고 다른 테이블은 안 바뀜
  - 설정이 연결 없이도 바로 적용되던 장점은 없음: 앱이 켜질 때 `settings` 를 읽어야 함 (끊겼을 때의 동작은 C-6 미정 항목)
- **`timezone` 을 넣음 (2026-11-21 확정)**: 하루 경계 · 자정 만료를 서버가 계산하려면 필요
- **`ghosts` 와 합치지 않음**: 유령 정보(이름, 친밀도)는 앱이 **규칙으로** 바꾸고 일부는 앱이 못 바꾸지만, 설정은 사용자가 **마음대로** 바꿈. 바뀌는 방식과 권한이 달라서 따로 둠 ([01-users 에서 배운 것](01-users.md)과 같은 이유)
- **값을 칸마다 따로 둠**(jsonb 한 칸이 아니라): 칸마다 기본값 · `check`(범위) 를 DB 가 지켜 주고, 서버 함수가 읽어야 하는 값(`timezone`, `language`)을 바로 조회할 수 있어서. 설정이 자주 늘어나면 jsonb 로 바꿀 수 있음
- **시간대를 바꾸면 하루 경계가 바뀜**: 사용자가 `timezone` 을 직접 바꿔서 하루에 구슬을 더 받는 식의 악용 가능성이 있음 → 앱이 운영체제 값으로만 채우고, 서버가 바뀌는 횟수를 제한할지는 개발 때 확인
- **legacy 와 달라진 점**: legacy 의 `users` 에 있던 출퇴근 · 점심 시간 칸은 두지 않음 (메뉴에 없음, [B-8](../기획정리_추가정리필요요소.md))
- **미정**
  - [B-1](../기획정리_추가정리필요요소.md) 질문 도착 시각은 **앞뒤 20분 랜덤**으로 정함 (2026-11-21). 남은 것: 그 시각에 컴퓨터가 꺼져 있었으면 켤 때 도착하는지
  - [C-5](../기획정리_추가정리필요요소.md) 언어 범위(한국어 · 영어?) → `language` 에 `check` 를 걸지
  - 말 거는 빈도 5단계 · 말풍선 시간 · 투명도 최소값 · 자동 실행 기본값의 **실제 값**
  - 기획 메뉴에 "출근 · 점심 · 퇴근 시간 입력"을 넣을지 ([B-8](../기획정리_추가정리필요요소.md)). 넣으면 `settings` 에 칸 추가

## 이해 확인

<details>
<summary>질문 3개 (펼치기)</summary>

1. 설정을 PC 에 저장하지 않고 Supabase 에만 저장하면 어떤 점이 좋고, 어떤 점이 불편할까?
2. 친밀도 점수는 앱이 못 고치게 막았는데, `settings` 는 앱이 직접 `update` 하게 해도 되는 이유는?
3. `settings` 를 `ghosts` 에 합치지 않고 따로 두는 이유는?

| # | 혜리 님 답 | 확인 |
| --- | --- | --- |
| 1 | | |
| 2 | | |
| 3 | | |

> ✅ settings 이해 완료 (2026-11-21)

</details>
