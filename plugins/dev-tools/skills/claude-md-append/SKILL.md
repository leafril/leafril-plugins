---
name: claude-md-append
description: 세션 중 발견한 학습·규칙·취향을 올바른 레벨(user vs project, CLAUDE.md vs rules/ vs skill)로 라우팅해 기록한다. "이거 기억해", "CLAUDE.md에 넣어줘", "학습 반영해줘", "메모리에 추가", "remember this", "add to memory" 등 사용자가 세션 중 얻은 지식 한 조각을 영구 저장하려 할 때 반드시 트리거한다. 전체 감사(claude-md-audit)와 달리 **한 조각 라우팅**에 특화되어 있다.
tools: Read, Glob, Grep, Bash, Edit
---

# CLAUDE.md Append

세션 중 얻은 지식 한 조각을 **올바른 위치에 기록**한다. 이 스킬의 가치는 "어디에 쓸지" 결정 로직에 있다 — 그 외엔 최소한만 한다.

## 언제 쓰지 않는가

- **전체 CLAUDE.md 점검/감사** → `claude-md-audit` (주기 감사)
- **품질 점수 기반 개선** → `claude-md-management:claude-md-improver`
- **일회성 수정**, **재발 안 할 버그**, **코드에서 쉽게 찾을 정보** → 기록하지 마라. 컨텍스트 낭비다.

## 입력

다음 중 하나:

1. 사용자가 명시한 조각 — "이거 기억해: 이 레포는 pnpm 씀"
2. 스킬이 대화를 훑어 추출한 후보 — 사용자가 "학습 반영해줘" / "기억할 거 있나"라고 한 경우

2번의 경우 대화에서 다음을 찾는다:

- 사용자가 정정한 Claude의 행동
- 같은 실수가 2회 이상 반복된 지점
- 새로 발견한 명령·도구·경로·관례
- "앞으로 ~해줘" 같은 명시적 규칙 요청

기록할 만한 게 없으면 **"기록할 가치 있는 조각 없음"이라고 답하고 끝내라**. 억지로 채우면 user-scope 오염만 일으킨다.

## 라우팅 결정 트리

각 조각마다 다음 질문을 **순서대로** 묻는다. 앞 질문이 결정되면 다음은 조건부다.

### Q1. 이 정보가 모든 프로젝트에 공통인가, 특정 레포에만 해당하는가?

- **레포 한정** (빌드 명령, 이 코드베이스의 패턴, 팀 관례, 이 프로젝트의 아키텍처) → **project-level**
- **크로스 프로젝트** (언어·도구 선호, 말투, 코칭, 항상 참인 개인 원칙) → **user-level** (`~/.claude/`)

판단 원칙: "이 정보가 다른 레포에서도 참인가?" 아니면 project-level이다. **애매하면 project-level을 택한다** — user-scope 오염이 가장 큰 리스크다.

**project-level로 라우팅되면 즉시 "어느 레포인가"를 해결한다**:

```bash
git rev-parse --show-toplevel 2>/dev/null
```

- 현재 작업 디렉토리가 레포 안이면 그 루트를 타겟으로 쓴다.
- 레포가 아니거나("fatal: not a git repository") 여러 레포가 섞인 세션이면 **사용자에게 어느 레포인지 묻는다**. 추측하지 마라 — 엉뚱한 레포 CLAUDE.md에 쓰면 의미 없다.
- 레포 컨텍스트를 해결하기 전에는 Q3로 넘어가지 마라. 대상 파일(`<repo>/CLAUDE.md`)이 확정돼야 Q4·Q5 중복 체크가 가능하다.

### Q2. 단일 사실/규칙인가, 멀티스텝 절차인가?

- **멀티스텝 절차** (순서 있는 워크플로, 조건 분기, 여러 도구 호출) → **skill**
  - user-level: `~/.claude/skills/<name>/SKILL.md`
  - project-level: `<repo>/.claude/skills/<name>/SKILL.md` 또는 플러그인 저장소
- **단일 사실/규칙/취향** → Q3

스킬 생성은 append의 범위 밖이다. "이건 skill로 분리하는 게 맞겠다"라고 **제안하고 멈춘다** — 사용자가 `skill-creator`로 진행하도록 안내한다.

### Q3. 경로/파일별 규칙인가, 항상 참인 원칙인가?

- **경로 한정** ("src/api/ 밑에선 X", "*.test.ts에선 Y", "특정 도구 사용 시에만") → **`rules/` 파일**
  - user-level: `~/.claude/rules/<topic>.md`
  - project-level: `<repo>/.claude/rules/<topic>.md`
- **항상 참** → **CLAUDE.md**
  - user-level: `~/.claude/CLAUDE.md`
  - project-level: `<repo>/CLAUDE.md` 또는 `<repo>/.claude/CLAUDE.local.md`(개인용)

### Q4. 기존 주제별 파일이 있는가?

`rules/` 또는 CLAUDE.md의 기존 섹션에 같은 주제가 있으면 **append 또는 수정**한다. 없으면:

