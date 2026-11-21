# Supabase 구조 — ERD 를 위한 기초

> ERD 를 만들 때 필요한 만큼만 정리함
> **결론: 서버는 Supabase 를 씀.** 혜리 님이 설계하는 건 테이블 · RLS · DB 함수 · 인덱스

## 0. Supabase = 이 앱의 서버

- 이 프로젝트는 **서버를 따로 만들지 않음.** Supabase 가 서버 역할을 함 (BaaS: Backend as a Service, 서버를 빌려 쓰는 서비스)
- 데이터는 **Supabase 에만** 저장함. 설정값도 Supabase 에 저장하고 PC 에는 따로 저장하지 않음 ([08-settings.md](08-settings.md))
- 오프라인은 지원하지 않음 → [C-6](../기획정리_추가정리필요요소.md). 단, **저장 실패 시 안내 + 재시도**는 함 (→ [9. 장애 대응](#9-데이터-처리--장애-대응))

```
[클라이언트]                  [서버]
유령 앱 (Electron)  ──→   Supabase (서울)
관리자 웹 (나중)     ──→   DB + API + 로그인 + 권한 + 계산
```

| 서버가 하는 일 | 보통은 | 이 프로젝트에서는 |
| --- | --- | --- |
| 데이터 저장 | DB | Supabase Database (PostgreSQL) |
| 앱 요청 받기 (API) | 직접 만든 서버 코드 | Supabase 가 테이블마다 **자동으로** 만들어 줌 |
| 로그인 | 직접 구현 | Supabase Auth |
| 권한 검사 | 서버 코드의 if 문 | RLS 규칙 |
| 계산 · 규칙 (점수, 질문 뽑기) | 서버 코드 | **DB 함수 · 트리거** (복잡하면 Edge Functions) |

- 혜리 님이 만드는 것: **유령 앱** + **Supabase 안의 테이블 · 규칙 · 함수 · 인덱스** (= 이 ERD)
- 서버 컴퓨터를 켜고 관리하는 일은 Supabase 가 함

## 1. Supabase = 4가지를 묶어 둔 서비스

| 기능 | 하는 일 | 이 앱에서 |
| --- | --- | --- |
| **Database** | PostgreSQL 데이터베이스 (표 = 테이블) | 질문, 답변, 구슬, 유령 … 전부 |
| **Auth** | 로그인 · 회원 관리 | 익명 로그인, 이메일 연결 |
| **API** | 테이블을 만들면 읽고 쓰는 길이 자동으로 생김 | 앱 → `supabase-js` 로 호출 (→ [5](#5-앱에서-데이터-읽고-쓰기-api)) |
| Storage | 파일 저장 | (지금은 안 씀) |

## 2. 테이블이 들어 있는 구역 (schema)

**모든 데이터는 같은 Supabase 데이터베이스 안에 있음.** 그 안이 **구역(schema)** 으로 나뉨. 같은 건물 안의 여러 방 같은 것

```
Supabase 데이터베이스 (건물 하나)
├─ public      🏠 우리 사무실 — 우리가 설계 (ERD 는 여기)
│   ├─ questions
│   ├─ answers
│   └─ …
├─ auth        🔒 관리실 — Supabase 가 관리 (우리가 만들거나 고치지 않음)
│   └─ users        로그인 정보: 이메일, 비밀번호(암호화), 로그인 기록, 익명 여부 …
│
└─ storage · realtime · extensions · vault …
               ⚙️ Supabase 기능이 돌아가려고 있는 방 — 지금은 몰라도 됨
```

- ERD 에서 신경 쓰는 건 **`public`(만드는 곳)** 과 **`auth.users`(가리키기만 하는 곳)** 두 개뿐
- `public` 말고 구역을 더 만들 수도 있음 (예: 관리자 전용 `admin`). 이 앱 규모에선 `public` 하나로 충분

| | `auth.users` | `public` 의 테이블들 |
| --- | --- | --- |
| 위치 | 같은 Supabase DB | 같은 Supabase DB |
| 누가 만드나 | Supabase 가 자동으로 | 우리가 설계 |
| 칸 추가 · 수정 | ❌ 하면 안 됨 | ✅ 마음대로 |
| 앱에서 직접 읽기 · 쓰기 | ❌ 표처럼 조회는 못 함 (비밀번호가 있어서 잠겨 있음). 로그인 기능으로 **본인 정보(id, email)만** 받을 수 있음 | ✅ 가능 (RLS 규칙 안에서) |
| 들어 있는 것 | 로그인에 필요한 정보 | 앱에 필요한 정보 |

## 3. 사용자는 `auth.users` 를 그대로 씀 (public.users 안 만듦)

- 사용자 명단은 `auth.users` 하나로 충분함 → **public 에 users 테이블을 따로 만들지 않음** ([01-users.md](01-users.md))
- 다른 테이블은 `user_id` 칸에 **`auth.users` 의 id 를 바로 적음** (같은 DB 라 가리킬 수 있음)

```
auth.users (Supabase 관리)
   id: a1b2…  ←──────┬── public.answers.user_id   = a1b2…
                     ├── public.balls.user_id     = a1b2…
                     └── public.ghosts.user_id    = a1b2…
```

### 나중에 public.users 가 필요해지는 때
- **관리자 웹(나중)** 에서 **다른 사용자들의** 목록 · 가입일 등을 보여줄 때 → 로그인 기능으로는 본인 정보만 받을 수 있어서, 여러 사람 정보를 보여주려면 public 쪽에 둬야 함
- 개인정보 동의 여부, 이용 정지 같은 **앱 전용 사용자 상태**가 생길 때
- 그때 `auth.users` 와 같은 id 를 쓰는 `public.users` 를 추가하면 됨 → **다른 테이블은 고칠 필요 없음**

## 4. 익명 로그인 → 계정 연결

```
처음 실행          → 익명 로그인      → auth.users: id a1b2…, email 없음, is_anonymous = true
(쓰는 중)          → 답변 · 구슬 쌓임  → 모두 user_id = a1b2…
설정 → 계정 연결    → 이메일 연결      → auth.users: 같은 id a1b2…, email 생김, is_anonymous = false
```

- **id 가 바뀌지 않음** → 연결 전에 쌓은 기록이 그대로 이어짐
- 연결하지 않고 앱을 지우면 → 그 id 로 다시 로그인할 방법이 없음 → 기록을 못 찾음

## 5. 앱에서 데이터 읽고 쓰기 (API)

- **API 코드를 따로 만들지 않음.** 테이블을 만들면 Supabase 가 읽고 쓰는 길(API)을 자동으로 만들어 줌
- 앱은 `supabase-js` 로 테이블에 바로 `insert` · `select` 함

```
유령 앱
  └─ supabase.from('answers').insert(...)
        ↓ HTTPS + 로그인 토큰
Supabase API (자동 생성)
        ↓ RLS 검사: user_id = auth.uid() 인가?
public.answers 테이블에 저장
```

### 키 두 종류

| 키 | 할 수 있는 일 | 앱에 넣어도 되나 |
| --- | --- | --- |
| **anon (공개) 키** | RLS 규칙이 허락한 것만 | ✅ 넣어도 됨 (앱 파일이 열려도 규칙 밖의 일은 못 함) |
| **service_role 키** | 모든 규칙 무시 (관리자) | ❌ **절대 안 됨** |

### 코드 예시

```js
import { createClient } from '@supabase/supabase-js'
const supabase = createClient('https://xxxx.supabase.co', 'anon 키')

// 로그인 (익명) → 이후 요청에 토큰이 자동으로 붙음
await supabase.auth.signInAnonymously()

// 저장 — user_id 는 DB 기본값(auth.uid())이 채움
await supabase.from('answers').insert({ question_id: 12, content: '오늘은 버틸 만했다' })

// 읽기 — RLS 덕분에 내 것만 나옴
const { data } = await supabase.from('answers').select('*').order('created_at', { ascending: false })

// 규칙이 있는 일 — DB 함수 호출
const { data: q } = await supabase.rpc('pick_today_question')
```

- **점수 · 구슬 지급 · 질문 뽑기는 앱에서 계산하지 않음.** 앱이 계산해서 보내면 사용자가 조작할 수 있음 → DB 함수 안에서 계산

### DB 쪽에서 해둘 것

```sql
-- user_id 기본값 = 로그인한 사람
alter table answers alter column user_id set default auth.uid();
```

## 6. 내 데이터만 보이게 — RLS

- 모든 사용자의 답변이 **한 테이블**에 같이 들어 있음
- RLS(행 단위 보안) = "로그인한 사람의 id 와 `user_id` 가 같은 줄만 보여줘" 라는 규칙
- Supabase 에서 로그인한 사람의 id 는 `auth.uid()` 로 꺼냄

| answers | user_id | … |
| --- | --- | --- |
| 줄 1 | `a1b2…` | ← 혜리 님이 로그인하면 이것만 보임 |
| 줄 2 | `c3d4…` | ← 다른 사람 것. 안 보임 |

```sql
alter table answers enable row level security;

create policy "내 답변만" on answers
  for all
  using      (user_id = (select auth.uid()))   -- 읽기 · 수정 · 삭제
  with check (user_id = (select auth.uid()));  -- 쓰기
```

- `auth.uid()` 를 `(select …)` 로 감싸면 한 번만 계산해서 빨라짐
- **RLS 를 켜지 않은 테이블은 anon 키로 누구나 읽고 쓸 수 있음** → 테이블 만들 때 항상 켬

→ 그래서 **거의 모든 테이블에 `user_id` 칸이 필요**함 (users 테이블에서 배운 것)

## 7. 인덱스

- Supabase 의 DB 는 **그냥 PostgreSQL** → PostgreSQL 인덱스는 거의 다 쓸 수 있음

| 종류 | 언제 | 예시 |
| --- | --- | --- |
| B-tree (기본) | `=`, 범위, 정렬 | `user_id`, `created_at` |
| 복합 | 여러 칸으로 같이 조회 | `(user_id, created_at desc)` |
| 부분 | 일부 줄만 자주 조회 | `where deleted_at is null` |
| 표현식 | 계산된 값으로 조회 | `lower(email)` |
| GIN | JSONB · 배열 · 전문 검색 | 태그 배열 |
| pg_trgm | `LIKE '%단어%'` 검색 | 답변 내용 검색 |
| pgvector | AI 임베딩 유사도 검색 | 비슷한 답변 찾기 |

### 이 앱 기본 규칙

```sql
-- 모든 조회에 user_id 조건(RLS)이 붙으므로 거의 필수
create index on answers (user_id, created_at desc);

-- 삭제 안 된 것만 자주 볼 때
create index on ghosts (user_id) where deleted_at is null;
```

- 지금은 **모든 테이블에 `(user_id, created_at)` 인덱스** 정도면 충분
- 복잡한 인덱스는 **실제로 느린 쿼리가 보일 때** 추가
- 확인 도구: SQL Editor 의 `EXPLAIN ANALYZE`, 대시보드의 Query Performance · Index Advisor
- 한계: 슈퍼유저 권한이 없어 일부 서버 설정 · 미지원 확장은 못 씀. 성능 상한은 플랜의 서버 크기에 따라 다름

## 8. 왜 Supabase 인가 — 장단점

**이유**: 1인 개발 + 관리자 웹(나중)을 붙일 서버가 필요 + 로그인 필요 → 서버를 직접 만들지 않고 바로 쓸 수 있어서

| 장점 | 내용 |
| --- | --- |
| 서버를 안 만들어도 됨 | DB · 로그인 · API 가 이미 있음 |
| 로그인 기능 포함 | 익명 로그인 → 이메일 연결 제공 (기획의 "계정 연결") |
| 관리자 웹 붙이기 쉬움 | 나중에 같은 DB 에 연결만 하면 됨 |
| PostgreSQL | 표준 DB 라 인덱스 · 함수 다 쓸 수 있고, 나중에 다른 곳(AWS 등)으로 옮길 수 있음 |
| 대시보드 | 사이트에서 테이블 데이터를 엑셀처럼 보고 고칠 수 있음 |

| 단점 | 내용 |
| --- | --- |
| 오프라인 기능 없음 | 인터넷이 끊기거나 장애가 나면 저장이 안 됨 → [9](#9-데이터-처리--장애-대응) |
| 무료 플랜 제한 | 1주일 사용 없으면 일시정지 |
| RLS 공부 필요 | 앱이 DB 에 직접 붙는 구조라 규칙을 잘못 쓰면 남의 데이터가 보일 수 있음 |
| 개인정보 책임 | 퇴사 관련 답변이 서버에 쌓임 → 개인정보 처리방침 · 관리 필요 |
| 의존성 | Supabase 정책 · 가격이 바뀌면 영향을 받음 |

## 9. 데이터 처리 · 장애 대응

### Supabase 가 데이터를 어떻게 다루나

- **데이터 주인은 우리.** Supabase 는 대신 보관 · 처리하는 쪽(처리자)이고, 서비스 운영 목적 외에는 쓰지 않음 *(공식 페이지 확인 필요)*
- 보안 인증 SOC 2, DPA(데이터 처리 계약) 제공 *(공식 페이지 확인 필요)*
- **서울 리전**을 고르면 데이터는 서울의 AWS 서버에 저장됨
- 단, Supabase 는 미국 회사 → **개인정보 처리방침에 "처리 위탁(국외 이전): Supabase Inc." 기재** (퇴사 관련 답변은 민감할 수 있음)

### 장애가 나면

- Supabase 는 AWS 위에서 돌아감 → Supabase 자체 장애 + AWS 장애 영향을 받음
- 장애 중엔 **질문을 받거나 답변을 저장할 수 없음.** 이미 저장된 데이터가 사라지는 건 아님 (대부분 "잠깐 접속 불가")
- Free · Pro 플랜엔 가동률 보장(SLA) 없음. 상위 플랜 이야기 *(공식 페이지 확인 필요)*

| 위험 | 대비 |
| --- | --- |
| 잠깐 접속 불가 | "지금 저장할 수 없어요" 안내 + 입력한 답변은 잠시 들고 있다가 재시도 |
| 데이터 손실 | Pro 매일 자동 백업 + 직접 `pg_dump` 백업을 주기적으로 받아 둠 |
| 무료 플랜 일시정지 | 개발 중에만 Free, 배포는 Pro |
| Supabase 를 떠나야 할 때 | 표준 PostgreSQL 이라 덤프해서 다른 곳(AWS RDS 등)으로 옮김 |

- 직접 서버를 만들어도 장애는 남. 그땐 혼자 다 복구해야 함 → 1인 개발엔 Supabase 가 더 안정적일 가능성이 큼
- 장애 이력: [status.supabase.com](https://status.supabase.com) · 약관: [privacy](https://supabase.com/privacy) · [DPA](https://supabase.com/legal/dpa)

## 10. AWS 데이터베이스(RDS)와 차이

> AWS RDS = **DB 만** 빌려줌 (주방 · 재료) / Supabase = DB + 앱이 쓸 기능까지 묶어서 줌 (밀키트). Supabase 도 실제로는 AWS 위에서 돌아감

| 필요한 것 | AWS RDS | Supabase |
| --- | --- | --- |
| DB (PostgreSQL) | ✅ | ✅ |
| 앱이 DB 에 접속하는 길 (API) | ❌ **API 서버를 직접 만들어야 함** | ✅ 자동 |
| 로그인 | ❌ Cognito 등을 따로 붙임 | ✅ 포함 |
| 내 데이터만 보이게 | API 서버 코드로 처리 | ✅ RLS |
| 데이터 보기 · 수정 화면 | 별도 도구 | ✅ 대시보드 |
| 설정 난이도 | 네트워크 · 보안 그룹 · 서버 배포 등 많음 | 프로젝트 만들기 몇 분 |

- **데스크톱 앱이라서 중요한 차이**: RDS 는 DB 비밀번호를 앱에 넣을 수 없어서(앱 파일은 누구나 열어볼 수 있음) 중간에 API 서버가 꼭 필요함. Supabase 는 anon 키 + RLS 로 해결

```
AWS:      유령 앱 → [API 서버: 직접 만들고 운영] → RDS
Supabase: 유령 앱 → Supabase (API + 로그인 + RLS 포함) → DB
```

- AWS 가 나은 경우: 서비스가 아주 커져서 세밀한 조절이 필요할 때, 회사 정책상 AWS 를 써야 할 때, 어차피 복잡한 API 서버를 만들어야 할 때

## 11. 가격 (2026-11-18, [공식 페이지](https://supabase.com/pricing) 기준)

| | Free | Pro |
| --- | --- | --- |
| 월 요금 | $0 | **$25 부터** (서버 1개 비용 포함) |
| DB 용량 | 500 MB | 8 GB (넘으면 GB 당 $0.125) |
| 월간 활성 사용자 | 5만 명 | 10만 명 (넘으면 1명당 $0.00325) |
| 일시정지 | **1주일 사용 없으면 멈춤** | 없음 |
| 자동 백업 | 없음 | 매일, 7일 보관 |
| 프로젝트 수 | 2개 | 추가 시 $10~ |

- 이 앱은 하루 답변 최대 3줄 → 사용자 1명이 1년에 대략 0.3 MB (추정). 무료 500 MB 로도 천 명 정도 1년 가능
- **개발 중 → Free**, **배포할 때 → Pro 고려** (Supabase 가 유일한 원본이라 백업이 중요)

## 정리

| 기억할 것 | 한 줄 |
| --- | --- |
| 역할 | Supabase = 이 앱의 서버. 데이터는 Supabase 에만 |
| 구역 | 우리는 `public` 에 만들고, `auth.users` 는 가리키기만 함. 나머지 구역은 몰라도 됨 |
| 사용자 | public.users 없음. 모든 `user_id` 는 `auth.users` 의 id 를 가리킴 |
| 익명 → 연결 | id 가 그대로라 기록이 이어짐 |
| API | 자동 생성. 앱은 `supabase-js` 로 insert · select · rpc. anon 키만 앱에, service_role 키는 절대 X |
| 계산 | 점수 · 구슬 · 질문 뽑기는 DB 함수에서 (앱에서 계산 X) |
| RLS | `user_id = (select auth.uid())` 인 줄만 보임. 모든 테이블에 켬 |
| 인덱스 | PostgreSQL 이라 다 가능. 기본은 `(user_id, created_at)` |
| 장애 | 저장만 잠깐 안 됨. 안내 + 재시도, 백업(Pro + pg_dump) |
| 개인정보 | 처리방침에 Supabase 처리 위탁(국외 이전) 기재 |
| 가격 | 개발은 Free, 배포는 Pro($25~) 고려 |
