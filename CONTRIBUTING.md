# 개발 규칙

1인 개발 기준. 브랜치 · 커밋 · 머지 · 태그 규칙을 정리함.

## 1. 브랜치 전략 — GitHub Flow

```
main ─────●──────────────●──────────────●─────  (항상 실행 가능한 상태)
           \            /  \            /
            feat/pet-drag    fix/idle-time
            (PR → squash merge)
```

1. `main` 은 **항상 실행되는 상태**로 유지하고, **직접 커밋하지 않음**
2. 작업은 항상 최신 `main` 에서 브랜치를 따서 시작
3. 작업이 끝나면 **PR 생성 → 셀프 체크 → Squash merge**
4. 머지한 브랜치는 삭제
5. 배포 시점에 `main` 에 태그를 붙임

> 예외: 첫 커밋(`v0.1`)은 저장소 생성 시 `main` 에 직접 올림

## 2. 브랜치 이름 규칙

`<종류>/<짧은-설명>` — 소문자, 단어 사이는 하이픈(`-`)

| 종류 | 용도 | 예시 |
| --- | --- | --- |
| `feat/` | 새 기능 | `feat/transparent-pet-window` |
| `fix/` | 버그 수정 | `fix/idle-time-macos` |
| `docs/` | 문서 | `docs/erd-update` |
| `refactor/` | 동작 변화 없는 구조 개선 | `refactor/scoring-module` |
| `chore/` | 설정 · 빌드 · 패키지 | `chore/setup-electron-vite` |
| `db/` | DB 마이그레이션 · RLS · 함수 | `db/postgres-schema` |

- 이슈를 쓰면 번호를 앞에 붙임: `feat/12-pet-drag`
- 브랜치 하나 = 작업 하나. 여러 작업을 섞지 않음

## 3. 커밋 메시지 규칙 — Conventional Commits

```
<type>(<scope>): <제목>

<본문 — 무엇을, 왜 바꿨는지 (선택)>
```

| type | 의미 |
| --- | --- |
| `feat` | 새 기능 |
| `fix` | 버그 수정 |
| `docs` | 문서만 변경 |
| `refactor` | 동작 변화 없는 코드 구조 변경 |
| `style` | 포맷 · 세미콜론 등 (동작 변화 없음) |
| `test` | 테스트 추가 · 수정 |
| `chore` | 빌드 · 설정 · 패키지 |
| `perf` | 성능 개선 |

- `scope` 는 선택: `pet`, `dashboard`, `db`, `admin`, `scoring` 등
- **커밋 메시지(제목 · 본문)는 한국어로 작성**. `type` · `scope` 와 코드 · 파일 이름은 영어 그대로 씀
- 제목은 50자 이내, 마침표 없음
- 예시
  - `feat(pet): 투명 창에서 펫 드래그 기능 추가`
  - `fix(db): 경험치 역분개 시 UNIQUE 충돌 수정`
  - `docs: ERD 에 관리자 감사 로그 추가`

## 4. PR · 머지 규칙

- **머지 방식은 Squash merge 만 사용** → PR 하나가 `main` 에 커밋 하나로 들어감
- **PR 제목 = Conventional Commits 형식** (squash 후 그대로 `main` 의 커밋 메시지가 됨)
- 작업 브랜치 안의 커밋은 자유롭게 (`wip`, `오타` 등 괜찮음)
- 머지 전 셀프 체크
  - [ ] 앱이 실행되는가
  - [ ] PR 제목이 커밋 규칙에 맞는가
  - [ ] 관련 문서(ERD · 기술스택 등)를 같이 고쳤는가
  - [ ] `.env`, 키 같은 비밀 값이 들어가지 않았는가

## 5. 태그(버전) 규칙

- 형식: **`v<major>.<minor>`** — 예: `v0.1`, `v0.2`, `v1.0`
- 배포할 때마다 **두 번째 자리 +1** (기능 추가든 버그 수정이든 동일)
  - `v0.1` → `v0.2` → `v0.3` …
- `v1.0` = 첫 정식 출시. 그 전(MVP)까지는 `v0.x`
- 태그는 항상 **`main` 에, 메시지 있는 태그(annotated)** 로 붙임
- **앱 버전과의 대응**: Electron `package.json` 의 `version` 은 세 자리여야 하므로
  **태그 `v0.2` = `package.json` 버전 `0.2.0`** 으로 맞춤

## 6. 작업 흐름 예시

```bash
# 1. 최신 main 에서 브랜치 생성
git switch main
git pull
git switch -c feat/pet-drag

# 2. 작업 · 커밋 (브랜치 안에서는 자유롭게)
git add .
git commit -m "feat(pet): 드래그 이벤트 처리"

# 3. 푸시 후 PR 생성 (제목은 Conventional Commits 형식)
git push -u origin feat/pet-drag
gh pr create --title "feat(pet): 투명 창에서 펫 드래그 기능 추가" --fill

# 4. 셀프 체크 후 squash merge + 브랜치 삭제
gh pr merge --squash --delete-branch

# 5. 배포할 때 태그
git switch main
git pull
git tag -a v0.2 -m "v0.2: 펫 드래그 기능"
git push origin v0.2
```
