# 퇴사각 펫

바탕화면 위에 떠 있는 펫이 하루의 기분 · 업무 · 질문 답변을 기록해 "퇴사각 지수"를 보여주는 데스크톱 앱.

- 앱: Electron + React + TypeScript (macOS · Windows 10 · Windows 11)
- DB: Supabase (PostgreSQL, 서울 리전)

## 폴더 구조

```
pet/
├─ README.md            # 프로젝트 소개 (이 문서)
├─ CONTRIBUTING.md      # 개발 규칙: 브랜치 · 커밋 · 머지 · 태그
└─ docs/                # 설계 문서
   ├─ 기술스택.md        # 기술 스택 결정과 검토 기록
   ├─ ERD.md            # DB 관계도, 권한(RLS), DB 함수 · 트리거
   └─ schema.sql        # 초기 DB 스키마 (SQLite, PostgreSQL 로 변환 예정)
```

개발을 시작하면 아래 폴더가 추가될 예정 (자세한 내용은 [docs/기술스택.md](docs/기술스택.md)):

```
├─ app/                 # Electron 펫 앱 (main / renderer)
├─ admin/               # 관리자 웹
└─ supabase/            # 마이그레이션 · RLS · DB 함수 · seed
```

## 문서

| 문서 | 내용 |
| --- | --- |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 개발 규칙 |
| [docs/기술스택.md](docs/기술스택.md) | 언어 · 프레임워크 · DB 선택 이유 |
| [docs/ERD.md](docs/ERD.md) | 테이블 설계와 DB 로직 |
