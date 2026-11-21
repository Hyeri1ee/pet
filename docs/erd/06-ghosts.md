# 6. ghosts — 내 유령

> 기획 근거: [기획정리.md](../기획정리.md) 1. 유령 캐릭터, 8. 친밀도, 9. 우클릭 메뉴(이름 짓기 / 바꾸기), 11. 저장되는 정보("유령 이름, 친밀도 점수와 단계")
> 앞 단계: [balls](05-balls.md) / 다음 단계: intimacy_logs(7번)
> 미정 사항: [A-5 친밀도 점수 규칙](../기획정리_추가정리필요요소.md) · [B-9 첫 실행(이름 짓기)](../기획정리_추가정리필요요소.md) · [A-8 용어(펫 vs 유령)](../기획정리_추가정리필요요소.md)

## 왜 필요한가
- 사용자마다 **유령이 1마리**. 그 유령의 **이름**과 **친밀도**를 저장하는 곳
- 앱을 다시 켜도, 다른 컴퓨터에서 로그인해도 같은 이름 · 같은 친밀도가 이어져야 함
- 친밀도는 말투 · 새 대사 · 새 행동이 열리는 기준 ([기획정리.md](../기획정리.md) 8)
- 유령 **종류를 뽑는 기능은 없음** (유령 하나로 고정, A-7) → 종류 칸이 없음

## 다른 테이블과 다른 점: 사용자당 딱 1줄, `user_id` 가 기본키
- 유령은 사용자 1명당 **정확히 1마리** → 줄이 많아질 일이 없어서 `id` 를 따로 만들지 않고 **`user_id` 자체를 기본키**로 씀 (공통 규칙의 `id` 예외)
- 그러면 DB 가 "사용자 한 명에 유령 두 마리"를 **저절로 막아 줌**
- 다른 테이블이 유령을 가리킬 때도 `user_id` 로 가리킴 (예: 친밀도 기록, 7번)

## 예시 데이터

[users](01-users.md) 의 두 사용자와 같은 id

| user_id | name | intimacy_score | stage | created_at |
| --- | --- | --- | --- | --- |
| `a1b2…` | 몽글이 | 130 | 2 | 2026-11-18 09:00 |
| `c3d4…` | (이름 없음) | 0 | 1 | 2026-11-19 14:30 |

- 첫 번째 줄: 이름을 지어 주고 며칠 함께한 유령
- 두 번째 줄: 방금 시작한 사용자. **유령은 있지만 이름은 아직 없음** (null)
- `stage`(단계)는 `intimacy_score` 에서 **계산해서 같이 저장**한 값. 위 숫자와 단계 경계(임시: 100점마다 1단계)는 모두 임시임

## 칸(컬럼) 설명

| 칸 | 뜻 | 예시 | 비고 |
| --- | --- | --- | --- |
| `user_id` | 누구의 유령인가 (**기본키**) | `a1b2…` | `auth.users` 의 id. 사용자 1명당 1줄 |
| `name` | 유령 이름 | 몽글이 | 처음엔 비어 있을 수 있음(null). 우클릭 메뉴 "이름 짓기 / 바꾸기"로 사용자가 직접 바꿈. 길이 제한은 임시로 1~20자 |
| `intimacy_score` | 친밀도 점수 | 130 | 0 이상. **줄어들지 않음**. 앱이 직접 못 고치고 DB 함수만 올림 |
| `stage` | 친밀도 단계 (1~5) | 2 | 1~5. 말투 · 새 대사 · 새 행동이 열리는 기준. **점수에서 계산되어 저장됨**, 앱이 직접 못 고침 |
| `created_at` | 유령이 처음 생긴 시각 | 2026-11-18 09:00 | 사용자가 처음 앱을 실행한 때 |
| `updated_at` | 마지막으로 바뀐 시각 | 2026-11-21 16:10 | 이름이나 점수 · 단계가 바뀔 때 |

