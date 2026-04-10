# 정확성 Red Flag

"정확성" 검증은 "코드베이스와 일치하는가"라는 추상 기준으로 흐르기 쉽다. 다음 5개 체크리스트를 **명시적으로** 점검해 추상성을 제거한다.

적용 범위: **기존 CLAUDE.md 파일을 스캔**하는 audit 전용. 신규 한 조각을 다루는 `claude-md-append`엔 해당 없음.

## 1. 죽은 명령

문서의 명령이 실제로 실행되는가?

**점검:**
- `package.json`의 `scripts` 필드, `Makefile` 타겟, `justfile`, `Taskfile.yml` 등과 대조
- 패키지 매니저 일치 (`npm` vs `pnpm` vs `yarn`, `pip` vs `uv` vs `poetry`)
- 배포 명령이 실제 CI/CD 설정과 일치하는가 (`.github/workflows/`, `Dockerfile`)

**예:**
- ❌ `npm run build` — 하지만 `package.json`엔 `build:prod`만 있음
- ❌ `make deploy` — 하지만 프로젝트는 이미 pnpm 스크립트로 이전

## 2. 죽은 경로

문서가 언급하는 파일·디렉토리가 실존하는가?

**점검:**
- `src/api/handlers/`, `packages/core/` 같은 경로가 실제로 있는가
- 언급된 설정 파일(`.env.example`, `config/app.yml`)이 존재하는가
- 리팩토링 후 이름이 바뀌었거나 삭제된 모듈 참조

**예:**
- ❌ "API 핸들러는 `src/api/handlers/`에 있다" — 하지만 `src/routes/`로 이동됨
- ❌ "`config/redis.yml` 참고" — 파일이 `.gitignore`에 추가되며 삭제됨

## 3. Stale 버전

명시된 언어·프레임워크 버전이 현재 설정과 일치하는가?

**점검:**
- Node/Python 버전: `package.json` `engines`, `.nvmrc`, `.python-version`, `pyproject.toml`
- 프레임워크 메이저 버전: React 17 → 18, Next.js 13 → 15 같은 migration 후 문서 방치
- DB 버전, 런타임 버전, SDK 버전

**예:**
- ❌ "Node 16 이상" — 하지만 `.nvmrc`엔 `20.11.0`
- ❌ "Next.js 13 app router" — 현재 15로 업그레이드됨

## 4. 좀비 TODO

이미 해결된 항목이 TODO로 남아있는가?

**점검:**
- `TODO:`, `FIXME:`, "나중에 X하기로 함" 같은 문구
- 해당 이슈를 실제로 코드에서 검색해 해결 여부 확인
- "임시로 Y 사용" 표시가 영구 솔루션으로 바뀌었는데 문서는 그대로

**예:**
- ❌ "TODO: Redis로 캐시 마이그레이션" — 이미 `src/cache/redis.ts` 있음
- ❌ "임시로 localStorage 사용 중" — 이미 proper 세션 스토어로 교체됨

## 5. 치환 안 된 플레이스홀더

템플릿에서 복사한 뒤 실제 값으로 치환 안 된 자리

**점검:**
- `<project-name>`, `<your-command>`, `<path>`, `[TBD]`, `PROJECT_NAME` 등
- "Example: ..." 섹션이 실제 예시 없이 그대로 남음
- 마크다운 링크 `[text](url)`에서 `url`이 `#` 또는 `TODO`

**예:**
- ❌ `# <Project Name>` — 실제 프로젝트명으로 안 바뀜
- ❌ 명령 블록에 `<install command>` 그대로 남음

## 점검 원칙

- **실제 파일을 읽어** 검증한다. 문서끼리만 비교하지 마라.
- Red flag은 "추가 추천"이 아니라 **"수정/제거 추천"** 으로 분류된다.
- 5개 항목이 망라는 아니다. 더 중요한 게 있으면 사용자에게 질문·보고.
