# 퇴사각 펫 (미정)

일하는 동안 바탕화면에 함께 떠 있는 유령 위젯.
유령은 화면을 돌아다니며 말을 걸고, 지울 파일을 먹어 주고, 매일 오후 직장 생활에 대한 짧은 질문을 건넴.
답변이 쌓이면 나의 "퇴사각 지수"를 확인할 수 있고, 함께한 시간만큼 유령과 친해짐.

- 앱: Electron + React + TypeScript (macOS · Windows 10 · Windows 11)
- DB: Supabase (PostgreSQL) — 설계는 [docs/erd/ERD.md](docs/erd/ERD.md) (테이블 8개)

## 폴더 구조

```
pet/
├─ README.md                        # 프로젝트 소개 (이 문서)
├─ CONTRIBUTING.md                  # 개발 규칙: 브랜치 · 커밋 · 머지 · 태그
└─ docs/                            # 설계 문서
   ├─ 기획정리.md                    # 기획 정리 (유령 데스크톱 위젯, 최신 기준)
   ├─ 기획정리_추가정리필요요소.md     # 결정 필요 항목 · 임시 결정 기록
   ├─ 기술스택.md                    # 기술 스택 결정과 검토 기록
   ├─ erd/                          # 새 DB 설계 (테이블 8개, 최신 기준)
   │  ├─ ERD.md                     # 전체 관계도 · 함수 · 트리거 · 마이그레이션 순서
   │  ├─ ERD.png                    # 관계도 이미지
   │  ├─ 00-진행현황.md               # 진행 현황 · 공통 규칙 · 전체 그림
   │  ├─ 00-supabase-구조.md          # Supabase 기초 (auth / public, API, RLS, 인덱스)
   │  └─ 01 ~ 08-*.md               # 테이블별 설계 (users, questions, question_deliveries,
   │                                #   answers, balls, ghosts, intimacy_logs, settings)
   ├─ schema.sql                    # 초기 DB 스키마 (이전 기획 기준, erd/ 설계로 대체 예정)
   └─ legacy/                       # 이전 기획 기준 문서 (참고용)
      ├─ ERD.md                     # 이전 DB 관계도, 권한(RLS), DB 함수 · 트리거
      └─ 화면-구슬병.md               # 이전 캘린더 · 대시보드 화면 안 (구슬병)
```

개발을 시작하면 아래 폴더가 추가될 예정 (자세한 내용은 [docs/기술스택.md](docs/기술스택.md)):

```
├─ app/                 # Electron 유령 앱 (main / renderer)
└─ supabase/            # 마이그레이션 · RLS · DB 함수 · seed (질문 · 대사 포함)
```

## 문서

| 문서 | 내용 |
| --- | --- |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 개발 규칙 |
| [docs/기획정리.md](docs/기획정리.md) | **기획 기준 문서.** 유령 · 질문 · 구슬 · 유리병 선반 · 친밀도 · 메뉴 |
| [docs/기획정리_추가정리필요요소.md](docs/기획정리_추가정리필요요소.md) | 결정이 필요한 항목 · 임시 결정 기록 |
| [docs/erd/ERD.md](docs/erd/ERD.md) | **DB 설계 기준 문서.** 테이블 8개의 관계도 · DB 함수 · 트리거 · 아직 정해지지 않은 값 |
| [docs/erd/00-진행현황.md](docs/erd/00-진행현황.md) | 테이블별 설계 문서 목록과 진행 상태 |
| [docs/기술스택.md](docs/기술스택.md) | 언어 · 프레임워크 · DB 선택 이유 |
| [docs/schema.sql](docs/schema.sql) | 초기 DB 스키마 (이전 기획 기준, `docs/erd/` 설계로 대체 예정) |

> [!WARNING]
> 기획정리_추가정리필요요소.md 의 ✅ 결정은 ERD 설계를 위한 임시 결정
> ERD 는 테이블 구조(칸)가 확정이고, 점수 규칙 · 계산식 같은 **값**은 일부 미정 ([docs/erd/ERD.md](docs/erd/ERD.md) "아직 정해지지 않은 것")

### 이전 문서 (legacy)

새 기획([기획정리.md](docs/기획정리.md))과 다른 부분이 있음. 참고용으로만 사용

| 문서 | 내용 |
| --- | --- |
| [docs/legacy/ERD.md](docs/legacy/ERD.md) | 이전 테이블 설계와 DB 로직 (새 설계는 [docs/erd/ERD.md](docs/erd/ERD.md) 로 대체됨) |
| [docs/legacy/화면-구슬병.md](docs/legacy/화면-구슬병.md) | 이전 캘린더 · 대시보드 구슬병 화면 안 |