### 점수(`intimacy_score`)와 단계(`stage`)의 관계
- **점수**는 쌓이는 값, **단계**는 그 점수가 **어느 구간인지**로 정해지는 값 (예: 100점이 되면 1단계 → 2단계. 구간은 [A-5](../기획정리_추가정리필요요소.md) 에서 정함)
- 단계도 칸으로 **같이 저장함**: 앱이 `stage` 만 읽으면 대사 · 행동을 바로 고를 수 있고, 계산 함수를 앱이 알 필요가 없음
- 단, 둘을 따로 저장하면 **어긋날 수 있음** → 점수가 바뀔 때 **DB 트리거가 단계를 자동으로 다시 계산해서 채움**. 함수든 직접이든 점수를 올리면 단계는 항상 따라옴 (한 곳에서만 계산)
- 점수는 줄지 않으므로 단계도 내려가지 않음
- 단계 경계값이 나중에 바뀌면: 계산 함수 `intimacy_stage(score)` 를 고치고 **기존 줄의 `stage` 를 한 번 다시 계산**해 줘야 함 (`update ghosts set stage = intimacy_stage(intimacy_score)`)

### 올라간 기록은 여기 없음
- "언제 · 왜 올랐나"는 알 수 없음 (하루 상한은 두지 않기로 함)
- 그 기록은 `ghosts` 가 아니라 **친밀도 기록 테이블(`intimacy_logs`, 7번)** 에 쌓음. `ghosts.intimacy_score` 는 그 합계(결과값)만 가짐

## 다른 테이블과 연결
> **사용자 1명 ↔ 유령 1마리**

```
auth.users ──1:1── ghosts ──< intimacy_logs (7번: 친밀도가 언제 왜 올랐나)
```

- `ghosts.user_id` 가 `auth.users.id` 를 가리킴
- 질문 · 답변 · 구슬은 `user_id` 로 같은 사용자에 붙어 있고 `ghosts` 와 직접 연결되진 않음. **"질문 답변"이 친밀도를 올리는 요인**이라 답변 함수가 친밀도 함수도 같이 부름

## 어떻게 만들어지고 바뀌나

| 언제 | 누가 | 하는 일 |
| --- | --- | --- |
| 사용자가 처음 생길 때 (익명 로그인) | **DB 트리거** | `auth.users` 에 줄이 생기면 `ghosts` 에도 `user_id` 만 채운 줄을 자동으로 만듦 (이름 null, 점수 0) |
| 이름 짓기 / 바꾸기 | 앱이 직접 | `name` 한 칸만 `update` 할 수 있음 |
| 쓰다듬기 · 질문 답변 · 나타나 있던 시간 | **DB 함수** | `intimacy_logs` 에 기록하고 `intimacy_score` 를 올림 (7번에서 설계). **`stage` 는 트리거가 알아서 맞춤** |

- 트리거로 만들기 때문에 **모든 사용자가 반드시 유령 1마리**를 가짐 → 앱에서 "유령이 있는지" 확인하고 만드는 코드가 필요 없음 (여러 기기에서 동시에 처음 켜도 안 꼬임)

## SQL 초안

```sql
create table ghosts (
  user_id        uuid primary key references auth.users(id) on delete cascade,
  name           text check (name is null or char_length(name) between 1 and 20),
  intimacy_score int  not null default 0 check (intimacy_score >= 0),
  stage          smallint not null default 1 check (stage between 1 and 5),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- 점수 → 단계 (경계값은 임시: 100점마다 1단계, 최대 5. A-5 가 정해지면 이 함수만 고침)
create function intimacy_stage(score int) returns smallint
language sql immutable as $$
  select least(5, 1 + score / 100)::smallint
$$;

-- 점수가 바뀔 때 단계를 자동으로 맞춤 (둘이 어긋나지 않게)
create function sync_ghost_stage() returns trigger
language plpgsql as $$
begin
  new.stage := intimacy_stage(new.intimacy_score);
  return new;
end $$;

create trigger ghost_stage_sync
  before insert or update of intimacy_score on ghosts
  for each row execute function sync_ghost_stage();

-- 새 사용자가 생기면 유령도 자동으로 1마리
create function handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.ghosts (user_id) values (new.id);
  insert into public.settings (user_id) values (new.id);   -- 8번 settings 를 만든 뒤에 추가
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

alter table ghosts enable row level security;

create policy "내 유령 읽기" on ghosts
  for select to authenticated using (user_id = (select auth.uid()));

-- 이름만 고칠 수 있음: 정책 + 칸 단위 권한
create policy "내 유령 이름 바꾸기" on ghosts
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

revoke update on ghosts from authenticated;
grant  update (name) on ghosts to authenticated;   -- intimacy_score · stage 는 앱이 못 고침
-- insert / delete 정책은 만들지 않음
```

