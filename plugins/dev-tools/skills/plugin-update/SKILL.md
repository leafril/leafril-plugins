---
name: plugin-update
disable-model-invocation: true
description: |
  leafril-plugins의 변경사항을 원본 저장소에 동기화하고 버전 업데이트 후 push하는 스킬.
  "플러그인 업데이트", "플러그인 push", "plugin update", "스킬 변경사항 반영", "leafril-plugin push" 등을 말할 때 트리거한다.
  캐시 디렉터리에서 직접 push할 수 없으므로, 원본 저장소로 변경사항을 동기화하는 과정이 필요하다.
allowed-tools: Read, Edit, Glob, Bash, AskUserQuestion
argument-hint: "[readme]"
---

캐시 디렉터리에서 수정한 플러그인 변경사항을 원본 git 저장소로 동기화하고, 버전을 올린 뒤 커밋 + push한다.

## 인자 파싱

- `$ARGUMENTS`에 "readme"가 포함되면 **README 단독 모드**: Step 1~4를 건너뛰고 Step 5(README 업데이트) → Step 6(커밋 + push)만 실행한다.
  - 단, diff 확인 시 스킬 파일 변경이 감지되면 사용자에게 경고하고 전체 워크플로우로 전환할지 AskUserQuestion으로 확인한다.
- `$ARGUMENTS`가 비어 있거나 "readme"가 아니면 **전체 워크플로우**(Step 1~8)를 실행한다.

## 경로

- **원본 저장소**: `~/.claude/plugins/marketplaces/leafril-plugins/`
- **캐시 디렉터리**: `~/.claude/plugins/cache/leafril-plugins/`

경로 매핑:

| 캐시 | 원본 저장소 |
|---|---|
| `cache/{플러그인}/{버전}/skills/` | `plugins/{플러그인}/skills/` |
| `cache/{플러그인}/{버전}/hooks/` | `plugins/{플러그인}/hooks/` |
| `cache/{플러그인}/{버전}/.claude-plugin/plugin.json` | `plugins/{플러그인}/.claude-plugin/plugin.json` |
| — | `.claude-plugin/marketplace.json` (버전 필드만 업데이트) |

## 워크플로우

### Step 1: 변경된 플러그인 파악

각 플러그인의 최신 버전 디렉터리(가장 높은 버전)에서 스킬 파일과 hooks 파일을 원본 저장소의 대응 파일과 `diff`로 비교한다. 변경된 파일 목록과 **변경 방향**을 사용자에게 보여준다.

변경 방향 판단:
- **캐시가 최신**: 캐시에만 변경이 있고 원본은 git clean → 캐시 → 원본 동기화 필요
- **원본이 최신**: 원본에 uncommitted changes가 있고 캐시는 원본의 이전 커밋과 동일 → 원본 동기화 불필요
- **양쪽 다 변경**: 캐시와 원본 모두 변경 → 충돌 경고 후 사용자에게 어느 쪽을 기준으로 할지 확인

기타:
- **변경사항이 없으면**: 사용자에게 알리고 워크플로우를 종료한다
- **여러 플러그인이 변경된 경우**: 플러그인별로 변경 내용을 나열하고, AskUserQuestion의 options로 "한꺼번에 처리" / "개별 처리"를 선택받는다

### Step 2: 버전 결정

현재 버전을 보여주고 semver 기준으로 AskUserQuestion의 options를 사용하여 버전을 선택받는다:
- patch (예: 1.1.1 → 1.1.2) — 버그 수정
- minor (예: 1.1.1 → 1.2.0) — 기능 추가
- major (예: 1.1.1 → 2.0.0) — 호환성 깨짐
- 직접 입력

### Step 3: 원본 저장소에 변경사항 동기화

Step 1의 변경 방향에 따라 처리:
- **캐시가 최신**: 변경된 파일들을 캐시에서 원본 저장소로 복사한다 (경로 매핑 참조)
- **원본이 최신**: 이미 원본에 반영되어 있으므로 이 단계를 건너뛴다

사용자가 diff 결과에 이의가 있으면 수정 후 다시 Step 1로 돌아간다.

### Step 4: 버전 업데이트

아래 파일들의 버전을 새 버전으로 업데이트:
1. `plugins/{플러그인}/.claude-plugin/plugin.json`의 `version` 필드
2. `.claude-plugin/marketplace.json`의 해당 플러그인 `version` 필드

### Step 5: README.md 업데이트

원본 저장소 루트의 `README.md`를 현재 플러그인 상태에 맞게 재생성한다.

정보 수집:
- 각 `plugins/{플러그인}/.claude-plugin/plugin.json`에서 `name`, `description`, `version`
- 각 `plugins/{플러그인}/skills/*/skill.md`의 frontmatter에서 `name`, `description` (첫 문장만 사용)

README 구조:
```
# leafril-plugins
(저장소 설명)

## Plugins

### {플러그인명} (v{버전})
{플러그인 description}

| Skill | Command | Description |
|---|---|---|
| {스킬명} | `/{스킬명}` | {스킬 description 첫 문장} |
...

## Installation
(설치 안내)
```

규칙:
- 스킬은 알파벳순으로 정렬
- description이 길면 첫 마침표(`. ` 또는 행 끝 `.`)까지만 사용한다. 테이블 셀의 가독성을 위해 1문장으로 제한.
- 기존 README의 헤더와 Installation 섹션은 유지, Plugins 섹션만 재생성
- 생성 결과를 기존 README와 diff해서 실질 변경이 없으면 이 단계를 건너뛴다 (불필요한 커밋 방지)

### Step 6: 커밋 + push

원본 저장소에서:
1. 변경된 파일들을 `git add`
2. 커밋 메시지를 작성하여 AskUserQuestion으로 확인받는다 (options: "커밋 + push", "메시지 수정", "취소")
3. 확인 후 `git commit` + `git push`
4. push 실패 시 원인을 안내하고 사용자에게 다음 행동을 확인한다

### Step 7: 캐시 업데이트

원본 저장소의 최신 파일을 기존 캐시 디렉터리에 덮어쓴다. `installed_plugins.json`의 `installPath`가 캐시 경로를 직접 참조하므로, 새 디렉터리를 만들지 않고 기존 경로를 유지해야 한다.

IMPORTANT: skills뿐 아니라 hooks 디렉터리도 반드시 함께 복사해야 한다. 누락 시 PostToolUse hook이 동작하지 않는다.

복사 대상:
1. `plugins/{플러그인}/skills/` → `cache/{플러그인}/{버전}/skills/`
2. `plugins/{플러그인}/hooks/` → `cache/{플러그인}/{버전}/hooks/` (hooks 디렉터리가 있는 경우)

### Step 8: 완료 안내

업데이트된 플러그인명, 버전, push 결과를 출력한다.