- 재사용 가능한 주제이고 3줄 이상 쓸 가치 있으면 → **새 `rules/<topic>.md` 파일**
- 한 줄짜리 → **CLAUDE.md 적절한 섹션에 삽입**

### Q5. 이미 다른 곳에 기록되어 있는가?

편집 전 반드시 확인:

- user-scope에 쓰기 전: 해당 레포 CLAUDE.md에 이미 있는 내용을 복사하려는 건 아닌가?
- 같은 주제의 기존 항목이 있는가? 있으면 **중복 추가 대신 기존 항목 수정**.

중복을 발견하면 사용자에게 "이미 X에 있다"고 알리고 수정 제안 또는 skip.

## 워크플로

### Phase 1: 후보 추출

입력이 명시적이면 그대로 쓴다. 암묵적이면("학습 반영해줘") 대화를 훑어 후보를 **2~5개** 뽑는다. 더 많으면 사용자에게 우선순위를 묻는다.

### Phase 2: 각 후보에 Q1~Q5 적용

결과를 표로 정리:

```
| # | 조각 | 레벨 | 대상 파일 | 라우팅 근거 |
|---|------|------|-----------|-------------|
| 1 | 이 레포는 pnpm 사용 | project | ./CLAUDE.md | Q1: 레포 한정, Q3: 항상 참 |
| 2 | 한국어 답변 시 영어 팁 | user | ~/.claude/rules/english-coaching.md | Q1: 크로스 프로젝트, Q4: 기존 파일 append |
| 3 | 배포 여러 단계 절차 | — | (skill-creator 제안) | Q2: 멀티스텝 → 스킬 생성 범위 밖 |
```

### Phase 3: 중복 체크

각 대상 파일을 실제로 **읽어** 중복/충돌 확인. 문서 제목만 보고 판단하지 마라.

- 중복 → 기존 항목 수정으로 전환
- 충돌 → 사용자에게 알리고 대기

### Phase 4: Diff 제시

각 변경마다:

```markdown
### Update: <경로>
**Why:** <1줄 사유 + 라우팅 근거 요약>

```diff
+ <추가 내용>
```
```

user-scope 편집이 포함되면 사용자가 직접 리뷰하기 쉽도록 **user-scope 변경을 맨 위에** 놓는다.

### Phase 5: 승인 후 적용

사용자 승인을 받은 항목만 변경한다. **특히 user-scope (`~/.claude/`)는 승인 없이 절대 쓰지 마라.**

user-scope 편집 전 **dotfiles 매니저 감지**를 한다 — 아래 참고.

## Chezmoi 감지 (user-scope 편집 시)

`~/.claude/` 이하가 chezmoi로 관리되면 타겟을 직접 편집했을 때 다음 `chezmoi apply`에서 **덮어써진다**. 편집 전 반드시 감지한다:

```bash
chezmoi managed ~/.claude/CLAUDE.md 2>/dev/null && echo "managed"
```

managed이면:

1. `chezmoi source-path <타겟경로>`로 소스 경로 해결 (OS별 다름, 하드코딩 금지)
2. 소스에서 Edit
3. `chezmoi apply`로 타겟 반영
4. 커밋/푸시는 **사용자가 명시 요청한 경우만**. `chezmoi cd`로 소스 디렉토리에 들어가 수행.

경로 매핑: `dot_claude/` ↔ `~/.claude/` (chezmoi는 `dot_` 접두사를 `.`로 변환).

managed가 아니면 `~/.claude/`를 직접 편집한다. chezmoi가 설치되어 있지 않은 환경이면 감지 명령이 실패하므로 fallthrough도 같은 경로다.

## 작성 규칙 (기록 내용 자체의 품질)

**핵심 원칙**: "이 줄이 없으면 Claude가 실수할까?" 아니면 쓰지 마라.

- 한 줄이면 한 줄. 장황한 설명 금지.
- 구체적으로. "코드 깔끔하게" ❌ → "2-space indent" ✅ — 검증 가능한 지시만.
- Claude가 이미 아는 표준 프레임워크 관례는 쓰지 마라.
- 일회성 수정, 재발 안 할 버그는 기록하지 마라.
- CLAUDE.md 파일당 **200줄 한계** 존중. 초과 시 `rules/` 분리 또는 하위 CLAUDE.md 분할 제안.
- 기존 파일에 append할 때는 **그 파일의 문체·길이·포맷을 먼저 읽고 맞춘다**.

포함/제외 판단의 상세 기준은 `claude-md-audit` 스킬의 `references/criteria.md` 참고. 중복 유지 회피를 위해 본 스킬엔 상세 표를 넣지 않는다.

## 원칙 요약

- **최소 개입**: 기록할 가치 없으면 쓰지 마라.
- **라우팅이 본질**: 이 스킬의 가치는 "어디에 쓸지"다.
- **user-scope 보수주의**: 애매하면 project-level.
- **승인 필수**: 특히 user-scope는 사용자 명시 승인 없이 건드리지 않는다.
- **매니저 존중**: dotfiles 매니저가 감지되면 소스 경로로 우회.