- **칸 단위 권한**을 쓰는 이유: RLS 는 "어느 줄"을 막고, "어느 칸"은 못 막음. 이름은 앱이 바꾸게 하되 **점수는 못 건드리게** `update (name)` 만 열어 줌 (점수 조작 방지)
- 기본키가 `user_id` 라서 `user_id` 로 찾는 조회는 인덱스가 자동으로 생김 → **추가 인덱스 필요 없음**
- `updated_at` 은 점수가 오를 때는 함수가, 이름을 바꿀 때는 갱신 트리거가 필요함 → 구현 때 처리

## 결정 · 메모
- **`user_id` 를 기본키로 (공통 규칙의 `id` 예외)**: 사용자당 1마리라서. 나중에 유령이 여러 마리가 된다면(유령 종류, 수집 등) 그때 `id` 를 추가
- **`stage` 를 칸으로 저장 (2026-11-21)**: 기획의 "친밀도 점수와 단계"(11. 저장되는 정보) 그대로. 처음엔 점수로만 계산하려 했지만 앱이 단계를 바로 읽는 편이 단순해서 저장하기로 함. 어긋남은 **트리거**가 막고, 경계값이 바뀌면 한 번 재계산
- **`name` 이 null 일 수 있음**: 첫 실행에 이름을 받는지가 미정([B-9](../기획정리_추가정리필요요소.md)). 비어 있으면 앱이 기본 호칭("유령")을 보여줌. 첫 실행에서 꼭 받기로 하면 `not null` 로 바꿈
- **legacy 와 달라진 점**: 레벨 · 경험치 + 애정도 두 축을 **친밀도 하나로 합침**(A-5), 유령 종류 뽑기 없음, 유령 상태 규칙 · 종류 테이블 없음. 이름은 legacy 의 `users` 가 아니라 `ghosts` 에 둠
- **대사 · 행동 목록은 이 테이블 범위 밖**: 단계별로 열리는 대사 · 행동은 아직 미정(A-5). 질문처럼 DB 에 seed 로 넣기로 하면([A-7](../기획정리_추가정리필요요소.md)) 대사 테이블을 나중에 추가
- **메뉴 설정값(크기, 투명도, 말 거는 빈도 등)은 여기 두지 않음**: 8번 `settings` 에서 다룸. 이름만 유령의 정보라서 `ghosts` 에 있음
- **미정**
  - [A-5](../기획정리_추가정리필요요소.md) 친밀도 규칙: 요인별 점수, 단계별 필요 점수(경계값). 정해지면 `intimacy_stage` 함수와 7번의 함수만 바뀌고 `ghosts` 칸 구조는 그대로 (기존 줄의 `stage` 는 한 번 재계산)
  - 이름 **길이 제한 · 금지어** (지금 1~20자는 임시)
  - 용어: 문서 · 코드에서 "유령(ghost)" vs "펫(pet)" ([A-8](../기획정리_추가정리필요요소.md)). 테이블 이름은 진행현황대로 `ghosts`

## 이해 확인

<details>
<summary>질문 3개 (펼치기)</summary>

1. `ghosts` 에 `id` 칸 없이 `user_id` 가 기본키인 이유는?
2. 이름은 앱이 직접 바꾸게 하면서 친밀도 점수는 왜 못 고치게 할까?
3. `stage`(단계)를 점수와 같이 저장하면 어긋날 수 있는데, 어긋나지 않게 하려면 어떻게 할까?

| # | 혜리 님 답 | 확인 |
| --- | --- | --- |
| 1 | ghost는 유저 id 당 하나이므로 | ⭕ 맞음. 사용자당 1마리라 `user_id` 가 기본키가 되고, DB 가 "유령 두 마리"를 저절로 막아 줌 |
| 2 | 친밀도 점수를 바꾸면 신뢰성 x | ⭕ 맞음. 앱이 점수를 직접 고치면 점수 규칙을 무시하고 마음대로 올릴 수 있음(조작). 이름은 바꿔도 다른 기록에 영향이 없어서 열어 둠 |
| 3 | stage는 친밀도 점수로만 변경 가능하도록 | ⭕ 맞음. 트리거가 점수가 바뀔 때 `stage` 를 자동 계산해서 채우고, 앱은 `stage` 를 직접 못 고침(칸 권한) |

> ✅ ghosts 이해 완료 (2026-11-21)

</details>
